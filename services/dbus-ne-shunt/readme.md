# dbus-ne-shunt-notes

### stop serial-starter (temporary)
```
/opt/victronenergy/serial-starter/stop-tty.sh ttyACM0
```
### serial-starter rules location
```
/etc/udev/rules.d/serial-starter.rules
```
Get Serial ID
```
udevadm info --query=property --name=/dev/ttyUSB0 | grep ^ID_SERIAL=
```

Add the result to serial-starter rules (/etc/udev/rules.d/serial-starter.rules)
```
ACTION=="add", ENV{ID_BUS}=="usb", ENV{ID_SERIAL}=="FTDI_FT232R_USB_UART_A5069RR4", ENV{VE_SERVICE}="ignore"
```

### get serial port info
```
stty -F /dev/ttyACM0
```
### set serial port to read at 38400 8N1 binary data
```
stty -F /dev/ttyAMC0 38400 cs8 -cstopb -parenb -ixon -ixoff -crtscts raw -echo
stty -F /dev/ttyUSB0 9600 cs8 -cstopb -parenb -ixon -ixoff -crtscts raw -echo
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
od -An -tx1 -v </dev/ttyUSB0
```
#### Flags explained
- -An → no address offsets
- -tx1 → hex, 1 byte at a time
- -v → don’t collapse repeated lines (important for binary)


# GUI mods
## Classic UI
PageMain.qml contains the device entries.  
main.qml contains the entries for dashboard pages.  
There is no overlay mechanism for the classic ui.  
```
/opt/victronenergy/gui/qml
```

### Restart the UI service
```
svc -t /service/gui
```

### useful links  
https://github.com/victronenergy/venus/wiki/howto-add-a-driver-to-Venus
https://github.com/class142/ne-rs485/blob/master/spec.md
