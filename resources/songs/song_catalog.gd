class_name SongCatalog extends Resource

## Every song in the game, in Enums.Song order. The single place anything
## looks a song up, so nothing else has to hold an Array[Song] of its own.

@export var songs: Array[Song] = []

func get_song(id: Enums.Song) -> Song:
	for song: Song in songs:
		if song.id == id:
			return song
	return null

func songs_for_season(season: Enums.Season) -> Array[Song]:
	var result: Array[Song] = []
	for song: Song in songs:
		if song.season() == season:
			result.append(song)
	return result

## Debug-only integrity check, called from _ready() by whoever holds the
## catalog. Catches the authoring mistakes that would otherwise show up as a
## song that can never be played: a missing entry, a duplicate id, or a
## sequence that shadows a longer one.
func validate() -> void:
	assert(songs.size() == Enums.Song.size(),
		"SongCatalog holds %d songs but Enums.Song has %d members." % [songs.size(), Enums.Song.size()])
	var seen: Dictionary = {}
	for song: Song in songs:
		assert(song != null, "SongCatalog holds an empty slot.")
		assert(not seen.has(song.id), "SongCatalog holds two songs with id %d." % song.id)
		assert(song.notes.size() == Song.NOTE_COUNT,
			"Song %d has %d notes; every song has %d." % [song.id, song.notes.size(), Song.NOTE_COUNT])
		assert(song.palette != null, "Song %d has no SeasonPalette." % song.id)
		assert(song.pulse_stats != null, "Song %d has no PulseStats." % song.id)
		assert(not song.title_key.is_empty(), "Song %d has no title_key." % song.id)
		assert(song.track != null, "Song %d has no track." % song.id)
		_validate_cues(song)
		seen[song.id] = true
	for song: Song in songs:
		for other: Song in songs:
			if other == song:
				continue
			# Identical sequences are the case a prefix test misses: neither is
			# a strict prefix of the other, but the matcher resolves on the
			# first hit, so the second song is unplayable forever.
			assert(song.notes != other.notes,
				"Songs %d and %d have identical sequences; only the first could ever be played." % [song.id, other.id])
			assert(not _is_prefix(song.notes, other.notes),
				"Song %d's sequence is a prefix of song %d's, so the longer one can never be played." % [song.id, other.id])

## Cues are optional (Song.cues() spaces them evenly when they are absent), but
## once authored they must line up one-to-one with the notes and advance in
## time, or the sheet would light slots out of order or never light the last
## one before the excerpt is cut.
func _validate_cues(song: Song) -> void:
	if song.note_cues.is_empty():
		return
	assert(song.note_cues.size() == song.notes.size(),
		"Song %d has %d note cues for %d notes." % [song.id, song.note_cues.size(), song.notes.size()])
	var previous := -1.0
	for cue: float in song.note_cues:
		assert(cue >= 0.0 and cue > previous,
			"Song %d's note cues must be non-negative and strictly ascending." % song.id)
		previous = cue
	if song.excerpt_duration > 0.0:
		assert(previous < song.excerpt_duration,
			"Song %d's last cue (%.2fs) falls after the excerpt is cut (%.2fs)." % [song.id, previous, song.excerpt_duration])

func _is_prefix(shorter: Array[Enums.Note], longer: Array[Enums.Note]) -> bool:
	if shorter.size() >= longer.size():
		return false
	for i: int in shorter.size():
		if shorter[i] != longer[i]:
			return false
	return true
