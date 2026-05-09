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
        Layout.preferredWidth: 360
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
            const out = [];
            for (let i = 0; i < n; ++i) {
                out.push("");
            }
            return out;
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

        ScrollView {
            anchors.fill: parent
            clip: true

            Column {
                id: mainColumn
                width: rect.width - 4
                spacing: 10
                padding: 5

                MyRect {
                    height: 50
                    width: parent.width - 10
                    border.color: "transparent"

                    MyText {
                        text: "Размерность"
                    }
                }

                RowLayout {
                    width: parent.width - 30
                    x: 15
                    spacing: 8

                    MyButton {
                        text: "−"
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        leftAligned: false
                        bold: true
                        textNormalColor: Theme.textMain
                        textHoverColor: Theme.textDimmed
                        onClicked: rect.resizeTo(rect.currentSize - 1)
                    }

                    Text {
                        text: "n = " + rect.currentSize
                        color: Theme.textMain
                        font.pixelSize: 20
                        font.family: "JetbrainsMono Nerd Font"
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                    }

                    MyButton {
                        text: "+"
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        leftAligned: false
                        bold: true
                        textNormalColor: Theme.textMain
                        textHoverColor: Theme.textDimmed
                        onClicked: rect.resizeTo(rect.currentSize + 1)
                    }
                }

                MyRect {
                    height: 50
                    width: parent.width - 10
                    border.color: "transparent"

                    MyText {
                        text: "Матрица [A | b]"
                    }
                }

                Column {
                    width: parent.width - 30
                    x: 15
                    spacing: 4

                    Repeater {
                        model: rect.currentSize

                        delegate: RowLayout {
                            id: matrixRow
                            required property int index
                            width: parent.width
                            spacing: 3

                            Repeater {
                                model: rect.currentSize

                                delegate: MyTextField {
                                    required property int index
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 32
                                    text: rect.matrixValues[matrixRow.index] && rect.matrixValues[matrixRow.index][index] !== undefined ? rect.matrixValues[matrixRow.index][index] : ""
                                    placeholderText: "0"
                                    font.pixelSize: 13
                                    horizontalAlignment: TextInput.AlignHCenter

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

                            Text {
                                text: "│"
                                color: Theme.textDimmed
                                font.pixelSize: 18
                                Layout.alignment: Qt.AlignVCenter
                            }

                            MyTextField {
                                Layout.preferredWidth: 60
                                Layout.preferredHeight: 32
                                text: rect.augmentationValues[matrixRow.index] !== undefined ? rect.augmentationValues[matrixRow.index] : ""
                                placeholderText: "b"
                                font.pixelSize: 13
                                horizontalAlignment: TextInput.AlignHCenter

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

                MyRect {
                    height: 50
                    width: parent.width - 10
                    border.color: "transparent"
                }

                MyButton {
                    text: "Случайные коэффициенты"
                    width: parent.width - 30
                    x: 15
                    height: 45
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

                MyButton {
                    text: "Вычислить"
                    width: parent.width - 30
                    x: 15
                    height: 50
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

        ScrollView {
            anchors.fill: parent
            anchors.margins: 12
            clip: true

            Column {
                width: parent.width
                spacing: 14

                Text {
                    text: "Решение СЛАУ методом Гаусса"
                    color: Theme.textMain
                    font.pixelSize: 22
                    font.family: "JetbrainsMono Nerd Font"
                    font.bold: true
                }

                MyRect {
                    visible: rect.hasResult
                    width: parent.width - 4
                    height: statusColumn.implicitHeight + 24
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

                Text {
                    visible: rect.hasResult && rect.triangular.length > 0
                    text: "Треугольная матрица (после прямого хода)"
                    color: Theme.textMain
                    font.pixelSize: 17
                    font.family: "JetbrainsMono Nerd Font"
                    font.bold: true
                }

                MyRect {
                    visible: rect.hasResult && rect.triangular.length > 0
                    width: parent.width - 4
                    height: triangColumn.implicitHeight + 20
                    color: Theme.bg

                    Column {
                        id: triangColumn
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 3

                        Repeater {
                            model: rect.triangular

                            delegate: Row {
                                required property var modelData
                                required property int index
                                spacing: 8

                                Repeater {
                                    model: modelData

                                    delegate: Text {
                                        required property var modelData
                                        text: rect.formattedNumber(Number(modelData))
                                        color: Theme.textMain
                                        font.pixelSize: 13
                                        font.family: "JetbrainsMono Nerd Font"
                                        width: 90
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }

                                Text {
                                    text: "│"
                                    color: Theme.textDimmed
                                    font.pixelSize: 14
                                }

                                Text {
                                    text: rect.reducedAugmentation[parent.index] !== undefined ? rect.formattedNumber(Number(rect.reducedAugmentation[parent.index])) : ""
                                    color: Theme.accent
                                    font.pixelSize: 13
                                    font.family: "JetbrainsMono Nerd Font"
                                    width: 90
                                    horizontalAlignment: Text.AlignRight
                                }
                            }
                        }
                    }
                }

                Text {
                    visible: rect.hasResult && rect.solution.length > 0
                    text: "Неизвестные"
                    color: Theme.textMain
                    font.pixelSize: 17
                    font.family: "JetbrainsMono Nerd Font"
                    font.bold: true
                }

                MyRect {
                    visible: rect.hasResult && rect.solution.length > 0
                    width: parent.width - 4
                    height: solutionColumn.implicitHeight + 20
                    color: Theme.bg

                    Column {
                        id: solutionColumn
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 3

                        Repeater {
                            model: rect.solution

                            delegate: Text {
                                required property var modelData
                                required property int index
                                text: "x[" + (index + 1) + "] = " + rect.formattedNumber(Number(modelData))
                                color: Theme.accent
                                font.pixelSize: 15
                                font.bold: true
                                font.family: "JetbrainsMono Nerd Font"
                            }
                        }
                    }
                }

                Text {
                    visible: rect.hasResult && rect.residuals.length > 0
                    text: "Невязки"
                    color: Theme.textMain
                    font.pixelSize: 17
                    font.family: "JetbrainsMono Nerd Font"
                    font.bold: true
                }

                MyRect {
                    visible: rect.hasResult && rect.residuals.length > 0
                    width: parent.width - 4
                    height: residualsColumn.implicitHeight + 20
                    color: Theme.bg

                    Column {
                        id: residualsColumn
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 3

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
    }
}
