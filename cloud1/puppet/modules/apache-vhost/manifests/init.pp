#                  www.billy.org   puppet:///files/www.billy.org.conf
define line($file, $line, $ensure = 'present') {
    case $ensure {
        default : { err ( "unknown ensure value ${ensure}" ) }
        present: {
            exec { "/bin/echo '${line}' >> '${file}'":
                unless => "/bin/grep -qFx '${line}' '${file}'"
            }
        }
        absent: {
            exec { "/bin/grep -vFx '${line}' '${file}' | /usr/bin/tee '${file}' > /dev/null 2>&1":
              onlyif => "/bin/grep -qFx '${line}' '${file}'"
            }
        }
    }
}

class apache-vhost($vhost_name,    $vhost_source) {

  line { "/etc/hosts-${vhost_name}" :
    file => '/etc/hosts',
    line => "127.0.0.1    ${vhost_name}"
  }

  file { "/var/${vhost_name}" :
    ensure => directory
  }

#  file { "/var/${vhost_name}/html" :
#    require => File["/var/${vhost_name}"],
#    ensure => directory
#  }

  file { "/etc/httpd/conf.d/${vhost_name}.conf" :
    require => [ Package['httpd'], Line["/etc/hosts-${vhost_name}"] ],
    ensure  => file,
    source  => $vhost_source
  }

}
