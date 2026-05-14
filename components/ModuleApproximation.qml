pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import QtCharts
import Calc 1.0
import ".."

RowLayout {
    id: root

    MyRect {
        id: rect
        Layout.fillHeight: true
        Layout.preferredWidth: 360

        property int currentSize: 8
        property var xValues: rect.makeEmptyArray(8)
        property var yValues: rect.makeEmptyArray(8)
        property bool hasResult: false
        property string statusKey: ""
        property string statusMessage: ""
        property string bestMessage: ""
        property int bestIndex: -1
        property var methods: []
        property var points: []
        property real xMin: 0
        property real xMax: 1
        property var visibleKinds: ({})

        function makeEmptyArray(n) {
            return Array.from({ length: n }, () => "");
        }

        function resizeTo(n) {
            if (n < 4 || n > 12) {
                return;
            }
            const nx = rect.makeEmptyArray(n);
            const ny = rect.makeEmptyArray(n);
            for (let i = 0; i < Math.min(n, rect.xValues.length); ++i) {
                nx[i] = rect.xValues[i];
                ny[i] = rect.yValues[i];
            }
            rect.xValues = nx;
            rect.yValues = ny;
            rect.currentSize = n;
            rect.hasResult = false;
        }

        // Случайные точки около заданной функции варианта №5:
        // y = 6x / (x⁴ + 5) на [0, 2], с шумом ±5%.
        function generateRandom() {
            const n = rect.currentSize;
            const nx = [];
            const ny = [];
            const a = 0;
            const b = 2;
            const h = (b - a) / (n - 1);
            for (let i = 0; i < n; ++i) {
                const x = a + i * h;
                const baseY = 6 * x / (x * x * x * x + 5);
                const noise = (Math.random() - 0.5) * 0.1 * Math.max(baseY, 0.05);
                nx.push(x.toFixed(3));
                ny.push((baseY + noise).toFixed(4));
            }
            rect.xValues = nx;
            rect.yValues = ny;
            rect.hasResult = false;
        }

        function formattedNumber(value) {
            if (!Number.isFinite(value)) {
                return "—";
            }
            const abs = Math.abs(value);
            if (abs !== 0 && (abs < 1e-4 || abs >= 1e8)) {
                return Number(value).toExponential(4);
            }
            return Number(value).toFixed(4);
        }

        function statusColor(key) {
            switch (key) {
            case "ok":
                return "#16A34A";
            case "non_positive_x":
            case "non_positive_y":
                return "#D97706";
            case "too_few":
            case "too_many":
            case "degenerate":
            case "error":
                return "#DC2626";
            default:
                return Theme.textDimmed;
            }
        }

        function methodColor(kind) {
            switch (kind) {
            case "linear":
                return "#2563EB";
            case "poly2":
                return "#16A34A";
            case "poly3":
                return "#9333EA";
            case "exp":
                return "#DC2626";
            case "log":
                return "#D97706";
            case "power":
                return "#0EA5E9";
            default:
                return Theme.textDimmed;
            }
        }

        function setKindVisible(kind, on) {
            const v = Object.assign({}, rect.visibleKinds);
            v[kind] = on;
            rect.visibleKinds = v;
        }

        function isKindVisible(kind) {
            return rect.visibleKinds[kind] === true;
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
                    text: "Количество точек"
                }
            }

            Item {
                width: parent.width - 40
                height: 40
                x: 20

                MyButton {
                    text: "−"
                    width: 40
                    height: 40
                    anchors.left: parent.left
                    leftAligned: false
                    bold: true
                    textNormalColor: Theme.textMain
                    textHoverColor: Theme.textDimmed
                    onClicked: rect.resizeTo(rect.currentSize - 1)
                }

                Text {
                    anchors.centerIn: parent
                    text: "n = " + rect.currentSize
                    color: Theme.textMain
                    font.pixelSize: 20
                    font.family: "JetbrainsMono Nerd Font"
                }

                MyButton {
                    text: "+"
                    width: 40
                    height: 40
                    anchors.right: parent.right
                    leftAligned: false
                    bold: true
                    textNormalColor: Theme.textMain
                    textHoverColor: Theme.textDimmed
                    onClicked: rect.resizeTo(rect.currentSize + 1)
                }
            }

            MyRect {
                height: 50
                width: parent.width
                border.color: "transparent"
                MyText {
                    text: "Таблица (xᵢ, yᵢ)"
                }
            }

            Column {
                id: tableBlock
                width: parent.width - 40
                x: 20
                spacing: 3

                Row {
                    width: parent.width
                    spacing: 6

                    Text {
                        width: (parent.width - 6) / 2
                        text: "xᵢ"
                        color: Theme.textDimmed
                        horizontalAlignment: Text.AlignHCenter
                        font.family: "JetbrainsMono Nerd Font"
                        font.pixelSize: 14
                    }

                    Text {
                        width: (parent.width - 6) / 2
                        text: "yᵢ"
                        color: Theme.textDimmed
                        horizontalAlignment: Text.AlignHCenter
                        font.family: "JetbrainsMono Nerd Font"
                        font.pixelSize: 14
                    }
                }

                Repeater {
                    model: rect.currentSize

                    delegate: RowLayout {
                        id: tableRow
                        required property int index
                        width: tableBlock.width
                        spacing: 6

                        MyTextField {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 30
                            horizontalAlignment: TextInput.AlignHCenter
                            font.pixelSize: 13
                            placeholderText: "0"
                            text: rect.xValues[tableRow.index] !== undefined ? rect.xValues[tableRow.index] : ""

                            validator: RegularExpressionValidator {
                                regularExpression: /-?\d*([.,]\d*)?/
                            }

                            onTextEdited: {
                                const a = rect.xValues.slice();
                                a[tableRow.index] = text;
                                rect.xValues = a;
                            }
                        }

                        MyTextField {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 30
                            horizontalAlignment: TextInput.AlignHCenter
                            font.pixelSize: 13
                            placeholderText: "0"
                            text: rect.yValues[tableRow.index] !== undefined ? rect.yValues[tableRow.index] : ""

                            validator: RegularExpressionValidator {
                                regularExpression: /-?\d*([.,]\d*)?/
                            }

                            onTextEdited: {
                                const a = rect.yValues.slice();
                                a[tableRow.index] = text;
                                rect.yValues = a;
                            }
                        }
                    }
                }
            }
        }

        MyButton {
            id: randomButton
            text: "Случайные данные"
            anchors.top: mainColumn.bottom
            anchors.topMargin: 28
            width: parent.width - 50
            height: 50
            anchors.horizontalCenter: parent.horizontalCenter
            textNormalColor: Theme.textMain
            textHoverColor: Theme.textDimmed
            leftAligned: false
            bold: true

            onClicked: rect.generateRandom()
        }

        MyButton {
            id: calculateButton
            text: "Рассчитать"
            anchors.top: randomButton.bottom
            anchors.topMargin: 10
            width: parent.width - 50
            height: 50
            anchors.horizontalCenter: parent.horizontalCenter
            textNormalColor: Theme.textMain
            textHoverColor: Theme.textDimmed
            leftAligned: false
            bold: true

            onClicked: {
                const payload = [];
                for (let i = 0; i < rect.currentSize; ++i) {
                    payload.push({
                        "x": rect.xValues[i],
                        "y": rect.yValues[i]
                    });
                }
                const response = backend.approximate({ "points": payload });
                rect.statusKey = response.status;
                rect.statusMessage = response.message !== undefined ? response.message : "";
                if (response.status === "ok") {
                    rect.methods = response.methods;
                    rect.points = response.points;
                    rect.xMin = response.xMin;
                    rect.xMax = response.xMax;
                    rect.bestIndex = response.best;
                    rect.bestMessage = response.bestMessage;
                    // По умолчанию показываем лучшую модель + первые две полиномиальные.
                    const v = {};
                    for (let i = 0; i < rect.methods.length; ++i) {
                        const m = rect.methods[i];
                        if (m.status === "ok") {
                            v[m.kind] = (i === rect.bestIndex) || (m.kind === "linear");
                        }
                    }
                    rect.visibleKinds = v;
                } else {
                    rect.methods = [];
                    rect.points = [];
                    rect.bestIndex = -1;
                    rect.bestMessage = "";
                }
                rect.hasResult = true;
                graphView.refresh();
            }
        }

        MyRect {
            id: statusCard
            anchors.top: calculateButton.bottom
            anchors.topMargin: 14
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 50
            height: statusColumn.implicitHeight + 20
            color: Theme.bg
            visible: rect.hasResult

            Column {
                id: statusColumn
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
                        color: rect.statusColor(rect.statusKey === "ok" ? "ok" : "error")
                    }

                    Text {
                        text: rect.statusKey === "ok" ? "Расчёт выполнен" : "Ошибка"
                        color: Theme.textMain
                        font.pixelSize: 15
                        font.bold: true
                        font.family: "JetbrainsMono Nerd Font"
                    }
                }

                Text {
                    visible: rect.statusKey === "ok" && rect.bestMessage.length > 0
                    text: rect.bestMessage
                    color: Theme.accent
                    wrapMode: Text.WordWrap
                    width: parent.width
                    font.pixelSize: 13
                    font.bold: true
                    font.family: "JetbrainsMono Nerd Font"
                }

                Text {
                    visible: rect.statusKey !== "ok" && rect.statusMessage.length > 0
                    text: rect.statusMessage
                    color: Theme.textDimmed
                    wrapMode: Text.WordWrap
                    width: parent.width
                    font.pixelSize: 12
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
                Layout.fillWidth: true
                text: "Аппроксимация методом наименьших квадратов"
                color: Theme.textMain
                font.pixelSize: 20
                font.family: "JetbrainsMono Nerd Font"
                font.bold: true
                Layout.leftMargin: 6
            }

            MyRect {
                Layout.fillWidth: true
                Layout.preferredHeight: 250
                color: Theme.bg
                visible: rect.hasResult && rect.statusKey === "ok"

                ListView {
                    id: methodsList
                    anchors.fill: parent
                    anchors.margins: 8
                    clip: true
                    model: rect.methods
                    spacing: 2

                    header: Row {
                        width: methodsList.width
                        spacing: 6

                        Text {
                            width: 60
                            text: "График"
                            color: Theme.textMain
                            font.bold: true
                            font.family: "JetbrainsMono Nerd Font"
                            font.pixelSize: 13
                            horizontalAlignment: Text.AlignHCenter
                        }
                        Text {
                            width: 110
                            text: "Метод"
                            color: Theme.textMain
                            font.bold: true
                            font.family: "JetbrainsMono Nerd Font"
                            font.pixelSize: 13
                        }
                        Text {
                            width: 200
                            text: "Формула"
                            color: Theme.textMain
                            font.bold: true
                            font.family: "JetbrainsMono Nerd Font"
                            font.pixelSize: 13
                        }
                        Text {
                            width: 80
                            text: "S"
                            color: Theme.textMain
                            font.bold: true
                            font.family: "JetbrainsMono Nerd Font"
                            font.pixelSize: 13
                            horizontalAlignment: Text.AlignRight
                        }
                        Text {
                            width: 80
                            text: "δ"
                            color: Theme.textMain
                            font.bold: true
                            font.family: "JetbrainsMono Nerd Font"
                            font.pixelSize: 13
                            horizontalAlignment: Text.AlignRight
                        }
                        Text {
                            width: 70
                            text: "R²"
                            color: Theme.textMain
                            font.bold: true
                            font.family: "JetbrainsMono Nerd Font"
                            font.pixelSize: 13
                            horizontalAlignment: Text.AlignRight
                        }
                        Text {
                            width: 70
                            text: "r"
                            color: Theme.textMain
                            font.bold: true
                            font.family: "JetbrainsMono Nerd Font"
                            font.pixelSize: 13
                            horizontalAlignment: Text.AlignRight
                        }
                        Text {
                            width: 160
                            text: "Качество (по R²)"
                            color: Theme.textMain
                            font.bold: true
                            font.family: "JetbrainsMono Nerd Font"
                            font.pixelSize: 13
                        }
                    }

                    delegate: Row {
                        id: methodRow
                        required property var modelData
                        required property int index
                        width: methodsList.width
                        spacing: 6
                        readonly property bool isOk: modelData.status === "ok"
                        readonly property bool isBest: index === rect.bestIndex
                        readonly property bool curveVisible: rect.isKindVisible(modelData.kind)
                        readonly property color curveColor: rect.methodColor(modelData.kind)

                        Item {
                            width: 60
                            height: 26

                            Rectangle {
                                id: toggleBtn
                                anchors.centerIn: parent
                                width: 54
                                height: 24
                                radius: 5
                                color: methodRow.curveVisible ? methodRow.curveColor : "transparent"
                                border.color: methodRow.isOk ? methodRow.curveColor : Theme.textDimmed
                                border.width: 1.5
                                opacity: methodRow.isOk ? (toggleArea.containsMouse ? 0.82 : 1.0) : 0.4
                                scale: toggleArea.containsMouse ? 1.06 : 1.0
                                Behavior on scale { NumberAnimation { duration: 120 } }
                                Behavior on color { ColorAnimation { duration: 120 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: methodRow.isOk ? (methodRow.curveVisible ? "вкл" : "выкл") : "—"
                                    color: methodRow.curveVisible ? "#ffffff" : (methodRow.isOk ? methodRow.curveColor : Theme.textDimmed)
                                    font.family: "JetbrainsMono Nerd Font"
                                    font.pixelSize: 11
                                    font.bold: true
                                }

                                MouseArea {
                                    id: toggleArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    enabled: methodRow.isOk
                                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: {
                                        rect.setKindVisible(methodRow.modelData.kind, !methodRow.curveVisible);
                                        graphView.refresh();
                                    }
                                }
                            }
                        }

                        Text {
                            width: 110
                            text: methodRow.modelData.shortTitle + (methodRow.isBest ? " ★" : "")
                            color: methodRow.isBest ? "#16A34A" : (methodRow.isOk ? Theme.textMain : Theme.textDimmed)
                            font.family: "JetbrainsMono Nerd Font"
                            font.pixelSize: 13
                            font.bold: methodRow.isBest
                            elide: Text.ElideRight
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            width: 200
                            text: methodRow.isOk ? methodRow.modelData.formula : methodRow.modelData.statusMessage
                            color: methodRow.isOk ? Theme.accent : "#D97706"
                            font.family: "JetbrainsMono Nerd Font"
                            font.pixelSize: 12
                            elide: Text.ElideRight
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            width: 80
                            text: methodRow.isOk ? Number(methodRow.modelData.S).toExponential(2) : "—"
                            color: Theme.textMain
                            font.family: "JetbrainsMono Nerd Font"
                            font.pixelSize: 12
                            horizontalAlignment: Text.AlignRight
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            width: 80
                            text: methodRow.isOk ? Number(methodRow.modelData.delta).toFixed(4) : "—"
                            color: Theme.textMain
                            font.family: "JetbrainsMono Nerd Font"
                            font.pixelSize: 12
                            horizontalAlignment: Text.AlignRight
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            width: 70
                            text: methodRow.isOk ? Number(methodRow.modelData.r2).toFixed(4) : "—"
                            color: Theme.textMain
                            font.family: "JetbrainsMono Nerd Font"
                            font.pixelSize: 12
                            horizontalAlignment: Text.AlignRight
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            width: 70
                            text: methodRow.modelData.pearson !== null && methodRow.modelData.pearson !== undefined ? Number(methodRow.modelData.pearson).toFixed(4) : "—"
                            color: Theme.textDimmed
                            font.family: "JetbrainsMono Nerd Font"
                            font.pixelSize: 12
                            horizontalAlignment: Text.AlignRight
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            width: 160
                            text: methodRow.isOk ? methodRow.modelData.r2Verdict : "—"
                            color: methodRow.isOk ? Theme.textMain : Theme.textDimmed
                            font.family: "JetbrainsMono Nerd Font"
                            font.pixelSize: 12
                            elide: Text.ElideRight
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }

            Text {
                text: "График аппроксимаций"
                color: Theme.textMain
                font.pixelSize: 18
                font.family: "JetbrainsMono Nerd Font"
                font.bold: true
                Layout.leftMargin: 6
                Layout.topMargin: 6
                visible: rect.hasResult && rect.statusKey === "ok"
            }

            ChartView {
                id: graphView
                Layout.fillWidth: true
                Layout.fillHeight: true
                antialiasing: true
                legend.visible: false
                backgroundRoundness: 0
                backgroundColor: Theme.bg
                plotAreaColor: Theme.bg
                margins.left: 18
                margins.right: 12
                margins.top: 10
                margins.bottom: 16

                property real plotMinX: 0
                property real plotMaxX: 1
                property real plotMinY: -1
                property real plotMaxY: 1

                function refresh() {
                    pointSeries.clear();
                    linearSeries.clear();
                    poly2Series.clear();
                    poly3Series.clear();
                    expSeries.clear();
                    logSeries.clear();
                    powerSeries.clear();

                    if (!rect.hasResult || rect.statusKey !== "ok") {
                        return;
                    }

                    const span = rect.xMax - rect.xMin;
                    const pad = span * 0.1;
                    const xLo = rect.xMin - pad;
                    const xHi = rect.xMax + pad;
                    graphView.plotMinX = xLo;
                    graphView.plotMaxX = xHi;

                    let minY = Number.POSITIVE_INFINITY;
                    let maxY = Number.NEGATIVE_INFINITY;

                    for (let i = 0; i < rect.points.length; ++i) {
                        const p = rect.points[i];
                        pointSeries.append(Number(p.x), Number(p.y));
                        if (p.y < minY) minY = p.y;
                        if (p.y > maxY) maxY = p.y;
                    }

                    const seriesByKind = {
                        "linear": linearSeries,
                        "poly2": poly2Series,
                        "poly3": poly3Series,
                        "exp": expSeries,
                        "log": logSeries,
                        "power": powerSeries
                    };

                    for (let i = 0; i < rect.methods.length; ++i) {
                        const m = rect.methods[i];
                        const series = seriesByKind[m.kind];
                        series.color = rect.methodColor(m.kind);
                        series.visible = m.status === "ok" && rect.isKindVisible(m.kind);
                        if (!series.visible) {
                            continue;
                        }
                        const samples = backend.sampleApproximation(m.kind, m.coeffs, xLo, xHi, 400);
                        for (let j = 0; j < samples.length; ++j) {
                            const s = samples[j];
                            const yv = Number(s.y);
                            if (!Number.isFinite(yv)) {
                                continue;
                            }
                            series.append(Number(s.x), yv);
                            if (yv < minY) minY = yv;
                            if (yv > maxY) maxY = yv;
                        }
                    }

                    if (!Number.isFinite(minY) || !Number.isFinite(maxY)) {
                        minY = -1;
                        maxY = 1;
                    }
                    if (Math.abs(maxY - minY) < 1e-9) {
                        minY -= 1;
                        maxY += 1;
                    }
                    const yPad = (maxY - minY) * 0.1;
                    graphView.plotMinY = minY - yPad;
                    graphView.plotMaxY = maxY + yPad;
                }

                ValueAxis {
                    id: axisX
                    min: graphView.plotMinX
                    max: graphView.plotMaxX
                    labelsColor: Theme.textDimmed
                    gridLineColor: Theme.border
                    color: Theme.border
                    tickCount: 9
                    titleText: "x"
                }
                ValueAxis {
                    id: axisY
                    min: graphView.plotMinY
                    max: graphView.plotMaxY
                    labelsColor: Theme.textDimmed
                    gridLineColor: Theme.border
                    color: Theme.border
                    tickCount: 9
                    titleText: "y"
                }
                ScatterSeries {
                    id: pointSeries
                    axisX: axisX
                    axisY: axisY
                    markerSize: 9
                    color: Theme.accent
                    borderColor: Theme.bg
                }
                LineSeries {
                    id: linearSeries
                    axisX: axisX
                    axisY: axisY
                    width: 2
                    useOpenGL: true
                }
                LineSeries {
                    id: poly2Series
                    axisX: axisX
                    axisY: axisY
                    width: 2
                    useOpenGL: true
                }
                LineSeries {
                    id: poly3Series
                    axisX: axisX
                    axisY: axisY
                    width: 2
                    useOpenGL: true
                }
                LineSeries {
                    id: expSeries
                    axisX: axisX
                    axisY: axisY
                    width: 2
                    useOpenGL: true
                }
                LineSeries {
                    id: logSeries
                    axisX: axisX
                    axisY: axisY
                    width: 2
                    useOpenGL: true
                }
                LineSeries {
                    id: powerSeries
                    axisX: axisX
                    axisY: axisY
                    width: 2
                    useOpenGL: true
                }
            }
        }
    }
}
