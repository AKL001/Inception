```bash
FROM alpine:3.23

RUN apk update && apk add --no-cache redis 

# ==============================================================================
# NETWORKING
# ==============================================================================
# Informs Docker that the container listens on network port 6379 at runtime.
# Note: This does NOT publish the port to your host machine; it acts as 
# documentation and allows communication on internal Docker networks.
EXPOSE 6379

# ==============================================================================
# PRODUCTION CONSIDERATIONS (READ BEFORE DEPLOYING LIVE)
# ==============================================================================
# ⚠️ WARNING FOR PRODUCTION USE:
# Running Redis with '--protected-mode no' and NO password is highly insecure
# if your Docker networks are misconfigured or exposed to the public internet.
#
# To secure this for a production environment, follow these steps instead:
#
# 1. Force Redis to require a password by changing the CMD below to include:
#    "--requirepass YOUR_STRONG_SECRET_PASSWORD"
#
# 2. Re-enable protected mode by removing "--protected-mode no".
#    When a password is required, protected mode can safely remain enabled.
#
# 3. Update your WordPress 'wp-config.php' to authenticate with Redis:
#    define('WP_REDIS_PASSWORD', 'YOUR_STRONG_SECRET_PASSWORD');
#
# 4. (Optional but recommended) Limit memory usage to prevent Redis from crashing 
#    your server if your cache grows uncontrollably. Add these flags to CMD:
#    "--maxmemory 256mb --maxmemory-policy allkeys-lru"
# ==============================================================================

# ==============================================================================
# CONTAINER STARTUP COMMAND
# ==============================================================================
# Executes the Redis server when the container starts.
#
# '--bind 0.0.0.0': Forces Redis to listen to connections on ALL network 
#   interfaces. This is mandatory in Docker so your WordPress container can 
#   reach Redis across the virtual bridge network ('inc_net').
#
# '--protected-mode no': Disables Redis protection rules. This allows 
#   unauthenticated connections from other internal containers. 
#   (Fine for testing, but must be paired with '--requirepass' in production!)
CMD ["redis-server", "--bind", "0.0.0.0", "--protected-mode", "no"]
```