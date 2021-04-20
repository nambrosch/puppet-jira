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
# == Class: jira
#
# This module is used to install Jira.
#
# See README.md for more details
#
# === Authors
#
# Bryce Johnson
# Merritt Krakowitzer
#
# === Copyright
#
# Copyright (c) 2012 Bryce Johnson
#
# Published under the Apache License, Version 2.0
#
class jira (

  # Jira Settings
  String $version                                                   = '8.13.5',
  String $product                                                   = 'jira',
  Stdlib::Absolutepath $installdir                                  = '/opt/jira',
  Stdlib::Absolutepath $homedir                                     = '/home/jira',
  Boolean $manage_user                                              = true,
  String $user                                                      = 'jira',
  String $group                                                     = 'jira',
  Optional[Integer[0]] $uid                                         = undef,
  Optional[Integer[0]] $gid                                         = undef,
  Stdlib::Absolutepath $shell                                       = '/bin/true',
  # Advanced configuration options
  Boolean $enable_secure_admin_sessions                             = true,
  Hash $jira_config_properties                                      = {},
  Boolean $datacenter                                               = false,
  Optional[Stdlib::AbsolutePath] $shared_homedir                    = undef,
  Optional[Stdlib::Host] $ehcache_listener_host                     = undef,
  Optional[Stdlib::Port] $ehcache_listener_port                     = undef,
  Optional[Stdlib::Port] $ehcache_object_port                       = undef,
  # Database Settings
  Enum['postgresql','mysql','sqlserver','oracle','h2'] $db          = 'postgresql',
  String $dbuser                                                    = 'jiraadm',
  String $dbpassword                                                = 'mypassword',
  String $dbserver                                                  = 'localhost',
  String $dbname                                                    = 'jira',
  Optional[Variant[Integer,String]] $dbport                         = undef,
  Optional[String] $dbdriver                                        = undef,
  Optional[String] $dbtype                                          = undef,
  Optional[String] $dburl                                           = undef,
  Optional[String] $connection_settings                             = undef,
  Boolean $oracle_use_sid                                           = true,
  $dbschema                                                         = undef,
  # MySQL Connector Settings
  Boolean $mysql_connector_manage                                   = true,
  String $mysql_connector_version                                   = '8.0.23',
  String $mysql_connector_product                                   = 'mysql-connector-java',
  String $mysql_connector_format                                    = 'tar.gz',
  Stdlib::Absolutepath $mysql_connector_install                     = '/opt/MySQL-connector',
  Stdlib::HTTPUrl $mysql_connector_url                              = 'https://dev.mysql.com/get/Downloads/Connector-J',
  Optional[Integer[0]] $pool_min_size                               = undef,
  Optional[Integer[0]] $pool_max_size                               = undef,
  Optional[Integer[-1]] $pool_max_wait                              = undef,
  Optional[String] $validation_query                                = undef,
  Optional[Integer[0]] $validation_query_timeout                    = undef,
  Optional[Integer[0]] $min_evictable_idle_time                     = undef,
  Optional[Integer[0]] $time_between_eviction_runs                  = undef,
  Optional[Integer[0]] $pool_max_idle                               = undef,
  Optional[Boolean] $pool_remove_abandoned                          = undef,
  Optional[Integer[0]]  $pool_remove_abandoned_timeout              = undef,
  Optional[Boolean] $pool_test_while_idle                           = undef,
  Optional[Boolean] $pool_test_on_borrow                            = undef,
  # JVM Settings
  Optional[String[1]] $java_package                                 = undef,
  Optional[Stdlib::AbsolutePath] $javahome                          = undef,
  Jira::Jvm_types $jvm_type                                         = 'openjdk-11',
  String $jvm_xms                                                   = '256m',
  String $jvm_xmx                                                   = '1024m',
  Optional[String] $java_opts                                       = undef,
  Optional[String] $jvm_gc_args                                     = undef,
  Optional[String] $jvm_code_cache_args                             = undef,
  Optional[String] $jvm_extra_args                                  = undef,
  Integer $jvm_nofiles_limit                                        = 16384,
  String $catalina_opts                                             = '',
  # Misc Settings
  Stdlib::HTTPUrl $download_url                                     = 'https://product-downloads.atlassian.com/software/jira/downloads',
  Optional[String] $checksum                                        = undef,
  Boolean $disable_notifications                                    = false,
  Optional[String] $proxy_server                                    = undef,
  Optional[Enum['none','http','https','ftp']] $proxy_type           = undef,
  # Manage service
  Boolean $service_manage                                           = true,
  Stdlib::Ensure::Service $service_ensure                           = 'running',
  Boolean $service_enable                                           = true,
  $service_notify                                                   = undef,
  $service_subscribe                                                = undef,
  # Command to stop jira in preparation to upgrade. This is configurable
  # incase the jira service is managed outside of puppet. eg: using the
  # puppetlabs-corosync module: 'crm resource stop jira && sleep 15'
  # Note: the command should return either 0 or  5 
  # when the service doesn't exist
  String $stop_jira                                                 = 'systemctl stop jira.service && sleep 15',
  # Whether to manage the 'check-java.sh' script, and where to retrieve
  # the script from.
  Boolean $script_check_java_manage                                 = false,
  String $script_check_java_template                                = 'jira/check-java.sh.erb',
  # Tomcat
  Optional[String] $tomcat_address                                  = undef,
  Stdlib::Port $tomcat_port                                         = 8080,
  Stdlib::Port $tomcat_shutdown_port                                = 8005,
  Integer $tomcat_max_http_header_size                              = 8192,
  Integer[0] $tomcat_min_spare_threads                              = 25,
  Integer[0] $tomcat_connection_timeout                             = 20000,
  Boolean $tomcat_enable_lookups                                    = false,
  Boolean $tomcat_native_ssl                                        = false,
  Stdlib::Port $tomcat_https_port                                   = 8443,
  Optional[Stdlib::Port] $tomcat_redirect_https_port                = undef,
  String $tomcat_protocol                                           = 'HTTP/1.1',
  Optional[String] $tomcat_protocol_ssl                             = undef,
  Boolean $tomcat_use_body_encoding_for_uri                         = true,
  Boolean $tomcat_disable_upload_timeout                            = true,
  String $tomcat_key_alias                                          = 'jira',
  Stdlib::Absolutepath $tomcat_keystore_file                        = '/home/jira/jira.jks',
  String $tomcat_keystore_pass                                      = 'changeit',
  Enum['JKS', 'JCEKS', 'PKCS12'] $tomcat_keystore_type              = 'JKS',
  String $tomcat_accesslog_format                                   = '%a %{jira.request.id}r %{jira.request.username}r %t &quot;%m %U%q %H&quot; %s %b %D &quot;%{Referer}i&quot; &quot;%{User-Agent}i&quot; &quot;%{jira.request.assession.id}r&quot;',
  Boolean $tomcat_accesslog_enable_xforwarded_for                   = false,
  # Tomcat Tunables
  Integer $tomcat_max_threads                                       = 150,
  Integer $tomcat_accept_count                                      = 100,
  # Reverse https proxy
  Hash $proxy                                                       = {},
  # Options for the AJP connector
  Hash $ajp                                                         = {},
  Boolean $tomcat_default_connector                                 = true,
  # Additional connectors in server.xml
  Jira::Tomcat_connectors $tomcat_additional_connectors             = {},
  # Context path (usualy used in combination with a reverse proxy)
  String $contextpath                                               = '',
  # Resources for context.xml
  Hash $resources                                                   = {},
  # Enable SingleSignOn via Crowd
  Boolean $enable_sso                                               = false,
  String $application_name                                          = 'crowd',
  String $application_password                                      = '1234',
  Variant[Stdlib::HTTPUrl, Stdlib::HTTPSUrl] $application_login_url = 'https://crowd.example.com/console/',
  Variant[Stdlib::HTTPUrl, Stdlib::HTTPSUrl] $crowd_server_url      = 'https://crowd.example.com/services/',
  Variant[Stdlib::HTTPUrl, Stdlib::HTTPSUrl] $crowd_base_url        = 'https://crowd.example.com/',
  String $session_isauthenticated                                   = 'session.isauthenticated',
  String $session_tokenkey                                          = 'session.tokenkey',
  Integer $session_validationinterval                               = 5,
  String $session_lastvalidation                                    = 'session.lastvalidation',
  # Deprecated parameters
  Optional[String] $jvm_permgen                                     = undef,
  Optional[Integer[0]] $poolsize                                    = undef,
  Optional[Boolean] $enable_connection_pooling                      = undef,
) {
  if versioncmp($jira::version, '8.0.0') < 0 {
    fail('JIRA versions older than 8.0.0 are no longer supported. Please use an older version of this module to upgrade first.')
  }

  if $datacenter and !$shared_homedir {
    fail("\$shared_homedir must be set when \$datacenter is true")
  }

  if $jvm_permgen {
    fail('jira::jvm_permgen', 'jira::jvm_permgen has been removed and no longer does anything. Configuring it hasn\'t been supported since JDK 8')
  }

  if $enable_connection_pooling != undef {
    deprecation('jira::enable_connection_pooling', 'jira::enable_connection_pooling has been removed and does nothing. Please simply configure the connection pooling parameters')
  }

  if $tomcat_redirect_https_port {
    unless ($tomcat_native_ssl) {
      fail('You need to set native_ssl to true when using tomcat_redirect_https_port')
    }
  }

  # The default Jira product starting with version 7 is 'jira-software',
  # but some old configuration may explicitly specify 'jira'
  if $product == 'jira' {
    $product_name = 'jira-software'
  } else {
    $product_name = $product
  }

  $webappdir = "${installdir}/atlassian-${product_name}-${version}-standalone"

  if ! empty($ajp) {
    if ! ('port' in $ajp) {
      fail('You need to specify a valid port for the AJP connector.')
    } else {
      assert_type(Variant[Pattern[/^\d+$/], Stdlib::Port], $ajp['port'])
    }
    if ! ('protocol' in $ajp) {
      fail('You need to specify a valid protocol for the AJP connector.')
    } else {
      assert_type(Enum['AJP/1.3', 'org.apache.coyote.ajp', 'org.apache.coyote.ajp.AjpNioProtocol'], $ajp['protocol'])
    }
  }

  if $javahome == undef {
    fail('You need to specify a value for javahome')
  }

  contain jira::install
  contain jira::config
  contain jira::service

  Class['jira::install']
  -> Class['jira::config']
  ~> Class['jira::service']

  if ($enable_sso) {
    class { 'jira::sso': }
  }
}
