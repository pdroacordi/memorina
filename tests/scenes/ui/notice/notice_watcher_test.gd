class_name NoticeWatcherTest extends GdUnitTestSuite

## The watcher seeds silently, tells each item gained and each intent change one at a time from the save, and never
## while a talk or a cutscene runs (systems/notices).

const NOTEBOOK := preload("res://resources/ui/notebook/notebook_catalog.tres")
const INTENTS := preload("res://resources/story/intent_catalog.tres")
const IVO := preload("res://scenes/characters/ivo/ivo.tscn")
const TOAST := preload("res://scenes/ui/notice/notice_toast.tscn")

var _watcher: NoticeWatcher
## [text key, icon] per notice shown.
var _shown: Array = []
var _withdrawn: int = 0


func before_test() -> void:
	SaveSystem.begin("", true)
	_shown.clear()
	_withdrawn = 0

func after_test() -> void:
	SaveSystem.begin("", true)

func _watch(watcher: NoticeWatcher = null) -> NoticeWatcher:
	_watcher = auto_free(watcher if watcher != null else NoticeWatcher.new()) as NoticeWatcher
	_watcher.notebook = NOTEBOOK
	_watcher.intents = INTENTS
	_watcher.shown.connect(func(key: String, icon: Texture2D) -> void: _shown.append([key, icon]))
	_watcher.withdrawn.connect(func() -> void: _withdrawn += 1)
	add_child(_watcher)
	return _watcher

func _keys() -> Array[String]:
	var keys: Array[String] = []
	for notice: Array in _shown:
		keys.append(notice[0])
	return keys

func _ivo() -> Player:
	var ivo := IVO.instantiate() as Player
	add_child(ivo)
	auto_free(ivo)
	return ivo

## Her errand sets the first intent: a change, so it is told.
func test_the_daughters_errand_tells_the_round_loaf() -> void:
	_watch()
	SaveSystem.mark_dialogue_heard(&"daughter_errand")
	_watcher._process(0.0)
	assert_array(_keys()).contains_exactly(["INTENT_BREAD"])

func test_what_the_save_already_holds_tells_nothing() -> void:
	SaveSystem.set_item_owned(Enums.PlayerItem.SWORD, true)
	SaveSystem.mark_dialogue_heard(&"baker_errand")
	_watch()
	_watcher._process(0.0)
	assert_array(_shown).is_empty()

func test_an_item_gained_shows_its_name_and_icon() -> void:
	_watch()
	SaveSystem.set_item_owned(Enums.PlayerItem.BREAD, true)
	_watcher._process(0.0)
	assert_array(_keys()).contains_exactly(["ITEM_BREAD"])
	assert_object(_shown[0][1]).is_same(NOTEBOOK.item_entry(Enums.PlayerItem.BREAD).icon)

## The baker's errand: the loaf on her line, the new intent when the talk is heard; one notice at a time.
func test_the_errand_tells_the_bread_then_the_way_home() -> void:
	_watch()
	SaveSystem.set_item_owned(Enums.PlayerItem.BREAD, true)
	SaveSystem.mark_dialogue_heard(&"baker_errand")
	_watcher._process(0.0)
	_watcher._process(0.0)
	assert_array(_keys()).contains_exactly(["ITEM_BREAD"])
	_watcher.on_notice_finished()
	_watcher._process(0.0)
	assert_array(_keys()).contains_exactly(["ITEM_BREAD", "INTENT_HOME"])
	assert_object(_shown[1][1]).is_null()

func test_an_item_taken_back_before_its_turn_is_dropped() -> void:
	_watch()
	SaveSystem.set_item_owned(Enums.PlayerItem.SWORD, true)
	SaveSystem.set_item_owned(Enums.PlayerItem.SWORD, false)
	assert_array(_watcher.waiting()).is_empty()

## A rebuilt world's pause menu shows the intent it was built with.
func test_the_menus_intent_is_the_seeded_one_on_a_new_world() -> void:
	SaveSystem.mark_dialogue_heard(&"baker_errand")
	SaveSystem.mark_dialogue_heard(&"daughter_song")
	_watch()
	assert_str(_watcher.intent_key()).is_equal("INTENT_ELDER")

## The menu shows the intent last told, so it never names one before its notice (default, 2026-10-16): the elder's
## story waits for the daughter's scene to end, in the menu too.
func test_the_menus_intent_waits_for_its_notice() -> void:
	SaveSystem.mark_dialogue_heard(&"baker_errand")
	var ivo := _ivo()
	_watch()
	_watcher.subject = ivo
	assert_str(_watcher.intent_key()).is_equal("INTENT_HOME")
	ivo.begin_scene()
	SaveSystem.mark_dialogue_heard(&"daughter_song")
	_watcher._process(0.0)
	assert_str(_watcher.intent_key()).is_equal("INTENT_HOME")
	ivo.end_scene()
	_watcher._process(0.0)
	assert_array(_keys()).contains_exactly(["INTENT_ELDER"])
	assert_str(_watcher.intent_key()).is_equal("INTENT_ELDER")
	SaveSystem.mark_dialogue_heard(&"baker_errand")
	SaveSystem.mark_dialogue_heard(&"daughter_song")
	assert_str(_watcher.intent_key()).is_equal("INTENT_ELDER")

## A talk's granted item waits for the talk to end (systems/dialogue), as the notebook quill does.
func test_the_queue_waits_for_a_talk_to_end() -> void:
	var ivo := _ivo()
	_watch()
	_watcher.subject = ivo
	ivo.begin_talk(ivo.global_position + Vector2(20, 0))
	SaveSystem.set_item_owned(Enums.PlayerItem.BREAD, true)
	assert_bool(_watcher.is_holding()).is_true()
	_watcher._process(0.0)
	assert_array(_shown).is_empty()
	ivo.end_talk()
	_watcher._process(0.0)
	assert_array(_keys()).contains_exactly(["ITEM_BREAD"])

func test_the_queue_waits_for_a_cutscene_to_end() -> void:
	var ivo := _ivo()
	_watch()
	_watcher.subject = ivo
	ivo.begin_scene()
	SaveSystem.mark_dialogue_heard(&"baker_errand")
	SaveSystem.mark_dialogue_heard(&"daughter_song")
	_watcher._process(0.0)
	assert_array(_shown).is_empty()
	ivo.end_scene()
	_watcher._process(0.0)
	assert_array(_keys()).contains_exactly(["INTENT_ELDER"])

## A talk that starts while a notice shows hides it at once; the notice shows whole after the talk.
func test_a_talk_withdraws_the_notice_showing_and_it_shows_again_after() -> void:
	var ivo := _ivo()
	_watch()
	_watcher.subject = ivo
	SaveSystem.set_item_owned(Enums.PlayerItem.BREAD, true)
	_watcher._process(0.0)
	assert_bool(_watcher.is_showing()).is_true()
	ivo.begin_talk(ivo.global_position + Vector2(20, 0))
	_watcher._process(0.0)
	assert_int(_withdrawn).is_equal(1)
	assert_bool(_watcher.is_showing()).is_false()
	ivo.end_talk()
	_watcher._process(0.0)
	assert_array(_keys()).contains_exactly(["ITEM_BREAD", "ITEM_BREAD"])

## bugs/a-notice-withdrawn-after-it-left-is-told-twice: once the notice slides out it is told; a hold in the slide-out
## leaves it be, and nothing is shown again after the hold.
func test_a_hold_during_the_slide_out_does_not_tell_it_again() -> void:
	var toast := await _shown_with_toast()
	await _until(func() -> bool: return not _watcher.is_showing())
	assert_bool(toast.is_showing()).override_failure_message("the slide-out has begun on screen").is_true()
	await _hold_and_release()
	assert_int(_withdrawn).is_equal(0)
	assert_array(_keys()).contains_exactly(["ITEM_BREAD"])

## The same in the gap after it left the screen.
func test_a_hold_during_the_gap_does_not_tell_it_again() -> void:
	var toast := await _shown_with_toast()
	await _until(func() -> bool: return not toast.is_showing())
	await _hold_and_release()
	assert_int(_withdrawn).is_equal(0)
	assert_array(_keys()).contains_exactly(["ITEM_BREAD"])

func test_no_hold_without_a_subject() -> void:
	_watch()
	assert_bool(_watcher.is_holding()).is_false()

func test_a_held_queue_keeps_every_notice_for_later() -> void:
	var watcher := _watch(HeldWatcher.new()) as HeldWatcher
	watcher.held = true
	SaveSystem.set_item_owned(Enums.PlayerItem.SWORD, true)
	SaveSystem.set_item_owned(Enums.PlayerItem.MEMORINA, true)
	watcher._process(0.0)
	assert_array(_shown).is_empty()
	watcher.held = false
	watcher._process(0.0)
	watcher.on_notice_finished()
	watcher._process(0.0)
	assert_array(_keys()).contains_exactly(["ITEM_SWORD", "ITEM_MEMORINA"])


## A real toast wired to the watcher with long slide-out and gap windows, showing the bread.
func _shown_with_toast() -> NoticeToast:
	var ivo := _ivo()
	_watch()
	_watcher.subject = ivo
	var toast := auto_free(TOAST.instantiate()) as NoticeToast
	toast.slide_in = 0.01
	toast.hold = 0.01
	toast.slide_out = 1.5
	toast.gap = 1.5
	add_child(toast)
	_watcher.shown.connect(toast.show_notice)
	_watcher.withdrawn.connect(toast.withdraw)
	toast.leaving.connect(_watcher.on_notice_leaving)
	toast.finished.connect(_watcher.on_notice_finished)
	SaveSystem.set_item_owned(Enums.PlayerItem.BREAD, true)
	await _until(func() -> bool: return _watcher.is_showing())
	return toast

func _hold_and_release() -> void:
	var ivo := _watcher.subject
	ivo.begin_talk(ivo.global_position + Vector2(20, 0))
	for i: int in 3:
		await get_tree().process_frame
	ivo.end_talk()
	for i: int in 6:
		await get_tree().process_frame

func _until(done: Callable) -> void:
	for i: int in 300:
		if done.call():
			return
		await get_tree().process_frame
	assert_bool(false).override_failure_message("waited 300 frames").is_true()


class HeldWatcher extends NoticeWatcher:
	var held: bool = false

	func is_holding() -> bool:
		return held
