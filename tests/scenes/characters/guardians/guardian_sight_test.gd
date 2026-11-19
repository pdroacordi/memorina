class_name GuardianSightTest extends GdUnitTestSuite

## Every guardian sees its whole arena from anywhere in it, so no move can carry Ivo out of its sight and stop its AI
## mid-strike (bugs/the-leaf-gust-blows-ivo-out-of-the-guardians-sight-and-the-fight-stops).

const ROOMS_DIR := "res://scenes/world/rooms"
const GUARDIANS_DIR := "res://scenes/characters/guardians/"


func before_test() -> void:
	SaveSystem.begin("", true)

func after_test() -> void:
	SaveSystem.begin("", true)

func test_every_guardian_sees_across_its_own_arena() -> void:
	var checked := 0
	for path: String in _contents_scenes(ROOMS_DIR):
		if not FileAccess.get_file_as_string(path).contains(GUARDIANS_DIR):
			continue
		var contents := (load(path) as PackedScene).instantiate() as Node2D
		add_child(contents)
		for child: Node in contents.get_children():
			var guardian := child as Guardian
			if guardian == null:
				continue
			checked += 1
			var arena := guardian.arena_bounds()
			var shape := (guardian.get_node(^"EnemySight/CollisionShape2D") as CollisionShape2D).shape as CircleShape2D
			assert_float(arena.size.x).override_failure_message("%s has no arena" % guardian.name).is_greater(0.0)
			assert_float(shape.radius).override_failure_message("%s: sight %.0f, arena %s" % [
					guardian.name, shape.radius, arena.size]).is_greater_equal(arena.size.length())
		contents.free()
	assert_int(checked).is_equal(5)

func test_sight_never_shrinks_below_the_scene_radius() -> void:
	assert_float(Guardian.sight_radius_for(900.0, Rect2(0.0, 0.0, 300.0, 200.0))).is_equal(900.0)
	assert_float(Guardian.sight_radius_for(900.0, Rect2(0.0, 0.0, 1280.0, 384.0))).is_equal_approx(1336.36, 0.01)
	assert_float(Guardian.sight_radius_for(900.0, Rect2())).is_equal(900.0)

func _contents_scenes(dir: String) -> Array[String]:
	var found: Array[String] = []
	for sub: String in DirAccess.get_directories_at(dir):
		found.append_array(_contents_scenes(dir.path_join(sub)))
	for file: String in DirAccess.get_files_at(dir):
		if file.ends_with("_contents.tscn"):
			found.append(dir.path_join(file))
	return found
