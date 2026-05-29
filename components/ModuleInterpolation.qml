pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import QtQuick.Dialogs
import QtCharts
import Calc 1.0
import ".."

RowLayout {
    id: root

    MyRect {
        id: rect
        Layout.fillHeight: true
        Layout.preferredWidth: 380

        property int inputMode: 0

        property int currentSize: 7
        property var xValues: ["2.10", "2.15", "2.20", "2.25", "2.30", "2.35", "2.40"]
        property var yValues: ["3.7587", "4.1861", "4.9218", "5.3487", "5.9275", "6.4193", "7.0839"]
        property string targetX: "2.112"

        property var functions: []
        property var datasets: []
        property int funcId: 0
        property string funcA: "0"
        property string funcB: "1.5"
        property int funcN: 7
        property int activeFunctionId: -1
        property real activeA: 0
        property real activeB: 1

        property bool hasResult: false
        property string statusKey: ""
        property string statusMessage: ""
        property var nodes: []
        property var methods: []
        property var diffTable: []
        property bool equidistant: false
        property real targetValue: 0
        property real target: 0

        property bool showNodes: true
        property bool showPoly: true
        property bool showFunc: true

        function makeEmptyArray(n) {
            return Array.from({ length: n }, () => "");
        }

        function resizeTo(n) {
            if (n < 2 || n > 20) {
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

        function setData(points) {
            const nx = [];
            const ny = [];
            for (let i = 0; i < points.length; ++i) {
                nx.push(String(points[i].x));
                ny.push(String(points[i].y));
            }
            rect.xValues = nx;
            rect.yValues = ny;
            rect.currentSize = points.length;
            rect.hasResult = false;
        }

        function applyDataset(id) {
            const r = backend.loadInterpolationDataset(id);
            if (r.status !== "ok") {
                rect.statusKey = "error";
                rect.statusMessage = r.message;
                rect.hasResult = true;
                return;
            }
            rect.activeFunctionId = -1;
            rect.setData(r.points);
            if (r.target !== undefined) {
                rect.targetX = String(r.target);
            }
        }

        function generateFromFunction() {
            const a = Number(String(rect.funcA).replace(",", "."));
            const b = Number(String(rect.funcB).replace(",", "."));
            if (!Number.isFinite(a) || !Number.isFinite(b) || b <= a || rect.funcN < 2) {
                rect.statusKey = "error";
                rect.statusMessage = "Проверьте интервал [a, b] и число узлов";
                rect.hasResult = true;
                return;
            }
            const pts = backend.sampleInterpolationFunction(rect.funcId, a, b, rect.funcN);
            rect.setData(pts);
            rect.activeFunctionId = rect.funcId;
            rect.activeA = a;
            rect.activeB = b;
        }

        function calculate() {
            const payload = [];
            for (let i = 0; i < rect.currentSize; ++i) {
                payload.push({ "x": rect.xValues[i], "y": rect.yValues[i] });
            }
            const response = backend.interpolate({ "points": payload, "target": rect.targetX });
            rect.statusKey = response.status;
            rect.statusMessage = response.message !== undefined ? response.message : "";
            if (response.status === "ok") {
                rect.nodes = response.nodes;
                rect.methods = response.methods;
                rect.diffTable = response.diffTable;
                rect.equidistant = response.equidistant;
                rect.target = response.target;
                rect.targetValue = response.methods.length > 0 ? Number(response.methods[0].value) : 0;
            } else {
                rect.nodes = [];
                rect.methods = [];
                rect.diffTable = [];
            }
            rect.hasResult = true;
            graphView.refresh();
        }

        function formattedNumber(value) {
            if (!Number.isFinite(value)) {
                return "—";
            }
            const abs = Math.abs(value);
            if (abs !== 0 && (abs < 1e-4 || abs >= 1e7)) {
                return Number(value).toExponential(4);
            }
            return Number(value).toFixed(5);
        }

        Backend {
            id: backend
        }

        Component.onCompleted: {
            rect.functions = backend.interpolationFunctions();
            rect.datasets = backend.interpolationDatasets();
        }

        FileDialog {
            id: fileDialog
            title: "Открыть файл данных"
            nameFilters: ["Текстовые данные (*.txt *.dat *.csv)", "Все файлы (*)"]
            onAccepted: {
                const r = backend.loadInterpolationFile(selectedFile);
                if (r.status !== "ok") {
                    rect.statusKey = "error";
                    rect.statusMessage = r.message;
                    rect.hasResult = true;
                    return;
                }
                rect.activeFunctionId = -1;
                rect.setData(r.points);
                if (r.target !== undefined) {
                    rect.targetX = String(r.target);
                }
            }
        }

        Flickable {
            anchors.fill: parent
            anchors.margins: 8
            contentHeight: leftColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: leftColumn
                width: parent.width
                spacing: 10

                Row {
                    width: parent.width
                    spacing: 6

                    Repeater {
                        model: [
                            { "k": 0, "t": "Вручную" },
                            { "k": 1, "t": "Из файла" },
                            { "k": 2, "t": "Функция" }
                        ]
                        delegate: Rectangle {
                            id: tabDelegate
                            required property var modelData
                            width: (leftColumn.width - 12) / 3
                            height: 34
                            radius: 4
                            color: rect.inputMode === modelData.k ? Theme.accent : Theme.bg
                            border.width: 1
                            border.color: rect.inputMode === modelData.k ? Theme.accent : Theme.border

                            Text {
                                anchors.centerIn: parent
                                text: tabDelegate.modelData.t
                                color: rect.inputMode === tabDelegate.modelData.k ? "#ffffff" : Theme.textMain
                                font.family: "JetbrainsMono Nerd Font"
                                font.pixelSize: 13
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: rect.inputMode = tabDelegate.modelData.k
                            }
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: 6
                    visible: rect.inputMode === 1

                    Text {
                        text: "Встроенные наборы"
                        color: Theme.textDimmed
                        font.family: "JetbrainsMono Nerd Font"
                        font.pixelSize: 13
                    }

                    Repeater {
                        model: rect.datasets
                        delegate: MyButton {
                            required property var modelData
                            width: leftColumn.width
                            height: 34
                            text: modelData.title
                            leftAligned: true
                            textNormalColor: Theme.textMain
                            textHoverColor: Theme.accent
                            onClicked: rect.applyDataset(modelData.id)
                        }
                    }

                    MyButton {
                        width: leftColumn.width
                        height: 36
                        text: "Открыть файл…"
                        leftAligned: false
                        bold: true
                        normalColor: Theme.bg
                        textNormalColor: Theme.accent
                        textHoverColor: Theme.textMain
                        onClicked: fileDialog.open()
                    }
                }

                Column {
                    width: parent.width
                    spacing: 6
                    visible: rect.inputMode === 2

                    Text {
                        text: "Функция y = f(x)"
                        color: Theme.textDimmed
                        font.family: "JetbrainsMono Nerd Font"
                        font.pixelSize: 13
                    }

                    Flow {
                        width: parent.width
                        spacing: 6
                        Repeater {
                            model: rect.functions
                            delegate: Rectangle {
                                id: funcDelegate
                                required property var modelData
                                width: (leftColumn.width - 12) / 3
                                height: 32
                                radius: 4
                                color: rect.funcId === modelData.id ? Theme.accent : Theme.bg
                                border.width: 1
                                border.color: rect.funcId === modelData.id ? Theme.accent : Theme.border

                                Text {
                                    anchors.centerIn: parent
                                    text: funcDelegate.modelData.title
                                    color: rect.funcId === funcDelegate.modelData.id ? "#ffffff" : Theme.textMain
                                    font.family: "JetbrainsMono Nerd Font"
                                    font.pixelSize: 12
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: rect.funcId = funcDelegate.modelData.id
                                }
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: 6

                        Column {
                            width: (parent.width - 12) / 3
                            spacing: 2
                            Text {
                                text: "a"
                                color: Theme.textDimmed
                                font.family: "JetbrainsMono Nerd Font"
                                font.pixelSize: 12
                            }
                            MyTextField {
                                width: parent.width
                                height: 30
                                text: rect.funcA
                                onTextEdited: rect.funcA = text
                            }
                        }
                        Column {
                            width: (parent.width - 12) / 3
                            spacing: 2
                            Text {
                                text: "b"
                                color: Theme.textDimmed
                                font.family: "JetbrainsMono Nerd Font"
                                font.pixelSize: 12
                            }
                            MyTextField {
                                width: parent.width
                                height: 30
                                text: rect.funcB
                                onTextEdited: rect.funcB = text
                            }
                        }
                        Column {
                            width: (parent.width - 12) / 3
                            spacing: 2
                            Text {
                                text: "узлов"
                                color: Theme.textDimmed
                                font.family: "JetbrainsMono Nerd Font"
                                font.pixelSize: 12
                            }
                            MyTextField {
                                width: parent.width
                                height: 30
                                text: String(rect.funcN)
                                validator: IntValidator { bottom: 2; top: 20 }
                                onTextEdited: rect.funcN = Number(text)
                            }
                        }
                    }

                    MyButton {
                        width: leftColumn.width
                        height: 36
                        text: "Сгенерировать"
                        leftAligned: false
                        bold: true
                        normalColor: Theme.bg
                        textNormalColor: Theme.accent
                        textHoverColor: Theme.textMain
                        onClicked: rect.generateFromFunction()
                    }
                }

                Item {
                    width: parent.width
                    height: 40
                    visible: rect.inputMode === 0

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
                        font.pixelSize: 18
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

                Text {
                    text: "Таблица (xᵢ, yᵢ)"
                    color: Theme.textMain
                    font.family: "JetbrainsMono Nerd Font"
                    font.pixelSize: 15
                }

                Row {
                    width: parent.width
                    spacing: 6
                    Text {
                        width: (parent.width - 6) / 2
                        text: "xᵢ"
                        color: Theme.textDimmed
                        horizontalAlignment: Text.AlignHCenter
                        font.family: "JetbrainsMono Nerd Font"
                        font.pixelSize: 13
                    }
                    Text {
                        width: (parent.width - 6) / 2
                        text: "yᵢ"
                        color: Theme.textDimmed
                        horizontalAlignment: Text.AlignHCenter
                        font.family: "JetbrainsMono Nerd Font"
                        font.pixelSize: 13
                    }
                }

                Column {
                    width: parent.width
                    spacing: 3

                    Repeater {
                        model: rect.currentSize
                        delegate: RowLayout {
                            id: tableRow
                            required property int index
                            width: leftColumn.width
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

                Text {
                    text: "Точка интерполяции X*"
                    color: Theme.textMain
                    font.family: "JetbrainsMono Nerd Font"
                    font.pixelSize: 15
                }
                MyTextField {
                    width: parent.width
                    height: 34
                    horizontalAlignment: TextInput.AlignHCenter
                    text: rect.targetX
                    validator: RegularExpressionValidator {
                        regularExpression: /-?\d*([.,]\d*)?/
                    }
                    onTextEdited: rect.targetX = text
                }

                MyButton {
                    width: parent.width
                    height: 48
                    text: "Рассчитать"
                    leftAligned: false
                    bold: true
                    textNormalColor: Theme.textMain
                    textHoverColor: Theme.textDimmed
                    onClicked: rect.calculate()
                }

                MyRect {
                    width: parent.width
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
                            text: rect.equidistant ? "Узлы равноотстоящие — применимы все методы" : "Узлы неравноотстоящие — применим только Лагранж"
                            color: rect.equidistant ? Theme.accent : "#D97706"
                            wrapMode: Text.WordWrap
                            width: parent.width
                            font.pixelSize: 12
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
                text: "Интерполяция функции"
                color: Theme.textMain
                font.pixelSize: 20
                font.family: "JetbrainsMono Nerd Font"
                font.bold: true
                Layout.leftMargin: 6
            }

            Text {
                text: "Таблица конечных разностей"
                color: Theme.textMain
                font.pixelSize: 16
                font.family: "JetbrainsMono Nerd Font"
                font.bold: true
                Layout.leftMargin: 6
                visible: rect.hasResult && rect.statusKey === "ok" && rect.equidistant
            }

            MyRect {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(diffFlick.contentHeight + 16, 220)
                color: Theme.bg
                visible: rect.hasResult && rect.statusKey === "ok" && rect.equidistant

                Flickable {
                    id: diffFlick
                    anchors.fill: parent
                    anchors.margins: 8
                    contentWidth: diffGrid.width
                    contentHeight: diffGrid.height
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: diffGrid
                        spacing: 2

                        Row {
                            spacing: 0
                            Text {
                                width: 70
                                text: "xᵢ"
                                color: Theme.textDimmed
                                font.family: "JetbrainsMono Nerd Font"
                                font.pixelSize: 12
                                horizontalAlignment: Text.AlignHCenter
                            }
                            Repeater {
                                model: rect.diffTable.length
                                delegate: Text {
                                    required property int index
                                    width: 80
                                    text: index === 0 ? "yᵢ" : "Δ" + (index > 1 ? "^" + index : "") + "yᵢ"
                                    color: Theme.textDimmed
                                    font.family: "JetbrainsMono Nerd Font"
                                    font.pixelSize: 12
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                        }

                        Repeater {
                            model: rect.nodes.length
                            delegate: Row {
                                id: diffRow
                                required property int index
                                spacing: 0
                                Text {
                                    width: 70
                                    text: Number(rect.nodes[diffRow.index].x).toFixed(3)
                                    color: Theme.textMain
                                    font.family: "JetbrainsMono Nerd Font"
                                    font.pixelSize: 12
                                    horizontalAlignment: Text.AlignHCenter
                                }
                                Repeater {
                                    model: rect.diffTable.length
                                    delegate: Text {
                                        required property int index
                                        width: 80
                                        text: diffRow.index < rect.diffTable[index].length ? Number(rect.diffTable[index][diffRow.index]).toFixed(4) : ""
                                        color: index === 0 ? Theme.textMain : Theme.accent
                                        font.family: "JetbrainsMono Nerd Font"
                                        font.pixelSize: 12
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Text {
                text: "Значения в точке X* = " + rect.formattedNumber(rect.target)
                color: Theme.textMain
                font.pixelSize: 16
                font.family: "JetbrainsMono Nerd Font"
                font.bold: true
                Layout.leftMargin: 6
                visible: rect.hasResult && rect.statusKey === "ok"
            }

            MyRect {
                Layout.fillWidth: true
                Layout.preferredHeight: methodsList.contentHeight + (methodsList.headerItem ? methodsList.headerItem.height : 0) + 16
                color: Theme.bg
                visible: rect.hasResult && rect.statusKey === "ok"

                ListView {
                    id: methodsList
                    anchors.fill: parent
                    anchors.margins: 8
                    clip: true
                    interactive: false
                    model: rect.methods
                    spacing: 2

                    header: Row {
                        spacing: 10
                        Text { width: 180; text: "Метод"; color: Theme.textMain; font.bold: true; font.family: "JetbrainsMono Nerd Font"; font.pixelSize: 13 }
                        Text { width: 120; text: "P(X*)"; color: Theme.textMain; font.bold: true; font.family: "JetbrainsMono Nerd Font"; font.pixelSize: 13; horizontalAlignment: Text.AlignRight }
                        Text { width: 70; text: "t"; color: Theme.textMain; font.bold: true; font.family: "JetbrainsMono Nerd Font"; font.pixelSize: 13; horizontalAlignment: Text.AlignRight }
                        Text { width: 60; text: "степень"; color: Theme.textMain; font.bold: true; font.family: "JetbrainsMono Nerd Font"; font.pixelSize: 13; horizontalAlignment: Text.AlignRight }
                        Text { width: 320; text: "Примечание"; color: Theme.textMain; font.bold: true; font.family: "JetbrainsMono Nerd Font"; font.pixelSize: 13 }
                    }

                    delegate: Row {
                        id: methodRow
                        required property var modelData
                        spacing: 10
                        readonly property bool isOk: modelData.statusKey === "ok"

                        Text {
                            width: 180
                            text: methodRow.modelData.title
                            color: methodRow.isOk ? Theme.textMain : Theme.textDimmed
                            font.family: "JetbrainsMono Nerd Font"
                            font.pixelSize: 13
                            elide: Text.ElideRight
                        }
                        Text {
                            width: 120
                            text: methodRow.isOk ? rect.formattedNumber(Number(methodRow.modelData.value)) : "—"
                            color: methodRow.isOk ? Theme.accent : Theme.textDimmed
                            font.family: "JetbrainsMono Nerd Font"
                            font.pixelSize: 13
                            horizontalAlignment: Text.AlignRight
                        }
                        Text {
                            width: 70
                            text: (methodRow.isOk && methodRow.modelData.order > 0) ? Number(methodRow.modelData.t).toFixed(3) : "—"
                            color: Theme.textMain
                            font.family: "JetbrainsMono Nerd Font"
                            font.pixelSize: 12
                            horizontalAlignment: Text.AlignRight
                        }
                        Text {
                            width: 60
                            text: methodRow.isOk ? methodRow.modelData.order : "—"
                            color: Theme.textMain
                            font.family: "JetbrainsMono Nerd Font"
                            font.pixelSize: 12
                            horizontalAlignment: Text.AlignRight
                        }
                        Text {
                            width: 320
                            text: methodRow.isOk ? methodRow.modelData.note : methodRow.modelData.statusMessage
                            color: methodRow.isOk ? Theme.textDimmed : "#D97706"
                            font.family: "JetbrainsMono Nerd Font"
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            Row {
                spacing: 16
                Layout.leftMargin: 6
                visible: rect.hasResult && rect.statusKey === "ok"

                Repeater {
                    model: [
                        { "label": "Узлы", "color": "#127846", "p": "nodes" },
                        { "label": "Многочлен", "color": "#2563EB", "p": "poly" },
                        { "label": "Функция", "color": "#D97706", "p": "func" }
                    ]
                    delegate: Row {
                        id: legendRow
                        required property var modelData
                        readonly property bool checked: modelData.p === "nodes" ? rect.showNodes : (modelData.p === "poly" ? rect.showPoly : rect.showFunc)
                        spacing: 6
                        visible: modelData.p !== "func" || rect.activeFunctionId >= 0

                        Rectangle {
                            width: 16
                            height: 16
                            radius: 3
                            anchors.verticalCenter: parent.verticalCenter
                            color: legendRow.checked ? legendRow.modelData.color : "transparent"
                            border.color: legendRow.modelData.color
                            border.width: 2
                        }
                        Text {
                            text: legendRow.modelData.label
                            color: Theme.textMain
                            font.family: "JetbrainsMono Nerd Font"
                            font.pixelSize: 13
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (legendRow.modelData.p === "nodes") rect.showNodes = !rect.showNodes;
                                else if (legendRow.modelData.p === "poly") rect.showPoly = !rect.showPoly;
                                else rect.showFunc = !rect.showFunc;
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
                    nodeSeries.clear();
                    polySeries.clear();
                    funcSeries.clear();
                    targetSeries.clear();
                    axisXLine.clear();
                    axisYLine.clear();

                    if (!rect.hasResult || rect.statusKey !== "ok" || rect.nodes.length < 2) {
                        return;
                    }

                    let xLo = Number(rect.nodes[0].x);
                    let xHi = xLo;
                    for (let i = 0; i < rect.nodes.length; ++i) {
                        const xv = Number(rect.nodes[i].x);
                        if (xv < xLo) xLo = xv;
                        if (xv > xHi) xHi = xv;
                    }
                    xLo = Math.min(xLo, rect.target);
                    xHi = Math.max(xHi, rect.target);
                    const pad = (xHi - xLo) * 0.08 || 0.5;
                    xLo -= pad;
                    xHi += pad;
                    graphView.plotMinX = xLo;
                    graphView.plotMaxX = xHi;

                    let yLo = Number.POSITIVE_INFINITY;
                    let yHi = Number.NEGATIVE_INFINITY;
                    const points = [];
                    for (let i = 0; i < rect.nodes.length; ++i) {
                        const xv = Number(rect.nodes[i].x);
                        const yv = Number(rect.nodes[i].y);
                        points.push({ "x": xv, "y": yv });
                        if (yv < yLo) yLo = yv;
                        if (yv > yHi) yHi = yv;
                    }
                    const span = Math.max(yHi - yLo, 0.5);
                    const yClampLo = yLo - 1.5 * span;
                    const yClampHi = yHi + 1.5 * span;

                    if (rect.showNodes) {
                        for (let i = 0; i < points.length; ++i) {
                            nodeSeries.append(points[i].x, points[i].y);
                        }
                    }

                    if (rect.showPoly) {
                        const samples = backend.sampleInterpolation(points, xLo, xHi, 400);
                        for (let j = 0; j < samples.length; ++j) {
                            const yv = Number(samples[j].y);
                            polySeries.append(Number(samples[j].x), yv);
                            if (yv > yClampLo && yv < yClampHi) {
                                if (yv < yLo) yLo = yv;
                                if (yv > yHi) yHi = yv;
                            }
                        }
                    }

                    if (rect.showFunc && rect.activeFunctionId >= 0) {
                        const fs = backend.sampleInterpolationFunction(rect.activeFunctionId, xLo, xHi, 400);
                        for (let j = 0; j < fs.length; ++j) {
                            const yv = Number(fs[j].y);
                            funcSeries.append(Number(fs[j].x), yv);
                            if (yv < yLo) yLo = yv;
                            if (yv > yHi) yHi = yv;
                        }
                    }

                    targetSeries.append(rect.target, rect.targetValue);
                    if (rect.targetValue < yLo) yLo = rect.targetValue;
                    if (rect.targetValue > yHi) yHi = rect.targetValue;

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
                        axisXLine.append(xLo, 0);
                        axisXLine.append(xHi, 0);
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
                    id: funcSeries
                    axisX: axisX
                    axisY: axisY
                    color: "#D97706"
                    width: 2
                    style: Qt.DashLine
                    useOpenGL: true
                }
                LineSeries {
                    id: polySeries
                    axisX: axisX
                    axisY: axisY
                    color: "#2563EB"
                    width: 2
                    useOpenGL: true
                }
                ScatterSeries {
                    id: nodeSeries
                    axisX: axisX
                    axisY: axisY
                    markerSize: 11
                    color: Theme.accent
                    borderColor: "#ffffff"
                }
                ScatterSeries {
                    id: targetSeries
                    axisX: axisX
                    axisY: axisY
                    markerSize: 13
                    color: "#DC2626"
                    borderColor: "#ffffff"
                }
            }
        }
    }
}
