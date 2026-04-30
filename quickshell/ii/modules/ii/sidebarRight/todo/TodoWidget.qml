import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "."

Item {
	id: root

	property bool showAddDialog: false
	property bool isEditMode: false
	property var editingTask: null
	property bool needsKeyboardFocus: showAddDialog
	property int dialogMargins: 20
	property int fabSize: 48
	property int fabMargins: 14

	function labelsToInput(labelsValue) {
		if (labelsValue === null || labelsValue === undefined)
			return ""

		if (Array.isArray(labelsValue))
			return labelsValue.join(", ")

		if (typeof labelsValue === "string")
			return labelsValue

		if (typeof labelsValue.length === "number") {
			var values = []
			for (var i = 0; i < labelsValue.length; i++)
				values.push(labelsValue[i])
			return values.join(", ")
		}

		return ""
	}

	function priorityColor(priority) {
		var value = Number(priority)
		if (value === 1)
			return "#e53935"
		if (value === 2)
			return "#fb8c00"
		if (value === 3)
			return "#fdd835"
		return Appearance.m3colors.m3outline
	}

	function selectedPriorityValue() {
		return prioritySelector.currentIndex === 0 ? null : prioritySelector.currentIndex
	}

	function openAddDialog() {
		isEditMode = false
		editingTask = null
		todoInput.text = ""
		dueInput.text = ""
		labelsInput.text = ""
		prioritySelector.currentIndex = 0
		showAddDialog = true
	}

	function openEditDialog(task) {
		if (!task || !task.id)
			return

		isEditMode = true
		editingTask = task
		todoInput.text = task.content || ""
		dueInput.text = task.dueString || ""
		labelsInput.text = labelsToInput(task.labels)
		var priority = Number(task.priority)
		if (isNaN(priority) || priority < 1 || priority > 4)
			prioritySelector.currentIndex = 0
		else
			prioritySelector.currentIndex = priority
		showAddDialog = true
	}

	function closeDialog() {
		showAddDialog = false
	}

	function saveTask() {
		var content = todoInput.text.trim()
		if (content.length === 0)
			return

		var due = dueInput.text.trim()
		var priority = prioritySelector.currentIndex === 0 ? null : prioritySelector.currentIndex
		var labels = labelsInput.text

		if (isEditMode && editingTask) {
			var updatePayload = {
				content: content,
				dueString: due,
				clearDue: due.length === 0,
				labels: labels
			}

			if (priority !== null)
				updatePayload.priority = priority

			todoController.editTask(editingTask.id, updatePayload)
		} else {
			todoController.addTask({
				content: content,
				dueString: due,
				priority: priority,
				labels: labels
			})
		}

		closeDialog()
	}

	TodoController {
		id: todoController
	}

	// Pull fresh data from Todoist every 60 seconds
	Timer {
		interval: 60000
		repeat: true
		running: true
		onTriggered: todoController.refresh()
	}

    Keys.onPressed: (event) => {
        // Open add dialog on "N" (any modifiers)
        if (event.key === Qt.Key_N) {
            root.openAddDialog()
            event.accepted = true;
        }
        // Close dialog on Esc if open
        else if (event.key === Qt.Key_Escape && root.showAddDialog) {
            root.showAddDialog = false
            event.accepted = true;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        TaskList {
            Layout.topMargin: 10
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            listBottomPadding: root.fabSize + root.fabMargins * 2 + 12
            emptyPlaceholderIcon: "check_circle"
            emptyPlaceholderText: Translation.tr("Nothing here!")
            controller: todoController
            taskList: todoController.unfinishedTasks
            onEditRequested: task => root.openEditDialog(task)
        }
    }

    // + FAB
    StyledRectangularShadow {
        target: fabButton
        radius: fabButton.buttonRadius
        blur: 0.6 * Appearance.sizes.elevationMargin
    }
    FloatingActionButton {
        id: fabButton
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: root.fabMargins
        anchors.bottomMargin: root.fabMargins

        onClicked: root.openAddDialog()
        iconText: "add"
    }

    Item {
        anchors.fill: parent
        z: 9999

        visible: opacity > 0
        opacity: root.showAddDialog ? 1 : 0
        Behavior on opacity {
            NumberAnimation { 
                duration: Appearance.animation.elementMoveFast.duration
                easing.type: Appearance.animation.elementMoveFast.type
                easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
            }
        }

        // Small delay so the compositor has time to grant input focus
        // before we try to grab it for the text field.
        Timer {
            id: focusGrabTimer
            interval: 50
            repeat: false
            onTriggered: {
                if (root.showAddDialog)
                    todoInput.forceActiveFocus();
            }
        }

        onVisibleChanged: {
            if (visible) {
                focusGrabTimer.restart()
            } else {
                focusGrabTimer.stop()
                todoInput.text = ""
                dueInput.text = ""
                labelsInput.text = ""
		prioritySelector.currentIndex = 0
		root.isEditMode = false
		root.editingTask = null
                fabButton.focus = true
            }
        }

        Rectangle { // Scrim
            anchors.fill: parent
            radius: Appearance.rounding.small
            color: Appearance.colors.colScrim
            MouseArea {
                hoverEnabled: true
                anchors.fill: parent
                preventStealing: true
                propagateComposedEvents: false
            }
        }

        Rectangle { // The dialog
            id: dialog
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: root.dialogMargins
            implicitHeight: dialogColumnLayout.implicitHeight

            color: Appearance.m3colors.m3surfaceContainerHigh
            radius: Appearance.rounding.normal

            ColumnLayout {
                id: dialogColumnLayout
                anchors.fill: parent
                spacing: 16

                StyledText {
                    Layout.topMargin: 16
                    Layout.leftMargin: 16
                    Layout.rightMargin: 16
                    Layout.alignment: Qt.AlignLeft
                    color: Appearance.m3colors.m3onSurface
                    font.pixelSize: Appearance.font.pixelSize.larger
                    text: root.isEditMode ? Translation.tr("Edit task") : Translation.tr("Add task")
                }

                TextField {
                    id: todoInput
                    Layout.fillWidth: true
                    Layout.leftMargin: 16
                    Layout.rightMargin: 16
                    padding: 10
                    color: activeFocus ? Appearance.m3colors.m3onSurface : Appearance.m3colors.m3onSurfaceVariant
                    renderType: Text.NativeRendering
                    selectedTextColor: Appearance.m3colors.m3onSecondaryContainer
                    selectionColor: Appearance.colors.colSecondaryContainer
                    placeholderText: Translation.tr("Task description")
                    placeholderTextColor: Appearance.m3colors.m3outline
                    focus: root.showAddDialog
                    onAccepted: root.saveTask()

                    background: Rectangle {
                        anchors.fill: parent
                        radius: Appearance.rounding.verysmall
                        border.width: 2
                        border.color: todoInput.activeFocus ? Appearance.colors.colPrimary : Appearance.m3colors.m3outline
                        color: "transparent"
                    }

                    cursorDelegate: Rectangle {
                        width: 1
                        color: todoInput.activeFocus ? Appearance.colors.colPrimary : "transparent"
                        radius: 1
                    }
                }

                TextField {
                    id: dueInput
                    Layout.fillWidth: true
                    Layout.leftMargin: 16
                    Layout.rightMargin: 16
                    padding: 10
                    color: activeFocus ? Appearance.m3colors.m3onSurface : Appearance.m3colors.m3onSurfaceVariant
                    renderType: Text.NativeRendering
                    selectedTextColor: Appearance.m3colors.m3onSecondaryContainer
                    selectionColor: Appearance.colors.colSecondaryContainer
                    placeholderText: Translation.tr("Due (e.g. tomorrow 9pm)")
                    placeholderTextColor: Appearance.m3colors.m3outline
                    onAccepted: root.saveTask()

                    background: Rectangle {
                        anchors.fill: parent
                        radius: Appearance.rounding.verysmall
                        border.width: 2
                        border.color: dueInput.activeFocus ? Appearance.colors.colPrimary : Appearance.m3colors.m3outline
                        color: "transparent"
                    }

                    cursorDelegate: Rectangle {
                        width: 1
                        color: dueInput.activeFocus ? Appearance.colors.colPrimary : "transparent"
                        radius: 1
                    }
                }

				RowLayout {
					Layout.fillWidth: true
					Layout.leftMargin: 16
					Layout.rightMargin: 16
					spacing: 8

					Rectangle {
						Layout.preferredWidth: 12
						Layout.preferredHeight: 28
						radius: 3
						color: root.priorityColor(root.selectedPriorityValue())
					}

					StyledComboBox {
						id: prioritySelector
						Layout.fillWidth: true
						model: ["None", "P1", "P2", "P3", "P4"]
						currentIndex: 0
					}
				}

                TextField {
                    id: labelsInput
                    Layout.fillWidth: true
                    Layout.leftMargin: 16
                    Layout.rightMargin: 16
                    padding: 10
                    color: activeFocus ? Appearance.m3colors.m3onSurface : Appearance.m3colors.m3onSurfaceVariant
                    renderType: Text.NativeRendering
                    selectedTextColor: Appearance.m3colors.m3onSecondaryContainer
                    selectionColor: Appearance.colors.colSecondaryContainer
                    placeholderText: Translation.tr("Labels (comma-separated)")
                    placeholderTextColor: Appearance.m3colors.m3outline
                    onAccepted: root.saveTask()

                    background: Rectangle {
                        anchors.fill: parent
                        radius: Appearance.rounding.verysmall
                        border.width: 2
                        border.color: labelsInput.activeFocus ? Appearance.colors.colPrimary : Appearance.m3colors.m3outline
                        color: "transparent"
                    }

                    cursorDelegate: Rectangle {
                        width: 1
                        color: labelsInput.activeFocus ? Appearance.colors.colPrimary : "transparent"
                        radius: 1
                    }
                }

                RowLayout {
                    Layout.bottomMargin: 16
                    Layout.leftMargin: 16
                    Layout.rightMargin: 16
                    Layout.alignment: Qt.AlignRight
                    spacing: 5

                    DialogButton {
                        buttonText: Translation.tr("Cancel")
                        onClicked: root.closeDialog()
                    }
                    DialogButton {
                        buttonText: root.isEditMode ? Translation.tr("Save") : Translation.tr("Add")
                        enabled: todoInput.text.trim().length > 0
                        onClicked: root.saveTask()
                    }
                }
            }
        }
    }
}
