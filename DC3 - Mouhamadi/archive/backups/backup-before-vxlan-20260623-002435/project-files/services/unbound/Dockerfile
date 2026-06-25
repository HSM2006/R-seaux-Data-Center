FROM alpine:latest
RUN apk add --no-cache unbound bind-tools
CMD ["unbound", "-d", "-c", "/etc/unbound/unbound.conf"]
