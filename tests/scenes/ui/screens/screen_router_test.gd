class_name ScreenRouterTest extends GdUnitTestSuite

## The whole decision table: which screen is open after each press, from every state.

const K := ScreenRouter.Kind
const P := ScreenRouter.Press


func _decide(open: ScreenRouter.Kind, press: ScreenRouter.Press, paused: bool = false, locked: bool = false) -> ScreenRouter.Kind:
	return ScreenRouter.decide(open, press, paused, locked)

func test_each_toggle_opens_its_screen_from_none() -> void:
	assert_int(_decide(K.NONE, P.PAUSE)).is_equal(K.PAUSE)
	assert_int(_decide(K.NONE, P.NOTEBOOK)).is_equal(K.NOTEBOOK)
	assert_int(_decide(K.NONE, P.MAP)).is_equal(K.MAP)

func test_back_opens_nothing() -> void:
	assert_int(_decide(K.NONE, P.BACK)).is_equal(K.NONE)

## A performance or lesson holds the tree: nothing opens over it.
func test_nothing_opens_over_a_paused_tree() -> void:
	for press: ScreenRouter.Press in [P.PAUSE, P.NOTEBOOK, P.MAP, P.BACK]:
		assert_int(_decide(K.NONE, press, true)).is_equal(K.NONE)

func test_nothing_opens_while_locked() -> void:
	for press: ScreenRouter.Press in [P.PAUSE, P.NOTEBOOK, P.MAP, P.BACK]:
		assert_int(_decide(K.NONE, press, false, true)).is_equal(K.NONE)

func test_an_open_screen_closes_on_its_own_toggle() -> void:
	assert_int(_decide(K.PAUSE, P.PAUSE)).is_equal(K.NONE)
	assert_int(_decide(K.NOTEBOOK, P.NOTEBOOK)).is_equal(K.NONE)
	assert_int(_decide(K.MAP, P.MAP)).is_equal(K.NONE)

func test_back_and_pause_close_any_screen() -> void:
	for open: ScreenRouter.Kind in [K.PAUSE, K.NOTEBOOK, K.MAP]:
		assert_int(_decide(open, P.BACK)).override_failure_message("back on %d" % open).is_equal(K.NONE)
		assert_int(_decide(open, P.PAUSE)).override_failure_message("pause on %d" % open).is_equal(K.NONE)

func test_other_toggles_are_ignored_while_a_screen_is_open() -> void:
	assert_int(_decide(K.PAUSE, P.NOTEBOOK)).is_equal(K.PAUSE)
	assert_int(_decide(K.PAUSE, P.MAP)).is_equal(K.PAUSE)
	assert_int(_decide(K.NOTEBOOK, P.MAP)).is_equal(K.NOTEBOOK)
	assert_int(_decide(K.MAP, P.NOTEBOOK)).is_equal(K.MAP)

## The open screen's own freeze is what pauses the tree, so closing ignores it.
func test_an_open_screen_closes_on_its_own_paused_tree() -> void:
	assert_int(_decide(K.PAUSE, P.PAUSE, true)).is_equal(K.NONE)
	assert_int(_decide(K.NOTEBOOK, P.BACK, true)).is_equal(K.NONE)
	assert_int(_decide(K.PAUSE, P.MAP, true)).is_equal(K.PAUSE)
