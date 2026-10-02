class_name EntityParamsTest extends GdUnitTestSuite

## Checks JSON entity params are converted to node property types and invalid values are reported.

func _node() -> Node2D:
	return auto_free(Node2D.new())

func test_a_vector_comes_from_a_pair() -> void:
	var node := _node()
	EntityParams.apply(node, {"position": [3, 4]})
	assert_vector(node.position).is_equal(Vector2(3, 4))

func test_a_number_sets_a_float() -> void:
	var node := _node()
	EntityParams.apply(node, {"rotation": 1})
	assert_float(node.rotation).is_equal(1.0)

func test_a_color_comes_from_hex() -> void:
	var node := _node()
	EntityParams.apply(node, {"modulate": "#ff000080"})
	assert_float(node.modulate.r).is_equal(1.0)
	assert_float(node.modulate.a).is_equal_approx(0.5, 0.01)

func test_the_id_names_the_node() -> void:
	var node := _node()
	EntityParams.apply(node, {"id": "gate_a"})
	assert_str(String(node.name)).is_equal("gate_a")

func test_an_unknown_param_is_reported() -> void:
	var problems := EntityParams.check(_node(), {"no_such_thing": 1})
	assert_int(problems.size()).is_equal(1)

func test_a_value_of_the_wrong_type_is_reported() -> void:
	var problems := EntityParams.check(_node(), {"position": "left"})
	assert_int(problems.size()).is_equal(1)

func test_valid_params_report_nothing() -> void:
	assert_int(EntityParams.check(_node(), {"id": "x", "position": [1, 2], "visible": false}).size()).is_equal(0)

func test_a_bare_id_links_to_a_sibling() -> void:
	var link: Variant = EntityParams._convert("gate_a", TYPE_NODE_PATH)
	assert_str(str(link)).is_equal("../gate_a")

func test_a_written_path_is_kept() -> void:
	var link: Variant = EntityParams._convert("../../x", TYPE_NODE_PATH)
	assert_str(str(link)).is_equal("../../x")

func test_a_resource_comes_from_its_path() -> void:
	var loaded: Variant = EntityParams._convert("res://resources/world/wind/gusty_wind.tres", TYPE_OBJECT)
	assert_object(loaded).is_instanceof(WindProfile)

func test_a_missing_resource_is_reported() -> void:
	assert_object(EntityParams._convert("res://nowhere.tres", TYPE_OBJECT)).is_null()

func test_a_fraction_is_not_an_int() -> void:
	assert_object(EntityParams._convert(1.5, TYPE_INT)).is_null()
