class_name NoticeQueueTest extends GdUnitTestSuite

## The queue tells each item gained once and only the newest intent change, drops what a rewind took back, and puts a
## withdrawn notice back first (systems/notices).


func _owned(items: Array[int]) -> Array[bool]:
	var flags: Array[bool] = []
	flags.resize(Enums.PlayerItem.size())
	for item: int in items:
		flags[item] = true
	return flags

func _describe(queue: NoticeQueue) -> Array[String]:
	var found: Array[String] = []
	for notice: Notice in queue.waiting():
		found.append("item %d" % notice.item if notice.is_item() else "intent %s" % notice.intent_id)
	return found

func test_gained_lists_the_new_items_only() -> void:
	var before := _owned([Enums.PlayerItem.SWORD])
	var after := _owned([Enums.PlayerItem.SWORD, Enums.PlayerItem.BREAD])
	assert_array(NoticeQueue.gained(before, after)).contains_exactly([Enums.PlayerItem.BREAD])
	assert_array(NoticeQueue.gained(after, before)).is_empty()

## An older save's shorter array still counts the appended item as gained.
func test_gained_reads_a_shorter_before() -> void:
	var before: Array[bool] = [false]
	assert_array(NoticeQueue.gained(before, _owned([Enums.PlayerItem.BREAD]))).contains_exactly([Enums.PlayerItem.BREAD])

func test_an_item_is_queued_once() -> void:
	var queue := NoticeQueue.new()
	queue.add_item(Enums.PlayerItem.BREAD)
	queue.add_item(Enums.PlayerItem.BREAD)
	assert_array(_describe(queue)).contains_exactly(["item %d" % Enums.PlayerItem.BREAD])

func test_the_seeded_intent_tells_nothing() -> void:
	var queue := NoticeQueue.new(&"bread")
	queue.set_intent(&"bread")
	assert_bool(queue.is_empty()).is_true()

func test_only_the_newest_intent_change_waits() -> void:
	var queue := NoticeQueue.new(&"bread")
	queue.set_intent(&"home")
	queue.set_intent(&"elder")
	assert_array(_describe(queue)).contains_exactly(["intent elder"])

func test_a_change_back_before_its_turn_tells_nothing() -> void:
	var queue := NoticeQueue.new(&"bread")
	queue.set_intent(&"home")
	queue.set_intent(&"bread")
	assert_bool(queue.is_empty()).is_true()

func test_no_intent_drops_a_waiting_change() -> void:
	var queue := NoticeQueue.new(&"bread")
	queue.set_intent(&"home")
	queue.set_intent(&"")
	assert_bool(queue.is_empty()).is_true()

## The baker's talk grants the bread on a line and is heard at its end: the item first, then the new intent.
func test_items_and_intents_pop_in_the_order_they_came() -> void:
	var queue := NoticeQueue.new(&"bread")
	queue.add_item(Enums.PlayerItem.BREAD)
	queue.set_intent(&"home")
	var first := queue.pop()
	assert_bool(first.is_item()).is_true()
	assert_int(first.item).is_equal(Enums.PlayerItem.BREAD)
	assert_str(String(queue.pop().intent_id)).is_equal("home")
	assert_object(queue.pop()).is_null()

func test_a_told_intent_is_not_told_again() -> void:
	var queue := NoticeQueue.new(&"bread")
	queue.set_intent(&"home")
	queue.pop()
	queue.set_intent(&"home")
	assert_bool(queue.is_empty()).is_true()

func test_an_item_taken_back_before_its_turn_is_dropped() -> void:
	var queue := NoticeQueue.new()
	queue.add_item(Enums.PlayerItem.SWORD)
	queue.add_item(Enums.PlayerItem.BREAD)
	queue.keep_owned(_owned([Enums.PlayerItem.BREAD]))
	assert_array(_describe(queue)).contains_exactly(["item %d" % Enums.PlayerItem.BREAD])

func test_a_withdrawn_notice_goes_back_first() -> void:
	var queue := NoticeQueue.new()
	queue.add_item(Enums.PlayerItem.SWORD)
	queue.add_item(Enums.PlayerItem.BREAD)
	var shown := queue.pop()
	queue.push_front(shown)
	assert_array(_describe(queue)).contains_exactly(["item %d" % Enums.PlayerItem.SWORD, "item %d" % Enums.PlayerItem.BREAD])

## bugs/a-withdrawn-intent-comes-back-after-the-intent-ended: an intent that ended while it showed is not told again,
## and the told intent becomes none, so the pause menu drops it.
func test_a_withdrawn_intent_that_ended_is_dropped() -> void:
	var queue := NoticeQueue.new(&"bread")
	queue.set_intent(&"home")
	var shown := queue.pop()
	assert_str(String(queue.told_intent())).is_equal("home")
	queue.set_intent(&"")
	queue.push_front(shown)
	assert_bool(queue.is_empty()).is_true()
	assert_str(String(queue.told_intent())).is_equal("")

func test_a_withdrawn_intent_that_still_holds_goes_back_first() -> void:
	var queue := NoticeQueue.new(&"bread")
	queue.set_intent(&"home")
	var shown := queue.pop()
	queue.add_item(Enums.PlayerItem.BREAD)
	queue.push_front(shown)
	assert_array(_describe(queue)).contains_exactly(["intent home", "item %d" % Enums.PlayerItem.BREAD])

## An unchanged intent keeps its place: the queue stays oldest first.
func test_an_unchanged_intent_keeps_its_place() -> void:
	var queue := NoticeQueue.new(&"bread")
	queue.set_intent(&"home")
	queue.add_item(Enums.PlayerItem.BREAD)
	queue.set_intent(&"home")
	assert_array(_describe(queue)).contains_exactly(["intent home", "item %d" % Enums.PlayerItem.BREAD])

## An intent replaced while it showed is stale: the newer one is told instead.
func test_a_withdrawn_intent_a_newer_one_replaced_is_dropped() -> void:
	var queue := NoticeQueue.new(&"bread")
	queue.set_intent(&"home")
	var shown := queue.pop()
	queue.set_intent(&"elder")
	queue.push_front(shown)
	assert_array(_describe(queue)).contains_exactly(["intent elder"])
