class_name GuitarJam
extends RefCounted
## The free guitar's rules, pure (systems/story): any note sounds, every one out of tune, measured against her line only
## to know when she laughs. There is no right note: the morning song is never played.

## ALONG: the note her line has at this press; ASTRAY: another one. Both sound detuned.
enum Strum { ALONG, ASTRAY }

## Cents; the least a string is ever off, so no press sounds in tune.
const MIN_DETUNE_CENTS := 20.0

var _setup: GuitarJamSetup
var _presses: int = 0
var _mismatches: int = 0
var _laughs: bool = false


func _init(setup: GuitarJamSetup) -> void:
	_setup = setup

func press(note: Enums.Note) -> Strum:
	var notes := _setup.melody.notes
	var along := not notes.is_empty() and note == notes[_presses % notes.size()]
	_presses += 1
	_laughs = false
	if along:
		return Strum.ALONG
	_mismatches += 1
	_laughs = _mismatches == _setup.laugh_at
	return Strum.ASTRAY

## The pitch scale of press `index` (0 is the first): never 1.
func pitch_scale(index: int) -> float:
	return pow(2.0, cents(index) / 1200.0)

## Cents press `index` is off, at least MIN_DETUNE_CENTS either way.
func cents(index: int) -> float:
	var table := _setup.detune_cents
	var off := table[index % table.size()] if not table.is_empty() else MIN_DETUNE_CENTS
	if absf(off) < MIN_DETUNE_CENTS:
		off = MIN_DETUNE_CENTS if off >= 0.0 else -MIN_DETUNE_CENTS
	return off

## The last press was the mismatch she laughs at.
func laughs() -> bool:
	return _laughs

func presses() -> int:
	return _presses

func mismatches() -> int:
	return _mismatches

func is_over() -> bool:
	return _presses >= _setup.max_presses
