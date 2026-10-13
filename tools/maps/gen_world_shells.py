"""Scaffold the WORLD-05 greybox: region scenes, room triggers, contents scenes and .room shells.

Run: python -I tools/maps/gen_world_shells.py <repo root>. Only Room triggers are rewritten; region scenes,
contents scenes and .room files are written once, so hand edits survive (systems/world).
"""
import os
import sys

ROOT = sys.argv[1]
ROOMS = os.path.join(ROOT, "scenes", "world", "rooms")
SW, SH = 20, 12  # cells per macro cell
PX_W, PX_H = SW * 32, SH * 32
INTERIOR_Y = 12000
INTERIOR_SPACING = 1600
REGION_BAND = 12000  # px of world x each region's interiors keep to
INTERIOR_ROW_SPACING = 2000  # a further row of interiors starts this far below, past the tallest (4 screens)
RING_GAP = 320  # px kept clear before the next region's band: rooms that do not touch are two RoomRing.WIDTH apart

# name_key, season (Enums.Season: WINTER 0, SUMMER 1, AUTUMN 2, SPRING 3), memory, guardian (Enums.Guardian or None), wall
REGIONS = {
    "home_village": ("REGION_HOME_VILLAGE", 3, 0.8, None, "#"),
    "threshold": ("REGION_THRESHOLD", 0, 0.3, None, "#"),
    "frost_edge": ("REGION_FROST_EDGE", 0, 0.05, None, "S"),
    "spring_woods": ("REGION_SPRING_WOODS", 3, 0.4, 1, "#"),
    "frozen_lake": ("REGION_FROZEN_LAKE", 0, 0.3, 0, "#"),
    "wind_orchards": ("REGION_WIND_ORCHARDS", 2, 0.25, None, "#"),
    "summer_caldera": ("REGION_SUMMER_CALDERA", 1, 0.15, None, "S"),
}
REGION_ORDER = list(REGIONS)

# region, id, c0, c1, r0, r1, surface (open sky above)
ROOM_LIST = [
    ("home_village", "village_lane_west", -2, -1, 0, 0, True),
    ("home_village", "village_square", 0, 2, 0, 0, True),
    ("home_village", "village_mill", 3, 4, 0, 0, True),
    ("home_village", "village_gate_east", 5, 6, 0, 0, True),
    ("threshold", "threshold_fields", 7, 9, 0, 0, True),
    ("threshold", "threshold_bridge", 10, 11, 0, 0, True),
    ("threshold", "threshold_wayshrine", 12, 12, 0, 0, True),
    ("frost_edge", "frost_shore", 13, 14, 0, 0, True),
    ("frost_edge", "frost_cliffs", 15, 16, -3, 0, True),
    ("frost_edge", "lighthouse_base", 17, 18, -3, -3, True),
    ("frost_edge", "lighthouse_top", 17, 18, -5, -4, True),
    ("spring_woods", "woods_edge", -4, -3, 0, 0, True),
    ("spring_woods", "woods_deep", -7, -5, -2, 0, True),
    ("spring_woods", "woods_canopy", -7, -5, -3, -3, True),
    ("spring_woods", "woods_root_caves", -7, -5, 1, 2, False),
    ("spring_woods", "woods_pond", -9, -8, 0, 0, True),
    ("spring_woods", "bloom_hollow", -11, -10, 0, 0, True),
    ("frozen_lake", "lake_waterfall_path", 4, 4, -5, -1, True),
    ("frozen_lake", "lake_fishing_village", 1, 3, -5, -5, True),
    ("frozen_lake", "lake_well", 2, 2, -4, -4, False),
    ("frozen_lake", "lake_shore", -2, 0, -5, -5, True),
    ("frozen_lake", "lake_high_wall", -3, -3, -7, -5, True),
    ("frozen_lake", "lake_ice_caves", 5, 6, -5, -5, False),
    ("frozen_lake", "lake_frost_arena", 7, 8, -5, -5, False),
    ("frozen_lake", "lake_chasm", -5, -4, -6, -5, True),
    ("wind_orchards", "orchard_chasm_bridge", -7, -6, -6, -6, True),
    ("wind_orchards", "orchard_terraces", -9, -7, -5, -4, True),
    ("wind_orchards", "orchard_well", -6, -5, -4, -4, True),
    ("wind_orchards", "orchard_mill_town", -12, -10, -4, -4, True),
    ("wind_orchards", "orchard_counterweights", -10, -10, -6, -5, True),
    ("wind_orchards", "orchard_windy_gap", -12, -11, -5, -5, True),
    ("wind_orchards", "orchard_leaf_path", -14, -13, -4, -4, True),
    ("wind_orchards", "orchard_arena", -16, -15, -4, -4, True),
    ("wind_orchards", "orchard_cliff_chimney", -17, -17, -4, 4, True),
    ("summer_caldera", "caldera_chimney_base", -16, -15, 4, 4, False),
    ("summer_caldera", "caldera_long_corridor", -14, -11, 4, 4, False),
    ("summer_caldera", "caldera_bait", -10, -9, 4, 4, False),
    ("summer_caldera", "caldera_dry_moat", -8, -6, 4, 4, False),
    ("summer_caldera", "caldera_seesaw", -5, -4, 4, 4, False),
    ("summer_caldera", "caldera_open_crater", -3, -2, 2, 5, True),
    ("summer_caldera", "caldera_cistern", 1, 1, 1, 2, False),
    ("summer_caldera", "caldera_cistern_bottom", -1, 1, 3, 4, False),
    ("summer_caldera", "caldera_temple_gate", 2, 3, 4, 4, False),
    ("summer_caldera", "caldera_arena", 4, 5, 4, 4, False),
]

# Horizontal openings: (west room, east room, global macro row). Air rows 5..8, floor row 9 of that macro row.
H_LINKS = [
    ("bloom_hollow", "woods_pond", 0), ("woods_pond", "woods_deep", 0), ("woods_deep", "woods_edge", 0),
    ("woods_edge", "village_lane_west", 0), ("village_lane_west", "village_square", 0),
    ("village_square", "village_mill", 0), ("village_mill", "village_gate_east", 0),
    ("village_gate_east", "threshold_fields", 0), ("threshold_fields", "threshold_bridge", 0),
    ("threshold_bridge", "threshold_wayshrine", 0), ("threshold_wayshrine", "frost_shore", 0),
    ("frost_shore", "frost_cliffs", 0), ("frost_cliffs", "lighthouse_base", -3),
    ("lake_shore", "lake_fishing_village", -5), ("lake_fishing_village", "lake_waterfall_path", -5),
    ("lake_waterfall_path", "lake_ice_caves", -5), ("lake_ice_caves", "lake_frost_arena", -5),
    ("lake_high_wall", "lake_shore", -5), ("lake_chasm", "lake_high_wall", -5),
    ("orchard_chasm_bridge", "lake_chasm", -6),
    ("orchard_cliff_chimney", "orchard_arena", -4), ("orchard_arena", "orchard_leaf_path", -4),
    ("orchard_leaf_path", "orchard_mill_town", -4), ("orchard_mill_town", "orchard_terraces", -4),
    ("orchard_terraces", "orchard_well", -4), ("orchard_counterweights", "orchard_terraces", -5),
    ("orchard_cliff_chimney", "caldera_chimney_base", 4), ("caldera_chimney_base", "caldera_long_corridor", 4),
    ("caldera_long_corridor", "caldera_bait", 4), ("caldera_bait", "caldera_dry_moat", 4),
    ("caldera_dry_moat", "caldera_seesaw", 4), ("caldera_seesaw", "caldera_open_crater", 4),
    ("caldera_open_crater", "caldera_cistern_bottom", 4), ("caldera_cistern_bottom", "caldera_temple_gate", 4),
    ("caldera_temple_gate", "caldera_arena", 4),
]

# Vertical openings: (upper room, lower room, global macro col, first cell col, last cell col inside that macro col).
V_LINKS = [
    ("village_square", "caldera_cistern", 1, 8, 11),
    ("lake_waterfall_path", "village_mill", 4, 4, 15),
    ("woods_canopy", "woods_deep", -5, 8, 15),
    ("orchard_terraces", "woods_canopy", -7, 4, 11),
    ("woods_deep", "woods_root_caves", -6, 8, 11),
    ("orchard_chasm_bridge", "orchard_terraces", -7, 4, 11),
    ("orchard_counterweights", "orchard_mill_town", -10, 6, 13),
    ("orchard_windy_gap", "orchard_mill_town", -11, 4, 15),
]

# room, cell col, bench id (on the room's bottom floor)
BENCHES = [
    ("village_square", 12, "village_square_bench"),
    ("threshold_wayshrine", 10, "threshold_wayshrine_bench"),
    ("frost_cliffs", 6, "frost_cliffs_bench"),
    ("woods_edge", 30, "woods_edge_bench"),
    ("lake_waterfall_path", 10, "lake_waterfall_bench"),
    ("orchard_terraces", 30, "orchard_terraces_bench"),
    ("caldera_open_crater", 20, "caldera_crater_bench"),
]

# region, interior id, width screens, height screens
INTERIORS = [
    ("home_village", "village_house", 1, 1),
    ("home_village", "village_tavern", 2, 2),
    ("home_village", "village_tavern_cellar", 1, 1),
    ("home_village", "village_elder", 1, 1),
    ("home_village", "village_bakery", 1, 1),
    ("home_village", "village_empty_house", 2, 1),
    ("home_village", "village_bell_tower", 1, 4),
    ("home_village", "village_mill_house", 1, 1),
    ("home_village", "village_notes_house", 1, 1),
    ("threshold", "threshold_farmhouse", 1, 1),
    ("frost_edge", "lighthouse_interior", 1, 4),
    ("spring_woods", "woods_hut", 1, 1),
    ("frozen_lake", "lake_fisher_hut", 1, 1),
    ("wind_orchards", "orchard_inn", 2, 1),
]

# (room A, cell col in A, room B, cell col in B, link, extra params for A, extra params for B).
# A door stands on its room's bottom floor unless a row is given as "row".
DOORS = [
    ("village_square", 8, "village_house", 4, "village_house_door", {}, {"arrive_facing": 1}),
    ("village_square", 38, "village_tavern", 4, "village_tavern_door", {}, {"arrive_facing": 1}),
    ("village_square", 50, "village_elder", 4, "village_elder_door", {}, {"arrive_facing": 1}),
    ("village_lane_west", 12, "village_bakery", 4, "village_bakery_door", {}, {"arrive_facing": 1}),
    ("village_lane_west", 30, "village_empty_house", 4, "village_empty_house_door", {}, {"arrive_facing": 1}),
    ("village_square", 20, "village_bell_tower", 6, "village_bell_tower_door", {}, {"arrive_facing": 1}),
    ("village_tavern", 34, "village_tavern_cellar", 4, "village_tavern_cellar_door", {}, {"arrive_facing": 1}),
    ("village_mill", 3, "village_mill_house", 4, "village_mill_house_door", {}, {"arrive_facing": 1}),
    ("village_square", 15, "village_notes_house", 4, "village_notes_house_door", {}, {"arrive_facing": 1}),
    ("threshold_fields", 40, "threshold_farmhouse", 4, "threshold_farmhouse_door", {}, {"arrive_facing": 1}),
    ("lighthouse_base", 20, "lighthouse_interior", 6, "lighthouse_door", {}, {"arrive_facing": 1}),
    ("lighthouse_top", 20, "lighthouse_interior", 12, "lighthouse_hatch",
        {"arrive_facing": -1},
        {"row": 4, "requires": "res://resources/save_facts/all_guardians_restored.tres", "arrive_facing": -1}),
    ("woods_edge", 12, "woods_hut", 4, "woods_hut_door", {}, {"arrive_facing": 1}),
    ("lake_fishing_village", 40, "lake_fisher_hut", 4, "lake_fisher_hut_door", {}, {"arrive_facing": 1}),
    ("lake_fishing_village", 3, "lake_well", 9, "lake_well_stairwell",
        {"look": "stairwell", "arrive_facing": 1}, {"row": 2, "look": "hatch_up", "arrive_facing": 1}),
    ("orchard_mill_town", 30, "orchard_inn", 4, "orchard_inn_door", {}, {"arrive_facing": 1}),
    ("caldera_cistern", 9, "caldera_cistern_bottom", 49, "caldera_cistern_door",
        {"row": 10, "arrive_facing": 1}, {"row": 17}),
]

# room, cell col of an owns_memorina barrier on the bottom floor
BARRIERS = [
    ("village_lane_west", 3),
    ("village_mill", 30),
]


def tscn_name(room_id):
    return "".join(part.capitalize() for part in room_id.split("_"))


class Room:
    def __init__(self, region, rid, c0, c1, r0, r1, surface, interior=False, origin=None):
        self.region, self.id = region, rid
        self.c0, self.c1, self.r0, self.r1 = c0, c1, r0, r1
        self.surface, self.interior = surface, interior
        self.w = (c1 - c0 + 1) * SW
        self.h = (r1 - r0 + 1) * SH
        self.origin = origin if origin is not None else (c0 * PX_W, r0 * PX_H)
        self.wall = REGIONS[region][4]
        self.grid = [["." for _ in range(self.w)] for _ in range(self.h)]
        self.entities = []
        self._shell()

    def floor_row(self):
        return self.h - SH + 9

    def _shell(self):
        g, wall = self.grid, self.wall
        for row in range(self.h):
            g[row][0] = wall
            g[row][self.w - 1] = wall
        if not self.surface:
            for col in range(self.w):
                g[0][col] = wall
        for row in range(self.floor_row(), self.h):
            for col in range(self.w):
                g[row][col] = wall

    def open_side(self, east, macro_row):
        k = macro_row - self.r0
        col = self.w - 1 if east else 0
        for row in range(k * SH + 5, k * SH + 9):
            self.grid[row][col] = "."
        floor = k * SH + 9
        if floor != self.floor_row():
            span = range(self.w - 8, self.w) if east else range(0, 8)
            for col in span:
                for row in range(floor, min(floor + 2, self.h)):
                    self.grid[row][col] = self.wall

    def open_vertical(self, bottom, macro_col, first, last):
        base = (macro_col - self.c0) * SW
        rows = range(self.floor_row(), self.h) if bottom else range(0, 1)
        for row in rows:
            for col in range(base + first, base + last + 1):
                self.grid[row][col] = "."

    def place(self, col, row, symbol, params):
        self.grid[row][col] = symbol
        if params:
            self.entities.append((col, row, params))

    def voided(self):
        """An interior's grid with every wall cell beyond the one next to its room turned to void `_` (architecture/room-void-outside-the-shell)."""
        if not self.interior:
            return self.grid
        ground = set("#S%")

        def solid(x, y):
            return not (0 <= x < self.w and 0 <= y < self.h) or self.grid[y][x] in ground

        return [["_" if self.grid[y][x] in ground and all(solid(x + dx, y + dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1))
                 else self.grid[y][x] for x in range(self.w)] for y in range(self.h)]

    def room_text(self):
        lines = [
            "; %s.room - WORLD-05 greybox shell (docs/design/04_mapa_do_mundo.md section 3)." % self.id,
            "; Bounds and edge openings come from the world layout (systems/world); keep them.",
            "",
            "[room]",
            "origin = 0, 0",
            "tileset = legacy",
            "",
            "[grid]",
        ]
        lines += ["".join(row) for row in self.voided()]
        if self.entities:
            lines += ["", "[entities]"]
            for col, row, params in sorted(self.entities, key=lambda e: (e[0], e[1])):
                body = ", ".join('"%s": %s' % (k, fmt(v)) for k, v in params.items())
                lines.append("%d,%d = {%s}" % (col, row, body))
        return "\n".join(lines) + "\n"


def fmt(value):
    if isinstance(value, str):
        return '"%s"' % value
    return str(value)


def _used_uids():
    used = set()
    for base, _dirs, files in os.walk(ROOMS):
        for f in files:
            if f.endswith(".tscn"):
                first = open(os.path.join(base, f), encoding="utf-8").readline()
                if 'uid="' in first:
                    used.add(first.split('uid="')[1].split('"')[0])
    return used


# Minted by Godot (ResourceUID.create_id); entries already in a scene header are skipped.
_USED = _used_uids()
UID_POOL = [line.strip() for line in open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "world_uid_pool.txt"))
            if line.strip() and line.strip() not in _USED]


def stamp_uid(path, text):
    """A scene keeps the uid its header already has, so save keys survive a rerun."""
    if not path.endswith(".tscn"):
        return text
    uid = None
    if os.path.exists(path):
        first = open(path, encoding="utf-8").readline()
        if 'uid="' in first:
            uid = first.split('uid="')[1].split('"')[0]
    if uid is None:
        uid = UID_POOL.pop(0)
    return text.replace("[gd_scene format=3]", '[gd_scene format=3 uid="%s"]' % uid, 1)


def write(path, text, overwrite=True):
    if not overwrite and os.path.exists(path):
        return False
    text = stamp_uid(path, text)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)
    return True


def room_trigger(room):
    rel = "res://scenes/world/rooms/%s/contents/%s_contents.tscn" % (room.region, room.id)
    w, h = room.w * 32, room.h * 32
    interior = "interior = true\n" if room.interior else ""
    return """[gd_scene format=3]

[ext_resource type="Script" uid="uid://bpd45kolxse8x" path="res://scenes/world/rooms/room.gd" id="1_room"]
[ext_resource type="PackedScene" path="%s" id="2_contents"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_room"]
size = Vector2(%d, %d)

[node name="%s" type="Area2D"]
collision_mask = 256
script = ExtResource("1_room")
contents_scene = ExtResource("2_contents")
%s
[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
position = Vector2(%d, %d)
shape = SubResource("RectangleShape2D_room")

[connection signal="body_entered" from="." to="." method="_on_body_entered"]
""" % (rel, w, h, tscn_name(room.id), interior, w // 2, h // 2)


# Each region's backdrop set and its one horizon, px below the region node: every open room shows it (systems/backdrops).
REGION_BACKDROPS = {
    "home_village": ("village_valley", 235), "threshold": ("village_valley", 235), "frost_edge": ("village_valley", 235),
    "spring_woods": ("village_valley", 235), "frozen_lake": ("village_valley", -1685),
    "wind_orchards": ("village_valley", -1301), "summer_caldera": ("caldera_crater", 768),
}
# Open rooms inside rock override their region's set with a rock wall (WORLD-28).
ROCK_SETS = {
    "lighthouse_top": "interior_stone", "frost_cliffs": "ice_caves", "lake_waterfall_path": "ice_caves",
    "lake_high_wall": "ice_caves", "lake_chasm": "ice_caves", "orchard_counterweights": "earth_caves",
    "orchard_cliff_chimney": "basalt_caves",
}
# The backdrop set an underground room of each region shows (architecture/backdrop-seams).
UNDERGROUND_SETS = {
    "home_village": "village_strata", "threshold": "earth_caves", "frost_edge": "ice_caves",
    "spring_woods": "earth_caves", "frozen_lake": "ice_caves", "wind_orchards": "earth_caves",
    "summer_caldera": "basalt_caves",
}


def contents(room):
    """Every room has a backdrop: its region's set outdoors (no override), a rock wall inside rock, its region's caves
    underground, a wall indoors."""
    rel = "res://scenes/world/rooms/%s/contents/%s.room" % (room.region, room.id)
    if room.interior:
        backdrop = "interior_timber"
    elif room.id in ROCK_SETS:
        backdrop = ROCK_SETS[room.id]
    elif room.surface:
        backdrop = None
    else:
        backdrop = UNDERGROUND_SETS[room.region]
    own_ext = own_set = ""
    if backdrop is not None:
        own_ext = '[ext_resource type="Resource" path="res://resources/world/backdrops/%s.tres" id="bd_set"]\n' % backdrop
        own_set = 'backdrop_set = ExtResource("bd_set")\n'
    return """[gd_scene format=3]

[ext_resource type="Script" path="res://scenes/world/environment/backdrop/backdrop.gd" id="bd_script"]
%s[ext_resource type="Script" path="res://scenes/world/rooms/maps/room_map_node.gd" id="room_map_node"]
[ext_resource type="Resource" path="%s" id="room_map"]

[node name="Contents" type="Node2D"]

[node name="Backdrop" type="Node2D" parent="."]
script = ExtResource("bd_script")
%s
[node name="RoomMap" type="Node2D" parent="."]
script = ExtResource("room_map_node")
map = ExtResource("room_map")
""" % (own_ext, rel, own_set)


def region_scene(region, rooms):
    key, season, memory, guardian, _ = REGIONS[region]
    lines = ["[gd_scene format=3]", ""]
    lines.append('[ext_resource type="Script" path="res://scenes/world/rooms/region.gd" id="1_region"]')
    lines.append('[ext_resource type="Script" path="res://scenes/world/rooms/region_memory.gd" id="2_regmem"]')
    backdrop, horizon = REGION_BACKDROPS[region]
    lines.append('[ext_resource type="Resource" path="res://resources/world/backdrops/%s.tres" id="bd_region_set"]' % backdrop)
    for i, room in enumerate(rooms):
        lines.append('[ext_resource type="PackedScene" path="res://scenes/world/rooms/%s/%s.tscn" id="r%d"]' % (region, room.id, i))
    lines += ["", '[node name="%s" type="Node2D"]' % tscn_name(region), 'script = ExtResource("1_region")',
              'name_key = "%s"' % key, "season = %d" % season]
    if guardian is not None:
        lines += ["has_guardian = true", "guardian = %d" % guardian]
    lines += ['backdrop_set = ExtResource("bd_region_set")', "horizon_y = %s.0" % horizon]
    lines += ["", '[node name="Memory" type="Node2D" parent="."]', 'script = ExtResource("2_regmem")',
              "authored = %s" % memory]
    for i, room in enumerate(rooms):
        lines += ["", '[node name="%s" parent="." instance=ExtResource("r%d")]' % (tscn_name(room.id), i),
                  "position = Vector2(%d, %d)" % room.origin]
    return "\n".join(lines) + "\n"


def main():
    rooms = {}
    for region, rid, c0, c1, r0, r1, surface in ROOM_LIST:
        rooms[rid] = Room(region, rid, c0, c1, r0, r1, surface)
    counters = {}
    for region, rid, ws, hs in INTERIORS:
        row, index = counters.get(region, (0, 0))
        base = REGION_ORDER.index(region) * REGION_BAND
        # A slot whose room would come within two rings of the next region's band starts the next row (systems/world).
        if index * INTERIOR_SPACING + ws * PX_W > REGION_BAND - RING_GAP:
            row, index = row + 1, 0
        counters[region] = (row, index + 1)
        origin = (base + index * INTERIOR_SPACING, INTERIOR_Y + row * INTERIOR_ROW_SPACING)
        room = Room(region, rid, 0, ws - 1, 0, hs - 1, False, interior=True, origin=origin)
        rooms[rid] = room
    for west, east, row in H_LINKS:
        rooms[west].open_side(True, row)
        rooms[east].open_side(False, row)
    for upper, lower, col, first, last in V_LINKS:
        rooms[upper].open_vertical(True, col, first, last)
        rooms[lower].open_vertical(False, col, first, last)
    for rid, col, bench in BENCHES:
        room = rooms[rid]
        room.place(col, room.floor_row() - 1, "R", {"bench_id": bench})
    for a, col_a, b, col_b, link, extra_a, extra_b in DOORS:
        for rid, col, other, extra in ((a, col_a, b, extra_a), (b, col_b, a, extra_b)):
            room = rooms[rid]
            params = {"link": link, "to_room": other}
            params.update({k: v for k, v in extra.items() if k != "row"})
            row = extra.get("row", room.floor_row() - 1)
            if row != room.floor_row() - 1:
                for c in range(col - 2, col + 3):
                    room.grid[row + 1][c] = room.wall
            room.place(col, row, "E", params)
    for rid, col in BARRIERS:
        room = rooms[rid]
        room.place(col, room.floor_row() - 1, "X", {"requires": "res://resources/save_facts/owns_memorina.tres"})

    smoke = []
    written = 0
    for room in rooms.values():
        base = os.path.join(ROOMS, room.region)
        write(os.path.join(base, room.id + ".tscn"), room_trigger(room))
        write(os.path.join(base, "contents", room.id + "_contents.tscn"), contents(room), overwrite=False)
        if write(os.path.join(base, "contents", room.id + ".room"), room.room_text(), overwrite=False):
            written += 1
        smoke.append("res://scenes/world/rooms/%s/contents/%s_contents.tscn" % (room.region, room.id))
    for region in REGION_ORDER:
        members = [r for r in rooms.values() if r.region == region]
        write(os.path.join(ROOMS, region + ".tscn"), region_scene(region, members), overwrite=False)
    print("rooms:", len(rooms), "new shells:", written)
    listed = open(os.path.join(ROOT, "tools", "smoke", "scenes.txt"), encoding="utf-8").read()
    for line in smoke:
        if line not in listed:
            print("not in tools/smoke/scenes.txt:", line)


main()
