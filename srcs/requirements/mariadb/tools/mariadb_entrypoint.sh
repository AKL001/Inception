#!/bin/sh
set -e
# the /run/mysqld in alpine get deleted each time we reboot the container that's why we add it here and give it the right permession
# the /run/mysqld is where the mariadb add the socket file . we dont actually need this file for the communication betweeen the wordpress and mariadb 
# the socket file is only here so that mariadb dont crash when lanching it 

mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld
# give the right permession for the named volume /var/lib/mysql is where mariadb stored the databases
chown -R mysql:mysql /var/lib/mysql

if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB data directory..."
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql

    mysqld --user=mysql --bootstrap << EOF
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF
fi

echo "Starting MariaDB server..."
exec "$@" # this means run CMD  arguments here , we replace the PID 1 with the mariadb , cuz the PID 1 at first would be the .sh  file configuration and then we  replace it with mariadb PID 