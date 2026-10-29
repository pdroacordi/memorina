class_name CreatureSheetTest extends GdUnitTestSuite

## Each creature's clips match their art contracts and only draw: frame sizes from tools/art/prompts, hframes keyed
## before frame, no Area2D track (systems/creatures: every area is script-owned), no transitions, and the
## resolver's consts naming exactly the tree's states.

const SPECIES: Array[String] = ["boar", "scorpion"]
## One-shot attack clips whose length is their move's active window.
const TIMED_ATTACKS := {"scorpion": &"strike"}


func test_every_sheet_is_hframes_frames_of_the_contracted_size() -> void:
	for species: String in SPECIES:
		var root := _scene(species)
		for clip: Animation in _tree_clips(root):
			var contract := _contract_size(species, clip.resource_name)
			var texture := _keyed(clip, "Sprite2D:texture") as Texture2D
			var hframes := int(_keyed(clip, "Sprite2D:hframes"))
			var label := "%s %s" % [species, clip.resource_name]
			assert_int(texture.get_width()).override_failure_message("%s: %d px wide, not %d x %d" % [
				label, texture.get_width(), hframes, contract.x]).is_equal(hframes * contract.x)
			assert_int(texture.get_height()).override_failure_message(label).is_equal(contract.y)

func test_clips_key_hframes_before_frame_and_frames_below_hframes() -> void:
	for species: String in SPECIES:
		for clip: Animation in _tree_clips(_scene(species)):
			var hframes_track := clip.find_track(^"Sprite2D:hframes", Animation.TYPE_VALUE)
			var frame_track := clip.find_track(^"Sprite2D:frame", Animation.TYPE_VALUE)
			var label := "%s %s" % [species, clip.resource_name]
			assert_int(hframes_track).override_failure_message(label).is_less(frame_track)
			var hframes := int(_keyed(clip, "Sprite2D:hframes"))
			for key: int in clip.track_get_key_count(frame_track):
				assert_int(int(clip.track_get_key_value(frame_track, key))).override_failure_message(label).is_less(hframes)

func test_no_clip_keys_anything_but_the_sprite() -> void:
	for species: String in SPECIES:
		var root := _scene(species)
		var player := root.get_node(^"AnimationPlayer") as AnimationPlayer
		for clip_name: StringName in player.get_animation_list():
			var clip := player.get_animation(clip_name)
			for track: int in clip.get_track_count():
				var path := String(clip.track_get_path(track))
				assert_bool(path.begins_with("Sprite2D:")).override_failure_message(
					"%s %s keys %s; areas are script-owned" % [species, clip_name, path]).is_true()

func test_trees_have_no_transitions_and_the_resolver_names_every_state() -> void:
	for species: String in SPECIES:
		var root := _scene(species)
		var machine := (root.get_node(^"AnimationTree") as AnimationTree).tree_root as AnimationNodeStateMachine
		assert_int(machine.get_transition_count()).override_failure_message(species).is_equal(0)
		var states: Array[String] = []
		for state: StringName in machine.get_node_list():
			if state != &"Start" and state != &"End":
				states.append(String(state))
		var consts: Array[String] = []
		var resolver := (root.get_node(^"AnimationResolver") as Node).get_script() as GDScript
		for value: Variant in resolver.get_script_constant_map().values():
			if value is StringName:
				consts.append(String(value))
		states.sort()
		consts.sort()
		assert_array(consts).override_failure_message("%s: resolver %s, tree %s" % [species, consts, states]).is_equal(states)

func test_a_timed_attack_clip_lasts_its_move_active_window() -> void:
	for species: String in TIMED_ATTACKS:
		var root := _scene(species)
		var player := root.get_node(^"AnimationPlayer") as AnimationPlayer
		var clip := player.get_animation(TIMED_ATTACKS[species])
		var enemy := root as Enemy
		assert_float(clip.length).is_equal_approx(enemy.stats.moves[0].active, 0.001)
		assert_int(clip.loop_mode).is_equal(Animation.LOOP_NONE)

func _scene(species: String) -> Node:
	var path := "res://scenes/characters/creatures/%s/%s.tscn" % [species, species]
	return auto_free((load(path) as PackedScene).instantiate())

func _tree_clips(root: Node) -> Array[Animation]:
	var machine := (root.get_node(^"AnimationTree") as AnimationTree).tree_root as AnimationNodeStateMachine
	var player := root.get_node(^"AnimationPlayer") as AnimationPlayer
	var clips: Array[Animation] = []
	for state: StringName in machine.get_node_list():
		var node := machine.get_node(state) as AnimationNodeAnimation
		if node != null:
			clips.append(player.get_animation(node.animation))
	return clips

func _keyed(clip: Animation, path: String) -> Variant:
	var track := clip.find_track(NodePath(path), Animation.TYPE_VALUE)
	assert_int(track).override_failure_message("%s keys no %s" % [clip.resource_name, path]).is_not_equal(-1)
	return clip.track_get_key_value(track, 0)

## The `size:` line of tools/art/prompts/creature_<species>_<clip>.md.
func _contract_size(species: String, clip: String) -> Vector2i:
	var text := FileAccess.get_file_as_string("res://tools/art/prompts/creature_%s_%s.md" % [species, clip])
	for line: String in text.split("\n"):
		if line.begins_with("size:"):
			var parts := line.trim_prefix("size:").strip_edges().split("x")
			return Vector2i(int(parts[0]), int(parts[1]))
	assert_bool(false).override_failure_message("no contract size for %s %s" % [species, clip]).is_true()
	return Vector2i.ZERO
