---
id: bugs/air-jump-assigned-mid-rise-is-invisible
type: bug
title: The recalled double jump fired every time and could not be seen, because an air jump assigns the speed it should have added
status: fixed
severity: high
tags: [qte, recall, double-jump, feel, platformer]
related: [features/recall-in-more-than-one-press]
created: 2026-09-22
updated: 2026-09-22
source_files:
  - scenes/characters/ivo/abilities/double_jump_component.gd
---

## Summary

`DoubleJumpComponent.try_jump()` did `_body.velocity.y = jump_force(height)`. That is the
normal platformer rule and it is right at the apex, where the body is barely moving. It is
wrong halfway up a rise: pressed while already travelling at -184 px/s, a 222 px/s launch
is a gain of 38 px/s. The jump fires, the signal is emitted, the skill unlocks - and
nothing happens on screen.

## Symptom

User: "Even when I hit the QTE correctly, I feel like it doesn't answer to me quite well.
The second jump, for example, rarely is hitten, even though i hit the QTE." Probed in
engine, the chain was working perfectly - `step remaining=1`, then `RECALLED`,
`DOUBLE_JUMP` - and the velocity after the second press was -198 against -184 before it.

## Root cause

The chained recall FORCES the bad press. The world runs at 0.2 time scale while the window
is open, so Ivo's rise takes five times as long in real seconds as it does in game time;
the 1.0 s step window closes long before the apex. The player cannot wait for the moment
the rule was written for.

## Fix

Rising, the launch is added to what the body already had, capped so it is never worse than
the plain launch:

    var rising := minf(_body.velocity.y, 0.0)
    jump.launch(height)
    if rising < 0.0:
        _body.velocity.y = minf(_body.velocity.y, rising + _body.velocity.y * rising_boost)

At or past the apex `rising` is 0 and the behaviour is exactly what it was, so ordinary
play is untouched. Measured after: the recalled double jump launches at -462 against the
ground jump's -490.

## Prevention

A feel rule tuned for one moment ("you press the air jump near the apex") becomes a bug
the moment some other system decides when the press happens. When a QTE, a cutscene or a
slowed clock takes the timing out of the player's hands, re-check the moves it asks for
against the state they will actually be pressed in - not the state they were designed for.
