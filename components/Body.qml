import QtQuick
import QtQuick.Layouts
import ".."

MyRect {
    id: content

    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.margins: 12
    property int currentModule: 0

    RowLayout {
        anchors.fill: parent
        spacing: 20

        MyRect {
            Layout.preferredWidth: 240
            Layout.minimumWidth: 100
            Layout.alignment: Qt.AlignTop
            Column {
                width: parent.width
                topPadding: 20
                leftPadding: 10
                rightPadding: 10
                spacing: 15

                Text {
                    width: parent.width
                    color: Theme.textMain
                    font.pixelSize: 20
                    horizontalAlignment: Text.AlignHCenter
                    font.family: "JetbrainsMono Nerd Font"
                    text: "Методы"
                }

                Column {
                    width: parent.width
                    spacing: 8

                    NavButton {
                        text: "Метод Гаусса"
                        active: content.currentModule === 0
                        onClicked: content.currentModule = 0
                    }

                    NavButton {
                        text: "Поиск корня"
                        active: content.currentModule === 1
                        onClicked: content.currentModule = 1
                    }

                    NavButton {
                        text: "Решение системы"
                        active: content.currentModule === 2
                        onClicked: content.currentModule = 2
                    }

                    NavButton {
                        text: "Интегрирование"
                        active: content.currentModule === 3
                        onClicked: content.currentModule = 3
                    }

                    NavButton {
                        text: "Аппроксимация"
                        active: content.currentModule === 4
                        onClicked: content.currentModule = 4
                    }

                    NavButton {
                        text: "Интерполяция"
                        active: content.currentModule === 5
                        onClicked: content.currentModule = 5
                    }

                    NavButton {
                        text: "ОДУ"
                        active: content.currentModule === 6
                        onClicked: content.currentModule = 6
                    }
                }
            }
        }

        MyRect {
            Layout.fillWidth: true
            Layout.fillHeight: true
            StackLayout {
                id: moduleStack
                anchors.fill: parent
                currentIndex: content.currentModule
                onCurrentIndexChanged: moduleFade.restart()

                NumberAnimation {
                    id: moduleFade
                    target: moduleStack
                    property: "opacity"
                    from: 0.35
                    to: 1.0
                    duration: 200
                    easing.type: Easing.OutCubic
                }

                ModuleGauss {}

                ModuleRoot {}

                ModuleSystem {}

                ModuleIntegration {}

                ModuleApproximation {}

                ModuleInterpolation {}

                ModuleOde {}
            }
        }
    }
}
