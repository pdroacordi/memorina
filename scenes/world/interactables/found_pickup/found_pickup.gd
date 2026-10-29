class_name FoundPickup
extends Area2D
## A found piece lying in its reward slot: Up in reach takes it (systems/found-pieces). It shows only while the save
## lacks it, so a death before a bench puts it back.

## The piece was taken.
signal taken(slot_id: StringName)

## A songbook always teaches the second half (design 02 §7.2.1).
const TAUGHT_HALF := Enums.SongHalf.SECOND
## Reach, in cells, centred on the slot and rising from its floor.
const REACH_CELLS := Vector2(2.0, 2.0)

## Set before the node enters the tree.
var piece: FoundPiece

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _reach: UpReach = $UpReach


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
	_sprite.texture = piece.texture
	var art_height := float(piece.texture.get_height())
	_sprite.position = Vector2(0.0, -art_height * 0.5)
	_reach.setup(REACH_CELLS, -art_height)
	SaveSystem.progress_changed.connect(_refresh)
	_refresh()

# A songbook is read standing still, so its prompt hides while Ivo moves (playtests/2026-10-28-story06-found-pieces).
func _physics_process(_delta: float) -> void:
	var player := _reach.player()
	var readable := player != null and (piece.song == null or not player.wants_to_move())
	_reach.refresh(_sprite.visible and readable)

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
