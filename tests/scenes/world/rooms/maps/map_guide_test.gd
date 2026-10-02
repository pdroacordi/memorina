class_name MapGuideTest extends GdUnitTestSuite

## Verifies generated sections in docs/maps/README.md match current map data.

func test_the_map_guide_matches_the_code() -> void:
	var readme := FileAccess.get_file_as_string(MapGuide.README)
	var rendered := MapGuide.render(readme, RoomLegend.load_default())
	assert_bool(rendered == readme) \
		.override_failure_message("docs/maps/README.md is stale: run \"<godot>\" --headless --path . res://tools/maps/gen_map_docs.tscn") \
		.is_true()
