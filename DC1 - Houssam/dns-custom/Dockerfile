FROM alpine:latest
RUN apk add --no-cache unbound
COPY unbound.conf /etc/unbound/unbound.conf
CMD ["unbound", "-d", "-v"]
