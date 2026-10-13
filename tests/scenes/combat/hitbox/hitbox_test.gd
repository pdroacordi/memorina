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
