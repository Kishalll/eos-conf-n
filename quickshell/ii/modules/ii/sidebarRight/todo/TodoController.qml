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

    // Optimistic add — show it in the UI right away, then tell the API.
    function addTask(content) {
        var optimistic = tasks.slice()
        optimistic.push({
            id: "pending-" + Date.now(),
            content: content,
            done: false
        })
        tasks = optimistic

        api.createTask(content, function() {
            deferredRefresh.restart()
        })
    }

    // Optimistic complete — flip `done` locally first.
    function completeTask(taskId) {
        var updated = tasks.map(function(t) {
            if (t.id === taskId) {
                return { id: t.id, content: t.content, done: true }
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
