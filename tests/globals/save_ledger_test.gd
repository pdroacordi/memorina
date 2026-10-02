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
