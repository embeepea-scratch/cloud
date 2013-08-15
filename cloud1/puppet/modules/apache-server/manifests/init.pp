class apache-server {

  package { 'httpd':
    ensure => 'present'
  }

  service { 'httpd':
    require => Package['httpd'],
    ensure => running,            # this makes sure httpd is running now
    enable => true                # this make sure httpd starts on each boot
  }

  service { 'iptables':
    ensure => stopped,
    enable => false
  }

  service { 'ip6tables':
    ensure => stopped,
    enable => false
  }

}
