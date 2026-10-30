class_name BarkBalloonTest extends GdUnitTestSuite

## A guardian's bark beside its head: on the side asked, inside the screen, clear of the encounter slot; it shows the
## text without stutter marks and closes when its speaker goes (systems/guardians, "Talks").

const BALLOON := preload("res://scenes/ui/bark_balloon/bark_balloon.tscn")
const CALL_HUD := preload("res://scenes/ui/guardian_call_hud/guardian_call_hud.tscn")
const SONG := preload("res://resources/songs/root.tres")
const SCREEN := Vector2(320, 180)
const BOX := Vector2(80, 24)
const TAIL := 4.0
const GAP := 6.0
const MARGIN := 2.0

var _balloon: BarkBalloon
var _anchor: Node2D


func before_test() -> void:
	_balloon = auto_free(BALLOON.instantiate()) as BarkBalloon
	add_child(_balloon)
	_anchor = auto_free(Node2D.new()) as Node2D
	add_child(_anchor)
	_anchor.position = get_viewport().get_visible_rect().size * 0.5

func _inside(placed: Vector2, box: Vector2, screen: Vector2) -> bool:
	return Rect2(Vector2.ZERO, screen).encloses(Rect2(placed, box))

func test_it_sits_beside_the_anchor_on_the_side_asked() -> void:
	var anchor := Vector2(160, 120)
	var east := BalloonPlacement.beside(anchor, BOX, TAIL, 1, GAP, SCREEN, MARGIN)
	assert_float(east.x).is_equal(anchor.x + GAP)
	assert_float(east.y + BOX.y + TAIL).is_equal(anchor.y)
	var west := BalloonPlacement.beside(anchor, BOX, TAIL, -1, GAP, SCREEN, MARGIN)
	assert_float(west.x + BOX.x).is_equal(anchor.x - GAP)

func test_it_stays_inside_the_screen() -> void:
	for anchor: Vector2 in [Vector2(318, 120), Vector2(2, 120), Vector2(160, 4), Vector2(316, 178)]:
		for side: int in [-1, 1]:
			var placed := BalloonPlacement.beside(anchor, BOX, TAIL, side, GAP, SCREEN, MARGIN)
			assert_bool(_inside(placed, BOX, SCREEN)).override_failure_message("%s side %d at %s" % [anchor, side, placed]).is_true()

func test_it_keeps_clear_of_the_slot() -> void:
	var anchor := Vector2(200, 70)
	var slot := Rect2(Vector2(204, 20), Vector2(112, 64))
	var placed := BalloonPlacement.beside(anchor, BOX, TAIL, 1, GAP, SCREEN, MARGIN, slot)
	assert_bool(Rect2(placed, BOX).intersects(slot)).is_false()
	assert_float(placed.x + BOX.x).is_less_equal(anchor.x)
	# A slot over both sides sends it beside the head under the slot, the tail up.
	var wide := Rect2(Vector2(0, 20), Vector2(320, 64))
	var under := BalloonPlacement.beside(anchor, BOX, TAIL, 1, GAP, SCREEN, MARGIN, wide)
	assert_bool(Rect2(under, BOX).intersects(wide)).is_false()
	assert_bool(_inside(under, BOX, SCREEN)).is_true()
	assert_bool(BalloonPlacement.tail_points_up(anchor, under)).is_true()

# The Bloom stag under a centred sheet (playtests/2026-10-30-grd08-story18-guardian-clips-and-talks, art px): the head
# sits inside the slot's band on both sides, and the sheet leaves no room above it for the two-row box.
func test_the_bloom_bark_keeps_off_the_sheet_and_the_stag() -> void:
	var slot := Rect2(Vector2(79, 20), Vector2(128, 64))
	var box := Vector2(128, 29)
	var screen := Vector2(320, 180)
	# Head anchor y -56 art px over the feet; body capsule r16 h120 world px, centred at y -60.
	for case: Array in [[Vector2(275, 76), 1], [Vector2(46, 76), -1]]:
		var head: Vector2 = case[0]
		var side: int = case[1]
		var body := Rect2(head + Vector2(-8, -4), Vector2(16, 60))
		var placed := BalloonPlacement.beside(head, box, TAIL, side, GAP, screen, MARGIN, slot, body)
		var rect := Rect2(placed, box)
		var label := "head %s: %s" % [head, rect]
		assert_bool(rect.intersects(slot)).override_failure_message(label).is_false()
		assert_bool(rect.intersects(body)).override_failure_message(label).is_false()
		assert_bool(_inside(placed, box, screen)).override_failure_message(label).is_true()
		var up := BalloonPlacement.tail_points_up(head, placed)
		var tip := Vector2(placed.x + BalloonPlacement.tail_x(head.x, placed.x, box.x, TAIL),
				placed.y - TAIL if up else placed.y + box.y + TAIL)
		assert_float(tip.distance_to(head)).override_failure_message(label).is_less(32.0)

func test_the_tail_stays_on_the_box() -> void:
	assert_float(BalloonPlacement.tail_x(10.0, 50.0, 80.0, TAIL)).is_equal(TAIL)
	assert_float(BalloonPlacement.tail_x(200.0, 50.0, 80.0, TAIL)).is_equal(80.0 - TAIL)
	assert_float(BalloonPlacement.tail_x(90.0, 50.0, 80.0, TAIL)).is_equal(40.0)

func test_above_matches_the_teachers_placement() -> void:
	var placed := BalloonPlacement.above(Vector2(160, 100), BOX, TAIL, SCREEN, MARGIN)
	assert_vector(placed).is_equal(Vector2(120, 72))
	assert_bool(_inside(BalloonPlacement.above(Vector2(1, 1), BOX, TAIL, SCREEN, MARGIN), BOX, SCREEN)).is_true()

func test_it_shows_the_text_without_stutter_marks_and_is_found() -> void:
	_balloon.say(_anchor, "BARK_GUARDIAN_BLOOM_RETRY", 1)
	assert_bool(_balloon.visible).is_true()
	assert_object(_balloon.speaker()).is_same(_anchor)
	assert_str(_balloon.text_label().text).is_equal(StutterText.strip(tr("BARK_GUARDIAN_BLOOM_RETRY")))
	assert_str(_balloon.text_label().text).not_contains(StutterText.MARK)
	assert_object(BarkBalloon.find(get_tree())).is_same(_balloon)
	assert_bool(get_viewport().get_visible_rect().encloses(_balloon.box_rect())).is_true()
	_balloon.close()
	assert_bool(_balloon.visible).is_false()
	assert_object(_balloon.speaker()).is_null()

func test_it_closes_when_its_speaker_leaves() -> void:
	_balloon.say(_anchor, "BARK_GUARDIAN_FROST_RETRY", -1)
	_anchor.hide()
	await get_tree().process_frame
	await get_tree().process_frame
	assert_bool(_balloon.visible).is_false()

func test_it_keeps_clear_of_the_open_call_sheet() -> void:
	var hud := auto_free(CALL_HUD.instantiate()) as GuardianCallHud
	add_child(hud)
	_balloon.call_hud = hud
	var screen := get_viewport().get_visible_rect().size
	for side: int in [-1, 1]:
		hud.on_call_opened(SONG, 6, Enums.GlyphSet.KEYBOARD_ARROWS, 0, 2, side, 120.0)
		var slot := hud.slot_rect()
		assert_bool(slot.has_area()).is_true()
		# The head just under the slot's middle: the box's natural place is inside the slot.
		_anchor.position = Vector2(slot.get_center().x, slot.end.y - 8.0)
		_balloon.say(_anchor, "BARK_GUARDIAN_BLOOM_LUCID_0", side)
		assert_bool(_balloon.box_rect().intersects(slot)).override_failure_message("side %d: %s in %s" % [
				side, _balloon.box_rect(), slot]).is_false()
		assert_bool(Rect2(Vector2.ZERO, screen).encloses(_balloon.box_rect())).is_true()
