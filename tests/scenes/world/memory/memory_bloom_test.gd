class_name MemoryBloomTest extends GdUnitTestSuite

## A MemoryBloom's source is hidden at rest, cuts or eases to a shape, size and strength on the scaled clock, and a reset
## hides it again.

var _bloom: MemoryBloom


func before_test() -> void:
	_bloom = auto_free(MemoryBloom.new()) as MemoryBloom
	_bloom.position = Vector2(100, 50)
	add_child(_bloom)

func test_it_is_hidden_at_rest() -> void:
	assert_bool(_bloom.is_blooming()).is_false()
	assert_float(_bloom.source().strength).is_equal(0.0)
	assert_bool(_bloom.is_in_group(MemoryBloom.GROUP)).is_true()

func test_a_cut_puts_the_source_at_once() -> void:
	_bloom.bloom_to(MemoryFieldMath.Shape.RECT, Vector2(64, 200), 0.0, Vector2(120, 150), -1.0, 0.5, 0.0)
	var source := _bloom.source()
	assert_bool(_bloom.is_blooming()).is_true()
	assert_int(source.shape).is_equal(MemoryFieldMath.Shape.RECT)
	assert_vector(source.global_position).is_equal(Vector2(120, 150))
	assert_vector(source.rect_size).is_equal(Vector2(64, 200))
	assert_float(source.strength).is_equal(-1.0)
	assert_float(source.ring).is_equal(0.5)

func test_a_bloom_eases_to_its_end_and_a_reset_hides_it() -> void:
	_bloom.bloom_to(MemoryFieldMath.Shape.CIRCLE, Vector2.ZERO, 96.0, Vector2(100, 50), 1.0, 0.0, 1.0)
	await await_millis(300)
	assert_float(_bloom.source().radius).is_between(0.1, 95.9)
	await await_millis(1000)
	assert_float(_bloom.source().radius).is_equal(96.0)
	assert_float(_bloom.source().strength).is_equal(1.0)
	_bloom.reset()
	assert_bool(_bloom.is_blooming()).is_false()
	assert_float(_bloom.source().strength).is_equal(0.0)

## The field reads it only while shown, as it reads a bench's bloom.
func test_the_field_reads_it_only_while_shown() -> void:
	var field := auto_free(MemoryField.new()) as MemoryField
	field.baseline = 0.0
	add_child(field)
	var bloom := auto_free(MemoryBloom.new()) as MemoryBloom
	add_child(bloom)
	assert_float(field.sample(Vector2.ZERO)).is_equal(0.0)
	bloom.bloom_to(MemoryFieldMath.Shape.CIRCLE, Vector2.ZERO, 64.0, Vector2.ZERO, 1.0, 0.0, 0.0)
	assert_float(field.sample(Vector2.ZERO)).is_greater(0.5)
	bloom.reset()
	assert_float(field.sample(Vector2.ZERO)).is_equal(0.0)
