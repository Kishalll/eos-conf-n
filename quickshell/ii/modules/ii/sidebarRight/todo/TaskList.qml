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

    function labelsDisplayText(task) {
        if (!task || !task.labels || task.labels.length === 0)
            return ""

        var formatted = []
        for (var i = 0; i < task.labels.length; i++) {
            var label = (task.labels[i] || "").toString().trim()
            if (label.length > 0)
                formatted.push("#" + label)
        }

        return formatted.join("  ")
    }

    function normalizedPriority(task) {
        if (!task)
            return null

        var value = Number(task.priority)
        if (isNaN(value) || value < 1 || value > 4)
            return null

        return Math.round(value)
    }

    function priorityColor(task) {
        var priority = normalizedPriority(task)
        if (priority === 1)
            return "#e53935"
        if (priority === 2)
            return "#fb8c00"
        if (priority === 3)
            return "#fdd835"
        return Appearance.m3colors.m3outline
    }

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

    function resolveDueDate(task) {
        if (!task || !task.due)
            return null

        var due = task.due
        var phraseDate = parseRelativeDueDate(due.string || "")
        if (phraseDate)
            return phraseDate

        if (!due.date)
            return null

        if (/^\d{4}-\d{2}-\d{2}$/.test(due.date)) {
            var dateParts = due.date.split("-")
            return new Date(Number(dateParts[0]), Number(dateParts[1]) - 1, Number(dateParts[2]), 12, 0, 0)
        }

        var parsed = new Date(due.date)
        if (isNaN(parsed.getTime()))
            return null

        return parsed
    }

    function sameDay(a, b) {
        return a.getFullYear() === b.getFullYear()
            && a.getMonth() === b.getMonth()
            && a.getDate() === b.getDate()
    }

    function dueBucket(task) {
        var dueDate = resolveDueDate(task)
        if (!dueDate)
            return "no_date"

        var now = new Date()
        var todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0, 0)

        if (sameDay(dueDate, now))
            return "today"

        if (dueDate.getTime() < todayStart.getTime())
            return "overdue"

        return "upcoming"
    }

    property var collapsedSections: ({
        overdue: false,
        today: false,
        upcoming: false,
        no_date: false
    })

    function toggleSection(sectionKey) {
        if (!sectionKey)
            return

        var next = Object.assign({}, collapsedSections)
        next[sectionKey] = !next[sectionKey]
        collapsedSections = next
    }

    function tasksForBucket(bucket) {
        return taskList.filter(function(task) {
            return dueBucket(task) === bucket
        })
    }

    property var visibleSections: {
        var sections = [
            {
                key: "overdue",
                title: Translation.tr("Overdue"),
                tasks: tasksForBucket("overdue")
            },
            {
                key: "today",
                title: Translation.tr("Today"),
                tasks: tasksForBucket("today")
            },
            {
                key: "upcoming",
                title: Translation.tr("Upcoming"),
                tasks: tasksForBucket("upcoming")
            },
            {
                key: "no_date",
                title: Translation.tr("No date"),
                tasks: tasksForBucket("no_date")
            }
        ]

        return sections.filter(function(section) {
            return section.tasks.length > 0
        })
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
        bottomMargin: 0
        model: ScriptModel {
            values: root.visibleSections
        }
        delegate: Item {
            id: sectionItem
            required property var modelData
            readonly property bool collapsed: !!root.collapsedSections[modelData.key]

            implicitHeight: headerRow.implicitHeight + (collapsed ? 0 : tasksColumn.implicitHeight + root.todoListItemSpacing)
            width: ListView.view.width

            RowLayout {
                id: headerRow
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 6

                MaterialSymbol {
                    Layout.alignment: Qt.AlignVCenter
                    text: sectionItem.collapsed ? "chevron_right" : "expand_more"
                    iconSize: 20
                    color: Appearance.colors.colOnLayer1
                }

                StyledText {
                    Layout.fillWidth: true
                    text: sectionItem.modelData.title
                    color: Appearance.colors.colPrimary
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.bold: true
                    elide: Text.ElideRight
                }
            }

            MouseArea {
                anchors.fill: headerRow
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.toggleSection(sectionItem.modelData.key)
                }
            }

            Column {
                id: tasksColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: headerRow.bottom
                anchors.topMargin: root.todoListItemSpacing
                spacing: root.todoListItemSpacing
                visible: !sectionItem.collapsed

                Repeater {
                    model: sectionItem.modelData.tasks
                    delegate: Rectangle {
                        required property var modelData
                        width: tasksColumn.width
                        implicitHeight: todoContentRowLayout.implicitHeight
                        color: Appearance.colors.colLayer2
                        radius: Appearance.rounding.small

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: 4
                            radius: 2
                            color: root.priorityColor(modelData)
                        }

                        ColumnLayout {
                            id: todoContentRowLayout
                            anchors.left: parent.left
                            anchors.right: parent.right

                            StyledText {
                                Layout.fillWidth: true
                                Layout.leftMargin: 10
                                Layout.rightMargin: 10
                                Layout.topMargin: todoListItemPadding
                                text: modelData.content
                                wrapMode: Text.Wrap
                                font.pixelSize: Appearance.font.pixelSize.normal
                            }
                            StyledText {
                                Layout.fillWidth: true
                                Layout.leftMargin: 10
                                Layout.rightMargin: 10
                                visible: text.length > 0
                                text: root.dueDisplayText(modelData)
                                color: Appearance.m3colors.m3outline
                                font.pixelSize: Appearance.font.pixelSize.small
                            }
                            StyledText {
                                Layout.fillWidth: true
                                Layout.leftMargin: 10
                                Layout.rightMargin: 10
                                visible: text.length > 0
                                text: root.labelsDisplayText(modelData)
                                color: Appearance.colors.colPrimary
                                font.pixelSize: Appearance.font.pixelSize.smaller
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
                                        root.editRequested(modelData)
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
                                        root.controller.completeTask(modelData.id)
                                    }
                                    contentItem: MaterialSymbol {
                                        anchors.centerIn: parent
                                        horizontalAlignment: Text.AlignHCenter
                                        text: modelData.done ? "remove_done" : "check"
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
                                        root.controller.deleteTask(modelData.id)
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
        }

        footer: Item {
            width: listView.width
            height: root.listBottomPadding
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
