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

        property var equations: []
        property int equationId: 0

        property string x0Text: "0"
        property string y0Text: "1"
        property string xnText: "1"
        property string hText: "0.1"
        property string epsText: "0.001"

        property bool hasResult: false
        property string statusKey: ""
        property string statusMessage: ""
        property string resultTitle: ""
        property var table: []
        property var methods: []
        property int nodeCount: 0
        property real x0: 0
        property real xn: 1
        property real h: 0.1
        property real eps: 0.001

        property bool showExact: true
        property bool showImprovedEuler: true
        property bool showRk4: true
        property bool showMilne: true

        readonly property color exactColor: "#0EA5E9"

        function methodColor(key) {
            switch (key) {
            case "improved_euler":
                return "#16A34A";
            case "rk4":
                return "#9333EA";
            case "milne":
                return "#DB2777";
            default:
                return Theme.textDimmed;
            }
        }

        function fieldValue(key) {
            switch (key) {
            case "x0":
                return rect.x0Text;
            case "y0":
                return rect.y0Text;
            case "xn":
                return rect.xnText;
            case "h":
                return rect.hText;
            case "eps":
                return rect.epsText;
            }
            return "";
        }

        function setField(key, value) {
            switch (key) {
            case "x0":
                rect.x0Text = value;
                break;
            case "y0":
                rect.y0Text = value;
                break;
            case "xn":
                rect.xnText = value;
                break;
            case "h":
                rect.hText = value;
                break;
            case "eps":
                rect.epsText = value;
                break;
            }
        }

        function calculate() {
            const payload = {
                "equationId": rect.equationId,
                "x0": rect.x0Text,
                "y0": rect.y0Text,
                "xn": rect.xnText,
                "h": rect.hText,
                "eps": rect.epsText
            };
            const r = backend.solveOde(payload);
            rect.statusKey = r.status;
            rect.statusMessage = r.message !== undefined ? r.message : "";
            if (r.status === "ok") {
                rect.table = r.table;
                rect.methods = r.methods;
                rect.nodeCount = r.nodeCount;
                rect.resultTitle = r.equationTitle;
                rect.x0 = r.x0;
                rect.xn = r.xn;
                rect.h = r.h;
                rect.eps = r.eps;
            } else {
                rect.table = [];
                rect.methods = [];
                rect.nodeCount = 0;
            }
            rect.hasResult = true;
            graphView.refresh();
        }

        function formattedNumber(value) {
            if (!Number.isFinite(Number(value))) {
                return "—";
            }
            const abs = Math.abs(value);
            if (abs !== 0 && (abs < 1e-4 || abs >= 1e7)) {
                return Number(value).toExponential(4);
            }
            return Number(value).toFixed(5);
        }

        function expo(value) {
            if (!Number.isFinite(Number(value))) {
                return "—";
            }
            return Number(value).toExponential(2);
        }

        function numStr(value) {
            return String(Number(value));
        }

        Backend {
            id: backend
        }

        Component.onCompleted: {
            rect.equations = backend.odeEquations();
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
                        text: "Уравнение y′ = f(x, y)"
                        font.pixelSize: 18
                    }
                }

                Column {
                    width: parent.width
                    spacing: 4

                    Repeater {
                        model: rect.equations
                        delegate: EquationCard {
                            required property var modelData
                            source: `../assets/ode${modelData.id}.svg`
                            active: rect.equationId === modelData.id
                            onClicked: rect.equationId = modelData.id
                        }
                    }
                }

                MyRect {
                    height: 50
                    width: parent.width
                    border.color: "transparent"
                    MyText {
                        text: "Начальные условия и отрезок"
                        font.pixelSize: 18
                    }
                }

                Column {
                    width: parent.width
                    spacing: 8

                    Repeater {
                        model: [
                            { "key": "x0", "label": "x₀:", "ph": "Начало отрезка" },
                            { "key": "y0", "label": "y₀:", "ph": "y(x₀)" },
                            { "key": "xn", "label": "xₙ:", "ph": "Конец отрезка" },
                            { "key": "h", "label": "h:", "ph": "Шаг" },
                            { "key": "eps", "label": "ε:", "ph": "Точность" }
                        ]
                        delegate: RowLayout {
                            id: fieldRow
                            required property var modelData
                            width: parent.width
                            spacing: 2

                            Text {
                                text: fieldRow.modelData.label
                                color: Theme.textMain
                                Layout.leftMargin: 20
                                Layout.preferredWidth: 32
                                font.pixelSize: 20
                                font.family: "JetbrainsMono Nerd Font"
                            }
                            MyTextField {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                Layout.rightMargin: 20
                                placeholderText: fieldRow.modelData.ph
                                text: rect.fieldValue(fieldRow.modelData.key)
                                validator: RegularExpressionValidator {
                                    regularExpression: /-?\d*([.,]\d*)?(e-?\d*)?/
                                }
                                onTextEdited: rect.setField(fieldRow.modelData.key, text)
                            }
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: 64

                    MyButton {
                        anchors.centerIn: parent
                        width: parent.width - 50
                        height: 50
                        text: "Рассчитать"
                        leftAligned: false
                        bold: true
                        textNormalColor: Theme.textMain
                        textHoverColor: Theme.textDimmed
                        onClicked: rect.calculate()
                    }
                }

                MyRect {
                    width: parent.width - 50
                    x: 25
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
                                color: rect.statusKey === "ok" ? "#16A34A" : "#DC2626"
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
                            visible: rect.statusKey === "ok"
                            text: "Узлов: " + rect.nodeCount + " · точное решение и 3 метода построены"
                            color: Theme.accent
                            wrapMode: Text.WordWrap
                            width: parent.width
                            font.pixelSize: 12
                            font.family: "JetbrainsMono Nerd Font"
                        }
                        Text {
                            visible: rect.statusKey !== "ok" && rect.statusMessage.length > 0
                            text: rect.statusMessage
                            color: "#D97706"
                            wrapMode: Text.WordWrap
                            width: parent.width
                            font.pixelSize: 12
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
                Layout.fillWidth: true
                Layout.leftMargin: 6
                text: "Численное решение задачи Коши"
                color: Theme.textMain
                font.pixelSize: 20
                font.family: "JetbrainsMono Nerd Font"
                font.bold: true
            }

            Text {
                Layout.fillWidth: true
                Layout.leftMargin: 6
                visible: rect.hasResult && rect.statusKey === "ok"
                text: rect.resultTitle + "   [" + rect.numStr(rect.x0) + ", " + rect.numStr(rect.xn) + "],   h = " + rect.numStr(rect.h) + ",   ε = " + rect.numStr(rect.eps)
                color: Theme.textDimmed
                font.pixelSize: 14
                font.family: "JetbrainsMono Nerd Font"
            }

            Text {
                Layout.leftMargin: 6
                text: "Оценка точности методов"
                color: Theme.textMain
                font.pixelSize: 16
                font.family: "JetbrainsMono Nerd Font"
                font.bold: true
                visible: rect.hasResult && rect.statusKey === "ok"
            }

            MyRect {
                Layout.fillWidth: true
                Layout.preferredHeight: methodsColumn.implicitHeight + 16
                color: Theme.bg
                visible: rect.hasResult && rect.statusKey === "ok"

                Column {
                    id: methodsColumn
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 6

                    RowLayout {
                        width: parent.width
                        spacing: 10
                        Text {
                            Layout.preferredWidth: 64
                            text: "График"
                            color: Theme.textMain
                            font.bold: true
                            font.family: "JetbrainsMono Nerd Font"
                            font.pixelSize: 13
                            horizontalAlignment: Text.AlignHCenter
                        }
                        Text {
                            Layout.preferredWidth: 180
                            Layout.minimumWidth: 140
                            text: "Метод"
                            color: Theme.textMain
                            font.bold: true
                            font.family: "JetbrainsMono Nerd Font"
                            font.pixelSize: 13
                        }
                        Text {
                            Layout.preferredWidth: 36
                            text: "p"
                            color: Theme.textMain
                            font.bold: true
                            font.family: "JetbrainsMono Nerd Font"
                            font.pixelSize: 13
                            horizontalAlignment: Text.AlignHCenter
                        }
                        Text {
                            Layout.preferredWidth: 110
                            text: "R (Рунге)"
                            color: Theme.textMain
                            font.bold: true
                            font.family: "JetbrainsMono Nerd Font"
                            font.pixelSize: 13
                            horizontalAlignment: Text.AlignRight
                        }
                        Text {
                            Layout.preferredWidth: 120
                            text: "max|y−yₜ|"
                            color: Theme.textMain
                            font.bold: true
                            font.family: "JetbrainsMono Nerd Font"
                            font.pixelSize: 13
                            horizontalAlignment: Text.AlignRight
                        }
                        Text {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 150
                            text: "шаг по ε (узлов)"
                            color: Theme.textMain
                            font.bold: true
                            font.family: "JetbrainsMono Nerd Font"
                            font.pixelSize: 13
                            horizontalAlignment: Text.AlignRight
                        }
                    }

                    Repeater {
                        model: rect.methods
                        delegate: RowLayout {
                            id: methodRow
                            required property var modelData
                            width: parent.width
                            spacing: 10
                            readonly property bool curveVisible: root.legendChecked(modelData.key)
                            readonly property color curveColor: rect.methodColor(modelData.key)

                            Item {
                                Layout.preferredWidth: 64
                                Layout.preferredHeight: 26

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 50
                                    height: 24
                                    radius: 5
                                    color: methodRow.curveVisible ? methodRow.curveColor : "transparent"
                                    border.color: methodRow.curveColor
                                    border.width: 1.5
                                    opacity: toggleArea.containsMouse ? 0.82 : 1.0
                                    scale: toggleArea.containsMouse ? 1.06 : 1.0
                                    Behavior on scale {
                                        NumberAnimation { duration: 120 }
                                    }
                                    Behavior on color {
                                        ColorAnimation { duration: 120 }
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: methodRow.curveVisible ? "вкл" : "выкл"
                                        color: methodRow.curveVisible ? "#ffffff" : methodRow.curveColor
                                        font.family: "JetbrainsMono Nerd Font"
                                        font.pixelSize: 11
                                        font.bold: true
                                    }

                                    MouseArea {
                                        id: toggleArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.legendToggle(methodRow.modelData.key);
                                            graphView.refresh();
                                        }
                                    }
                                }
                            }

                            Text {
                                Layout.preferredWidth: 180
                                Layout.minimumWidth: 140
                                text: methodRow.modelData.title
                                color: Theme.textMain
                                font.family: "JetbrainsMono Nerd Font"
                                font.pixelSize: 13
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.preferredWidth: 36
                                text: methodRow.modelData.order
                                color: Theme.textMain
                                font.family: "JetbrainsMono Nerd Font"
                                font.pixelSize: 13
                                horizontalAlignment: Text.AlignHCenter
                            }
                            Text {
                                Layout.preferredWidth: 110
                                text: methodRow.modelData.usesRunge ? rect.expo(methodRow.modelData.runge) : "—"
                                color: Theme.textMain
                                font.family: "JetbrainsMono Nerd Font"
                                font.pixelSize: 13
                                horizontalAlignment: Text.AlignRight
                            }
                            Text {
                                Layout.preferredWidth: 120
                                text: rect.expo(methodRow.modelData.exactError)
                                color: Theme.textMain
                                font.family: "JetbrainsMono Nerd Font"
                                font.pixelSize: 13
                                horizontalAlignment: Text.AlignRight
                            }
                            Text {
                                Layout.fillWidth: true
                                Layout.minimumWidth: 150
                                text: methodRow.modelData.usesRunge ? (rect.numStr(methodRow.modelData.refinedStep) + "  (" + methodRow.modelData.refinedSteps + ")") : "—"
                                color: methodRow.modelData.usesRunge ? Theme.textMain : Theme.textDimmed
                                font.family: "JetbrainsMono Nerd Font"
                                font.pixelSize: 13
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                Layout.leftMargin: 6
                text: "Метод Милна — многошаговый, правило Рунге неприменимо; его погрешность оценивается по точному решению (колонка max|y−yₜ|)."
                color: Theme.textDimmed
                font.pixelSize: 12
                font.family: "JetbrainsMono Nerd Font"
                wrapMode: Text.WordWrap
                visible: rect.hasResult && rect.statusKey === "ok"
            }

            Text {
                Layout.leftMargin: 6
                text: "Таблица решений"
                color: Theme.textMain
                font.pixelSize: 16
                font.family: "JetbrainsMono Nerd Font"
                font.bold: true
                visible: rect.hasResult && rect.statusKey === "ok"
            }

            MyRect {
                Layout.fillWidth: true
                Layout.preferredHeight: 200
                color: Theme.bg
                visible: rect.hasResult && rect.statusKey === "ok"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.rightMargin: 12
                        spacing: 6
                        Repeater {
                            model: ["xᵢ", "y точное", "y Эйлер", "y РК4", "y Милна"]
                            delegate: Text {
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                                text: modelData
                                color: Theme.textDimmed
                                font.family: "JetbrainsMono Nerd Font"
                                font.pixelSize: 13
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }

                    ListView {
                        id: tableList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: rect.table
                        boundsBehavior: Flickable.StopAtBounds
                        ScrollBar.vertical: ScrollBar {}

                        delegate: Row {
                            id: tableRow
                            required property var modelData
                            required property int index
                            width: tableList.width - 12
                            height: 24

                            readonly property var cells: [modelData.x, modelData.exact, modelData.improved_euler, modelData.rk4, modelData.milne]

                            Repeater {
                                model: tableRow.cells
                                delegate: Text {
                                    required property var modelData
                                    required property int index
                                    width: tableRow.width / 5
                                    height: 24
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignHCenter
                                    text: index === 0 ? Number(modelData).toFixed(4) : rect.formattedNumber(modelData)
                                    color: Theme.textMain
                                    font.family: "JetbrainsMono Nerd Font"
                                    font.pixelSize: 13
                                }
                            }
                        }
                    }
                }
            }

            Row {
                spacing: 18
                Layout.leftMargin: 6
                visible: rect.hasResult && rect.statusKey === "ok"

                Repeater {
                    model: [
                        { "label": "Точное решение", "color": "#0EA5E9", "p": "exact" }
                    ]
                    delegate: Row {
                        id: legendRow
                        required property var modelData
                        readonly property bool checked: root.legendChecked(modelData.p)
                        spacing: 6

                        Rectangle {
                            width: 18
                            height: 18
                            radius: 4
                            anchors.verticalCenter: parent.verticalCenter
                            color: legendRow.checked ? legendRow.modelData.color : "transparent"
                            border.color: legendRow.modelData.color
                            border.width: 2
                            scale: legendArea.containsMouse ? 1.12 : 1.0
                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }
                            Behavior on scale {
                                NumberAnimation { duration: 120 }
                            }
                        }
                        Text {
                            text: legendRow.modelData.label
                            color: Theme.textMain
                            font.family: "JetbrainsMono Nerd Font"
                            font.pixelSize: 14
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        MouseArea {
                            id: legendArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.legendToggle(legendRow.modelData.p);
                                graphView.refresh();
                            }
                        }
                    }
                }
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

                property real plotMinX: 0
                property real plotMaxX: 1
                property real plotMinY: -1
                property real plotMaxY: 1

                function refresh() {
                    exactSeries.clear();
                    ieSeries.clear();
                    rk4Series.clear();
                    milneSeries.clear();
                    axisXLine.clear();
                    axisYLine.clear();

                    if (!rect.hasResult || rect.statusKey !== "ok" || rect.table.length < 1) {
                        return;
                    }

                    const xLo = rect.x0;
                    const xHi = rect.xn;
                    const pad = (xHi - xLo) * 0.04 || 0.5;
                    graphView.plotMinX = xLo - pad;
                    graphView.plotMaxX = xHi + pad;

                    let yLo = Number.POSITIVE_INFINITY;
                    let yHi = Number.NEGATIVE_INFINITY;

                    for (let i = 0; i < rect.table.length; ++i) {
                        const row = rect.table[i];
                        const xv = Number(row.x);
                        const ie = Number(row.improved_euler);
                        const rk = Number(row.rk4);
                        const ml = Number(row.milne);
                        if (rect.showImprovedEuler && Number.isFinite(ie)) {
                            ieSeries.append(xv, ie);
                            if (ie < yLo) yLo = ie;
                            if (ie > yHi) yHi = ie;
                        }
                        if (rect.showRk4 && Number.isFinite(rk)) {
                            rk4Series.append(xv, rk);
                            if (rk < yLo) yLo = rk;
                            if (rk > yHi) yHi = rk;
                        }
                        if (rect.showMilne && Number.isFinite(ml)) {
                            milneSeries.append(xv, ml);
                            if (ml < yLo) yLo = ml;
                            if (ml > yHi) yHi = ml;
                        }
                    }

                    if (rect.showExact) {
                        const es = backend.sampleOdeExact(rect.equationId, rect.x0, rect.y0, graphView.plotMinX, graphView.plotMaxX, 400);
                        for (let j = 0; j < es.length; ++j) {
                            const yv = Number(es[j].y);
                            if (!Number.isFinite(yv)) {
                                continue;
                            }
                            exactSeries.append(Number(es[j].x), yv);
                            if (yv < yLo) yLo = yv;
                            if (yv > yHi) yHi = yv;
                        }
                    }

                    if (!Number.isFinite(yLo) || !Number.isFinite(yHi)) {
                        yLo = -1;
                        yHi = 1;
                    }
                    if (Math.abs(yHi - yLo) < 1e-9) {
                        yLo -= 1;
                        yHi += 1;
                    }
                    const yPad = (yHi - yLo) * 0.1;
                    graphView.plotMinY = yLo - yPad;
                    graphView.plotMaxY = yHi + yPad;

                    if (graphView.plotMinY <= 0 && graphView.plotMaxY >= 0) {
                        axisXLine.append(graphView.plotMinX, 0);
                        axisXLine.append(graphView.plotMaxX, 0);
                    }
                    if (graphView.plotMinX <= 0 && graphView.plotMaxX >= 0) {
                        axisYLine.append(0, graphView.plotMinY);
                        axisYLine.append(0, graphView.plotMaxY);
                    }
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
                LineSeries {
                    id: axisXLine
                    axisX: axisX
                    axisY: axisY
                    color: Theme.textDimmed
                    width: 1.2
                    style: Qt.DashLine
                }
                LineSeries {
                    id: axisYLine
                    axisX: axisX
                    axisY: axisY
                    color: Theme.textDimmed
                    width: 1.2
                    style: Qt.DashLine
                }
                LineSeries {
                    id: ieSeries
                    axisX: axisX
                    axisY: axisY
                    color: "#16A34A"
                    width: 2
                    pointsVisible: true
                }
                LineSeries {
                    id: rk4Series
                    axisX: axisX
                    axisY: axisY
                    color: "#9333EA"
                    width: 2
                    pointsVisible: true
                }
                LineSeries {
                    id: milneSeries
                    axisX: axisX
                    axisY: axisY
                    color: "#DB2777"
                    width: 2
                    pointsVisible: true
                }
                LineSeries {
                    id: exactSeries
                    axisX: axisX
                    axisY: axisY
                    color: rect.exactColor
                    width: 2.5
                }
            }
        }
    }

    function legendChecked(key) {
        switch (key) {
        case "exact":
            return rect.showExact;
        case "improved_euler":
            return rect.showImprovedEuler;
        case "rk4":
            return rect.showRk4;
        case "milne":
            return rect.showMilne;
        }
        return false;
    }

    function legendToggle(key) {
        switch (key) {
        case "exact":
            rect.showExact = !rect.showExact;
            break;
        case "improved_euler":
            rect.showImprovedEuler = !rect.showImprovedEuler;
            break;
        case "rk4":
            rect.showRk4 = !rect.showRk4;
            break;
        case "milne":
            rect.showMilne = !rect.showMilne;
            break;
        }
    }
}
