class_name SeasonPalette extends Resource

## The look of one season, shared by both of its songs. Lives in its own
## resource rather than on Song so that retinting a season is one edit, not
## two, and so a future tube/material resource can point at the same data.

@export var season: Enums.Season = Enums.Season.WINTER
## Colour a pulse of either of this season's songs tints the world with.
@export var tint: Color = Color.WHITE
## Translation key for the season's displayed name. Never a literal.
@export var name_key: String = ""
