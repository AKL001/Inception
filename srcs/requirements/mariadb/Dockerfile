FROM alpine:latest

RUN apk update && apk add --no-cache mariadb mariadb-client

# RUN mkdir -p /run/mysqld && chown -R mysql:mysql /run/mysqld \
#     && chmod -R mysql:mysql /var/lib/mysql

COPY conf/mariadb-server.cnf  /etc/my.cnf.d/mariadb-server.cnf

COPY tools/mariadb_entrypoint.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/mariadb_entrypoint.sh

EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/mariadb_entrypoint.sh"]

CMD ["mysqld" , "--user=mysql"]