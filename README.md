# Pi-hole Docker Image
This image integrates Unbound (using cloudflared and stubby for DoH/DoT) as
the upstream DNS server and Keepalived for high-availability.

The image will automatically create the DNS configs located in '/configs' if
existing configs are not found. Feel free to modify or replace with your own.
Just make sure to keep the naming conventions:

- cloudflared.yml
- keepalived.conf
- stubby.yml
- unbound.conf

## Recommended Variables / Paths

| Variable | Value | Description |
| -------- | ----- | ---------- |
| `FTLCONF_dns_cache_size` | `0` | Rely upon Unbound's caching |
| `FTLCONF_dns_upstreams` | `127.0.0.1#5335` | Set the upstream to Unbound |

| Path | Value | Description |
| ---- | ----- | ----------- |
| `./pihole/configs` | `/configs` | Various customized DNS settings |

## Docker Compose
```yml
services:
  pihole:
    container_name: pihole
    image: ghcr.io/j-pap/docker-pi-hole:latest
    hostname: pihole
    ports:
      # DNS Ports
      - "53:53/tcp"
      - "53:53/udp"
      # Default HTTP Port
      - "80:80/tcp"
      # Default HTTPs Port. FTL will generate a self-signed certificate
      - "443:443/tcp"
      # Uncomment the line below if you are using Pi-hole as your DHCP server
      #- "67:67/udp"
      # Uncomment the line below if you are using Pi-hole as your NTP server
      #- "123:123/udp"
    environment:
      # Set the appropriate timezone for your location (https://en.wikipedia.org/wiki/List_of_tz_database_time_zones), e.g:
      TZ: 'Europe/London'
      # If using Docker's default `bridge` network setting the dns listening mode should be set to 'all'
      FTLCONF_dns_listeningMode: 'all'
      # Set a password to access the web interface. Not setting one will result in a random password being assigned
      FTLCONF_webserver_api_password: 'correct horse battery staple'
      # Setting to 0 to increase Unbound speed
      FTLCONF_dns_cache_size: '0'
      # Set upstream to Unbound IP/Port
      FTLCONF_dns_upstreams: '127.0.0.1#5335'
      FTLCONF_misc_etc_dnsmasq_d: 'true'
      # Comment out the two lines below if you are using Pi-hole as your NTP server
      FTLCONF_ntp_ipv4_active: 'false'
      FTLCONF_ntp_ipv6_active: 'false'
    # Volumes store your data between container upgrades
    volumes:
      # For persisting Pi-hole's databases and common configuration file
      - './pihole/etc-pihole:/etc/pihole'
      # Config directory for DNS services
      - './pihole/configs:/configs'
      # Uncomment the below if you have custom dnsmasq config files that you want to persist. Not needed for most starting fresh with Pi-hole v6. If you're upgrading from v5 you and have used this directory before, you should keep it enabled for the first v6 container start to allow for a complete migration. It can be removed afterwards. Needs environment variable FTLCONF_misc_etc_dnsmasq_d: 'true'
      - './pihole/etc-dnsmasq.d:/etc/dnsmasq.d'
    cap_add:
      # See https://github.com/pi-hole/docker-pi-hole#note-on-capabilities
      # Required if you are using Pi-hole as your DHCP server, else not needed
      #- NET_ADMIN
      # Required if you are using Pi-hole as your NTP client to be able to set the host's system time
      #- SYS_TIME
      # Optional, if Pi-hole should get some more processing time
      - SYS_NICE
    restart: unless-stopped
```

## Docker command
```bash
docker run
  --name='pihole'
  --net='br0'
  --ip='192.168.0.2'
  -e TZ="Europe/London"
  -e 'TCP_PORT_80'='80'
  -e 'TCP_PORT_443'='443'
  -e 'TCP_PORT_53'='53'
  -e 'UDP_PORT_53'='53'
  -e 'FTLCONF_dns_listeningMode'='all'
  -e 'FTLCONF_webserver_api_password'='correct horse battery staple'
  -e 'FTLCONF_dns_cache_size'='0'
  -e 'FTLCONF_dns_upstreams'='127.0.0.1#5335'
  -e 'FTLCONF_misc_etc_dnsmasq_d'='true'
  -e 'FTLCONF_ntp_ipv4_active'='false'
  -e 'FTLCONF_ntp_ipv6_active'='false'
  -v './pihole/etc-pihole':'/etc/pihole':'rw'
  -v './pihole/configs':'/configs':'rw'
  -v './pihole/etc-dnsmasq.d':'/etc/dnsmasq.d':'rw'
  --hostname=pihole
  --restart=unless-stopped
  --cap-add=SYS_NICE 'ghcr.io/j-pap/docker-pi-hole:latest'
```
