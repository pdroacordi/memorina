class_name IvoSheetTest extends GdUnitTestSuite

## Ivo's 2x sheets fit his clips and his body (docs/knowledge/architecture/ivo-at-2x.md).

const IVO := preload("res://scenes/characters/ivo/ivo.tscn")
const PALETTE := "res://tools/art/sources/ivo/ivo_palette.png"
## A sheet where Ivo holds a prop may also use the colours its contract snaps to: the prop's, or its still's.
const HELD_PROPS := {
	"ivo_guitar.png": "res://assets/sprites/world/props/interiors/ivo_house/guitar.png",
	"ivo_memorina_play.png": "res://tools/art/sources/story/ivo_memorina_still_2x.png",
	"ivo_memorina_lower.png": "res://tools/art/sources/story/ivo_memorina_still_2x.png",
}
const FRAME := 128
## Game px: the feet end on the row above the floor line (row 96).
const FEET_ROW := 95
## Game px: Sprite2D is centred, so flip_h mirrors a 128 px frame about this column.
const FLIP_AXIS := 63.5
## Game px: the body capsule's front edge (radius 11) in the frame.
const WALL_COLUMN := 75
## Game px (2 art px): how far a clip's body centroid may sit off the flip axis.
const CENTRE_TOLERANCE := 4.0
## Game px (2 art px): how far an attack's body may move between two frames, so a swing never slides or pops.
const STEADY_TOLERANCE := 4.0
const GROUNDED: Array[StringName] = [
	&"idle", &"run", &"brace", &"land", &"hurt", &"sit", &"death", &"memorina_draw", &"memorina_idle", &"memorina_lower",
	&"idle_attack_swing_in", &"idle_attack_swing_out", &"run_attack_swing_in", &"run_attack_swing_out",
	&"guitar_hold", &"guitar_strum",
]
## Sheet frames in flight, both boots off the floor 1-3 art px; the running attack keeps the run's legs.
const FLIGHT := {&"run": [3, 4, 7], &"run_attack_swing_in": [3, 4], &"run_attack_swing_out": [7]}
## Game px: how far a flight frame's lowest row may sit above the feet row.
const FLIGHT_LIFT := Vector2i(2, 6)
const CENTRED: Array[StringName] = [
	&"idle", &"run", &"brace", &"jump_start", &"jump_idle", &"fall_start", &"fall_idle", &"air_spin", &"land",
	&"hurt", &"roll", &"sit", &"climb", &"climb_back", &"death",
]
## Measured on the feet (rows 80-95), where no blade or trail passes; the running attacks are measured on the torso (their legs are the run's stride).
const GROUND_ATTACKS: Array[StringName] = [
	&"idle_attack_swing_in", &"idle_attack_swing_out", &"run_attack_swing_in", &"run_attack_swing_out",
]
## Measured on the head and torso (rows 40-69), above the air slash's trail and the pogo blade.
const AIR_ATTACKS: Array[StringName] = [&"jump_attack", &"fall_attack", &"air_downwards_attack"]
## Sword clips whose Hitbox reaches forward, and the pogo, whose Hitbox reaches below the feet.
const FORWARD_SWINGS: Array[StringName] = [
	&"idle_attack_swing_in", &"idle_attack_swing_out", &"run_attack_swing_in", &"run_attack_swing_out", &"jump_attack",
	&"fall_attack",
]
const DOWNWARD_SWINGS: Array[StringName] = [&"air_downwards_attack"]
## Game px: how far a keyed Hitbox edge may sit from the drawn steel's (the keys are rounded to 4 decimals).
const BOX_TOLERANCE := 1.0
## Game px: the frame's top-left corner in Ivo's space (Sprite2D centred at (0, -32)).
const FRAME_ORIGIN := Vector2(-64, -96)
## Exempt from centring: they face the wall and put the front on the capsule edge instead.
const WALL: Array[StringName] = [&"wall_landing", &"wall_slide"]
## The blade's colours, left out of an attack's body centroid.
const STEEL: Array[Color] = [Color8(98, 106, 112), Color8(150, 160, 166), Color8(200, 208, 210), Color8(234, 240, 240)]
## Seconds; the 2x sheets kept every clip's timing but the Memorina's, redrawn in STORY-11.
const LENGTHS := {
	&"idle": 0.8333333, &"run": 0.6666667, &"brace": 1.0, &"jump_start": 0.25, &"jump_idle": 0.083333336,
	&"fall_start": 0.25, &"fall_idle": 0.083333336, &"air_spin": 0.5, &"land": 0.75, &"wall_landing": 0.5,
	&"wall_slide": 1.0, &"roll": 0.5833333, &"hurt": 0.33333334, &"death": 0.8333333, &"sit": 1.0,
	&"climb": 0.6, &"climb_hold": 0.1, &"climb_back": 0.6, &"climb_back_hold": 0.1, &"memorina_draw": 0.33333334,
	&"memorina_idle": 1.0, &"memorina_lower": 0.33333334, &"idle_attack_swing_in": 0.41666666, &"idle_attack_swing_out": 0.33333334,
	&"run_attack_swing_in": 0.41666666, &"run_attack_swing_out": 0.33333334, &"jump_attack": 0.33333334,
	&"fall_attack": 0.33333334, &"air_downwards_attack": 0.5,
}

var _library: AnimationLibrary
var _ivo: Node
var _images := {}


func before() -> void:
	_ivo = IVO.instantiate()
	_library = (_ivo.get_node("AnimationPlayer") as AnimationPlayer).get_animation_library(&"")

func after() -> void:
	_ivo.free()

func test_every_sheet_is_its_frame_count_of_128_px_frames() -> void:
	var problems := PackedStringArray()
	for clip: StringName in _sprite_clips():
		var size := _image(clip).get_size()
		if size != Vector2i(_hframes(clip) * FRAME, FRAME):
			problems.append("%s: sheet %s for %d frames" % [clip, size, _hframes(clip)])
	assert_array(Array(problems)).is_empty()

func test_no_frame_key_reaches_hframes() -> void:
	var problems := PackedStringArray()
	for clip: StringName in _sprite_clips():
		for frame: int in _frames(clip):
			if frame < 0 or frame >= _hframes(clip):
				problems.append("%s: frame %d of %d" % [clip, frame, _hframes(clip)])
	assert_array(Array(problems)).is_empty()

func test_texture_and_hframes_are_keyed_before_frame() -> void:
	var problems := PackedStringArray()
	for clip: StringName in _sprite_clips():
		var animation := _library.get_animation(clip)
		var frame := animation.find_track(^"Sprite2D:frame", Animation.TYPE_VALUE)
		if animation.find_track(^"Sprite2D:texture", Animation.TYPE_VALUE) > frame \
				or animation.find_track(^"Sprite2D:hframes", Animation.TYPE_VALUE) > frame:
			problems.append(String(clip))
	assert_array(Array(problems)).is_empty()

func test_clip_lengths_are_unchanged() -> void:
	for clip: StringName in LENGTHS:
		assert_float(_library.get_animation(clip).length).override_failure_message(String(clip)) \
			.is_equal_approx(LENGTHS[clip], 0.0001)

func test_grounded_clips_stand_on_the_floor_line() -> void:
	var problems := PackedStringArray()
	for clip: StringName in GROUNDED:
		for frame: int in _frames(clip):
			var lift := FEET_ROW - (_used(clip, frame).end.y - 1)
			var flying: bool = frame in FLIGHT.get(clip, [])
			if (flying and (lift < FLIGHT_LIFT.x or lift > FLIGHT_LIFT.y)) or (not flying and lift != 0):
				problems.append("%s frame %d: lowest row %d" % [clip, frame, FEET_ROW - lift])
	assert_array(Array(problems)).is_empty()

func test_body_clips_are_centred() -> void:
	var problems := PackedStringArray()
	for clip: StringName in CENTRED:
		problems.append_array(_off_axis(clip, 0, FRAME))
	for clip: StringName in GROUND_ATTACKS:
		# A running attack's legs are the run's stride, centred with the run; its head and torso are measured.
		var band := Vector2i(40, 70) if String(clip).begins_with("run_") else Vector2i(80, 96)
		problems.append_array(_off_axis(clip, band.x, band.y))
	for clip: StringName in AIR_ATTACKS:
		problems.append_array(_off_axis(clip, 40, 70))
	assert_array(Array(problems)).is_empty()

func test_attack_bodies_hold_still_between_frames() -> void:
	var problems := PackedStringArray()
	for clip: StringName in GROUND_ATTACKS + AIR_ATTACKS:
		# A running attack's legs keep the run cycle's stride, so its upper body is what must hold still.
		var standing := clip in GROUND_ATTACKS and not String(clip).begins_with("run_")
		var band := Vector2i(80, 96) if standing else Vector2i(40, 70)
		var frames := _frames(clip)
		for i: int in range(1, frames.size()):
			var shift := _centroid_x(clip, frames[i], band.x, band.y) - _centroid_x(clip, frames[i - 1], band.x, band.y)
			if absf(shift) > STEADY_TOLERANCE:
				problems.append("%s frames %d-%d: body moves %.1f px" % [clip, frames[i - 1], frames[i], shift])
	assert_array(Array(problems)).is_empty()

## The Hitbox each sword clip keys is the box its hit-window frames' steel covers: a forward swing from the body centre
## to the steel's front, as high as the steel in front of the centre; the pogo as wide as the steel, from the feet to
## the blade's point (features/ivo-sword-attacks-from-key-poses, CORE-11).
func test_every_swing_reaches_exactly_as_far_as_its_drawn_steel() -> void:
	var problems := PackedStringArray()
	for clip: StringName in FORWARD_SWINGS + DOWNWARD_SWINGS:
		var forward := clip in FORWARD_SWINGS
		var steel := _window_steel(clip, forward)
		var expected := Rect2(0.0, steel.position.y, steel.end.x, steel.size.y) if forward \
				else Rect2(steel.position.x, 0.0, steel.size.x, steel.end.y)
		for box: Rect2 in _window_boxes(clip):
			if not _same_rect(box, expected):
				problems.append("%s: Hitbox %s, steel asks %s" % [clip, box, expected])
				break
	assert_array(Array(problems)).is_empty()

func test_wall_clips_meet_the_wall_at_the_capsule_edge() -> void:
	var problems := PackedStringArray()
	for clip: StringName in WALL:
		for frame: int in _frames(clip):
			var front := _used(clip, frame).end.x - 1
			if absi(front - WALL_COLUMN) > 2:
				problems.append("%s frame %d: front %d" % [clip, frame, front])
	assert_array(Array(problems)).is_empty()

func test_no_frame_touches_its_border() -> void:
	var problems := PackedStringArray()
	for clip: StringName in _sprite_clips():
		for frame: int in range(_hframes(clip)):
			var used := _used(clip, frame)
			if used.position.x <= 0 or used.position.y <= 0 or used.end.x >= FRAME or used.end.y >= FRAME:
				problems.append("%s frame %d: %s" % [clip, frame, used])
	assert_array(Array(problems)).is_empty()

func test_every_colour_is_from_the_palette() -> void:
	var palette := {}
	var strip := Image.load_from_file(ProjectSettings.globalize_path(PALETTE))
	for x: int in strip.get_width():
		palette[strip.get_pixel(x, 0).to_rgba32()] = true
	var strays := {}
	var seen := {}
	for clip: StringName in _sprite_clips():
		var image := _image(clip)
		if seen.has(image):
			continue
		seen[image] = true
		var allowed := palette.duplicate()
		var file := _texture(clip).resource_path.get_file()
		if HELD_PROPS.has(file):
			var prop := Image.load_from_file(ProjectSettings.globalize_path(HELD_PROPS[file]))
			prop.convert(Image.FORMAT_RGBA8)
			for y: int in prop.get_height():
				for x: int in prop.get_width():
					var colour := prop.get_pixel(x, y)
					if colour.a8 == 0:
						continue
					allowed[colour.to_rgba32() | 0xff] = true
		var data := image.get_data()
		for i: int in range(0, data.size(), 4):
			if data[i + 3] == 0:
				continue
			var rgba := (data[i] << 24) | (data[i + 1] << 16) | (data[i + 2] << 8) | 0xff
			if not allowed.has(rgba):
				strays["%s %x" % [_texture(clip).resource_path.get_file(), rgba]] = true
	assert_array(strays.keys()).is_empty()

func test_the_body_is_the_capsule_the_rooms_were_built_for() -> void:
	var shape_node := _ivo.get_node("CollisionShape2D") as CollisionShape2D
	var capsule := shape_node.shape as CapsuleShape2D
	assert_float(capsule.radius).is_equal(11.0)
	assert_float(capsule.height).is_equal(54.0)
	assert_int(ceili(capsule.height / 32.0)).is_equal(2)
	assert_vector(shape_node.position).is_equal(Vector2(0, -27))

func test_the_jumps_still_clear_the_same_gaps() -> void:
	# px; the redraw keeps the capsule (r 11) and the jump stats, so these are the template body's numbers.
	var reach := MapGuide.ivo_reach()
	assert_float(reach.peak()).is_equal_approx(143.16, 0.01)
	assert_float(reach.peak(true)).is_equal_approx(270.48, 0.01)
	assert_float(reach.gap()).is_equal_approx(271.60, 0.01)
	assert_float(reach.gap(true)).is_equal_approx(434.80, 0.01)

func _sprite_clips() -> Array[StringName]:
	var clips: Array[StringName] = []
	for clip: StringName in _library.get_animation_list():
		if _library.get_animation(clip).find_track(^"Sprite2D:frame", Animation.TYPE_VALUE) >= 0:
			clips.append(clip)
	return clips

func _key_values(clip: StringName, path: NodePath) -> Array:
	var animation := _library.get_animation(clip)
	var track := animation.find_track(path, Animation.TYPE_VALUE)
	if track < 0:
		animation = _library.get_animation(&"RESET")
		track = animation.find_track(path, Animation.TYPE_VALUE)
	var values := []
	for key: int in animation.track_get_key_count(track):
		values.append(animation.track_get_key_value(track, key))
	return values

## The value a clip's track (or RESET's, if the clip keys none) holds at `at` s, read as its last key at or before.
func _keyed_at(clip: StringName, path: NodePath, at: float, fallback: Variant) -> Variant:
	for animation: Animation in [_library.get_animation(clip), _library.get_animation(&"RESET")]:
		var track := animation.find_track(path, Animation.TYPE_VALUE)
		if track < 0:
			continue
		var value: Variant = animation.track_get_key_value(track, 0)
		for key: int in animation.track_get_key_count(track):
			if animation.track_get_key_time(track, key) <= at + 0.0005:
				value = animation.track_get_key_value(track, key)
		return value
	return fallback

## The times, in s, sampled each physics frame while the clip keeps the Hitbox monitoring.
func _window_times(clip: StringName) -> Array[float]:
	var animation := _library.get_animation(clip)
	var times: Array[float] = []
	var at := 0.001
	while at < animation.length:
		if _keyed_at(clip, ^"Hitbox:monitoring", at, false):
			times.append(at)
		at += 1.0 / 60.0
	return times

## The steel shown during the hit window, in Ivo's space; a forward swing counts only the steel in front of his centre.
func _window_steel(clip: StringName, forward: bool) -> Rect2:
	var steel := {}
	for colour: Color in STEEL:
		steel[colour.to_rgba32() | 0xff] = true
	var frames := {}
	for at: float in _window_times(clip):
		frames[_keyed_at(clip, ^"Sprite2D:frame", at, 0)] = true
	var found := Rect2()
	var any := false
	for frame: int in frames:
		var data := _image(clip).get_region(Rect2i(frame * FRAME, 0, FRAME, FRAME)).get_data()
		for i: int in range(0, data.size(), 4):
			if data[i + 3] == 0 or not steel.has((data[i] << 24) | (data[i + 1] << 16) | (data[i + 2] << 8) | 0xff):
				continue
			var pixel := Rect2(FRAME_ORIGIN + Vector2((i >> 2) % FRAME, (i >> 2) / FRAME), Vector2.ONE)
			if forward and pixel.position.x < 0.0:
				continue
			found = found.merge(pixel) if any else pixel
			any = true
	return found

## The keyed Hitbox capsule's bounding box at each sampled moment of the hit window, in Ivo's space facing east.
func _window_boxes(clip: StringName) -> Array[Rect2]:
	var node := _ivo.get_node(^"Hitbox/CollisionShape2D") as CollisionShape2D
	var capsule := node.shape as CapsuleShape2D
	var boxes: Array[Rect2] = []
	for at: float in _window_times(clip):
		var radius: float = _keyed_at(clip, ^"Hitbox/CollisionShape2D:shape:radius", at, capsule.radius)
		var scale: Vector2 = _keyed_at(clip, ^"Hitbox/CollisionShape2D:scale", at, node.scale)
		var centre: Vector2 = _keyed_at(clip, ^"Hitbox/CollisionShape2D:position", at, node.position)
		var half := Vector2(radius * scale.x, capsule.height * scale.y / 2.0)
		boxes.append(Rect2(centre - half, half * 2.0))
	return boxes

func _same_rect(a: Rect2, b: Rect2) -> bool:
	return absf(a.position.x - b.position.x) <= BOX_TOLERANCE and absf(a.position.y - b.position.y) <= BOX_TOLERANCE \
			and absf(a.end.x - b.end.x) <= BOX_TOLERANCE and absf(a.end.y - b.end.y) <= BOX_TOLERANCE

func _texture(clip: StringName) -> Texture2D:
	return _key_values(clip, ^"Sprite2D:texture")[0]

func _hframes(clip: StringName) -> int:
	return _key_values(clip, ^"Sprite2D:hframes")[0]

func _frames(clip: StringName) -> Array:
	return _key_values(clip, ^"Sprite2D:frame")

func _image(clip: StringName) -> Image:
	var path := _texture(clip).resource_path
	if not _images.has(path):
		_images[path] = Image.load_from_file(ProjectSettings.globalize_path(path))
	return _images[path]

func _used(clip: StringName, frame: int) -> Rect2i:
	return _image(clip).get_region(Rect2i(frame * FRAME, 0, FRAME, FRAME)).get_used_rect()

func _off_axis(clip: StringName, top: int, bottom: int) -> PackedStringArray:
	var found := PackedStringArray()
	for frame: int in _frames(clip):
		var centre := _centroid_x(clip, frame, top, bottom)
		if absf(centre - FLIP_AXIS) > CENTRE_TOLERANCE:
			found.append("%s frame %d: centre %.1f" % [clip, frame, centre])
	return found

## Centroid column of the frame's opaque non-steel pixels in rows top..bottom-1.
func _centroid_x(clip: StringName, frame: int, top: int, bottom: int) -> float:
	var steel := {}
	for colour: Color in STEEL:
		steel[colour.to_rgba32() | 0xff] = true
	var data := _image(clip).get_region(Rect2i(frame * FRAME, top, FRAME, bottom - top)).get_data()
	var total := 0.0
	var count := 0
	for i: int in range(0, data.size(), 4):
		if data[i + 3] == 0 or steel.has((data[i] << 24) | (data[i + 1] << 16) | (data[i + 2] << 8) | 0xff):
			continue
		total += (i >> 2) % FRAME
		count += 1
	return total / maxi(count, 1)
