class_name EngravingViewTest extends GdUnitTestSuite

## The view draws a frame in the palette's ink, retranslates its caption, stops under a hold and hides whole.

const VIEW := preload("res://scenes/ui/engraving/engraving_view.tscn")
const BASE := preload("res://assets/sprites/story/bearers/frost/frame_1_base.png")
const FLAKES := preload("res://assets/sprites/story/bearers/frost/frame_1_flakes.png")
const WINTER := preload("res://resources/songs/palettes/winter_palette.tres")
const KEY := &"REGION_THRESHOLD"

var _view: EngravingView
var _locale: String


func before() -> void:
	_locale = TranslationServer.get_locale()

func after() -> void:
	TranslationServer.set_locale(_locale)

func before_test() -> void:
	TranslationServer.set_locale("en")
	_view = auto_free(VIEW.instantiate()) as EngravingView
	_view.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_view)

func _frame(seconds: float = 3.0) -> EngravingFrame:
	var base := EngravingLayer.new()
	base.texture = BASE
	var flakes := EngravingLayer.new()
	flakes.texture = FLAKES
	flakes.ink_only = true
	flakes.drift = Vector2(0.0, 3.0)
	var frame := EngravingFrame.new()
	frame.layers = [base, flakes]
	frame.captions = [KEY]
	frame.seconds = seconds
	frame.pan_to = Vector2(64.0, 32.0)
	frame.reveal_seconds = 0.2
	frame.dissolve_seconds = 0.2
	return frame

func test_it_starts_hidden() -> void:
	assert_bool(_view.visible).is_false()
	assert_bool(_view.is_settled()).is_true()

func test_the_ink_comes_from_the_palette() -> void:
	_view.show_frame(_frame(), WINTER.tint, false)
	assert_bool(_view.visible).is_true()
	assert_object(_view.tint()).is_equal(WINTER.tint)
	assert_int(_view.sprites().size()).is_equal(2)
	for sprite: Sprite2D in _view.sprites():
		var material := sprite.material as ShaderMaterial
		assert_object(material.get_shader_parameter(&"ink_colour")).is_equal(WINTER.tint)
	assert_bool((_view.sprites()[1].material as ShaderMaterial).get_shader_parameter(&"ink_only")).is_true()

func test_the_frame_reveals_then_settles() -> void:
	_view.show_frame(_frame(), WINTER.tint, false)
	assert_bool(_view.is_settled()).is_false()
	await await_millis(400)
	assert_bool(_view.is_settled()).is_true()

func test_the_caption_retranslates() -> void:
	_view.show_frame(_frame(), WINTER.tint, false)
	var english := _view.caption_label().text
	assert_str(english).is_equal(TranslationServer.translate(KEY))
	TranslationServer.set_locale("pt_BR")
	await get_tree().process_frame
	assert_str(_view.caption_label().text).is_equal(TranslationServer.translate(KEY))
	assert_str(_view.caption_label().text).is_not_equal(english)

func test_a_paused_tree_stops_it() -> void:
	var freeze := WorldFreeze.new()
	add_child(freeze)
	_view.show_frame(_frame(10.0), WINTER.tint, false)
	await await_millis(200)
	freeze.freeze()
	var held := _view.elapsed()
	# A timer that runs while paused: gdUnit's await_millis stops with the tree.
	await get_tree().create_timer(0.6, true, false, true).timeout
	assert_float(_view.elapsed()).is_equal(held)
	freeze.thaw()
	remove_child(freeze)
	freeze.free()
	await await_millis(200)
	assert_float(_view.elapsed()).is_greater(held)

func test_land_puts_the_frame_at_its_end() -> void:
	var frame := _frame(10.0)
	_view.show_frame(frame, WINTER.tint, false)
	_view.land()
	assert_bool(_view.is_settled()).is_true()
	assert_vector(_view.sprites()[0].position).is_equal(-frame.pan_to)

func test_clear_leaves_bare_paper() -> void:
	_view.show_frame(_frame(), WINTER.tint, false)
	_view.clear(0.1)
	await await_millis(300)
	assert_bool(_view.visible).is_true()
	assert_int(_view.sprites().size()).is_equal(0)
	assert_float(_view.caption_label().modulate.a).is_equal(0.0)

func test_hide_now_resets_it() -> void:
	_view.show_frame(_frame(), WINTER.tint, false)
	_view.hide_now()
	assert_bool(_view.visible).is_false()
	assert_int(_view.sprites().size()).is_equal(0)
	assert_str(_view.caption_label().text).is_empty()
	assert_bool(_view.is_settled()).is_true()

func test_a_dissolve_keeps_the_frame_under_until_the_new_one_is_whole() -> void:
	_view.show_frame(_frame(), WINTER.tint, false)
	_view.show_frame(_frame(), WINTER.tint, true)
	assert_bool(_view.is_settled()).is_false()
	await await_millis(400)
	assert_bool(_view.is_settled()).is_true()

## The paper is the art's paper grey in the forgotten print at the project's black lift (greyhush_print.gdshaderinc).
func test_the_paper_is_the_printed_paper_grey() -> void:
	var lift := float(ProjectSettings.get_setting("shader_globals/greyhush_black_lift")["value"])
	var lift_colour: Vector3 = ProjectSettings.get_setting("shader_globals/greyhush_black_lift_color")["value"]
	var grey := EngravingView.PAPER_GREY.r
	var flat := Vector3(grey, grey, grey)
	var expected := flat.lerp(lift_colour + flat * (Vector3.ONE - lift_colour), lift)
	assert_float(_view.paper.r).is_equal_approx(expected.x, 0.002)
	assert_float(_view.paper.g).is_equal_approx(expected.y, 0.002)
	assert_float(_view.paper.b).is_equal_approx(expected.z, 0.002)

## The caption sits in the bottom bar, so the view draws after the Letterbox and before the Fade; its paper leaves the
## bars uncovered (playtests/2026-11-13-story04-bearer-fragments: the bar hid every caption).
func test_the_caption_draws_over_the_bars_and_the_paper_between_them() -> void:
	var game := (load("res://scenes/world/game.tscn") as PackedScene).get_state()
	var order: Array[StringName] = []
	for node: int in game.get_node_count():
		if String(game.get_node_path(node, true)).trim_prefix("./") == "CanvasLayer":
			order.append(game.get_node_name(node))
	assert_int(order.find(&"EngravingView")).is_greater(order.find(&"Letterbox"))
	assert_int(order.find(&"EngravingView")).is_less(order.find(&"Fade"))
	var letterbox := auto_free((load("res://scenes/ui/letterbox/letterbox.tscn") as PackedScene).instantiate()) as Letterbox
	var paper := _view.get_node("Paper") as ColorRect
	assert_float(paper.position.y).is_equal(letterbox.bar_height)
	assert_float(paper.position.y + paper.size.y).is_equal(_view.size.y - letterbox.bar_height)
	var caption := _view.caption_label().get_global_rect()
	assert_float(caption.position.y).is_greater_equal(_view.size.y - letterbox.bar_height)
