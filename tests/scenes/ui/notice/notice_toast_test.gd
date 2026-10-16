class_name NoticeToastTest extends GdUnitTestSuite

## The notice slides in with its text and icon, leaves on its own and says so; a withdrawn notice hides at once
## (systems/notices).

const TOAST := preload("res://scenes/ui/notice/notice_toast.tscn")
const ICON := preload("res://assets/sprites/hud/items/item_icon_bread.png")

var _toast: NoticeToast
var _finished: int = 0


func before_test() -> void:
	_finished = 0
	_toast = auto_free(TOAST.instantiate()) as NoticeToast
	_toast.slide_in = 0.01
	# Longer than a headless frame (measured up to 0.14 s), so the shown check lands inside it.
	_toast.hold = 1.0
	_toast.slide_out = 0.01
	_toast.gap = 0.01
	_toast.finished.connect(func() -> void: _finished += 1)
	add_child(_toast)

func test_it_starts_hidden() -> void:
	assert_bool(_toast.is_showing()).is_false()

func test_an_item_shows_its_name_and_icon_then_leaves() -> void:
	_toast.show_notice("ITEM_BREAD", ICON)
	await get_tree().process_frame
	assert_bool(_toast.is_showing()).is_true()
	assert_str(_toast.shown_text()).is_equal(tr("ITEM_BREAD"))
	assert_bool(_toast.shows_icon()).is_true()
	await await_millis(1500)
	assert_bool(_toast.is_showing()).is_false()
	assert_int(_finished).is_equal(1)

func test_an_intent_shows_no_icon() -> void:
	_toast.show_notice("INTENT_BREAD", null)
	await get_tree().process_frame
	assert_str(_toast.shown_text()).is_equal(tr("INTENT_BREAD"))
	assert_bool(_toast.shows_icon()).is_false()

func test_it_says_it_is_leaving_before_it_finishes() -> void:
	var order: Array[String] = []
	_toast.leaving.connect(func() -> void: order.append("leaving"))
	_toast.finished.connect(func() -> void: order.append("finished"))
	_toast.show_notice("ITEM_BREAD", ICON)
	await await_millis(1500)
	assert_array(order).contains_exactly(["leaving", "finished"])

func test_a_withdrawn_notice_hides_at_once_without_finishing() -> void:
	_toast.show_notice("ITEM_BREAD", ICON)
	await get_tree().process_frame
	_toast.withdraw()
	assert_bool(_toast.is_showing()).is_false()
	await await_millis(1500)
	assert_int(_finished).is_equal(0)

## Pausable: a menu hold stops it where it is (systems/screens, "Real time under a hold").
func test_it_is_pausable() -> void:
	assert_int(_toast.process_mode).is_equal(Node.PROCESS_MODE_INHERIT)
