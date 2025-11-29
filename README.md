# Set up the Venus Os for Debugging Python/C++ using Visual Studio Code

## Setup

Use a RaspberryPi 4B
Install Venus OS on sd card 

Set wifi in Venus OS
Use Victron Connect App. Select Rasperry pi, enter bluetooth pin, then connect to wifi
Note if Wifi fails, connect ethernet cable instead and connect wifi using Venus OS GUI

In Venus GUI to enable ssh, elect username then press and hold right arrow key for 5 seconds to enable root access
add ssh password

SSH into Venus OS

### set up dev environment

Download and run dev_setup.sh from github
This creates the standard folders
Adds our gitbug opkg feed for installing custom packages
Installs mount-nfs-cifs package for mounting nfs and cfs shares
Mounts the dev server
Installs package to replace BusyBox (so we can remote debug using VS Code)
Installs Python (full version)
Installs libatomic1
Sets up rc.local and alias files

```
wget https://raw.githubusercontent.com/thespinmaster/venus-os/refs/heads/main/scripts/dev-setup.sh -O /data/dev-setup.sh
chmod +x /data/dev-setup.sh
/data/dev-setup.sh

```

In Visual Studio use remote debugging 
root@192.xxx.xxx.xxx
open remote folder in /data/dev/projects
may need to remove .env folder from project
debug code...



