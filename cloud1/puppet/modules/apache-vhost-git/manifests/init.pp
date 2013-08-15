class apache-vhost-git($vhost_name, $vhost_source, $git_source) {

  class { "apache-vhost" :
    vhost_name   => $vhost_name,
    vhost_source => $vhost_source
  }

  package { "git" :
    ensure => present
  }

  vcsrepo { $vhost_name:
    require  => Package['git'],
#   require  => apache-vhost[$vhost_name],
    path     => "/var/www.billy.org/html",
    ensure   => present,
    provider => git,
    source   => $git_source
  }

}
