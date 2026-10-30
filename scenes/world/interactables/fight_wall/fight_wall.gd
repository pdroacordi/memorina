class_name FightWall
extends StaticBody2D
## A wall of stopped grey across an arena exit, solid while its guardian fights Ivo inside the arena ("Parede de cinza",
## user, 2026-10-30; GRD-05; systems/guardians).

## Height in cells, rising from its cell's floor.
@export var cells: int = 4
## Width in cells, growing east from its cell: a ceiling under a shaft is one cell tall and several across.
@export var across: int = 1

## Closed: its body bars the way.
var _closed: bool = false

@onready var _shape: CollisionShape2D = $CollisionShape2D
@onready var _curtain: ColorRect = $Curtain


## Closes once a fight is on at the wall and at Ivo and his body is clear of it; stays closed while the fight is on.
static func closes(closed: bool, fighting: bool, clear: bool) -> bool:
	return fighting and (closed or clear)

func _ready() -> void:
	var rect := _local_rect()
	var box := RectangleShape2D.new()
	box.size = rect.size
	_shape.shape = box
	_shape.position = rect.get_center()
	_shape.disabled = true
	_curtain.position = rect.position
	_curtain.size = rect.size
	(_curtain.material as ShaderMaterial).set_shader_parameter(&"size_px", rect.size)
	_curtain.visible = false

func _physics_process(_delta: float) -> void:
	var ivo := get_tree().get_first_node_in_group(Player.GROUP) as Player
	var fighting := (ivo != null and Guardian.fight_at(get_tree(), global_position)
			and Guardian.fight_at(get_tree(), ivo.global_position))
	var clear := ivo == null or not body_rect().intersects(ivo.body_rect())
	var closed := closes(_closed, fighting, clear)
	if closed == _closed:
		return
	_closed = closed
	# Deferred: the fight can end inside a physics callback.
	_shape.set_deferred(&"disabled", not closed)
	_curtain.visible = closed

func is_closed() -> bool:
	return _closed

## Its body in global coordinates.
func body_rect() -> Rect2:
	var rect := _local_rect()
	return Rect2(global_position + rect.position, rect.size)

## Its body around its origin, the first cell's bottom centre.
func _local_rect() -> Rect2:
	var size := Vector2(across * RoomMap.CELL_PX, cells * RoomMap.CELL_PX)
	return Rect2(Vector2(-RoomMap.CELL_PX * 0.5, -size.y), size)
