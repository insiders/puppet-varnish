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

  if $::varnish::params::service_provider == 'systemd' {

    file { '/etc/systemd/system/varnishncsa.service.d/':
      ensure => 'directory',
    }

    file { '/etc/systemd/system/varnishncsa.service.d/varnishncsa.conf':
      ensure  => 'present',
      content => "[Service]\nExecStart=\nExecStart=/usr/bin/varnishncsa -a -w /var/log/varnish/varnishncsa.log -D -F ${logformat}\n",
      require => File['/etc/systemd/system/varnishncsa.service.d/'],
      notify  => Exec['varnishncsa_systemctl_daemon_reload'],
    }

    exec { 'varnishncsa_systemctl_daemon_reload':
      command     => '/bin/systemctl daemon-reload',
      refreshonly => true,
      require     => File['/etc/systemd/system/varnishncsa.service.d/varnishncsa.conf'],
      notify      => Service['varnishncsa'],
    }

  }
}
