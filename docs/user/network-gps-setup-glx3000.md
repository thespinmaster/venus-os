# Network GPS Setup - GL.iNet GL-X3000

This guide is specific to the GL.iNet GL-X3000 (Spitz AX).

Upstream project instructions:
[GLX3000-GPS README](https://github.com/thespinmaster/GLX3000-GPS/blob/main/README.md)

Manufacturer page:
[GL.iNet GL-X3000 Product Page](https://www.gl-inet.com/products/gl-x3000/)

## Prerequisites

* GL.iNet GL-X3000 router.
* Venus OS device (for example, Cerbo GX) on the same reachable network.
* SSH access to the router.

## 1) Router GPS Setup

1. Log in to the GL-X3000 web UI.
2. Enable `gpsd` in the modem/5G settings.
3. In cellular settings, send the AT commands shown in the upstream guide:

```bash
AT+QGPSCFG="autogps",1
AT+QGPS=1
```

4. SSH into the router and install the full `socat` package:

```bash
opkg update
opkg install socat
```

5. Verify GPS output is active:

```bash
cat /dev/mhi_LOOPBACK
```

You should see NMEA messages streaming (for example `$GPGGA`, `$GPRMC`, `$GPGSV`).

## 2) Install Forwarding Service on Router

1. Download and run the installer:

```bash
wget -O gpsdservice-install.sh https://raw.githubusercontent.com/thespinmaster/GLX3000-GPS/refs/heads/main/gpsdservice-install.sh
chmod 755 gpsdservice-install.sh
./gpsdservice-install.sh
```

2. Enter the Venus OS IP address when prompted.
3. Confirm service status:

```bash
service --status-all | grep 'gpsdservice'
```

Optional management commands:

```bash
/etc/init.d/gpsdservice stop
/etc/init.d/gpsdservice disable
```

Update the configured Venus OS IP later if needed:

```bash
uci set gpsdservice.venus.ip=<ip-address>
uci commit gpsdservice
```

## 3) Validate on Venus OS

1. Confirm Venus OS starts receiving NMEA0183 data.
2. Wait a few minutes for GPS location data to appear.
3. Verify position updates in VRM portal tracking views.

---
#### Previous - [Network GPS Setup](network-gps-setup.md)