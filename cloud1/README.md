actions:

* provision server
* start an application
* create a 'container' for a deployable application
  - create an apache virtualhost
  - create a database/user
* deploy an application






* create a drupal project:
    makeproj foobar.nemac.org
    sudo dbcreate foobar
    cd /var/vsites/foobar.nemac.org
    drush dl drupal --drupal-project-rename=html   
    cd /var/vsites/foobar.nemac.org/html
    drush site-install standard '--db-url=mysql://foobar:ZW8YtaNz4x@localhost/foobar' \
         --site-name=foobar.nemac.org
    edit sites/default/settings.php:
      - remove the database settings from it (set all values to empty string)
      - append the following line to the end:
           include "../../mysql/foobar.nemac.org-database.php";
