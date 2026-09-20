class_name Enums

## WALL_CLIMB gates WallMobilityComponent, which covers both wall sliding and
## jumping away from a wall, not just climbing.
##
## Member ORDER is load-bearing: PlayerData stores unlocked skills as an
## Array[bool] indexed by this enum, persisted in the save file. Members must
## only ever be appended at the end, never reordered or removed, or saved
## unlock flags will silently point at the wrong skill.
enum PlayerSkill {
	DOUBLE_JUMP,
	WALL_CLIMB,
	ROLL
}

## Possessions, as opposed to PlayerSkill's permanent unlocks: an item can be
## granted and later taken away, so unlike skills this array's values are NOT
## expected to be monotonic. Member order is still append-only for the same
## reason as PlayerSkill - it indexes PlayerData.owned_items in the save file.
enum PlayerItem {
	SWORD,
	MEMORINA
}

## The four seasons the Memorina's tubes are made from. Indexes nothing in the
## save file, but SeasonPalette resources key off it, so treat it as stable.
enum Season {
	WINTER,
	SUMMER,
	AUTUMN,
	SPRING
}

## The four directional notes the Memorina can play. The instrument has eight
## tubes, but a tube gates a SONG, not a note - the player always has these
## four inputs available and songs are sequences over them.
enum Note {
	UP,
	DOWN,
	LEFT,
	RIGHT
}

## Which physical buttons the player pressed a note with, so the sheet can
## draw the key that was actually under the thumb. PlayerInput is the only
## place that derives one from an InputEvent; MemorinaHud maps it to a
## NoteGlyphSet. Indexes MemorinaHud.glyph_sets, so append only.
enum GlyphSet {
	KEYBOARD_ARROWS,
	KEYBOARD_WASD,
	XBOX,
	PLAYSTATION
}

## The eight note sequences, two per season, in season order (Winter, Summer,
## Autumn, Spring). English identifiers for the Portuguese design-doc names:
## FREEZE=Congelar, BLIZZARD=Ventania/Nevasca, CONCENTRATED_SUN=Sol
## Concentrado, SUDDEN_STORM=Tempestade Repentina, WEAKEN=Fragilizar,
## STRIP=Despir, SPROUT=Brotar, HATCH=Eclodir.
##
## Member order is load-bearing for the same reason as PlayerSkill: it indexes
## PlayerData.learned_songs in the save file. Append only.
##
## The design docs also describe a third Winter sequence (Hibernacao) that
## does not fit the fixed eight-slot grid; see docs/design/03_mundo_e_ambiente.md
## section 7. It is deliberately absent until that conflict is resolved.
enum Song {
	FREEZE,
	BLIZZARD,
	CONCENTRATED_SUN,
	SUDDEN_STORM,
	WEAKEN,
	STRIP,
	SPROUT,
	HATCH
}
