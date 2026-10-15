class_name DialogueBeat
extends Node
## A scripted beat a line's `cue` hands the talk to: the box hides, Ivo is free, and the talk resumes at `finished`
## (systems/dialogue). A scene composes one and calls `finish()` when its beat is over.

signal started
signal finished

const GROUP := &"dialogue_beats"

## Matches a DialogueLine's `cue`.
@export var cue: StringName = &""


## The beat for `cue` in the tree; null when none is loaded.
static func find(tree: SceneTree, wanted: StringName) -> DialogueBeat:
	for node: Node in tree.get_nodes_in_group(GROUP):
		var beat := node as DialogueBeat
		if beat != null and beat.cue == wanted:
			return beat
	return null

func _enter_tree() -> void:
	add_to_group(GROUP)

func start() -> void:
	started.emit()

func finish() -> void:
	finished.emit()
