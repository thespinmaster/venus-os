# themer Mermaid diagrams

## 1) Runtime architecture

```mermaid
flowchart LR
    SETTINGS[(VBus settings)] --> PAGE[ThemerPageSettings.qml]
    PAGE --> CURRENT[CurrentTheme option]
    PAGE --> AVAIL[AvailableThemes list]

    SETTINGS --> SINGLETON[Theming Themer singleton]
    SINGLETON --> BINDINGS[dynamic binds for theme values]
    BINDINGS --> COLORS[text background border icon suffix]

    COLORS --> MBSTYLE[ThemerMbStyle and themed controls]
    MBSTYLE --> UI[ThemerMain and overview pages]
```

## 2) Theme change propagation

```mermaid
sequenceDiagram
    participant User
    participant Page as ThemerPageSettings
    participant VBus as settings paths
    participant Themer as Theming Themer singleton
    participant UI as themed QML pages

    User->>Page: select Current Theme
    Page->>VBus: write Settings Themer CurrentTheme
    VBus-->>Themer: themeItem onValueChanged
    Themer->>Themer: updateBindings for selected theme paths
    Themer-->>UI: resolved colors and icon suffix values
    UI->>UI: repaint with new theme values
```

## Source anchors

- [src/opt/victronenergy/gui/qml/ThemerPageSettings.qml](../src/opt/victronenergy/gui/qml/ThemerPageSettings.qml)
- [src/opt/victronenergy/gui/qml/ThemerPageSettingsSubMenu.qml](../src/opt/victronenergy/gui/qml/ThemerPageSettingsSubMenu.qml)
- [src/opt/victronenergy/gui/qml/Theming/Themer.qml](../src/opt/victronenergy/gui/qml/Theming/Themer.qml)
- [src/opt/victronenergy/gui/qml/ThemerMain.qml](../src/opt/victronenergy/gui/qml/ThemerMain.qml)
