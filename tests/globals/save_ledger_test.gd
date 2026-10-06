class_name SaveLedgerTest extends GdUnitTestSuite

## Death rewinds to the last bench while preserving its new death mark.

func _ledger() -> SaveLedger:
	return SaveLedger.new(PlayerData.new())

func test_what_is_gained_after_a_bench_is_lost_to_a_death() -> void:
	var ledger := _ledger()
	ledger.live.learned_songs[Enums.Song.FREEZE] = true
	ledger.live.restored_guardians[0] = true
	ledger.record_death("region", Vector2(10, 20))
	assert_bool(ledger.live.learned_songs[Enums.Song.FREEZE]).is_false()
	assert_bool(ledger.live.restored_guardians[0]).is_false()

func test_what_a_bench_commits_survives_a_death() -> void:
	var ledger := _ledger()
	ledger.live.learned_songs[Enums.Song.FREEZE] = true
	ledger.live.bench_id = &"downtown_bench"
	ledger.commit()
	ledger.record_death("region", Vector2.ZERO)
	assert_bool(ledger.live.learned_songs[Enums.Song.FREEZE]).is_true()
	assert_str(String(ledger.live.bench_id)).is_equal("downtown_bench")

func test_the_death_mark_survives_its_own_rewind() -> void:
	var ledger := _ledger()
	var written := ledger.record_death("region", Vector2(10, 20))
	assert_array(Array(ledger.live.deaths["region"])).is_equal([Vector2(10, 20)])
	assert_array(Array(written.deaths["region"])).is_equal([Vector2(10, 20)])

func test_deaths_accumulate_per_region() -> void:
	var ledger := _ledger()
	ledger.record_death("a", Vector2(1, 1))
	ledger.record_death("a", Vector2(2, 2))
	ledger.record_death("b", Vector2(3, 3))
	assert_int(ledger.live.deaths["a"].size()).is_equal(2)
	assert_int(ledger.live.deaths["b"].size()).is_equal(1)

## An uncommitted mark erasure is restored by death.
func test_an_erasure_not_yet_committed_is_rewound() -> void:
	var ledger := _ledger()
	ledger.record_death("a", Vector2(1, 1))
	ledger.live.deaths.erase("a")
	ledger.record_death("b", Vector2(2, 2))
	assert_bool(ledger.live.deaths.has("a")).is_true()

## Live and committed save arrays must not alias.
func test_live_and_committed_share_nothing() -> void:
	var ledger := _ledger()
	ledger.live.learned_songs[Enums.Song.FREEZE] = true
	ledger.live.resolved_shortcuts.append(&"lever")
	ledger.live.deaths["a"] = PackedVector2Array([Vector2.ONE])
	assert_bool(ledger.committed.learned_songs[Enums.Song.FREEZE]).is_false()
	assert_array(ledger.committed.resolved_shortcuts).is_empty()
	assert_bool(ledger.committed.deaths.has("a")).is_false()
	ledger.commit()
	ledger.live.learned_songs[Enums.Song.ROOT] = true
	assert_bool(ledger.committed.learned_songs[Enums.Song.ROOT]).is_false()

func test_a_rest_and_a_death_both_bring_the_defeated_back() -> void:
	var ledger := _ledger()
	ledger.defeated["brute"] = true
	ledger.commit()
	assert_bool(ledger.defeated.has("brute")).is_false()
	ledger.defeated["brute"] = true
	ledger.record_death("a", Vector2.ZERO)
	assert_bool(ledger.defeated.has("brute")).is_false()

func test_a_commit_adds_the_play_time_since_the_last_one() -> void:
	var ledger := _ledger()
	ledger.commit(60.0)
	ledger.commit(30.0)
	assert_float(ledger.committed.play_time).is_equal(90.0)
	assert_float(ledger.live.play_time).is_equal(90.0)

## The time played up to a death counts, though what was gained in it is lost.
func test_a_death_keeps_the_play_time_since_the_bench() -> void:
	var ledger := _ledger()
	ledger.commit(100.0)
	var written := ledger.record_death("a", Vector2.ZERO, 40.0)
	assert_float(written.play_time).is_equal(140.0)
	assert_float(ledger.live.play_time).is_equal(140.0)
	ledger.commit(10.0)
	assert_float(ledger.committed.play_time).is_equal(150.0)

func test_a_rewind_with_no_mark_keeps_the_play_time() -> void:
	var ledger := _ledger()
	ledger.rewind(25.0)
	assert_float(ledger.live.play_time).is_equal(25.0)

## The map is live data: what was seen since the bench is forgotten by a death (user decision 2026-10-02, "Map rewinds").
func test_the_map_seen_since_the_bench_is_forgotten_by_a_death() -> void:
	var ledger := _ledger()
	ledger.live.map_seen["room"] = PackedByteArray([1, 0, 1, 0, 1])
	var written := ledger.record_death("region", Vector2.ZERO)
	assert_bool(ledger.live.map_seen.has("room")).is_false()
	assert_bool(written.map_seen.has("room")).is_false()

func test_the_map_a_bench_commits_survives_a_death() -> void:
	var ledger := _ledger()
	ledger.live.map_seen["room"] = PackedByteArray([1, 0, 1, 0, 1])
	ledger.commit()
	var grown := ledger.live.map_seen["room"]
	grown.append(3)
	ledger.live.map_seen["room"] = grown
	ledger.live.map_seen["other"] = PackedByteArray([1, 0, 1, 0, 2])
	ledger.record_death("region", Vector2.ZERO)
	assert_array(Array(ledger.live.map_seen["room"])).is_equal([1, 0, 1, 0, 1])
	assert_bool(ledger.live.map_seen.has("other")).is_false()

## A PackedByteArray in a Dictionary is a value: a live write never reaches the committed save.
func test_live_and_committed_maps_share_nothing() -> void:
	var ledger := _ledger()
	ledger.live.map_seen["room"] = PackedByteArray([1, 0, 1, 0, 1])
	ledger.commit()
	var bytes := ledger.live.map_seen["room"]
	bytes[4] = 7
	ledger.live.map_seen["room"] = bytes
	assert_int(ledger.committed.map_seen["room"][4]).is_equal(1)
