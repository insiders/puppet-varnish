# == Class: varnish
#
# Configure Varnish proxy cache
#
# === Parameters
#
# [*addrepo*]
#   Whether to add the official Varnish repos
# [*secret*]
#   Varnish secret (used by varnishadm etc).
#   Optional; will be autogenerated if not specified
# [*vcl_conf*]
#   Location of Varnish config file template
# [*listen*]
#   IP address for HTTP to listen on
# [*listen_port*]
#   Port to listen on for HTTP requests
# [*admin_listen*]
#   IP address for admin requests - defaults to 127.0.0.1
# [*admin_port*]
#   Port for Varnish admin to listen on
# [*min_threads*]
#   Varnish minimum thread pool size
# [*max_threads*]
#   Varnish maximum thread pool size
# [*thread_timeout*]
#   Thread timeout
# [*storage_type*]
#   Whether to use malloc (RAM only) or file storage for cache
# [*storage_size*]
#   Size of cache
# [*storage_additional*]
#   Hash of additional storage backends containing strings in the varnish format (passed to -s)
# [*varnish_version*]
#   Major Varnish version to use
# [*vcl_reload*]
#   Script to use to load new Varnish config
# [*package_ensure*]
#   Ensure specific package version for Varnish, eg 3.0.5-1.el6
# [*runtime_params*]
#   Hash of key:value runtime parameters
# @param enabled Whether to enable and start the varnishncsa daemon. Boolean. Default to false.
# @param logformat The log format that varnishncsa should use. Optional String. If not specified the default format will be used, which resembles Apache "combined" log format.
#
class varnish (
  Hash $runtime_params                      = {},
  Boolean $addrepo                          = true,
  String $admin_listen                      = '127.0.0.1',
  Integer $admin_port                       = 6082,
  Variant[String,Array] $listen             = '0.0.0.0',
  Integer $listen_port                      = 6081,
  Optional[String] $secret                  = undef,
  Stdlib::AbsolutePath $secret_file         = '/etc/varnish/secret',
  Stdlib::AbsolutePath $vcl_conf            = '/etc/varnish/default.vcl',
  Enum['file','malloc'] $storage_type       = 'file',
  Stdlib::AbsolutePath $storage_file        = '/var/lib/varnish/varnish_storage.bin',
  String $storage_size                      = '1G',
  Array $storage_additional                 = [],
  Integer $min_threads                      = 50,
  Integer $max_threads                      = 1000,
  Integer $thread_timeout                   = 120,
  Pattern[/^[3-6]\.[0-9]/] $varnish_version = '4.1',
  Optional[String] $instance_name           = undef,
  String $package_ensure                    = 'present',
  String $package_name                      = 'varnish',
  String $service_name                      = 'varnish',
  Optional[String] $vcl_reload_cmd          = undef,
  String $vcl_reload_path                   = $::path,
  Boolean $varnishncsa_enable               = false,
  Optional[String] $varnishncsa_logformat   = '%h %l %u %t "%r" %s %b "%{Referer}i" "%{User-agent}i"',
) {

  if $package_ensure == 'present' {
    $version_major = regsubst($varnish_version, '^(\d+)\.(\d+).*$', '\1')
    $version_minor = regsubst($varnish_version, '^(\d+)\.(\d+).*$', '\2')
    $version_full  = $varnish_version
  } else {
    $version_major = regsubst($package_ensure, '^(\d+)\.(\d+).*$', '\1')
    $version_minor = regsubst($package_ensure, '^(\d+)\.(\d+).*$', '\2')
    $version_full = "${version_major}.${version_minor}"
    if $varnish_version != "${version_major}.${version_minor}" {
      fail("Version mismatch, varnish_version is ${varnish_version}, but package_ensure is ${version_full}")
    }
  }

  include ::varnish::params

  if $vcl_reload_cmd == undef {
    $vcl_reload = $::varnish::params::vcl_reload
  } else {
    $vcl_reload = $vcl_reload_cmd
  }

  if $addrepo {
    class { '::varnish::repo':
      before => Class['::varnish::install'],
    }
  }

  include ::varnish::install


  class { '::varnish::secret':
    secret  => $secret,
    require => Class['::varnish::install'],
  }

  class { '::varnish::config':
    require => Class['::varnish::secret'],
    notify  => Class['::varnish::service'],
  }

  class { '::varnish::service':
    require => Class['::varnish::config'],
  }

  class { '::varnish::varnishncsa':
    enabled   => $varnishncsa_enable,
    logformat => $varnishncsa_logformat,
  }

}
