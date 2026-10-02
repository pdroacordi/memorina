class_name LifeHudTest extends GdUnitTestSuite

## The life HUD draws one note per unit and forgets from the right. The first
## pool it hears is SHOWN (no fade in front of the player); later losses fade.
## A forgotten note is still: its sway stops on the frame it held.

const HUD := preload("res://scenes/ui/life_hud/life_hud.tscn")

var _hud: LifeHud

func before_test() -> void:
	_hud = auto_free(HUD.instantiate()) as LifeHud
	add_child(_hud)

func test_one_note_per_unit_of_life() -> void:
	_hud.show_health(3, 3)
	assert_int(_hud.notes().size()).is_equal(3)

func test_the_first_pool_is_shown_not_faded() -> void:
	_hud.show_health(1, 3)
	var notes := _hud.notes()
	assert_float(notes[0].memory()).is_equal(1.0)
	assert_float(notes[1].memory()).is_equal(0.0)
	assert_float(notes[2].memory()).is_equal(0.0)

func test_a_lost_unit_forgets_from_the_right_and_fades() -> void:
	_hud.show_health(3, 3)
	_hud.show_health(2, 3)
	var notes := _hud.notes()
	assert_bool(notes[0].is_remembered()).is_true()
	assert_bool(notes[1].is_remembered()).is_true()
	assert_bool(notes[2].is_remembered()).is_false()
	# Still holding its colour until the fade runs.
	assert_float(notes[2].memory()).is_equal(1.0)
	notes[2]._process(notes[2].fade_time)
	assert_float(notes[2].memory()).is_equal(0.0)

func test_a_forgotten_note_holds_its_frame() -> void:
	_hud.show_health(0, 3)
	var note := _hud.notes()[2]
	var sprite := note.get_node("Sprite2D") as Sprite2D
	var held := sprite.frame
	for i: int in 30:
		note._process(0.1)
	assert_int(sprite.frame).is_equal(held)

func test_a_rest_refills_the_row_one_note_after_another() -> void:
	_hud.show_health(1, 3)
	_hud.show_health(3, 3)
	var notes := _hud.notes()
	notes[1]._process(0.05)
	notes[2]._process(0.05)
	assert_float(notes[1].memory()).is_greater(0.0)
	assert_float(notes[2].memory()).is_equal(0.0)
	notes[2]._process(_hud.refill_step)
	assert_float(notes[2].memory()).is_greater(0.0)

func test_losing_a_note_cancels_its_pending_return() -> void:
	_hud.show_health(1, 3)
	_hud.show_health(3, 3)
	_hud.show_health(1, 3)
	var note := _hud.notes()[2]
	note._process(1.0)
	assert_bool(note.is_remembered()).is_false()
	assert_float(note.memory()).is_equal(0.0)

func test_a_rest_brings_the_colour_back() -> void:
	_hud.show_health(1, 3)
	_hud.show_health(3, 3)
	for note: LifeNote in _hud.notes():
		assert_bool(note.is_remembered()).is_true()
