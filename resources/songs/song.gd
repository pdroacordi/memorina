class_name Song extends Resource

## One note sequence. Pure data: it knows what the player must play, what
## season it belongs to and how its pulse behaves, and nothing about who
## listens or what happens in the world - that is SongReceiver's job.

@export var id: Enums.Song = Enums.Song.FREEZE
@export var palette: SeasonPalette
## The sequence, in order. No song's notes may be a prefix of another's or the
## longer one becomes unreachable; SongCatalog.validate() enforces that.
@export var notes: Array[Enums.Note] = []
## Translation key for the song's displayed name. Never a literal.
@export var name_key: String = ""
@export var pulse_stats: PulseStats

func season() -> Enums.Season:
	return palette.season

func tint() -> Color:
	return palette.tint
