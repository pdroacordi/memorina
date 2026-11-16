class_name CreditsSheet
extends Resource
## The credits roll's content, top to bottom, and its pace (architecture/story-07-epilogue, "The credits").

@export var sections: Array[CreditsSection] = []
## Art px the column rolls per scaled second.
@export var scroll_speed: float = 12.0
## Scaled seconds the logo holds centred at the end.
@export var hold_end: float = 4.0
