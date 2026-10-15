class_name OpeningTest extends GdUnitTestSuite

## The opening's stages follow the talks heard, in the order the east gate guarantees (systems/story): a new game starts
## in Ivo's house with the daughter asleep, items owned early included; the errand, the song and the mentor's gift move her;
## the elder's audience leaves for the square after his story or at 0.6; the mentor holds the Memorina, gives it and goes
## still; the east gate stays shut until the elder's story.

const GAME := "res://scenes/world/game.tscn"
const HOME := "res://scenes/world/rooms/home_village.tscn"
const GATE_ROOM := "res://scenes/world/rooms/home_village/contents/village_gate_east.room"
const HEARD_ELDER := "res://resources/save_facts/heard_elder_story.tres"
const HOUSE := preload("res://scenes/world/rooms/home_village/contents/village_house_contents.tscn")
const ELDER := preload("res://scenes/world/rooms/home_village/contents/village_elder_contents.tscn")
const SQUARE := preload("res://scenes/world/rooms/home_village/contents/village_square_contents.tscn")
const LIGHTHOUSE := preload("res://scenes/world/rooms/frost_edge/contents/lighthouse_interior_contents.tscn")
## A room is a 640x384 screen (systems/world).
const ROOM := Vector2(640, 384)


func before_test() -> void:
	SaveSystem.begin("", true)
	SaveSystem.set_item_owned(Enums.PlayerItem.MEMORINA, false)
	SaveSystem.set_item_owned(Enums.PlayerItem.SWORD, false)

func after_test() -> void:
	SaveSystem.begin("", true)

## A new game has no bench, so Ivo starts where game.tscn places him: in his house, owning nothing.
func test_a_new_game_starts_in_ivos_house() -> void:
	var player := _position((load(GAME) as PackedScene).get_state(), &"Player")
	var house := _position((load(HOME) as PackedScene).get_state(), &"VillageHouse")
	assert_bool(Rect2(house, ROOM).has_point(player)).is_true()
	SaveSystem.begin("", true)
	assert_bool(SaveSystem.has_item(Enums.PlayerItem.SWORD)).is_false()
	assert_bool(SaveSystem.has_item(Enums.PlayerItem.MEMORINA)).is_false()

## Owning both items early (a playtest's kit) changes nothing: the stages read talks, so the morning is the same.
func test_owning_the_items_early_changes_nothing_in_the_house() -> void:
	SaveSystem.set_item_owned(Enums.PlayerItem.MEMORINA, true)
	SaveSystem.set_item_owned(Enums.PlayerItem.SWORD, true)
	var house := _mount(HOUSE)
	assert_str(_shown(house, "Props/Daughter")).is_equal("Asleep")
	assert_str(_shown(house, "Props/WallGuitar")).is_equal("OnWall")
	var lighthouse := _mount(LIGHTHOUSE)
	assert_str(_shown(lighthouse, "Props/Mentor")).is_equal("Holding")

func test_the_daughter_follows_the_morning() -> void:
	var house := _mount(HOUSE)
	assert_str(_shown(house, "Props/Daughter")).is_equal("Asleep")
	assert_str(_shown(house, "Props/WallGuitar")).is_equal("OnWall")
	assert_str(_shown(house, "Props/Drawings")).is_equal("Usual")
	SaveSystem.mark_dialogue_heard(&"baker_errand")
	assert_str(_shown(house, "Props/Daughter")).is_equal("HoldingOut")
	assert_str(_shown(house, "Props/WallGuitar")).is_equal("")
	SaveSystem.record_response(&"morning_song", &"guitar_try_again")
	SaveSystem.mark_dialogue_heard(&"daughter_song")
	assert_str(_shown(house, "Props/Daughter")).is_equal("InBedTurned")
	assert_str(_shown(house, "Props/WallGuitar")).is_equal("OnWall")
	SaveSystem.mark_dialogue_heard(&"mentor_gift")
	assert_str(_shown(house, "Props/Daughter")).is_equal("AtGuitar")
	assert_str(_shown(house, "Props/WallGuitar")).is_equal("")
	SaveSystem.mark_dialogue_heard(&"daughter_return")
	assert_str(_shown(house, "Props/Daughter")).is_equal("Standing")
	assert_str(_shown(house, "Props/WallGuitar")).is_equal("OnWall")
	_restore_two()
	assert_str(_shown(house, "Props/Drawings")).is_equal("Repeated")

## A held return heard late, at 0.6, still finds her at the guitar (bugs/a-late-held-return-shows-the-daughter-away-from-the-guitar-she-plays).
func test_a_late_held_return_finds_her_at_the_guitar() -> void:
	SaveSystem.mark_dialogue_heard(&"baker_errand")
	SaveSystem.record_response(&"morning_song", &"guitar_try_again")
	SaveSystem.mark_dialogue_heard(&"daughter_song")
	SaveSystem.mark_dialogue_heard(&"mentor_gift")
	_restore_two()
	var house := _mount(HOUSE)
	assert_str(_shown(house, "Props/Daughter")).is_equal("AtGuitar")
	assert_str(_shown(house, "Props/WallGuitar")).is_equal("")
	SaveSystem.mark_dialogue_heard(&"daughter_return")
	assert_str(_shown(house, "Props/Daughter")).is_equal("Standing")
	assert_str(_shown(house, "Props/WallGuitar")).is_equal("OnWall")

## STORY-12: standing and holding the guitar out, she breathes on the memory clock like the villagers, faces east as
## drawn, and every frame's feet (row 61) stand on the floor (y 288).
func test_the_daughter_moves_as_a_strip_with_her_feet_on_the_floor() -> void:
	var house := _mount(HOUSE)
	for path: String in ["Props/Daughter/Standing/Girl", "Props/Daughter/HoldingOut/Girl"]:
		var girl := house.get_node(path) as Sprite2D
		var frames := {"Props/Daughter/Standing/Girl": 8, "Props/Daughter/HoldingOut/Girl": 6}[path] as int
		assert_int(girl.hframes).override_failure_message(path).is_equal(frames)
		assert_int(girl.texture.get_width()).is_equal(frames * 64)
		assert_int(girl.texture.get_height()).is_equal(64)
		assert_object(girl.get_node_or_null("AmbientMotion") as AmbientMotion).override_failure_message(path).is_not_null()
		assert_bool(girl.flip_h).is_false()
		assert_float(girl.position.y + girl.offset.y + 62.0).is_equal(288.0)
		var image := girl.texture.get_image()
		for frame: int in frames:
			var feet := false
			var below := false
			for x: int in range(frame * 64, frame * 64 + 64):
				feet = feet or image.get_pixel(x, 61).a > 0.0
				below = below or image.get_pixel(x, 62).a > 0.0 or image.get_pixel(x, 63).a > 0.0
			assert_bool(feet and not below).override_failure_message("%s frame %d" % [path, frame]).is_true()

## Lowered, she hums at home after the gift instead of playing; the guitar stays on the wall.
func test_the_lowered_guitar_leaves_her_humming() -> void:
	SaveSystem.mark_dialogue_heard(&"baker_errand")
	SaveSystem.record_response(&"morning_song", &"guitar_lower")
	SaveSystem.mark_dialogue_heard(&"daughter_song")
	SaveSystem.mark_dialogue_heard(&"mentor_gift")
	var house := _mount(HOUSE)
	assert_str(_shown(house, "Props/Daughter")).is_equal("Standing")
	assert_str(_shown(house, "Props/WallGuitar")).is_equal("OnWall")

## The guitar is never lost: the girl holds it out only until the gift (bugs/the-memorina-before-the-song-hides-the-guitar-and-keeps-the-elders-audience).
func test_the_guitar_comes_back_whatever_was_skipped() -> void:
	SaveSystem.mark_dialogue_heard(&"baker_errand")
	SaveSystem.mark_dialogue_heard(&"mentor_gift")
	var house := _mount(HOUSE)
	assert_str(_shown(house, "Props/WallGuitar")).is_equal("OnWall")

func test_the_children_leave_the_elder_for_the_square_after_his_story() -> void:
	var elder := _mount(ELDER)
	var square := _mount(SQUARE)
	assert_str(_shown(elder, "Props/Audience")).is_equal("Listening")
	assert_str(_shown(square, "Props/Children")).is_equal("")
	SaveSystem.mark_dialogue_heard(&"elder_story")
	assert_str(_shown(elder, "Props/Audience")).is_equal("")
	assert_str(_shown(square, "Props/Children")).is_equal("Playing")

## At 0.6 his bench is empty whatever was heard: "He stops and looks at the empty bench."
func test_the_bench_is_empty_at_six_tenths() -> void:
	_restore_two()
	var elder := _mount(ELDER)
	assert_str(_shown(elder, "Props/Audience")).is_equal("")

## The gift's beat stands the empty hand in; the talk's end turns him to stasis.
func test_the_mentor_holds_gives_and_goes_still() -> void:
	var lighthouse := _mount(LIGHTHOUSE)
	assert_str(_shown(lighthouse, "Props/Mentor")).is_equal("Holding")
	var gift := lighthouse.get_node("Beats/MentorGift") as StagedBeat
	assert_str(String(gift.stand_ins.values()[0])).is_equal("EmptyHand")
	SaveSystem.mark_dialogue_heard(&"mentor_gift")
	assert_str(_shown(lighthouse, "Props/Mentor")).is_equal("Stasis")
	assert_float((lighthouse.get_node("Props/Mentor") as FactStaging).stages[0].fade_seconds).is_equal(1.5)

## STORY-11: his phrase stands in the strip that raises the flute and plays it, then gives way to the holding still.
func test_the_mentor_raises_and_plays_the_flute_during_his_phrase() -> void:
	var lighthouse := _mount(LIGHTHOUSE)
	var staging := lighthouse.get_node("Props/Mentor") as FactStaging
	var strip := lighthouse.get_node("Props/Mentor/Playing") as StagedStrip
	assert_bool(strip.is_visible_in_tree()).is_false()
	assert_int(strip.sprite_frames.get_frame_count(&"raise")).is_equal(5)
	assert_bool(strip.sprite_frames.get_animation_loop(&"raise")).is_false()
	assert_int(strip.sprite_frames.get_frame_count(&"play")).is_equal(6)
	assert_bool(strip.sprite_frames.get_animation_loop(&"play")).is_true()
	var phrase := lighthouse.get_node("Beats/MentorPhrase") as StagedBeat
	phrase.start()
	assert_str(String(staging.shown().name)).is_equal("Playing")
	assert_str(String(strip.animation)).is_equal("raise")
	assert_bool(strip.is_playing()).is_true()
	await await_signal_on(strip, "animation_changed", [], 2000)
	assert_str(String(strip.animation)).is_equal("play")
	await await_signal_on(phrase, "finished", [], 5000)
	assert_str(String(staging.shown().name)).is_equal("Holding")
	assert_bool(strip.is_playing()).is_false()

## The gift's line grants the Memorina as its beat starts, once.
func test_the_mentor_gives_the_memorina_once() -> void:
	var gift := (load("res://resources/dialogue/story/mentor.tres") as DialogueSet).dialogues[0]
	var granting: Array[DialogueLine] = []
	for line: DialogueLine in gift.lines:
		if line.grants != null:
			granting.append(line)
	assert_int(granting.size()).is_equal(1)
	assert_str(String(granting[0].cue)).is_equal("mentor_gift")
	assert_bool(granting[0].text_key.is_empty()).is_true()
	assert_int(granting[0].grants.index).is_equal(Enums.PlayerItem.MEMORINA)
	assert_bool(gift.once).is_true()
	var data := PlayerData.new()
	assert_bool(gift.is_open_for(data)).is_true()
	data.dialogues_heard.append(&"mentor_gift")
	assert_bool(gift.is_open_for(data)).is_false()

## The three remembered choices are gestures or a question, each a HOLD_ON and a LET_GO (design 05, Decisões).
func test_the_three_choices_hold_on_or_let_go() -> void:
	var catalog := load("res://resources/dialogue/dialogue_catalog.tres") as DialogueCatalog
	var asks: Dictionary[StringName, Array] = {}
	for line: DialogueLine in catalog.lines():
		if line.asks():
			var tones: Array[int] = []
			for answer: DialogueChoice in line.choices:
				tones.append(answer.tone)
			asks[line.ask_id] = tones
	for ask: StringName in [&"morning_song", &"elder_story", &"mentor_flicker"]:
		assert_array(asks.get(ask, [])).is_equal([DialogueChoice.Tone.HOLD_ON, DialogueChoice.Tone.LET_GO])

## "East gate shut until the elder points east (Recommended)" (user, 2026-10-15): the way east is a gate on his story,
## and both of his choices end the same talk.
func test_the_east_gate_opens_on_the_elders_story() -> void:
	var map := RoomMapParser.parse(FileAccess.get_file_as_string(GATE_ROOM), RoomLegend.load_default(), GATE_ROOM).map
	var gates: Array[String] = []
	for placed: Dictionary in map.entities:
		if placed.symbol == "X":
			gates.append(str(placed.params.get("requires", "")))
	assert_array(gates).contains([HEARD_ELDER])
	var fact := load(HEARD_ELDER) as SaveFact
	assert_int(fact.kind).is_equal(SaveFact.Kind.DIALOGUE_HEARD)
	assert_str(String(fact.id)).is_equal("elder_story")
	var data := PlayerData.new()
	assert_bool(fact.holds(data)).is_false()
	data.dialogues_heard.append(&"elder_story")
	assert_bool(fact.holds(data)).is_true()

func _restore_two() -> void:
	SaveSystem.restore_guardian(Enums.Guardian.FROST)
	SaveSystem.restore_guardian(Enums.Guardian.BLOOM)

func _position(state: SceneState, node_name: StringName) -> Vector2:
	for node: int in state.get_node_count():
		if state.get_node_name(node) != node_name:
			continue
		for i: int in state.get_node_property_count(node):
			if state.get_node_property_name(node, i) == &"position":
				return state.get_node_property_value(node, i)
	return Vector2.INF

func _shown(contents: Node, staging: String) -> String:
	var shown := (contents.get_node(staging) as FactStaging).shown()
	return String(shown.name) if shown != null else ""

func _mount(scene: PackedScene) -> Node:
	var contents := auto_free(scene.instantiate()) as Node
	add_child(contents)
	return contents
