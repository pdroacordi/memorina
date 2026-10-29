class_name TeacherSheetTest extends GdUnitTestSuite

## Each teacher's three clips match their art (assets/sprites/world/creatures, 4 frames each) and the shared resolver
## names exactly the tree's states (systems/teaching-creatures).

const SPECIES := {
	"snail": Vector2i(32, 32),
	"thrush": Vector2i(32, 32),
	"kestrel": Vector2i(48, 48),
	"lizard": Vector2i(48, 32),
}
const FRAMES := 4
## Clip: frames per second, loops.
const CLIPS := {
	TeacherAnimationResolver.IDLE: [6.0, true],
	TeacherAnimationResolver.SING: [8.0, true],
	TeacherAnimationResolver.FLOURISH: [8.0, false],
}


func _scene(species: String) -> Node:
	return auto_free(load("res://scenes/world/creatures/%s/%s.tscn" % [species, species]).instantiate())

func test_three_clips_of_four_frames_at_the_art_size() -> void:
	for species: String in SPECIES:
		var root := _scene(species)
		var player := root.get_node(^"AnimationPlayer") as AnimationPlayer
		var sprite := root.get_node(^"Sprite2D") as Sprite2D
		assert_int(sprite.hframes).is_equal(FRAMES)
		for clip_name: StringName in CLIPS:
			var label := "%s %s" % [species, clip_name]
			assert_bool(player.has_animation(clip_name)).override_failure_message(label).is_true()
			var clip := player.get_animation(clip_name)
			var texture_track := clip.find_track(^"Sprite2D:texture", Animation.TYPE_VALUE)
			var texture := clip.track_get_key_value(texture_track, 0) as Texture2D
			var size: Vector2i = SPECIES[species]
			assert_int(texture.get_width()).override_failure_message(label).is_equal(size.x * FRAMES)
			assert_int(texture.get_height()).override_failure_message(label).is_equal(size.y)
			assert_float(clip.length).override_failure_message(label).is_equal_approx(FRAMES / float(CLIPS[clip_name][0]), 0.001)
			assert_bool(clip.loop_mode == Animation.LOOP_LINEAR).override_failure_message(label).is_equal(CLIPS[clip_name][1])

func test_clips_key_only_the_sprite_and_never_its_scale() -> void:
	for species: String in SPECIES:
		var player := _scene(species).get_node(^"AnimationPlayer") as AnimationPlayer
		for clip_name: StringName in player.get_animation_list():
			var clip := player.get_animation(clip_name)
			for track: int in clip.get_track_count():
				var path := String(clip.track_get_path(track))
				assert_bool(path.begins_with("Sprite2D:") and not path.ends_with(":scale")).override_failure_message(
					"%s %s keys %s" % [species, clip_name, path]).is_true()

func test_trees_have_no_transitions_and_the_resolver_names_every_state() -> void:
	var consts: Array[String] = []
	for value: Variant in (TeacherAnimationResolver as GDScript).get_script_constant_map().values():
		if value is StringName:
			consts.append(String(value))
	consts.sort()
	for species: String in SPECIES:
		var root := _scene(species)
		var machine := (root.get_node(^"AnimationTree") as AnimationTree).tree_root as AnimationNodeStateMachine
		assert_int(machine.get_transition_count()).override_failure_message(species).is_equal(0)
		var states: Array[String] = []
		for state: StringName in machine.get_node_list():
			if state != &"Start" and state != &"End":
				states.append(String(state))
		states.sort()
		assert_array(states).override_failure_message(species).is_equal(consts)
		assert_object(root.get_node(^"AnimationResolver").get_script()).is_same(TeacherAnimationResolver)
