class_name Talkable
extends Area2D
## A place Ivo talks: Up in reach, or an auto start on arrival, runs its set's current dialogue (systems/dialogue). It
## stands beside a villager prop, never on it: a prop carries no gameplay (systems/props).

const GROUP := &"talkables"
## Px between the zone's top and the prompt.
const PROMPT_GAP := 8.0

## The talker's dialogues; must be in the DialogueCatalog (room_files_test).
@export var talk: DialogueSet
## Starts its pending dialogue on its own when Ivo comes in reach, once per visit.
@export var auto_start: bool = false
## Region baseline (0..1) at and above which it is present, like its villager's RegionPresence; 0 is always.
@export_range(0.0, 1.0) var presence: float = 0.0
## Zone width, in cells, centred on its cell.
@export var width_cells: int = 2
## Zone height, in cells, rising from its cell's floor.
@export var height_cells: int = 2
## Seconds in reach before an auto start is due: past an arrival's fade.
@export var auto_delay: float = 0.4
## Px along x from its origin to where the speaker (the villager prop beside it) stands; Ivo faces that point.
@export var speaker_offset: float = 0.0

## Ivo while he is in reach.
var _body: Player
var _bodies: int = 0
var _armed: bool = false
## Seconds since the auto start armed.
var _armed_for: float = 0.0

@onready var _shape: CollisionShape2D = $CollisionShape2D
@onready var _prompt: KeyGlyph = $Prompt


func _init() -> void:
	collision_layer = Seat.LAYER
	collision_mask = Seat.PLAYER_BODY
	monitorable = true
	monitoring = true

func _enter_tree() -> void:
	add_to_group(GROUP)

func _ready() -> void:
	var box := RectangleShape2D.new()
	box.size = size()
	_shape.shape = box
	_shape.position = Vector2(0.0, -box.size.y * 0.5)
	_prompt.position = Vector2(-_prompt.size.x * 0.5, -box.size.y - PROMPT_GAP - _prompt.size.y)
	_prompt.show_action(&"look_up")
	_prompt.hide()
	if presence > 0.0:
		var keeper := RegionPresence.new()
		keeper.min_baseline = presence
		add_child(keeper)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	if _armed:
		_armed_for += delta
	_prompt.visible = _body != null and not _body.is_talking() and has_talk()

## The zone's size in px.
func size() -> Vector2:
	return Vector2(width_cells, height_cells) * RoomMap.CELL_PX

## Where the speaker stands, in world px.
func speaker_position() -> Vector2:
	return global_position + Vector2(speaker_offset, 0.0)

func current(data: PlayerData) -> Dialogue:
	return talk.current(data) if talk != null else null

## Present, with a current dialogue under the live save.
func has_talk() -> bool:
	return is_visible_in_tree() and current(SaveSystem.player_data) != null

## An auto start is armed, its delay has passed and a dialogue is pending.
func auto_ready() -> bool:
	return (auto_start and _armed and _armed_for >= auto_delay and is_visible_in_tree() and talk != null
			and talk.pending(SaveSystem.player_data) != null)

## The auto start fired; it arms again only after Ivo leaves and comes back.
func take_auto() -> void:
	_armed = false

func _on_body_entered(body: Node2D) -> void:
	_bodies += 1
	_body = body as Player
	if _bodies == 1:
		_armed = true
		_armed_for = 0.0

func _on_body_exited(_body_left: Node2D) -> void:
	_bodies = maxi(_bodies - 1, 0)
	if _bodies == 0:
		_body = null
		_armed = false
