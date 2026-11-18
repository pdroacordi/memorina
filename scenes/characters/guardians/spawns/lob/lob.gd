class_name Lob
extends SpawnedAttack
## An ember or seed pod thrown from the guardian's hand in a ballistic arc onto its root, the spot its placement chose;
## it leaves a FloorPatch there. Harmless in flight: only the patch hurts, so its arc never crosses the gaps it leaves
## (bugs/a-bloom-seed-pods-flight-crosses-the-gap-it-leaves-ivo).

## Px of the arc's apex above the line from hand to landing.
@export var arc: float = 120.0
## Px above the guardian's feet it leaves the hand.
@export var hand: float = 48.0
## Px of the pod, the hit included.
@export var size: Vector2 = Vector2(10.0, 10.0)
## Left where it lands; null leaves nothing.
@export var patch: PackedScene

var _burst: bool = false
## Px wide its landing mark is drawn: its patch's.
var _rest: float = 0.0


func _ready() -> void:
	super()
	_rest = rest_width()


func aimed() -> bool:
	return true

## The pod never hurts; its patch does.
func is_live(_t_at: float) -> bool:
	return false

## It falls on its spot from above: the spot is marked through the warning.
func from_above() -> bool:
	return true

## Where it leaves the hand, relative to the root.
func launch() -> Vector2:
	return context.origin + Vector2(0.0, -hand) - position

## The width it leaves on the floor: its patch's, else its own.
func rest_width() -> float:
	if patch == null:
		return size.x
	var left := patch.instantiate() as FloorPatch
	var width := left.width if left != null else size.x
	if left != null:
		left.free()
	return width

func _hit_offset(t: float) -> Vector2:
	var u := clampf((t - warn) / maxf(live, 0.001), 0.0, 1.0)
	var point := launch().lerp(Vector2.ZERO, u)
	point.y -= 4.0 * arc * u * (1.0 - u)
	return point + Vector2(0.0, size.y * 0.5)

func _hit_size() -> Vector2:
	return size

func _advance(_delta: float) -> void:
	if _burst or _t < warn + live:
		return
	_burst = true
	var spawner := get_parent() as GuardianSpawner
	if patch == null or spawner == null:
		return
	var left := patch.instantiate() as SpawnedAttack
	left.position = position
	left.facing = facing
	left.context = context
	var box := hitbox()
	spawner.adopt(left, box.damage, box.knockback_strength, box.knockback_lift)

func _drawn_rect() -> Rect2:
	var start := launch()
	var top := minf(start.y, 0.0) - arc - size.y
	return snapped_rect(Rect2(minf(start.x, 0.0) - size.x, top, absf(start.x) + size.x * 2.0, maxf(start.y, 0.0) - top + 2.0))

func _draw() -> void:
	if _t >= warn + live:
		return
	# The spot it will land on, over the grass, through the warning and the flight.
	draw_floor_warning(-_rest * 0.5, _rest * 0.5, _t / maxf(warn + live, 0.001))
	var at := _hit_offset(_t) - Vector2(0.0, size.y * 0.5)
	draw_rect(snapped_rect(Rect2(at - size * 0.5 - Vector2(2.0, 2.0), size + Vector2(4.0, 4.0))), dark)
	draw_rect(snapped_rect(Rect2(at - size * 0.5 + Vector2(2.0, 2.0), size - Vector2(4.0, 4.0))), light)
