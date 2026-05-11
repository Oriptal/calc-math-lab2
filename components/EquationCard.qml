import QtQuick
import QtQuick.Effects
import ".."

NavButton {
    property alias source: image.source

    Image {
        id: image
        anchors.left: parent.left
        anchors.leftMargin: 20
        anchors.verticalCenter: parent.verticalCenter
        visible: false
    }

    MultiEffect {
        anchors.fill: image
        source: image
        colorization: 1.0
        colorizationColor: parent.active ? Theme.surface : Theme.textMain

        Behavior on colorizationColor {
            ColorAnimation {
                duration: 200
            }
        }
    }
}
