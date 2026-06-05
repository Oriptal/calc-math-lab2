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
        Layout.preferredWidth: 360

        property int inputMode: 0

        property int currentSize: 7
        property var xValues: ["2.10", "2.15", "2.20", "2.25", "2.30", "2.35", "2.40"]
        property var yValues: ["3.7587", "4.1861", "4.9218", "5.3487", "5.9275", "6.4193", "7.0839"]
        property string targetX: "2.112"

        property var functions: []
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
        property bool showFunc: true
        property var visibleMethods: ({})

        function methodColor(key) {
            switch (key) {
            case "lagrange":
                return "#2563EB";
            case "newton_fwd":
                return "#16A34A";
            case "newton_bwd":
                return "#0EA5E9";
            case "gauss1":
                return "#9333EA";
            case "gauss2":
                return "#BE123C";
            case "stirling":
                return "#DB2777";
            case "bessel":
                return "#CA8A04";
            default:
                return Theme.textDimmed;
            }
        }

        function setMethodVisible(key, on) {
            const v = Object.assign({}, rect.visibleMethods);
            v[key] = on;
            rect.visibleMethods = v;
        }

        function isMethodVisible(key) {
            return rect.visibleMethods[key] === true;
        }

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
                const v = {};
                for (let i = 0; i < rect.methods.length; ++i) {
                    const m = rect.methods[i];
                    v[m.key] = m.statusKey === "ok" && m.key === "lagrange";
                }
                rect.visibleMethods = v;
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

        function factorialOf(k) {
            let f = 1;
            for (let i = 2; i <= k; ++i) {
                f *= i;
            }
            return f;
        }

        function superscriptNum(k) {
            const map = { "0": "⁰", "1": "¹", "2": "²", "3": "³", "4": "⁴", "5": "⁵", "6": "⁶", "7": "⁷", "8": "⁸", "9": "⁹" };
            return String(k).split("").map(d => map[d] !== undefined ? map[d] : d).join("");
        }

        function compactNumber(value) {
            const a = Math.abs(value);
            if (a !== 0 && (a < 1e-4 || a >= 1e6)) {
                return a.toExponential(3);
            }
            return String(Number(a.toPrecision(5)));
        }

        function polyEquation() {
            if (!rect.diffTable || rect.diffTable.length === 0 || rect.nodes.length < 2) {
                return "";
            }
            const parts = [];
            for (let k = 0; k < rect.diffTable.length; ++k) {
                if (rect.diffTable[k].length === 0) {
                    continue;
                }
                const coef = Number(rect.diffTable[k][0]) / rect.factorialOf(k);
                if (k > 0 && Math.abs(coef) < 1e-12) {
                    continue;
                }
                let factor = "";
                if (k >= 1) {
                    factor = "·q";
                    for (let j = 1; j < k; ++j) {
                        factor += "(q−" + j + ")";
                    }
                }
                const term = rect.compactNumber(coef) + factor;
                if (parts.length === 0) {
                    parts.push((coef < 0 ? "−" : "") + term);
                } else {
                    parts.push((coef < 0 ? " − " : " + ") + term);
                }
            }
            return parts.length > 0 ? "P(x) = " + parts.join("") : "";
        }

        function qDefinition() {
            if (rect.nodes.length < 2) {
                return "";
            }
            const x0 = Number(rect.nodes[0].x);
            const h = Number(rect.nodes[1].x) - x0;
            const x0part = (x0 < 0 ? "+ " : "− ") + rect.compactNumber(x0);
            return "q = (x " + x0part + ") / " + rect.compactNumber(h);
        }

        Backend {
            id: backend
        }

        Component.onCompleted: {
            rect.functions = backend.interpolationFunctions();
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
                        text: "Способ ввода"
                    }
                }

                Row {
                    width: parent.width
                    spacing: 6

                    Repeater {
                        model: [
                            { "k": 0, "t": "Вручную" },
                            { "k": 1, "t": "Функция" }
                        ]
                        delegate: Rectangle {
                            id: tab
                            required property var modelData
                            readonly property bool sel: rect.inputMode === modelData.k
                            width: (mainColumn.width - 6) / 2
                            height: 40
                            radius: 4
                            color: sel ? Theme.accent : (tabArea.containsMouse ? Qt.lighter(Theme.bg, 1.5) : Theme.bg)
                            border.width: 1
                            border.color: sel ? Theme.accent : Theme.border
                            scale: (tabArea.containsMouse && !sel) ? 1.04 : 1.0

                            Behavior on color {
                                ColorAnimation { duration: 180 }
                            }
                            Behavior on border.color {
                                ColorAnimation { duration: 180 }
                            }
                            Behavior on scale {
                                NumberAnimation { duration: 120 }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: tab.modelData.t
                                color: tab.sel ? "#ffffff" : Theme.textMain
                                font.family: "JetbrainsMono Nerd Font"
                                font.pixelSize: 14
                            }

                            MouseArea {
                                id: tabArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: rect.inputMode = tab.modelData.k
                            }
                        }
                    }
                }

                MyRect {
                    height: 50
                    width: parent.width
                    border.color: "transparent"
                    visible: rect.inputMode === 0
                    MyText {
                        text: "Количество точек"
                    }
                }

                Item {
                    width: parent.width
                    height: 44
                    visible: rect.inputMode === 0

                    MyButton {
                        text: "−"
                        width: 44
                        height: 44
                        anchors.left: parent.left
                        anchors.leftMargin: 20
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
                        width: 44
                        height: 44
                        anchors.right: parent.right
                        anchors.rightMargin: 20
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
                    visible: rect.inputMode === 0
                    MyText {
                        text: "Таблица (xᵢ, yᵢ)"
                    }
                }

                Column {
                    width: parent.width - 40
                    x: 20
                    spacing: 4
                    visible: rect.inputMode === 0

                    Row {
                        width: parent.width
                        spacing: 8
                        Text {
                            width: (parent.width - 8) / 2
                            text: "xᵢ"
                            color: Theme.textDimmed
                            horizontalAlignment: Text.AlignHCenter
                            font.family: "JetbrainsMono Nerd Font"
                            font.pixelSize: 14
                        }
                        Text {
                            width: (parent.width - 8) / 2
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
                            width: parent.width
                            spacing: 8

                            MyTextField {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 36
                                horizontalAlignment: TextInput.AlignHCenter
                                font.pixelSize: 14
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
                                Layout.preferredHeight: 36
                                horizontalAlignment: TextInput.AlignHCenter
                                font.pixelSize: 14
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

                MyButton {
                    width: parent.width - 40
                    x: 20
                    height: 46
                    text: "Из файла…"
                    leftAligned: false
                    bold: true
                    visible: rect.inputMode === 0
                    normalColor: Theme.bg
                    hoverColor: Qt.lighter(Theme.bg, 1.5)
                    textNormalColor: Theme.accent
                    textHoverColor: Theme.textMain
                    onClicked: fileDialog.open()
                }

                MyRect {
                    height: 50
                    width: parent.width
                    border.color: "transparent"
                    visible: rect.inputMode === 1
                    MyText {
                        text: "Функция"
                    }
                }

                Column {
                    width: parent.width
                    spacing: 4
                    visible: rect.inputMode === 1

                    Repeater {
                        model: rect.functions
                        delegate: EquationCard {
                            required property var modelData
                            source: `../assets/func${modelData.id}.svg`
                            active: rect.funcId === modelData.id
                            onClicked: rect.funcId = modelData.id
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: 8
                    visible: rect.inputMode === 1

                    Repeater {
                        model: [
                            { "key": "a", "label": "a:", "ph": "Левая граница" },
                            { "key": "b", "label": "b:", "ph": "Правая граница" },
                            { "key": "n", "label": "n:", "ph": "Число узлов" }
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
                                Layout.preferredWidth: 28
                                font.pixelSize: 20
                                font.family: "JetbrainsMono Nerd Font"
                            }
                            MyTextField {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                Layout.rightMargin: 20
                                placeholderText: fieldRow.modelData.ph
                                text: fieldRow.modelData.key === "a" ? rect.funcA : (fieldRow.modelData.key === "b" ? rect.funcB : String(rect.funcN))
                                validator: RegularExpressionValidator {
                                    regularExpression: /-?\d*([.,]\d*)?/
                                }
                                onTextEdited: {
                                    if (fieldRow.modelData.key === "a")
                                        rect.funcA = text;
                                    else if (fieldRow.modelData.key === "b")
                                        rect.funcB = text;
                                    else
                                        rect.funcN = Number(text);
                                }
                            }
                        }
                    }

                    MyButton {
                        width: parent.width - 40
                        x: 20
                        height: 46
                        text: "Сгенерировать"
                        leftAligned: false
                        bold: true
                        textNormalColor: Theme.textMain
                        textHoverColor: Theme.textDimmed
                        onClicked: rect.generateFromFunction()
                    }
                }

                MyRect {
                    height: 50
                    width: parent.width
                    border.color: "transparent"
                    MyText {
                        text: "Точка интерполяции X*"
                    }
                }

                Item {
                    width: parent.width
                    height: 40

                    MyTextField {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 20
                        anchors.rightMargin: 20
                        height: 40
                        horizontalAlignment: TextInput.AlignHCenter
                        text: rect.targetX
                        validator: RegularExpressionValidator {
                            regularExpression: /-?\d*([.,]\d*)?/
                        }
                        onTextEdited: rect.targetX = text
                    }
                }

                Item {
                    width: parent.width
                    height: 64

                    MyButton {
                        id: calculateButton
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
                Layout.preferredHeight: diffColumn.implicitHeight + 16
                color: Theme.bg
                visible: rect.hasResult && rect.statusKey === "ok" && rect.equidistant

                Column {
                    id: diffColumn
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 3

                    RowLayout {
                        width: parent.width
                        spacing: 6
                        Text {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            text: "xᵢ"
                            color: Theme.textDimmed
                            font.family: "JetbrainsMono Nerd Font"
                            font.pixelSize: 13
                            horizontalAlignment: Text.AlignHCenter
                        }
                        Repeater {
                            model: rect.diffTable.length
                            delegate: Text {
                                id: diffHeader
                                required property int index
                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                                function superscript(k) {
                                    const map = { "2": "²", "3": "³", "4": "⁴", "5": "⁵", "6": "⁶", "7": "⁷", "8": "⁸", "9": "⁹" };
                                    return map[String(k)] !== undefined ? map[String(k)] : "^" + k;
                                }
                                text: index === 0 ? "yᵢ" : "Δ" + (index > 1 ? superscript(index) : "") + "yᵢ"
                                color: Theme.textDimmed
                                font.family: "JetbrainsMono Nerd Font"
                                font.pixelSize: 13
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }

                    Repeater {
                        model: rect.nodes.length > 0 ? rect.nodes.length * 2 - 1 : 0
                        delegate: RowLayout {
                            id: diffRow
                            required property int index
                            width: parent.width
                            spacing: 6
                            Text {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                                text: (diffRow.index % 2 === 0) ? Number(rect.nodes[diffRow.index / 2].x).toFixed(3) : ""
                                color: Theme.textMain
                                font.family: "JetbrainsMono Nerd Font"
                                font.pixelSize: 13
                                horizontalAlignment: Text.AlignHCenter
                            }
                            Repeater {
                                model: rect.diffTable.length
                                delegate: Text {
                                    id: diffCell
                                    required property int index
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 1
                                    readonly property int srcRow: diffRow.index - diffCell.index
                                    readonly property bool filled: srcRow >= 0 && srcRow % 2 === 0 && srcRow / 2 < rect.diffTable[diffCell.index].length
                                    text: filled ? Number(rect.diffTable[diffCell.index][srcRow / 2]).toFixed(4) : ""
                                    color: Theme.textMain
                                    font.family: "JetbrainsMono Nerd Font"
                                    font.pixelSize: 13
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                        }
                    }
                }
            }

            Text {
                text: "Интерполяционный многочлен (1-я формула Ньютона)"
                color: Theme.textMain
                font.pixelSize: 16
                font.family: "JetbrainsMono Nerd Font"
                font.bold: true
                Layout.leftMargin: 6
                visible: rect.hasResult && rect.statusKey === "ok" && rect.equidistant
            }

            MyRect {
                Layout.fillWidth: true
                Layout.preferredHeight: polyColumn.implicitHeight + 16
                color: Theme.bg
                visible: rect.hasResult && rect.statusKey === "ok" && rect.equidistant

                Column {
                    id: polyColumn
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 6

                    Text {
                        width: parent.width
                        text: rect.polyEquation()
                        color: Theme.textMain
                        wrapMode: Text.WordWrap
                        font.family: "JetbrainsMono Nerd Font"
                        font.pixelSize: 14
                    }
                    Text {
                        width: parent.width
                        text: rect.qDefinition()
                        color: Theme.textDimmed
                        wrapMode: Text.WordWrap
                        font.family: "JetbrainsMono Nerd Font"
                        font.pixelSize: 13
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
                Layout.preferredHeight: methodsColumn.implicitHeight + 16
                color: Theme.bg
                visible: rect.hasResult && rect.statusKey === "ok"

                Column {
                    id: methodsColumn
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 4

                    RowLayout {
                        width: parent.width
                        spacing: 12
                        Text {
                            Layout.preferredWidth: 64
                            text: "График"
                            color: Theme.textMain
                            font.bold: true
                            font.family: "JetbrainsMono Nerd Font"
                            font.pixelSize: 14
                            horizontalAlignment: Text.AlignHCenter
                        }
                        Text {
                            Layout.preferredWidth: 190
                            Layout.minimumWidth: 160
                            text: "Метод"
                            color: Theme.textMain
                            font.bold: true
                            font.family: "JetbrainsMono Nerd Font"
                            font.pixelSize: 14
                        }
                        Text {
                            Layout.preferredWidth: 130
                            text: "P(X*)"
                            color: Theme.textMain
                            font.bold: true
                            font.family: "JetbrainsMono Nerd Font"
                            font.pixelSize: 14
                            horizontalAlignment: Text.AlignRight
                        }
                        Text {
                            Layout.preferredWidth: 80
                            text: "t"
                            color: Theme.textMain
                            font.bold: true
                            font.family: "JetbrainsMono Nerd Font"
                            font.pixelSize: 14
                            horizontalAlignment: Text.AlignRight
                        }
                        Text {
                            Layout.preferredWidth: 80
                            text: "степень"
                            color: Theme.textMain
                            font.bold: true
                            font.family: "JetbrainsMono Nerd Font"
                            font.pixelSize: 14
                            horizontalAlignment: Text.AlignRight
                        }
                        Text {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 180
                            text: ""
                            color: Theme.textMain
                            font.bold: true
                            font.family: "JetbrainsMono Nerd Font"
                            font.pixelSize: 14
                        }
                    }

                    Repeater {
                        model: rect.methods
                        delegate: RowLayout {
                            id: methodRow
                            required property var modelData
                            width: parent.width
                            spacing: 12
                            readonly property bool isOk: modelData.statusKey === "ok"
                            readonly property bool curveVisible: rect.isMethodVisible(modelData.key)
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
                                    border.color: methodRow.isOk ? methodRow.curveColor : Theme.textDimmed
                                    border.width: 1.5
                                    opacity: methodRow.isOk ? (toggleArea.containsMouse ? 0.82 : 1.0) : 0.4
                                    scale: toggleArea.containsMouse ? 1.06 : 1.0
                                    Behavior on scale {
                                        NumberAnimation { duration: 120 }
                                    }
                                    Behavior on color {
                                        ColorAnimation { duration: 120 }
                                    }

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
                                            rect.setMethodVisible(methodRow.modelData.key, !methodRow.curveVisible);
                                            graphView.refresh();
                                        }
                                    }
                                }
                            }

                            Text {
                                Layout.preferredWidth: 190
                                Layout.minimumWidth: 160
                                text: methodRow.modelData.title
                                color: methodRow.isOk ? Theme.textMain : Theme.textDimmed
                                font.family: "JetbrainsMono Nerd Font"
                                font.pixelSize: 14
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.preferredWidth: 130
                                text: methodRow.isOk ? rect.formattedNumber(Number(methodRow.modelData.value)) : "—"
                                color: methodRow.isOk ? Theme.textMain : Theme.textDimmed
                                font.family: "JetbrainsMono Nerd Font"
                                font.pixelSize: 14
                                horizontalAlignment: Text.AlignRight
                            }
                            Text {
                                Layout.preferredWidth: 80
                                text: (methodRow.isOk && methodRow.modelData.order > 0) ? Number(methodRow.modelData.t).toFixed(3) : "—"
                                color: Theme.textMain
                                font.family: "JetbrainsMono Nerd Font"
                                font.pixelSize: 13
                                horizontalAlignment: Text.AlignRight
                            }
                            Text {
                                Layout.preferredWidth: 80
                                text: methodRow.isOk ? methodRow.modelData.order : "—"
                                color: Theme.textMain
                                font.family: "JetbrainsMono Nerd Font"
                                font.pixelSize: 13
                                horizontalAlignment: Text.AlignRight
                            }
                            Text {
                                Layout.fillWidth: true
                                Layout.minimumWidth: 180
                                text: methodRow.isOk ? "" : methodRow.modelData.statusMessage
                                color: "#D97706"
                                font.family: "JetbrainsMono Nerd Font"
                                font.pixelSize: 13
                                elide: Text.ElideRight
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
                        { "label": "Узлы", "color": "#127846", "p": "nodes" },
                        { "label": "Функция", "color": "#D97706", "p": "func" }
                    ]
                    delegate: Row {
                        id: legendRow
                        required property var modelData
                        readonly property bool checked: modelData.p === "nodes" ? rect.showNodes : rect.showFunc
                        spacing: 6
                        visible: modelData.p !== "func" || rect.activeFunctionId >= 0

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
                                if (legendRow.modelData.p === "nodes")
                                    rect.showNodes = !rect.showNodes;
                                else
                                    rect.showFunc = !rect.showFunc;
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

                readonly property var seriesByKey: ({
                        "lagrange": lagrangeSeries,
                        "newton_fwd": newtonFwdSeries,
                        "newton_bwd": newtonBwdSeries,
                        "gauss1": gauss1Series,
                        "gauss2": gauss2Series,
                        "stirling": stirlingSeries,
                        "bessel": besselSeries
                    })

                function refresh() {
                    nodeSeries.clear();
                    funcSeries.clear();
                    targetSeries.clear();
                    axisXLine.clear();
                    axisYLine.clear();
                    for (const key in graphView.seriesByKey)
                        graphView.seriesByKey[key].clear();

                    if (!rect.hasResult || rect.statusKey !== "ok" || rect.nodes.length < 2) {
                        return;
                    }

                    let xLo = Number(rect.nodes[0].x);
                    let xHi = xLo;
                    for (let i = 0; i < rect.nodes.length; ++i) {
                        const xv = Number(rect.nodes[i].x);
                        if (xv < xLo)
                            xLo = xv;
                        if (xv > xHi)
                            xHi = xv;
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
                        if (yv < yLo)
                            yLo = yv;
                        if (yv > yHi)
                            yHi = yv;
                    }
                    const span = Math.max(yHi - yLo, 0.5);
                    const yClampLo = yLo - 1.5 * span;
                    const yClampHi = yHi + 1.5 * span;

                    if (rect.showNodes) {
                        for (let i = 0; i < points.length; ++i)
                            nodeSeries.append(points[i].x, points[i].y);
                    }

                    for (let m = 0; m < rect.methods.length; ++m) {
                        const meth = rect.methods[m];
                        const series = graphView.seriesByKey[meth.key];
                        if (series === undefined || meth.statusKey !== "ok" || !rect.isMethodVisible(meth.key)) {
                            continue;
                        }
                        const samples = backend.sampleInterpolationMethod(meth.key, points, xLo, xHi, 400);
                        for (let j = 0; j < samples.length; ++j) {
                            const yv = Number(samples[j].y);
                            if (!Number.isFinite(yv)) {
                                continue;
                            }
                            series.append(Number(samples[j].x), yv);
                            if (yv > yClampLo && yv < yClampHi) {
                                if (yv < yLo)
                                    yLo = yv;
                                if (yv > yHi)
                                    yHi = yv;
                            }
                        }
                    }

                    if (rect.showFunc && rect.activeFunctionId >= 0) {
                        const fs = backend.sampleInterpolationFunction(rect.activeFunctionId, xLo, xHi, 400);
                        for (let j = 0; j < fs.length; ++j) {
                            const yv = Number(fs[j].y);
                            funcSeries.append(Number(fs[j].x), yv);
                            if (yv < yLo)
                                yLo = yv;
                            if (yv > yHi)
                                yHi = yv;
                        }
                    }

                    targetSeries.append(rect.target, rect.targetValue);
                    if (rect.targetValue < yLo)
                        yLo = rect.targetValue;
                    if (rect.targetValue > yHi)
                        yHi = rect.targetValue;

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
                    id: newtonBwdSeries
                    axisX: axisX
                    axisY: axisY
                    color: "#0EA5E9"
                    width: 2
                    useOpenGL: true
                }
                LineSeries {
                    id: gauss1Series
                    axisX: axisX
                    axisY: axisY
                    color: "#9333EA"
                    width: 2
                    useOpenGL: true
                }
                LineSeries {
                    id: gauss2Series
                    axisX: axisX
                    axisY: axisY
                    color: "#BE123C"
                    width: 2
                    useOpenGL: true
                }
                LineSeries {
                    id: stirlingSeries
                    axisX: axisX
                    axisY: axisY
                    color: "#DB2777"
                    width: 2
                    useOpenGL: true
                }
                LineSeries {
                    id: besselSeries
                    axisX: axisX
                    axisY: axisY
                    color: "#CA8A04"
                    width: 2
                    useOpenGL: true
                }
                LineSeries {
                    id: newtonFwdSeries
                    axisX: axisX
                    axisY: axisY
                    color: "#16A34A"
                    width: 2
                    useOpenGL: true
                }
                LineSeries {
                    id: lagrangeSeries
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
                    markerSize: 12
                    color: Theme.accent
                    borderColor: "#ffffff"
                }
                ScatterSeries {
                    id: targetSeries
                    axisX: axisX
                    axisY: axisY
                    markerSize: 14
                    color: "#DC2626"
                    borderColor: "#ffffff"
                }
            }
        }
    }
}
