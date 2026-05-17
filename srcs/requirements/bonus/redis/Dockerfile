FROM alpine:3.23

RUN apk update && apk add --no-cache redis 

# Expose the default Redis port
EXPOSE 6379

# --bind 0.0.0.0 accepts traffic from the 'inc_net' network
CMD ["redis-server", "--bind", "0.0.0.0", "--protected-mode", "no"]