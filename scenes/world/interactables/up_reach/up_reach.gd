class_name UpReach
extends Node
## The Up reach every pickup composes: sizes its root's shape, stands the prompt over it and tracks Ivo in it
## (systems/pickups). The root is the Area2D parent, which PickupComponent finds.

## Px between the art's or the reach's top, whichever is higher, and the prompt.
const PROMPT_GAP := 8.0

@export var shape_path: NodePath = ^"../CollisionShape2D"
@export var prompt_path: NodePath = ^"../Prompt"

var _bodies: int = 0
## Ivo while he is in reach.
var _body: Player

@onready var _area: Area2D = get_parent() as Area2D
@onready var _shape: CollisionShape2D = get_node(shape_path)
@onready var _prompt: KeyGlyph = get_node(prompt_path)


func _ready() -> void:
	assert(_area != null, "An UpReach must be the child of a pickup's Area2D")
	_area.body_entered.connect(_on_body_entered)
	_area.body_exited.connect(_on_body_exited)

## Sizes the reach to `cells`, centred on the root and rising from its floor, and stands the prompt over the higher of
## the reach and `art_top` (px from the root, negative up), centred on `art_x`. The root calls it in its own _ready.
func setup(cells: Vector2, art_top: float, art_x: float = 0.0) -> void:
	var box := RectangleShape2D.new()
	box.size = cells * RoomMap.CELL_PX
	_shape.shape = box
	_shape.position = Vector2(0.0, -box.size.y * 0.5)
	var top := minf(-box.size.y, art_top)
	_prompt.position = Vector2(art_x - _prompt.size.x * 0.5, top - PROMPT_GAP - _prompt.size.y)
	_prompt.show_action(&"look_up")

## Ivo while he is in reach; null otherwise.
func player() -> Player:
	return _body

## Shows the prompt only while `shown`, Ivo is in reach and not in a story, and Up would reach the root. The root calls it
## every physics frame, as Talkable does: a talk starts and ends without a signal here.
func refresh(shown: bool) -> void:
	_prompt.visible = shown and _body != null and not _body.is_in_story() and _body.reaches(_area)

func _on_body_entered(body: Node2D) -> void:
	_bodies += 1
	_body = body as Player

func _on_body_exited(_body_left: Node2D) -> void:
	_bodies = maxi(_bodies - 1, 0)
	if _bodies == 0:
		_body = null
