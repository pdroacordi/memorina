class_name StepSurfaces
extends RefCounted
## The footstep surface of a map cell: its biome's surface for its look, else its ground's (systems/sound-effects).


## The surface of a cell with `look` (BiomeTileset.Look, or RoomMap.NO_LOOK) and `ground`, drawn by `biome`.
static func of(look: int, ground: Enums.Ground, biome: BiomeTileset) -> Enums.Surface:
	if ground == Enums.Ground.NONE:
		return Enums.Surface.NONE
	if biome != null and look >= 0 and look < biome.step_surfaces.size():
		var surface: int = biome.step_surfaces[look]
		if surface != Enums.Surface.NONE:
			return surface as Enums.Surface
	return by_ground(ground)

## The surface a ground is when its biome names none (a look-less roof cell).
static func by_ground(ground: Enums.Ground) -> Enums.Surface:
	match ground:
		Enums.Ground.EARTH:
			return Enums.Surface.EARTH
		Enums.Ground.STONE:
			return Enums.Surface.STONE
		Enums.Ground.WOOD:
			return Enums.Surface.WOOD
	return Enums.Surface.NONE
