FROM alpine:3.23  

RUN apk update && apk add --no-cache \
    bash \
    wget \
    unzip \
    php83 \
    php83-fpm \
    php83-mysqli \
    php83-pecl-redis \
    php83-json \
    php83-dom \
    php83-mbstring \
    php83-openssl \
    php83-xml \
    php83-phar \
    php83-curl \
    php83-zip \
    php83-zlib \
    php83-tokenizer \
    php83-ctype \
    php83-posix \
    php83-session

RUN mkdir -p /var/www/html && \
    wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp && \
    ln -s /usr/bin/php83 /usr/bin/php
    # in alpine to use the php version u want u need a symlink it with the /usr/bin/php 
    # symlink between the php83 and the /php cuz wp-cli looks for /usr/bin/php
    # so the wp-cli /usr/bin/php83 

    
# Fix PHP memory limit for WP-CLI
RUN echo "memory_limit=512M" > /etc/php83/conf.d/memory-limit.ini

COPY conf/www.conf /etc/php83/php-fpm.d/www.conf

COPY tools/wordpress_entrypoint.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/wordpress_entrypoint.sh

WORKDIR /var/www/html

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/wordpress_entrypoint.sh"]

CMD ["php-fpm83", "-F"]