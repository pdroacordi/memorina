class_name TeacherBalloonTest extends GdUnitTestSuite

## The HUD balloon of a teacher's phrase: device glyphs, lit glyphs, a shake that returns home (systems/teaching-creatures).

const BALLOON := preload("res://scenes/ui/teacher_balloon/teacher_balloon.tscn")

var _balloon: TeacherBalloon
var _anchor: Node2D
var _glyph_set: Enums.GlyphSet


func before_test() -> void:
	_glyph_set = InputDevice.glyph_set
	_balloon = auto_free(BALLOON.instantiate()) as TeacherBalloon
	add_child(_balloon)
	_anchor = auto_free(Node2D.new()) as Node2D
	add_child(_anchor)
	_anchor.position = Vector2(200, 150)

func after_test() -> void:
	InputDevice.glyph_set = _glyph_set

func _phrase() -> Array[Enums.Note]:
	return [Enums.Note.LEFT, Enums.Note.RIGHT, Enums.Note.LEFT]

func _glyph(index: int) -> TextureRect:
	return _balloon.get_node("Box/Glyph%d" % index) as TextureRect

func _texture(glyph_set: Enums.GlyphSet, note: Enums.Note, lit: bool) -> Texture2D:
	return _balloon.glyphs.texture(note, glyph_set, lit)

func test_it_opens_with_three_hidden_glyphs_of_the_device_set() -> void:
	_balloon.show_for(_anchor, _phrase())
	assert_bool(_balloon.visible).is_true()
	assert_object(_balloon.speaker()).is_same(_anchor)
	for i: int in 3:
		assert_bool(_glyph(i).visible).is_false()
	_balloon.reveal(1)
	assert_bool(_glyph(1).visible).is_true()
	assert_object(_glyph(1).texture).is_same(_texture(InputDevice.glyph_set, Enums.Note.RIGHT, false))

func test_light_reveals_all_and_uses_the_selected_glyphs() -> void:
	_balloon.show_for(_anchor, _phrase())
	_balloon.light(2)
	var glyphs := InputDevice.glyph_set
	assert_object(_glyph(0).texture).is_same(_texture(glyphs, Enums.Note.LEFT, true))
	assert_object(_glyph(1).texture).is_same(_texture(glyphs, Enums.Note.RIGHT, true))
	assert_object(_glyph(2).texture).is_same(_texture(glyphs, Enums.Note.LEFT, false))
	assert_bool(_glyph(2).visible).is_true()

func test_lit_as_sung_lights_each_revealed_glyph() -> void:
	_balloon.show_for(_anchor, _phrase(), true)
	_balloon.reveal(0)
	assert_object(_glyph(0).texture).is_same(_texture(InputDevice.glyph_set, Enums.Note.LEFT, true))

func test_a_device_change_retextures() -> void:
	InputDevice.glyph_set = Enums.GlyphSet.KEYBOARD_ARROWS
	_balloon.show_for(_anchor, _phrase())
	_balloon.reveal_all()
	InputDevice.glyph_set = Enums.GlyphSet.XBOX
	InputDevice.device_changed.emit(Enums.GlyphSet.XBOX)
	assert_object(_glyph(0).texture).is_same(_texture(Enums.GlyphSet.XBOX, Enums.Note.LEFT, false))

func test_a_shake_returns_home() -> void:
	_balloon.show_for(_anchor, _phrase())
	await get_tree().process_frame
	var home := (_balloon.get_node("Box") as Control).position
	_balloon.shake()
	await await_millis(450)
	await get_tree().process_frame
	assert_vector((_balloon.get_node("Box") as Control).position).is_equal(home)

func test_closing_kills_the_shake() -> void:
	_balloon.show_for(_anchor, _phrase())
	_balloon.shake()
	_balloon.close()
	assert_bool(_balloon.visible).is_false()
	assert_object(_balloon.speaker()).is_null()

func test_close_lingers() -> void:
	_balloon.show_for(_anchor, _phrase())
	_balloon.close(0.2)
	assert_bool(_balloon.visible).is_true()
	await await_millis(350)
	assert_bool(_balloon.visible).is_false()

func test_it_hides_when_the_anchor_goes() -> void:
	_balloon.show_for(_anchor, _phrase())
	_anchor.hide()
	await get_tree().process_frame
	await get_tree().process_frame
	assert_bool(_balloon.visible).is_false()

func test_find_returns_it() -> void:
	assert_object(TeacherBalloon.find(get_tree())).is_same(_balloon)

## A lit glyph reads at true scale: unlit glyphs are faded, lit ones at full strength.
func test_unlit_glyphs_are_faded() -> void:
	_balloon.show_for(_anchor, _phrase())
	_balloon.light(1)
	assert_float(_glyph(0).modulate.a).is_equal(1.0)
	assert_float(_glyph(1).modulate.a).is_less(0.6)
	_balloon.light(3)
	assert_float(_glyph(1).modulate.a).is_equal(1.0)

## Near a screen edge the box stays fully on screen.
func test_the_box_stays_on_screen() -> void:
	var screen := _balloon.get_viewport_rect()
	for at: Vector2 in [Vector2(-40.0, 150.0), Vector2(screen.size.x + 40.0, 150.0), Vector2(200.0, 5.0)]:
		_anchor.position = at
		_balloon.show_for(_anchor, _phrase())
		await get_tree().process_frame
		var box := _balloon.box_rect()
		assert_bool(screen.encloses(box)).override_failure_message("%s -> %s in %s" % [at, box, screen]).is_true()
