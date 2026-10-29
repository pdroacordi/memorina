class_name RewardSlot
extends Node2D
## A place the layout promises a reward, filled later by slot_id (architecture/reward-slots-reserve-their-place-in-the-room-text).

## Append only: maps store the number.
enum Kind {
	## A STORY-06 collectible: a letter, a diary page, a photo.
	COLLECTIBLE,
	## A LIFE-04 cache: one season seed (systems/seeds-and-the-seller).
	CACHE,
}

const MARKER_COLOURS: Dictionary[Kind, Color] = {
	Kind.COLLECTIBLE: Color("#f2c84b"),
	Kind.CACHE: Color("#a0662f"),
}
## px, the marker's half width.
const MARKER_HALF := 6.0
## px above the floor to the marker's centre, clear of the grass.
const MARKER_LIFT := 22.0
## Over grass and ground; under a closed secret's world copy, which must hide it.
const MARKER_Z := RoomMapNode.SECRET_Z - 10
const FOUND_PICKUP := preload("res://scenes/world/interactables/found_pickup/found_pickup.tscn")
const CACHE_PICKUP := preload("res://scenes/world/interactables/cache_pickup/cache_pickup.tscn")

## Unique across every map; the filling system's catalog keys its content by it.
@export var slot_id: StringName
@export var kind: Kind = Kind.COLLECTIBLE

# Not exported: the map guide lists exports as legend params.
var found_catalog: FoundCatalog = preload(FoundCatalog.DEFAULT_PATH)

## A FoundPickup or a CachePickup; null for an unfilled slot.
var _content: Area2D


func _ready() -> void:
	z_index = MARKER_Z
	_fill()


## The pickup this slot holds (a FoundPickup or a CachePickup); null for an unfilled slot.
func content() -> Area2D:
	return _content


func _draw() -> void:
	# Release builds and filled slots draw no marker: an unfilled slot gives nothing until LIFE-05 fills it.
	if not OS.is_debug_build() or _content != null:
		return
	var centre := Vector2(0.0, -MARKER_LIFT)
	var points := PackedVector2Array([
		centre + Vector2(0.0, -MARKER_HALF),
		centre + Vector2(MARKER_HALF, 0.0),
		centre + Vector2(0.0, MARKER_HALF),
		centre + Vector2(-MARKER_HALF, 0.0),
	])
	draw_colored_polygon(points, MARKER_COLOURS[kind])
	points.append(points[0])
	draw_polyline(points, Color.BLACK, 2.0)


# Every cache holds one seed, so a CACHE needs no catalog.
func _fill() -> void:
	if kind == Kind.CACHE:
		var cache := CACHE_PICKUP.instantiate() as CachePickup
		cache.slot_id = slot_id
		_content = cache
	elif found_catalog != null:
		var piece := found_catalog.get_piece(slot_id)
		if piece == null:
			return
		var found := FOUND_PICKUP.instantiate() as FoundPickup
		found.piece = piece
		_content = found
	else:
		return
	add_child(_content)
