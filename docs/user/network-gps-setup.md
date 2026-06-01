# Network GPS Setup

This page describes the general setup flow for Network GPS.
Hardware-specific steps are documented in separate profile pages so support for additional devices can be added without changing this core guide.

## What You Need

* A device that can output NMEA GPS sentences over the network.
* A Venus OS device (for example, Cerbo GX).
* IP connectivity between the GPS source device and Venus OS (Wi-Fi or Ethernet).

## General Setup Flow

1. Confirm the GPS source device has a valid satellite lock.
2. Verify NMEA sentences are being produced by the source device.
3. Configure forwarding/service on the source device to send NMEA data to Venus OS.
4. Confirm Venus OS receives and recognizes NMEA0183 messages.
5. Wait a few minutes for location and tracking data to appear.

## Hardware Profiles

Use one of the hardware profiles below for detailed device-specific steps.

| Hardware | Setup Guide | Manufacturer |
|---|---|---|
| GL.iNet GL-X3000 (Spitz AX) | [GL-X3000 Setup](network-gps-setup-glx3000.md) | [GL.iNet GL-X3000 Product Page](https://www.gl-inet.com/products/gl-x3000/) |

When adding support for new hardware, create a new `network-gps-setup-<device>.md` page and add it to this table.

---
#### Previous - [Overview](network-gps-overview.md)
#### Next - [GL-X3000 Setup](network-gps-setup-glx3000.md)