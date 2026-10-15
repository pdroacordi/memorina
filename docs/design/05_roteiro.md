# Cantomória / Memorina — Roteiro da abertura e vozes da vila

*Documento de design, versão de trabalho*

> Responde à pendência "Cena de abertura" de `01_lore_e_narrativa.md`, seção 10. Roteiro aprovado: "Approve draft 2 (Recommended)" (usuário, 2026-10-15), depois de "The story feels rushed. The dialogues feel unatural. I want us to follow the good principles of storytelling: show, don't tell. During the project while still in chat I've worked that very much." O texto do jogo vive em `i18n/translations.csv`; este documento é a fonte das cenas, das escolhas e da ordem. Abertura e mentor: STORY-03; vozes da vila: STORY-09.

## Decisões (usuário, 2026-10-15)

- **Melodia da manhã:** E G E D | C D E C, tempos 1 1 1,5 0,5 1 1 1 2,5 a 0,42 s ("Approve melody (Recommended)"). Ivo para depois da 5ª nota; em "[Try again]", uma nota antes.
- **Sons:** "Placeholders now, yours later (Recommended)": sons sintetizados (`tools/audio/synth_story_placeholders.py`) até as gravações do usuário substituírem os arquivos.
- **Nota errada antes da lacuna:** "Sounds, doesn't advance (Recommended)".
- **A padeira:** "Draw it: two baker stills (Recommended)": ela segura dois pães, depois um.
- **Mudanças de cena ao fim de uma conversa:** "Short cross-fade (Recommended)".
- **O retorno do ancião:** "In his house, maybe heard late (Recommended)". **Emenda ao roteiro:** as cercas leem "ter a Memorina" (`04_mapa_do_mundo.md`, seção 2) e já estão abertas quando Ivo volta; a linha "He goes out and opens the fences" sai. A conversa do modelo do farol acontece na casa dele, quando Ivo entra com o instrumento.
- **Palavras partidas do mentor (`~palavra~`):** "Yes, a brief stutter (Recommended)".
- **A ordem da abertura:** "East gate shut until the elder points east (Recommended)": o portão leste da vila fica fechado até a história do ancião ser ouvida; o "Leste. Ainda está lá." dele é o que o abre. A abertura sempre acontece em ordem. Isso muda, só para a abertura, a "Estrada do Limiar: aberta" de `04_mapa_do_mundo.md`, seção 2.
- **Gestos em português:** [Tentar de novo], [Baixar o violão], [Esperar por ele], [Olhar o quadro], [Tocar de novo], [Baixá-la] ("Approve (Recommended)").
- **Retratos e personagens:** o quadro do elenco aprovado (`tools/art/sources/story/story_cast_board_codex.png`).

---

Draft 2, 2026-10-15. Reworked after "The story feels rushed. The dialogues feel unnatural… show, don't tell."

## The rules this draft follows (all from the design)

1. **The symptoms are seen before anything names them** (01 §9.1). The player spends the first minutes of play in a village that is already slipping, before the daughter asks for the song.
2. **The world tells; a line only reacts.** The house of notes, the wife's shawl, the elder's walls covered in the lighthouse, the village's memory number (03: "visivelmente pior, sem uma linha de diálogo precisar dizer isso").
3. **Nobody says the theme.** No one says "grey", "forget", "memory", "season" or "guardian" to explain them. The theme is "texture, never a line of dialogue" (01 §9).
4. **The mentor never explains** (01 §8). He gives, he shows once, he goes still.
5. **A choice is something Ivo does, not a speech.** The remembered choices are gestures, and the same gesture comes back at each key moment: *try again* (holding on) or *lower it* (letting go).
6. **Forgetting is shown by behaviour.** A greeting repeated as if new, a sentence that loses its end, a mug poured for someone who isn't there.

English, then Portuguese. ★ = a remembered choice (HOLD / LET). ↺ = changes with an earlier choice. `~word~` = a brief stutter in the box (approved).

---

## Act 1: the ordinary morning (playable, no rush)

### 1a. Ivo's house: waking
No talk. Ivo stands by the bed. The daughter is asleep. The shawl lies on the chair, the guitar against the wall. The door is open.

If the player walks to the sleeping daughter (Up):
**Daughter** (half asleep): Bread. The round one.
*Filha (meio dormindo): Pão. O redondo.*

That is the errand. Nothing else points the way; the bakery is in the lane.

### 1b. The walk (the village at 0.8)
The player passes the square, the house of notes and the villagers on the way. Each villager has one optional line (Act 4 lists them). Nobody is told to talk.

### 1c. The bakery
**Baker:** Morning, Ivo. Round one?
*Padeira: Bom dia, Ivo. O redondo?*

**Baker:** And the long one for— (she stops, a loaf in each hand. She puts one back.)
*Padeira: E o comprido pra— (para, um pão em cada mão. Devolve um.)*

**Baker:** Just the round one.
*Padeira: Só o redondo.*

(The wife bought the long loaf. The baker reached for it out of habit. Nobody explains.)

### 1d. Home: the song
Ivo comes back with the loaf. The daughter is up and holds the guitar out to him.

**Daughter:** The morning one.
*Filha: A da manhã.*

> **[Guitar beat]** Ivo plays. Partway through, the next note isn't there. No input finishes it. The strings ring out and stop.

Silence. She looks at the guitar, not at him.

★ **Choice A** (`morning_song`), no words:
1. **[Try again]** (HOLD). He plays again, from the top. This time the gap comes **one note earlier**. He stops on his own.
2. **[Lower the guitar]** (LET). He sets it down. After a moment she hums the opening herself, four notes, and stops in the same place.

**Daughter:** …
*Filha: …*

She goes back to her bed and turns to the wall. (Up on her: "…")

### 1e. The elder's house
The walls are all lighthouse: painted, mapped, a model on the shelf (already dressed, WORLD-11). The elder is in the middle of telling it to the two children.

**Elder:** …and the keeper climbed the stairs every night, and lit the lamp, and the ships came home, until one winter he—
*Ancião: …e o guardião subia a escada toda noite, acendia a lâmpada, e os barcos voltavam, até que um inverno ele—*

**Elder:** He…
*Ancião: Ele…*

(The children wait. He looks at the painting.)

**Elder:** It had an end. It had a good end.
*Ancião: Tinha um fim. Tinha um fim bom.*

★ **Choice B** (`elder_story`):
1. **[Wait for him]** (HOLD). The elder tries twice, gets less each time: "…until one winter— until one—". He gives up and points at the painting: "East. It's still there."
   *"…até que um inverno— até que um—" Desiste e aponta o quadro: "Leste. Ainda está lá."*
2. **[Look at the painting]** (LET). Ivo walks to it. The elder, behind him: "East. Past the fields. Nobody's been in years."
   *Ancião, atrás dele: "Leste. Depois dos campos. Faz anos que ninguém vai."*

That is the only direction anyone gives. The east road is open; the elder is a pointer, not a gate.

---

## Act 2: the Threshold (no talk)
The fields stopped mid-sway. The farmhouse: a meal stopped mid-bite, a chair pushed back, and the sword on the table, where someone set it down to eat (STORY-02, Up to take). The notebook's existing line for the sword is enough.

---

## Act 3: the lighthouse

Ivo climbs the stair. On the mentor's floor stands a tall figure, mostly grey, one hand still raised as if about to play. The talk starts when Ivo comes near.

**Mentor:** …You came the ~long~ way.
*Mentor: …Você veio pelo caminho ~longo~.*

(He lifts the Memorina and plays one short phrase. Colour opens around the two of them for a breath, then closes.)

**Mentor:** Many hands. None of them ~kept~ it.
*Mentor: Muitas mãos. Nenhuma ~guardou~.*

> **[Grant]** He holds it out; Ivo takes the Memorina.
> **[Flicker]** As Ivo's hand closes on it, **the first notes of the morning song** sound in a woman's voice, in colour, for a second. Then they're gone. (The design's hint that it can restore the memory of the one who touches it, shown and never said; 01 §4.)

★ **Choice C** (`mentor_flicker`):
1. **[Play it again]** (HOLD). Ivo lifts it and blows. Nothing: one flat note, grey.
2. **[Lower it]** (LET). Ivo lowers it and looks at the mentor.

**Mentor:** Yours ~too~. Maybe. If you—
*Mentor: Seu ~também~. Talvez. Se você—*

> **[Stasis]** He doesn't finish. His raised hand stops. The grey closes over him. Up on him again: "…"

**Notebook, short entry** (appears after the gift; the full one comes at his restoration):
"The keeper of the lighthouse. He gave me the Memorina and didn't finish his sentence."
*"O guardião do farol. Me deu a Memorina e não terminou a frase."*

---

## Act 4: back in the village

**Elder** (in his house, the first time Ivo enters with the instrument):
He sees the Memorina. He takes the lighthouse model from the shelf and turns it over. On its base there is a drawing of the same flute.
**Elder:** …My father carved that. I never knew what it was.
*Ancião: …Meu pai entalhou isso. Nunca soube o que era.*
(The fences already stand open: they read "owns the Memorina". Amended 2026-10-15, "In his house, maybe heard late (Recommended)".)

**Daughter** (at home, after the Memorina):
↺ (A = HOLD) She's at the guitar, trying the song herself. She stops one note early, where he did. She puts it back against the wall.
↺ (A = LET) She's humming her four notes. **Five** this time. She notices, and stops.
Then she sees the instrument.
**Daughter:** That's a strange one.
*Filha: Que estranha.*

### Later visits (memory steps: 0.8 at the start, 0.6 from the 2nd guardian restored)

**Daughter at 0.6.** Her drawings on the wall have started to repeat: the same house, three times.
↺ (A = HOLD) **Daughter:** Papa. What colour were her eyes? …Don't guess.
*Filha: Pai. De que cor eram os olhos dela? …Não chuta.*
↺ (A = LET) **Daughter:** Papa. What colour were her eyes? …It's okay. I'll draw them grey for now.
*Filha: Pai. De que cor eram os olhos dela? …Tudo bem. Vou pintar de cinza por enquanto.*

**Elder at 0.6.** The children are gone from his house. He starts the story to an empty room.
**Elder:** …and the keeper climbed the stairs every night, and—
*Ancião: …e o guardião subia a escada toda noite, e—*
He stops and looks at the empty bench.

(The Return at 1.0 belongs to STORY-07.)

---

## Village voices (STORY-09): one optional line each, Up to talk

Forgetting is shown through behaviour, and nobody comments on it.

| Who | 0.8 | 0.6 |
|---|---|---|
| **Baker** | (after the errand) "Morning, Ivo. Round one?" Said again, as if for the first time. / *"Bom dia, Ivo. O redondo?"* | "Morning! …Ivo. Ivo. Sorry. Round one?" / *"Bom dia! …Ivo. Ivo. Desculpa. O redondo?"* |
| **Baker, once only** | "She used to come in coughing, at the end. That thing she had. Never did have a name, did it." Then back to the dough. (01 §9: once, in passing.) / *"No fim ela vinha tossindo. Aquilo que ela tinha. Nunca teve nome, né."* | (gone, never repeated) |
| **Taverner** | Wiping the same mug. "Quiet one tonight." / *"Noite calma."* | He sets two mugs on the counter, one in front of the patron's empty seat, and waits. No line. |
| **Water carrier** | "Up's heavy. Down's light. Same water." / *"Pra cima pesa. Pra baixo é leve. Mesma água."* | She stands at the well holding the full bucket. "…" |
| **Seller** (leaves at 0.6) | "Apples. West orchards. Last ones, till someone goes out there." / *"Maçãs. Pomares do oeste. As últimas, até alguém ir lá."* | (stall gone) |
| **Boy** | Playing statues with the girl. "Don't move. You moved." / *"Não mexe. Mexeu."* | Alone. "Don't move." He waits for the girl, who isn't there. / *"Não mexe."* |

---

## What this needs beyond dialogue (so you can judge the scope)
- **The errand:** the bread is a story item (a talk grants it; the daughter's talk reads it). No pickup scene is needed.
- **The flicker** (Act 3): a short colour-and-voice moment, a scripted beat like the guitar. It needs a few seconds of the morning song hummed, which comes from the song pipeline.
- **The elder's model with the flute on its base:** one new prop (art).
- **"Gap one note earlier" on [Try again]:** the guitar beat takes the gap position as data.
- **Scenery that changes at 0.6** (the repeated drawings, the empty bench, two mugs): props under `RegionPresence`, the same mechanism the villagers who leave already use.

## Open points
1. Names stay unspoken: no one in these scenes needs one.
2. Does the opening start **at 1a (waking, the errand)**, or straight at the song (1d)? I recommend 1a: §9.1 asks that the player sees the symptoms first.
