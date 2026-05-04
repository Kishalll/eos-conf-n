import QtQuick

Item {
    id: controller

    property var tasks: []
    property var unfinishedTasks: sortTasksByDue(tasks.filter(function(t) { return !t.done }))
    property var finishedTasks: tasks.filter(function(t) { return t.done })
    property bool requestInProgress: false
    property bool refreshQueued: false
    property double requestStartedAtMs: 0

    function dueSortTimestamp(task) {
        if (!task || !task.due)
            return Number.MAX_SAFE_INTEGER

        var phraseDate = parseRelativeDueDate(task.due.string || "")
        if (phraseDate)
            return phraseDate.getTime()

        if (!task.due.date)
            return Number.MAX_SAFE_INTEGER

        var dueDate = task.due.date

        if (/^\d{4}-\d{2}-\d{2}$/.test(dueDate)) {
            var parts = dueDate.split("-")
            var year = Number(parts[0])
            var month = Number(parts[1]) - 1
            var day = Number(parts[2])
            return new Date(year, month, day, 23, 59, 59, 999).getTime()
        }

        var parsed = Date.parse(dueDate)
        if (!isNaN(parsed))
            return parsed

        return Number.MAX_SAFE_INTEGER
    }

    function parseRelativeDueDate(text) {
        if (!text)
            return null

        var normalized = text.trim().toLowerCase().replace(/\s+/g, " ")
        if (normalized.length === 0)
            return null

        var words = normalized.split(" ")
        var typoMap = {
            "minday": "monday",
            "mon": "monday",
            "tue": "tuesday",
            "wed": "wednesday",
            "thur": "thursday",
            "thurs": "thursday",
            "fri": "friday",
            "sat": "saturday",
            "sun": "sunday",
            "jan": "january",
            "feb": "february",
            "mar": "march",
            "apr": "april",
            "aprl": "april",
            "jun": "june",
            "jul": "july",
            "aug": "august",
            "sep": "september",
            "oct": "october",
            "nov": "november",
            "dec": "december",
            "nxt": "next",
            "wek": "week",
            "mnth": "month",
            "mth": "month",
            "wk": "week",
            "tom": "tomorrow",
            "tod": "today",
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
            var minutes = timeInfo ? timeInfo.minutes : 59
            var seconds = timeInfo ? 0 : 59
            var millis = timeInfo ? 0 : 999
            return new Date(baseDate.getFullYear(), baseDate.getMonth(), baseDate.getDate(), hours, minutes, seconds, millis)
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

        var todayMatch = matchPhraseWithOptionalTime(normalized, "today")
        if (todayMatch.matched) {
            var todayDate = new Date(today.getFullYear(), today.getMonth(), today.getDate())
            return dateWithTime(todayDate, todayMatch.time, 23)
        }

        var weekdayMatch = normalized.match(/^(next\s+)?(monday|tuesday|wednesday|thursday|friday|saturday|sunday)(?:\s+(.+))?$/)
        if (weekdayMatch) {
            var weekdays = {
                sunday: 0,
                monday: 1,
                tuesday: 2,
                wednesday: 3,
                thursday: 4,
                friday: 5,
                saturday: 6
            }
            var wantsNextWeek = !!weekdayMatch[1]
            var targetDow = weekdays[weekdayMatch[2]]
            var timeInfo = weekdayMatch[3] ? parseTimeSuffix(weekdayMatch[3]) : null
            if (weekdayMatch[3] && !timeInfo)
                return null

            var dayDelta = targetDow - today.getDay()
            if (dayDelta < 0)
                dayDelta += 7
            if (wantsNextWeek && dayDelta === 0)
                dayDelta = 7

            var weekdayDate = new Date(today.getFullYear(), today.getMonth(), today.getDate() + dayDelta)
            return dateWithTime(weekdayDate, timeInfo, 23)
        }

        var tomorrowMatch = matchPhraseWithOptionalTime(normalized, "tomorrow")
        if (tomorrowMatch.matched) {
            var tomorrowDate = new Date(today.getFullYear(), today.getMonth(), today.getDate() + 1)
            return dateWithTime(tomorrowDate, tomorrowMatch.time, 23)
        }

        var dayAfterTomorrowMatch = matchPhraseWithOptionalTime(normalized, "day after tomorrow")
        if (dayAfterTomorrowMatch.matched) {
            var dayAfterTomorrowDate = new Date(today.getFullYear(), today.getMonth(), today.getDate() + 2)
            return dateWithTime(dayAfterTomorrowDate, dayAfterTomorrowMatch.time, 23)
        }

        var nextWeekMatch = matchPhraseWithOptionalTime(normalized, "next week")
        if (nextWeekMatch.matched) {
            var dayOfWeek = today.getDay()
            var daysUntilNextMonday = ((8 - dayOfWeek) % 7)
            if (daysUntilNextMonday === 0)
                daysUntilNextMonday = 7
            var nextWeekDate = new Date(today.getFullYear(), today.getMonth(), today.getDate() + daysUntilNextMonday)
            return dateWithTime(nextWeekDate, nextWeekMatch.time, 23)
        }

        var nextMonthMatch = matchPhraseWithOptionalTime(normalized, "next month")
        if (nextMonthMatch.matched) {
            var nextMonthDate = new Date(today.getFullYear(), today.getMonth() + 1, 1)
            return dateWithTime(nextMonthDate, nextMonthMatch.time, 23)
        }

        var inAWeekMatch = matchPhraseWithOptionalTime(normalized, "in a week")
        if (inAWeekMatch.matched) {
            var inAWeekDate = new Date(today.getFullYear(), today.getMonth(), today.getDate() + 7)
            return dateWithTime(inAWeekDate, inAWeekMatch.time, 23)
        }

        var afterAWeekMatch = matchPhraseWithOptionalTime(normalized, "after a week")
        if (afterAWeekMatch.matched) {
            var afterAWeekDate = new Date(today.getFullYear(), today.getMonth(), today.getDate() + 7)
            return dateWithTime(afterAWeekDate, afterAWeekMatch.time, 23)
        }

        var inAMonthMatch = matchPhraseWithOptionalTime(normalized, "in a month")
        if (inAMonthMatch.matched) {
            var inAMonthDate = new Date(today.getFullYear(), today.getMonth(), today.getDate())
            inAMonthDate.setMonth(inAMonthDate.getMonth() + 1)
            return dateWithTime(inAMonthDate, inAMonthMatch.time, 23)
        }

        var afterAMonthMatch = matchPhraseWithOptionalTime(normalized, "after a month")
        if (afterAMonthMatch.matched) {
            var afterAMonthDate = new Date(today.getFullYear(), today.getMonth(), today.getDate())
            afterAMonthDate.setMonth(afterAMonthDate.getMonth() + 1)
            return dateWithTime(afterAMonthDate, afterAMonthMatch.time, 23)
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
                    return dateWithTime(shifted, optionalTime, 23)
                }
                if (unit === "week" || unit === "weeks") {
                    shifted.setDate(shifted.getDate() + amount * 7)
                    return dateWithTime(shifted, optionalTime, 23)
                }
                if (unit === "month" || unit === "months") {
                    shifted.setMonth(shifted.getMonth() + amount)
                    return dateWithTime(shifted, optionalTime, 23)
                }
            }
        }

        return null
    }

    function sortTasksByDue(taskList) {
        return taskList
            .map(function(task, index) {
                var priority = normalizePriority(task.priority)
                return {
                    task: task,
                    index: index,
                    dueTs: dueSortTimestamp(task),
                    priority: priority === null ? 99 : priority
                }
            })
            .sort(function(a, b) {
                if (a.dueTs !== b.dueTs)
                    return a.dueTs - b.dueTs

                if (a.priority !== b.priority)
                    return a.priority - b.priority

                return a.index - b.index
            })
            .map(function(entry) { return entry.task })
    }

    TodoistService {
        id: api

        onSyncFailed: {
            console.warn("[TodoController] Sync failed — will retry on next refresh cycle")
            controller.requestInProgress = false
            controller.requestStartedAtMs = 0
            if (controller.refreshQueued) {
                controller.refreshQueued = false
                controller.refresh(true)
            }
        }
    }

    // Delayed refresh so rapid actions don't spam the API.
    // Every mutation restarts this timer; when it finally fires
    // we do one clean fetch to reconcile with Todoist.
    Timer {
        id: deferredRefresh
        interval: 2000
        repeat: false
        onTriggered: controller.refresh()
    }

    // Pull the full task list from Todoist.
    function refresh(force) {
        var shouldForce = force === true

        if (requestInProgress) {
            if (shouldForce && requestStartedAtMs > 0 && (Date.now() - requestStartedAtMs) > 12000)
                requestInProgress = false

            if (shouldForce)
                refreshQueued = true

            if (requestInProgress)
                return
        }

        if (!api.token || api.token.length === 0) return
        requestInProgress = true
        requestStartedAtMs = Date.now()

        api.fetchTasks(function(fetched) {
            controller.tasks = fetched
            controller.requestInProgress = false
            controller.requestStartedAtMs = 0

            if (controller.refreshQueued) {
                controller.refreshQueued = false
                controller.refresh(true)
            }
        })
    }

    function parseLabels(labelsInput) {
        var rawLabels = []

        if (Array.isArray(labelsInput)) {
            rawLabels = labelsInput
        } else if (labelsInput) {
            rawLabels = labelsInput.split(",")
        }

        var normalized = []
        var seen = {}

        for (var i = 0; i < rawLabels.length; i++) {
            var label = (rawLabels[i] || "").toString().trim()
            if (label.startsWith("#"))
                label = label.slice(1).trim()

            if (label.length === 0)
                continue

            var key = label.toLowerCase()
            if (seen[key])
                continue

            seen[key] = true
            normalized.push(label)
        }

        return normalized
    }

    function normalizePriority(priorityInput) {
        var value = Number(priorityInput)
        if (isNaN(value) || value < 1 || value > 4)
            return null
        return Math.round(value)
    }

    // Optimistic add — show it in the UI right away, then tell the API.
    function addTask(taskInput) {
        var content = ""
        var dueString = ""
        var priority = null
        var labels = []

        if (typeof taskInput === "string") {
            content = taskInput.trim()
        } else {
            content = (taskInput.content || "").trim()
            dueString = (taskInput.dueString || "").trim()
            priority = normalizePriority(taskInput.priority)
            labels = parseLabels(taskInput.labels)
        }

        if (content.length === 0)
            return

        var optimistic = tasks.slice()
        var pendingId = "pending-" + Date.now()
        optimistic.push({
            id: pendingId,
            content: content,
            done: false,
            priority: priority,
            labels: labels,
            due: dueString.length > 0 ? { string: dueString } : null,
            dueString: dueString
        })
        tasks = optimistic

        api.createTask({
            content: content,
            dueString: dueString,
            priority: priority,
            labels: labels
        }, function(createdTask) {
            if (createdTask && createdTask.id) {
                tasks = tasks.map(function(t) {
                    if (t.id === pendingId)
                        return createdTask
                    return t
                })
            }
            deferredRefresh.restart()
        })
    }

    function editTask(taskId, updates) {
        if (!taskId)
            return

        var isPendingTask = taskId.toString().indexOf("pending-") === 0

        var newContent = (updates.content || "").trim()
        if (newContent.length === 0)
            return

        var hasPriorityUpdate = updates.hasOwnProperty("priority")
        var normalizedPriority = hasPriorityUpdate ? normalizePriority(updates.priority) : null
        var normalizedLabels = parseLabels(updates.labels)
        var dueRaw = updates.dueString || ""
        var normalizedDue = dueRaw.trim()
        var shouldClearDue = updates.clearDue === true

        tasks = tasks.map(function(t) {
            if (t.id !== taskId)
                return t

            return {
                id: t.id,
                content: newContent,
                done: t.done,
                priority: hasPriorityUpdate ? normalizedPriority : t.priority,
                labels: normalizedLabels,
                due: shouldClearDue ? null : (normalizedDue.length > 0 ? { string: normalizedDue } : t.due),
                dueString: shouldClearDue ? "" : (normalizedDue.length > 0 ? normalizedDue : (t.dueString || ""))
            }
        })

        var updatePayload = {
            content: newContent,
            labels: normalizedLabels,
            dueString: normalizedDue,
            dueClear: shouldClearDue
        }

        if (hasPriorityUpdate && normalizedPriority !== null)
            updatePayload.priority = normalizedPriority

        if (isPendingTask)
            return

        api.updateTask(taskId, updatePayload, function(updatedTask) {
            if (updatedTask && updatedTask.id) {
                tasks = tasks.map(function(t) {
                    if (t.id === taskId)
                        return updatedTask
                    return t
                })
            }
            deferredRefresh.restart()
        })
    }

    // Optimistic complete — flip `done` locally first.
    function completeTask(taskId) {
        var updated = tasks.map(function(t) {
            if (t.id === taskId) {
                return Object.assign({}, t, { done: true })
            }
            return t
        })
        tasks = updated

        api.completeTask(taskId, function() {
            deferredRefresh.restart()
        })
    }

    // Optimistic delete — yank it from the list immediately.
    function deleteTask(taskId) {
        tasks = tasks.filter(function(t) { return t.id !== taskId })

        api.deleteTask(taskId, function() {
            deferredRefresh.restart()
        })
    }

    // Wait for the token to be read from disk before the first fetch.
    Connections {
        target: api
        function onTokenReady() {
            controller.refresh()
        }
    }
}
