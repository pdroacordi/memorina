class_name Door
extends Area2D
## A building's doorway: Up in reach takes Ivo to the door sharing its `link` in `to_room` (design 04 section 4, architecture/doors-and-interiors).

## A press at a sealed door.
signal knocked

const GROUP := &"doors"
## Seconds the sprite shakes on a knock.
const KNOCK_TIME := 0.2
## Pixels the sprite shakes either way on a knock.
const KNOCK_PX := 2.0

## Name of the doorway, shared by exactly two doors across the world.
@export var link: StringName = &""
## Room id (Room scene file name) of the partner door; same region.
@export var to_room: StringName = &""
## The save fact that opens the door; null is always open.
@export var requires: SaveFact
## Facing on arrival through the partner: 0 keeps Ivo's, 1 right, -1 left.
@export_range(-1, 1) var arrive_facing: int = 0

var _bodies: int = 0
var _knock: Tween

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _prompt: KeyGlyph = $Prompt


## The door in `room` that carries `link`, if its contents are loaded.
static func find(tree: SceneTree, room: Room, link_name: StringName) -> Door:
	for node: Node in tree.get_nodes_in_group(GROUP):
		var door := node as Door
		if door != null and door.link == link_name and room.is_ancestor_of(door):
			return door
	return null

func _init() -> void:
	collision_layer = Seat.LAYER
	collision_mask = Seat.PLAYER_BODY
	monitorable = true
	monitoring = true

func _enter_tree() -> void:
	add_to_group(GROUP)

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	SaveSystem.progress_changed.connect(_refresh)
	_prompt.show_action(&"look_up")
	_refresh()

func is_open_for(data: PlayerData) -> bool:
	return requires == null or requires.holds(data)

## Read at the press, never cached: a death rewinds the save under the door.
func is_open() -> bool:
	return is_open_for(SaveSystem.player_data)

func has_body_in_reach() -> bool:
	return _bodies > 0

## The sealed door answers a press by shaking in whole pixels.
func knock() -> void:
	if _knock != null:
		_knock.kill()
	_sprite.position.x = 0.0
	_knock = create_tween()
	var step := KNOCK_TIME / 4.0
	for x: float in [KNOCK_PX, -KNOCK_PX, KNOCK_PX, 0.0]:
		_knock.tween_property(_sprite, "position:x", x, step)
	knocked.emit()

func _refresh() -> void:
	var open := is_open()
	_sprite.frame = 0 if open else 1
	_prompt.visible = open and has_body_in_reach()

func _on_body_entered(_body: Node2D) -> void:
	_bodies += 1
	_refresh()

func _on_body_exited(_body: Node2D) -> void:
	_bodies = maxi(_bodies - 1, 0)
	_refresh()
