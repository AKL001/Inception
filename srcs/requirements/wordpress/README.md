## php-fpm (FastCGI Process Manager)
 is a PHP interpreter that runs as a separate service/daemon. It manages a pool of worker processes that are ready to execute PHP code. It doesn't compile PHP — it interprets it at runtime.

# The full request flow

Client (Browser)
      ↓  HTTP request
    Nginx
      ↓  "this is a .php file, I can't handle this"
      ↓  forwards via FastCGI protocol (not HTTP)
   PHP-FPM
      ↓  worker process executes the PHP code
      ↓  PHP talks to DB, runs logic, etc.
      ↓  returns the OUTPUT (plain HTML string)
    Nginx
      ↓  takes that HTML string, wraps it in HTTP response
Client (Browser)


# Full  picture

Browser → GET /wp-login.php
              ↓
           Nginx
   matches location ~ \.php$
              ↓
   sends FastCGI request to wordpress:9000
   with params:
     SCRIPT_FILENAME = /var/www/html/wp-login.php
     REQUEST_METHOD  = GET
     QUERY_STRING    = ...
     etc.
              ↓
          PHP-FPM
   finds the file, executes it,
   returns HTML output
              ↓
           Nginx
   wraps it in HTTP response
              ↓
           Browser
