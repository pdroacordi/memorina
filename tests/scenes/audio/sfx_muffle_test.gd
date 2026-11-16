class_name SfxMuffleTest extends GdUnitTestSuite

## SfxMuffle sets the SfxWorld low-pass from the memory at its subject, off at full memory, and leaves the bus open
## when it leaves the tree; game.tscn has one, pausable, following Ivo.

const GAME := "res://scenes/world/game.tscn"

var _field: MemoryField
var _subject: Node2D
var _muffle: SfxMuffle


func before_test() -> void:
	_field = auto_free(MemoryField.new()) as MemoryField
	add_child(_field)
	_subject = auto_free(Node2D.new()) as Node2D
	add_child(_subject)
	_muffle = auto_free(SfxMuffle.new()) as SfxMuffle
	_muffle.subject = _subject
	add_child(_muffle)

func after_test() -> void:
	_bus_open()

func _bus_open() -> void:
	var bus := AudioServer.get_bus_index(AudioBuses.SFX_WORLD)
	AudioServer.set_bus_effect_enabled(bus, 0, false)
	(AudioServer.get_bus_effect(bus, 0) as AudioEffectLowPassFilter).cutoff_hz = SfxMuffleMath.OPEN_HZ

func _bus_state() -> Array:
	var bus := AudioServer.get_bus_index(AudioBuses.SFX_WORLD)
	return [AudioServer.is_bus_effect_enabled(bus, 0),
			(AudioServer.get_bus_effect(bus, 0) as AudioEffectLowPassFilter).cutoff_hz]

func test_full_memory_leaves_the_filter_off() -> void:
	_field.baseline = 1.0
	await get_tree().process_frame
	assert_array(_bus_state()).contains_exactly([false, SfxMuffleMath.OPEN_HZ])

func test_a_grey_place_muffles_by_its_memory() -> void:
	_field.baseline = 0.4
	await get_tree().process_frame
	var state := _bus_state()
	assert_bool(state[0]).is_true()
	assert_float(state[1]).is_equal_approx(SfxMuffleMath.cutoff(0.4), 0.5)
	assert_bool(_muffle.is_muffling()).is_true()

func test_returning_colour_opens_it() -> void:
	_field.baseline = 0.0
	await get_tree().process_frame
	_field.baseline = 1.0
	await get_tree().process_frame
	assert_array(_bus_state()).contains_exactly([false, SfxMuffleMath.OPEN_HZ])

## The bus outlives the game.tscn swap.
func test_leaving_the_tree_opens_the_bus() -> void:
	_field.baseline = 0.2
	await get_tree().process_frame
	remove_child(_muffle)
	assert_array(_bus_state()).contains_exactly([false, SfxMuffleMath.OPEN_HZ])
	add_child(_muffle)

func test_a_tree_pause_keeps_the_last_cutoff() -> void:
	# As under World.
	_muffle.process_mode = Node.PROCESS_MODE_PAUSABLE
	_field.baseline = 0.5
	await get_tree().process_frame
	var freeze := auto_free(WorldFreeze.new()) as WorldFreeze
	add_child(freeze)
	freeze.hold()
	_field.baseline = 0.0
	await get_tree().process_frame
	await get_tree().process_frame
	var held := _bus_state()
	freeze.release()
	assert_float(held[1]).is_equal_approx(SfxMuffleMath.cutoff(0.5), 0.5)

func test_the_game_has_one_pausable_muffle_on_ivo() -> void:
	var game := (load(GAME) as PackedScene).instantiate()
	var muffle := game.get_node(^"World/SfxMuffle") as SfxMuffle
	assert_object(muffle).is_not_null()
	assert_int(muffle.process_mode).is_equal(Node.PROCESS_MODE_INHERIT)
	assert_int(game.get_node(^"World").process_mode).is_equal(Node.PROCESS_MODE_PAUSABLE)
	assert_object(muffle.subject).is_same(game.get_node(^"World/Player"))
	game.free()
