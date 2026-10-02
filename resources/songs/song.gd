class_name Song extends Resource

## Song data; world responses belong to SongReceiver.

## Must match the note-slot count in MemorinaHud; SongCatalog validates it.
const NOTE_COUNT := 6
## Seconds the fallback cues span when there is no excerpt duration to use.
const DEFAULT_CUE_WINDOW := 6.0

@export var id: Enums.Song = Enums.Song.FREEZE
@export var palette: SeasonPalette
## Ordered notes; no sequence may prefix another (SongCatalog validates this).
@export var notes: Array[Enums.Note] = []
## Translation key for the song's effect.
@export var name_key: String = ""
## Translation key for the title shown when the player learns the song.
@export var title_key: String = ""
@export var pulse_stats: PulseStats
## Optional effect scene mounted under ColorPulse; world responses are handled by receivers.
@export var pulse_effect: PackedScene

@export_group("Performance")
## The full piece, heard once, when the song is learned.
@export var track: AudioStream
## What is heard after the sequence is played in the world. Null means the
## track itself, cut at excerpt_duration. A dedicated excerpt must begin at
## the same instant as the track so note_cues stays valid for both.
@export var excerpt: AudioStream
## Seconds played before the excerpt cut; 0 plays the full stream.
@export var excerpt_duration: float = 7.0
## Fade duration, in seconds.
@export var excerpt_fade: float = 0.5
## Optional per-note cue times in seconds, tuned to the audio; empty uses evenly spaced cues.
@export var note_cues: PackedFloat32Array = []

func season() -> Enums.Season:
	return palette.season

func tint() -> Color:
	return palette.tint

## The stream a world performance plays: the excerpt when one is authored,
## the track otherwise.
func performance_stream() -> AudioStream:
	return excerpt if excerpt != null else track

## The cue times to light the sheet by: the authored ones when they are
## present, otherwise the notes spread evenly across the excerpt so an
## untuned (or editor-stripped) song still lights up in order.
func cues() -> PackedFloat32Array:
	if note_cues.size() == notes.size():
		return note_cues
	var window := excerpt_duration if excerpt_duration > 0.0 else DEFAULT_CUE_WINDOW
	var spread := PackedFloat32Array()
	for i: int in notes.size():
		spread.append(window * (i + 1) / float(notes.size() + 1))
	return spread
