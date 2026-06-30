# Venus OS Addons Documentation

User documentation for Venus OS add-ons, including overview, setup, usage, and hardware references where applicable.

Use this page as a navigation hub:

1. Start with an add-on **Overview** page.
2. Follow the **Setup** guide (if available).
3. Continue to **Using** and **Hardware** sections for setup details and daily operation.

## Quick Start

If you are new to this repository:

1. Install and open Opkg Manager.
2. Add or verify your package feed.
3. Install the add-on you want to use.
4. Open that add-on's **Using** page for configuration steps.

## Addon Documentation

| Add-on | Summary | Overview | Hardware | Setup | Usage |
|--------|----------|----------|----------|--------|--------|
| Opkg Manager | Package/feed manager and USB serial device installer for Venus OS add-ons. | [Overview](docs/user/opkg-manager-overview.md) | - | [Setup](docs/user/opkg-manager-setup.md) | [Usage](docs/user/opkg-manager-usage.md) |
| Themer | UI theme customization add-on for Venus OS. | [Overview](docs/user/themer-overview.md) | - | - | - |
| Inetbox | RV control integration for supported Inetbox hardware. | [Overview](docs/user/inetbox-overview.md) | [Hardware](docs/user/inetbox-hardware.md) | [Setup](docs/user/inetbox-setup.md) | [Usage](docs/user/inetbox-usage.md) |
| Ne Shunt (Nordelettronica shunt) | Integration for supported Nordelettronica shunt devices. | [Overview](docs/user/ne-shunt-overview.md) | [Hardware](docs/user/ne-shunt-hardware.md) | [Setup](docs/user/ne-shunt-setup.md) | [Usage](docs/user/ne-shunt-usage.md) |
| Network GPS | Network-based GPS data integration. | [Overview](docs/user/network-gps-overview.md) | - | [Setup](docs/user/network-gps-setup.md) | - |
| Mount Shares | Mount and use remote network shares from Venus OS. | [Overview](docs/user/mount-shares-overview.md) | - | - | [Usage](docs/user/mount-shares-usage.md) |
| Solar Divert Relay (to come) | Tiggers a relay on&#124;off, when excess solar is available; or not. | [Overview](docs/user/solar-divert-overview.md) | - | - | - |
| Event Logger | Event Logger captures event streams and writes them to logs. | [Overview](docs/user/event-logger-overview.md) | - | - | - |

## Notes

* Some add-ons require specific hardware and are not useful without compatible devices.
* Setup steps and behavior can vary by Venus OS version.
* Prefer release feeds on production systems; use development feeds only for testing.