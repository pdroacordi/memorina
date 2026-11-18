class_name SpawnedAttack
extends Node2D
## A guardian's projectile or floor hazard: warns with its hitbox off, hurts while live, fades, then expires.
## Runs on the scaled physics clock and pauses with the world; its root script owns its Hitbox's `monitoring`.

## The spawn ran its course; GuardianSpawner frees it.
signal expired

## Sampling step, s, of `hit_transforms`.
const SAMPLE := 1.0 / 60.0
## Px above the floor a floor warning's line is drawn: over the tallest grass blade (GrassLook, 2x art), which the
## front grass strip draws over the creature pass.
const WARN_RISE := float(GrassLook.MAX_BLADE_ART * 2 + 4)

## Scaled seconds of the warning, the hitbox off.
@export var warn: float = 0.35
## Scaled seconds the hitbox is on.
@export var live: float = 0.8
## Scaled seconds of the fade after it, the hitbox off.
@export var fade: float = 0.2
## Light and dark of its two-value art, so it reads in the grey.
@export var light: Color = Color(0.93, 0.89, 0.78)
@export var dark: Color = Color(0.24, 0.2, 0.18)

## -1 or 1: the side it travels or faces.
var facing: int = 1
## Where it was fired from and at; set by GuardianSpawner before it enters the tree.
var context: SpawnContext = SpawnContext.new()

## Scaled seconds since it was fired.
var _t: float = 0.0
var _expired: bool = false

@onready var _hitbox: Hitbox = $Hitbox


func _ready() -> void:
	CanvasPass.join_layer(self, CanvasPass.CREATURES)
	_hitbox.monitoring = false
	_fit_shape()
	_place_hit(0.0)

func _physics_process(delta: float) -> void:
	_t += delta
	_advance(delta)
	_place_hit(_t)
	var on := is_live(_t)
	if _hitbox.monitoring != on:
		_hitbox.monitoring = on
	queue_redraw()
	if not _expired and _t >= lifetime():
		_expired = true
		expired.emit()

## Its Hitbox, for the spawner to set the move's damage and knockback.
func hitbox() -> Hitbox:
	return $Hitbox as Hitbox

func is_live(t: float) -> bool:
	return t >= warn and t < warn + live

## Scaled seconds from firing to expiry.
func lifetime() -> float:
	return warn + live + fade

## Switches the hitbox off on the next frame and frees the spawn; safe inside a physics flush.
func kill() -> void:
	_expired = true
	var box := $Hitbox as Hitbox
	box.set_deferred(&"monitoring", false)
	queue_free()

## The hit shape's transforms relative to the root, one per SAMPLE of the live time (combat_reach_test).
func hit_transforms(ctx: SpawnContext) -> Array[Transform2D]:
	context = ctx
	_fit_shape()
	var shape := $Hitbox/CollisionShape2D as CollisionShape2D
	var xforms: Array[Transform2D] = []
	var t := warn
	while t < warn + live:
		xforms.append(Transform2D(0.0, _hit_offset(t)) * shape.transform)
		t += SAMPLE
	return xforms

## Whether it travels to or lands on Ivo, so it must touch him wherever its move is thrown from (combat_reach_test).
func aimed() -> bool:
	return false

## Whether it comes from above or below, so its warning must last MIN_WARN (combat_reach_test).
func from_above() -> bool:
	return false

## The box its art covers over its whole life, relative to the root.
func drawn_rect(ctx: SpawnContext) -> Rect2:
	context = ctx
	return _drawn_rect()

## Where the hit shape's centre is at `t`, relative to the root; the kind's motion.
func _hit_offset(_t_at: float) -> Vector2:
	return Vector2.ZERO

## Kind-specific state each physics frame (a probe, a landing).
func _advance(_delta: float) -> void:
	pass

func _drawn_rect() -> Rect2:
	return Rect2()

## The hit rectangle's size, px, standing on the root; zero keeps the scene's shape.
func _hit_size() -> Vector2:
	return Vector2.ZERO

func _fit_shape() -> void:
	var size := _hit_size()
	if size == Vector2.ZERO:
		return
	var node := $Hitbox/CollisionShape2D as CollisionShape2D
	var rect := RectangleShape2D.new()
	rect.size = size
	node.shape = rect
	node.position = Vector2(0.0, -size.y * 0.5)

func _place_hit(t: float) -> void:
	_hitbox.position = _hit_offset(t)

## A floor warning across `from_x..to_x`: a light line with a dark rim over the grass, and light sparks rising to it
## as `progress` (0..1) grows, alternating on the scaled clock.
func draw_floor_warning(from_x: float, to_x: float, progress: float) -> void:
	var top := -WARN_RISE
	draw_rect(snapped_rect(Rect2(from_x - 2.0, top - 2.0, to_x - from_x + 4.0, 6.0)), dark)
	draw_rect(snapped_rect(Rect2(from_x, top, to_x - from_x, 2.0)), light)
	var even := int(_t * 12.0) % 2 == 0
	var rise := WARN_RISE * clampf(progress, 0.0, 1.0)
	var x := from_x
	var k := 0
	while x <= to_x:
		var tall := rise if (k % 2 == 0) == even else rise * 0.6
		draw_rect(snapped_rect(Rect2(x - 2.0, -tall, 4.0, tall)), dark)
		draw_rect(snapped_rect(Rect2(x - 1.0, -tall, 2.0, tall)), light)
		x += 6.0
		k += 1

## `rect` snapped outward to the 2 px art grid.
static func snapped_rect(rect: Rect2) -> Rect2:
	var low := (rect.position / 2.0).floor() * 2.0
	var high := (rect.end / 2.0).ceil() * 2.0
	return Rect2(low, high - low)
