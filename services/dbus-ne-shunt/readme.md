# dbus-ne-shunt-notes

### stop serial-starter (temporary)
```
/opt/victronenergy/serial-starter/stop-tty.sh ttyACM0
```
### serial-starter rules location
```
/etc/udev/rules.d/serial-starter.rules
```

### get serial port info
```
stty -F /dev/ttyACM0
```
### set serial port speed
```
stty -F /dev/ttyACM0 38400
```

### useful links  
https://github.com/victronenergy/venus/wiki/howto-add-a-driver-to-Venus
https://github.com/class142/ne-rs485/blob/master/spec.md
