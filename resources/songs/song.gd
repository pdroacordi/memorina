class_name Song extends Resource

## One note sequence. Pure data: it knows what the player must play, what
## season it belongs to, how it sounds and how its pulse behaves, and nothing
## about who listens or what happens in the world - that is SongReceiver's job.

## Every song is exactly this long; the sheet in MemorinaHud has this many
## slots. SongCatalog.validate() enforces it.
const NOTE_COUNT := 6
## Seconds the fallback cues span when there is no excerpt duration to use.
const DEFAULT_CUE_WINDOW := 6.0

@export var id: Enums.Song = Enums.Song.FREEZE
@export var palette: SeasonPalette
## The sequence, in order. No song's notes may be a prefix of another's or the
## longer one becomes unreachable; SongCatalog.validate() enforces that.
@export var notes: Array[Enums.Note] = []
## Translation key for the song's effect ("Freeze"). Never a literal.
@export var name_key: String = ""
## Translation key for the piece's title ("Hymn of Frost"), the name the
## player learns it by. Distinct from name_key, which names what it does.
@export var title_key: String = ""
@export var pulse_stats: PulseStats

@export_group("Performance")
## The full piece, heard once, when the song is learned.
@export var track: AudioStream
## What is heard after the sequence is played in the world. Null means the
## track itself, cut at excerpt_duration. A dedicated excerpt must begin at
## the same instant as the track so note_cues stays valid for both.
@export var excerpt: AudioStream
## Seconds of performance_stream() heard in the world before the cut. 0 plays
## it whole.
@export var excerpt_duration: float = 7.0
## Seconds over which the cut fades out.
@export var excerpt_fade: float = 0.5
## Seconds into the track at which each of the motif's notes sounds, one per
## note, ascending. The sheet lights the matching slot as playback crosses
## each. Hand-tuned against the audio. Optional: leave it empty and cues()
## spaces the notes evenly across the excerpt, a placeholder until it is tuned.
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
