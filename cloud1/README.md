This directory contains the configuration for the 'cloud1' server, which supports:

* Apache Web Sites
* Drupal Web Sites

In order to start this server, you need to add the following files:

* *aws.yml*: Amazon EC2 credentials file.  The file should have the following form:
  ```
      aws:
        instance_type     : 't1.micro'
        access_key_id     : '<amazon ec2 access key id goes here>'
        secret_access_key : '<amazon ec2 secret access key goes here>'
        keypair_name      : 'keypair1'
        security_groups   : [ 'webserver' ]
        ami               : 'ami-fc314395'
  ```
  
* *keypair1.pem*: keypair file for accessing Amazon server (this file should be named
  according to whatever the value of keypair_name is in aws.yml).   The file should
  have the following form:
  ```
      -----BEGIN RSA PRIVATE KEY-----
      ...
      -----END RSA PRIVATE KEY-----
  ```
  
* *puppet/assets/mysql/password.pp*: Mysql root password file.  This file should
  have the password that will be set for the Mysql 'root' account on the server;
  it should be of the following form:
  ```
    $mysql_root_password = "<mysql root password here>"
  ```
