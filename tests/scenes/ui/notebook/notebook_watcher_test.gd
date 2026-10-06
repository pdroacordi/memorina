class_name NotebookWatcherTest extends GdUnitTestSuite

## The watcher seeds silently, announces only new unread entries, and drops one a rewind took back.

const CATALOG := preload("res://resources/ui/notebook/notebook_catalog.tres")
const IVO := preload("res://scenes/characters/ivo/ivo.tscn")

var _watcher: NotebookWatcher
var _announced: Array = []


func before_test() -> void:
	SaveSystem.begin("", true)
	_announced.clear()

func after_test() -> void:
	SaveSystem.begin("", true)

func _watch() -> void:
	_watcher = auto_free(NotebookWatcher.new()) as NotebookWatcher
	_watcher.catalog = CATALOG
	_watcher.announced.connect(func(ids: Array[StringName]) -> void: _announced.append(ids))
	add_child(_watcher)

func test_what_the_save_already_holds_is_never_announced() -> void:
	SaveSystem.learn_song(Enums.Song.FREEZE)
	_watch()
	_watcher._process(0.0)
	assert_array(_announced).is_empty()

func test_a_gain_is_announced_once() -> void:
	_watch()
	SaveSystem.learn_song(Enums.Song.GALE)
	_watcher._process(0.0)
	_watcher._process(0.0)
	assert_array(_announced).contains_exactly([[&"song_gale"]])
	assert_array(_watcher.recent).contains_exactly([&"song_gale"])

func test_gains_queued_together_are_announced_together() -> void:
	_watch()
	SaveSystem.unlock_skill(Enums.PlayerSkill.ROLL)
	SaveSystem.meet_guardian(Enums.Guardian.FROST)
	_watcher._process(0.0)
	assert_array(_announced).contains_exactly([[&"lore_roll", &"guardian_frost"]])

## A song lost to a death and learned again was already read: nothing new to tell.
func test_an_entry_already_read_is_not_announced() -> void:
	_watch()
	SaveSystem.mark_notebook_read(&"song_root")
	SaveSystem.learn_song(Enums.Song.ROOT)
	_watcher._process(0.0)
	assert_array(_announced).is_empty()

func test_an_entry_taken_back_before_its_turn_is_dropped() -> void:
	_watch()
	SaveSystem.set_item_owned(Enums.PlayerItem.SWORD, false)
	SaveSystem.set_item_owned(Enums.PlayerItem.SWORD, true)
	SaveSystem.set_item_owned(Enums.PlayerItem.SWORD, false)
	assert_array(_watcher.waiting()).is_empty()

func test_no_fight_without_a_subject() -> void:
	_watch()
	assert_bool(_watcher.is_holding()).is_false()

## "After the fight" (design 02 §4, "pós-combate"): the queue waits while a fight is on.
func test_the_queue_waits_while_a_fight_is_on() -> void:
	var watcher := auto_free(HeldWatcher.new()) as HeldWatcher
	watcher.catalog = CATALOG
	watcher.announced.connect(func(ids: Array[StringName]) -> void: _announced.append(ids))
	add_child(watcher)
	watcher.held = true
	SaveSystem.unlock_skill(Enums.PlayerSkill.DOUBLE_JUMP)
	watcher._process(0.0)
	assert_array(_announced).is_empty()
	watcher.held = false
	watcher._process(0.0)
	assert_array(_announced).contains_exactly([[&"lore_double_jump"]])


## A lesson starts unpaused (0.5 s of lead-in) and freezes later: outside any fight, the quill still waits for it to end
## (bugs/the-notebook-quill-shows-through-a-lesson).
func test_a_lesson_holds_the_queue_until_its_track_ends() -> void:
	var holder := auto_free(Node2D.new()) as Node2D
	add_child(holder)
	var floor_body := StaticBody2D.new()
	floor_body.collision_layer = 2
	floor_body.position = Vector2(0, 40)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(4000, 20)
	shape.shape = rect
	floor_body.add_child(shape)
	holder.add_child(floor_body)
	var ivo := IVO.instantiate() as Player
	ivo.position = Vector2(0, -60)
	holder.add_child(ivo)
	for i: int in 120:
		await get_tree().physics_frame
		if ivo.is_on_floor() and ivo.is_still():
			break
	_watch()
	_watcher.subject = ivo
	SaveSystem.set_item_owned(Enums.PlayerItem.MEMORINA, true)
	_watcher._process(0.0)
	_announced.clear()
	var song := (load("res://resources/songs/song_catalog.tres") as SongCatalog).get_song(Enums.Song.GALE)
	assert_bool(ivo.learn_song(song)).is_true()
	assert_bool(ivo.is_in_lesson()).is_true()
	assert_bool(_watcher.is_holding()).is_true()
	_watcher._process(0.0)
	assert_array(_announced).is_empty()
	(ivo.get_node("SongPerformance") as SongPerformance).finished.emit()
	assert_bool(ivo.is_in_lesson()).is_false()
	_watcher._process(0.0)
	assert_array(_announced).contains_exactly([[&"song_gale"]])

## An entry read while its hint waited (the book opened mid-queue) gets no hint.
func test_an_entry_read_while_waiting_is_not_announced() -> void:
	var watcher := auto_free(HeldWatcher.new()) as HeldWatcher
	watcher.catalog = CATALOG
	watcher.announced.connect(func(ids: Array[StringName]) -> void: _announced.append(ids))
	add_child(watcher)
	watcher.held = true
	SaveSystem.learn_song(Enums.Song.RAIN)
	SaveSystem.learn_song(Enums.Song.ROOT)
	SaveSystem.mark_notebook_read(&"song_rain")
	watcher.held = false
	watcher._process(0.0)
	assert_array(_announced).contains_exactly([[&"song_root"]])
	SaveSystem.learn_song(Enums.Song.SHADOW)
	SaveSystem.mark_notebook_read(&"song_shadow")
	watcher._process(0.0)
	assert_array(_announced).has_size(1)


class HeldWatcher extends NotebookWatcher:
	var held: bool = false

	func is_holding() -> bool:
		return held
