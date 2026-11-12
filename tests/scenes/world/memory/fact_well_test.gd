class_name FactWellTest extends GdUnitTestSuite

## FactWell gives its source the strength of the first level that holds: at once on ready, over a scaled tween on a
## save change, hidden at 0.

const F := preload("res://tests/resources/dialogue/dialogue_fixture.gd")

var _source: MemorySource
var _well: FactWell


func before_test() -> void:
	SaveSystem.begin("", true)

func after_test() -> void:
	SaveSystem.begin("", true)

func _level(when: Array[SaveFact], strength: float) -> FactLevel:
	var made := FactLevel.new()
	made.when = when
	made.strength = strength
	return made

## Restored 0 · seen `a` 0.5 · else -0.8.
func _levels() -> Array[FactLevel]:
	return [
		_level([F.fact(SaveFact.Kind.WORLD_RESTORED)], 0.0),
		_level([F.fact(SaveFact.Kind.SCENE_SEEN, &"a")], 0.5),
		_level([], -0.8),
	]

func _make(fade: float) -> void:
	_source = auto_free(MemorySource.new()) as MemorySource
	_source.shape = MemoryFieldMath.Shape.RECT
	_well = FactWell.new()
	_well.source = _source
	_well.levels = _levels()
	_well.fade_seconds = fade
	_source.add_child(_well)
	add_child(_source)

func test_pick_takes_the_first_level_that_holds() -> void:
	var levels := _levels()
	var data := PlayerData.new()
	assert_int(FactWell.pick(levels, data)).is_equal(2)
	assert_float(FactWell.strength_for(levels, data)).is_equal_approx(-0.8, 0.0001)
	data.scenes_seen.append(&"a")
	assert_int(FactWell.pick(levels, data)).is_equal(1)
	assert_float(FactWell.strength_for(levels, data)).is_equal_approx(0.5, 0.0001)
	data.world_restored = true
	assert_int(FactWell.pick(levels, data)).is_equal(0)
	assert_float(FactWell.strength_for(levels, data)).is_equal(0.0)

func test_no_level_holding_gives_nothing() -> void:
	var only: Array[FactLevel] = [_level([F.fact(SaveFact.Kind.SCENE_SEEN, &"a")], 0.5)]
	assert_int(FactWell.pick(only, PlayerData.new())).is_equal(-1)
	assert_float(FactWell.strength_for(only, PlayerData.new())).is_equal(0.0)

func test_ready_snaps_to_the_level() -> void:
	SaveSystem.player_data.scenes_seen.append(&"a")
	_make(1.0)
	assert_float(_source.strength).is_equal_approx(0.5, 0.0001)
	assert_bool(_source.visible).is_true()

func test_a_save_change_tweens_to_the_new_level() -> void:
	_make(0.2)
	assert_float(_source.strength).is_equal_approx(-0.8, 0.0001)
	SaveSystem.mark_scene_seen(&"a")
	await get_tree().process_frame
	await get_tree().process_frame
	assert_float(_source.strength).is_greater(-0.8).is_less(0.5)
	await get_tree().create_timer(0.35).timeout
	assert_float(_source.strength).is_equal_approx(0.5, 0.0001)

func test_a_zero_level_hides_the_source() -> void:
	_make(0.0)
	assert_bool(_source.visible).is_true()
	SaveSystem.player_data.world_restored = true
	SaveSystem.progress_changed.emit()
	assert_float(_source.strength).is_equal(0.0)
	assert_bool(_source.visible).is_false()
