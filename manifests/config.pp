# -----------------------------------------------------------------------------
#   Copyright (c) 2012 Bryce Johnson
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
# -----------------------------------------------------------------------------

# @api private
class jira::config {
  # This class should be used from init.pp with a dependency on jira::install
  # and sending a refresh to jira::service
  assert_private()

  File {
    owner => $jira::user,
    group => $jira::group,
  }

  # JVM args. These will be the defaults if not overridden
  if $jira::jvm_type == 'openjdk-11' {
    $jvm_gc_args = '-XX:+UseG1GC -XX:+ExplicitGCInvokesConcurrent'
  } else {
    $jvm_gc_args = '-XX:+ExplicitGCInvokesConcurrent'
  }
  $jvm_code_cache_args = '-XX:InitialCodeCacheSize=32m -XX:ReservedCodeCacheSize=512m'
  $jvm_extra_args = '-XX:-OmitStackTraceInFastThrow -Djava.locale.providers=COMPAT'

  $dbschema_default = $jira::db ? {
    'postgresql' => 'public',
    default      => undef
  }

  # can't use pick_default: https://tickets.puppetlabs.com/browse/MODULES-11018
  $dbschema = if $jira::dbschema { $jira::dbschema } else { $dbschema_default }

  if $jira::tomcat_redirect_https_port {
    unless $jira::tomcat_native_ssl {
      fail('You need to set jira::tomcat_native_ssl to true when using jira::tomcat_redirect_https_port')
    }
  }

  $change_dbpassword = $jira::change_dbpassword

  if $jira::dbport {
    $dbport = $jira::dbport
  } else {
    $dbport = $jira::db ? {
      'postgresql' => '5432',
      'mysql'      => '3306',
      'oracle'     => '1521',
      'sqlserver'  => '1433',
      'h2'         => '',
    }
  }

  if $jira::dbdriver {
    $dbdriver = $jira::dbdriver
  } else {
    $dbdriver = $jira::db ? {
      'postgresql' => 'org.postgresql.Driver',
      'mysql'      => 'com.mysql.jdbc.Driver',
      'oracle'     => 'oracle.jdbc.OracleDriver',
      'sqlserver'  => 'com.microsoft.sqlserver.jdbc.SQLServerDriver',
      'h2'         => 'org.h2.Driver',
    }
  }

  if $jira::dbtype {
    $dbtype = $jira::dbtype
  } else {
    $dbtype = $jira::db ? {
      'postgresql' => 'postgres72',
      'mysql'      => 'mysql',
      'oracle'     => 'oracle10g',
      'sqlserver'  => 'mssql',
      'h2'         => 'h2',
    }
  }

  if $jira::dburl {
    $dburl = $jira::dburl
  }
  else {
    # SIDs use :, service names use /
    $oracle_separator = bool2str($jira::oracle_use_sid, ':', '/')
    $dburl = $jira::db ? {
      'postgresql' => "jdbc:${jira::db}://${jira::dbserver}:${dbport}/${jira::dbname}",
      'mysql'      => "jdbc:${jira::db}://${jira::dbserver}:${dbport}/${jira::dbname}?useUnicode=true&amp;characterEncoding=UTF8&amp;sessionVariables=default_storage_engine=InnoDB",
      'oracle'     => "jdbc:${jira::db}:thin:@${jira::dbserver}:${dbport}${oracle_separator}${jira::dbname}",
      'sqlserver'  => "jdbc:jtds:${jira::db}://${jira::dbserver}:${dbport}/${jira::dbname}",
      'h2'         => "jdbc:h2:file:/${jira::homedir}/database/${jira::dbname}",
    }
  }

  # Allow some backwards compatibility;
  if $jira::poolsize {
    deprecation('jira::poolsize', 'jira::poolsize is deprecated and simply sets max-pool-size. Please use jira::pool_max_size instead and remove this configuration')
  }

  $pool_min_size = pick($jira::pool_min_size, 20)
  $pool_max_size = pick($jira::pool_max_size, $jira::poolsize, 20)
  $pool_max_wait = pick($jira::pool_max_wait, 30000)
  $pool_max_idle = pick($jira::pool_max_idle, 20)
  $pool_remove_abandoned = pick($jira::pool_remove_abandoned, true)
  $pool_remove_abandoned_timeout = pick($jira::pool_remove_abandoned_timeout, 300)
  $min_evictable_idle_time = pick($jira::min_evictable_idle_time, 60000)
  $time_between_eviction_runs = pick($jira::time_between_eviction_runs, 300000)
  $pool_test_while_idle = pick($jira::pool_test_while_idle, true)
  $pool_test_on_borrow = pick($jira::pool_test_on_borrow, false)

  # JIRA will complain if these aren't set for PostgreSQL (will work fine though)
  # https://confluence.atlassian.com/jirakb/connection-problems-to-postgresql-result-in-stuck-threads-in-jira-1047534091.html
  if $jira::db == 'postgresql' {
    $connection_settings = pick($jira::connection_settings, 'tcpKeepAlive=true;socketTimeout=240')
  } else {
    $connection_settings = $jira::connection_settings
  }

  if $jira::db == 'mysql' {
    $validation_query_timeout = pick($jira::validation_query_timeout, 3)
  } else {
    $validation_query_timeout = $jira::validation_query_timeout
  }

  if $jira::validation_query {
    $validation_query = $jira::validation_query
  } else {
    $validation_query = $jira::db ? {
      'mysql'      => 'select 1',
      'sqlserver'  => 'select 1',
      'oracle'     => 'select 1 from dual',
      'postgresql' => 'select version();',
      'h2'         => undef,
    }
  }

  $tomcat_protocol_ssl_real = pick($jira::tomcat_protocol_ssl, 'org.apache.coyote.http11.Http11NioProtocol')

  $jira_properties = {
    'jira.websudo.is.disabled' => !$jira::enable_secure_admin_sessions,
  }
  $merged_jira_config_properties = jira::sort_hash($jira_properties + $jira::jira_config_properties)

  # Configuration logic ends, resources begin:

  file { "${jira::webappdir}/bin/user.sh":
    content => epp("${module_name}/user.sh.epp"),
    mode    => '0755',
  }

  file { "${jira::webappdir}/bin/setenv.sh":
    content => epp("${module_name}/setenv.sh.epp"),
    mode    => '0755',
  }

  $dbconfig_template = $jira::use_jndi_ds ? {
    true    => "${module_name}/dbconfig.jndi.xml.epp",
    default => "${module_name}/dbconfig.xml.epp"
  }
  file { "${jira::homedir}/dbconfig.xml":
    content => epp($dbconfig_template),
    mode    => '0600',
  }

  if $jira::script_check_java_manage {
    file { "${jira::webappdir}/bin/check-java.sh":
      content => template($jira::script_check_java_template),
      mode    => '0755',
      require => File["${jira::webappdir}/bin/setenv.sh"],
    }
  }

  file { "${jira::webappdir}/conf/server.xml":
    content => epp("${module_name}/server.xml.epp"),
    mode    => '0600',
  }

  file { "${jira::webappdir}/conf/context.xml":
    content => epp("${module_name}/context.xml.epp"),
    mode    => '0600',
  }

  file { "${jira::homedir}/jira-config.properties":
    content => inline_epp(@(EOF)
        <% $merged_jira_config_properties.each |$key, $val| { -%>
        <%= $key %> = <%= $val %>
        <%- } -%>
        | EOF
    ),
    mode    => '0600',
  }

  if $jira::datacenter {
    file { "${jira::homedir}/cluster.properties":
      content => epp("${module_name}/cluster.properties.epp"),
      mode    => '0600',
    }
  }
}
