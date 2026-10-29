class_name PlayerData extends Resource

@export var unlocked_player_skills: Array[bool]
@export var owned_items: Array[bool]
@export var learned_songs: Array[bool]
@export var restored_guardians: Array[bool]
## Resolved puzzle shortcuts keyed by authored id (docs/design/02_mecanicas.md, section 6.1); song effects are not stored here.
@export var resolved_shortcuts: Array[StringName] = []
## Last rested bench id and room key; empty until the first rest.
@export var bench_id: StringName = &""
@export var bench_room: String = ""
## Region-local death points keyed by region scene key; clustering is handled by `RegionMemory`.
@export var deaths: Dictionary[String, PackedVector2Array] = {}
## Seconds played up to the last commit, menus included.
@export var play_time: float = 0.0
## Translation key of the last rested bench's region; the title shows it.
@export var region_name_key: String = ""
## Unix seconds of the last write to disk; 0 in a save written before it existed. The title continues the latest.
@export var saved_at: int = 0
## Seen map cells per room scene key, as `MapGrid.to_bytes()`; live data that a bench commits and a death forgets.
@export var map_seen: Dictionary[String, PackedByteArray] = {}
## Guardians whose fight has begun, indexed by Enums.Guardian; a restored guardian counts as met too.
@export var met_guardians: Array[bool]
## Notebook entry ids the player has read; a death keeps them (SaveLedger.rewind).
@export var notebook_read: Array[StringName] = []
## Secret spaces opened, by `SecretWall.secret_id`; live data that a bench commits and a death forgets (architecture/secret-false-walls).
@export var found_secrets: Array[StringName] = []
## Found pieces taken, by reward `slot_id`; live data like heard (architecture/found-pieces).
@export var found_pieces: Array[StringName] = []
## Season-seed caches taken, by reward `slot_id`; live data like heard (systems/seeds-and-the-seller).
@export var caches_taken: Array[StringName] = []
## Seller offers bought (MAP and REPLANT), by `SeedOffer.id`; live data like heard.
@export var offers_bought: Array[StringName] = []
## Found-piece slot ids the seller told a rumour of, in the order bought; live data like heard.
@export var rumours: Array[StringName] = []
## Regions whose title has played, by region `SceneKey`; a death keeps them (SaveLedger.rewind).
@export var announced_regions: Array[StringName] = []
## Dialogue ids heard to their end; live data that a bench commits and a death forgets (systems/dialogue).
@export var dialogues_heard: Array[StringName] = []
## The choice id answered to each question, by ask id; asked again, the new answer replaces it. Live data like heard.
@export var responses: Dictionary[StringName, StringName] = {}
## Cutscene ids played or skipped to their end; live data like heard (systems/cutscenes).
@export var scenes_seen: Array[StringName] = []
## Known first halves (notes 1-3) by Enums.Song; live data like learned_songs (architecture/half-songs).
@export var song_first_halves: Array[bool]
## Known second halves (notes 4-6) by Enums.Song.
@export var song_second_halves: Array[bool]
## The Enums.SongHalf Ivo completed by ear, by Enums.Song; NONE when the song was not guessed.
@export var guessed_halves: Array[int]

func _init() -> void:
	migrate()

## Grows flag arrays after loading older saves; enums are append-only, so migration only grows arrays.
func migrate() -> void:
	_grow(unlocked_player_skills, Enums.PlayerSkill.size())
	_grow(owned_items, Enums.PlayerItem.size())
	_grow(learned_songs, Enums.Song.size())
	_grow(restored_guardians, Enums.Guardian.size())
	_grow(met_guardians, Enums.Guardian.size())
	_grow(song_first_halves, Enums.Song.size())
	_grow(song_second_halves, Enums.Song.size())
	if guessed_halves.size() < Enums.Song.size():
		guessed_halves.resize(Enums.Song.size())

func _grow(flags: Array[bool], size: int) -> void:
	if flags.size() < size:
		flags.resize(size)
