class_name FactPresenceTest extends GdUnitTestSuite

## FactPresence hides and disables its parent while its gates fail, shows and enables it a deferred frame after they
## pass, hears the save while its parent is disabled, and leaves a present parent INHERIT under a disabled root.

const F := preload("res://tests/resources/dialogue/dialogue_fixture.gd")


func before_test() -> void:
	SaveSystem.begin("", true)

func after_test() -> void:
	SaveSystem.begin("", true)

## A root holding a body whose presence waits for `gift` heard, unless `four` is heard.
func _mount(root_mode: Node.ProcessMode = Node.PROCESS_MODE_INHERIT) -> Node2D:
	var root := auto_free(Node2D.new()) as Node2D
	root.process_mode = root_mode
	var body := Node2D.new()
	body.name = "Body"
	var presence := FactPresence.new()
	presence.name = "FactPresence"
	presence.when = [F.fact(SaveFact.Kind.DIALOGUE_HEARD, &"gift")]
	presence.unless = [F.fact(SaveFact.Kind.DIALOGUE_HEARD, &"four")]
	body.add_child(presence)
	root.add_child(body)
	add_child(root)
	return body

func test_absent_at_ready_hides_and_disables_its_parent() -> void:
	var body := _mount()
	assert_bool(body.visible).is_false()
	assert_int(body.process_mode).is_equal(Node.PROCESS_MODE_DISABLED)
	assert_bool(body.can_process()).is_false()

func test_present_at_ready_shows_and_inherits_at_once() -> void:
	SaveSystem.mark_dialogue_heard(&"gift")
	var body := _mount()
	assert_bool(body.visible).is_true()
	assert_int(body.process_mode).is_equal(Node.PROCESS_MODE_INHERIT)

func test_a_fact_arriving_shows_and_enables_it_after_a_deferred_frame() -> void:
	var body := _mount()
	SaveSystem.mark_dialogue_heard(&"gift")
	assert_bool(body.visible).is_false()
	await get_tree().process_frame
	assert_bool(body.visible).is_true()
	assert_int(body.process_mode).is_equal(Node.PROCESS_MODE_INHERIT)
	assert_bool(body.can_process()).is_true()

func test_an_unless_fact_takes_it_away_again() -> void:
	SaveSystem.mark_dialogue_heard(&"gift")
	var body := _mount()
	SaveSystem.mark_dialogue_heard(&"four")
	await get_tree().process_frame
	assert_bool(body.visible).is_false()
	assert_int(body.process_mode).is_equal(Node.PROCESS_MODE_DISABLED)

func test_progress_reaches_it_while_its_parent_is_disabled() -> void:
	var body := _mount()
	assert_bool((body.get_node("FactPresence") as FactPresence).can_process()).is_false()
	SaveSystem.mark_dialogue_heard(&"gift")
	await get_tree().process_frame
	assert_bool(body.visible).is_true()

func test_a_present_parent_under_a_disabled_root_stays_disabled() -> void:
	SaveSystem.mark_dialogue_heard(&"gift")
	var body := _mount(Node.PROCESS_MODE_DISABLED)
	assert_int(body.process_mode).is_equal(Node.PROCESS_MODE_INHERIT)
	assert_bool(body.can_process()).is_false()
