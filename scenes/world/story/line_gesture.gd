class_name LineGesture
extends Node
## A figure's clip played while a line is shown: stands `child` in on `staging` and releases it when the clip ends
## (systems/story, architecture/story37-the-mentor-moves-while-he-talks).

const GROUP := &"line_gestures"

## Matches a DialogueLine's `gesture`.
@export var gesture: StringName = &""
@export var staging: NodePath
## A StagedStrip child of `staging` with an `intro` and no `loop`.
@export var child: StringName = &""
## The clip's last frame stays until something else takes the staging.
@export var holds: bool = false

@onready var _staging: FactStaging = get_node_or_null(staging) as FactStaging
@onready var _strip: StagedStrip = _staging.get_node_or_null(NodePath(child)) as StagedStrip if _staging != null else null


## The gesture for `wanted` in the tree; null when none is loaded.
static func find(tree: SceneTree, wanted: StringName) -> LineGesture:
	for node: Node in tree.get_nodes_in_group(GROUP):
		var found := node as LineGesture
		if found != null and found.gesture == wanted:
			return found
	return null

func _enter_tree() -> void:
	add_to_group(GROUP)

func _ready() -> void:
	assert(_staging != null and _strip != null, "%s: no StagedStrip '%s' under %s" % [name, child, staging])
	if not holds:
		_strip.animation_finished.connect(_on_clip_finished)

func play() -> void:
	_staging.stand_in(child)

func _on_clip_finished() -> void:
	_staging.release(child)
