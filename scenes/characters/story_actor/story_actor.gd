class_name StoryActor
extends Character
## A story character that exists only during a cutscene: it covers its FactStaging, walks and gestures on the scaled
## clock, then leaves; no GreyhushShield, so it greys with the place like the prop it stands for (systems/cutscenes).

const GROUP := &"story_actors"

## Unique among the actors of one contents scene.
@export var actor_id: StringName = &""
## The FactStaging whose shown child this actor stands for.
@export var stands_for: NodePath

## The clip a gesture asked for; empty shows the resolver's idle clip.
var _clip: StringName = &""
var _in_scene: bool = false

@onready var _controller: ScriptedController = $Controller
@onready var _locomotion: LocomotionComponent = $Locomotion
@onready var _resolver: StoryAnimationResolver = $AnimationResolver


func _enter_tree() -> void:
	add_to_group(GROUP)

func _ready() -> void:
	super()
	hide()
	process_mode = Node.PROCESS_MODE_DISABLED

## The staging this actor stands for; null when `stands_for` names none.
func staging() -> FactStaging:
	return get_node_or_null(stands_for) as FactStaging

## The rest child it would appear on: the staging's shown child; null when none shows.
func rest_child() -> Node2D:
	var shown := staging().shown() if staging() != null else null
	return shown as Node2D

## Covers the staging and appears on the shown child's feet, facing its flip, in the clip named like it.
func enter() -> void:
	assert(not _in_scene, "%s entered twice" % actor_id)
	_in_scene = true
	var child := rest_child()
	if child != null:
		teleport(child.global_position)
		var sprite := child as Sprite2D
		face_towards(-1.0 if sprite != null and sprite.flip_h else 1.0)
		_clip = StringName(String(child.name).to_snake_case())
		assert(_resolver.has_clip(_clip), "%s has no clip for its rest child '%s'" % [actor_id, child.name])
	if staging() != null:
		staging().cover()
	velocity = Vector2.ZERO
	show()
	process_mode = Node.PROCESS_MODE_INHERIT

## Hides; its process stops after this physics step (gotchas/disabling-a-body-inside-its-own-physics-step-errors-its-move).
func leave() -> void:
	_in_scene = false
	_controller.stop()
	hide()
	set_deferred(&"process_mode", Node.PROCESS_MODE_DISABLED)

func is_in_scene() -> bool:
	return _in_scene

func walk_to(x: float, pace: float) -> void:
	_clip = _resolver.idle_clip()
	_controller.walk_to(x, pace)

func is_walking() -> bool:
	return _controller.is_walking()

## Plays `clip`, a clip of this actor's resolver.
func gesture(clip: StringName) -> void:
	assert(_resolver.has_clip(clip), "%s has no clip '%s'" % [actor_id, clip])
	_clip = clip
	_animation_driver.request_replay()

## Shows the clip `clip` ends held on, at once.
func land_gesture(clip: StringName) -> void:
	assert(_resolver.has_clip(clip), "%s has no clip '%s'" % [actor_id, clip])
	_clip = _resolver.settle_of(clip)

func is_settled() -> bool:
	return _resolver.is_settled(_clip)

## Read by the resolver.
func asked_clip() -> StringName:
	return _clip

func _process_motion(delta: float) -> void:
	if _controller.steer(global_position.x, velocity.x, _locomotion.stats.deceleration, delta):
		velocity.x = 0.0
		teleport(Vector2(_controller.target_x(), global_position.y))
	face_towards(_controller.direction)
	_locomotion.ground_update(delta, _controller.direction)
	if not is_on_floor():
		velocity.y += base_gravity() * delta
