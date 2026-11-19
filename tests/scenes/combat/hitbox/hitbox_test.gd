class_name HitboxTest extends GdUnitTestSuite

## A strikes_once Hitbox lands one hit per window on each hurtbox; contact damage keeps hitting.

var _hitbox: Hitbox
var _hurtbox: Hurtbox
var _hits: Array[int] = []


func before_test() -> void:
	_hitbox = auto_free(Hitbox.new())
	_hurtbox = auto_free(Hurtbox.new())
	add_child(_hitbox)
	add_child(_hurtbox)
	_hits.clear()
	_hurtbox.hit_received.connect(func(damage: int, _knockback: Vector2, _source: Node2D) -> void: _hits.append(damage))


func test_a_window_strikes_a_hurtbox_once() -> void:
	_hitbox.strikes_once = true
	_hitbox._on_area_entered(_hurtbox)
	_hitbox._on_area_entered(_hurtbox)
	assert_int(_hits.size()).is_equal(1)


func test_the_next_window_strikes_again() -> void:
	_hitbox.strikes_once = true
	_hitbox._on_area_entered(_hurtbox)
	_hitbox.monitoring = false
	_hitbox._physics_process(1.0 / 60.0)
	_hitbox.monitoring = true
	_hitbox._on_area_entered(_hurtbox)
	assert_int(_hits.size()).is_equal(2)


func test_contact_damage_strikes_on_every_entry() -> void:
	_hitbox._on_area_entered(_hurtbox)
	_hitbox._on_area_entered(_hurtbox)
	assert_int(_hits.size()).is_equal(2)


## A hit landing at the target's own x (an icicle aimed at Ivo) pushes him away from the guardian that threw it, on
## either side of it, never into its body (bugs/a-hit-at-the-lanterns-west-wall-knocks-ivo-into-the-mentor).
func test_an_aligned_hit_pushes_away_from_its_thrower() -> void:
	var pushes: Array[Vector2] = []
	_hurtbox.hit_received.connect(func(_damage: int, knockback: Vector2, _source: Node2D) -> void: pushes.append(knockback))
	_hitbox.knockback_strength = 400.0
	_hitbox.knockback_lift = 120.0
	var thrower := auto_free(Node2D.new()) as Node2D
	add_child(thrower)
	_hitbox.thrower = thrower
	_hitbox.global_position = Vector2(100.0, -20.0)
	_hurtbox.global_position = Vector2(100.0, 0.0)
	for side: float in [1.0, -1.0]:
		thrower.global_position = Vector2(100.0 + side * 60.0, 0.0)
		_hitbox._on_area_entered(_hurtbox)
		assert_float(signf(pushes[pushes.size() - 1].x)).override_failure_message("thrower on %+.0f" % side).is_equal(-side)
	# Without a thrower the push keeps the box's own side.
	_hitbox.thrower = null
	_hurtbox.global_position = Vector2(102.0, 0.0)
	_hitbox._on_area_entered(_hurtbox)
	assert_float(signf(pushes[pushes.size() - 1].x)).is_equal(1.0)
