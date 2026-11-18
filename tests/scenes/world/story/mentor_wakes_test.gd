class_name MentorWakesTest extends GdUnitTestSuite

## STORY-38: with the four restored the keeper waits still at the lamp and his guardian body is absent; the awakening's
## SCENE_SEEN hands the staging over to the body's FactPresence in one frame, and the body's ArenaTrigger, turned on with
## Ivo inside, begins the fight (architecture/story38-the-keeper-wakes; systems/story, systems/guardians).

const LANTERN := preload("res://scenes/world/rooms/frost_edge/contents/lighthouse_top_contents.tscn")
const IVO := preload("res://scenes/characters/ivo/ivo.tscn")
const ROOM := "res://scenes/world/rooms/frost_edge/contents/lighthouse_top.room"
const WAKES := "res://resources/cutscene/story/mentor_wakes.tres"
## Px: Ivo's origin above the floor (y 672) when he stands at a mark.
const STAND_LIFT := 30.0
const LETTERBOX := "res://scenes/ui/letterbox/letterbox.tscn"
## Px of floor kept above the bottom bar, so the figures stand on something.
const FLOOR_SHOWN := 24.0

var _lantern: Node2D
var _ivo: Player


func before_test() -> void:
	SaveSystem.begin("", true)
	SaveSystem.set_item_owned(Enums.PlayerItem.SWORD, true)
	SaveSystem.set_item_owned(Enums.PlayerItem.MEMORINA, true)
	SaveSystem.mark_dialogue_heard(&"mentor_gift")
	for guardian: Enums.Guardian in Enums.Guardian.values():
		SaveSystem.restore_guardian(guardian)

func after_test() -> void:
	SaveSystem.begin("", true)

func test_before_the_awakening_he_waits_still_and_no_fight_begins() -> void:
	_mount()
	await _frames(10)
	assert_str(_shown()).is_equal("StillAtLamp")
	assert_bool(_body().visible).is_false()
	assert_int(_body().process_mode).is_equal(Node.PROCESS_MODE_DISABLED)
	assert_int(_body().phase()).is_equal(GuardianFight.Phase.DORMANT)

func test_the_record_hands_the_keeper_to_the_body_in_one_frame_and_the_fight_begins() -> void:
	_mount()
	await _frames(4)
	var both: Array[int] = []
	var neither: Array[int] = []
	var sample := func() -> void:
		var keeper := _lantern.get_node("Props/Mentor") as FactStaging
		var keeper_shown := keeper.shown() != null and keeper.shown().visible
		if keeper_shown and _body().visible:
			both.append(Engine.get_process_frames())
		if not keeper_shown and not _body().visible:
			neither.append(Engine.get_process_frames())
	get_tree().process_frame.connect(sample)
	await get_tree().physics_frame
	SaveSystem.mark_scene_seen(&"mentor_wakes")
	await get_tree().process_frame
	assert_str(_shown()).is_equal("")
	assert_bool(_body().visible).is_true()
	assert_int(_body().process_mode).is_equal(Node.PROCESS_MODE_INHERIT)
	var began := -1
	for frame: int in 3:
		await get_tree().physics_frame
		if _body().phase() != GuardianFight.Phase.DORMANT:
			began = frame
			break
	get_tree().process_frame.disconnect(sample)
	assert_array(both).override_failure_message("the keeper and the body drawn together").is_empty()
	assert_array(neither).override_failure_message("neither the keeper nor the body drawn").is_empty()
	assert_int(began).override_failure_message("the trigger's re-entry began no fight").is_greater_equal(0)
	await _end_fight()

func test_an_unarmed_ivo_starts_nothing_until_he_returns_armed() -> void:
	SaveSystem.set_item_owned(Enums.PlayerItem.SWORD, false)
	_mount()
	await _frames(4)
	SaveSystem.mark_scene_seen(&"mentor_wakes")
	await _frames(6)
	assert_bool(_body().visible).is_true()
	assert_int(_body().phase()).is_equal(GuardianFight.Phase.DORMANT)
	# Out of the trigger's 560 px and back, armed: the refused entry left it open.
	_ivo.teleport(Vector2(720, -1200))
	await _frames(3)
	SaveSystem.set_item_owned(Enums.PlayerItem.SWORD, true)
	_ivo.teleport(_stand())
	await _frames(6)
	assert_int(_body().phase()).override_failure_message("no fight on his armed return").is_not_equal(
			GuardianFight.Phase.DORMANT)
	await _end_fight()

## A death rewinds the live SCENE_SEEN and rebuilds the world: he waits at the lamp again and the body is gone.
func test_a_rewind_puts_him_back_at_the_lamp_and_takes_the_body_away() -> void:
	SaveSystem.commit()
	SaveSystem.mark_scene_seen(&"mentor_wakes")
	SaveSystem.rewind()
	_mount()
	await _frames(2)
	assert_str(_shown()).is_equal("StillAtLamp")
	assert_bool(_body().visible).is_false()
	assert_int(_body().process_mode).is_equal(Node.PROCESS_MODE_DISABLED)

## The scene turns the absent body toward Ivo, and its first drawn frame keeps that facing.
func test_the_body_faces_ivo_on_its_first_visible_frame() -> void:
	var scene := load(WAKES) as Cutscene
	var faces := CutsceneCatalog.leaves(scene.steps).filter(func(step: CutsceneStep) -> bool:
		return step is CutsceneFace and (step as CutsceneFace).actor == &"mentor")
	assert_int(faces.size()).is_equal(1)
	assert_str(String((faces[0] as CutsceneFace).toward)).is_equal("ivo")
	_mount()
	await _frames(4)
	var toward := 1 if _ivo.global_position.x > _body().global_position.x else -1
	_body().face_towards(float(-toward))
	_body().face_towards(float(toward))
	SaveSystem.mark_scene_seen(&"mentor_wakes")
	await get_tree().process_frame
	assert_bool(_body().visible).is_true()
	assert_int(_body().facing).is_equal(toward)
	assert_bool((_body().get_node(^"Sprite2D") as Sprite2D).flip_h).is_equal(toward < 0)
	await _end_fight()

## No running jump or double jump from the hatch carries Ivo past the zone: every landing west of its east edge is a
## grounded tick inside it, and the zone runs to the west wall, so the walk to `ivo_stand` stays short
## (bugs/a-jump-over-the-mentor-wakes-zone-skips-the-awakening). It is the lantern's first trigger, armed before the
## restoration's.
func test_no_jump_from_the_hatch_lands_past_the_zone() -> void:
	_lantern = auto_free(LANTERN.instantiate()) as Node2D
	var map := RoomMapParser.parse(FileAccess.get_file_as_string(ROOM), RoomLegend.load_default(), ROOM).map
	var hatch_centre := INF
	for placed: Dictionary in map.entities:
		if placed.symbol == "E" and (placed.params as Dictionary).get("link", "") == "lighthouse_hatch":
			hatch_centre = float((placed.cell as Vector2i).x * RoomMap.CELL_PX) + RoomMap.CELL_PX * 0.5
	assert_float(hatch_centre).is_less(INF)
	var trigger := _lantern.get_node("Triggers").get_child(0) as CutsceneTrigger
	assert_str(String(trigger.cutscene.id)).is_equal("mentor_wakes")
	var shape := trigger.zone.get_node(^"CollisionShape2D") as CollisionShape2D
	var size := (shape.shape as RectangleShape2D).size
	var zone := Rect2(trigger.zone.position + shape.position - size * 0.5, size)
	var floor_y := (_lantern.get_node("Marks/MentorHome") as Node2D).position.y
	var ivo := auto_free(IVO.instantiate()) as Player
	assert_int(trigger.zone.collision_mask & ivo.collision_layer).is_not_equal(0)
	assert_float(zone.position.y).is_less_equal(0.0)
	assert_float(zone.end.y).is_greater_equal(floor_y)
	var reach := MapGuide.ivo_reach()
	var radius := reach.body_radius
	# Ivo arrives on the hatch outside the zone.
	assert_float(hatch_centre - radius).is_greater_equal(zone.end.x)
	var stand := (_lantern.get_node("Marks/IvoStand") as Node2D).position.x
	var walk := CutsceneCatalog.leaves((load(WAKES) as Cutscene).steps).filter(func(step: CutsceneStep) -> bool:
		return step is CutsceneWalk)[0] as CutsceneWalk
	var walk_speed := reach.locomotion.move_speed * walk.pace
	var landings := 0
	var take_off := hatch_centre
	while take_off - radius >= zone.end.x:
		for double: bool in [false, true]:
			var landing := take_off - (reach.gap(double) - radius * 2.0)
			if landing - radius >= zone.end.x:
				continue
			landings += 1
			var at := "take-off %.0f, %s" % [take_off, "double jump" if double else "jump"]
			assert_float(landing - radius).override_failure_message(at + ": lands west of the zone").is_greater_equal(
					zone.position.x)
			assert_float(absf(landing - stand) / walk_speed).override_failure_message(at + ": the walk is too long") 					.is_less_equal(3.0)
		take_off -= 4.0
	assert_int(landings).is_greater(0)

## STORY-38: the guardian stands idle for its opening hold once the fight begins, then its AI acts
## (bugs/the-mentor-guardian-hits-a-still-ivo-1-8-s-after-the-awakening-hands-back-control).
func test_the_fight_opens_with_the_guardian_idle() -> void:
	_mount()
	await _frames(4)
	SaveSystem.mark_scene_seen(&"mentor_wakes")
	var began := false
	for frame: int in 6:
		await get_tree().physics_frame
		if _body().phase() != GuardianFight.Phase.DORMANT:
			began = true
			break
	assert_bool(began).is_true()
	var hold := _body().stats.opening_hold
	assert_float(hold).is_equal_approx(1.5, 0.01)
	var home := _body().global_position.x
	var held_frames := floori((hold - 0.1) * Engine.physics_ticks_per_second)
	for frame: int in held_frames:
		await get_tree().physics_frame
		assert_bool((_body().get(&"_ai") as GuardianAI).active).override_failure_message(
				"the AI acted %d frames in" % frame).is_false()
	assert_float(absf(_body().global_position.x - home)).is_less(2.0)
	await _frames(12)
	assert_bool((_body().get(&"_ai") as GuardianAI).active).is_true()
	await _end_fight()

## The frame between the letterbox bars holds the lamp, the whole keeper and the whole Ivo with the floor under them
## (bugs/the-keeper-wakes-frame-hides-ivo-and-the-keeper-below-the-waist).
func test_the_frame_keeps_the_lamp_and_both_figures_between_the_bars() -> void:
	_lantern = auto_free(LANTERN.instantiate()) as Node2D
	var camera := CutsceneCatalog.leaves((load(WAKES) as Cutscene).steps).filter(func(step: CutsceneStep) -> bool:
		return step is CutsceneCamera)[0] as CutsceneCamera
	var zoom := camera.zoom if camera.zoom > 0.0 else 1.0
	var sum := Vector2.ZERO
	for id: StringName in camera.targets:
		var mark := "Marks/IvoStand" if id == &"ivo" else "Marks/MentorHome"
		sum += (_lantern.get_node(mark) as Node2D).position
	var centre := sum / camera.targets.size() + camera.offset
	var letterbox := auto_free((load(LETTERBOX) as PackedScene).instantiate()) as Node
	var bar := float(letterbox.get(&"bar_height")) / zoom
	var half := float(ProjectSettings.get_setting("display/window/size/viewport_height")) * 0.5 / zoom
	var lamp := _lantern.get_node("Lamp") as Node2D
	var floor_y := (_lantern.get_node("Marks/MentorHome") as Node2D).position.y
	assert_float(centre.y - half + bar).override_failure_message("the bar covers the lamp").is_less_equal(lamp.position.y)
	assert_float(centre.y + half - bar).override_failure_message("the bar covers the feet").is_greater_equal(
			floor_y + FLOOR_SHOWN)

## The awakening's last frame is the guardian's idle frame 0, drawn where and as the body draws it.
func test_the_raise_ends_on_the_guardians_first_frame() -> void:
	_lantern = auto_free(LANTERN.instantiate()) as Node2D
	var sprite := _lantern.get_node("MentorGuardian/Sprite2D") as Sprite2D
	var size := Vector2i(sprite.texture.get_width() / sprite.hframes, sprite.texture.get_height() / sprite.vframes)
	var idle := sprite.texture.get_image().get_region(Rect2i(Vector2i.ZERO, size))
	var strip := _lantern.get_node("Props/Mentor/RaisingWrong") as StagedStrip
	var frames := strip.sprite_frames
	var count := frames.get_frame_count(strip.intro)
	assert_bool(frames.get_animation_loop(strip.intro)).is_false()
	assert_str(_differs(frames.get_frame_texture(strip.intro, count - 1).get_image(), idle)).is_empty()
	assert_str(_differs(frames.get_frame_texture(strip.intro, 0).get_image(), idle)).is_empty()
	var placed := (_lantern.get_node("Props") as Node2D).position + strip.position
	assert_vector(placed).is_equal(_lantern.get_node("MentorGuardian").position + sprite.position)
	assert_vector(strip.scale).is_equal(sprite.scale)
	assert_bool(strip.flip_h).is_equal(sprite.flip_h)
	assert_bool(strip.centered).is_equal(sprite.centered)
	assert_vector(strip.offset).is_equal(sprite.offset)
	var seconds := 0.0
	for i: int in count:
		seconds += frames.get_frame_duration(strip.intro, i) / frames.get_animation_speed(strip.intro)
	assert_float(seconds).is_equal_approx(0.8, 0.01)

## The turn starts on StillAtLamp and ends on Stasis; the crack starts on Stasis: each the still's pixels where the still
## draws, so the cuts between them do not jump.
func test_the_strips_meet_the_stills() -> void:
	_lantern = auto_free(LANTERN.instantiate()) as Node2D
	var at_lamp := _lantern.get_node("Props/Mentor/StillAtLamp/Body") as Sprite2D
	var stasis := _lantern.get_node("Props/Mentor/Stasis/Body") as Sprite2D
	var turn := _lantern.get_node("Props/Mentor/StillTurning") as StagedStrip
	var crack := _lantern.get_node("Props/Mentor/Cracking") as StagedStrip
	assert_str(_strip_meets(turn, 0, at_lamp)).is_empty()
	assert_str(_strip_meets(turn, turn.sprite_frames.get_frame_count(turn.intro) - 1, stasis)).is_empty()
	assert_str(_strip_meets(crack, 0, stasis)).is_empty()
	assert_float(turn.sprite_frames.get_frame_count(turn.intro) / turn.sprite_frames.get_animation_speed(turn.intro)) 			.is_equal_approx(1.0, 0.01)

## Empty when frame `index` of `strip` draws `still`'s pixels on the same screen pixels; else the first difference.
func _strip_meets(strip: StagedStrip, index: int, still: Sprite2D) -> String:
	var frame := strip.sprite_frames.get_frame_texture(strip.intro, index).get_image().duplicate() as Image
	# A copy: flipping the image a texture hands out would flip it for the next caller too.
	var art := still.texture.get_image().duplicate() as Image
	if still.flip_h:
		art.flip_x()
	var at := Vector2i(still.position + still.offset - strip.position - strip.offset)
	if at.x < 0 or at.y < 0 or at.x + art.get_width() > frame.get_width() or at.y + art.get_height() > frame.get_height():
		return "%s frame %d: %s does not fit at %s" % [strip.name, index, still.get_parent().name, at]
	var shown := frame.get_region(Rect2i(at, art.get_size()))
	var differs := _differs(shown, art)
	if not differs.is_empty():
		return "%s frame %d vs %s: %s" % [strip.name, index, still.get_parent().name, differs]
	for y: int in frame.get_height():
		for x: int in frame.get_width():
			if not Rect2i(at, art.get_size()).has_point(Vector2i(x, y)) and frame.get_pixel(x, y).a > 0.0:
				return "%s frame %d draws outside %s at %s" % [strip.name, index, still.get_parent().name, Vector2i(x, y)]
	return ""

## Empty when the two images are the same size and every pixel matches (transparent pixels match any colour).
func _differs(first: Image, second: Image) -> String:
	if first.get_size() != second.get_size():
		return "sizes %s and %s" % [first.get_size(), second.get_size()]
	var a := first.duplicate() as Image
	var b := second.duplicate() as Image
	a.convert(Image.FORMAT_RGBA8)
	b.convert(Image.FORMAT_RGBA8)
	for y: int in a.get_height():
		for x: int in a.get_width():
			var pa := a.get_pixel(x, y)
			var pb := b.get_pixel(x, y)
			if (pa.a > 0.0 or pb.a > 0.0) and not pa.is_equal_approx(pb):
				return "pixel %s: %s vs %s" % [Vector2i(x, y), pa, pb]
	return ""

func _mount() -> void:
	_lantern = auto_free(LANTERN.instantiate()) as Node2D
	add_child(_lantern)
	_ivo = auto_free(IVO.instantiate()) as Player
	_ivo.position = _stand()
	add_child(_ivo)

func _stand() -> Vector2:
	return (_lantern.get_node("Marks/IvoStand") as Node2D).position - Vector2(0, STAND_LIFT)

func _body() -> Guardian:
	return _lantern.get_node("MentorGuardian") as Guardian

func _shown() -> String:
	var shown := (_lantern.get_node("Props/Mentor") as FactStaging).shown()
	return String(shown.name) if shown != null else ""

## Ivo leaves the tree before the guardian, which would otherwise answer his freed signals.
func _end_fight() -> void:
	_ivo.queue_free()
	await get_tree().physics_frame

func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame
