class_name HitGateTest extends GdUnitTestSuite

## One life note per guardian move or string, through its recovery ("One note per string (Recommended)", user,
## 2026-11-18; bugs/a-single-guardian-move-can-cost-two-notes-through-its-contact-box).

var _gate: HitGate
var _ivo: Object


func before_test() -> void:
	_gate = HitGate.new()
	_ivo = auto_free(Node.new())

func test_a_string_hurts_a_target_once_its_first_move_included() -> void:
	_gate.begin_string()
	assert_bool(_gate.allows(_ivo)).is_true()
	_gate.record(_ivo)
	assert_bool(_gate.allows(_ivo)).override_failure_message("the same move hurt again").is_false()
	var other: Object = auto_free(Node.new())
	assert_bool(_gate.allows(other)).is_true()

func test_between_strings_every_hit_counts() -> void:
	_gate.record(_ivo)
	assert_bool(_gate.allows(_ivo)).override_failure_message("contact between moves was refused").is_true()

func test_the_end_of_a_string_forgets() -> void:
	_gate.begin_string()
	_gate.record(_ivo)
	_gate.end_string()
	assert_bool(_gate.allows(_ivo)).is_true()
	_gate.begin_string()
	assert_bool(_gate.allows(_ivo)).is_true()

func test_a_hitbox_with_the_gate_refuses_the_hit() -> void:
	var box: Hitbox = auto_free(Hitbox.new())
	var contact: Hitbox = auto_free(Hitbox.new())
	var hurtbox: Hurtbox = auto_free(Hurtbox.new())
	var hits: Array[int] = []
	hurtbox.hit_received.connect(func(damage: int, _knockback: Vector2, _source: Node2D) -> void: hits.append(damage))
	# No i-frames, so only the gate can refuse a second hit.
	hurtbox.invulnerability_time = 0.0
	add_child(hurtbox)
	box.gate = _gate
	contact.gate = _gate
	_gate.begin_string()
	box._hit(hurtbox)
	assert_int(hits.size()).is_equal(1)
	# The move's contact box touches him in its recovery.
	contact._hit(hurtbox)
	assert_int(hits.size()).override_failure_message("the move's contact hurt again").is_equal(1)
	_gate.end_string()
	contact._hit(hurtbox)
	assert_int(hits.size()).override_failure_message("contact after the move was refused").is_equal(2)
