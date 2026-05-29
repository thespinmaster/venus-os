# Opkg Manager Overview

The Opkg Manager allows end users to install `opkg` packages (add-ons) on Venus OS without needing to use more complex SSH shell commands. It also allows users to add custom feeds (sources) for add-ons created by third parties.

![Opkg Manager main menu screenshot](images/opkg-manager-main-menu-screenshot.png "Opkg Manager Main Menu")

## What is Opkg?
Opkg (Open Package Management) is a compact package manager built for embedded Linux environments and Internet of Things (IoT) devices. Widely used in platforms such as OpenWrt routers, smart home controllers, and Yocto-based distributions, it provides functionality comparable to apt while maintaining a minimal memory footprint. Opkg comes pre-installed with Venus OS.

## USB Serial Device Installer
In addition to installing add-ons, the Opkg Manager also supports installing USB serial devices and services.

After selecting the service to use and connecting a USB device, the installer detects the device and starts the appropriate service.

## Menu Customization

Provides add-ons with the ability to add, remove, and reposition existing menus in Venus OS without patching files. This is explained in more detail in the developer documentation, as it is transparent to the end user.

## Overview Page Customization
Provides add-ons with the ability to add, remove, or replace overview pages without patching files. This is also explained in more detail in the developer documentation, as it is transparent to the end user.

## New Firmware Updates
When a new Venus OS firmware version is installed, the Opkg Manager automatically downloads and reinstalls previously installed packages.

# 
#### Next - [Installing](opkg-manager-installing.md)