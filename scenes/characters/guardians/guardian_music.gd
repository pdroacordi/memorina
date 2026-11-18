class_name GuardianMusic
extends Node
## Asks Music for the guardian's fight music at each turn of the fight; never plays audio itself
## (architecture/music-system, "Wiring for the final battle").

## How far the music sinks while a call is open, dB ("segue, só abaixa, mas mais do que apenas 6db", user, 2026-11-18).
const CALL_DUCK_DB := -12.0
const CALL_DUCK := &"call"
## Real seconds the spring layer takes to rise at the revelation and to fade once a track is chosen.
const SPRING_RISE := 4.0
const SPRING_FADE := 2.0

var _guardian: Guardian
var _fight_request: MusicRequest
var _hushed: bool = false


func _ready() -> void:
	_guardian = get_parent() as Guardian
	assert(_guardian != null, "GuardianMusic must be a Guardian's child")
	_guardian.phase_changed.connect(_on_phase_changed)
	_guardian.lucid_landed.connect(_on_lucid_landed.unbind(2))
	_guardian.call_ended.connect(_on_call_ended)
	_guardian.restored.connect(_on_restored.unbind(1))
	var finale := _guardian.get_node_or_null(^"Finale") as GuardianFinale
	if finale != null:
		finale.revelation_opened.connect(_on_revelation_opened)
		finale.track_chosen.connect(_on_track_chosen)
		finale.freeze_frame_began.connect(_on_freeze_frame)

func _exit_tree() -> void:
	if _hushed:
		Music.unhush()

func _on_phase_changed(from: GuardianFight.Phase, to: GuardianFight.Phase) -> void:
	if from != GuardianFight.Phase.DORMANT or to != GuardianFight.Phase.PRESSURE or _guardian.stats.music == null:
		return
	_fight_request = Music.request(_guardian.stats.music, MusicRequest.Layer.FIGHT, self)
	# A save that has seen the revelation fights two-track from the start.
	if _guardian.stats.finale != null and SaveSystem.is_finale_revealed():
		Music.set_stem(_fight_request, &"spring", 1.0, 0.0)

func _on_lucid_landed() -> void:
	Music.set_stem(_fight_request, &"lead", 0.0, 0.3)
	Music.duck(CALL_DUCK, CALL_DUCK_DB, self)

func _on_call_ended() -> void:
	Music.set_stem(_fight_request, &"lead", 1.0, 1.0)
	Music.unduck(CALL_DUCK)

func _on_revelation_opened() -> void:
	Music.set_stem(_fight_request, &"spring", 1.0, SPRING_RISE)

func _on_freeze_frame(seconds: float) -> void:
	_hushed = true
	Music.hush()
	# Real time, and running while the freeze frame holds the tree.
	await get_tree().create_timer(seconds, true, false, true).timeout
	_hushed = false
	Music.unhush()

## The fight loop plays through the final call, ducked with its lead out ("a música de luta deve ser um loop
## enquanto há luta", user, 2026-11-18).
func _on_track_chosen() -> void:
	Music.set_stem(_fight_request, &"spring", 0.0, SPRING_FADE)

func _on_restored() -> void:
	Music.unduck(CALL_DUCK)
	Music.release(_fight_request, 0.5)
	_fight_request = null
