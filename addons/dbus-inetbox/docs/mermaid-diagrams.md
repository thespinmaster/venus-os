# dbus-inetbox Mermaid diagrams

## 1) Runtime architecture

```mermaid
flowchart LR
    MAIN[__main__.py] --> TM[TaskManager]
    MAIN --> GLIB[GLib MainLoop]
    MAIN --> CTRL[InetboxController]

    CTRL --> SETTINGS[SettingsDevice]
    CTRL --> APP[InetboxApp]
    CTRL --> LIN[Lin serial adapter]
    CTRL --> DBUS[dbusInetboxService]

    APP --> LIN
    LIN --> SERIAL[Serial device]

    APP --> PUB[publish callback]
    PUB --> CTRL
    CTRL --> DBUS

    DBUS --> UI[QML InetboxOverview and InetboxDevicePage]
    UI --> DBUS
```

## 2) Dbus write to device flow

```mermaid
sequenceDiagram
    participant UI as QML page
    participant Dbus as dbusInetboxService
    participant Ctrl as InetboxController
    participant App as InetboxApp
    participant Lin as Lin

    UI->>Dbus: write Values path
    Dbus->>Ctrl: onValueChanged callback
    Ctrl->>Ctrl: map DBus key to LIN key
    Ctrl->>App: set_status name value
    App->>Lin: write encoded status frame
```

## 3) Device telemetry publish flow

```mermaid
sequenceDiagram
    participant Lin as Lin
    participant App as InetboxApp
    participant Ctrl as InetboxController
    participant Dbus as dbusInetboxService
    participant UI as QML page

    Lin->>App: receive and decode status
    App->>Ctrl: publish callback name value
    Ctrl->>Ctrl: map LIN key to DBus key
    Ctrl->>Dbus: set_value
    Dbus->>UI: value updates
```

## Source anchors

- [src/opt/victronenergy/dbus-inetbox/__main__.py](../src/opt/victronenergy/dbus-inetbox/__main__.py)
- [src/opt/victronenergy/dbus-inetbox/inetbox_controller.py](../src/opt/victronenergy/dbus-inetbox/inetbox_controller.py)
- [src/opt/victronenergy/dbus-inetbox/inetboxapp.py](../src/opt/victronenergy/dbus-inetbox/inetboxapp.py)
- [src/opt/victronenergy/dbus-inetbox/dbus_services/dbus_inetbox_service.py](../src/opt/victronenergy/dbus-inetbox/dbus_services/dbus_inetbox_service.py)
- [src/opt/victronenergy/gui/qml/InetboxOverview.qml](../src/opt/victronenergy/gui/qml/InetboxOverview.qml)
