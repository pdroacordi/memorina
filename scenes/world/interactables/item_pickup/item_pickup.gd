class_name ItemPickup
extends Area2D
## An item lying where it was left: Up in reach takes it (systems/pickups). It shows only while the save does not own
## the item, so a death before a bench puts it back.

## The item was taken.
signal taken(item: Enums.PlayerItem)

@export var item: Enums.PlayerItem = Enums.PlayerItem.SWORD
## The item lying down, drawn standing on its bottom row.
@export var texture: Texture2D
## Px from its cell's bottom centre (the floor) to the item's bottom centre: where it lies, on a table top.
@export var rest_offset: Vector2 = Vector2.ZERO
## Reach width, in cells, centred on its cell.
@export var width_cells: int = 2
## Reach height, in cells, rising from its cell's floor.
@export var height_cells: int = 2
## What Ivo says as he takes it (its current dialogue, started by the take itself); null says nothing.
@export var talk: DialogueSet

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _reach: UpReach = $UpReach


## Whether `which` lies in the world under `data`: only while it is not owned.
static func lies(which: Enums.PlayerItem, data: PlayerData) -> bool:
	return not data.owned_items[which]

func _init() -> void:
	collision_layer = Seat.LAYER
	collision_mask = Seat.PLAYER_BODY
	monitorable = true
	monitoring = true

func _ready() -> void:
	_sprite.texture = texture
	var art_height := float(texture.get_height()) if texture != null else 0.0
	_sprite.position = rest_offset + Vector2(0.0, -art_height * 0.5)
	_reach.setup(Vector2(width_cells, height_cells), rest_offset.y - art_height, rest_offset.x)
	SaveSystem.progress_changed.connect(_refresh)
	_refresh()

func _physics_process(_delta: float) -> void:
	_reach.refresh(_sprite.visible)

## Shown and not owned: Up may take it. Read at the press, never cached.
func is_available() -> bool:
	return is_visible_in_tree() and lies(item, SaveSystem.player_data)

## Live, like every gain: a bench commits it, a death forgets it.
func take() -> void:
	SaveSystem.set_item_owned(item, true)
	taken.emit(item)

## The talk the take starts, read after the take; null when none is current.
func talk_after_take() -> Dialogue:
	return talk.current(SaveSystem.player_data) if talk != null else null

func is_lying() -> bool:
	return _sprite.visible

func _refresh() -> void:
	_sprite.visible = lies(item, SaveSystem.player_data)
