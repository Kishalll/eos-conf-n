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
    // callback(tasks) receives an array of { id, content, done } objects.
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
                    formatted.push({
                        id: items[i].id,
                        content: items[i].content,
                        done: items[i].checked || false
                    })
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
    function createTask(content, callback) {
        if (!token) return

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

            if (callback) callback()
        }

        xhr.send(JSON.stringify({ "content": content }))
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
