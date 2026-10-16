class_name LetterboxTest extends GdUnitTestSuite

## The bars slide in and out (or cut at 0 s), stop under a hold, and a lesson still brings them in and out through them.

const LETTERBOX := preload("res://scenes/ui/letterbox/letterbox.tscn")
const CINEMATIC := preload("res://scenes/ui/lesson_cinematic/lesson_cinematic.tscn")

var _layer: CanvasLayer
var _letterbox: Letterbox


func before_test() -> void:
	_layer = auto_free(CanvasLayer.new()) as CanvasLayer
	add_child(_layer)
	_letterbox = LETTERBOX.instantiate() as Letterbox
	_layer.add_child(_letterbox)

func test_a_cut_opens_and_closes_at_once() -> void:
	assert_bool(_letterbox.visible).is_false()
	_letterbox.open(0.0)
	assert_bool(_letterbox.visible).is_true()
	assert_float(_letterbox.shown()).is_equal(1.0)
	_letterbox.close(0.0)
	assert_float(_letterbox.shown()).is_equal(0.0)
	assert_bool(_letterbox.visible).is_false()

func test_a_slide_reaches_its_end_and_hides_when_closed() -> void:
	_letterbox.open(0.2)
	await await_millis(350)
	assert_float(_letterbox.shown()).is_equal(1.0)
	assert_bool(_letterbox.is_open()).is_true()
	_letterbox.close(0.2)
	await await_millis(350)
	assert_float(_letterbox.shown()).is_equal(0.0)
	assert_bool(_letterbox.visible).is_false()

## Scaled: a menu's hold stops the slide where it is (gotchas/gdunit-await-millis-never-resumes-while-the-tree-is-paused).
func test_a_hold_stops_the_slide() -> void:
	var freeze := WorldFreeze.new()
	add_child(freeze)
	_letterbox.open(0.6)
	await await_millis(150)
	freeze.hold()
	# An ALWAYS node's frame already under way when the hold lands still steps once.
	await get_tree().process_frame
	await get_tree().process_frame
	var held := _letterbox.shown()
	await get_tree().create_timer(0.4, true, false, true).timeout
	assert_float(_letterbox.shown()).is_equal(held)
	assert_float(held).is_less(1.0)
	freeze.release()
	remove_child(freeze)
	freeze.free()

## LessonCinematic lost its own bars to the Letterbox; a lesson still brings them in and takes them out.
func test_a_lesson_opens_and_closes_the_letterbox() -> void:
	var cinematic := CINEMATIC.instantiate() as LessonCinematic
	cinematic.letterbox = _letterbox
	_layer.add_child(cinematic)
	var song := Song.new()
	cinematic.on_lesson_started(song, Enums.GlyphSet.KEYBOARD_ARROWS)
	assert_bool(_letterbox.is_open()).is_true()
	cinematic.on_lesson_finished()
	assert_bool(_letterbox.is_open()).is_false()
	cinematic.queue_free()
