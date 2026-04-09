pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import ".."

RowLayout {
    MyRect {
        id: rect
        Layout.fillHeight: true
        Layout.preferredWidth: 300
        property int currentEquation: 0
        property int currentMethod: 0

        Column {
            id: mainColumn
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 5
            spacing: 10
            MyRect {
                height: 50
                width: parent.width
                border.color: "transparent"
                MyText {
                    text: "Метод"
                }
            }

            property var methods: ["Половинное деление", "Ньютон", "Простая итерация",]

            Repeater {
                model: parent.methods

                delegate: NavButton {
                    required property var modelData
                    required property int index

                    text: modelData
                    active: rect.currentMethod === index
                    onClicked: rect.currentMethod = index
                }
            }

            MyRect {
                height: 50
                width: parent.width
                border.color: "transparent"
                MyText {
                    text: "Уравнение"
                }
            }

            Repeater {
                model: 4

                delegate: EquationCard {
                    required property int index
                    source: `../assets/equation${index}.svg`
                    active: rect.currentEquation === index
                    onClicked: rect.currentEquation = index
                }
            }

            MyRect {
                height: 50
                width: parent.width
                border.color: "transparent"
                MyText {
                    text: "Интервал"
                }
            }

            property var borders: [
                {
                    key: "left",
                    text: "l:",
                    placeholderText: "Например, -2,5"
                },
                {
                    key: "right",
                    text: "r:",
                    placeholderText: "Например, 3.1"
                },
                {
                    key: "eps",
                    text: "ε:",
                    placeholderText: "Например, 0.0001"
                },
            ]

            property var borderValues: {
                "left": "",
                "right": "",
                "eps": ""
            }

            Repeater {
                model: parent.borders
                RowLayout {
                    required property var modelData

                    spacing: 2
                    width: parent.width

                    Text {
                        text: parent.modelData.text
                        color: Theme.textMain
                        Layout.leftMargin: 20
                        font.pixelSize: 20
                        font.family: "JetbrainsMono Nerd Font"
                    }

                    TextField {
                        id: textField
                        text: mainColumn.borderValues[parent.modelData.key]
                        Layout.preferredHeight: 40
                        Layout.fillWidth: true
                        placeholderText: parent.modelData.placeholderText
                        Layout.rightMargin: 20

                        validator: RegularExpressionValidator {
                            regularExpression: /-?\d*([.,]\d*)?/
                        }

                        function numericValue() {
                            return Number(text.replace(",", "."));
                        }

                        onTextEdited: mainColumn.borderValues[parent.modelData.key] = text

                        background: Rectangle {
                            radius: 3
                            color: Theme.bg
                            border.width: 1
                            border.color: textField.activeFocus ? Theme.accent : Theme.border

                            Behavior on border.color {
                                ColorAnimation {
                                    duration: 200
                                }
                            }
                        }
                    }
                }
            }
        }
        MyButton {
            text: "Вычислить"
            anchors.top: mainColumn.bottom
            anchors.margins: 40
            width: parent.width - 50
            height: 50
            anchors.horizontalCenter: parent.horizontalCenter
            textNormalColor: Theme.textMain
            textHoverColor: Theme.textDimmed
            leftAligned: false
            bold: true

            onClicked: {
                console.log(mainColumn.borderValues.left);
                console.log(mainColumn.borderValues.right);
                console.log(mainColumn.borderValues.eps);
            }
        }
    }
    MyRect {} // График
}
