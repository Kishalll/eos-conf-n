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

        function parseTimeSuffix(rawSuffix) {
            if (!rawSuffix)
                return null

            var suffix = rawSuffix.trim()
            if (suffix.length === 0)
                return null

            if (suffix.indexOf("at ") === 0)
                suffix = suffix.slice(3).trim()

            var meridiemMatch = suffix.match(/^(\d{1,2})(?::(\d{2}))?\s*(am|pm)$/)
            if (meridiemMatch) {
                var hour12 = Number(meridiemMatch[1])
                var minute12 = meridiemMatch[2] ? Number(meridiemMatch[2]) : 0
                var period = meridiemMatch[3]

                if (isNaN(hour12) || hour12 < 1 || hour12 > 12 || isNaN(minute12) || minute12 < 0 || minute12 > 59)
                    return null

                var hour24 = hour12 % 12
                if (period === "pm")
                    hour24 += 12

                return {
                    hours: hour24,
                    minutes: minute12
                }
            }

            var twentyFourHourMatch = suffix.match(/^(\d{1,2}):(\d{2})$/)
            if (twentyFourHourMatch) {
                var hour24Only = Number(twentyFourHourMatch[1])
                var minute24Only = Number(twentyFourHourMatch[2])

                if (isNaN(hour24Only) || hour24Only < 0 || hour24Only > 23 || isNaN(minute24Only) || minute24Only < 0 || minute24Only > 59)
                    return null

                return {
                    hours: hour24Only,
                    minutes: minute24Only
                }
            }

            return null
        }

        function dateWithTime(baseDate, timeInfo, defaultHours) {
            var hours = timeInfo ? timeInfo.hours : defaultHours
            var minutes = timeInfo ? timeInfo.minutes : 0
            return new Date(baseDate.getFullYear(), baseDate.getMonth(), baseDate.getDate(), hours, minutes, 0)
        }

        function matchPhraseWithOptionalTime(value, phrase) {
            if (value === phrase)
                return { matched: true, time: null }

            var prefix = phrase + " "
            if (value.indexOf(prefix) !== 0)
                return { matched: false, time: null }

            var timeInfo = parseTimeSuffix(value.slice(prefix.length))
            if (!timeInfo)
                return { matched: false, time: null }

            return {
                matched: true,
                time: timeInfo
            }
        }

        var today = new Date()

        var tomorrowMatch = matchPhraseWithOptionalTime(normalized, "tomorrow")
        if (tomorrowMatch.matched) {
            var tomorrowDate = new Date(today.getFullYear(), today.getMonth(), today.getDate() + 1)
            return dateWithTime(tomorrowDate, tomorrowMatch.time, 12)
        }

        var dayAfterTomorrowMatch = matchPhraseWithOptionalTime(normalized, "day after tomorrow")
        if (dayAfterTomorrowMatch.matched) {
            var dayAfterTomorrowDate = new Date(today.getFullYear(), today.getMonth(), today.getDate() + 2)
            return dateWithTime(dayAfterTomorrowDate, dayAfterTomorrowMatch.time, 12)
        }

        var nextWeekMatch = matchPhraseWithOptionalTime(normalized, "next week")
        if (nextWeekMatch.matched) {
            var dayOfWeek = today.getDay()
            var daysUntilNextMonday = ((8 - dayOfWeek) % 7)
            if (daysUntilNextMonday === 0)
                daysUntilNextMonday = 7
            var nextWeekDate = new Date(today.getFullYear(), today.getMonth(), today.getDate() + daysUntilNextMonday)
            return dateWithTime(nextWeekDate, nextWeekMatch.time, 12)
        }

        var nextMonthMatch = matchPhraseWithOptionalTime(normalized, "next month")
        if (nextMonthMatch.matched) {
            var nextMonthDate = new Date(today.getFullYear(), today.getMonth() + 1, 1)
            return dateWithTime(nextMonthDate, nextMonthMatch.time, 12)
        }

        var inAWeekMatch = matchPhraseWithOptionalTime(normalized, "in a week")
        if (inAWeekMatch.matched) {
            var inAWeekDate = new Date(today.getFullYear(), today.getMonth(), today.getDate() + 7)
            return dateWithTime(inAWeekDate, inAWeekMatch.time, 12)
        }

        var afterAWeekMatch = matchPhraseWithOptionalTime(normalized, "after a week")
        if (afterAWeekMatch.matched) {
            var afterAWeekDate = new Date(today.getFullYear(), today.getMonth(), today.getDate() + 7)
            return dateWithTime(afterAWeekDate, afterAWeekMatch.time, 12)
        }

        var inAMonthMatch = matchPhraseWithOptionalTime(normalized, "in a month")
        if (inAMonthMatch.matched) {
            var inAMonthDate = new Date(today.getFullYear(), today.getMonth(), today.getDate())
            inAMonthDate.setMonth(inAMonthDate.getMonth() + 1)
            return dateWithTime(inAMonthDate, inAMonthMatch.time, 12)
        }

        var afterAMonthMatch = matchPhraseWithOptionalTime(normalized, "after a month")
        if (afterAMonthMatch.matched) {
            var afterAMonthDate = new Date(today.getFullYear(), today.getMonth(), today.getDate())
            afterAMonthDate.setMonth(afterAMonthDate.getMonth() + 1)
            return dateWithTime(afterAMonthDate, afterAMonthMatch.time, 12)
        }

        var multiSpanMatch = normalized.match(/^(?:in|after)\s+(\d+)\s+(day|days|week|weeks|month|months)(?:\s+(.+))?$/)
        if (multiSpanMatch) {
            var amount = Number(multiSpanMatch[1])
            var unit = multiSpanMatch[2]
            var optionalTime = multiSpanMatch[3] ? parseTimeSuffix(multiSpanMatch[3]) : null
            if (multiSpanMatch[3] && !optionalTime)
                return null
            if (!isNaN(amount) && amount > 0) {
                var shifted = new Date(today.getFullYear(), today.getMonth(), today.getDate())
                if (unit === "day" || unit === "days") {
                    shifted.setDate(shifted.getDate() + amount)
                    return dateWithTime(shifted, optionalTime, 12)
                }
                if (unit === "week" || unit === "weeks") {
                    shifted.setDate(shifted.getDate() + amount * 7)
                    return dateWithTime(shifted, optionalTime, 12)
                }
                if (unit === "month" || unit === "months") {
                    shifted.setMonth(shifted.getMonth() + amount)
                    return dateWithTime(shifted, optionalTime, 12)
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

            Rectangle {
                id: refreshButton
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                width: 132
                height: 34
                radius: Appearance.rounding.small
                color: refreshMouseArea.containsMouse ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer2
                border.width: 1
                border.color: Appearance.colors.colLayer0Border

                StyledText {
                    anchors.centerIn: parent
                    text: Translation.tr("Refresh")
                    color: Appearance.colors.colOnLayer1
                    font.pixelSize: Appearance.font.pixelSize.small
                }

                MouseArea {
                    id: refreshMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.controller.refresh(true)
                }
            }

            height: refreshButton.height + 6
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
