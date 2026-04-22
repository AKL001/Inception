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
# -nodes => no des meaning dont use any passphrase for the private key
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    # generating the private key
    -keyout /etc/nginx/ssl/self-signed.key \
    # generating the certificate 
    -out /etc/nginx/ssl/self-signed.crt \
    -subj "/CN=localhost"

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
# HTTPS & TLS Handshake

## Why TLS and Not SSL?

SSL (Secure Sockets Layer) is the predecessor to TLS (Transport Layer Security). SSL had several critical vulnerabilities:
- **SSLv2 and SSLv3** were found to be fundamentally broken (e.g., the POODLE attack on SSLv3).
- SSL uses weaker, outdated cipher suites and hash functions (e.g., MD5, RC4).

TLS is a complete redesign — not just an upgrade. Despite this, many people still say "SSL" colloquially when they actually mean TLS. Modern browsers and servers have **fully deprecated SSL** and require TLS 1.2 at minimum, with TLS 1.3 being the current standard.

---

## How Encryption Works in TLS — Asymmetric vs Symmetric Keys

Both TLS 1.2 and TLS 1.3 use a **combination** of asymmetric and symmetric encryption:

- **Asymmetric encryption** uses a **key pair**: a public key (anyone can see it) and a private key (only the owner holds it). Data encrypted with the public key can only be decrypted with the private key, and vice versa. This is used during the handshake phase for authentication and key exchange.
- **Symmetric encryption** uses a **single shared secret key** for both encryption and decryption. It is much faster than asymmetric encryption and is used to encrypt the actual data once the handshake is complete.

The goal of the handshake is to **authenticate the server** and **negotiate a shared symmetric session key** securely, so that the rest of the communication is fast and encrypted.

---

## TLS 1.2 Handshake

The TLS 1.2 handshake takes **2 round trips** (RTTs) before data can be sent.

### Phase 1 — Authentication (Certificates)

1. **Client Hello** — The client sends a hello message to the server containing:
   - Supported TLS versions
   - Supported cipher suites
   - A random value (`client_random`)

2. **Server Hello + Certificate** — The server responds with:
   - The chosen TLS version and cipher suite
   - Another random value (`server_random`)
   - Its **digital certificate** (commonly called a TLS/SSL certificate, issued by a Certificate Authority)

3. **Server Hello Done** — The server signals it is done with this phase.

### Phase 2 — Key Exchange (Session Key)

This is where both sides derive the **shared symmetric session key** using the **Diffie-Hellman (DH) key exchange**:

4. **Client Key Exchange** — The client and server exchange DH parameters. Each side generates a temporary (ephemeral) key pair. They exchange public values, and through the math of DH, both independently compute the **same shared pre-master secret** — without ever sending the secret over the wire.

5. **Session Key Derivation** — Both sides use the pre-master secret combined with `client_random` and `server_random` to derive the same **symmetric session key** (also called the master secret).

6. **Change Cipher Spec + Finished** — Both sides send a "Finished" message encrypted with the new session key, confirming the handshake succeeded.

From this point on, all communication is encrypted using **symmetric encryption** (e.g., AES-GCM) with the session key.

> **Round trips in TLS 1.2:** 2 RTTs before application data can flow.

---

## TLS 1.3 Handshake

TLS 1.3 is a major improvement over 1.2. It reduces the handshake to **1 round trip (1-RTT)**, and even supports **0-RTT** resumption for returning clients.

### Key Differences from TLS 1.2

| Feature | TLS 1.2 | TLS 1.3 |
|---|---|---|
| Round trips | 2 RTTs | 1 RTT (or 0-RTT resumption) |
| Key exchange | RSA or DH (static possible) | Ephemeral DH only (ECDHE) |
| Cipher suites | Many, some weak | Only strong modern suites |
| Authentication | Separate step | Integrated into key exchange |
| Forward secrecy | Optional | Mandatory |

### How TLS 1.3 Achieves 1-RTT

1. **Client Hello** — The client sends its hello **and immediately includes its DH key share** (instead of waiting for the server to confirm the cipher suite first).

2. **Server Hello + Everything** — The server responds with its DH key share, derives the session key immediately, and sends its **certificate and Finished message — all already encrypted**. Authentication and key exchange happen in one step.

3. **Client Finished** — The client verifies the server's certificate, derives the same session key, and sends its Finished message.

Application data can now flow — in **1 RTT**.

### Forward Secrecy

TLS 1.3 mandates **ephemeral key exchange** (ECDHE), meaning a new temporary key pair is generated for every session. This ensures **forward secrecy**: even if the server's long-term private key is compromised in the future, past sessions cannot be decrypted.

---

## Summary Flow

```
Client                                    Server
  |                                          |
  |-------- Client Hello (+ DH share) ------>|   (TLS 1.3 sends DH here)
  |                                          |
  |<-- Server Hello + Cert + DH + Finished --|
  |                                          |
  |---------- Client Finished ------------->|
  |                                          |
  |<======= Encrypted Application Data =====>|
```

---

## Key Takeaways

- TLS replaced SSL due to critical security flaws in SSL.
- Asymmetric encryption is used to **authenticate** and **exchange keys**; symmetric encryption is used for the **actual data transfer**.
- The CA certificate is verified **locally** using a pre-installed trust store — not by contacting the CA at runtime.
- TLS 1.3 is faster (1 RTT vs 2 RTT) and more secure (mandatory forward secrecy, fewer cipher options).
- The **Diffie-Hellman key exchange** allows both parties to independently derive the same session key without ever transmitting it.


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
