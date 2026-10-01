class_name SceneKeyTest extends GdUnitTestSuite

## The save names regions and rooms by the uid of the scene they come from, so
## a bench and its death marks are still found after the files are renamed.

const ROOM := "res://scenes/world/rooms/home_village/downtown.tscn"

func test_an_instanced_scene_is_keyed_by_its_uid() -> void:
	var room: Node = auto_free((load(ROOM) as PackedScene).instantiate())
	var key := SceneKey.of(room)
	assert_str(key).starts_with("uid://")
	assert_str(key).is_equal(ResourceUID.id_to_text(ResourceLoader.get_resource_uid(ROOM)))

func test_two_instances_of_one_scene_share_a_key() -> void:
	var a: Node = auto_free((load(ROOM) as PackedScene).instantiate())
	var b: Node = auto_free((load(ROOM) as PackedScene).instantiate())
	assert_str(SceneKey.of(a)).is_equal(SceneKey.of(b))
