class_name Enums

## PlayerData stores skills by enum index; append members only.
enum PlayerSkill {
	DOUBLE_JUMP,
	WALL_CLIMB,
	ROLL
}

## PlayerData stores possessions by enum index; append members only.
enum PlayerItem {
	SWORD,
	MEMORINA,
	## The round loaf from the baker's errand; kept, never given away (systems/story).
	BREAD,
}

## SeasonPalette resources key seasons by enum value.
enum Season {
	WINTER,
	SUMMER,
	AUTUMN,
	SPRING
}

## The four directional notes used in song sequences.
enum Note {
	UP,
	DOWN,
	LEFT,
	RIGHT
}

## MemorinaHud.glyph_sets is indexed by this enum; append members only.
enum GlyphSet {
	KEYBOARD_ARROWS,
	KEYBOARD_WASD,
	XBOX,
	PLAYSTATION
}

## PlayerData.learned_songs is indexed by this enum; append members only. See docs/design/02_mecanicas.md section 7.1.
enum Song {
	FREEZE,
	BELL_JAR,
	SHADOW,
	SOLSTICE,
	RELEASE,
	GALE,
	ROOT,
	RAIN
}

## Which half of a six-note song: notes 1-3 or 4-6 (design 02 section 7.2.1). Saved as an int; append members only.
enum SongHalf {
	NONE,
	FIRST,
	SECOND
}

## PlayerData.restored_guardians is indexed by this enum; append members only.
enum Guardian {
	FROST,
	BLOOM,
	## The bone scarecrow of the Wind Orchards (GRD-04).
	AUTUMN,
	## The sun-lion of the Summer Caldera (GRD-04).
	SUMMER,
}

## Ground materials used by songs and room maps; see docs/design/02_mecanicas.md section 7.1.
enum Ground {
	NONE,
	EARTH,
	STONE,
	## Planks and beams: solid, never roots (architecture/biome-tilesets).
	WOOD,
}
