1) Compile this plugin for gui-v2 using the gui-v2-plugin-compiler

Either: run the following in a terminal which has sourced the Venus OS SDK environment:

python3 ../../tools/gui-v2-plugin-compiler.py \
    --min-required-version v1.2.13 \
    --devicelist 0x106 inetbox_CellVoltages.qml inetbox_cellvoltages_title_cell_voltages \
    --devicelist 0x106 inetbox_CellTemperatures.qml 'Cell Temperatures' \
    --devicelist 0x106 inetbox_ComponentError.qml 'Invalid Customisation'

Alternatively: copy the contents of this directory to the device, ssh in, and compile it on device (requires Large image):

rsync -avc . root@gx.device.ip.address:/tmp/inetbox/
ssh root@gx.device.ip.address
cd /tmp/inetbox/
python3 /opt/victronenergy/gui-v2/gui-v2-plugin-compiler.py \
    --min-required-version v1.2.13 \
    --devicelist 0xD01A inetbox_CellVoltages.qml inetbox_cellvoltages_title_cell_voltages \
    --devicelist 0xD01A inetbox_CellTemperatures.qml 'Cell Temperatures' \
    --devicelist 0xD01A inetbox_ComponentError.qml 'Invalid Customisation'

2) Copy the output file `inetbox.json` to /data/apps/available/inetbox/gui-v2/inetbox.json on device: `mkdir -p /data/apps/available/inetbox/gui-v2/ && cp inetbox.json /data/apps/available/inetbox/gui-v2/inetbox.json`
3) Symlink the `inetbox` directory as follows: `ln -s /data/apps/available/inetbox /data/apps/enabled/inetbox` on device
4) Run gui-v2 in mock mode, e.g. `/opt/victronenergy/venus-gui-v2 --mock --no-mock-timers`
5) Navigate to Settings -> Integrations -> UI Plugins and confirm the inetbox plugin exists
6) Navigate to Settings -> Device List -> Skylla-i 24/100 and find the plugin-provided entries there

Note that the custom entries provided by the inetbox plugin will only be displayed in the Device List page for "Skylla-i 24/100" devices which have product id "0x106".
