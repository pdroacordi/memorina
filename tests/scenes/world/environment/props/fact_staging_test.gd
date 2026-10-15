class_name FactStagingTest extends GdUnitTestSuite

## FactStaging shows exactly one child, picked by the first stage that holds: instantly at ready, cross-faded on a save
## change (a new change snaps the running fade), a stand-in until the stage next changes, right again after a rebuild.

const F := preload("res://tests/resources/dialogue/dialogue_fixture.gd")

var _staging: FactStaging


func before_test() -> void:
	SaveSystem.begin("", true)
	SaveSystem.set_item_owned(Enums.PlayerItem.MEMORINA, false)
	# The bench a rewind returns to: a debug new game owns the Memorina.
	SaveSystem.commit()
	_staging = _make()

func after_test() -> void:
	SaveSystem.begin("", true)

## Held (MEMORINA) · Up (heard `errand`) · Asleep; a fourth child, Lowered, only for stand-ins.
func _make() -> FactStaging:
	var made := auto_free(FactStaging.new()) as FactStaging
	made.process_mode = Node.PROCESS_MODE_PAUSABLE
	made.stages = [
		_stage([F.fact(SaveFact.Kind.ITEM, &"", Enums.PlayerItem.MEMORINA)], &"Held", 0.4),
		_stage([F.fact(SaveFact.Kind.DIALOGUE_HEARD, &"errand")], &"Up", 0.4),
		_stage([], &"Asleep", 0.4),
	]
	for child: String in ["Asleep", "Up", "Held", "Lowered"]:
		var sprite := Sprite2D.new()
		sprite.name = child
		made.add_child(sprite)
	add_child(made)
	return made

func _stage(when: Array[SaveFact], show: StringName, fade: float) -> FactStage:
	var stage := FactStage.new()
	stage.when = when
	stage.show = show
	stage.fade_seconds = fade
	return stage

func _visible(staging: FactStaging) -> Array[String]:
	var names: Array[String] = []
	for child: Node in staging.get_children():
		if (child as CanvasItem).visible:
			names.append(String(child.name))
	return names

func test_pick_takes_the_first_stage_that_holds() -> void:
	var data := PlayerData.new()
	assert_int(FactStaging.pick(_staging.stages, data)).is_equal(2)
	data.dialogues_heard.append(&"errand")
	assert_int(FactStaging.pick(_staging.stages, data)).is_equal(1)
	data.owned_items[Enums.PlayerItem.MEMORINA] = true
	assert_int(FactStaging.pick(_staging.stages, data)).is_equal(0)
	var none: Array[FactStage] = [_stage([F.fact(SaveFact.Kind.ITEM, &"", Enums.PlayerItem.MEMORINA)], &"Held", 0.0)]
	assert_int(FactStaging.pick(none, PlayerData.new())).is_equal(-1)

func test_ready_shows_its_stage_at_once() -> void:
	assert_array(_visible(_staging)).is_equal(["Asleep"])
	assert_float((_staging.get_node("Asleep") as CanvasItem).modulate.a).is_equal(1.0)

func test_a_change_cross_fades_then_shows_only_the_new_child() -> void:
	SaveSystem.mark_dialogue_heard(&"errand")
	assert_array(_visible(_staging)).is_equal(["Asleep", "Up"])
	await await_millis(200)
	var up := (_staging.get_node("Up") as CanvasItem).modulate.a
	assert_float(up).is_greater(0.0)
	assert_float(up).is_less(1.0)
	await await_millis(400)
	assert_array(_visible(_staging)).is_equal(["Up"])
	assert_float((_staging.get_node("Up") as CanvasItem).modulate.a).is_equal(1.0)
	assert_float((_staging.get_node("Asleep") as CanvasItem).modulate.a).is_equal(1.0)

## A second change mid-fade snaps the first to its end and fades from it.
func test_a_change_mid_fade_snaps_the_running_fade() -> void:
	SaveSystem.mark_dialogue_heard(&"errand")
	await await_millis(100)
	SaveSystem.set_item_owned(Enums.PlayerItem.MEMORINA, true)
	assert_array(_visible(_staging)).is_equal(["Up", "Held"])
	assert_float((_staging.get_node("Up") as CanvasItem).modulate.a).is_equal(1.0)
	await await_millis(600)
	assert_array(_visible(_staging)).is_equal(["Held"])

func test_a_stand_in_holds_until_the_stage_changes() -> void:
	_staging.stand_in(&"Lowered")
	assert_array(_visible(_staging)).is_equal(["Lowered"])
	# A save change that keeps the same stage keeps the stand-in.
	SaveSystem.mark_notebook_read(&"x")
	SaveSystem.learn_song(Enums.Song.FREEZE)
	assert_array(_visible(_staging)).is_equal(["Lowered"])
	SaveSystem.mark_dialogue_heard(&"errand")
	await await_millis(600)
	assert_array(_visible(_staging)).is_equal(["Up"])

func test_release_returns_to_the_stage() -> void:
	_staging.stand_in(&"Lowered")
	_staging.release(&"Lowered")
	assert_array(_visible(_staging)).is_equal(["Asleep"])

## A beat releases only its own stand-in: a later beat's stays.
func test_a_release_of_another_stand_in_changes_nothing() -> void:
	_staging.stand_in(&"Lowered")
	_staging.stand_in(&"Up")
	_staging.release(&"Lowered")
	assert_array(_visible(_staging)).is_equal(["Up"])
	_staging.release(&"Up")
	assert_array(_visible(_staging)).is_equal(["Asleep"])

## A death rebuilds the world: a new staging reads the rewound save, with no stand-in.
func test_a_rebuild_shows_the_saved_stage() -> void:
	SaveSystem.mark_dialogue_heard(&"errand")
	_staging.stand_in(&"Lowered")
	SaveSystem.rewind()
	var rebuilt := _make()
	assert_array(_visible(rebuilt)).is_equal(["Asleep"])

## A hold stops the cross-fade where it is.
func test_a_hold_stops_the_fade() -> void:
	var freeze := WorldFreeze.new()
	add_child(freeze)
	SaveSystem.mark_dialogue_heard(&"errand")
	await await_millis(150)
	freeze.hold()
	var held := (_staging.get_node("Up") as CanvasItem).modulate.a
	await get_tree().create_timer(0.5, true, false, true).timeout
	assert_float((_staging.get_node("Up") as CanvasItem).modulate.a).is_equal(held)
	freeze.release()
	remove_child(freeze)
	freeze.free()

func test_an_empty_show_hides_every_child() -> void:
	var empty := auto_free(FactStaging.new()) as FactStaging
	empty.stages = [_stage([], &"", 0.0)]
	var sprite := Sprite2D.new()
	sprite.name = "Guitar"
	empty.add_child(sprite)
	add_child(empty)
	assert_array(_visible(empty)).is_empty()
