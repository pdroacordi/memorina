---
id: door_breach
command: generate
target: res://assets/sprites/world/props/door/door_breach.png
size: 48x48
frames: 2
view: side
source: procedural: tools/art/cut_door_breach.py
---
The `breach` door look: the hole in the beached wreck on frost_shore that leads into frost_wreck_hold (WORLD-35 step 6; features/doorways-fit-their-place). Two 48x48 frames side by side, bottom-aligned on the floor line, centred on the door. Open (frame 0) is clear, so the wreck facade's own dark breach shows. Sealed (frame 1) fills the breach's dark pixels, grown by one, with the hull planks 57 px to its right, so a sealed breach reads as patched hull. Cut from our own wreck art by `python -I tools/art/cut_door_breach.py assets/sprites/world/props/frost_edge/wreck_hull.png assets/sprites/world/props/door/door_breach.png`; the breach's centre (307 hull px) must match the offset in `scenes/world/environment/props/frost_edge/wreck_hull_facade.tscn`. Decided by the orchestrator (2026-10-15): "The shore door must not draw the stone arch inside a ship".
Negative: a drawn frame, stone, an arch, outlines
