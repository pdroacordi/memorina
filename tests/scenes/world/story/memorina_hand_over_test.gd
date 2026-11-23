class_name MemorinaHandOverTest extends GdUnitTestSuite

## STORY-35: the keeper lowers the flute, Ivo takes it from the same world pixels, and the end rests on EmptyHand
## (architecture/story35-memorina-hand-over; systems/cutscenes, systems/story).

const LANTERN := preload("res://scenes/world/rooms/frost_edge/contents/lighthouse_top_contents.tscn")
const IVO := preload("res://scenes/characters/ivo/ivo.tscn")
const SCENE := preload("res://resources/cutscene/story/memorina_hand_over.tres")
const HOLD_OUT := preload("res://assets/sprites/world/story/mentor/hold_out.png")
const IDLE := preload("res://assets/sprites/characters/ivo/ivo_idle.png")
const REACH := preload("res://assets/sprites/characters/ivo/ivo_memorina_reach.png")
const TAKE := preload("res://assets/sprites/characters/ivo/ivo_memorina_take.png")
const HOLD := preload("res://assets/sprites/characters/ivo/ivo_memorina_hold.png")
const LOWER := preload("res://assets/sprites/characters/ivo/ivo_memorina_lower.png")
const IVO_PALETTE := "res://tools/art/sources/ivo/ivo_palette.png"
const FRAME := 128
## Contents px: the flute of `give.png` frame 3 (tools/art/prompts/story_mentor_give.md).
const FLUTE := Rect2i(749, 610, 14, 16)
## Contents px: the top-left of Ivo's 128 px frame from his feet (Sprite2D centred at (0, -32)).
const IVO_FRAME_ORIGIN := Vector2i(-64, -96)
## Ivo file column: right of it, his frames draw only his forward arm and what it holds.
const FRAME_HAND_COLUMN := 70
## Px: Ivo's origin above the floor (y 672) when he stands at a mark.
const STAND_LIFT := 30.0
## Scaled seconds: one physics tick, the most the resolver's clip change trails a stand-in.
const TICK := 1.0 / 60.0

var _lantern: Node2D
var _ivo: Player
var _director: CutsceneDirector


func before_test() -> void:
	SaveSystem.begin("", true)
	SaveSystem.set_item_owned(Enums.PlayerItem.MEMORINA, true)
	SaveSystem.mark_scene_seen(&"mentor_turns")

func after_test() -> void:
	SaveSystem.begin("", true)

func test_the_keeper_rests_on_the_empty_hand_once_the_hand_over_is_seen() -> void:
	_lantern = auto_free(LANTERN.instantiate()) as Node2D
	add_child(_lantern)
	var names: Array[String] = []
	for stage: FactStage in _staging().stages:
		names.append(String(stage.show))
	assert_array(names).is_equal(["", "StillAtLamp", "Stasis", "EmptyHand", "Holding", "AtLamp"])
	assert_str(_shown()).is_equal("Holding")
	SaveSystem.mark_scene_seen(&"memorina_hand_over")
	assert_str(_shown()).is_equal("EmptyHand")
	SaveSystem.mark_dialogue_heard(&"mentor_gift")
	assert_str(_shown()).is_equal("Stasis")
	var gift := _lantern.get_node(^"Beats/MentorGift") as CutsceneBeat
	assert_object(gift.cutscene).is_same(SCENE)
	assert_int(gift.hold).is_equal(DialogueBeat.Hold.STILL)
	assert_int(gift.pose).is_equal(DialogueBeat.Pose.NONE)
	var catalog := load("res://resources/cutscene/cutscene_catalog.tres") as CutsceneCatalog
	assert_object(catalog.find(&"memorina_hand_over")).is_same(SCENE)
	assert_bool(SCENE.skippable).is_true()

func test_the_strips_meet_at_every_cut() -> void:
	_lantern = auto_free(LANTERN.instantiate()) as Node2D
	var giving := _strip("Giving")
	var letting_go := _strip("LettingGo")
	var empty := _strip("EmptyHand")
	for strip: StagedStrip in [giving, letting_go]:
		assert_vector(strip.position).is_equal(Vector2(720, 672))
		assert_vector(strip.offset).is_equal(Vector2(-61, -126))
		assert_bool(strip.flip_h).is_true()
		assert_bool(strip.loop.is_empty()).is_true()
		assert_bool(strip.sprite_frames.get_animation_loop(strip.intro)).is_false()
	assert_str(_differs(_strip_frame(giving, 0), _region(HOLD_OUT, 3))).is_empty()
	assert_str(_differs(_strip_frame(letting_go, 0), _strip_frame(giving, _last(giving)))).is_empty()
	assert_str(_differs(_strip_frame(letting_go, _last(letting_go)), _strip_frame(empty, 0))).is_empty()
	assert_str(_differs(_region(REACH, 0), _region(IDLE, 0))).is_empty()
	assert_str(_differs(_region(TAKE, TAKE.get_width() / FRAME - 1), _region(LOWER, 1))).is_empty()
	assert_str(_differs(_region(HOLD, 0), _region(LOWER, 1))).is_empty()

## In contents px, the keeper's flute in `give` 3 is the flute Ivo's take 0 draws: where they differ, Ivo's hand covers
## it; Ivo draws no flute pixel elsewhere, and take 0 is reach 4 outside the flute.
func test_the_flute_changes_sprites_on_the_same_pixels() -> void:
	_lantern = auto_free(LANTERN.instantiate()) as Node2D
	var giving := _strip("Giving")
	var at := Vector2i(giving.position + giving.offset)
	var keeper := _world(_strip_frame(giving, _last(giving)), at)
	var flute_colours := _flute_colours(keeper)
	assert_int(flute_colours.size()).is_greater(0)
	var feet := Vector2i((_lantern.get_node(^"Marks/IvoNear") as Node2D).position)
	var take := _world(_region(TAKE, 0), feet + IVO_FRAME_ORIGIN)
	var reach := _world(_region(REACH, 4), feet + IVO_FRAME_ORIGIN)
	var skin := _palette()
	var flute := 0
	var problems := PackedStringArray()
	for pixel: Vector2i in keeper:
		if not flute_colours.has(keeper[pixel].to_rgba32()):
			continue
		flute += 1
		var drawn: Variant = take.get(pixel)
		if drawn == null:
			problems.append("keeper flute pixel %s: Ivo draws nothing" % pixel)
		elif not (drawn as Color).is_equal_approx(keeper[pixel]) and not skin.has((drawn as Color).to_rgba32()):
			problems.append("keeper flute pixel %s: Ivo draws %s" % [pixel, drawn])
	for pixel: Vector2i in take:
		var colour := take[pixel] as Color
		if flute_colours.has(colour.to_rgba32()) and not FLUTE.has_point(pixel):
			problems.append("Ivo's flute pixel %s lies outside the keeper's" % pixel)
		var before: Variant = reach.get(pixel)
		if (before == null or not (before as Color).is_equal_approx(colour)) and not FLUTE.has_point(pixel):
			problems.append("take 0 differs from reach 4 at %s" % pixel)
	for pixel: Vector2i in reach:
		if not take.has(pixel) and not FLUTE.has_point(pixel):
			problems.append("take 0 drops reach 4's pixel %s" % pixel)
	assert_int(flute).is_greater(100)
	assert_array(Array(problems)).is_empty()

## The keeper's flute shrinks to the Memorina over the take, never growing back and never losing more than half of
## itself in one frame (the STORY-35 playtest's frame 3 pop: 160 px to 12 in one frame).
func test_the_take_shrinks_the_flute_in_steps() -> void:
	var ivo := _palette()
	var areas: Array[int] = []
	for k: int in TAKE.get_width() / FRAME:
		var image := _region(TAKE, k)
		var area := 0
		for y: int in FRAME:
			for x: int in range(FRAME_HAND_COLUMN, FRAME):
				var colour := image.get_pixel(x, y)
				if colour.a > 0.0 and not ivo.has(colour.to_rgba32()):
					area += 1
		areas.append(area)
	for k: int in range(3, areas.size()):
		assert_int(areas[k]).override_failure_message("take %d: %s" % [k, areas]).is_less_equal(areas[k - 1])
		assert_int(areas[k - 1] - areas[k]).override_failure_message("take %d: %s" % [k, areas]).is_less_equal(areas[0] / 2)

## The flute leaves the keeper's hand after let_go frame 0 and nowhere else; the reach draws none.
func test_only_the_hand_off_frames_draw_the_keepers_flute() -> void:
	_lantern = auto_free(LANTERN.instantiate()) as Node2D
	var giving := _strip("Giving")
	var letting_go := _strip("LettingGo")
	var flute_colours := _flute_colours(_world(_strip_frame(giving, _last(giving)), Vector2i(giving.position + giving.offset)))
	for i: int in giving.sprite_frames.get_frame_count(giving.intro):
		assert_bool(_draws_any(_strip_frame(giving, i), flute_colours)).override_failure_message("give %d" % i).is_true()
	for i: int in range(1, letting_go.sprite_frames.get_frame_count(letting_go.intro)):
		assert_bool(_draws_any(_strip_frame(letting_go, i), flute_colours)) \
			.override_failure_message("let_go %d draws the flute" % i).is_false()
	for i: int in REACH.get_width() / FRAME:
		assert_bool(_draws_any(_region(REACH, i), flute_colours)).override_failure_message("reach %d" % i).is_false()

## The hand-off frame shows one flute however the stand-in and the clip change fall: let_go 0 outlasts no tick of take 0,
## the give and the reach end before the grip, and the let-go ends before EmptyHand takes its picture.
func test_the_timings_keep_one_flute_and_cover_the_voice() -> void:
	_lantern = auto_free(LANTERN.instantiate()) as Node2D
	var ivo := auto_free(IVO.instantiate()) as Player
	var clips := ivo.get_node("AnimationPlayer") as AnimationPlayer
	var take := clips.get_animation(PlayerAnimationResolver.MEMORINA_TAKE)
	var take_frame_0 := take.track_get_key_time(take.find_track(^"Sprite2D:frame", Animation.TYPE_VALUE), 1)
	var letting_go := _strip("LettingGo")
	var let_go_frame_0 := _frame_seconds(letting_go, 0)
	assert_float(let_go_frame_0).is_greater_equal(TICK)
	assert_float(take_frame_0 - let_go_frame_0).is_greater_equal(TICK)
	var reach_wait := _together_posing(DialogueBeat.Pose.RECEIVE)
	var grip := _together_posing(DialogueBeat.Pose.MEMORINA_HELD)
	assert_float(_length(reach_wait)).is_greater_equal(_intro_seconds(_strip("Giving")))
	assert_float(_length(reach_wait)).is_greater_equal(clips.get_animation(PlayerAnimationResolver.MEMORINA_REACH).length)
	var lets_go := _sequence_staging(grip, &"LettingGo")
	assert_float((lets_go.steps[1] as CutsceneWait).seconds).is_greater_equal(_intro_seconds(letting_go))
	assert_str(String((lets_go.steps[2] as CutsceneStage).child)).is_equal("EmptyHand")
	var hum: AudioStream = null
	for step: CutsceneStep in grip.steps:
		if step is CutsceneSound:
			hum = (step as CutsceneSound).stream
	assert_object(hum).is_not_null()
	var after := _length(grip) + _length(SCENE.steps.back())
	assert_float(after).is_greater_equal(hum.get_length())

## The end records SCENE_SEEN and EmptyHand is the picked stage in the same frame; every rendered frame shows one flute,
## or both on the same pixels at the hand-off; the pose holds while the talk does.
func test_the_scene_hands_the_flute_over_and_rests_on_the_empty_hand() -> void:
	await _mount()
	var at_end := {}
	_director.scene_ended.connect(func(_scene: Cutscene) -> void:
		at_end.merge({"seen": SaveSystem.is_scene_seen(&"memorina_hand_over"), "shown": _shown(),
				"picked": _staging().picked()}))
	var problems := PackedStringArray()
	var count := func() -> void:
		if not _director.is_playing():
			return
		var keeper := _keeper_flute()
		var ivo := _ivo_flute()
		if keeper == 0 and ivo == 0:
			problems.append("no flute at frame %d" % Engine.get_process_frames())
		elif keeper > 0 and ivo > 0 and not (keeper == 2 and ivo == 2):
			problems.append("two flutes at frame %d (%d, %d)" % [Engine.get_process_frames(), keeper, ivo])
	get_tree().process_frame.connect(count)
	assert_bool(_director.play(SCENE, _lantern.get_node(^"Beats/MentorGift"))).is_true()
	for i: int in 600:
		await get_tree().physics_frame
		if not _director.is_playing():
			break
	get_tree().process_frame.disconnect(count)
	assert_dict(at_end).is_equal({"seen": true, "shown": "EmptyHand", "picked": 3})
	assert_array(Array(problems)).is_empty()
	assert_int(_ivo.held_pose()).is_equal(DialogueBeat.Pose.MEMORINA_HELD)
	assert_bool(_ivo.is_memorina_drawn()).is_false()
	assert_bool(_bloom().is_blooming()).is_false()

## A skip lands EmptyHand and the held flute, hides the colour and never plays the voice; it records.
func test_a_skip_lands_the_empty_hand_and_the_held_flute() -> void:
	await _mount()
	_director.play(SCENE, _lantern.get_node(^"Beats/MentorGift"))
	await _frames(20)
	_director.request_skip()
	await _frames(2)
	assert_bool(_director.is_playing()).is_false()
	assert_bool(SaveSystem.is_scene_seen(&"memorina_hand_over")).is_true()
	assert_str(_shown()).is_equal("EmptyHand")
	assert_int(_ivo.held_pose()).is_equal(DialogueBeat.Pose.MEMORINA_HELD)
	assert_bool(_bloom().is_blooming()).is_false()
	for voice: Node in _director.find_children("*", "AudioStreamPlayer", true, false):
		assert_bool((voice as AudioStreamPlayer).playing).is_false()

## A drop records nothing and gives the held gesture back on its held last frame, not replayed; and no pose.
func test_a_drop_shows_the_held_out_flute_again() -> void:
	await _mount()
	_staging().stand_in(&"HoldingOut")
	_director.play(SCENE, _lantern.get_node(^"Beats/MentorGift"))
	for i: int in 200:
		await get_tree().physics_frame
		if _shown() == "Giving":
			break
	assert_str(_shown()).is_equal("Giving")
	await _frames(10)
	_director.interrupt()
	assert_bool(SaveSystem.is_scene_seen(&"memorina_hand_over")).is_false()
	assert_str(_shown()).is_equal("HoldingOut")
	var held := _strip("HoldingOut")
	assert_int(held.frame).is_equal(_last(held))
	assert_bool(held.is_playing()).is_false()
	await _frames(10)
	assert_int(held.frame).is_equal(_last(held))
	assert_int(_ivo.held_pose()).is_equal(DialogueBeat.Pose.NONE)

func _mount() -> void:
	_lantern = auto_free(LANTERN.instantiate()) as Node2D
	add_child(_lantern)
	_ivo = auto_free(IVO.instantiate()) as Player
	_ivo.position = (_lantern.get_node(^"Marks/IvoNear") as Node2D).position - Vector2(0, STAND_LIFT)
	add_child(_ivo)
	_director = auto_free(CutsceneDirector.new()) as CutsceneDirector
	_director.ivo = _ivo
	add_child(_director)
	_director.scene_began.connect(_ivo.begin_scene.unbind(1))
	_director.scene_ended.connect(_ivo.end_scene.unbind(1))
	_director.ivo_driven.connect(_ivo.drive)
	_director.ivo_posed.connect(_ivo.stage_pose)
	for i: int in 60:
		await get_tree().physics_frame
		if _ivo.is_on_floor():
			break
	# As the talk's CutsceneBeat holds him before its scene.
	_ivo.begin_talk((_lantern.get_node(^"Marks/MentorHome") as Node2D).position)
	_ivo.pause_talk(DialogueBeat.Hold.STILL, DialogueBeat.Pose.NONE)

func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame

func _staging() -> FactStaging:
	return _lantern.get_node(^"Props/Mentor") as FactStaging

func _strip(strip_name: String) -> StagedStrip:
	return _staging().get_node(NodePath(strip_name)) as StagedStrip

func _bloom() -> MemoryBloom:
	return _lantern.get_node(^"GiftBloom") as MemoryBloom

func _shown() -> String:
	var shown := _staging().shown()
	return String(shown.name) if shown != null else ""

## 0: the keeper draws no flute; 1: he draws it; 2: on the hand-off frame (give 3 or let_go 0).
func _keeper_flute() -> int:
	var shown := _shown()
	if shown == "Giving":
		return 2 if _strip("Giving").frame == _last(_strip("Giving")) else 1
	if shown == "LettingGo":
		return 2 if _strip("LettingGo").frame == 0 else 0
	return 1 if shown in ["Holding", "HoldingOut"] else 0

## 0: Ivo draws no flute; 1: he draws it; 2: on the hand-off frame (take 0).
func _ivo_flute() -> int:
	var sprite := _ivo.get_node(^"Sprite2D") as Sprite2D
	if sprite.texture == TAKE:
		return 2 if sprite.frame == 0 else 1
	return 1 if sprite.texture == HOLD or sprite.texture == LOWER else 0

func _last(strip: StagedStrip) -> int:
	return strip.sprite_frames.get_frame_count(strip.intro) - 1

func _frame_seconds(strip: StagedStrip, index: int) -> float:
	return strip.sprite_frames.get_frame_duration(strip.intro, index) / strip.sprite_frames.get_animation_speed(strip.intro)

func _intro_seconds(strip: StagedStrip) -> float:
	var seconds := 0.0
	for i: int in _last(strip):
		seconds += _frame_seconds(strip, i)
	return seconds

## Scaled seconds a step takes; instant steps take none.
func _length(step: CutsceneStep) -> float:
	if step is CutsceneWait:
		return (step as CutsceneWait).seconds
	if step is CutsceneSequence:
		var total := 0.0
		for child: CutsceneStep in (step as CutsceneSequence).steps:
			total += _length(child)
		return total
	if step is CutsceneTogether:
		var longest := 0.0
		for child: CutsceneStep in (step as CutsceneTogether).steps:
			longest = maxf(longest, _length(child))
		return longest
	var seconds: Variant = step.get(&"seconds")
	return float(seconds) if seconds != null else 0.0

func _together_posing(pose: int) -> CutsceneTogether:
	for step: CutsceneStep in SCENE.steps:
		if step is CutsceneTogether:
			for child: CutsceneStep in (step as CutsceneTogether).steps:
				if child is CutscenePose and (child as CutscenePose).pose == pose:
					return step as CutsceneTogether
	return null

func _sequence_staging(together: CutsceneTogether, first: StringName) -> CutsceneSequence:
	for step: CutsceneStep in together.steps:
		var sequence := step as CutsceneSequence
		if sequence != null and sequence.steps[0] is CutsceneStage and (sequence.steps[0] as CutsceneStage).child == first:
			return sequence
	return null

func _strip_frame(strip: StagedStrip, index: int) -> Image:
	var clip := strip.intro if not strip.intro.is_empty() else strip.loop
	var image := strip.sprite_frames.get_frame_texture(clip, index).get_image().duplicate() as Image
	image.convert(Image.FORMAT_RGBA8)
	return image

func _region(sheet: Texture2D, index: int) -> Image:
	var image := sheet.get_image().get_region(Rect2i(index * FRAME, 0, FRAME, FRAME))
	image.convert(Image.FORMAT_RGBA8)
	return image

## Opaque pixels of a west-facing frame drawn mirrored with its top-left at `at`, by contents px.
func _world(image: Image, at: Vector2i) -> Dictionary:
	var found := {}
	for y: int in image.get_height():
		for x: int in image.get_width():
			var colour := image.get_pixel(x, y)
			if colour.a > 0.0:
				found[at + Vector2i(image.get_width() - 1 - x, y)] = colour
	return found

## The colours the keeper's frame draws only inside the flute's rect.
func _flute_colours(keeper: Dictionary) -> Dictionary:
	var inside := {}
	var outside := {}
	for pixel: Vector2i in keeper:
		var rgba := (keeper[pixel] as Color).to_rgba32()
		if FLUTE.has_point(pixel):
			inside[rgba] = true
		else:
			outside[rgba] = true
	for rgba: int in outside:
		inside.erase(rgba)
	return inside

func _draws_any(image: Image, colours: Dictionary) -> bool:
	for y: int in image.get_height():
		for x: int in image.get_width():
			var colour := image.get_pixel(x, y)
			if colour.a > 0.0 and colours.has(colour.to_rgba32()):
				return true
	return false

func _palette() -> Dictionary:
	var strip := Image.load_from_file(ProjectSettings.globalize_path(IVO_PALETTE))
	strip.convert(Image.FORMAT_RGBA8)
	var found := {}
	for x: int in strip.get_width():
		found[strip.get_pixel(x, 0).to_rgba32()] = true
	return found

## Empty when the two images are the same size and every pixel matches (transparent pixels match any colour).
func _differs(first: Image, second: Image) -> String:
	if first.get_size() != second.get_size():
		return "sizes %s and %s" % [first.get_size(), second.get_size()]
	for y: int in first.get_height():
		for x: int in first.get_width():
			var a := first.get_pixel(x, y)
			var b := second.get_pixel(x, y)
			if (a.a > 0.0 or b.a > 0.0) and not a.is_equal_approx(b):
				return "pixel %s: %s vs %s" % [Vector2i(x, y), a, b]
	return ""
