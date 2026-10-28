class_name FoundPickup
extends Area2D
## A found piece lying in its reward slot: Up in reach takes it (systems/found-pieces). It shows only while the save
## lacks it, so a death before a bench puts it back.

## The piece was taken.
signal taken(slot_id: StringName)

## A songbook always teaches the second half (design 02 §7.2.1).
const TAUGHT_HALF := Enums.SongHalf.SECOND
## Px between the art's top and the prompt.
const PROMPT_GAP := 8.0
## Reach, in cells, centred on the slot and rising from its floor.
const REACH_CELLS := Vector2(2.0, 2.0)

## Set before the node enters the tree.
var piece: FoundPiece

var _bodies: int = 0
## Ivo while he is in reach.
var _body: Player

@onready var _shape: CollisionShape2D = $CollisionShape2D
@onready var _sprite: Sprite2D = $Sprite2D
@onready var _prompt: KeyGlyph = $Prompt


## Whether `found` lies in the world under `data`: a letter until taken, a songbook while its half would teach.
static func lies(found: FoundPiece, data: PlayerData) -> bool:
	if found.song != null:
		return SongHalves.can_teach(data, found.song.id, TAUGHT_HALF)
	return not data.found_pieces.has(found.slot_id)

func _init() -> void:
	collision_layer = Seat.LAYER
	collision_mask = Seat.PLAYER_BODY
	monitorable = true
	monitoring = true

func _ready() -> void:
	assert(piece != null, "A FoundPickup needs its piece before _ready")
	var box := RectangleShape2D.new()
	box.size = REACH_CELLS * RoomMap.CELL_PX
	_shape.shape = box
	_shape.position = Vector2(0.0, -box.size.y * 0.5)
	_sprite.texture = piece.texture
	var art_height := float(piece.texture.get_height())
	_sprite.position = Vector2(0.0, -art_height * 0.5)
	_prompt.position = Vector2(-_prompt.size.x * 0.5, -box.size.y - PROMPT_GAP - _prompt.size.y)
	_prompt.show_action(&"look_up")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	SaveSystem.progress_changed.connect(_refresh)
	_refresh()

# Every frame, as ItemPickup does: a talk starts and ends without a signal here. A songbook is read standing still,
# so its prompt hides while Ivo moves (playtests/2026-10-28-story06-found-pieces).
func _physics_process(_delta: float) -> void:
	var readable := _body != null and (piece.song == null or not _body.wants_to_move())
	_prompt.visible = _sprite.visible and readable and not _body.is_in_story() and _body.reaches(self)

## Shown and still lying: Up may take it. Read at the press, never cached.
func is_available() -> bool:
	return is_visible_in_tree() and lies(piece, SaveSystem.player_data)

func is_lying() -> bool:
	return _sprite.visible

## The song a songbook teaches; null for a letter.
func teaches() -> Song:
	return piece.song

## Live, like every gain: a bench commits it, a death forgets it.
func take() -> void:
	SaveSystem.mark_found(piece.slot_id)
	taken.emit(piece.slot_id)

func _refresh() -> void:
	_sprite.visible = lies(piece, SaveSystem.player_data)

func _on_body_entered(body: Node2D) -> void:
	_bodies += 1
	_body = body as Player

func _on_body_exited(_body_left: Node2D) -> void:
	_bodies = maxi(_bodies - 1, 0)
	if _bodies == 0:
		_body = null
