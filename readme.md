# Venus OS Addons Documentation

User documentation for Venus OS add-ons, including overview, installation, usage, and hardware references where applicable.

Use this page as a navigation hub:

1. Start with an add-on **Overview** page.
2. Follow the **Installing** guide (if available).
3. Continue to **Using** and **Hardware** sections for setup details and daily operation.

## Quick Start

If you are new to this repository:

1. Install and open Opkg Manager.
2. Add or verify your package feed.
3. Install the add-on you want to use.
4. Open that add-on's **Using** page for configuration steps.

## Addon Documentation

| Add-on | Summary | Overview | Installing | Using | Hardware |
|---|---|---|---|---|---|
| Opkg Manager | Package/feed manager and USB serial device installer for Venus OS add-ons. | [Overview](docs/user/opkg-manager-overview.md) | [Installing](docs/user/opkg-manager-installing.md) | [Using](docs/user/opkg-manager-usage.md) | - |
| Themer | UI theme customization add-on for Venus OS. | [Overview](docs/user/themer-overview.md) | - | [Using](docs/user/themer-usage.md) | - |
| Inetbox | RV control integration for supported Inetbox hardware. | [Overview](docs/user/inetbox-overview.md) | [Installing](docs/user/inetbox-installing.md) | [Using](docs/user/inetbox-usage.md) | [Hardware](docs/user/inetbox-hardware.md) |
| Ne Shunt (Nordelettronica shunt) | Integration for supported Nordelettronica shunt devices. | [Overview](docs/user/ne-shunt-overview.md) | [Installing](docs/user/ne-shunt-installing.md) | [Using](docs/user/ne-shunt-usage.md) | [Hardware](docs/user/ne-shunt-hardware.md) |
| Network GPS | Network-based GPS data integration. | [Overview](docs/user/network-gps-overview.md) | - | - | [Hardware](docs/user/network-gps-hardware.md) |
| Mount Shares | Mount and use remote network shares from Venus OS. | [Overview](docs/user/mount-shares-overview.md) | - | [Using](docs/user/mount-shares-usage.md) | - |
| Node Red | Node-RED integration and workflow support. | [Overview](docs/user/node-red-overview.md) | [Installing](docs/user/node-red-installing.md) | [Using](docs/user/node-red-usage.md) | - |

## Notes

* Some add-ons require specific hardware and are not useful without compatible devices.
* Installing steps and behavior can vary by Venus OS version.
* Prefer release feeds on production systems; use development feeds only for testing.