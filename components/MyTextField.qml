import QtQuick
import QtQuick.Controls.Basic
import ".."

TextField {
    id: control

    color: Theme.textMain
    placeholderTextColor: Theme.textDimmed
    selectByMouse: true
    font.family: "JetbrainsMono Nerd Font"

    background: Rectangle {
        radius: 3
        color: Theme.bg
        border.width: 1
        border.color: control.activeFocus ? Theme.accent : Theme.border

        Behavior on border.color {
            ColorAnimation {
                duration: 200
            }
        }
    }
}
