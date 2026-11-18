class_name HitGateTest extends GdUnitTestSuite

## One life note per guardian string ("One note per string (Recommended)", user, 2026-11-18).

var _gate: HitGate
var _ivo: Object


func before_test() -> void:
	_gate = HitGate.new()
	_ivo = auto_free(Node.new())

func test_the_first_link_is_never_refused() -> void:
	_gate.begin_string()
	_gate.record(_ivo)
	assert_bool(_gate.allows(_ivo)).is_true()

func test_a_later_link_is_refused_on_a_target_the_string_hurt() -> void:
	_gate.begin_string()
	_gate.record(_ivo)
	_gate.link = 1
	assert_bool(_gate.allows(_ivo)).is_false()
	var other: Object = auto_free(Node.new())
	assert_bool(_gate.allows(other)).is_true()

func test_a_new_string_forgets() -> void:
	_gate.begin_string()
	_gate.record(_ivo)
	_gate.link = 1
	_gate.begin_string()
	assert_bool(_gate.allows(_ivo)).is_true()

func test_a_hitbox_with_the_gate_refuses_the_hit() -> void:
	var box: Hitbox = auto_free(Hitbox.new())
	var hurtbox: Hurtbox = auto_free(Hurtbox.new())
	var hits: Array[int] = []
	hurtbox.hit_received.connect(func(damage: int, _knockback: Vector2, _source: Node2D) -> void: hits.append(damage))
	add_child(hurtbox)
	box.gate = _gate
	_gate.begin_string()
	box._hit(hurtbox)
	assert_int(hits.size()).is_equal(1)
	_gate.link = 1
	box._hit(hurtbox)
	assert_int(hits.size()).override_failure_message("the second link hurt again").is_equal(1)
