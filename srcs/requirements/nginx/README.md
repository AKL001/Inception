# NGINX + HTTPS / TLS Deep Dive

> A practical guide to understanding TLS 1.2 vs 1.3, why SSL is dead, and how NGINX enforces secure communication.

---

## Table of Contents

- [Why TLS and Not SSL?](#why-tls-and-not-ssl)
- [Encryption Basics: Asymmetric vs Symmetric](#encryption-basics-asymmetric-vs-symmetric)
- [TLS 1.2 Handshake](#tls-12-handshake)
- [TLS 1.3 Handshake](#tls-13-handshake)
- [TLS 1.2 vs TLS 1.3 — Side by Side](#tls-12-vs-tls-13--side-by-side)
- [NGINX Overview](#nginx-overview)
- [NGINX Configuration — Enforcing TLS](#nginx-configuration--enforcing-tls)
- [Dockerfile — Building the NGINX + TLS Image](#dockerfile--building-the-nginx--tls-image)

---

## Why TLS and Not SSL?

**SSL (Secure Sockets Layer)** is the original protocol for encrypting web traffic. **TLS (Transport Layer Security)** is its modern, fully redesigned replacement. Despite this, many people still say "SSL" out of habit when they actually mean TLS.

SSL was retired for good reasons:

| Protocol | Status | Reason |
|---|---|---|
| SSLv2 | ❌ Broken | Fundamental design flaws |
| SSLv3 | ❌ Broken | POODLE attack (2014) |
| TLS 1.0 | ❌ Deprecated | BEAST attack, weak ciphers |
| TLS 1.1 | ❌ Deprecated | No longer considered secure |
| **TLS 1.2** | ✅ Supported | Strong, widely compatible |
| **TLS 1.3** | ✅ Current standard | Fastest, most secure |

> Modern browsers and servers **require TLS 1.2 at minimum**. TLS 1.3 is the current gold standard.

---

## Encryption Basics: Asymmetric vs Symmetric

TLS uses **two types of encryption** at different stages of the connection. Understanding why requires understanding what each one is good at.

### Asymmetric Encryption (used during the handshake)

Uses a **key pair** — a public key and a private key:

```
Public key  → anyone can have it, shared openly
Private key → only the owner holds it, never shared
```

- What you encrypt with the public key, only the private key can decrypt
- Mathematically secure but **slow** — not practical for large amounts of data
- Used for: **authentication** and **key exchange**

### Symmetric Encryption (used for actual data)

Uses a **single shared secret key** on both sides:

```
Same key → encrypts on one side, decrypts on the other
```

- Much **faster** than asymmetric
- The challenge: how do both sides agree on the same key without a hacker intercepting it?
- That's exactly what the TLS handshake solves

```
Handshake  →  asymmetric crypto  →  agree on a shared key
Data flow  →  symmetric crypto   →  fast encrypted communication
```

---

## TLS 1.2 Handshake

The TLS 1.2 handshake takes **2 round trips (2 RTTs)** before any application data flows.

### Phase 1 — Authentication

```
Client                                        Server
  │                                              │
  │──── Client Hello ───────────────────────────▶│
  │     (supported TLS versions, cipher suites,  │
  │      client_random)                          │
  │                                              │
  │◀─── Server Hello + Certificate ─────────────│
  │     (chosen cipher suite, server_random,     │
  │      digital certificate)                    │
  │                                              │
  │◀─── Server Hello Done ──────────────────────│
  │                                              │
  │   [client verifies the certificate locally]  │
```

**What is the certificate?**

The certificate is a signed document issued by a trusted **Certificate Authority (CA)**. It contains:

- The server's **public key**
- The server's **identity** (domain name, organization)
- The **CA's digital signature** — a hash of the certificate encrypted with the CA's private key
- Validity period (expiry date)

**How does the client verify it? (no network call to CA)**

```
1. The client OS/browser ships with a built-in list of trusted CA public keys
   → this is called the "trust store"

2. Client decrypts the certificate's digital signature
   using the CA's public key from the trust store

3. Client hashes the certificate content itself

4. Compares both hashes — if they match → certificate is authentic ✅

5. Also checks: is it expired? Is the domain name correct?
```

> ⚠️ **Important:** Authentication does NOT happen at the end of the handshake. It happens here in Phase 1 when the certificate is verified. The "Finished" messages later are just a checksum on the handshake itself — not identity verification.

---

### Phase 2 — Key Exchange (Diffie-Hellman)

```
Client                                        Server
  │                                              │
  │──── Client Key Exchange (DH public value) ──▶│
  │                                              │
  │   [both sides independently compute the      │
  │    same pre-master secret — math of DH]      │
  │                                              │
  │──── Change Cipher Spec + Finished ──────────▶│
  │◀─── Change Cipher Spec + Finished ───────────│
  │                                              │
  │◀══════════ Encrypted App Data ══════════════▶│
```

**How Diffie-Hellman works (simplified):**

Both sides exchange DH public values over the wire. Even if a hacker intercepts them, they cannot compute the shared secret without the private values that never left each machine. Both sides independently arrive at the **same number** — the pre-master secret.

**Session Key Derivation:**

```
pre-master secret + client_random + server_random
                         ↓
              symmetric session key (master secret)
```

**What is the session key's job?**

Purely **data confidentiality**. Every HTTP request and response — HTML, JSON, cookies, passwords — is encrypted with this key on one side and decrypted with the same key on the other. Nothing more, nothing less.

---

## TLS 1.3 Handshake

TLS 1.3 reduces the handshake to **1 round trip (1 RTT)** — and supports **0-RTT** for returning clients.

```
Client                                        Server
  │                                              │
  │──── Client Hello + DH Key Share ────────────▶│
  │     (cipher suites, client_random,           │
  │      DH public value sent immediately)       │
  │                                              │
  │◀─── Server Hello + DH Share                  │
  │     + Certificate + Finished (encrypted) ────│
  │     (all in one flight, already encrypted)   │
  │                                              │
  │──── Client Finished ────────────────────────▶│
  │                                              │
  │◀══════════ Encrypted App Data ══════════════▶│
```

**Why is TLS 1.3 faster?**

In TLS 1.2, the client waited for the server to confirm the cipher suite before sending DH parameters — that's the extra round trip. In TLS 1.3, the client **guesses** the cipher suite and sends the DH key share immediately. In practice, the guess is almost always correct.

### Forward Secrecy

TLS 1.3 mandates **ephemeral Diffie-Hellman (ECDHE)** — a brand new temporary key pair is generated for every single session:

```
Session 1 → key pair A → session key X  → discarded ✗
Session 2 → key pair B → session key Y  → discarded ✗
Session 3 → key pair C → session key Z  → discarded ✗
```

Even if an attacker records all your encrypted traffic today and later steals the server's private key — they still cannot decrypt past sessions. Each session key is gone forever.

> TLS 1.2 made forward secrecy **optional**. TLS 1.3 makes it **mandatory**.

---

## TLS 1.2 vs TLS 1.3 — Side by Side

| Feature | TLS 1.2 | TLS 1.3 |
|---|---|---|
| Round trips to connect | **2 RTTs** | **1 RTT** |
| Resumption (returning clients) | Session tickets | **0-RTT** possible |
| Key exchange | RSA or DH (static allowed) | **ECDHE only** (always ephemeral) |
| Forward secrecy | Optional | **Mandatory** |
| Cipher suites | Many (some weak) | Only modern, strong ones |
| Certificate during handshake | ❌ Sent in plaintext | ✅ Encrypted |
| Authentication timing | Phase 1 (cert check) | Integrated into key exchange |

---

## NGINX Overview

NGINX is a high-performance, event-driven web server. It is commonly used as:

```
┌─────────────────────────────────────────────────────────┐
│                     NGINX Functions                     │
├───────────────────┬─────────────────────────────────────┤
│  Web Server       │ Serves static files, HTML, assets   │
│  Reverse Proxy    │ Forwards requests to backend apps   │
│  Load Balancer    │ Distributes traffic across servers  │
│  Cache Server     │ Stores responses to reduce load     │
│  Mail Proxy       │ Handles IMAP, POP3, SMTP            │
└───────────────────┴─────────────────────────────────────┘
```

### How NGINX Handles Requests

Traditional servers spin up **one thread per request**. Under heavy load, this exhausts system resources fast.

NGINX uses an **event-driven, asynchronous** model instead:

```
Traditional (thread-per-request):
  Request 1 → Thread 1  (blocked, waiting for disk/network I/O)
  Request 2 → Thread 2  (blocked, waiting...)
  Request 3 → Thread 3  (blocked, waiting...)
  ...1000 requests = 1000 threads = RAM exhausted

NGINX (event-driven):
  Worker Process 1 → handles thousands of connections
                      never blocks — registers I/O events and moves on
  Worker Process 2 → same
  (only a handful of workers needed for massive traffic)
```

NGINX configuration lives in plain text files at `/etc/nginx/nginx.conf`, using **server blocks** and **location blocks** to control behavior.

---

## NGINX Configuration — Enforcing TLS

`default.conf`:

```nginx
# ─────────────────────────────────────────────────────────
# HTTPS Server Block — port 443
# ─────────────────────────────────────────────────────────
server {
    listen 443 ssl;
    server_name localhost;

    # Certificate and private key paths
    # (generated inside the image via Dockerfile for this demo)
    ssl_certificate     /etc/nginx/ssl/self-signed.crt;
    ssl_certificate_key /etc/nginx/ssl/self-signed.key;

    # ── Protocol Enforcement ──────────────────────────────
    # Only allow TLS 1.2 and 1.3.
    # This explicitly blocks SSLv3, TLS 1.0, and TLS 1.1.
    ssl_protocols TLSv1.2 TLSv1.3;

    # ── Cipher Suites ─────────────────────────────────────
    # HIGH     → only strong cipher suites
    # !aNULL   → reject anonymous ciphers (no server authentication)
    # !MD5     → reject MD5-based ciphers (cryptographically broken)
    ssl_ciphers HIGH:!aNULL:!MD5;

    # ── Session Caching (Performance) ─────────────────────
    # Avoids a full handshake for returning clients within the timeout window.
    # shared:SSL:10m → 10MB of shared memory across worker processes
    ssl_session_cache   shared:SSL:10m;
    ssl_session_timeout 10m;

    location / {
        return 200 'Hello! This traffic is secured with TLS 1.2 or 1.3.';
        add_header Content-Type text/plain;
    }
}

# ─────────────────────────────────────────────────────────
# HTTP Server Block — port 80
# Redirect all plain HTTP traffic to HTTPS permanently
# ─────────────────────────────────────────────────────────
server {
    listen 80;
    listen [::]:80;
    server_name localhost;

    # 301 = permanent redirect
    return 301 https://$host$request_uri;
}
```

---

## Dockerfile — Building the NGINX + TLS Image

```dockerfile
# ── 1. Base Image ─────────────────────────────────────────────────────────────
# Alpine Linux: minimal footprint (~5MB), reduced attack surface.
FROM alpine:latest

# ── 2. Install Dependencies ───────────────────────────────────────────────────
# --no-cache: skip storing the package index → keeps image size small
RUN apk add --no-cache nginx openssl

# ── 3. Create Certificate Directory ──────────────────────────────────────────
RUN mkdir -p /etc/nginx/ssl

# ── 4. Generate Self-Signed Certificate ──────────────────────────────────────
# For demo/development only.
# In production: mount real certificates from the host using a Docker volume,
# or use a certificate manager like Certbot or cert-manager (Kubernetes).
#
# Flag breakdown:
#   req -x509        → generate a self-signed cert (no CA needed)
#   -nodes           → "no DES": do NOT encrypt the private key with a passphrase
#                      needed for automated startup — no human to type a password
#   -days 365        → certificate valid for 1 year
#   -newkey rsa:2048 → generate a new RSA key pair, 2048-bit size
#   -keyout          → path to write the private key
#   -out             → path to write the certificate
#   -subj            → skip interactive prompts, set CN (Common Name) inline
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/self-signed.key \
    -out    /etc/nginx/ssl/self-signed.crt \
    -subj   "/CN=localhost"

# ── 5. Copy NGINX Configuration ───────────────────────────────────────────────
# On Alpine, NGINX reads from /etc/nginx/http.d/ (not /etc/nginx/conf.d/)
COPY default.conf /etc/nginx/http.d/default.conf

# ── 6. Expose Ports ───────────────────────────────────────────────────────────
EXPOSE 80 443

# ── 7. Start NGINX ────────────────────────────────────────────────────────────
# "daemon off" keeps NGINX running in the foreground.
# Without it, NGINX would daemonize (background itself) and Docker would
# think the container exited immediately.
CMD ["nginx", "-g", "daemon off;"]
```

> **Note on `-nodes` and production:** Without a passphrase, anyone who copies the `.key` file has it — no further protection. In production, private keys should be mounted at runtime (not baked into the image), tightly access-controlled, and ideally managed by a secrets manager.

---

## Quick Reference

```
HTTP (port 80)
    └── NGINX 301 redirect
            └── HTTPS (port 443)
                    └── TLS Handshake
                            ├── Certificate verification  (authentication)
                            ├── Diffie-Hellman exchange   (key agreement)
                            └── Session key derived       (symmetric encryption)
                                    └── Encrypted application data flows
```