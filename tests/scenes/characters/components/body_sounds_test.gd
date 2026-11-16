class_name BodySoundsTest extends GdUnitTestSuite

## A creature's body sounds through Enemy's wiring: a wound plays struck, a killing hit death alone, a guarded hit
## blocked; the voices are positional (systems/sound-effects).

const BOAR := "res://scenes/characters/creatures/boar/boar.tscn"
const CRAB := "res://scenes/characters/creatures/crab/crab.tscn"

var _played: Array[SoundCue] = []


func before_test() -> void:
	_played.clear()

func _spawn(path: String) -> Enemy:
	var enemy := (load(path) as PackedScene).instantiate() as Enemy
	enemy.position = Vector2(200, 100)
	add_child(enemy)
	auto_free(enemy)
	var sounds := enemy.get_node(^"BodySounds") as BodySounds
	sounds.emitter().cue_played.connect(func(cue: SoundCue) -> void: _played.append(cue))
	return enemy

func test_the_stats_reach_body_sounds_and_voices_are_positional() -> void:
	var boar := _spawn(BOAR)
	var sounds := boar.get_node(^"BodySounds") as BodySounds
	assert_object(sounds.sounds).is_same(boar.stats.sounds)
	assert_bool(sounds.emitter().positional).is_true()

func test_a_wound_plays_struck() -> void:
	var boar := _spawn(BOAR)
	boar.hurtbox.hit_received.emit(1, Vector2.ZERO, null)
	assert_bool(boar.is_dead()).is_false()
	assert_array(_played).contains_exactly([boar.stats.sounds.struck])

func test_a_killing_hit_plays_death_not_struck() -> void:
	var boar := _spawn(BOAR)
	boar.hurtbox.hit_received.emit(boar.health.max_hp * 10, Vector2.ZERO, null)
	assert_bool(boar.is_dead()).is_true()
	assert_array(_played).contains_exactly([boar.stats.sounds.death])

func test_a_guarded_hit_plays_blocked() -> void:
	var crab := _spawn(CRAB)
	var source := auto_free(Node2D.new()) as Node2D
	add_child(source)
	source.global_position = crab.body_rect().get_center() + Vector2(40.0 * crab.facing, 0.0)
	crab.hurtbox.hit_received.emit(1, Vector2.ZERO, source)
	assert_int(crab.health.current_hp).is_equal(crab.health.max_hp)
	assert_array(_played).contains_exactly([crab.stats.sounds.blocked])
