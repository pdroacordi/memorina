class_name SpawnArtTest extends GdUnitTestSuite

## A spawn's strip: rise stages reach the last frame only when whole, a loop runs on the scaled time given, and a frame
## lands bottom-centre on the 2 px art grid (systems/guardians, GRD-18).

const SPIKE := "res://assets/sprites/characters/guardians/bloom_guardian/effects/bloom_thorn_spike.png"


func test_a_rise_picks_its_stage_and_nothing_at_zero() -> void:
	assert_int(SpawnArt.stage_of(0.0, 4)).is_equal(-1)
	assert_int(SpawnArt.stage_of(-0.5, 4)).is_equal(-1)
	assert_int(SpawnArt.stage_of(0.01, 4)).is_equal(0)
	assert_int(SpawnArt.stage_of(0.3, 3)).is_equal(0)
	assert_int(SpawnArt.stage_of(0.45, 4)).is_equal(1)
	assert_int(SpawnArt.stage_of(0.75, 4)).is_equal(2)
	assert_int(SpawnArt.stage_of(0.76, 4)).is_equal(3)
	assert_int(SpawnArt.stage_of(1.0, 4)).is_equal(3)
	assert_int(SpawnArt.stage_of(1.5, 4)).is_equal(3)
	assert_int(SpawnArt.stage_of(1.0, 0)).is_equal(-1)

func test_a_loop_runs_on_the_time_given() -> void:
	var art := _art(4)
	art.fps = 10.0
	assert_int(art.loop_frame(0.0)).is_equal(0)
	assert_int(art.loop_frame(0.15)).is_equal(1)
	assert_int(art.loop_frame(0.45)).is_equal(0)
	art.fps = 0.0
	assert_int(art.loop_frame(0.45)).is_equal(0)

func test_a_frame_lands_bottom_centre_on_the_art_grid() -> void:
	var art := _art(4)
	assert_vector(art.frame_size()).is_equal(Vector2(12.0, 28.0))
	assert_that(art.frame_rect(Vector2(10.0, 0.0), false)).is_equal(Rect2(4.0, -28.0, 12.0, 28.0))
	# Half a game px off the grid snaps to the nearest art px, never between.
	var odd := art.frame_rect(Vector2(10.6, 0.4), false)
	assert_float(fposmod(odd.position.x, 2.0)).is_equal(0.0)
	assert_float(fposmod(odd.position.y, 2.0)).is_equal(0.0)
	# Mirrored: the same position with a negative width, which the renderer flips in place over x..x+w
	# (gotchas/a-negative-width-texture-rect-flips-in-place-at-its-position).
	var flipped := art.frame_rect(Vector2(10.0, 0.0), true)
	assert_that(flipped).is_equal(Rect2(4.0, -28.0, -12.0, 28.0))

func test_no_texture_has_no_size() -> void:
	assert_vector(SpawnArt.new().frame_size()).is_equal(Vector2.ZERO)

func _art(frames: int) -> SpawnArt:
	var art := SpawnArt.new()
	art.texture = load(SPIKE) as Texture2D
	art.frames = frames
	return art
