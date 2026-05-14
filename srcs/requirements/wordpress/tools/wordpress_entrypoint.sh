#!/bin/sh
# if any error happens we exit
set -e

#############################################################################
# we already handle the health check for mariadb in the docker compose file##
#############################################################################

if [ ! -f wp-config.php ]; then
    # we need to allow root cuz by defualt 
    wp core download --allow-root

    # Configure WordPress
    wp config create \
        --dbname=$WORDPRESS_DB_NAME \
        --dbuser=$WORDPRESS_DB_USER \
        --dbpass=$WORDPRESS_DB_PASSWORD \
        --dbhost=$WORDPRESS_DB_HOST \
        --allow-root

    # Install WordPress
    wp core install \
        --url=$WORDPRESS_URL \
        --title=$WORDPRESS_TITLE \
        --admin_user=$WORDPRESS_ADMIN_USER \
        --admin_email=$WORDPRESS_ADMIN_EMAIL \
        --admin_password=$WORDPRESS_ADMIN_PASSWORD \
        --allow-root
    
    # creating user 
    wp user create $WORDPRESS_USER $WORDPRESS_USER_EMAIL \
        --role=author \
        --user_pass=$WORDPRESS_USER_PASSWORD \
        --allow-root
        
fi

exec $@