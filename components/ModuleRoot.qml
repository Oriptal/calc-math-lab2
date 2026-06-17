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
        property int currentMethod: 0
        property int resultStatus: -1
        property var iterNumber: 0
        property real resultValue: Number.NaN
        property bool hasResult: false
        property real graphMinX: -5
        property real graphMaxX: 5
        property real graphMinY: -5
        property real graphMaxY: 5

        function statusText(status) {
            switch (status) {
            case 0:
                return "Найден корень";
            case 1:
                return "Неверный интервал";
            case 2:
                return "Несколько корней";
            case 3:
                return "Корень не найден";
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
                return "Корень уточнён на заданном интервале.";
            case 1:
                return "Задайте a < b, проверьте числа.";
            case 2:
                return "На интервале > 1 корня — сузьте отрезок.";
            case 3:
                return "Смены знака не обнаружено.";
            case 4:
                return "Введите положительное ε.";
            case 5:
                return "Условие сходимости не выполнено — сузьте интервал или выберите другой метод.";
            default:
                return "Проверьте входные данные.";
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

        function parseInputNumber(value) {
            return Number(String(value).replace(",", "."));
        }

        function updateGraph() {
            let left = parseInputNumber(mainColumn.borderValues.left);
            let right = parseInputNumber(mainColumn.borderValues.right);

            if (!Number.isFinite(left) || !Number.isFinite(right) || left >= right) {
                left = -5;
                right = 5;
            }

            const points = backend.sampleCurve(rect.currentEquation, left, right, 700);
            graphSeries.clear();
            zeroSeries.clear();
            rootSeries.clear();

            if (!points.length) {
                rect.graphMinX = left;
                rect.graphMaxX = right;
                rect.graphMinY = -1;
                rect.graphMaxY = 1;
                return;
            }

            let minY = Number.POSITIVE_INFINITY;
            let maxY = Number.NEGATIVE_INFINITY;

            for (let i = 0; i < points.length; ++i) {
                const p = points[i];
                const x = Number(p.x);
                const y = Number(p.y);
                graphSeries.append(x, y);
                if (y < minY)
                    minY = y;
                if (y > maxY)
                    maxY = y;
            }

            if (!Number.isFinite(minY) || !Number.isFinite(maxY)) {
                minY = -1;
                maxY = 1;
            }
            if (Math.abs(maxY - minY) < 1e-9) {
                minY -= 1;
                maxY += 1;
            }

            const yPadding = (maxY - minY) * 0.08;
            rect.graphMinX = left;
            rect.graphMaxX = right;
            rect.graphMinY = minY - yPadding;
            rect.graphMaxY = maxY + yPadding;

            zeroSeries.append(left, 0);
            zeroSeries.append(right, 0);

            if (rect.resultStatus === 0 && Number.isFinite(rect.resultValue)) {
                rootSeries.append(rect.resultValue, 0);
            }
        }

        Backend {
            id: backend
        }

        Flickable {
            anchors.fill: parent
            anchors.margins: 5
            contentHeight: mainColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: mainColumn
                width: parent.width
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

                        MyTextField {
                            text: mainColumn.borderValues[parent.modelData.key]
                            Layout.preferredHeight: 40
                            Layout.fillWidth: true
                            placeholderText: parent.modelData.placeholderText
                            Layout.rightMargin: 20

                            validator: RegularExpressionValidator {
                                regularExpression: /-?\d*([.,]\d*)?/
                            }

                            onTextEdited: mainColumn.borderValues[parent.modelData.key] = text
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: 30
                }

                MyButton {
                    id: calculateButton
                    text: "Вычислить"
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
                        rect.iterNumber = response.iter;
                        rect.hasResult = true;
                        rect.updateGraph();
                    }
                }

                MyRect {
                    id: resultCard
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
                            text: "x ≈ " + rect.formattedRoot()
                            color: Theme.accent
                            font.pixelSize: 18
                            font.bold: true
                            font.family: "JetbrainsMono Nerd Font"
                        }

                        Text {
                            visible: rect.resultStatus === 0
                            text: "Итераций: " + rect.iterNumber
                            color: Theme.accent
                            font.pixelSize: 18
                            font.bold: true
                            font.family: "JetbrainsMono Nerd Font"
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: 6
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
                text: "График функции"
                color: Theme.textMain
                font.pixelSize: 20
                font.family: "JetbrainsMono Nerd Font"
                font.bold: true
                Layout.leftMargin: 6
            }

            ChartView {
                id: graphView
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

                LineSeries {
                    id: zeroSeries
                    axisX: axisX
                    axisY: axisY
                    color: Theme.border
                    width: 1
                }

                LineSeries {
                    id: graphSeries
                    axisX: axisX
                    axisY: axisY
                    color: Theme.accent
                    width: 2.2
                }

                ScatterSeries {
                    id: rootSeries
                    axisX: axisX
                    axisY: axisY
                    markerSize: 11
                    color: "#F59E0B"
                    borderColor: "#B45309"
                }
            }
        }
    }
}
