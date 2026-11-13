class_name SwingPushBeat
extends DialogueBeat
## Ivo pushes her swing once, or stops pushing it (flashback 3, systems/story): a push swings `sway` while he holds the
## beat's pose (PUSH_SWING) for `seconds`, then he stands to hear her; letting go leaves the swing to die down by itself.

enum Kind { PUSH, LET_GO }

@export var kind: Kind = Kind.PUSH
@export var sway: SwingSway
## Scaled seconds the beat lasts.
@export var seconds: float = 0.9

var _left: float = 0.0
var _running: bool = false


func _process(delta: float) -> void:
	if not _running:
		return
	_left -= delta
	if _left <= 0.0:
		_running = false
		# The push clip would loop through her line: he stands once the push is given.
		change_pose(Pose.NONE)
		finish()

func start() -> void:
	if kind == Kind.PUSH:
		sway.push()
	else:
		sway.let_go()
	_left = seconds
	_running = true
	super()

func is_running() -> bool:
	return _running
