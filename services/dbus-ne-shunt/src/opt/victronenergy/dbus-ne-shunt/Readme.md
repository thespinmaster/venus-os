

# dbus-ne-shunt notes

## Read serial from cli

```
stty -F /dev/ttyACM0 speed 38400 cs8 -cstopb -parenb
od </dev/ttyACM0
 
cat < /dev/ttyACM0
```

If no data reverse wires

