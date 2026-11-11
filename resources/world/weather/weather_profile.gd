class_name WeatherProfile extends Resource

## A region's weather push and its gust cycle (design 03 sections 5.4-5.5; architecture/regional-weather-push).

## Air speed at full gust and memory 1, px/s.
@export var speed: float = 220.0
## The calm, rise, gust and fall, in profile seconds at memory 1.
@export var gusts: WindProfile
## Gust strength during a guardian fight, 0..1.
@export_range(0.0, 1.0) var fight_scale: float = 0.1
## Seconds the gust strength takes to ease to fight_scale and back.
@export var fight_ease: float = 1.0
## Sideways snow shown while a gust blows; null shows none.
@export var gust_particles: PackedScene
