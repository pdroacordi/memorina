class_name MusicLogicTest extends GdUnitTestSuite

## MusicRequests picks the top request and drops orphans; MusicMix fades stems and ducks; BarClock finds bar lines.


func _cue(stems: Array[StringName], levels: Dictionary[StringName, float] = {}) -> MusicCue:
	var cue := MusicCue.new()
	cue.stems = stems
	cue.levels = levels
	return cue

func _owner() -> Node:
	return auto_free(Node.new())

func test_the_highest_layer_plays_and_the_newest_wins_a_tie() -> void:
	var requests := MusicRequests.new()
	var holder := _owner()
	add_child(holder)
	var region := requests.add(MusicRequest.new(_cue([]), MusicRequest.Layer.REGION, holder))
	var fight := requests.add(MusicRequest.new(_cue([]), MusicRequest.Layer.FIGHT, holder))
	assert_object(requests.top()).is_same(fight)
	var fight2 := requests.add(MusicRequest.new(_cue([]), MusicRequest.Layer.FIGHT, holder))
	assert_object(requests.top()).is_same(fight2)
	requests.remove(fight2)
	requests.remove(fight)
	assert_object(requests.top()).is_same(region)
	requests.remove(region)
	assert_object(requests.top()).is_null()

func test_a_request_drops_when_its_owner_leaves_the_tree() -> void:
	var requests := MusicRequests.new()
	var holder := _owner()
	add_child(holder)
	requests.add(MusicRequest.new(_cue([]), MusicRequest.Layer.FIGHT, holder))
	assert_bool(requests.prune()).is_false()
	remove_child(holder)
	assert_bool(requests.prune()).is_true()
	assert_int(requests.size()).is_equal(0)

func test_a_stem_fades_to_its_target_on_real_time() -> void:
	var mix := MusicMix.new()
	mix.reset(_cue([&"bed", &"spring"], {&"spring": 0.0}))
	assert_float(mix.level(&"bed")).is_equal(1.0)
	assert_float(mix.stem_db(&"spring")).is_equal(MusicMix.SILENT_DB)
	mix.set_stem(&"spring", 1.0, 4.0)
	mix.step(2.0)
	assert_float(mix.level(&"spring")).is_equal_approx(0.5, 0.001)
	mix.step(3.0)
	assert_float(mix.level(&"spring")).is_equal(1.0)
	mix.set_stem(&"bed", 0.0, 0.0)
	assert_float(mix.level(&"bed")).is_equal(0.0)

func test_the_deepest_duck_wins_and_ducks_do_not_add() -> void:
	var mix := MusicMix.new()
	mix.reset(_cue([&"bed"]))
	mix.duck(&"call", -6.0)
	mix.duck(&"talk", -3.0)
	assert_float(mix.duck_target()).is_equal(-6.0)
	mix.step(1.0)
	assert_float(mix.duck_db()).is_equal(-6.0)
	mix.unduck(&"call")
	mix.step(1.0)
	assert_float(mix.duck_db()).is_equal(-3.0)
	mix.unduck(&"talk")
	mix.step(1.0)
	assert_float(mix.duck_db()).is_equal(0.0)

func test_the_next_bar_line() -> void:
	# 80 BPM, 4/4: a bar is 3 s.
	assert_float(BarClock.bar_seconds(80.0, 4)).is_equal_approx(3.0, 0.0001)
	assert_float(BarClock.next_bar(0.0, 80.0, 4)).is_equal(0.0)
	assert_float(BarClock.next_bar(3.0, 80.0, 4)).is_equal(0.0)
	assert_float(BarClock.next_bar(3.5, 80.0, 4)).is_equal_approx(2.5, 0.0001)
	assert_float(BarClock.next_bar(5.9995, 80.0, 4)).is_equal(0.0)
	# 60 BPM, 4/4: a bar is 4 s.
	assert_float(BarClock.next_bar(1.0, 60.0, 4)).is_equal_approx(3.0, 0.0001)

func test_a_cue_names_one_stem_per_stream() -> void:
	var sync := AudioStreamSynchronized.new()
	sync.stream_count = 2
	var cue := _cue([&"bed", &"lead"])
	cue.stream = sync
	assert_array(Array(cue.validate())).is_empty()
	cue.stems = [&"bed"]
	assert_array(Array(cue.validate())).is_not_empty()
	cue.stems = [&"bed", &"lead"]
	cue.levels = {&"spring": 0.0}
	assert_array(Array(cue.validate())).is_not_empty()

## A muffle eases on real time, the strongest wins, and the cutoff falls from open to under water.
func test_the_strongest_muffle_wins_and_eases_the_cutoff() -> void:
	var mix := MusicMix.new()
	assert_float(mix.cutoff_hz()).is_equal_approx(MusicMix.OPEN_HZ, 0.01)
	mix.muffle(&"leaving", 1.0)
	mix.muffle(&"talk", 0.3)
	assert_float(mix.muffle_target()).is_equal(1.0)
	mix.step(0.25)
	assert_float(mix.muffle_amount()).is_equal_approx(0.5, 0.001)
	assert_float(mix.cutoff_hz()).is_between(MusicMix.MUFFLED_HZ, MusicMix.OPEN_HZ)
	mix.step(1.0)
	assert_float(mix.cutoff_hz()).is_equal_approx(MusicMix.MUFFLED_HZ, 0.01)
	mix.unmuffle(&"leaving")
	mix.step(1.0)
	assert_float(mix.muffle_amount()).is_equal_approx(0.3, 0.001)
	mix.unmuffle(&"talk")
	mix.step(1.0)
	assert_float(mix.muffle_amount()).is_equal(0.0)

## A duck or a muffle with an owner closes once the owner leaves the tree or is disabled; one without stays.
func test_an_owned_duck_and_muffle_close_with_their_owner() -> void:
	var mix := MusicMix.new()
	var gone: Node = auto_free(Node.new())
	var idled: Node = auto_free(Node.new())
	add_child(gone)
	add_child(idled)
	mix.duck(&"gone", -6.0, gone)
	mix.muffle(&"idled", 0.8, idled)
	mix.muffle(&"kept", 0.3)
	mix.prune()
	assert_float(mix.duck_target()).is_equal(-6.0)
	assert_float(mix.muffle_target()).is_equal(0.8)
	remove_child(gone)
	idled.process_mode = Node.PROCESS_MODE_DISABLED
	mix.prune()
	assert_float(mix.duck_target()).is_equal(0.0)
	assert_float(mix.muffle_target()).is_equal(0.3)
	assert_bool(MusicMix.holds(0)).is_false()
