This is to quickly create virtual host domains for development. It creates the Apache records, A simple PHP web pahe, adds the entry to the hosts file plus database options.
Save file to directory.
```
$ chmod +x vhost.sh
$ sudo ./vhost.sh
```
This was coded to work on a Debian system with Apache & MariaDB. Use at own risk. The database code needs work yet.
