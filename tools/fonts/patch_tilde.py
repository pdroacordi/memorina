"""Rebuilds assets/fonts/memorina_text_font_size_8.ttf from the pack original with a wave tilde.

The pack draws the tilde of ã õ ñ Ã Õ Ñ as four diagonal pixels, which reads as an umlaut at 8 px.
Each tilde letter is rebuilt as its base letter plus a 5 px wave two rows tall, at the base letter's advance.
User decision 2026-10-02 ("Patch the glyph"); the Franuka licence allows editing.

Run from the project root (needs fontTools):
    python tools/fonts/patch_tilde.py [source.ttf] [output.ttf]
"""
import sys

from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.ttLib import TTFont

SOURCE = r"D:\Free Assets\RPG UI pack (by Franuka)\Fonts\FantasyRPGtext (size 8).ttf"
OUTPUT = "assets/fonts/memorina_text_font_size_8.ttf"
# Font units per pixel: 2048 units per em at the font's 8 px size.
UNIT = 256
# Tilde glyph -> (base glyph, lowest tilde row in pixels above the baseline).
TILDES = {
    "atilde": ("a", 4),
    "otilde": ("o", 4),
    "ntilde": ("n", 4),
    "Atilde": ("A", 5),
    "Otilde": ("O", 5),
    "Ntilde": ("N", 5),
}
# The wave as (top row x, bottom row x), in pixels from the glyph origin.
# 3 px letters centre it on x 1; 4 px letters (advance 5) on x 2.
WAVE_NARROW = ([0, 1, 3], [-1, 2])
WAVE_WIDE = ([1, 2, 4], [0, 3])


def _pixel(pen: TTGlyphPen, x: int, y: int) -> None:
    pen.moveTo((x * UNIT, y * UNIT))
    pen.lineTo(((x + 1) * UNIT, y * UNIT))
    pen.lineTo(((x + 1) * UNIT, (y + 1) * UNIT))
    pen.lineTo((x * UNIT, (y + 1) * UNIT))
    pen.closePath()


def patch(source: str, output: str) -> None:
    font = TTFont(source, recalcTimestamp=False)
    glyphs = font.getGlyphSet()
    glyf = font["glyf"]
    hmtx = font["hmtx"]
    for name, (base, bottom) in TILDES.items():
        advance = hmtx[base][0]
        top_xs, bottom_xs = WAVE_WIDE if advance >= 5 * UNIT else WAVE_NARROW
        pen = TTGlyphPen(glyphs)
        glyphs[base].draw(pen)
        for x in top_xs:
            _pixel(pen, x, bottom + 1)
        for x in bottom_xs:
            _pixel(pen, x, bottom)
        glyph = pen.glyph()
        glyph.recalcBounds(glyf)
        glyf[name] = glyph
        hmtx[name] = (advance, glyph.xMin)
    font.save(output)


if __name__ == "__main__":
    patch(sys.argv[1] if len(sys.argv) > 1 else SOURCE, sys.argv[2] if len(sys.argv) > 2 else OUTPUT)
