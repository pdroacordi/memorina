class_name DialogueBoxTest extends GdUnitTestSuite

## The box types in real time, completes on the first press and advances on the next, waits for the question before
## its choices, keeps focus inside itself, takes focus back after a hold, and ignores a release with no press.

const BOX := preload("res://scenes/ui/dialogue_box/dialogue_box.tscn")
const ELDER := preload("res://resources/dialogue/speakers/elder.tres")
## 40 characters: one second at 40 chars/s.
const LINE_KEY := "DIALOGUE_TRIAL_FIRST_01"

var _box: DialogueBox
var _advanced: int = 0
var _chosen: Array[int] = []
var _locale: String


func before() -> void:
	_locale = TranslationServer.get_locale()
	TranslationServer.set_locale("en")

func after() -> void:
	TranslationServer.set_locale(_locale)

func before_test() -> void:
	_advanced = 0
	_chosen.clear()
	_box = auto_free(BOX.instantiate()) as DialogueBox
	# The suite runs ALWAYS; the box inherits PAUSABLE in the game.
	_box.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_box)
	_box.advanced.connect(func() -> void: _advanced += 1)
	_box.chosen.connect(func(index: int) -> void: _chosen.append(index))

func after_test() -> void:
	get_viewport().gui_release_focus()

func _accept(pressed: bool = true, released: bool = true) -> void:
	for down: bool in [true, false]:
		if (down and not pressed) or (not down and not released):
			continue
		var event := InputEventAction.new()
		event.action = &"ui_accept"
		event.pressed = down
		Input.parse_input_event(event)
		await await_idle_frame()

func _down() -> void:
	for down: bool in [true, false]:
		var event := InputEventAction.new()
		event.action = &"ui_down"
		event.pressed = down
		Input.parse_input_event(event)
		await await_idle_frame()

func _focused() -> Control:
	return get_viewport().gui_get_focus_owner()

func test_a_line_types_in_real_time() -> void:
	_box.show_line(ELDER, LINE_KEY)
	assert_bool(_box.visible).is_true()
	assert_bool(_box.is_typing()).is_true()
	assert_float(_box.text_label().visible_ratio).is_equal(0.0)
	await await_millis(400)
	var ratio := _box.text_label().visible_ratio
	assert_float(ratio).is_greater(0.0)
	assert_float(ratio).is_less(1.0)
	await await_millis(1000)
	assert_bool(_box.is_typing()).is_false()
	assert_float(_box.text_label().visible_ratio).is_equal(1.0)

func test_the_first_press_completes_and_the_next_advances() -> void:
	_box.show_line(ELDER, LINE_KEY)
	await await_idle_frame()
	assert_object(_focused()).is_same(_box.get_node("Art/Box/ContinueArea"))
	await _accept()
	assert_bool(_box.is_typing()).is_false()
	assert_float(_box.text_label().visible_ratio).is_equal(1.0)
	assert_int(_advanced).is_equal(0)
	await _accept()
	assert_int(_advanced).is_equal(1)

## An auto start with Z held: the release that follows has no press on the box, so it skips nothing.
func test_a_release_with_no_press_does_nothing() -> void:
	_box.show_line(ELDER, LINE_KEY)
	await await_millis(1200)
	await _accept(false, true)
	assert_int(_advanced).is_equal(0)

func test_choices_wait_for_the_question_then_take_focus() -> void:
	_box.show_line(ELDER, LINE_KEY)
	_box.show_choices(PackedStringArray(["DIALOGUE_TRIAL_CHOICE_HOLD", "DIALOGUE_TRIAL_CHOICE_LET_GO"]))
	assert_bool(_box.choice_button(0).visible).is_false()
	assert_bool(_box.is_choosing()).is_false()
	await _accept()
	assert_bool(_box.is_choosing()).is_true()
	assert_bool(_box.choice_button(0).visible).is_true()
	assert_bool(_box.choice_button(1).visible).is_true()
	assert_bool(_box.choice_button(2).visible).is_false()
	assert_object(_focused()).is_same(_box.choice_button(0))
	assert_int(_advanced).is_equal(0)
	await _down()
	assert_object(_focused()).is_same(_box.choice_button(1))
	# The last choice is its own neighbour below.
	await _down()
	assert_object(_focused()).is_same(_box.choice_button(1))
	await _accept()
	assert_array(_chosen).contains_exactly([1])
	assert_bool(_box.is_choosing()).is_false()

func test_choices_shown_after_typing_appear_at_once() -> void:
	_box.show_line(ELDER, LINE_KEY)
	await await_millis(1200)
	_box.show_choices(PackedStringArray(["DIALOGUE_TRIAL_CHOICE_HOLD", "DIALOGUE_TRIAL_CHOICE_LET_GO"]))
	assert_bool(_box.is_choosing()).is_true()
	assert_bool(_box.get_node("Art/Box/Next").visible).is_false()

## A hold stops the typing; releasing it gives focus back to the box, which the pause took.
func test_a_hold_stops_typing_and_the_box_takes_focus_back() -> void:
	var freeze := WorldFreeze.new()
	add_child(freeze)
	_box.show_line(ELDER, LINE_KEY)
	await await_millis(300)
	freeze.hold()
	get_viewport().gui_release_focus()
	var held := _box.text_label().visible_ratio
	await get_tree().create_timer(0.5, true, false, true).timeout
	assert_float(_box.text_label().visible_ratio).is_equal(held)
	freeze.release()
	await await_idle_frame()
	assert_object(_focused()).is_same(_box.get_node("Art/Box/ContinueArea"))
	remove_child(freeze)
	freeze.free()
	await await_millis(1200)
	assert_bool(_box.is_typing()).is_false()

func test_close_hides_and_lets_go_of_focus() -> void:
	_box.show_line(ELDER, LINE_KEY)
	await await_idle_frame()
	_box.close()
	assert_bool(_box.visible).is_false()
	assert_object(_focused()).is_null()

func test_the_plate_shows_a_name_and_hides_without_one() -> void:
	_box.show_line(ELDER, LINE_KEY)
	var plate := _box.get_node("Art/Box/Plate") as Control
	assert_bool(plate.visible).is_true()
	assert_str(_box.name_label().text).is_equal("Elder")
	var nameless := Speaker.new()
	_box.show_line(nameless, LINE_KEY)
	assert_bool(plate.visible).is_false()

## The text rect stays put whether or not a portrait is shown.
func test_the_text_never_moves_for_a_portrait() -> void:
	var text := _box.text_label()
	var before := text.get_global_rect()
	var painted := Speaker.new()
	painted.portrait = PlaceholderTexture2D.new()
	_box.show_line(painted, LINE_KEY)
	await await_idle_frame()
	assert_bool(_box.get_node("Art/Box/Portrait").texture != null).is_true()
	assert_vector(text.get_global_rect().position).is_equal(before.position)
	assert_vector(text.get_global_rect().size).is_equal(before.size)

## Top or bottom, every piece of the box, the plate included, stays on the 320x180 art; the plate sits on the inner edge.
func test_the_box_opens_at_either_side_and_stays_on_screen() -> void:
	_box.show_line(ELDER, LINE_KEY)
	var screen := Rect2(0, 0, 320, 180)
	var panel := _box.get_node("Art/Box/Panel") as Control
	var plate := _box.get_node("Art/Box/Plate") as Control
	for side: DialogueBoxSide.Side in [DialogueBoxSide.Side.TOP, DialogueBoxSide.Side.BOTTOM]:
		_box.place(side)
		await await_idle_frame()
		for piece: Node in _box.get_node("Art/Box").get_children():
			var control := piece as Control
			var rect := Rect2(control.position + _box.get_node("Art/Box").position, control.size)
			assert_bool(screen.encloses(rect)).override_failure_message(
					"side %d: %s at %s leaves the screen" % [side, control.name, rect]).is_true()
		var panel_y := panel.position.y + panel.size.y * 0.5
		var plate_y := plate.position.y + plate.size.y * 0.5
		if side == DialogueBoxSide.Side.TOP:
			assert_float(plate_y).is_greater(panel_y)
		else:
			assert_float(plate_y).is_less(panel_y)
	_box.place(DialogueBoxSide.Side.TOP)
	assert_float((_box.get_node("Art/Box") as Control).position.y + panel.position.y).is_equal(20.0)
