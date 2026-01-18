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

Download and run dev_setup from github

Adds a opkg feed for installing custom packages from this repository

#### Installs
     Packages to replace BusyBox (so we can remote debug using VS Code)  
     Python 3 (full version)  
     libatomic1 (required by Python 3)  

#### Installs 
     opkg-helpers: A package for installing custom opkg packages on the Venus OS which will automatically get re-installed after firmware updates  
     mount-shares: A package for mounting nfs and cfs shares  

```
wget https://raw.githubusercontent.com/thespinmaster/venus-os/refs/heads/main/tasks/dev-setup -O /data/dev-setup
chmod +x /data/dev-setup
/data/dev-setup

```

In Visual Studio use remote debugging 
root@192.xxx.xxx.xxx  
open remote folder in /data/dev/projects  
may need to remove .env folder from project  
debug code...  






