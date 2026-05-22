# network-gps Mermaid diagrams

## 1) Runtime architecture

```mermaid
flowchart LR
    POSTINST[CONTROL postinst] --> COPY[copy service into service directory]
    COPY --> SVC[service network-gps run]

    SVC --> CONF[data conf network-gps.conf]
    CONF --> CFG[device port baud name]

    SVC --> SOCAT[socat UDP to PTY]
    SOCAT --> DEV[dev tty device]

    SVC --> GPSDBUS[gps_dbus process]
    DEV --> GPSDBUS
    GPSDBUS --> DBUS[(com.victronenergy.gps service)]

    SVC --> NAMELOOP[optional ProductName setter loop]
    NAMELOOP --> DBUS
```

## 2) Startup sequence

```mermaid
sequenceDiagram
    participant Run as service run script
    participant Conf as network-gps.conf
    participant Socat as socat
    participant GPS as gps_dbus
    participant Dbus as com.victronenergy.gps

    Run->>Conf: source config
    alt device missing
        Run->>Socat: start UDP recv to PTY link
    end
    Run->>GPS: start gps_dbus with serial device
    GPS->>Dbus: register gps dbus service
    opt friendly name configured
        Run->>Dbus: poll until service exists then set ProductName
    end
```

## Source anchors

- [src/opt/victronenergy/service/network-gps/run](../src/opt/victronenergy/service/network-gps/run)
- [src/data/conf/network-gps.conf](../src/data/conf/network-gps.conf)
- [src/CONTROL/postinst](../src/CONTROL/postinst)
- [src/CONTROL/prerm](../src/CONTROL/prerm)
