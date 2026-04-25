The version of MariaDB in the Alpine repositories behave like the MySQL tarball. No graphical tools are included.

The datadir located at /var/lib/mysql must be owned by the mysql user and group. The location of the datadir can be changed by editing the mariadb service file in /etc/init.d. The new location will also need to be set by adding datadir=<YOUR_DATADIR> in the [mysqld] section in a mariadb configuration file.

MariaDB is trying to put its core communication file (mysqld.sock) inside a folder called /run/mysqld/. But because you are using Alpine Linux, the system completely wipes the /run folder clean every single time the container starts up.

because of that we need to add the folder and grant it the permision to the user. 

we need also the add the mariadb-server.cnf 
```bash 
[mysqld]
user = mysql
port = 3306

datadir = /var/lib/mysql
socket  = /run/mysqld/mysqld.sock

bind-address = 0.0.0.0
skip-networking=0
``` 
so our mariadb can connect with wordpress bysetting the `port` `user` , `datadir` , and for the socket dirr it get deleted after a restart we need to mkdir that dirrectory and tell mariadb where to find that socket file why we need it well 


bind-address: 0.0.0.0 accept any IP adress communication , so we can connect or communicate to any server 

skip-networking: by default MariaDB will not listen for TCP/IP connections at all. All interaction must be through local mechanisms like Unix sockets or named pipes. 
that's why we need to disable it or comment it.



