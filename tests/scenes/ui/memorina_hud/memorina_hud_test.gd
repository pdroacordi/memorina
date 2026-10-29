class_name MemorinaHudTest extends GdUnitTestSuite

## While a teacher's echo is open Ivo's own sheet stays hidden (systems/teaching-creatures).

const HUD := preload("res://scenes/ui/memorina_hud/memorina_hud.tscn")

var _hud: MemorinaHud


func before_test() -> void:
	_hud = auto_free(HUD.instantiate()) as MemorinaHud
	add_child(_hud)

func test_a_draw_shows_the_sheet() -> void:
	_hud.on_drawn([], 1)
	assert_bool(_hud.visible).is_true()

func test_no_sheet_on_a_draw_while_echoing() -> void:
	_hud.on_echo_opened()
	_hud.on_drawn([], 1)
	assert_bool(_hud.visible).is_false()
	_hud.on_camera_focused(Vector2(320, 192))
	assert_bool(_hud.visible).is_false()

func test_the_sheet_returns_after_the_echo_closes() -> void:
	_hud.on_echo_opened()
	_hud.on_echo_closed()
	_hud.on_drawn([], 1)
	assert_bool(_hud.visible).is_true()

func test_an_echo_opening_on_a_drawn_instrument_hides_the_sheet() -> void:
	_hud.on_drawn([], 1)
	_hud.on_echo_opened()
	assert_bool(_hud.visible).is_false()
