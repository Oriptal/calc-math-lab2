pragma Singleton
import QtQuick

QtObject {
    property bool isDark: true

    readonly property color _darkBg: "#1f1f1f"
    readonly property color _lightBg: "#F1F5F9"

    readonly property color _darkSurface: "#12834b"
    readonly property color _lightSurface: "#FFFFFF"

    readonly property color _darkText: "#fefefe"
    readonly property color _lightText: "#1E293B"

    readonly property color bg: isDark ? _darkBg : _lightBg
    readonly property color surface: isDark ? _darkSurface : _lightSurface
    readonly property color textMain: isDark ? _darkText : _lightText
    readonly property color textDimmed: isDark ? "#7f7f7f" : "#64748B"

    readonly property color accent: "#127846"
    readonly property color border: isDark ? "#7f7f7f" : "#E2E8F0"
}
