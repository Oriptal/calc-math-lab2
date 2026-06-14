pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import QtCharts
import Calc 1.0
import ".."

RowLayout {
    MyRect {
        id: rect
        Layout.fillHeight: true
        Layout.preferredWidth: 350
        property int currentEquation: 0
        property int resultStatus: -1
        property var iterNumber: 0
        property real resultX: Number.NaN
        property real resultY: Number.NaN
        property bool hasResult: false
        property real graphMinX: -1.2
        property real graphMaxX: 1.2
        property real graphMinY: -1.2
        property real graphMaxY: 1.2

        function statusText(status) {
            switch (status) {
            case 0:
                return "Решение найдено";
            case 1:
                return "Неверная область";
            case 3:
                return "Решение не найдено";
            case 4:
                return "Неверная точность";
            case 5:
                return "Метод расходится";
            default:
                return "Ошибка";
            }
        }

        function statusHint(status) {
            switch (status) {
            case 0:
                return "Корень системы уточнён в заданной области.";
            case 1:
                return "Задайте l < r и b < t.";
            case 3:
                return "В области нет пересечения кривых.";
            case 4:
                return "Введите положительное ε.";
            case 5:
                return "Условие сходимости не выполнено — сузьте область или выберите другую систему.";
            default:
                return "Проверьте входные данные.";
            }
        }

        function statusColor(status) {
            switch (status) {
            case 0:
                return "#16A34A";
            case 1:
            case 3:
            case 4:
            case 5:
                return "#DC2626";
            default:
                return Theme.textDimmed;
            }
        }

        function formattedNumber(value) {
            return Number.isFinite(value) ? Number(value).toPrecision(10) : "—";
        }

        function parseInputNumber(value) {
            return Number(String(value).replace(",", "."));
        }
        function printIndex(index) {
            console.log(index);
        }

        function updateGraph() {
            let left = parseInputNumber(mainColumn.borderValues.left);
            let right = parseInputNumber(mainColumn.borderValues.right);
            let bottom = parseInputNumber(mainColumn.borderValues.bottom);
            let top = parseInputNumber(mainColumn.borderValues.top);

            if (!Number.isFinite(left) || !Number.isFinite(right) || left >= right) {
                left = -1.2;
                right = 1.2;
            }

            if (!Number.isFinite(bottom) || !Number.isFinite(top) || bottom >= top) {
                bottom = -1.2;
                top = 1.2;
            }

            rect.graphMinX = left;
            rect.graphMaxX = right;
            rect.graphMinY = bottom;
            rect.graphMaxY = top;

            firstCurveSeries.clear();
            secondCurveSeries.clear();
            rootSeries.clear();

            const curves = backend.sampleSystemCurvesByEquation(rect.currentEquation, left, right, bottom, top, 600);

            const firstCurve = curves.first || [];
            const secondCurve = curves.second || [];

            for (let i = 0; i < firstCurve.length; ++i) {
                const point = firstCurve[i];
                firstCurveSeries.append(Number(point.x), Number(point.y));
            }

            for (let i = 0; i < secondCurve.length; ++i) {
                const point = secondCurve[i];
                secondCurveSeries.append(Number(point.x), Number(point.y));
            }

            if (rect.resultStatus === 0 && Number.isFinite(rect.resultX) && Number.isFinite(rect.resultY)) {
                rootSeries.append(rect.resultX, rect.resultY);
            }
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

            NavButton {
                text: "Простая итерация"
                active: true
            }

            MyRect {
                height: 50
                width: parent.width
                border.color: "transparent"

                MyText {
                    text: "Система"
                }
            }

            Repeater {
                model: 3

                delegate: EquationCard {
                    required property int index
                    source: `../assets/system${index}.svg`
                    active: rect.currentEquation === index
                    onClicked: {
                        rect.currentEquation = index;
                    }
                }
            }

            MyRect {
                height: 50
                width: parent.width
                border.color: "transparent"

                MyText {
                    text: "Область"
                }
            }

            property var borders: [
                {
                    key: "left",
                    text: "l:",
                    placeholderText: "Например, -0.9"
                },
                {
                    key: "right",
                    text: "r:",
                    placeholderText: "Например, -0.8"
                },
                {
                    key: "bottom",
                    text: "b:",
                    placeholderText: "Например, -0.5"
                },
                {
                    key: "top",
                    text: "t:",
                    placeholderText: "Например, -0.3"
                },
                {
                    key: "eps",
                    text: "ε:",
                    placeholderText: "Например, 0.01"
                }
            ]

            property var borderValues: {
                "left": "-0.9",
                "right": "-0.8",
                "bottom": "-0.5",
                "top": "-0.3",
                "eps": "0.01"
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

                    MyTextField {
                        text: mainColumn.borderValues[parent.modelData.key]
                        Layout.preferredHeight: 40
                        Layout.fillWidth: true
                        placeholderText: parent.modelData.placeholderText
                        Layout.rightMargin: 20

                        validator: RegularExpressionValidator {
                            regularExpression: /-?\d*([.,]\d*)?/
                        }

                        onTextEdited: {
                            mainColumn.borderValues[parent.modelData.key] = text;
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
                const response = backend.processSystemDataByEquation(rect.currentEquation, mainColumn.borderValues);
                rect.resultStatus = response.status;
                rect.resultX = response.x;
                rect.iterNumber = response.iter;
                rect.resultY = response.y;
                rect.hasResult = true;
                rect.updateGraph();
            }
        }

        MyRect {
            id: resultCard
            anchors.top: calculateButton.bottom
            anchors.topMargin: 14
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 50
            height: resultColumn.implicitHeight + 24
            color: Theme.bg
            visible: rect.hasResult

            Column {
                id: resultColumn
                anchors.fill: parent
                anchors.margins: 12
                spacing: 6

                Row {
                    spacing: 8
                    width: parent.width

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
                        font.pixelSize: 17
                        font.bold: true
                        font.family: "JetbrainsMono Nerd Font"
                    }
                }

                Text {
                    text: rect.statusHint(rect.resultStatus)
                    color: Theme.textDimmed
                    wrapMode: Text.WordWrap
                    width: parent.width
                    font.pixelSize: 13
                    font.family: "JetbrainsMono Nerd Font"
                }

                Text {
                    visible: rect.resultStatus === 0
                    text: "x ≈ " + rect.formattedNumber(rect.resultX)
                    color: Theme.accent
                    font.pixelSize: 16
                    font.bold: true
                    font.family: "JetbrainsMono Nerd Font"
                    width: parent.width
                    elide: Text.ElideRight
                }

                Text {
                    visible: rect.resultStatus === 0
                    text: "y ≈ " + rect.formattedNumber(rect.resultY)
                    color: Theme.accent
                    font.pixelSize: 16
                    font.bold: true
                    font.family: "JetbrainsMono Nerd Font"
                    width: parent.width
                    elide: Text.ElideRight
                }

                Text {
                    visible: rect.resultStatus === 0
                    text: "Итераций: " + rect.iterNumber
                    color: Theme.accent
                    font.pixelSize: 16
                    font.bold: true
                    font.family: "JetbrainsMono Nerd Font"
                }
            }
        }
    }

    MyRect {
        Layout.fillWidth: true
        Layout.fillHeight: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            Text {
                text: "График системы"
                color: Theme.textMain
                font.pixelSize: 20
                font.family: "JetbrainsMono Nerd Font"
                font.bold: true
                Layout.leftMargin: 6
            }

            ChartView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 300
                antialiasing: true
                legend.visible: false
                backgroundRoundness: 0
                backgroundColor: Theme.bg
                plotAreaColor: Theme.bg
                margins.left: 18
                margins.right: 12
                margins.top: 10
                margins.bottom: 16

                ValueAxis {
                    id: axisX
                    min: rect.graphMinX
                    max: rect.graphMaxX
                    labelsColor: Theme.textDimmed
                    gridLineColor: Theme.border
                    color: Theme.border
                    tickCount: 9
                    titleText: "x"
                }

                ValueAxis {
                    id: axisY
                    min: rect.graphMinY
                    max: rect.graphMaxY
                    labelsColor: Theme.textDimmed
                    gridLineColor: Theme.border
                    color: Theme.border
                    tickCount: 9
                    titleText: "y"
                }

                ScatterSeries {
                    id: firstCurveSeries
                    axisX: axisX
                    axisY: axisY
                    markerSize: 3
                    color: Theme.accent
                    borderColor: Theme.accent
                    useOpenGL: true
                }

                ScatterSeries {
                    id: secondCurveSeries
                    axisX: axisX
                    axisY: axisY
                    markerSize: 3
                    color: "#38BDF8"
                    borderColor: "#38BDF8"
                    useOpenGL: true
                }

                ScatterSeries {
                    id: rootSeries
                    axisX: axisX
                    axisY: axisY
                    markerSize: 12
                    color: "#F59E0B"
                    borderColor: "#B45309"
                }
            }
        }
    }

    Component.onCompleted: rect.updateGraph()
}
