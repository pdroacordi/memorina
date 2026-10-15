class_name Door
extends Area2D
## A doorway: Up in reach takes Ivo to the door sharing its `link` in `to_room` (design 04 section 4, architecture/doors-and-interiors).

## A press at a sealed door.
signal knocked

const GROUP := &"doors"
## Seconds the sprite shakes on a knock.
const KNOCK_TIME := 0.2
## Pixels the sprite shakes either way on a knock.
const KNOCK_PX := 2.0
## Art per kind of doorway: two frames (open, sealed) standing on the door's floor (systems/rooms, Doors).
const LOOKS: Dictionary[String, Texture2D] = {
	"door": preload("res://assets/sprites/world/props/door/door.png"),
	"passage": preload("res://assets/sprites/world/props/door/door_passage.png"),
	"stairwell": preload("res://assets/sprites/world/props/door/door_stairwell.png"),
	"hatch_up": preload("res://assets/sprites/world/props/door/door_hatch_up.png"),
	"hatch_down": preload("res://assets/sprites/world/props/door/door_hatch_down.png"),
	"breach": preload("res://assets/sprites/world/props/door/door_breach.png"),
}
## Px of a look's art below the floor line. Must match the floor line in tools/art/prompts/door_stairwell.md.
const SINKS: Dictionary[String, float] = {"stairwell": 67.0}
## Frames side by side in every look's art (open, sealed).
const FRAMES := 2
## Px between the art and the prompt.
const PROMPT_GAP := 8.0
## Highest the prompt's top sits above the floor line, in px. Must match the Prompt's offset_top in door.tscn.
const PROMPT_TOP := -104.0

## Name of the doorway, shared by exactly two doors across the world.
@export var link: StringName = &""
## Room id (Room scene file name) of the partner door; same region.
@export var to_room: StringName = &""
## The save fact that opens the door; null is always open.
@export var requires: SaveFact
## Facing on arrival through the partner: 0 keeps Ivo's, 1 right, -1 left.
@export_range(-1, 1) var arrive_facing: int = 0
## A building door, a passage cut in stone, a stairwell down through a stone floor, a ladder hatch up or down, or a
## breach in a facade that draws its own hole.
@export_enum("door", "passage", "stairwell", "hatch_up", "hatch_down", "breach") var look: String = "door"

var _bodies: int = 0
var _knock: Tween
## The closed secret the doorway stands in, if any.
var _hidden_by: SecretWall

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _prompt: KeyGlyph = $Prompt


## The door in `room` that carries `link`, if its contents are loaded.
static func find(tree: SceneTree, room: Room, link_name: StringName) -> Door:
	for node: Node in tree.get_nodes_in_group(GROUP):
		var door := node as Door
		if door != null and door.link == link_name and room.is_ancestor_of(door):
			return door
	return null

## The prompt's top-left in a `look` door's space: above the art, or beside it at its middle when above would leave
## `bounds`, the room in the space `feet` is in (bugs/the-lake-well-hatch-prompt-is-cut-by-the-top-of-the-frame).
static func prompt_position(look: String, prompt_size: Vector2, feet: Vector2, bounds: Rect2) -> Vector2:
	var texture: Texture2D = LOOKS.get(look, LOOKS["door"])
	var sink: float = SINKS.get(look, 0.0)
	var art := Vector2(texture.get_width() / float(FRAMES), texture.get_height())
	var above := Vector2(-prompt_size.x * 0.5, minf(PROMPT_TOP, sink - art.y - PROMPT_GAP - prompt_size.y))
	if not bounds.has_area() or bounds.encloses(Rect2(feet + above, prompt_size)):
		return above
	var middle := sink - (art.y + prompt_size.y) * 0.5
	var right := Vector2(art.x * 0.5 + PROMPT_GAP, middle)
	if bounds.encloses(Rect2(feet + right, prompt_size)):
		return right
	return Vector2(-art.x * 0.5 - PROMPT_GAP - prompt_size.x, middle)

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
	_dress()
	_hide_in_secret()
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

## Hides the art until `wall` opens: a doorway inside a closed secret must not show through the stone around it
## (bugs/the-cistern-stairwell-shows-through-the-closed-secret-wall).
func hide_until(wall: SecretWall) -> void:
	_hidden_by = wall
	if is_node_ready():
		_hide_in_secret()

func _hide_in_secret() -> void:
	if _hidden_by == null or SaveSystem.is_secret_found(_hidden_by.secret_id):
		return
	_sprite.visible = false
	_hidden_by.found.connect(func(_id: StringName) -> void: _sprite.visible = true, CONNECT_ONE_SHOT)

func _dress() -> void:
	var texture: Texture2D = LOOKS.get(look, LOOKS["door"])
	_sprite.texture = texture
	var sink: float = SINKS.get(look, 0.0)
	_sprite.position.y = sink - texture.get_height() * 0.5
	var room := Room.of(self)
	var bounds := room.get_bounds() if room != null else Rect2()
	_prompt.position = Door.prompt_position(look, _prompt.size, global_position, bounds)

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
