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
### set serial port to read at 38400 8N1 binary data
```
stty -F /dev/ttyAMC0 38400 cs8 -cstopb -parenb -ixon -ixoff -crtscts raw -echo
```
#### Flags explained
- 38400 → baud rate
- cs8 → 8 data bits
- -cstopb → 1 stop bit
- -parenb → no parity
- raw → no line processing (required for binary)
- -ixon -ixoff → disable software flow control
- -crtscts → disable hardware flow control
- -echo → don't echo any data recieved back to device
### read data as hex using od
```
od -An -tx1 -v </dev/ttyACM0
```
#### Flags explained
- -An → no address offsets
- -tx1 → hex, 1 byte at a time
- -v → don’t collapse repeated lines (important for binary)

### useful links  
https://github.com/victronenergy/venus/wiki/howto-add-a-driver-to-Venus
https://github.com/class142/ne-rs485/blob/master/spec.md
