FROM alpine:latest 

RUN apk update && apk add --no-cache \
    php83 \
    php83-fpm \
    php83-mysqli \
    php83-json \
    php83-dom \
    php83-mbstring \
    php83-openssl \
    php83-xml \
    php83-phar \
    php83-session \
    wget \
    bash 

RUN mkdir -p /var/www/html && \
    wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp && \
    ln -s /usr/bin/php83 /usr/bin/php
    # in alpine to use the php version u want u need a symlink it with the /usr/bin/php 
    # symlink between the php83 and the /php cuz wp-cli looks for /usr/bin/php
    # so the wp-cli /usr/bin/php83 

    
COPY conf/www.conf /etc/php83/php-fpm.d/www.conf
# COPY tools/wordpress-entrypoint.sh /usr/local/bin/

# RUN chmod +x /usr/local/bin/wordpress-entrypoint.sh

WORKDIR /var/www/html

EXPOSE 9000

# ENTRYPOINT ["/usr/local/bin/wordpress-entrypoint.sh"]
CMD ["php-fpm83", "-F"]