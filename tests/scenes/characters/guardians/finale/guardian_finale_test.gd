class_name GuardianFinaleTest extends GdUnitTestSuite

## The mentor's finale on the real scene: a winter window, the revelation that shatters back into pressure and is kept,
## two-track dissonance that hurts from its second mixed note, and a chosen track that runs the final call
## (design 02 section 5; architecture/grd-06-final-battle).

const MENTOR := preload("res://scenes/characters/guardians/mentor_guardian/mentor_guardian.tscn")
const IVO := preload("res://scenes/characters/ivo/ivo.tscn")
const ROOT := preload("res://resources/songs/root.tres")
const FREEZE := preload("res://resources/songs/freeze.tres")
const BELL_JAR := preload("res://resources/songs/bell_jar.tres")

## Top of the test floor.
const FLOOR_Y := 30.0

var _mentor: Guardian
var _ivo: Player
var _finale: GuardianFinale


func before_test() -> void:
	SaveSystem.begin("", true)
	SaveSystem.set_item_owned(Enums.PlayerItem.MEMORINA, true)

func after_test() -> void:
	SaveSystem.begin("", true)

## Builds the arena after the save is set, since the Finale reads the revelation from it.
func _set_up() -> void:
	var holder := auto_free(Node2D.new()) as Node2D
	add_child(holder)
	var floor_body := StaticBody2D.new()
	floor_body.collision_layer = GroundCollision.COLLISION_LAYER | 2
	floor_body.position = Vector2(0, FLOOR_Y + 10.0)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(4000, 20)
	shape.shape = rect
	floor_body.add_child(shape)
	holder.add_child(floor_body)
	_mentor = MENTOR.instantiate() as Guardian
	_mentor.position = Vector2(300, FLOOR_Y)
	holder.add_child(_mentor)
	_ivo = IVO.instantiate() as Player
	_ivo.position = Vector2(0, FLOOR_Y - 30.0)
	holder.add_child(_ivo)
	_finale = _mentor.get_node(^"Finale") as GuardianFinale
	_mentor.call(&"_on_player_entered")

func _lucid() -> void:
	for i: int in 30:
		if _mentor.fight().register_hit():
			return

## A winter window answered, its relapse over, and the next lucidity opened.
func _past_winter() -> void:
	_lucid()
	_finale.open_call(_ivo)
	_mentor.fight().answer_succeeded()
	_mentor.fight().tick(10.0)
	_lucid()
	_finale.open_call(_ivo)

func test_the_mentor_is_not_one_of_the_four_and_starts_in_winter() -> void:
	_set_up()
	assert_bool(SaveSystem.is_guardian_met(Enums.Guardian.FROST)).is_false()
	_lucid()
	_finale.open_call(_ivo)
	assert_bool(_finale.counts_window()).is_true()

func test_the_revelation_shatters_into_pressure_and_is_kept() -> void:
	_set_up()
	_past_winter()
	assert_bool(_finale.counts_window()).is_false()
	for i: int in 3:
		_finale.mixed(_ivo)
	assert_int(_mentor.fight().phase()).is_equal(GuardianFight.Phase.PRESSURE)
	assert_bool(SaveSystem.is_finale_revealed()).is_true()
	assert_int(_mentor.fight().cycles()).is_equal(1)

func test_dissonance_hurts_from_the_second_mixed_note_and_a_pure_track_starts_the_final_call() -> void:
	SaveSystem.mark_finale_revealed()
	_set_up()
	_past_winter()
	assert_bool(_finale.counts_window()).is_true()
	var health := _ivo.get_node(^"Health") as Health
	var before := health.current_hp
	_finale.mixed(_ivo)
	assert_int(health.current_hp).is_equal(before)
	_finale.mixed(_ivo)
	assert_int(health.current_hp).is_equal(before - 1)
	assert_bool(_finale.answered(ROOT, _ivo)).is_true()
	assert_bool(_finale.answered(FREEZE, _ivo)).is_true()
	assert_bool(_finale.answered(BELL_JAR, _ivo)).is_false()
