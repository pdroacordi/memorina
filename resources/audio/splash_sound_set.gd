class_name SplashSoundSet
extends Resource
## A body of water's splashes, played by SplashSounds (systems/sound-effects).

@export var small: SoundCue
@export var large: SoundCue
## px/s; a fall into the water at this speed or faster plays `large`.
@export var large_speed: float = 500.0
## px/s heard at ImpactLevel.QUIETEST; the pool profile's splash_min_speed, the slowest fall that splashes.
@export var quiet_speed: float = 120.0
## px/s heard at full level; Ivo's hard_land_speed.
@export var full_speed: float = 800.0


## The cue for a fall into the water at `speed` px/s.
func cue_for(speed: float) -> SoundCue:
	return large if speed >= large_speed else small
