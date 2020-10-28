# qBittorrent with OpenVPN and Kill Switch

## Jail Setup

The jail should have `allow_tun=1`.

```sh
pkg install \
    qbittorrent-nox \
    openvpn
```

Get config from your VPN provider and save it to: `/usr/local/etc/openvpn/`

```sh
# Test VPN and Kill Switch
/usr/local/etc/rc.d/openvpn stop
wget -qO - http://wtfismyip.com/text

/usr/local/etc/rc.d/openvpn start
wget -qO - http://wtfismyip.com/text
```
