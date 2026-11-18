class_name SpawnPlacement
extends RefCounted
## Where each instance of a GuardianSpawn goes, in world px; pure (GuardianSpawner, combat_reach_test).

## Px an instance keeps inside the arena's walls.
const EDGE_MARGIN := 16.0


## The instances' roots in firing order. BOTH_SIDES gives `count` pairs, the facing side first.
static func points(spawn: GuardianSpawn, ctx: SpawnContext) -> Array[Vector2]:
	var placed: Array[Vector2] = []
	var front := Vector2(spawn.offset.x * ctx.facing, spawn.offset.y)
	match spawn.placement:
		GuardianSpawn.Placement.FRONT:
			for i: int in spawn.count:
				placed.append(ctx.origin + front + Vector2(ctx.facing * spawn.spacing * i, 0.0))
		GuardianSpawn.Placement.AT_IVO:
			for i: int in spawn.count:
				placed.append(Vector2(ctx.target.x, ctx.floor_y + spawn.offset.y))
		GuardianSpawn.Placement.AROUND_IVO:
			var width := spawn.spacing * (spawn.count - 1)
			# Slid whole off a wall, so the gaps it leaves Ivo keep their width (playtests/2026-11-18-grd13-bloom-fight).
			var first := ctx.clamp_x(ctx.target.x - width * 0.5 + width, EDGE_MARGIN) - width
			first = ctx.clamp_x(first, EDGE_MARGIN)
			for i: int in spawn.count:
				placed.append(Vector2(first + spawn.spacing * i, ctx.floor_y + spawn.offset.y))
		GuardianSpawn.Placement.ACROSS_ARENA:
			var low := ctx.origin.x - spawn.spacing * spawn.count * 0.5
			var width := spawn.spacing * spawn.count
			if ctx.arena.size.x > 0.0:
				low = ctx.arena.position.x + EDGE_MARGIN
				width = ctx.arena.size.x - 2.0 * EDGE_MARGIN
			for i: int in spawn.count:
				# Ordered from the guardian's side outward, so a sequence sweeps away from it.
				var slot := i if ctx.facing > 0 else spawn.count - 1 - i
				placed.append(Vector2(low + width * (slot + 0.5) / spawn.count, ctx.floor_y + spawn.offset.y))
		GuardianSpawn.Placement.BOTH_SIDES:
			for i: int in spawn.count:
				for side: int in [ctx.facing, -ctx.facing]:
					placed.append(ctx.origin + Vector2(side * (spawn.offset.x + spawn.spacing * i), spawn.offset.y))
	for i: int in placed.size():
		placed[i].x = ctx.clamp_x(placed[i].x, EDGE_MARGIN)
	return placed

## The side an instance at `point` faces: away from the guardian, its own facing when straight above it.
static func facing_at(point: Vector2, ctx: SpawnContext) -> int:
	var dx := point.x - ctx.origin.x
	if absf(dx) < 1.0:
		return ctx.facing
	return 1 if dx > 0.0 else -1
