import QtQuick
import "components"

Window {
    width: 1400
    height: 1050
    minimumWidth: 1400
    minimumHeight: 1050
    visible: true
    color: "transparent"

    flags: Qt.Tool | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.WindowDoesNotAcceptFocus
    MyRect {
        id: root
        anchors.fill: parent

        Header {
            id: header
        }

        Body {
            anchors.top: header.bottom
        }
    }
}
