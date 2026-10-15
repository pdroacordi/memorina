"""Cut the `breach` door look from the wreck hull (tools/art/prompts/door_breach.md).

Run: python -I tools/art/cut_door_breach.py <wreck_hull.png> <door_breach.png>
Frame 0 (open) is clear, so the facade's own breach shows. Frame 1 (sealed) fills the breach's dark pixels with the hull
planks beside it. Both frames are FRAME px square, bottom-aligned on the hull's ground line, centred on BREACH_X.
"""
import sys

from PIL import Image

FRAME = 48
# Hull art px of the breach's centre; must match the offset in scenes/world/environment/props/frost_edge/wreck_hull_facade.tscn.
BREACH_X = 307
# Hull art px right of BREACH_X where the patch of planks is taken.
PATCH_SHIFT = 57
# A pixel darker than this (sum of RGB) is the breach's shadow.
DARK = 110

hull = Image.open(sys.argv[1]).convert("RGBA")
left, top = BREACH_X - FRAME // 2, hull.height - FRAME
window = hull.crop((left, top, left + FRAME, top + FRAME))
patch = hull.crop((left + PATCH_SHIFT, top, left + PATCH_SHIFT + FRAME, top + FRAME))


def dark(x: int, y: int) -> bool:
    r, g, b, a = window.getpixel((x, y))
    return a > 128 and r + g + b < DARK


sealed = Image.new("RGBA", (FRAME, FRAME))
for y in range(FRAME):
    for x in range(FRAME):
        near = any(0 <= x + dx < FRAME and 0 <= y + dy < FRAME and dark(x + dx, y + dy)
                   for dx in (-1, 0, 1) for dy in (-1, 0, 1))
        if near:
            sealed.putpixel((x, y), patch.getpixel((x, y)))
sheet = Image.new("RGBA", (FRAME * 2, FRAME))
sheet.paste(sealed, (FRAME, 0))
sheet.save(sys.argv[2])
print("wrote", sys.argv[2], sheet.size)
