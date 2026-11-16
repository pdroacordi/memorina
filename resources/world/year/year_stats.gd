class_name YearStats
extends Resource
## How a region's year passes once its gate holds (architecture/story-07-epilogue, "The year").

## The seasons in the order they pass; the region's own season is where a world build starts.
@export var order: Array[Enums.Season] = [Enums.Season.SPRING, Enums.Season.SUMMER, Enums.Season.AUTUMN, Enums.Season.WINTER]
## Scaled seconds of advance per season, its turn included.
@export var season_seconds: float = 240.0
## Scaled seconds the dithered turn into the next season takes, at the end of each season.
@export var turn_seconds: float = 12.0
## The year passes only while every fact holds.
@export var when: Array[SaveFact] = []


func cycle_seconds() -> float:
	return season_seconds * order.size()
