import QtQuick
import ".."

MyRect {
    id: button
    width: 30
    height: 30
    border.color: "transparent"

    color: mouseArea.containsMouse ? hoverColor : normalColor
    Behavior on color {
        ColorAnimation {
            duration: 200
        }
    }

    property color hoverColor: Theme.accent
    property color normalColor: Theme.surface
    property color textNormalColor: Theme.textDimmed
    property color textHoverColor: Theme.textMain
    property alias text: myText.text
    property alias bold: myText.font.bold
    property alias containsMouse: mouseArea.containsMouse
    property bool leftAligned: true

    signal clicked

    MyText {
        id: myText
        font.bold: true
        anchors.centerIn: parent.leftAligned ? null : parent
        anchors.left: parent.leftAligned ? parent.left : undefined
        anchors.leftMargin: parent.leftAligned ? 20 : 0
        anchors.verticalCenter: parent.verticalCenter
        color: mouseArea.containsMouse ? button.textHoverColor : button.textNormalColor

        Behavior on color {
            ColorAnimation {
                duration: 200
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true

        cursorShape: Qt.PointingHandCursor

        onClicked: {
            button.clicked();
        }
    }
}
