class_name Enemy
extends Character
## A corrupted creature's composition root: pushes its EnemyStats into its children, owns every Area2D
## each physics frame, and drives its motor from the AI (docs/knowledge/systems/creatures.md).

signal woken
## A hit turned away by its front guard: no damage, a white flash.
signal blocked

## Over-bright modulate: the shader multiplies the texel by it, so a blocked hit flashes the body white.
const BLOCK_FLASH := Color(4.0, 4.0, 4.0)

@export var save_id: String = ""
@export var stats: EnemyStats
## Fall speed cap, px/s.
@export var terminal_velocity: float = 500.0

var _woken: bool = false
var _was_on_wall: bool = false
## The current move already hit someone: its body stops hurting until the move ends, so one move costs one life
## (docs/knowledge/bugs/a-boar-charge-that-hits-ivo-by-a-ledge-dazes-inside-him-and-contact-takes-a-second-life.md).
var _move_landed: bool = false
## Each move's Hitbox by EnemyMove.hitbox.
var _move_hitboxes: Dictionary[StringName, Hitbox] = {}

@onready var _ai: EnemyAI = $AI
@onready var _edge: CorruptionEdge = $CorruptionEdge
@onready var _contact: Hitbox = $ContactHitbox
@onready var _sight: EnemySight = $EnemySight
@onready var _wake_trigger: PlayerProximityTrigger = $WakeTrigger
@onready var _locomotion: LocomotionComponent = get_node_or_null(^"Locomotion") as LocomotionComponent
@onready var _flight: FlightComponent = get_node_or_null(^"Flight") as FlightComponent
@onready var _guard: Hitbox = get_node_or_null(^"Guard") as Hitbox
@onready var _ledge_probe: RayCast2D = get_node_or_null(^"LedgeProbe") as RayCast2D


func _ready() -> void:
	super()
	if not save_id.is_empty() and SaveSystem.is_enemy_defeated(save_id):
		hide()
		queue_free()
		return
	assert(stats != null and stats.validate().is_empty(), "%s: bad EnemyStats %s" % [name, stats.validate() if stats else ["missing"]])
	_apply_stats()
	died.connect(_on_died)
	_wake_trigger.player_entered.connect(wake)
	_ai.move_telegraphed.connect(_on_move_telegraphed)
	_ai.move_started.connect(_on_move_started)
	_ai.move_finished.connect(_on_move_finished)
	if stats.hidden_until_woken:
		_edge.hide_now()
	_sync_areas()

## Ivo came near: it gathers out of the grey (if hidden) and starts acting once gathered.
func wake() -> void:
	if _woken or is_dead():
		return
	_woken = true
	_ai.wake()
	if stats.hidden_until_woken:
		_edge.appear()
	woken.emit()

func is_dormant() -> bool:
	return not _woken

## Hurtable, hurting and acting: not dead, and woken and gathered when hidden until woken.
func is_present() -> bool:
	if is_dead():
		return false
	if not stats.hidden_until_woken:
		return true
	return _woken and not _edge.is_appearing()

func is_telegraphing() -> bool:
	return _ai.is_telegraphing()

func is_attacking() -> bool:
	return _ai.is_active()

func is_recovering() -> bool:
	return _ai.is_recovering()

## An armoured move's hit window: hits neither knock back nor cancel.
func is_armoured() -> bool:
	return _ai.is_active() and _ai.current_move().armoured

## At home or asleep: a ceiling creature hangs there, a thread creature rests under its anchor.
func is_home() -> bool:
	return _ai.is_home()

func wants_to_move() -> bool:
	return not _ai.steer.is_zero_approx()

## A creature has no safe ground to return to: a hazard kills it.
func receive_hazard(_hazard: HazardZone) -> void:
	if is_dead():
		return
	_wound(health.current_hp)

func _process_motion(delta: float) -> void:
	var present := is_present()
	if present:
		_ai.ledge_ahead = _ledge_ahead()
		_ai.tick(delta)
	_sync_areas()
	if is_dead() or is_in_knockback():
		apply_knockback_decay(delta)
		if _flight != null:
			velocity.y = lerpf(velocity.y, 0.0, 1.0 - exp(-knockback_damping * delta))
	elif present:
		face_towards(_ai.facing_direction)
		_drive(delta, _ai.steer)
	else:
		_drive(delta, Vector2.ZERO)
	if _flight == null and not is_on_floor():
		velocity.y = minf(velocity.y + base_gravity() * delta, terminal_velocity)

func _after_move(_delta: float) -> void:
	if is_dead():
		if _edge.is_gone():
			queue_free()
		return
	var on_wall := is_on_wall()
	if on_wall and not _was_on_wall and is_present():
		_ai.handle_wall_contact()
	_was_on_wall = on_wall

func _on_hit_received(damage: int, knockback: Vector2, source: Node2D) -> void:
	if is_dead():
		return
	if stats.front_guard and source != null and HitGuard.blocks(facing, body_rect(), source.global_position):
		flash(BLOCK_FLASH, hurt_flash_time)
		blocked.emit()
		return
	# Woken before the knock, so a creature drawn asleep keeps the place it was struck at as home.
	wake()
	var armoured := is_armoured()
	_wound(damage)
	if not armoured:
		apply_knockback(knockback)
	_ai.on_hurt()

func _apply_stats() -> void:
	health.max_hp = stats.health
	health.current_hp = stats.health
	_contact.damage = stats.contact_damage
	_contact.knockback_strength = stats.contact_knockback
	_set_radius(_sight, stats.sight_radius)
	_set_radius(_wake_trigger, stats.wake_radius)
	if _locomotion != null:
		_locomotion.stats = stats.locomotion
	if _flight != null:
		_flight.stats = stats.locomotion
	_ai.stats = stats
	for move: EnemyMove in stats.moves:
		_move_hitboxes[move.hitbox] = get_node(NodePath(String(move.hitbox))) as Hitbox
	for hitbox: Hitbox in _move_hitboxes.values():
		hitbox.hit_landed.connect(_on_move_landed)
	_contact.hit_landed.connect(_on_contact_landed)

## Written every physics frame, never from a signal in the physics flush.
func _sync_areas() -> void:
	var present := is_present()
	if not _ai.is_busy():
		_move_landed = false
	hurtbox.monitorable = present
	_contact.monitoring = present and not _move_landed
	var live := _ai.current_move() if present and _ai.is_active() else null
	for hitbox_name: StringName in _move_hitboxes:
		_move_hitboxes[hitbox_name].monitoring = live != null and live.hitbox == hitbox_name
	if _guard != null:
		_guard.monitoring = present and not _ai.is_recovering() and not _move_landed

func _drive(delta: float, steer: Vector2) -> void:
	# Asleep, it is not carried: a hanging bat or a creature not yet gathered stays where it was placed.
	var wind := carry() if _woken else Vector2.ZERO
	if _flight != null:
		_flight.fly_update(delta, steer, wind)
	else:
		# A lunge passes an axis above 1: ground_update targets axis * move_speed.
		_locomotion.ground_update(delta, steer.x / stats.locomotion.move_speed, wind.x)

## No floor under the probe, moved to the side it faces; false in the air.
func _ledge_ahead() -> bool:
	if _ledge_probe == null or not is_on_floor():
		return false
	_ledge_probe.position.x = absf(_ledge_probe.position.x) * facing
	_ledge_probe.force_raycast_update()
	return not _ledge_probe.is_colliding()

## The circle is duplicated: a scene's two placements (the scorpion and its bait) must not share one.
func _set_radius(area: Area2D, radius: float) -> void:
	var shape_node := area.get_node(^"CollisionShape2D") as CollisionShape2D
	var circle := shape_node.shape.duplicate() as CircleShape2D
	circle.radius = radius
	shape_node.shape = circle

func _on_died() -> void:
	if not save_id.is_empty():
		SaveSystem.mark_enemy_defeated(save_id)
	_edge.vanish()

func _on_move_telegraphed(_move: EnemyMove) -> void:
	_edge.agitate(true)

func _on_move_started(move: EnemyMove) -> void:
	_edge.agitate(false)
	var hitbox := _move_hitboxes[move.hitbox]
	hitbox.damage = move.damage
	hitbox.knockback_strength = move.knockback_strength
	hitbox.knockback_lift = move.knockback_lift

## From the physics flush: only a flag, the areas follow in the next _sync_areas.
func _on_move_landed(_target: Hurtbox) -> void:
	_move_landed = true

## A touch while a move hits or recovers counts as that move's hit.
func _on_contact_landed(_target: Hurtbox) -> void:
	if _ai.is_active() or _ai.is_recovering():
		_move_landed = true

func _on_move_finished(_move: EnemyMove) -> void:
	_edge.agitate(false)
