class_name MentorMovesTest extends GdUnitTestSuite

## The mentor breathes and gestures while he talks (STORY-37): Holding and EmptyHand loop at his feet, every gesture
## starts on Holding's first frame (tilt and lower end on it), and Holding's first frame is the old still with the flute.

const LANTERN := preload("res://scenes/world/rooms/frost_edge/contents/lighthouse_top_contents.tscn")
const EMPTY_HAND := preload("res://assets/sprites/world/story/mentor/empty_hand.png")
const FLUTE := preload("res://assets/sprites/world/story/mentor/memorina_in_hand.png")

var _mentor: FactStaging


func before_test() -> void:
	SaveSystem.begin("", true)
	var lantern := auto_free(LANTERN.instantiate()) as Node2D
	add_child(lantern)
	_mentor = lantern.get_node(^"Props/Mentor") as FactStaging

func after_test() -> void:
	SaveSystem.begin("", true)

func _strip(strip_name: String) -> StagedStrip:
	return _mentor.get_node(NodePath(strip_name)) as StagedStrip

func _frame(strip: StagedStrip, clip: StringName, index: int) -> Image:
	var image := strip.sprite_frames.get_frame_texture(clip, index).get_image().duplicate() as Image
	image.convert(Image.FORMAT_RGBA8)
	return image

func _clip(strip: StagedStrip) -> StringName:
	return strip.loop if strip.intro.is_empty() else strip.intro

## Holding as it was shown before STORY-37, in the strip's stored (west-facing) frame.
func _old_holding() -> Image:
	var shown := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	for part: Array in [[EMPTY_HAND, Vector2i(18, 6)], [FLUTE, Vector2i(91, 20)]]:
		var art := (part[0] as Texture2D).get_image().duplicate() as Image
		art.convert(Image.FORMAT_RGBA8)
		art.flip_x()
		shown.blend_rect(art, Rect2i(Vector2i.ZERO, art.get_size()), part[1])
	shown.flip_x()
	return shown

func _same(first: Image, second: Image) -> bool:
	for y: int in first.get_height():
		for x: int in first.get_width():
			var a := first.get_pixel(x, y)
			var b := second.get_pixel(x, y)
			if (a.a > 0.0 or b.a > 0.0) and not a.is_equal_approx(b):
				return false
	return true

func test_holding_and_empty_hand_are_loops_at_his_feet() -> void:
	for strip_name: String in ["Holding", "EmptyHand", "Tilting", "Lowering", "HoldingOut"]:
		var strip := _strip(strip_name)
		assert_object(strip).override_failure_message(strip_name).is_not_null()
		assert_vector(strip.position).is_equal(Vector2(720, 672))
		assert_vector(strip.offset).is_equal(Vector2(-61, -126))
		assert_bool(strip.flip_h).is_true()
	for strip_name: String in ["Holding", "EmptyHand"]:
		var strip := _strip(strip_name)
		assert_bool(strip.intro.is_empty()).is_true()
		assert_bool(strip.sprite_frames.get_animation_loop(strip.loop)).is_true()
	for strip_name: String in ["Tilting", "Lowering", "HoldingOut"]:
		var strip := _strip(strip_name)
		assert_bool(strip.loop.is_empty()).is_true()
		assert_bool(strip.sprite_frames.get_animation_loop(strip.intro)).is_false()

func test_holding_starts_on_the_old_still_and_every_gesture_meets_it() -> void:
	var holding := _strip("Holding")
	var rest := _frame(holding, holding.loop, 0)
	assert_bool(_same(rest, _old_holding())).override_failure_message("Holding frame 0 is not the old still").is_true()
	for strip_name: String in ["Tilting", "Lowering", "HoldingOut"]:
		var strip := _strip(strip_name)
		assert_bool(_same(_frame(strip, strip.intro, 0), rest)).override_failure_message(strip_name + " frame 0").is_true()
	for strip_name: String in ["Tilting", "Lowering"]:
		var strip := _strip(strip_name)
		var last := strip.sprite_frames.get_frame_count(strip.intro) - 1
		assert_bool(_same(_frame(strip, strip.intro, last), rest)).override_failure_message(strip_name + " last").is_true()

func test_empty_hand_starts_on_the_still_without_the_flute() -> void:
	var empty := _strip("EmptyHand")
	var shown := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	var art := EMPTY_HAND.get_image().duplicate() as Image
	art.convert(Image.FORMAT_RGBA8)
	art.flip_x()
	shown.blend_rect(art, Rect2i(Vector2i.ZERO, art.get_size()), Vector2i(18, 6))
	shown.flip_x()
	assert_bool(_same(_frame(empty, empty.loop, 0), shown)).is_true()

func test_the_three_lines_carry_their_gestures() -> void:
	var gestures := {}
	for line: DialogueLine in (load("res://resources/dialogue/story/mentor.tres") as DialogueSet).dialogues[0].lines:
		if line.gesture != &"":
			gestures[line.text_key] = line.gesture
	assert_dict(gestures).is_equal({
		"DLG_MENTOR_GIFT_05": &"mentor_tilt",
		"DLG_MENTOR_GIFT_09": &"mentor_lower",
		"DLG_MENTOR_GIFT_02": &"mentor_hold_out",
	})

## Only the hold-out keeps its last frame; the tilt and the lowered hand give Holding back.
func test_the_lantern_gestures_stand_in_their_strips() -> void:
	var beats := _mentor.get_parent().get_parent().get_node(^"Beats")
	var wired := {}
	for node: Node in beats.get_children():
		var gesture := node as LineGesture
		if gesture != null:
			wired[gesture.gesture] = [String(gesture.child), gesture.holds]
	assert_dict(wired).is_equal({
		&"mentor_tilt": ["Tilting", false],
		&"mentor_lower": ["Lowering", false],
		&"mentor_hold_out": ["HoldingOut", true],
	})

## No drawn frame redraws the figure: each step changes under a third of his opaque pixels
## (bugs/the-mentors-new-strips-redraw-the-figure-between-frame-0-and-frame-1).
func test_no_step_redraws_the_figure() -> void:
	var holding := _strip("Holding")
	var rest := _frame(holding, holding.loop, 0)
	var body := 0
	for y: int in 128:
		for x: int in 128:
			if rest.get_pixel(x, y).a > 0.0:
				body += 1
	for strip_name: String in ["Holding", "EmptyHand", "Tilting", "Lowering", "HoldingOut"]:
		var strip := _strip(strip_name)
		var clip := _clip(strip)
		for i: int in strip.sprite_frames.get_frame_count(clip) - 1:
			var changed := _changed(_frame(strip, clip, i), _frame(strip, clip, i + 1))
			assert_int(changed).override_failure_message("%s step %d changes %d of %d px" % [strip_name, i, changed, body]) \
			.is_less(body / 3)

func _changed(first: Image, second: Image) -> int:
	var count := 0
	for y: int in first.get_height():
		for x: int in first.get_width():
			var a := first.get_pixel(x, y)
			var b := second.get_pixel(x, y)
			if (a.a > 0.0 or b.a > 0.0) and not a.is_equal_approx(b):
				count += 1
	return count
