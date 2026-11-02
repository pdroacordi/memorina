---
name: aiva
description: Drive AIVA (creators.aiva.ai, v1) in the user's Chrome to compose, import MIDI, render and download music for Memorina. Use when a piece must be generated, re-rendered or downloaded from AIVA, or when the user says "AIVA", "gerar a música", "baixar do AIVA". Records what works in the UI as it is learned.
---

# aiva

AIVA has no API. It is driven in the user's Chrome through the Claude in Chrome tools (`mcp__claude-in-chrome__*`; load them in one ToolSearch). The built-in browser cannot upload files, so it is not used. The desktop app (`%LOCALAPPDATA%\AIVA`, Electron, v2.4.21) is the same site; it is not driven.

## Rules

- **The user approves before any generation, re-render or download of a new piece** (systems/music, "Decisions"). Say which piece, which settings and why. A re-download of a piece already downloaded is free and needs no question; AIVA says so in the dialog ("You already downloaded this track").
- The account is the user's and is already signed in. Never sign out, change billing, rename, delete or move anything in AIVA. Close dialogs you open by accident with their Cancel or ×, then check nothing changed.
- Quota: 300 downloads a month (plan since 2026-11-02); the sidebar shows what is left ("MONTHLY DOWNLOAD QUOTA"). Report it after a run.
- Downloads land in `%USERPROFILE%\Downloads` named `<Title> - Orchestrated.mid` / `<Title>.mp3`. Move them at once into `tools/audio/aiva/` (MIDI) or the scratchpad (audio being judged); never leave them in Downloads.

## The UI (learned 2026-11-02)

- Home → "Compositions" lists every piece: title, source (style or influence), instrumentation, key, tempo, meter, dates, duration. `get_page_text` reads the table; it is the cheapest way to see the account.
- "Styles" holds the custom style folder "Memorina". "Influences" lists uploaded MIDI influences.
- **Do not double-click a row**: on a folder it opened a Rename dialog. Single-click opens.
- Download: each row has a green download icon right of the heart, at x ≈ 1462 in the 1568-wide frame; rows start at y ≈ 125 and step ≈ 36.7. It opens "Download Composition": MP3, Orchestrated MIDI, Reduced MIDI, WAV, Stems, Chords; "Download zip (MP3 + MIDI)", "Render Uncompressed WAV (16 bit, 44.1kHz)", "Render Stems (16 bit WAV)".
- Find dialog buttons with `find` ("Orchestrated MIDI button in download dialog") and click the returned ref; the refs change every time the dialog opens.
- Batch clicks with `browser_batch`; a `wait` of 2 s after opening a dialog and 3-6 s after a download is enough.
- AIVA track names in its MIDI: `w.flute2.nat.slur` (woodwind, articulation), `s.solo-viola.nat.slur` (strings), `k.pop-piano.nat.stac` (keys), `p.taikos.nat.stac` (percussion); the General MIDI program is not reliable (percussion reads as piano).

## Not yet learned

Create Track (from a style, from an influence, chord progression), MIDI import into the editor, editing bars, the Style Designer. Record each here the first time it works, with the exact path of clicks and what went wrong.

## After a download

1. Move the file; give it the game's snake_case name.
2. Read the MIDI and check it against the contract in `docs/knowledge/systems/music.md`: the motif's six notes in order at beat 0, white keys, tempo, length.
3. Audio for the game: WAV from AIVA, converted to OGG (`ffmpeg -i in.wav -c:a libvorbis -q:a 6 out.ogg`), into `assets/audios/soundtrack/`, credited in `CREDITS.md` (AIVA, the plan's licence: "Full Copyright").
