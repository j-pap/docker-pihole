FROM pihole/pihole:latest
RUN apk add --no-cache \
    dns-root-hints \
    keepalived \
    openrc \
    stubby \
    unbound \
    cloudflared --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing

COPY configs /tmp/configs/
COPY --chmod=0755 custom-start.sh /usr/bin/custom-start.sh

ENTRYPOINT ["custom-start.sh"]
