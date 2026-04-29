import QtQuick

Item {
    id: controller

    property var tasks: []
    property var unfinishedTasks: sortTasksByDue(tasks.filter(function(t) { return !t.done }))
    property var finishedTasks: tasks.filter(function(t) { return t.done })
    property bool requestInProgress: false

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
            return new Date(today.getFullYear(), today.getMonth(), today.getDate() + 1, 23, 59, 59, 999)

        if (normalized === "day after tomorrow")
            return new Date(today.getFullYear(), today.getMonth(), today.getDate() + 2, 23, 59, 59, 999)

        if (normalized === "next week") {
            var dayOfWeek = today.getDay()
            var daysUntilNextMonday = ((8 - dayOfWeek) % 7)
            if (daysUntilNextMonday === 0)
                daysUntilNextMonday = 7
            return new Date(today.getFullYear(), today.getMonth(), today.getDate() + daysUntilNextMonday, 23, 59, 59, 999)
        }

        if (normalized === "next month")
            return new Date(today.getFullYear(), today.getMonth() + 1, 1, 23, 59, 59, 999)

        if (normalized === "in a week" || normalized === "after a week")
            return new Date(today.getFullYear(), today.getMonth(), today.getDate() + 7, 23, 59, 59, 999)

        if (normalized === "in a month" || normalized === "after a month") {
            var inAMonth = new Date(today.getFullYear(), today.getMonth(), today.getDate(), 23, 59, 59, 999)
            inAMonth.setMonth(inAMonth.getMonth() + 1)
            return inAMonth
        }

        var multiSpanMatch = normalized.match(/^(?:in|after)\s+(\d+)\s+(day|days|week|weeks|month|months)$/)
        if (multiSpanMatch) {
            var amount = Number(multiSpanMatch[1])
            var unit = multiSpanMatch[2]
            if (!isNaN(amount) && amount > 0) {
                var shifted = new Date(today.getFullYear(), today.getMonth(), today.getDate(), 23, 59, 59, 999)
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

    function sortTasksByDue(taskList) {
        return taskList
            .map(function(task, index) {
                return {
                    task: task,
                    index: index,
                    dueTs: dueSortTimestamp(task),
                    priority: normalizePriority(task.priority)
                }
            })
            .sort(function(a, b) {
                if (a.dueTs !== b.dueTs)
                    return a.dueTs - b.dueTs

                if (a.priority !== b.priority)
                    return b.priority - a.priority

                return a.index - b.index
            })
            .map(function(entry) { return entry.task })
    }

    TodoistService {
        id: api

        onSyncFailed: {
            console.warn("[TodoController] Sync failed — will retry on next refresh cycle")
            controller.requestInProgress = false
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
    function refresh() {
        if (requestInProgress) return
        requestInProgress = true

        api.fetchTasks(function(fetched) {
            controller.tasks = fetched
            controller.requestInProgress = false
        })
    }

    function parseLabels(labelsInput) {
        if (Array.isArray(labelsInput))
            return labelsInput

        if (!labelsInput)
            return []

        return labelsInput
            .split(",")
            .map(function(label) { return label.trim() })
            .filter(function(label) { return label.length > 0 })
    }

    function normalizePriority(priorityInput) {
        var value = Number(priorityInput)
        if (isNaN(value) || value < 1 || value > 4)
            return 1
        return Math.round(value)
    }

    // Optimistic add — show it in the UI right away, then tell the API.
    function addTask(taskInput) {
        var content = ""
        var dueString = ""
        var priority = 1
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
        if (!taskId || taskId.toString().indexOf("pending-") === 0)
            return

        var newContent = (updates.content || "").trim()
        if (newContent.length === 0)
            return

        var normalizedPriority = normalizePriority(updates.priority)
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
                priority: normalizedPriority,
                labels: normalizedLabels,
                due: shouldClearDue ? null : (normalizedDue.length > 0 ? { string: normalizedDue } : t.due),
                dueString: shouldClearDue ? "" : (normalizedDue.length > 0 ? normalizedDue : (t.dueString || ""))
            }
        })

        api.updateTask(taskId, {
            content: newContent,
            priority: normalizedPriority,
            labels: normalizedLabels,
            dueString: normalizedDue,
            dueClear: shouldClearDue
        }, function(updatedTask) {
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
