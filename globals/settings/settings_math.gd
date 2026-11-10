class_name SettingsMath
extends RefCounted
## Pure rules for volume steps, the boot locale and the window scale (systems/settings).

const VOLUME_STEPS := 10
## The game's viewport, px; the window is a whole multiple of it.
const BASE_SIZE := Vector2i(640, 360)
const MIN_SCALE := 1
const MAX_SCALE := 3
## The languages the game ships, in the order the Language row cycles them.
const LANGUAGES: Array[String] = ["en", "pt_BR"]


## dB for a 0..10 step: 10 is 0 dB and 5 is about -12 dB. Step 0 mutes the bus; its dB is only a floor.
static func volume_db(step: int) -> float:
	if step <= 0:
		return -80.0
	return 40.0 * log(float(mini(step, VOLUME_STEPS)) / VOLUME_STEPS) / log(10.0)

## The shipped language for an OS locale: any Portuguese is pt_BR, everything else English.
static func locale_for(os_locale: String) -> String:
	return "pt_BR" if os_locale.to_lower().begins_with("pt") else "en"

static func window_size(scale: int) -> Vector2i:
	return BASE_SIZE * scale

## Whether a window of `scale` fits inside `usable`, the screen's usable rect size in px.
static func fits(scale: int, usable: Vector2i) -> bool:
	var size := window_size(scale)
	return size.x <= usable.x and size.y <= usable.y

## The next scale from `current` in `direction` that fits, skipping those that do not; `current` when none does.
static func step_scale(current: int, direction: int, usable: Vector2i) -> int:
	var next := current + signi(direction)
	while next >= MIN_SCALE and next <= MAX_SCALE:
		if next == MIN_SCALE or fits(next, usable):
			return next
		next += signi(direction)
	return current

## `scale` if it fits, else the largest smaller one that does; 1x always fits.
static func largest_fitting(scale: int, usable: Vector2i) -> int:
	var tried := clampi(scale, MIN_SCALE, MAX_SCALE)
	while tried > MIN_SCALE and not fits(tried, usable):
		tried -= 1
	return tried
