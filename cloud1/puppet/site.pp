import 'assets/mysql/password.pp'

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

class nappl-server {

  exec { 'vagrant-user-in-git-goup':
    require => Package['drutils'],
    command => '/bin/grep -q vagrant /etc/passwd && /usr/sbin/usermod -a -G git vagrant',
    unless  => '/bin/grep -q vagrant /etc/passwd && ( /usr/bin/groups vagrant | /bin/grep -q git )'
  }
  exec { 'vagrant-user-in-nappl-goup':
    require => Package['drutils'],
    command => '/bin/grep -q vagrant /etc/passwd && /usr/sbin/usermod -a -G nappl vagrant',
    unless  => '/bin/grep -q vagrant /etc/passwd && ( /usr/bin/groups vagrant | /bin/grep -q nappl )'
  }
  exec { 'etc-hosts-writable-by-nappl-group':
    require => Package['drutils'],
    command => '/bin/grep -q nappl /etc/group && (/bin/chgrp nappl /etc/hosts ; /bin/chmod g+w /etc/hosts)'
  }
  exec { 'vagrant-user-has-mysql-root-access':
    require => Class["mysql::server"],
    command => '/bin/grep -q vagrant /etc/passwd && ( /bin/cp /root/.my.cnf /home/vagrant ; /bin/chown vagrant.vagrant /home/vagrant/.my.cnf )',
    unless => '/bin/grep -q vagrant /etc/passwd && /usr/bin/test -f /home/vagrant/.my.cnf'
  }

}

class { "nappl-server" : }
class { "apache-server" : }

class { 'mysql::server':
  config_hash => { 'root_password' => $mysql_root_password }
}

class { 'mysql::php': }

exec { 'secure-mysql-server' :
    require => Class["mysql::server"],
    command => '/usr/bin/mysql --defaults-extra-file=/root/.my.cnf --force mysql < /etc/puppet/files/assets/mysql/secure.sql'
}

package { 'drutils':
  ensure => installed
}

package { 'php':
  ensure => installed,
}

package { 'php-gd':
  ensure => installed,
}

package { 'php-domxml-php4-php5' :
  ensure => installed,
}

package { 'php-pear':
  ensure => installed
}

exec { 'install-drush' :
    command => '/usr/bin/pear channel-discover pear.drush.org ; /usr/bin/pear install drush/drush ; cd /usr/share/pear/drush/lib ; /bin/mkdir tmp ; cd tmp ; /bin/tar xfz /etc/puppet/files/assets/drush-dependencies/Console_Table-1.1.3.tgz ; /bin/rm -f package.xml ; /bin/mv Console_Table-1.1.3 .. ; cd .. ; /bin/rm -rf tmp',
    unless => '/usr/bin/test -f /usr/bin/drush'
}
