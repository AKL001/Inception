FROM alpine:latest

RUN apk update && apk add --no-cache mariadb mariadb-client

COPY tools/mariadb_entrypoint.sh /usr/local/bin

RUN chmod +x /usr/local/bin/mariadb_entrypoint.sh

EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/mariadb_entrypoint.sh"]

CMD ["mysqld" , "--user=mysql"]