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
        Layout.preferredWidth: 360
        property int currentFunction: 0
        property string resultStatus: ""
        property string resultMessage: ""
        property var resultsModel: []
        property bool hasResult: false
        property real graphMinX: -5
        property real graphMaxX: 5
        property real graphMinY: -5
        property real graphMaxY: 5

        function parseInputNumber(value) {
            return Number(String(value).replace(",", "."));
        }

        function statusText(status) {
            switch (status) {
            case "ok":
                return "Интеграл вычислен";
            case "ok_principal_value":
                return "Главное значение Коши";
            case "diverges":
                return "Интеграл расходится";
            case "indeterminate":
                return "Неопределённость";
            case "max_iter":
                return "Предел разбиений";
            case "error":
                return "Ошибка ввода";
            default:
                return "";
            }
        }

        function statusColor(status) {
            switch (status) {
            case "ok":
                return "#16A34A";
            case "ok_principal_value":
                return "#D97706";
            case "diverges":
            case "error":
            case "max_iter":
            case "indeterminate":
                return "#DC2626";
            default:
                return Theme.textDimmed;
            }
        }

        function formattedValue(v) {
            return Number.isFinite(v) ? Number(v).toPrecision(10) : "—";
        }

        function updateGraph() {
            let left = parseInputNumber(mainColumn.borderValues.left);
            let right = parseInputNumber(mainColumn.borderValues.right);

            if (!Number.isFinite(left) || !Number.isFinite(right) || left >= right) {
                left = -5;
                right = 5;
            }

            graphSeries.clear();
            const points = backend.sampleIntegrand(rect.currentFunction, left, right, 700);

            let minY = Number.POSITIVE_INFINITY;
            let maxY = Number.NEGATIVE_INFINITY;

            for (let i = 0; i < points.length; ++i) {
                const p = points[i];
                const y = Number(p.y);
                if (Math.abs(y) > 1e4)
                    continue;
                graphSeries.append(Number(p.x), y);
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
        }

        Backend {
            id: backend
        }

        Flickable {
            anchors.fill: parent
            anchors.margins: 5
            contentHeight: outerColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: outerColumn
                width: parent.width
                spacing: 10

                Column {
                    id: mainColumn
                    width: parent.width
                    spacing: 10

                    MyRect {
                        height: 50
                        width: parent.width
                        border.color: "transparent"
                        MyText {
                            text: "Функция"
                        }
                    }

                    Repeater {
                        model: 5
                        delegate: EquationCard {
                            required property int index
                            source: `../assets/integrand${index}.svg`
                            active: rect.currentFunction === index
                            onClicked: {
                                rect.currentFunction = index;
                                const disc = backend.integrandDiscontinuities(index);
                                if (disc.length > 0) {
                                    if (mainColumn.borderValues.left === "")
                                        mainColumn.borderValues.left = "0";
                                    if (mainColumn.borderValues.right === "")
                                        mainColumn.borderValues.right = "1";
                                }
                            }
                        }
                    }

                    MyRect {
                        height: 50
                        width: parent.width
                        border.color: "transparent"
                        MyText {
                            text: "Пределы и точность"
                        }
                    }

                    property var borders: [
                        {
                            key: "left",
                            text: "a:",
                            placeholderText: "Например, 2"
                        },
                        {
                            key: "right",
                            text: "b:",
                            placeholderText: "Например, 4"
                        },
                        {
                            key: "eps",
                            text: "ε:",
                            placeholderText: "Например, 0.0001"
                        }
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
                }

                Item {
                    width: parent.width
                    height: 94

                    MyButton {
                        id: calculateButton
                        text: "Вычислить"
                        anchors.centerIn: parent
                        width: parent.width - 50
                        height: 50
                        textNormalColor: Theme.textMain
                        textHoverColor: Theme.textDimmed
                        leftAligned: false
                        bold: true

                        onClicked: {
                            const response = backend.integrate(rect.currentFunction, mainColumn.borderValues);
                            rect.resultStatus = response.status;
                            rect.resultMessage = response.message || "";
                            rect.resultsModel = response.methods || [];
                            rect.hasResult = true;
                            rect.updateGraph();
                        }
                    }
                }

                MyRect {
                    id: resultCard
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 50
                    height: resultColumn.implicitHeight + 20
                    color: Theme.bg
                    visible: rect.hasResult

                    Column {
                        id: resultColumn
                        anchors.fill: parent
                        anchors.margins: 10
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
                                font.pixelSize: 15
                                font.bold: true
                                font.family: "JetbrainsMono Nerd Font"
                            }
                        }

                        Text {
                            text: rect.resultMessage
                            color: Theme.textDimmed
                            wrapMode: Text.WordWrap
                            width: parent.width
                            font.pixelSize: 12
                            font.family: "JetbrainsMono Nerd Font"
                            visible: rect.resultMessage.length > 0
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
                text: "Результаты по методам"
                color: Theme.textMain
                font.pixelSize: 20
                font.family: "JetbrainsMono Nerd Font"
                font.bold: true
                Layout.leftMargin: 6
            }

            MyRect {
                Layout.fillWidth: true
                Layout.preferredHeight: resultsList.contentHeight + 16
                color: Theme.bg

                ListView {
                    id: resultsList
                    anchors.fill: parent
                    anchors.margins: 8
                    clip: true
                    model: rect.resultsModel
                    spacing: 4

                    header: Row {
                        width: resultsList.width
                        spacing: 8
                        Text {
                            width: 170
                            text: "Метод"
                            color: Theme.textMain
                            font.bold: true
                            font.family: "JetbrainsMono Nerd Font"
                            font.pixelSize: 14
                        }
                        Text {
                            width: 180
                            text: "Значение"
                            color: Theme.textMain
                            font.bold: true
                            font.family: "JetbrainsMono Nerd Font"
                            font.pixelSize: 14
                        }
                        Text {
                            width: 70
                            text: "n"
                            color: Theme.textMain
                            font.bold: true
                            font.family: "JetbrainsMono Nerd Font"
                            font.pixelSize: 14
                        }
                        Text {
                            width: 130
                            text: "R (Рунге)"
                            color: Theme.textMain
                            font.bold: true
                            font.family: "JetbrainsMono Nerd Font"
                            font.pixelSize: 14
                        }
                        Text {
                            width: 180
                            text: "Статус"
                            color: Theme.textMain
                            font.bold: true
                            font.family: "JetbrainsMono Nerd Font"
                            font.pixelSize: 14
                        }
                    }

                    delegate: Row {
                        required property var modelData
                        width: resultsList.width
                        spacing: 8

                        Text {
                            width: 170
                            text: parent.modelData.method
                            color: Theme.textMain
                            font.family: "JetbrainsMono Nerd Font"
                            font.pixelSize: 13
                            elide: Text.ElideRight
                        }
                        Text {
                            width: 180
                            text: Number.isFinite(parent.modelData.value) ? Number(parent.modelData.value).toPrecision(10) : "—"
                            color: Theme.accent
                            font.family: "JetbrainsMono Nerd Font"
                            font.pixelSize: 13
                            elide: Text.ElideRight
                        }
                        Text {
                            width: 70
                            text: parent.modelData.n
                            color: Theme.textMain
                            font.family: "JetbrainsMono Nerd Font"
                            font.pixelSize: 13
                        }
                        Text {
                            width: 130
                            text: Number.isFinite(parent.modelData.runge) ? Number(parent.modelData.runge).toExponential(2) : "—"
                            color: Theme.textDimmed
                            font.family: "JetbrainsMono Nerd Font"
                            font.pixelSize: 13
                        }
                        Text {
                            width: 180
                            text: rect.statusText(parent.modelData.status)
                            color: rect.statusColor(parent.modelData.status)
                            font.family: "JetbrainsMono Nerd Font"
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            Text {
                text: "График функции"
                color: Theme.textMain
                font.pixelSize: 20
                font.family: "JetbrainsMono Nerd Font"
                font.bold: true
                Layout.leftMargin: 6
                Layout.topMargin: 8
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
                    id: graphSeries
                    axisX: axisX
                    axisY: axisY
                    color: Theme.accent
                    width: 2.2
                }
            }
        }
    }

    Component.onCompleted: rect.updateGraph()
}
