pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Calc 1.0
import ".."

RowLayout {
    MyRect {
        id: rect
        Layout.fillHeight: true
        Layout.preferredWidth: 350
        property int currentEquation: 0
        property int currentMethod: 0
        property int resultStatus: -1
        property real resultValue: Number.NaN
        property bool hasResult: false

        function statusText(status) {
            switch (status) {
            case 0:
                return "Успех";
            case 1:
                return "Некорректный интервал";
            case 2:
                return "Несколько корней";
            case 3:
                return "Корней нет";
            case 4:
                return "Некорректная точность";
            case 5:
                return "Метод не сходится";
            default:
                return "Неизвестная ошибка";
            }
        }

        function statusHint(status) {
            switch (status) {
            case 0:
                return "Корень найден на выбранном интервале.";
            case 1:
                return "Проверьте границы: l < r, l ≥ -5, r ≤ 5";
            case 2:
                return "На интервале найдено больше одного корня. Сузьте отрезок.";
            case 3:
                return "Смена знака функции не обнаружена.";
            case 4:
                return "Введите положительное ε.";
            case 5:
                return "Для выбранного метода условие сходимости не выполнено. Сузьте интервал или выберите другой метод.";
            default:
                return "Проверьте входные данные и попробуйте ещё раз.";
            }
        }

        function statusColor(status) {
            switch (status) {
            case 0:
                return "#16A34A";
            case 1:
            case 2:
            case 3:
            case 4:
            case 5:
                return "#DC2626";
            default:
                return Theme.textDimmed;
            }
        }

        function formattedRoot() {
            return Number.isFinite(resultValue) ? Number(resultValue).toPrecision(10) : "—";
        }

        Backend {
            id: backend
        }

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
            id: calculateButton
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
                const response = backend.processData(rect.currentMethod, rect.currentEquation, mainColumn.borderValues);
                rect.resultStatus = response.status;
                rect.resultValue = response.value;
                rect.hasResult = true;
            }
        }

        MyRect {
            id: resultCard
            anchors.top: calculateButton.bottom
            anchors.topMargin: 14
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 50
            height: 132
            color: Theme.bg
            visible: rect.hasResult

            Column {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                Row {
                    spacing: 8

                    Rectangle {
                        width: 10
                        height: 10
                        radius: 5
                        anchors.verticalCenter: parent.verticalCenter
                        color: rect.statusColor(rect.resultStatus)
                    }

                    Text {
                        text: rect.statusText(rect.resultStatus)
                        color: Theme.textMain
                        font.pixelSize: 18
                        font.bold: true
                        font.family: "JetbrainsMono Nerd Font"
                    }
                }

                Text {
                    text: rect.statusHint(rect.resultStatus)
                    color: Theme.textDimmed
                    wrapMode: Text.WordWrap
                    width: parent.width
                    font.pixelSize: 14
                    font.family: "JetbrainsMono Nerd Font"
                }

                Text {
                    visible: rect.resultStatus === 0
                    text: "x ≈ " + rect.formattedRoot()
                    color: Theme.accent
                    font.pixelSize: 20
                    font.bold: true
                    font.family: "JetbrainsMono Nerd Font"
                }
            }
        }
    }
    MyRect {} // График
}
