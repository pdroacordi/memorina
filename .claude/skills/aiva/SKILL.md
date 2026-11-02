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
- Imports in a row: after each Confirm, navigate to the Import MIDI URL again, wait ~8 s, `find` the file input (its ref changes: ref_27 or ref_39) and upload; a batch cannot reuse a ref across navigations.
- Find dialog buttons with `find` ("Orchestrated MIDI button in download dialog") and click the returned ref; the refs change every time the dialog opens.
- Batch clicks with `browser_batch`; a `wait` of 2 s after opening a dialog and 3-6 s after a download is enough.
- AIVA track names in its MIDI: `w.flute2.nat.slur` (woodwind, articulation), `s.solo-viola.nat.slur` (strings), `k.pop-piano.nat.stac` (keys), `p.taikos.nat.stac` (percussion); the General MIDI program is not reliable (percussion reads as piano).

## Import MIDI (learned 2026-11-02, Sombra)

1. Navigate to `https://creators.aiva.ai/create/Import%20MIDI` (or Create Track → Import MIDI).
2. `find` "file input for MIDI upload" and `file_upload` the `.mid` to that ref. Never click the drop zone (it opens the native picker).
3. AIVA reports "There is no first section: A section will be added in the beginning". Harmless: the notes keep their timing. `find` "Confirm button" and click it. Leave "Collapse layers" on.
4. The piece lands in Compositions as `<file>.mid`, source "Imported", with the tempo but no key. Its length is rounded up to whole sections (a 7 s sketch showed 0:14); the tail is silence, trimmed later.
5. A track named with an AIVA patch id (`w.flute2.nat.slur`, `s.solo-viola.nat.slur`, `k.pop-piano.nat.stac`, `s.basses.vib.slur`) is mapped to that patch (Flute 2 Legato, Solo Viola Legato, Pop Piano Sustain, ...): name sketch tracks that way to get a piece's own instruments. Percussion is not: `p.taikos` and `p.orchestral-kit` arrive as "Rock Drumkit 1"; set the kit by patch search ("Epic Taikos Kit", "Orchestral Kit") and check each drum channel's sound (combobox under the kit; "Unassigned" is silent). The September pieces layer an Orchestral Kit whose channel is Unassigned with an Epic Taikos Kit on "Floor Tom 2".
6. Otherwise instruments are mapped from the General MIDI program: flute 73 → "Flute 1 | Legato", viola 41 → "Violas | Legato (Auto-Staccato)" (an ensemble, not a solo), harp 46 → "Harp 1 | Pizzicato", contrabass 43 → "Basses | Legato (Auto-Staccato)". Check each and fix what is wrong.

## The editor

- Open a piece: row "..." menu (x ≈ 1495, the row's y) → `find` "Open in Editor menu item". The URL is `/editor/<id>/composition`; keep the id in the RUN-PLAN to come back directly.
- Click a track's lane (x ≈ 1100, y 179/212/245/277 for tracks 1-4) to select it; its instrument shows bottom left. The gear beside a track name is only Rename/Duplicate/Color/Delete; the "Mixing" button at the top shows a tooltip, not a panel.
- Change an instrument: `find` the bottom-left label (e.g. "Violas Legato") and click it; `find` "patch search textbox", type the patch ("Solo Cello Legato"), click the first result (x ≈ 327, y ≈ 214); close the picker with × (≈ 1314, 174). Clicking the label by coordinate often only shows a tooltip; use the ref.
- **An edit is not kept until Save.** Save (green, top left, ≈ 113, 25) appears after a change; it asks "Mixing options": choose "Mix & Normalise (recommended)" (`find` the radio and "Save changes"). Leaving the editor without Save loses the change silently (it happened to the first Sombra edit).
- Solo cello reaches A2; the AIVA "Violas" do not go below C3. Check a line's range against its instrument.

## Downloads

- One download per composition per month, whatever the formats ("Downloading the same composition multiple times will only count as one download"). So take the MP3 to judge, and the WAV/MIDI of the chosen one later at no cost.
- The file is named `<title>.mp3`, so an imported piece downloads as `sombra_reduzida.mid.mp3`.

## Not yet learned

Create Track from a style, from an influence, chord progression; editing notes or bars; the Style Designer; stems.

## WAV

The dialog's "WAV" is greyed until "Render Uncompressed WAV (16 bit, 44.1kHz)" has run (a spinner on the row, ~20 s); then "WAV" downloads `<title>.wav`. An unsaved imported piece downloads fine (MP3 rendered on demand).

## The September pieces in the editor

They open with sections (A, A1, Bridge, B) and chord labels, tracks Melody/Chords/Bass/Percussion. Reading one is safe; do not Save. Record each here the first time it works.

## After a download

1. Move the file; give it the game's snake_case name.
2. Read the MIDI and check it against the contract in `docs/knowledge/systems/music.md`: the motif's six notes in order at beat 0, white keys, tempo, length.
3. Audio for the game: WAV from AIVA, converted to OGG (`ffmpeg -i in.wav -c:a libvorbis -q:a 6 out.ogg`), into `assets/audios/soundtrack/`. No credit: the plan gives the project full authorship ("Eu assinei a versão que nos dá autoria total. Não precisamos dar créditos ao AIVA", user, 2026-11-02).
