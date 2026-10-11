class_name HelixViewTest extends GdUnitTestSuite

## The view draws at art resolution, nearest-filtered, shown at 2x on the 2x grid behind the room's art, and redraws only
## when the turn or the eye moved.

const STAIR := preload("res://scenes/world/interactables/helix_stair/helix_stair.tscn")


func _view() -> HelixView:
	var stair := STAIR.instantiate() as HelixStair
	stair.position = Vector2(336, 1440)
	add_child(stair)
	auto_free(stair)
	return stair.view()

func test_the_viewport_draws_nearest_at_art_resolution() -> void:
	var view := _view()
	assert_int(view.viewport().canvas_item_default_texture_filter).is_equal(Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST)
	assert_bool(view.viewport().transparent_bg).is_true()
	assert_int(view.viewport().size.x).is_equal(128)

func test_the_sprite_is_doubled_on_even_pixels_behind_the_room() -> void:
	var sprite := _view().sprite()
	assert_that(sprite.scale).is_equal(Vector2(2, 2))
	assert_int(sprite.z_index).is_equal(HelixView.Z)
	assert_float(fposmod(sprite.global_position.x, 2.0)).is_equal(0.0)
	assert_float(fposmod(sprite.global_position.y, 2.0)).is_equal(0.0)

func test_it_redraws_once_per_change_and_never_otherwise() -> void:
	var view := _view()
	await get_tree().process_frame
	await get_tree().process_frame
	var settled := view.redraws
	view.refresh(1.0, -300.0)
	assert_int(view.redraws).is_equal(settled + 1)
	view.refresh(1.0, -300.0)
	view.refresh(1.0, -300.0)
	assert_int(view.redraws).is_equal(settled + 1)
	view.refresh(1.1, -300.0)
	view.refresh(1.1, -310.0)
	assert_int(view.redraws).is_equal(settled + 3)
