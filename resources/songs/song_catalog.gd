class_name SongCatalog extends Resource

## Stores and validates songs in Enums.Song order.

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

## Returns the shared season palette used by songs and regions.
func palette_for(season: Enums.Season) -> SeasonPalette:
	for song: Song in songs:
		if song.season() == season:
			return song.palette
	return null

## Checks song count, uniqueness, required resources, cues, and playable sequences.
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
			# Identical sequences evade the strict-prefix check but make the later song unreachable.
			assert(song.notes != other.notes,
				"Songs %d and %d have identical sequences; only the first could ever be played." % [song.id, other.id])
			assert(not _is_prefix(song.notes, other.notes),
				"Song %d's sequence is a prefix of song %d's, so the longer one can never be played." % [song.id, other.id])

## Authored cues must align one-to-one with notes and precede the excerpt end; see Song.cues().
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
