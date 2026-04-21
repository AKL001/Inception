First, we need to tell NGINX how to behave. We will create a specific configuration that listens on port 443 (HTTPS) and strictly limits the TLS versions.

in `default.conf`
```bash 
server {
    # Listen on port 443 for SSL/HTTPS traffic
    listen 443 ssl;

    server_name localhost;

    # SSL Certificate locations (we will generate these in the Dockerfile)
    ssl_certificate /etc/nginx/ssl/self-signed.crt;
    ssl_certificate_key /etc/nginx/ssl/self-signed.key;

    # --- SECURITY SETTINGS ---
    # Strictly enforce TLSv1.2 and TLSv1.3. 
    # This disables older, insecure protocols like SSLv3, TLS 1.0, and TLS 1.1.
    ssl_protocols TLSv1.2 TLSv1.3;

    # Optimize SSL cipher suites (Recommended high-security ciphers)
    ssl_ciphers HIGH:!aNULL:!MD5;
    
    # SSL Session settings for performance
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    location / {
        # Return a simple 200 OK text for testing
        return 200 'Hello! This traffic is secured with TLS 1.2 or 1.3.';
        add_header Content-Type text/plain;
    }
}

# Redirect HTTP (port 80) to HTTPS (port 443)
server {
    listen 80;
    listen [::]:80;
    server_name localhost;
    return 301 https://$host$request_uri;
}
```

In Dockerfile 

```bash

# 1. Base Image
# We use Alpine Linux (Stable) for a tiny footprint and reduced attack surface.
FROM alpine:latest

# 3. Installation
# We update the package index and install NGINX and OpenSSL.
# --no-cache ensures we don't store the index, keeping the image small.
RUN apk add --no-cache nginx openssl

# 4. Setup Directories
# Create the directory where we will store the certificates.
RUN mkdir -p /etc/nginx/ssl

# 5. Generate Self-Signed Certificate
# We generate the cert INSIDE the image for this demo.
# In production, you would typically mount these from the host.
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    # generating the private key
    -keyout /etc/nginx/ssl/self-signed.key \
    # generating the certificate 
    -out /etc/nginx/ssl/self-signed.crt \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"

# 6. Configuration
# Copy our custom configuration file from the host into the container.
COPY default.conf /etc/nginx/http.d/default.conf # needs its own volume 

# 7. Ports
# Expose HTTP and HTTPS ports.
EXPOSE 80 443

# 8. Command
# Run NGINX in the foreground so the container doesn't exit immediately.
CMD ["nginx", "-g", "daemon off;"]
```

```bash 
    TLSv1.3

    we need the session key , which secure the connection between the server and client this is achived by the TLSv1.2 and TLSv1.3 

    using the diffie-hellman key exchange

    
```


# about NGINX  :

- NGINX critical functions :
    1) web server : act as a web server
    2) Reverse proxy : can also act or be configurate as a reverse proxy meaning the proxy do request or handle the request , as a middle man between the server and client
    3) load blancer 
    4) chaching server
    5) mail proxy : can handle mail protocols like (IMAP , POP3, SMPT)

- Core Features Nginx offers the following core features:
    High Performance: Nginx is designed to handle high traffic with minimal resource consumption. Its asynchronous, event-driven architecture allows it to manage thousands of concurrent connections efficiently.
    Scalability: Its modular design and support for load balancing enable it to scale horizontally across multiple servers. This makes it suitable for both small sites and large-scale applications.
    Reliability: With built-in features for failover and load balancing, Nginx ensures high availability and reliability for web applications.
    Configurability: Nginx configurations are highly flexible, allowing for fine-tuned control over server behavior, including URL routing, security settings, and caching policies.
    Security: Nginx includes numerous security features such as SSL/TLS support, rate limiting, and denial of service protection to secure web applications from various threats.

- How Nginx Works Nginx uses an event-driven architecture to handle requests. Unlike traditional servers that use a thread-per-request model, Nginx handles requests asynchronously, which allows it to process multiple requests in parallel with minimal resource overhead.
    Event-Driven Architecture: Nginx processes requests using a non-blocking approach. This means that it can handle multiple requests simultaneously without waiting for each request to complete.
    Worker Processes: Nginx operates using worker processes that handle incoming requests. Each worker can manage thousands of connections, thanks to the event-driven model.
    Configuration: Nginx configurations are specified in plain text files, usually located in /etc/nginx/nginx.conf. These configurations allow you to define server blocks, location blocks, and other directives to control how Nginx handles requests.
