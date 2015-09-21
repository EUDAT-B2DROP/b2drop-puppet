class b2drop::misc {
  # optimize php
  augeas { "php.ini":
    context => "/files/etc/php.ini/PHP",
    changes => [
      "set default_charset UTF-8",
      "set default_socket_timeout 300",
      "set upload_max_filesize 8G",
      "set post_max_size 8G"
    ];
  }

  # use cron instead of ajax.
  cron { 'owncloud':
    command => "php -f $::owncloud::params::documentroot/cron.php",
    user    => $::owncloud::params::www_user,
    minute  => '*/10'
  }

  # missing libs for centos
  $phpmodules = [ 'php-mysql']
  package { $phpmodules:
    ensure => 'installed',
  }

  #configure theme to be used
  file { 'b2drop_theme_config':
    path    => "${::owncloud::params::documentroot}/config/b2drop.config.php",
    content => '<?php
$CONFIG = array (
  \'theme\' => \'b2drop\',
);
',
  }

  if $::operatingsystem == CentOS {
    selinux::fcontext{ 'owncloud_docroot_httpd_context':
      context  => "httpd_sys_rw_content_t",
      pathname => "${::owncloud::datadirectory}(/.*)?",
      notify   => Exec['owncloud_set_docroot_httpd_context'],
      require  => File["${::owncloud::datadirectory}"]
    }
    exec{ 'owncloud_set_docroot_httpd_context':
      command     => "/sbin/restorecon -Rv ${::owncloud::datadirectory}",
      refreshonly => true,
      require     => File["${::owncloud::datadirectory}"]
    }

    selinux::fcontext{ 'owncloud_config_httpd_context':
      context  => "httpd_sys_rw_content_t",
      pathname => "${::owncloud::params::documentroot}/config(/.*)?",
      notify   => Exec['owncloud_set_config_httpd_context'],
      require  => File["${::owncloud::params::documentroot}"]
    }
    exec{ 'owncloud_set_config_httpd_context':
      command     => "/sbin/restorecon -Rv ${::owncloud::params::documentroot}/config",
      refreshonly => true,
      require     => File["${::owncloud::params::documentroot}"]
    }

    selinux::fcontext{ 'owncloud_apps_httpd_context':
      context  => "httpd_sys_rw_content_t",
      pathname => "${::owncloud::params::documentroot}/apps(/.*)?",
      notify   => Exec['owncloud_set_apps_httpd_context'],
      require  => File["${::owncloud::params::documentroot}"]
    }
    exec{ 'owncloud_set_apps_httpd_context':
      command     => "/sbin/restorecon -Rv ${::owncloud::params::documentroot}/apps",
      refreshonly => true,
      require     => File["${::owncloud::params::documentroot}"]
    }
  }
}