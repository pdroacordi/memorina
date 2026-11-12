class_name CorruptionEdgeTest extends GdUnitTestSuite

## A creature's edge puts its body on the creature pass and keeps its material; an actor's edge leaves it in the root
## canvas and carries the material only while agitated, so at rest it draws plain art with no unshielded mark.

var _body: Node2D
var _sprite: Sprite2D
var _material: ShaderMaterial


func before_test() -> void:
	_body = auto_free(Node2D.new()) as Node2D
	_sprite = Sprite2D.new()
	_material = ShaderMaterial.new()
	_material.shader = preload("res://scenes/characters/components/corruption/corruption_edge.gdshader")
	_sprite.material = _material
	_body.add_child(_sprite)
	_body.add_child(Health.new())

func _edge(creature_pass: bool) -> CorruptionEdge:
	var edge := CorruptionEdge.new()
	edge.sprite = _sprite
	edge.health = _body.get_child(1) as Health
	edge.creature_pass = creature_pass
	_body.add_child(edge)
	add_child(_body)
	return edge

func test_a_creature_joins_the_creature_pass() -> void:
	_edge(true)
	assert_int(_body.visibility_layer).is_equal(CanvasPass.CREATURES)
	assert_object(_sprite.material).is_same(_material)

func test_an_actor_stays_in_the_root_canvas_and_frays_only_while_agitated() -> void:
	var edge := _edge(false)
	assert_int(_body.visibility_layer).is_equal(1)
	assert_object(_sprite.material).is_null()
	edge.agitate(true)
	assert_object(_sprite.material).is_same(_material)
	assert_float(float(_material.get_shader_parameter(&"agitation"))).is_equal(edge.agitation_fray)
	edge.agitate(false)
	assert_object(_sprite.material).is_null()
	assert_float(float(_material.get_shader_parameter(&"agitation"))).is_equal(0.0)
