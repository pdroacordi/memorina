class_name PlayerFoundTest extends GdUnitTestSuite

## Up takes a found piece in reach once, under the pickups' gates; a songbook teaches its second half first and is
## taken only if the half was taught.

const IVO := preload("res://scenes/characters/ivo/ivo.tscn")
const PICKUP := preload("res://scenes/world/interactables/found_pickup/found_pickup.tscn")
const LETTER := preload("res://assets/sprites/world/pickups/letter.png")
const BOOK := preload("res://assets/sprites/world/pickups/songbook.png")
const BELL_JAR := preload("res://resources/songs/bell_jar.tres")

## Top of the test floor.
const FLOOR_Y := 30.0

var _holder: Node2D
var _ivo: Player
var _found: FoundPickup


func before_test() -> void:
	SaveSystem.begin("", true)
	_holder = auto_free(Node2D.new()) as Node2D
	add_child(_holder)
	var floor_body := StaticBody2D.new()
	floor_body.collision_layer = 2
	floor_body.position = Vector2(0, FLOOR_Y + 10.0)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(4000, 20)
	shape.shape = rect
	floor_body.add_child(shape)
	_holder.add_child(floor_body)

func after_test() -> void:
	SaveSystem.begin("", true)

func _place(slot_id: StringName, texture: Texture2D, song: Song) -> void:
	var piece := FoundPiece.new()
	piece.slot_id = slot_id
	piece.texture = texture
	piece.song = song
	_found = PICKUP.instantiate() as FoundPickup
	_found.piece = piece
	_found.position = Vector2(0, FLOOR_Y)
	_holder.add_child(_found)
	_ivo = IVO.instantiate() as Player
	_ivo.position = Vector2(0, -60)
	_holder.add_child(_ivo)

func _press_up() -> void:
	(_ivo.get_node("PlayerInput") as PlayerInput).look_up_pressed.emit()
	await _frames(3)

func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame

func _land() -> void:
	for i: int in 120:
		await get_tree().physics_frame
		if _ivo.is_on_floor() and _ivo.is_still():
			return
	fail("Ivo never landed on the test floor")

func test_up_takes_a_letter_once() -> void:
	_place(&"woods_hut_letter", LETTER, null)
	var taken: Array[StringName] = []
	_found.taken.connect(func(slot_id: StringName) -> void: taken.append(slot_id))
	await _land()
	await _press_up()
	assert_bool(SaveSystem.has_found(&"woods_hut_letter")).is_true()
	assert_bool(_found.is_lying()).is_false()
	await _press_up()
	assert_array(taken).is_equal([&"woods_hut_letter"])

func test_up_in_the_air_does_not_take_it() -> void:
	_place(&"woods_hut_letter", LETTER, null)
	await _land()
	(_ivo.get_node("PlayerInput") as PlayerInput).jump_pressed.emit()
	await _frames(4)
	assert_bool(_ivo.is_on_floor()).is_false()
	await _press_up()
	assert_bool(SaveSystem.has_found(&"woods_hut_letter")).is_false()

func test_a_songbook_teaches_its_second_half_and_is_taken() -> void:
	SaveSystem.set_item_owned(Enums.PlayerItem.MEMORINA, true)
	_place(&"woods_root_caves_alcove", BOOK, BELL_JAR)
	await _land()
	await _press_up()
	assert_bool(SaveSystem.knows_song_half(Enums.Song.BELL_JAR, Enums.SongHalf.SECOND)).is_true()
	assert_bool(SaveSystem.has_found(&"woods_root_caves_alcove")).is_true()
	assert_bool(_found.is_lying()).is_false()

## The half that completes the song plays a full lesson.
func test_a_songbook_that_completes_the_song_is_a_lesson() -> void:
	SaveSystem.set_item_owned(Enums.PlayerItem.MEMORINA, true)
	SaveSystem.learn_song_half(Enums.Song.BELL_JAR, Enums.SongHalf.FIRST)
	_place(&"woods_root_caves_alcove", BOOK, BELL_JAR)
	await _land()
	await _press_up()
	assert_bool(SaveSystem.player_data.learned_songs[Enums.Song.BELL_JAR]).is_true()
	assert_bool(_ivo.is_in_lesson()).is_true()

## No instrument, no lesson: the book stays and the press is spent.
func test_without_the_memorina_the_book_stays() -> void:
	SaveSystem.set_item_owned(Enums.PlayerItem.MEMORINA, false)
	_place(&"woods_root_caves_alcove", BOOK, BELL_JAR)
	await _land()
	await _press_up()
	assert_bool(SaveSystem.knows_song_half(Enums.Song.BELL_JAR, Enums.SongHalf.SECOND)).is_false()
	assert_bool(SaveSystem.has_found(&"woods_root_caves_alcove")).is_false()
	assert_bool(_found.is_lying()).is_true()
