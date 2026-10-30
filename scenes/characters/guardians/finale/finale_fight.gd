class_name FinaleFight extends RefCounted

## The final battle's stages and the cost of dissonance (design 02 section 5; architecture/grd-06-final-battle). Pure:
## the guardian feeds it windows and mixed inputs and reads what follows.

enum Stage {
	## A normal winter window: one track.
	WINTER,
	## The one unsolvable two-track window.
	REVELATION,
	## A two-track window: choose one and let the other go.
	DUAL,
	## The final call, phrase by phrase, after a track was chosen.
	FINAL,
}

var _stats: FinaleStats
var _revealed: bool
var _windows: int = 0
var _stage: Stage = Stage.WINTER
## Mixed inputs since the revelation; picks the damage.
var _mixed_total: int = 0
## Mixed inputs in this window; picks the veil and the drain.
var _mixed_window: int = 0
var _phrase: int = 0


## `revealed`: the save already holds the revelation ("Uma vez por save (Recommended)", user, 2026-10-30).
func _init(stats: FinaleStats, revealed: bool = false) -> void:
	assert(stats.winter_cycles >= 1, "At least one normal window before the revelation (design 5.1)")
	_stats = stats
	_revealed = revealed

## Starts the next lucidity window and returns its stage.
func open_window() -> Stage:
	_mixed_window = 0
	if _windows < _stats.winter_cycles:
		_stage = Stage.WINTER
	elif not _revealed:
		_stage = Stage.REVELATION
	else:
		_stage = Stage.DUAL
	_windows += 1
	return _stage

func stage() -> Stage:
	return _stage

## The revelation shattered; every window after it is two-track.
func reveal() -> void:
	_revealed = true

func is_revealed() -> bool:
	return _revealed

## Counts a mixed input and returns the damage it deals: the window's first is a warning.
func mix() -> int:
	_mixed_total += 1
	_mixed_window += 1
	if _mixed_window == 1 or _stats.mixed_damage.is_empty():
		return 0
	return _stats.mixed_damage[mini(_mixed_total - 1, _stats.mixed_damage.size() - 1)]

## The grey veil, 0..1.
func veil() -> float:
	return clampf(_stats.veil_per_mixed * maxf(_mixed_window - 1, 0), 0.0, 1.0)

## How much faster the window drains.
func drain() -> float:
	return 1.0 + _stats.mixed_drain * _mixed_window

## A track was finished cleanly: the veil clears and the final call begins.
func choose() -> void:
	_stage = Stage.FINAL
	_mixed_window = 0
	_phrase = 0

## The final call's current phrase; null past the last.
func phrase() -> Song:
	return _stats.final_phrases[_phrase] if _phrase < _stats.final_phrases.size() else null

## The current phrase was answered; returns true when it was the last.
func advance_phrase() -> bool:
	_phrase += 1
	return _phrase >= _stats.final_phrases.size()
