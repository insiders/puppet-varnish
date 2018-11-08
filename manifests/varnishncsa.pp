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

  file { '/etc/systemd/system/varnishncsa.service.d/':
    ensure => 'directory',
  }
  file { '/etc/systemd/system/varnishncsa.service.d/varnishncsa.conf':
    ensure  => 'present',
    content => "[Service]\nExecStart=\nExecStart=/usr/bin/varnishncsa -a -w /var/log/varnish/varnishncsa.log -D -F${logformat}\n"
  }
}
