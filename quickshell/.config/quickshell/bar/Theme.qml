pragma Singleton
import QtQuick

QtObject {
    // Arkaplan katmanları (Opak)
    readonly property color background:    "#0A0A0A"
    readonly property color surface:       "#1A1A1A"
    readonly property color surfaceVariant: "#2A2A2A"

    // Ön plan (metin)
    readonly property color fg:            "#EAEAEA"
    readonly property color fgMuted:       "#AAAAAA"

    // Vurgu
    readonly property color accent:        "#DC143C"
    readonly property color accentFg:      "#FFFFFF"

    // Durum renkleri
    readonly property color error:         "#FF1744"
    readonly property color warning:       "#FF6D00"

    // Kenarlıklar
    readonly property color border:        "#333333"
    readonly property color borderAccent:  "#DC143C"

    // Bar boyutları
    readonly property int barHeight:       36
    readonly property int barRadius:       12
    readonly property int barPaddingH:     10
    readonly property int barPaddingV:     4
    readonly property int itemSpacing:     10

    // Pill / Tray ögeleri
    readonly property int pillRadius:      14
    readonly property int pillPaddingH:    8
    readonly property int pillPaddingV:    4
    readonly property int pillMinHeight:   24
}
