class_name GuardianSpawner
extends Node2D
## Fires a guardian move's spawned attacks during its strike, in world coordinates (`top_level`). Spawns inherit the
## guardian's pause and visibility and are freed with it; `clear()` frees every live one when the pressure ends.

## The string's gate, set by the guardian: a spawn's hit counts toward the string's one life note.
var gate: HitGate = null

## Shots armed for the strike under way, in firing order.
var _shots: Array[Shot] = []
## Scaled s since the strike began.
var _elapsed: float = 0.0
## Landing time, s into the strike, once the guardian touched down; negative before.
var _landed_at: float = -1.0
## Placements by spawn, worked out when its first instance fires.
var _placed: Dictionary[GuardianSpawn, Placed] = {}

@onready var _guardian: Guardian = get_parent() as Guardian


func _ready() -> void:
	top_level = true
	global_position = Vector2.ZERO

## Arms `attack`'s spawns for the strike that begins now; a strike already armed is replaced, its live spawns kept.
func begin(attack: GuardianAttack) -> void:
	_shots.clear()
	_placed.clear()
	_elapsed = 0.0
	_landed_at = -1.0
	for spawn: GuardianSpawn in attack.spawns:
		if spawn == null or spawn.scene == null:
			continue
		var instances := spawn.count * (2 if spawn.placement == GuardianSpawn.Placement.BOTH_SIDES else 1)
		for i: int in instances:
			var shot := Shot.new()
			shot.spawn = spawn
			shot.index = i
			var order := floori(i / 2.0) if spawn.placement == GuardianSpawn.Placement.BOTH_SIDES else i
			shot.delay = spawn.interval * order
			_shots.append(shot)

## Advances the armed shots by `delta` scaled s, firing each one due; `landed` is true on the frame the guardian
## touched down inside the strike.
func tick(delta: float, landed: bool) -> void:
	if _shots.is_empty():
		return
	if landed and _landed_at < 0.0:
		_landed_at = _elapsed
	var due: Array[Shot] = []
	for shot: Shot in _shots:
		var start := _landed_at if shot.spawn.on_landing else shot.spawn.at
		if start >= 0.0 and _elapsed >= start + shot.delay:
			due.append(shot)
	for shot: Shot in due:
		_shots.erase(shot)
		_fire(shot)
	_elapsed += delta

## Drops the armed shots and frees every live spawn.
func clear() -> void:
	_shots.clear()
	_placed.clear()
	for child: Node in get_children():
		var spawned := child as SpawnedAttack
		if spawned != null:
			spawned.kill()

## Shots still waiting to fire.
func pending() -> int:
	return _shots.size()

## Takes `spawned` in with a hit of `damage` and the knockback, under the string's gate; it is freed on expiry.
func adopt(spawned: SpawnedAttack, damage: int, knockback_strength: float, knockback_lift: float) -> void:
	var box := spawned.hitbox()
	box.damage = damage
	box.knockback_strength = knockback_strength
	box.knockback_lift = knockback_lift
	box.gate = gate
	spawned.expired.connect(spawned.queue_free)
	add_child(spawned)

func _fire(shot: Shot) -> void:
	var ctx := _guardian.spawn_context()
	var point := _point_for(shot, ctx)
	var spawned := shot.spawn.scene.instantiate() as SpawnedAttack
	assert(spawned != null, "%s: a GuardianSpawn scene's root must be a SpawnedAttack" % _guardian.name)
	spawned.position = point
	spawned.facing = SpawnPlacement.facing_at(point, ctx)
	spawned.context = ctx
	adopt(spawned, shot.spawn.damage, shot.spawn.knockback_strength, shot.spawn.knockback_lift)

## AT_IVO aims each shot where Ivo stands as it fires; every other placement is worked out once, at its first shot.
func _point_for(shot: Shot, ctx: SpawnContext) -> Vector2:
	if shot.spawn.placement == GuardianSpawn.Placement.AT_IVO:
		return SpawnPlacement.points(shot.spawn, ctx)[0]
	if not _placed.has(shot.spawn):
		var placed := Placed.new()
		placed.points = SpawnPlacement.points(shot.spawn, ctx)
		_placed[shot.spawn] = placed
	var points: Array[Vector2] = _placed[shot.spawn].points
	return points[mini(shot.index, points.size() - 1)]


class Shot:
	var spawn: GuardianSpawn
	## Which instance of the spawn's placement.
	var index: int = 0
	## Scaled s after the spawn's start.
	var delay: float = 0.0


class Placed:
	var points: Array[Vector2] = []
