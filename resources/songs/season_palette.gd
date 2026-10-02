class_name SeasonPalette extends Resource

## Palette data shared by both songs of a season.

@export var season: Enums.Season = Enums.Season.WINTER
@export var tint: Color = Color.WHITE
@export var name_key: String = ""
## Optional particles scene; it must clip to the season mask (seasonal_particles.gdshader).
@export var pulse_particles: PackedScene
