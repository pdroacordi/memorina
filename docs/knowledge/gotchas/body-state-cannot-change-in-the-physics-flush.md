---
id: gotchas/body-state-cannot-change-in-the-physics-flush
type: gotcha
title: A body's physics state cannot change from an area signal - defer it
status: active
tags: [physics-flush, area-entered, rigidbody, freeze, set-deferred, call-deferred]
related: [bugs/released-load-refused-to-unfreeze-in-the-physics-flush]
created: 2026-09-30
updated: 2026-09-30
source_files:
  - scenes/world/interactables/releasable/releasable.gd
---

## Summary

`area_entered` / `body_entered` fire while the physics server flushes queries. Changing
a body's state there (`freeze`, a shape's `disabled`, `monitoring`) is refused with
"Can't change this state while flushing queries" and silently does nothing. Use
`set_deferred` or emit the signal that leads to it with `call_deferred`.
