# varnish::varnishncsa
#
# This class is meant to be called from varnish class
# Configure Varnishncsa logging daemon
#
class varnish::varnishncsa (
  Optional[String] $logformat,
  Boolean $enabled,
) {

  service { 'varnishncsa':
    ensure => $enabled,
    enable => $enabled,
  }

  notify { 'logformat':
    message => $logformat,
  }
}
