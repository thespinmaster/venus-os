# dbus-ne-shunt Mermaid diagrams

## 1) Runtime architecture

```mermaid
flowchart LR
    MAIN[__main__.py] --> CTRL[ne_shunt_services_controller]
    MAIN --> GLIB[GLib MainLoop timeout update]

    CTRL --> SETTINGS[SettingsDevice]
    CTRL --> SERIAL[ne_shunt_serial_service]
    CTRL --> DATA[ne_shunt_data parser]

    CTRL --> TANK[tank_service]
    CTRL --> BAT[battery_service]
    CTRL --> SW[switch_service]

    SERVICES[(DBus)] --> QML[NeShuntOverview.qml]
    QML --> SERVICES
```

## 2) Periodic update flow

```mermaid
sequenceDiagram
    participant Tick as GLib timeout
    participant Ctrl as controller update
    participant Serial as ne_shunt_serial_service
    participant Data as ne_shunt_data
    participant Dbus as dbus services

    Tick->>Ctrl: call _update each second
    Ctrl->>Serial: read_data
    alt no payload
        Ctrl-->>Tick: return true
    else payload changed
        Ctrl->>Data: parse new frame
        Ctrl->>Ctrl: diff against last frame
        loop each changed key
            Ctrl->>Dbus: set_value mapped path
        end
        Ctrl->>Ctrl: store curData and lastData
        Ctrl-->>Tick: return true
    end
```

## 3) Service lifecycle state

```mermaid
stateDiagram-v2
    [*] --> initializing
    initializing --> services_ready: initialize settings and services
    services_ready --> polling: timeout update active
    polling --> polling: read and publish data
    polling --> reconfigure: setting changed callback
    reconfigure --> services_ready: start stop services by flags
    polling --> closing: signal handler
    closing --> [*]
```

## Source anchors

- [src/opt/victronenergy/dbus-ne-shunt/__main__.py](../src/opt/victronenergy/dbus-ne-shunt/__main__.py)
- [src/opt/victronenergy/dbus-ne-shunt/ne_shunt_services_controller.py](../src/opt/victronenergy/dbus-ne-shunt/ne_shunt_services_controller.py)
- [src/opt/victronenergy/dbus-ne-shunt/serial_service/ne_shunt_serial_service.py](../src/opt/victronenergy/dbus-ne-shunt/serial_service/ne_shunt_serial_service.py)
- [src/opt/victronenergy/gui/qml/NeShuntOverview.qml](../src/opt/victronenergy/gui/qml/NeShuntOverview.qml)
