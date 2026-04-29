import QtQuick

Item {
    id: controller

    property var tasks: []
    property var unfinishedTasks: tasks.filter(function(t) { return !t.done })
    property var finishedTasks: tasks.filter(function(t) { return t.done })
    property bool requestInProgress: false

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
        optimistic.push({
            id: "pending-" + Date.now(),
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
        }, function() {
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
        }, function() {
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
