#!/bin/bash
# Hide cgroup log errors
sed -i '306 s|cgroup_add_service|#cgroup_add_service|' /usr/libexec/rc/sh/openrc-run.sh
# Initialize openrc softlevel parameter
install -m755 -d /run/openrc && touch /run/openrc/softlevel

function check_config() {
    [ ! -f /configs/"$1" ] && install -Tm0755 /tmp/configs/"$1" /configs/"$1"
}

function setup_srvc() {
    rc-service "$1" stop
    rc-update add "$1"
    rc-service "$1" start
}

# Check for configs volume - otherwise, create it
[ ! -d /configs ] && install -Dm0775 -d /configs

# Keepalived
check_config keepalived.conf
sed -i 's|#cfgfile="/etc/keepalived/keepalived.conf"|cfgfile="/configs/keepalived.conf"|' /etc/conf.d/keepalived
setup_srvc keepalived

# Cloudflared
# Update testing release to latest
ARCH="$(apk --print-arch)"
case "$ARCH" in
    aarch64 | arm64)
        CF_PKG="arm64" ;;
    amd64 | x86_64)
        CF_PKG="amd64" ;;
esac
if [ -n "$CF_PKG" ]; then
    wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-"$CF_PKG" -O /usr/bin/cloudflared \
    && chmod +x /usr/bin/cloudflared
fi
check_config cloudflared.yml
sed -i 's|command_args="tunnel --config /etc/cloudflared/config.yml run"|command_args="--config /configs/cloudflared.yml"|' /etc/conf.d/cloudflared
setup_srvc cloudflared

# Stubby
check_config stubby.yml
sed -i 's|command_args="$command_args -C /etc/stubby/stubby.yml"|command_args="$command_args -C /configs/stubby.yml"|' /etc/init.d/stubby
setup_srvc stubby

# Update hints for Unbound - "/usr/share/dns-root-hints/named.root"
update-dns-root-hints

# Unbound
[ ! -f /var/log/unbound/unbound.log ] && install -Dm755 -o unbound -g unbound /dev/null /var/log/unbound/unbound.log && chown -R unbound:unbound /var/log/unbound
check_config unbound.conf
sed -i 's|#cfgfile="/etc/unbound/$RC_SVCNAME.conf"|cfgfile="/configs/unbound.conf"|' /etc/conf.d/unbound
setup_srvc unbound

# Call original Pihole script
exec /usr/bin/start.sh
