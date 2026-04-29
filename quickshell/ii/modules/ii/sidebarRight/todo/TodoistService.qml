import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: service
    visible: false

    property string token: ""
    property string apiUrl: "https://api.todoist.com/api/v1/tasks"

    signal syncFailed()
    signal tokenReady()

    // UI priority: 1 highest ... 4 lowest
    // Todoist API priority: 4 highest ... 1 lowest
    function toApiPriority(uiPriority) {
        var value = Number(uiPriority)
        if (isNaN(value) || value < 1 || value > 4)
            return null
        return 5 - Math.round(value)
    }

    function toUiPriority(apiPriority) {
        var value = Number(apiPriority)
        if (isNaN(value) || value < 1 || value > 4)
            return null
        return 5 - Math.round(value)
    }

    function formatTask(item) {
        var dueObj = item && item.due ? item.due : null
        var dueText = ""
        if (dueObj && dueObj.string)
            dueText = dueObj.string
        else if (dueObj && dueObj.date)
            dueText = dueObj.date

        return {
            id: item.id,
            content: item.content,
            done: item.checked || false,
            priority: toUiPriority(item.priority),
            labels: item.labels || [],
            due: dueObj,
            dueString: dueText
        }
    }

    FileView {
        id: tokenFile
        path: Qt.resolvedUrl("todoist_token")
        onLoaded: {
            service.token = tokenFile.text().trim()
            console.log("[Todoist] Token loaded (" + service.token.length + " chars)")
            service.tokenReady()
        }
        onLoadFailed: (error) => {
            console.warn("[Todoist] Could not read token file: " + error)
        }
    }

    // Grab all tasks from Todoist (v1 API — paginated response).
    // callback(tasks) receives an array of task objects used by the UI.
    function fetchTasks(callback) {
        if (!token) return

        var xhr = new XMLHttpRequest()
        xhr.open("GET", apiUrl)
        xhr.setRequestHeader("Authorization", "Bearer " + token)

        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return

            if (xhr.status < 200 || xhr.status >= 300) {
                console.warn("[Todoist] Fetch failed — HTTP " + xhr.status)
                service.syncFailed()
                return
            }

            try {
                var response = JSON.parse(xhr.responseText)
                // v1 wraps tasks in { "results": [...], "next_cursor": ... }
                var items = response.results || response
                var formatted = []
                for (var i = 0; i < items.length; i++) {
                    formatted.push(formatTask(items[i]))
                }
                if (callback) callback(formatted)
            } catch (e) {
                console.warn("[Todoist] Failed to parse response: " + e)
                service.syncFailed()
            }
        }

        xhr.send()
    }

    // Create a new task. callback() is called on success.
    function createTask(payload, callback) {
        if (!token) return

        var body = {
            content: payload.content
        }

        if (payload.dueString && payload.dueString.trim().length > 0)
            body.due_string = payload.dueString.trim()

        if (payload.priority !== null && payload.priority !== undefined) {
            var apiPriority = toApiPriority(payload.priority)
            if (apiPriority !== null)
                body.priority = apiPriority
        }

        if (payload.labels)
            body.labels = payload.labels

        var xhr = new XMLHttpRequest()
        xhr.open("POST", apiUrl)
        xhr.setRequestHeader("Authorization", "Bearer " + token)
        xhr.setRequestHeader("Content-Type", "application/json")

        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return

            if (xhr.status < 200 || xhr.status >= 300) {
                console.warn("[Todoist] Create task failed — HTTP " + xhr.status)
                service.syncFailed()
                return
            }

            var createdTask = null
            try {
                createdTask = formatTask(JSON.parse(xhr.responseText))
            } catch (e) {
                createdTask = null
            }

            if (callback) callback(createdTask)
        }

        xhr.send(JSON.stringify(body))
    }

    // Update an existing task with partial data.
    function updateTask(taskId, payload, callback) {
        if (!token) return

        var body = {}

        if (payload.hasOwnProperty("content"))
            body.content = payload.content

        if (payload.hasOwnProperty("priority")) {
            var updatedApiPriority = toApiPriority(payload.priority)
            if (updatedApiPriority !== null)
                body.priority = updatedApiPriority
        }

        if (payload.hasOwnProperty("labels"))
            body.labels = payload.labels

        if (payload.hasOwnProperty("dueClear") && payload.dueClear === true) {
            body.due = null
        } else if (payload.hasOwnProperty("dueString")) {
            var newDue = payload.dueString ? payload.dueString.trim() : ""
            if (newDue.length > 0)
                body.due_string = newDue
        }

        var xhr = new XMLHttpRequest()
        xhr.open("POST", apiUrl + "/" + taskId)
        xhr.setRequestHeader("Authorization", "Bearer " + token)
        xhr.setRequestHeader("Content-Type", "application/json")

        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return

            if (xhr.status < 200 || xhr.status >= 300) {
                console.warn("[Todoist] Update task failed — HTTP " + xhr.status)
                service.syncFailed()
                return
            }

            var updatedTask = null
            try {
                updatedTask = formatTask(JSON.parse(xhr.responseText))
            } catch (e) {
                updatedTask = null
            }

            if (callback) callback(updatedTask)
        }

        xhr.send(JSON.stringify(body))
    }

    // Mark a task as complete via the close endpoint.
    function completeTask(taskId, callback) {
        if (!token) return

        var xhr = new XMLHttpRequest()
        xhr.open("POST", apiUrl + "/" + taskId + "/close")
        xhr.setRequestHeader("Authorization", "Bearer " + token)

        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return

            if (xhr.status < 200 || xhr.status >= 300) {
                console.warn("[Todoist] Complete task failed — HTTP " + xhr.status)
                service.syncFailed()
                return
            }

            if (callback) callback()
        }

        xhr.send()
    }

    // Permanently delete a task.
    function deleteTask(taskId, callback) {
        if (!token) return

        var xhr = new XMLHttpRequest()
        xhr.open("DELETE", apiUrl + "/" + taskId)
        xhr.setRequestHeader("Authorization", "Bearer " + token)

        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return

            if (xhr.status < 200 || xhr.status >= 300) {
                console.warn("[Todoist] Delete task failed — HTTP " + xhr.status)
                service.syncFailed()
                return
            }

            if (callback) callback()
        }

        xhr.send()
    }

}
