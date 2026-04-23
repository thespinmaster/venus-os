# Custom Devices

## Dbus entries
  
### com.victronenergy.settings
Paths added by the Service when installed

/Settings/opkg-manager/CustomServicePaths : `[DbusProductName]`|`[DbusProductName]`|`[DbusProductName]`  
/Settings/opkg-manager/CustomServicePaths : "`Inetbox`|`NeShunt`|`DummyService`"  

Each value in CustomServicePaths is the path name under /Settings/opkg-manager/CustomServices

/Settings/opkg-manager/CustomServices/`[DbusProductName]`

Examples:  
/Settings/opkg-manager/CustomServices/`Inetbox`/...  
/Settings/opkg-manager/CustomServices/`NeShunt`/...  
/Settings/opkg-manager/CustomServices/`DummyService`/...  

/Settings/opkg-manager/CustomServices/`[DbusProductName]`/`[Setting]`  

| Setting | Value | Note |
|---|---|---|
| `ProductName`    | "Inetbox"      | For display can be any text
| `ServiceName`    | "dbus-inetbox" | File system name
| `UsbMappingName` | "inetbox"      | Used in serial-starter.rule file and serial-starter.conf file
| `UsbProps`       | "ID_VENDOR\|ID_MODEL\|ID_SERIAL" | \| Separated props used to uniquily identify the device
 
#### Notes
This dbus setting is added by the service when it starts  
The `UsbProps` value is used to construct and remove the serial-starter.rule when "Remove Disconnected Devices" is clicked in the UI    

### com.victronenergy.temperature.cdt_dbus_inetbox_ttyUSB0
Values added by the service (when running)  

| Setting | Value | Note |
|---|---|---|
| `CustomDevicePage`    | "OpkgCustomDevicePage_neshunt"  |  The name of the qml page to use
| `CustomName`          | "My device 1"           |  User inputed text
| `ServiceName`         | "`[ServiceName]`"       |  From /Settings/opkg-manager/CustomServices/`[DbusProductName]`/`[ServiceName]`
| `SdiRuleID`            | "`ecbcdb5c55f831d7`"    |  A unique value used to find the device

 
## Files

### serial-starter.rules
 
ACTION=="add", ENV{ID_BUS}=="usb", ENV{ID_SERIAL}=="`[UsbProp(n)]`", ENV{SDI_RULE_ID}="`[SdiRuleID]`", ENV{VE_SERVICE}="`[UsbMappingName]`|`[ServiceName] (normalized)`"
 
#### example

ACTION=="add", ENV{ID_BUS}=="usb", ENV{ID_SERIAL}=="**FTDI_Intetbox_BG02CS2X**", ENV{SDI_RULE_ID}="**ecbcdb5c55f831d7**", ENV{VE_SERVICE}="**inetbox**"

#### notes
When the device is found in the serial-starter.rules file it adds
SDI_RULE_ID=ecbcdb5c55f831d7
VE_SERVICE=inetbox
To the udev properties

using the following you can get the SDI_RULE_ID value from the tty port name
```
 udevadm info --query=property --name="ttyUSB0" | sed -n "s/^SDI_RULE_ID=//p"
```

### serial-starter.conf

service **[UsbMappingName]**|**[service_name (normalized)]** **[ServiceName]**

#### example
  
```
service inetbox dbus-inetbox
service cgwacs		dbus-cgwacs
service gps		gps-dbus
...
```

## Folders:
/opt/victronenergy/service-templetes/`[ServiceName]`  
This folder is used when a device is matched to a service. The service is copied from the template folder to the service folder and appended with the port name  
/service/`[ServiceName]`.`TTY`  
#### example
```
/opt/victronenergy/service-templetes/dbus-dummy-service -> /service/dbus-dummy-service.ttyUSB0
```
