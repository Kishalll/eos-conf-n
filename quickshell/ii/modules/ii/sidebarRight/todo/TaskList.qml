import qs.modules.common
import qs.modules.common.widgets
import qs.services
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Item {
    id: root
    required property var taskList
    required property var controller
    signal editRequested(var task)
    property string emptyPlaceholderIcon
    property string emptyPlaceholderText
    property int todoListItemSpacing: 5
    property int todoListItemPadding: 8
    property int listBottomPadding: 80

    function dueDisplayText(task) {
        if (!task || !task.due)
            return ""

        var due = task.due
        var phraseDate = parseRelativeDueDate(due.string || "")
        if (phraseDate)
            return Qt.formatDateTime(phraseDate, "MMM d, ddd")

        if (!due.date)
            return ""

        if (/^\d{4}-\d{2}-\d{2}$/.test(due.date)) {
            var dateParts = due.date.split("-")
            var fullDayDate = new Date(Number(dateParts[0]), Number(dateParts[1]) - 1, Number(dateParts[2]), 12, 0, 0)
            return Qt.formatDateTime(fullDayDate, "MMM d, ddd")
        }

        var parsed = new Date(due.date)
        if (isNaN(parsed.getTime()))
            return ""

        return Qt.formatDateTime(parsed, "MMM d, ddd  hh:mm AP")
    }

    function parseRelativeDueDate(text) {
        if (!text)
            return null

        var normalized = text.trim().toLowerCase().replace(/\s+/g, " ")
        if (normalized.length === 0)
            return null

        var words = normalized.split(" ")
        var typoMap = {
            "nxt": "next",
            "wek": "week",
            "wk": "week",
            "tom": "tomorrow",
            "tmrw": "tomorrow",
            "tmr": "tomorrow",
            "tomorow": "tomorrow",
            "tommorow": "tomorrow"
        }
        for (var i = 0; i < words.length; i++) {
            if (typoMap[words[i]])
                words[i] = typoMap[words[i]]
        }
        normalized = words.join(" ")

        var today = new Date()

        if (normalized === "tomorrow")
            return new Date(today.getFullYear(), today.getMonth(), today.getDate() + 1, 12, 0, 0)

        if (normalized === "day after tomorrow")
            return new Date(today.getFullYear(), today.getMonth(), today.getDate() + 2, 12, 0, 0)

        if (normalized === "next week") {
            var dayOfWeek = today.getDay()
            var daysUntilNextMonday = ((8 - dayOfWeek) % 7)
            if (daysUntilNextMonday === 0)
                daysUntilNextMonday = 7
            return new Date(today.getFullYear(), today.getMonth(), today.getDate() + daysUntilNextMonday, 12, 0, 0)
        }

        if (normalized === "next month")
            return new Date(today.getFullYear(), today.getMonth() + 1, 1, 12, 0, 0)

        if (normalized === "in a week" || normalized === "after a week")
            return new Date(today.getFullYear(), today.getMonth(), today.getDate() + 7, 12, 0, 0)

        if (normalized === "in a month" || normalized === "after a month") {
            var inAMonth = new Date(today.getFullYear(), today.getMonth(), today.getDate(), 12, 0, 0)
            inAMonth.setMonth(inAMonth.getMonth() + 1)
            return inAMonth
        }

        var multiSpanMatch = normalized.match(/^(?:in|after)\s+(\d+)\s+(day|days|week|weeks|month|months)$/)
        if (multiSpanMatch) {
            var amount = Number(multiSpanMatch[1])
            var unit = multiSpanMatch[2]
            if (!isNaN(amount) && amount > 0) {
                var shifted = new Date(today.getFullYear(), today.getMonth(), today.getDate(), 12, 0, 0)
                if (unit === "day" || unit === "days") {
                    shifted.setDate(shifted.getDate() + amount)
                    return shifted
                }
                if (unit === "week" || unit === "weeks") {
                    shifted.setDate(shifted.getDate() + amount * 7)
                    return shifted
                }
                if (unit === "month" || unit === "months") {
                    shifted.setMonth(shifted.getMonth() + amount)
                    return shifted
                }
            }
        }

        return null
    }

    StyledListView {
        id: listView
        anchors.fill: parent
        spacing: root.todoListItemSpacing
        animateAppearance: false
        model: ScriptModel {
            values: root.taskList
        }
        delegate: Item {
            id: todoItem
            required property var modelData
            property bool pendingDoneToggle: false
            property bool pendingDelete: false
            property bool enableHeightAnimation: false

            implicitHeight: todoItemRectangle.implicitHeight
            width: ListView.view.width
            clip: true

            Behavior on implicitHeight {
                enabled: enableHeightAnimation
                NumberAnimation {
                    duration: Appearance.animation.elementMoveFast.duration
                    easing.type: Appearance.animation.elementMoveFast.type
                    easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                }
            }

            Rectangle {
                id: todoItemRectangle
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                implicitHeight: todoContentRowLayout.implicitHeight
                color: Appearance.colors.colLayer2
                radius: Appearance.rounding.small

                ColumnLayout {
                    id: todoContentRowLayout
                    anchors.left: parent.left
                    anchors.right: parent.right

                    StyledText {
                        id: todoContentText
                        Layout.fillWidth: true // Needed for wrapping
                        Layout.leftMargin: 10
                        Layout.rightMargin: 10
                        Layout.topMargin: todoListItemPadding
                        text: todoItem.modelData.content
                        wrapMode: Text.Wrap
                        font.pixelSize: Appearance.font.pixelSize.normal
                    }
                    StyledText {
                        Layout.fillWidth: true
                        Layout.leftMargin: 10
                        Layout.rightMargin: 10
                        visible: text.length > 0
                        text: root.dueDisplayText(todoItem.modelData)
                        color: Appearance.m3colors.m3outline
                        font.pixelSize: Appearance.font.pixelSize.small
                    }
                    RowLayout {
                        Layout.leftMargin: 10
                        Layout.rightMargin: 10
                        Layout.bottomMargin: todoListItemPadding
                        Item {
                            Layout.fillWidth: true
                        }
                        TodoItemActionButton {
                            Layout.fillWidth: false
                            implicitHeight: 48
                            onClicked: {
                                root.editRequested(todoItem.modelData)
                            }
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                horizontalAlignment: Text.AlignHCenter
                                text: "edit"
                                iconSize: 24
                                color: Appearance.colors.colOnLayer1
                            }
                        }
                        Item {
                            Layout.preferredWidth: 10
                        }
                        TodoItemActionButton {
                            Layout.fillWidth: false
                            implicitHeight: 48
                            onClicked: {
                                root.controller.completeTask(todoItem.modelData.id)
                            }
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                horizontalAlignment: Text.AlignHCenter
                                text: todoItem.modelData.done ? "remove_done" : "check"
                                iconSize: 24
                                color: Appearance.colors.colOnLayer1
                            }
                        }
                        Item {
                            Layout.preferredWidth: 10
                        }
                        TodoItemActionButton {
                            Layout.fillWidth: false
                            implicitHeight: 48
                            onClicked: {
                                root.controller.deleteTask(todoItem.modelData.id)
                            }
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                horizontalAlignment: Text.AlignHCenter
                                text: "delete_forever"
                                iconSize: 24
                                color: Appearance.colors.colOnLayer1
                            }
                        }
                        Item {
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }
    }

    Item {
        // Placeholder when list is empty
        visible: opacity > 0
        opacity: taskList.length === 0 ? 1 : 0
        anchors.fill: parent

        Behavior on opacity {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 5

            MaterialSymbol {
                Layout.alignment: Qt.AlignHCenter
                iconSize: 55
                color: Appearance.m3colors.m3outline
                text: emptyPlaceholderIcon
            }
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.m3colors.m3outline
                horizontalAlignment: Text.AlignHCenter
                text: emptyPlaceholderText
            }
        }
    }
}
