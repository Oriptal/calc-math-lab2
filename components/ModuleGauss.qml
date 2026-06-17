pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Calc 1.0
import ".."

RowLayout {
    id: root

    MyRect {
        id: rect
        Layout.fillHeight: true
        Layout.preferredWidth: 350

        property int currentSize: 3
        property int resultStatus: -1
        property bool hasResult: false
        property real determinant: Number.NaN
        property var solution: []
        property var residuals: []
        property var triangular: []
        property var reducedAugmentation: []
        property string errorMessage: ""

        property var matrixValues: rect.makeEmptyMatrix(3)
        property var augmentationValues: rect.makeEmptyAugmentation(3)

        function makeEmptyMatrix(n) {
            const out = [];
            for (let i = 0; i < n; ++i) {
                const row = [];
                for (let j = 0; j < n; ++j) {
                    row.push("");
                }
                out.push(row);
            }
            return out;
        }

        function makeEmptyAugmentation(n) {
            return Array.from({
                length: n
            }, () => "");
        }

        function statusText(status) {
            switch (status) {
            case 0:
                return "Единственное решение";
            case 1:
                return "Нет решений";
            case 2:
                return "Бесконечно много решений";
            case 3:
                return "Некорректный ввод";
            default:
                return "Ошибка";
            }
        }

        function statusHint(status) {
            switch (status) {
            case 0:
                return "СЛАУ имеет единственное решение, найдены неизвестные и невязки.";
            case 1:
                return "Ранг расширенной матрицы > ранга основной.";
            case 2:
                return "Свободные переменные присутствуют — система недоопределена.";
            case 3:
                return rect.errorMessage.length > 0 ? rect.errorMessage : "Проверьте размерность и значения коэффициентов.";
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
                return "#DC2626";
            default:
                return Theme.textDimmed;
            }
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

        function resizeTo(n) {
            if (n < 1 || n > 20) {
                return;
            }
            const newMatrix = rect.makeEmptyMatrix(n);
            const newAug = rect.makeEmptyAugmentation(n);
            const oldN = rect.matrixValues.length;
            for (let i = 0; i < Math.min(n, oldN); ++i) {
                for (let j = 0; j < Math.min(n, rect.matrixValues[i].length); ++j) {
                    newMatrix[i][j] = rect.matrixValues[i][j];
                }
                newAug[i] = rect.augmentationValues[i];
            }
            rect.matrixValues = newMatrix;
            rect.augmentationValues = newAug;
            rect.currentSize = n;
            rect.hasResult = false;
        }

        function applyFromGenerated(matrix, augmentation) {
            const n = matrix.length;
            const newMatrix = rect.makeEmptyMatrix(n);
            const newAug = rect.makeEmptyAugmentation(n);
            for (let i = 0; i < n; ++i) {
                for (let j = 0; j < n; ++j) {
                    newMatrix[i][j] = Number(matrix[i][j]).toFixed(3);
                }
                newAug[i] = Number(augmentation[i]).toFixed(3);
            }
            rect.matrixValues = newMatrix;
            rect.augmentationValues = newAug;
            rect.currentSize = n;
            rect.hasResult = false;
        }

        Backend {
            id: backend
        }

        Flickable {
            anchors.fill: parent
            anchors.margins: 5
            contentHeight: leftColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: leftColumn
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
                            text: "Размерность"
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
                            text: "Матрица [A | b]"
                        }
                    }

                    Column {
                        id: matrixBlock
                        width: parent.width - 40
                        x: 20
                        spacing: 4

                        Repeater {
                            model: rect.currentSize

                            delegate: RowLayout {
                                id: matrixRow
                                required property int index
                                width: matrixBlock.width
                                spacing: 3

                                Repeater {
                                    model: rect.currentSize

                                    delegate: MyTextField {
                                        required property int index
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 30
                                        Layout.minimumWidth: 28
                                        horizontalAlignment: TextInput.AlignHCenter
                                        font.pixelSize: 12
                                        placeholderText: "0"
                                        text: rect.matrixValues[matrixRow.index] && rect.matrixValues[matrixRow.index][index] !== undefined ? rect.matrixValues[matrixRow.index][index] : ""

                                        validator: RegularExpressionValidator {
                                            regularExpression: /-?\d*([.,]\d*)?/
                                        }

                                        onTextEdited: {
                                            const m = rect.matrixValues.slice();
                                            m[matrixRow.index] = m[matrixRow.index].slice();
                                            m[matrixRow.index][index] = text;
                                            rect.matrixValues = m;
                                        }
                                    }
                                }

                                Rectangle {
                                    Layout.preferredWidth: 1
                                    Layout.preferredHeight: 22
                                    Layout.alignment: Qt.AlignVCenter
                                    color: Theme.border
                                }

                                MyTextField {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 30
                                    Layout.minimumWidth: 28
                                    horizontalAlignment: TextInput.AlignHCenter
                                    font.pixelSize: 12
                                    placeholderText: "b"
                                    text: rect.augmentationValues[matrixRow.index] !== undefined ? rect.augmentationValues[matrixRow.index] : ""

                                    validator: RegularExpressionValidator {
                                        regularExpression: /-?\d*([.,]\d*)?/
                                    }

                                    onTextEdited: {
                                        const a = rect.augmentationValues.slice();
                                        a[matrixRow.index] = text;
                                        rect.augmentationValues = a;
                                    }
                                }
                            }
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: 28
                }

                MyButton {
                    id: randomButton
                    text: "Случайные коэффициенты"
                    width: parent.width - 50
                    height: 50
                    anchors.horizontalCenter: parent.horizontalCenter
                    textNormalColor: Theme.textMain
                    textHoverColor: Theme.textDimmed
                    leftAligned: false
                    bold: true

                    onClicked: {
                        const response = backend.generateLinearSystem(rect.currentSize);
                        if (response.status === 0) {
                            rect.applyFromGenerated(response.matrix, response.augmentation);
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: 10
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
                        const payload = {
                            "size": rect.currentSize,
                            "matrix": rect.matrixValues,
                            "augmentation": rect.augmentationValues
                        };
                        const response = backend.solveLinearSystem(payload);
                        rect.resultStatus = response.status;
                        rect.errorMessage = response.message !== undefined ? response.message : "";
                        if (response.status === 0) {
                            rect.determinant = response.determinant;
                            rect.solution = response.solution;
                            rect.residuals = response.residuals;
                            rect.triangular = response.triangular;
                            rect.reducedAugmentation = response.reducedAugmentation;
                        } else {
                            rect.determinant = response.determinant !== undefined ? response.determinant : Number.NaN;
                            rect.solution = [];
                            rect.residuals = [];
                            rect.triangular = response.triangular !== undefined ? response.triangular : [];
                            rect.reducedAugmentation = response.reducedAugmentation !== undefined ? response.reducedAugmentation : [];
                        }
                        rect.hasResult = true;
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
            spacing: 12

            Text {
                Layout.fillWidth: true
                text: "Решение СЛАУ методом Гаусса"
                color: Theme.textMain
                font.pixelSize: 22
                font.family: "JetbrainsMono Nerd Font"
                font.bold: true
                Layout.leftMargin: 6
            }

            MyRect {
                visible: rect.hasResult
                Layout.fillWidth: true
                Layout.preferredHeight: statusColumn.implicitHeight + 24
                color: Theme.bg

                Column {
                    id: statusColumn
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 6

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
                        width: statusColumn.width
                        font.pixelSize: 14
                        font.family: "JetbrainsMono Nerd Font"
                    }

                    Text {
                        visible: Number.isFinite(rect.determinant)
                        text: "det(A) = " + rect.formattedNumber(rect.determinant)
                        color: Theme.accent
                        font.pixelSize: 17
                        font.bold: true
                        font.family: "JetbrainsMono Nerd Font"
                    }
                }
            }

            ColumnLayout {
                visible: rect.hasResult && rect.triangular.length > 0
                Layout.fillWidth: true
                spacing: 6

                Text {
                    Layout.leftMargin: 4
                    text: "Треугольная матрица (после прямого хода)"
                    color: Theme.textMain
                    font.pixelSize: 16
                    font.family: "JetbrainsMono Nerd Font"
                    font.bold: true
                }

                MyRect {
                    Layout.fillWidth: true
                    Layout.preferredHeight: triangGrid.implicitHeight + 20
                    color: Theme.bg

                    GridLayout {
                        id: triangGrid
                        anchors.fill: parent
                        anchors.margins: 10
                        columns: rect.triangular.length > 0 ? rect.triangular[0].length + 2 : 1
                        columnSpacing: 12
                        rowSpacing: 4

                        Repeater {
                            model: {
                                const cells = [];
                                for (let i = 0; i < rect.triangular.length; ++i) {
                                    const row = rect.triangular[i];
                                    for (let j = 0; j < row.length; ++j) {
                                        cells.push({
                                            value: row[j],
                                            isAug: false,
                                            isSep: false
                                        });
                                    }
                                    cells.push({
                                        value: null,
                                        isAug: false,
                                        isSep: true
                                    });
                                    cells.push({
                                        value: rect.reducedAugmentation[i],
                                        isAug: true,
                                        isSep: false
                                    });
                                }
                                return cells;
                            }

                            delegate: Item {
                                required property var modelData
                                Layout.fillWidth: !modelData.isSep
                                Layout.preferredWidth: modelData.isSep ? 12 : -1
                                Layout.preferredHeight: 20

                                Rectangle {
                                    visible: modelData.isSep
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 1
                                    height: parent.height
                                    color: Theme.border
                                }

                                Text {
                                    visible: !modelData.isSep
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: rect.formattedNumber(Number(modelData.value))
                                    color: modelData.isAug ? Theme.accent : Theme.textMain
                                    font.pixelSize: 13
                                    font.family: "JetbrainsMono Nerd Font"
                                }
                            }
                        }
                    }
                }
            }

            RowLayout {
                id: resultsRow
                visible: rect.hasResult && rect.solution.length > 0
                Layout.fillWidth: true
                spacing: 12

                readonly property real blockHeight: Math.max(solutionColumn.implicitHeight, residualsColumn.implicitHeight) + 20

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    spacing: 6

                    Text {
                        Layout.leftMargin: 4
                        text: "Неизвестные"
                        color: Theme.textMain
                        font.pixelSize: 16
                        font.family: "JetbrainsMono Nerd Font"
                        font.bold: true
                    }

                    MyRect {
                        Layout.fillWidth: true
                        Layout.preferredHeight: resultsRow.blockHeight
                        color: Theme.bg

                        Column {
                            id: solutionColumn
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 4

                            Repeater {
                                model: rect.solution

                                delegate: Text {
                                    required property var modelData
                                    required property int index
                                    text: "x[" + (index + 1) + "] = " + rect.formattedNumber(Number(modelData))
                                    color: Theme.accent
                                    font.pixelSize: 14
                                    font.bold: true
                                    font.family: "JetbrainsMono Nerd Font"
                                }
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    spacing: 6

                    Text {
                        Layout.leftMargin: 4
                        text: "Невязки"
                        color: Theme.textMain
                        font.pixelSize: 16
                        font.family: "JetbrainsMono Nerd Font"
                        font.bold: true
                    }

                    MyRect {
                        Layout.fillWidth: true
                        Layout.preferredHeight: resultsRow.blockHeight
                        color: Theme.bg

                        Column {
                            id: residualsColumn
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 4

                            Repeater {
                                model: rect.residuals

                                delegate: Text {
                                    required property var modelData
                                    required property int index
                                    text: "r[" + (index + 1) + "] = " + rect.formattedNumber(Number(modelData))
                                    color: Theme.textMain
                                    font.pixelSize: 14
                                    font.family: "JetbrainsMono Nerd Font"
                                }
                            }
                        }
                    }
                }
            }

            Item {
                Layout.fillHeight: true
                Layout.fillWidth: true
            }
        }
    }
}
