"""Draw the house of notes' picture notes, recipe, tally board and the dog's lead on its peg as 2x-density prop PNGs.

python -I tools/art/draw_pictograms.py <out dir>
    Pictograms are drawn pixel by pixel from the templates below: a Codex sheet shrunk to these sizes and flattened to
    7 colours per object lost every pictogram (WORLD-11). Colours are the house of notes' cut props' own (paper, frame
    wood) plus one flat colour per pictogram. No letters or numbers anywhere: the notes are pictures only.
"""
import os
import sys

from PIL import Image

PAPER = (247, 220, 177)
PAPER_EDGE = (197, 176, 141)
WOOD = (142, 80, 36)
WOOD_DARK = (100, 54, 28)
WOOD_DEEP = (80, 43, 22)
INK = (74, 46, 30)
PIN = (158, 70, 35)
COLOURS = {
    "k": INK, "o": (222, 140, 52), "r": (178, 52, 44), "g": (86, 128, 58), "b": (113, 61, 32), "l": (188, 112, 50),
    "L": (226, 170, 96), "e": (250, 248, 240), "y": (236, 196, 72), "w": WOOD, "d": WOOD_DARK, "p": PAPER,
    "R": (158, 52, 40), "G": (122, 122, 126),
}

PICTOGRAMS = {
    "sun": ["...o...", ".o.o.o.", "..ooo..", "ooooooo", "..ooo..", ".o.o.o.", "...o..."],
    "heart": [".rr.rr.", "rrrrrrr", "rrrrrrr", ".rrrrr.", "..rrr..", "...r...", "......."],
    "tree": ["...g...", "..ggg..", ".ggggg.", "..ggg..", ".ggggg.", "ggggggg", "...b..."],
    "cup": [".......", "kkkkk..", "k...kk.", "k...k.k", "k...kk.", ".kkk...", "kkkkk.."],
    "key": [".kk....", "k..k...", "k..k...", ".kkkkkk", "....k.k", "....k.k", "......."],
    "dog": ["kk...kk", "kkkkkkk", "kk.k.kk", ".k...k.", ".k.k.k.", "..kkk..", "......."],
}
DOG_LEAD = ["ddddddddd", "wwwwkwwww", "....R....", "...R.R...", "..R...R..", "..R...R..", "..R...R..", "..R...R..",
    "...R.R...", "....R....", "....R....", "...GGG...", "...G.G...", "...GGG..."]
LOAF = [".lllll.", "lLlLlLl", "lllllll", ".lllll."]
EGG = [".ee.", "eeee", "eeee", ".ee."]
FLOWER = [".y.", "yoy", ".y.", ".g.", "gg."]
ARROW = ["k..", "kk.", "k.."]


def stamp(art: Image.Image, template: list[str], x: int, y: int) -> None:
    for j, row in enumerate(template):
        for i, ch in enumerate(row):
            if ch != ".":
                art.putpixel((x + i, y + j), (*COLOURS[ch], 255))


def note(name: str) -> Image.Image:
    """A 9x10 art px paper note, a pin at its top centre, the pictogram inside."""
    art = Image.new("RGBA", (9, 10))
    for y in range(1, 10):
        for x in range(9):
            art.putpixel((x, y), (*(PAPER_EDGE if y == 9 or x == 8 else PAPER), 255))
    art.putpixel((4, 0), (*PIN, 255))
    art.putpixel((4, 1), (*PIN, 255))
    stamp(art, PICTOGRAMS[name], 1, 2)
    return art


def framed(w: int, h: int) -> Image.Image:
    """A paper board in a two-tone wooden frame, hung from a string triangle 4 rows tall."""
    art = Image.new("RGBA", (w, h + 4))
    for i in range(4):
        for x in (w // 2 - 1 - i * 2, w // 2 - i * 2, w // 2 - 1 + i * 2, w // 2 + i * 2):
            if 0 <= x < w:
                art.putpixel((x, i), (*WOOD_DARK, 255))
    for y in range(h):
        for x in range(w):
            edge = x in (0, w - 1) or y in (0, h - 1)
            inner = x in (1, w - 2) or y in (1, h - 2)
            colour = WOOD_DEEP if edge and y == h - 1 else WOOD_DARK if edge else WOOD if inner else PAPER
            art.putpixel((x, y + 4), (*colour, 255))
    return art


def recipe() -> Image.Image:
    """A loaf, an egg and a flower joined by arrows: a family recipe drawn as pictures."""
    art = framed(30, 12)
    stamp(art, LOAF, 3, 4 + 4)
    stamp(art, ARROW, 11, 4 + 4)
    stamp(art, EGG, 15, 4 + 4)
    stamp(art, ARROW, 20, 4 + 4)
    stamp(art, FLOWER, 24, 3 + 4)
    return art


def tally() -> Image.Image:
    """Two rows of tally marks in groups of five: a calendar kept by strokes."""
    art = framed(14, 15)
    for row, strokes, struck in ((2, 4, True), (8, 3, False)):
        for s in range(strokes):
            for dy in range(5):
                art.putpixel((3 + s * 2, row + dy + 4), (*INK, 255))
        if struck:
            for i in range(9):
                art.putpixel((2 + i, row + 4 - i // 2 + 4), (*INK, 255))
    return art


def dog_lead() -> Image.Image:
    """The dog's red lead looped over a peg board's knob, a ring at its end."""
    art = Image.new("RGBA", (9, len(DOG_LEAD)))
    stamp(art, DOG_LEAD, 0, 0)
    return art


def save_2x(art: Image.Image, path: str) -> None:
    art.resize((art.width * 2, art.height * 2), Image.NEAREST).save(path)
    print(os.path.basename(path), art.width * 2, art.height * 2)


if __name__ == "__main__":
    out = sys.argv[1]
    for pictogram in PICTOGRAMS:
        save_2x(note(pictogram), os.path.join(out, f"note_{pictogram}.png"))
    save_2x(recipe(), os.path.join(out, "recipe.png"))
    save_2x(tally(), os.path.join(out, "tally_calendar.png"))
    save_2x(dog_lead(), os.path.join(out, "dog_lead.png"))
