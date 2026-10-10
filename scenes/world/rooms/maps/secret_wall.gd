class_name SecretWall
extends Node2D
## A closed secret space drawn as ground until Ivo's body enters it, then faded open for good (architecture/secret-false-walls).

## First opened: the hook for a discovery sound.
signal found(secret_id: StringName)

## Scaled seconds from closed to open; a hold stops it.
const FADE_TIME := 0.4
## Physics layer 9: the Player body, never the hurtbox (gotchas/monitorable-false-hides-an-area-from-every-monitor).
const PLAYER_BODY_MASK := 1 << 8
## Alpha of a closed wall in the editor, so the author sees the hollow behind it.
const EDITOR_ALPHA := 0.5

## `<room file>@x,y`, the key `found_secrets` remembers.
var secret_id: StringName
var _front: Array[CanvasItem] = []
var _rects: Array[Rect2] = []
var _trigger: Area2D


func _ready() -> void:
	if Engine.is_editor_hint():
		modulate.a = EDITOR_ALPHA
		return
	for item: CanvasItem in _front:
		CanvasPass.join_layer(item, CanvasPass.FOREGROUND)
	if SaveSystem.is_secret_found(secret_id):
		visible = false
		return
	_trigger = Area2D.new()
	_trigger.name = "Trigger"
	_trigger.collision_layer = 0
	_trigger.collision_mask = PLAYER_BODY_MASK
	_trigger.monitorable = false
	for rect: Rect2 in _rects:
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = rect.size
		shape.shape = box
		shape.position = rect.get_center()
		_trigger.add_child(shape)
	add_child(_trigger)
	_trigger.body_entered.connect(_on_body_entered)

## Called by RoomMapNode before the wall enters the tree: the layers drawn in ForegroundPass and the trigger's local rects.
func setup(id: StringName, front: Array[CanvasItem], rects: Array[Rect2]) -> void:
	secret_id = id
	_front = front
	_rects = rects

func _on_body_entered(_body: Node2D) -> void:
	# Deferred: an area cannot change its monitoring inside the physics flush.
	_trigger.set_deferred(&"monitoring", false)
	_trigger.body_entered.disconnect(_on_body_entered)
	SaveSystem.find_secret(secret_id)
	found.emit(secret_id)
	# Only the front copy fades: two fading copies would hide the hollow longer than Ivo, who is drawn between them.
	for child: Node in get_children():
		if child is CanvasItem and not child in _front:
			(child as CanvasItem).visible = false
	var tween := create_tween()
	tween.tween_property(self, ^"modulate:a", 0.0, FADE_TIME)
	tween.tween_callback(hide)
