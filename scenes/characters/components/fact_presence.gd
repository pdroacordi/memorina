class_name FactPresence
extends Node
## Keeps its parent present only while the save passes `when` and `unless` (systems/story, "FactPresence"): absent, the
## parent is hidden and DISABLED. It is the only writer of its parent's `visible` and `process_mode`.

@export var when: Array[SaveFact] = []
@export var unless: Array[SaveFact] = []

var _parent: CanvasItem


func _ready() -> void:
	_parent = get_parent() as CanvasItem
	assert(_parent != null, "FactPresence must be the child of a CanvasItem.")
	SaveSystem.progress_changed.connect(_on_progress_changed)
	apply()

## Whether the parent is present under the current save.
func is_present() -> bool:
	return SaveFact.gates_pass(when, unless, SaveSystem.player_data)

func apply() -> void:
	var present := is_present()
	_parent.visible = present
	# INHERIT, so a deactivated room's contents root still disables a present parent.
	_parent.process_mode = Node.PROCESS_MODE_INHERIT if present else Node.PROCESS_MODE_DISABLED

func _on_progress_changed() -> void:
	# Deferred: progress can change inside a physics callback, where a body cannot leave the physics server.
	apply.call_deferred()
