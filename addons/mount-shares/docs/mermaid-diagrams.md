# mount-shares Mermaid diagrams

## 1) Runtime architecture

```mermaid
flowchart LR
    POSTINST[CONTROL postinst] --> REG[opkg_common_register_package]
    POSTINST --> BOOTMOUNT[data mount-shares mount-common mount-all]

    RCLOCAL[data mount-shares 2-rc-startup] --> COMMON[mount-common]
    COMMON --> CONF[data conf mount-shares.conf]
    COMMON --> MOUNT[mount command]
    COMMON --> WAIT[mountpoint check loop]

    COMMON --> CIFS[sbin mount.cifs]
    COMMON --> NFS[sbin mount.nfs]
```

## 2) Mount all replay flow

```mermaid
sequenceDiagram
    participant Boot as rc.local script
    participant Common as mount-common
    participant Conf as mount-shares.conf
    participant Kernel as mount command

    Boot->>Common: mount-all
    Common->>Conf: read saved lines
    loop each non-empty config line
        Common->>Common: parse args and target path
        Common->>Kernel: mount args target
    end
```

## Source anchors

- [src/data/mount-shares/2-rc-startup](../src/data/mount-shares/2-rc-startup)
- [src/data/mount-shares/mount-common](../src/data/mount-shares/mount-common)
- [src/CONTROL/postinst](../src/CONTROL/postinst)
- [src/CONTROL/postrm](../src/CONTROL/postrm)
