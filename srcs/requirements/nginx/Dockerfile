FROM alpine:latest
# --no-cache so our image could be light 
RUN apk add --no-cache nginx openssl
# setting a dirrectory 
RUN mkdir -p /etc/nginx/ssl

# 1. Generate the Certss
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/self-signed.key \
    -out /etc/nginx/ssl/self-signed.crt \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"

# 2. COPY your config file into the image
# This is crucial. The volume will copy this file when it is created.
COPY conf/default.conf /etc/nginx/http.d/default.conf

# 3. COPY your HTML file (optional, to pre-fill the volume)
# COPY data/html/index.html /usr/share/nginx/html/index.html
# this for container in the same nethwork to be able to comminicate with the server
EXPOSE 80 443
# we need this CMD cuz nginx by default run in the daemon , we have to disable that cuz if we dont Docker by default 
# kill container if there is no process runing in the forground
CMD ["nginx", "-g", "daemon off;"]
