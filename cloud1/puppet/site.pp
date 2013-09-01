exec { disable_selinux_sysconfig:
    command => '/bin/sed -i "s@^\(SELINUX=\).*@\1disabled@" /etc/selinux/config',
    unless  => '/bin/grep -q "SELINUX=disabled" /etc/selinux/config',
}

exec { 'set-hostname':
    command => '/bin/sed -i "s/HOSTNAME=.*/HOSTNAME=cloud1/" /etc/sysconfig/network',
    unless  => '/bin/grep -q "HOSTNAME=cloud1" /etc/sysconfig/network',
}

exec { 'etc-hosts':
    command => '/bin/echo "127.0.0.1 cloud1" > /etc/hosts',
    unless  => '/bin/grep -q "127.0.0.1 cloud1" /etc/hosts',
}

package { 'emacs-nox':
  ensure => installed
}

package { 'man':
  ensure => installed
}

package { 'wget':
  ensure => installed
}

package { 'git':
  ensure => installed
}

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

class git-server {

  group { "git":
          ensure => present,
          gid => 721
  }

  user { "git":
          ensure => present,
          uid => 721,
          gid => "git",
          require => Group["git"]
  }

  file { "/prod":
    require => User["git"],
    ensure => directory,
    owner  => "git",
    group  => "git",
    mode => 2775
  }

  file { "/git":
    require => User["git"],
    ensure => directory,
    owner  => "git",
    group  => "git",
    mode => 2775
  }

  file { "/home/git":
    ensure => directory,
    owner  => "git",
    group  => "git",
    mode => 0755
  }

  file { "/home/git/.ssh":
    require => File["/home/git"],
    ensure => directory,
    owner  => "git",
    group  => "git",
    mode => 0700
  }

  file { "/home/git/.ssh/authorized_keys":
    require => File["/home/git/.ssh"],
    ensure => present,
    owner  => "git",
    group  => "git",
    mode => 0644
  }

  exec { 'vagrant-user-in-git-goup':
    command => '/bin/grep -q vagrant /etc/passwd && /usr/sbin/usermod -a -G git vagrant',
    unless  => '/bin/grep -q vagrant /etc/passwd && ( /usr/bin/groups vagrant | /bin/grep -q git )'
  }
  exec { 'vagrant-user-in-nappl-goup':
    command => '/bin/grep -q vagrant /etc/passwd && /usr/sbin/usermod -a -G nappl vagrant',
    unless  => '/bin/grep -q vagrant /etc/passwd && ( /usr/bin/groups vagrant | /bin/grep -q nappl )'
  }
  exec { 'etc-hosts-writable-by-nappl-group':
    command => '/bin/grep -q nappl /etc/group && (/bin/chgrp nappl /etc/hosts ; /bin/chmod g+w /etc/hosts)'
  }
  exec { 'vagrant-user-has-mysql-root-access':
    require => Class["mysql::server"],
    command => '/bin/grep -q vagrant /etc/passwd && ( /bin/cp /root/.my.cnf /home/vagrant ; /bin/chown vagrant.vagrant /home/vagrant/.my.cnf )',
    unless => '/bin/grep -q vagrant /etc/passwd && /usr/bin/test -f /home/vagrant/.my.cnf'
  }

}


class apache-vsites-server {

  class { "apache-server": }
  
  file { ["/var/vsites", "/var/vsites/conf", "/var/vsites/mysql"] :
    require => Class["git-server"],
    ensure => directory,
    owner  => "git",
    group  => "git",
    mode => 2775
  }

  file { "/etc/httpd/conf.d/vsites.conf" :
    require => Class["apache-server"],
    ensure => present,
content => "ServerName ${hostname}:80
NameVirtualHost *:80
Include /var/vsites/conf/*.conf
"
  }

  file { "/usr/local/bin/makeproj":
    ensure => present,
    source => "puppet:///files/assets/vsites/makeproj",
    mode => 0755
  }

}

class { "git-server" : }
class { "apache-vsites-server" : }

import 'assets/mysql/password.pp'

class { 'mysql::server':
  config_hash => { 'root_password' => $mysql_root_password }
}

class { 'mysql::php': }

exec { 'secure-mysql-server' :
    require => Class["mysql::server"],
    command => '/usr/bin/mysql --defaults-extra-file=/root/.my.cnf --force mysql < /etc/puppet/files/assets/mysql/secure.sql'
}


class drutils-server {

  package { 'drutils':
    ensure => installed
  }

}

class { 'drutils-server': }

package { 'php':
  ensure => installed,
}

package { 'php-gd':
  ensure => installed,
}

package { 'php-domxml-php4-php5' :
  ensure => installed,
}

# class pear-setup {
#   include pear
#   pear::package { "PEAR": }
#   pear::package { "Console_Table": }
#   pear::package { "drush":
#     repository => "pear.drush.org",
#   }
# }
# 
# class { 'pear-setup' :
#   require => Package["php"]
# }

package { 'php-pear':
  ensure => installed
}

exec { 'install-drush' :
    command => '/usr/bin/pear channel-discover pear.drush.org ; /usr/bin/pear install drush/drush ; cd /usr/share/pear/drush/lib ; /bin/mkdir tmp ; cd tmp ; /bin/tar xfz /etc/puppet/files/assets/drush-dependencies/Console_Table-1.1.3.tgz ; /bin/rm -f package.xml ; /bin/mv Console_Table-1.1.3 .. ; cd .. ; /bin/rm -rf tmp',
    unless => '/usr/bin/test -f /usr/bin/drush'
}

# ########################################################################
# 
# ###   #                  www.billy.org   puppet:///files/www.billy.org.conf
# ###   define line($file, $line, $ensure = 'present') {
# ###       case $ensure {
# ###           default : { err ( "unknown ensure value ${ensure}" ) }
# ###           present: {
# ###               exec { "/bin/echo '${line}' >> '${file}'":
# ###                   unless => "/bin/grep -qFx '${line}' '${file}'"
# ###               }
# ###           }
# ###           absent: {
# ###               exec { "/bin/grep -vFx '${line}' '${file}' | /usr/bin/tee '${file}' > /dev/null 2>&1":
# ###                 onlyif => "/bin/grep -qFx '${line}' '${file}'"
# ###               }
# ###           }
# ###       }
# ###   }
# ###   
# ###   class apache-vhost($vhost_name,    $vhost_source) {
# ###   
# ###     line { "/etc/hosts-${vhost_name}" :
# ###       file => '/etc/hosts',
# ###       line => "127.0.0.1    ${vhost_name}"
# ###     }
# ###   
# ###     file { "/var/${vhost_name}" :
# ###       ensure => directory
# ###     }
# ###   
# ###   #  file { "/var/${vhost_name}/html" :
# ###   #    require => File["/var/${vhost_name}"],
# ###   #    ensure => directory
# ###   #  }
# ###   
# ###     file { "/etc/httpd/conf.d/${vhost_name}.conf" :
# ###       require => [ Package['httpd'], Line["/etc/hosts-${vhost_name}"] ],
# ###       ensure  => file,
# ###       source  => $vhost_source
# ###     }
# ###   
# ###   }
# ###   
# ###   
# ###   class apache-vhost-git($vhost_name, $vhost_source, $git_source) {
# ###   
# ###     class { "apache-vhost" :
# ###       vhost_name   => $vhost_name,
# ###       vhost_source => $vhost_source
# ###     }
# ###   
# ###     package { "git" :
# ###       ensure => present
# ###     }
# ###   
# ###     vcsrepo { $vhost_name:
# ###       require  => Package['git'],
# ###   #   require  => apache-vhost[$vhost_name],
# ###       path     => "/var/www.billy.org/html",
# ###       ensure   => present,
# ###       provider => git,
# ###       source   => $git_source
# ###     }
# ###   
# ###   }
