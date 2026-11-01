class_name GuardianFinale extends Node

## The final battle's stages on the mentor's Guardian, a strategy child it hands off to at its seams: the revelation,
## the two-track calls and their dissonance, the final call, the world's restoration (design 02 section 5;
## architecture/grd-06-final-battle). FinaleFight keeps the rules; this node only applies them.

## The revelation's level (0..1) and the dissonance veil (0..1) changed; DissonanceFx draws them.
signal dissonance_changed(veil: float, revelation: float)
## The revelation shattered; every window after it is two-track.
signal revealed

## The grey veil's share at the revelation's peak; the rest of it is the glitch and the silhouette.
const REVELATION_VEIL := 0.6

var _guardian: Guardian
var _stats: FinaleStats
var _finale: FinaleFight
## Real msec when the revelation's call opened.
var _revelation_started: int = 0
var _revelation_notes: int = 0

## Track B's voice, sounding with the guardian's own call (design 02 section 5.3).
@onready var _call_b: PhraseCall = get_node_or_null(^"../CallB") as PhraseCall
@onready var _anchor: Node2D = $"../BarkAnchor"


func _ready() -> void:
	dissonance_changed.connect(_show_dissonance)
	_guardian = get_parent() as Guardian
	_stats = _guardian.stats.finale
	assert(_stats != null and _stats.second_song != null, "%s has a Finale child but no FinaleStats" % _guardian.name)
	_finale = FinaleFight.new(_stats, SaveSystem.is_finale_revealed())
	set_process(false)
	_guardian.call_ended.connect(_on_call_ended)

## Restored when the world is.
func is_restored() -> bool:
	return SaveSystem.is_world_restored()

## The leap landed: opens this window's call, one track or two.
func open_call(player: Player) -> void:
	var fight := _guardian.fight()
	var total := _guardian.stats.cycles_to_restore
	match _finale.open_window():
		FinaleFight.Stage.WINTER:
			player.open_call(_guardian.stats.song, _guardian.stats.revealed_notes, fight.cycles(), total)
		FinaleFight.Stage.REVELATION:
			_revelation_started = Time.get_ticks_msec()
			_revelation_notes = 0
			player.open_call(_guardian.stats.song, 0, fight.cycles(), total, _stats.second_song, false)
			set_process(true)
			_sound_track_b()
		FinaleFight.Stage.DUAL:
			player.open_call(_guardian.stats.song, _stats.dual_revealed, fight.cycles(), total, _stats.second_song)
			_sound_track_b()
	_guardian.call_phrase(_guardian.stats.song)

## The revelation has no window clock ("sem punição real", design 5.1).
func counts_window() -> bool:
	return _finale.stage() != FinaleFight.Stage.REVELATION

## An answer reached the guardian; returns true when the finale took it, false to let the ordinary path run.
func answered(song: Song, player: Player) -> bool:
	match _finale.stage():
		FinaleFight.Stage.WINTER:
			return false
		FinaleFight.Stage.DUAL:
			if song != _guardian.stats.song and song != _stats.second_song:
				return true
			_finale.choose()
			dissonance_changed.emit(0.0, 0.0)
			_bark(&"BARK_MENTOR_FINAL")
			_call_phrase(player)
			return true
		FinaleFight.Stage.FINAL:
			if song != _finale.phrase():
				return true
			if _finale.advance_phrase():
				return false
			_call_phrase(player)
			return true
	return true

## The answer played the other track's note.
func mixed(player: Player) -> void:
	match _finale.stage():
		FinaleFight.Stage.REVELATION:
			_revelation_notes += 1
			dissonance_changed.emit(_revelation_level() * REVELATION_VEIL, _revelation_level())
			if _revelation_notes >= _stats.revelation_notes:
				_shatter(player)
		FinaleFight.Stage.DUAL:
			player.take_dissonance(_finale.mix())
			_guardian.fight().set_drain(_finale.drain())
			dissonance_changed.emit(_finale.veil(), 0.0)

## The last phrase was answered: the world is restored and the save written at once ("Exceção: salva na hora"), then
## the restoration scene plays.
func restored() -> void:
	SaveSystem.restore_world()
	dissonance_changed.emit(0.0, 0.0)
	var director := CutsceneDirector.find(get_tree())
	if director != null and not director.play(_stats.restoration_scene, _guardian):
		push_error("%s: the restoration scene could not start" % _guardian.name)

## The restoration scene plays: the guardian performs through it.
func is_performing() -> bool:
	var director := CutsceneDirector.find(get_tree())
	return director != null and _stats.restoration_scene != null and director.playing() == _stats.restoration_scene

func _process(_delta: float) -> void:
	if _finale.stage() != FinaleFight.Stage.REVELATION or _finale.is_revealed():
		set_process(false)
		return
	dissonance_changed.emit(_revelation_level() * REVELATION_VEIL, _revelation_level())
	if _revelation_level() >= 1.0:
		_shatter(_guardian.fought_player())

func _revelation_level() -> float:
	var by_notes := float(_revelation_notes) / maxf(_stats.revelation_notes, 1)
	var by_time := (Time.get_ticks_msec() - _revelation_started) / 1000.0 / maxf(_stats.revelation_max_seconds, 0.01)
	return clampf(maxf(by_notes, by_time), 0.0, 1.0)

## The peak: a freeze frame, then the fight returns where it stood, two-track from now on.
func _shatter(player: Player) -> void:
	if _finale.is_revealed():
		return
	set_process(false)
	_finale.reveal()
	SaveSystem.mark_finale_revealed()
	_guardian.freeze_frame(_stats.freeze_frame_seconds)
	_guardian.end_lucidity_without_answer()
	if not _stats.revealed_attacks.is_empty():
		_guardian.set_attacks(_stats.revealed_attacks)
	dissonance_changed.emit(0.0, 0.0)
	revealed.emit()

## The next phrase of the final call, alone and fully shown, in the same window.
func _call_phrase(player: Player) -> void:
	var phrase := _finale.phrase()
	if phrase == null:
		return
	player.close_call(true)
	player.open_call(phrase, phrase.notes.size(), _guardian.fight().cycles(), _guardian.stats.cycles_to_restore)
	_guardian.call_phrase(phrase)

func _show_dissonance(veil: float, revelation: float) -> void:
	var player := _guardian.fought_player()
	if player != null:
		player.show_dissonance(veil, revelation)

func _sound_track_b() -> void:
	if _call_b != null:
		_call_b.play(_stats.second_song.notes, _guardian.stats.call_lead_in)

func _bark(key: StringName) -> void:
	var balloon := BarkBalloon.find(get_tree())
	if balloon == null:
		return
	balloon.say(_anchor, String(key), -_guardian.facing, _guardian)
	# Closed at the next phrase's first note, as the landing barks are (GuardianTalks).
	_guardian.call_note_sung.connect(_close_bark.unbind(1), CONNECT_ONE_SHOT)

func _close_bark() -> void:
	var balloon := BarkBalloon.find(get_tree())
	if balloon != null and balloon.speaker() == _anchor:
		balloon.close()

func _on_call_ended() -> void:
	if _call_b != null:
		_call_b.stop()
