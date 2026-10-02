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
	MEMORINA
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

## PlayerData.restored_guardians is indexed by this enum; append members only.
enum Guardian {
	FROST,
	BLOOM
}

## Ground materials used by songs and room maps; see docs/design/02_mecanicas.md section 7.1.
enum Ground {
	NONE,
	EARTH,
	STONE
}
