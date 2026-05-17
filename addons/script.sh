echo "=== current Start value ==="
dbus-send --system --dest=com.victronenergy.opkgmanager --type=method_call --print-reply --reply-timeout=3000 /Request/Start com.victronenergy.BusItem.GetValue

echo "=== current Source ==="
dbus-send --system --dest=com.victronenergy.opkgmanager --type=method_call --print-reply --reply-timeout=3000 /HttpServer/Source com.victronenergy.BusItem.GetValue

rm -f /tmp/opkg-manager-fs/packages.json

echo "=== sending Start=2 (should be a new value) ==="
dbus-send --system --dest=com.victronenergy.opkgmanager --type=method_call --print-reply --reply-timeout=3000 /Request/ArgsJson com.victronenergy.BusItem.SetValue variant:string:'["package","list"]'
dbus-send --system --dest=com.victronenergy.opkgmanager --type=method_call --print-reply --reply-timeout=3000 /Request/Start com.victronenergy.BusItem.SetValue variant:uint32:2

echo "t+0: waiting..."
sleep 1
echo "=== t+1 ==="
dbus-send --system --dest=com.victronenergy.opkgmanager --type=method_call --print-reply --reply-timeout=3000 /State/Running com.victronenergy.BusItem.GetValue
dbus-send --system --dest=com.victronenergy.opkgmanager --type=method_call --print-reply --reply-timeout=3000 /HttpServer/Source com.victronenergy.BusItem.GetValue
echo "=== t+2 ==="
sleep 2
dbus-send --system --dest=com.victronenergy.opkgmanager --type=method_call --print-reply --reply-timeout=3000 /State/Running com.victronenergy.BusItem.GetValue
dbus-send --system --dest=com.victronenergy.opkgmanager --type=method_call --print-reply --reply-timeout=3000 /HttpServer/Source com.victronenergy.BusItem.GetValue
echo "=== packages.json ==="
ls -la /tmp/opkg-manager-fs/packages.json 2>&1
