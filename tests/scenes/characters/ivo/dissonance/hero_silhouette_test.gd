class_name HeroSilhouetteTest extends GdUnitTestSuite

## At the revelation Ivo's sprite borrows the silhouette material and alternates with the past self; when it ends the
## material is given back and only Ivo shows (GRD-06).

const IVO := preload("res://scenes/characters/ivo/ivo.tscn")


func test_the_revelation_borrows_the_sprite_and_gives_it_back() -> void:
	SaveSystem.begin("", true)
	var ivo := auto_free(IVO.instantiate()) as Player
	add_child(ivo)
	var sprite := ivo.get_node(^"Sprite2D") as Sprite2D
	var past := ivo.get_node(^"HeroSilhouette/PastSelf") as Sprite2D
	ivo.show_dissonance(0.0, 0.5)
	assert_object(sprite.material).is_not_null()
	ivo.show_dissonance(0.0, 1.0)
	await get_tree().process_frame
	assert_bool(sprite.visible and past.visible).override_failure_message("fused at the peak").is_true()
	ivo.show_dissonance(0.0, 0.0)
	assert_object(sprite.material).is_null()
	assert_bool(sprite.visible).is_true()
	assert_bool(past.visible).is_false()
	SaveSystem.begin("", true)
