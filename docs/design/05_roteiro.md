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

- **Rascunho 3 (2026-10-16):** "Aprovar (Recommended)", depois de "Os diálogos poderiam ser melhorados no geral" (2026-10-15) e "Fala, escolhas viram gestos (Recommended)" (2026-10-16): Ivo fala, as escolhas continuam gestos, cada batida tem uma cena que a marca (`06_cinematica_e_experiencia.md`). As dúvidas do fim do rascunho: "Como proposto (Recommended)": "vô" é só como as crianças chamam o velho, e "Leva um casaco. Lá o inverno não acaba." fica. Os atos 1 a 4 abaixo são o rascunho 3; as vozes da vila e as visitas a 0.6 seguem do rascunho 2.

## The rules this draft follows (all from the design)

1. **The symptoms are seen before anything names them** (01 §9.1). The player spends the first minutes of play in a village that is already slipping, before the daughter asks for the song.
2. **The world tells; a line only reacts.** The house of notes, the wife's shawl, the elder's walls covered in the lighthouse, the village's memory number (03: "visivelmente pior, sem uma linha de diálogo precisar dizer isso").
3. **Nobody says the theme.** No one says "grey", "forget", "memory", "season" or "guardian" to explain them. The theme is "texture, never a line of dialogue" (01 §9).
4. **The mentor never explains** (01 §8). He gives, he shows once, he goes still.
5. **A choice is something Ivo does, not a speech.** The remembered choices are gestures, and the same gesture comes back at each key moment: *try again* (holding on) or *lower it* (letting go).
6. **Forgetting is shown by behaviour.** A greeting repeated as if new, a sentence that loses its end, a mug poured for someone who isn't there.

English, then Portuguese. ★ = a remembered choice (HOLD / LET). ↺ = changes with an earlier choice. `~word~` = a brief stutter in the box (approved).

---

## Ato 1: a manhã

### 1. Abertura [CENA, ~30 s]
Preto. Passarinhos ao longe; uma carroça passa lá fora.
Abre na janela: a luz da manhã entra torta pela casa. A câmera passa devagar pelo xale na cadeira (segura um instante), pelo violão na parede, pelos desenhos, e para na caminha: **a filha dormindo**, encolhida, o braço pra fora da colcha.
Corta para Ivo, sentado na beira da própria cama. Esfrega o rosto. Olha o xale. Levanta.
Volta o controle.

### 2. A filha, meio dormindo (ao chegar perto da caminha)
**Filha** (de olhos fechados): Pai… hoje é dia de pão redondo.
*Daughter (eyes closed): Papa… it's round-loaf day.*
**Ivo:** É? Quem disse?
*Ivo: Is it? Says who?*
**Filha:** A mamãe sempre… (para; vira para o outro lado) …o redondo.
*Daughter: Mama always… (she stops; turns over) …the round one.*
(Ivo olha o xale, um instante.)
**Ivo:** Já volto.
*Ivo: Back soon.*
→ Intenção: "O pão redondo." / "The round loaf."

### 3. O caminho (jogo)
A vila como está, a 0.8. As falas dos aldeões (STORY-09) seguem iguais.

### 4. A padaria
**Padeira:** Bom dia, Ivo. O redondo?
*Baker: Morning, Ivo. Round one?*
**Ivo:** O redondo.
*Ivo: The round one.*
[CENA curta] Ela pega o redondo e, sem pensar, o comprido também. Estende os dois. Para.
**Padeira:** E o comprido pra… (olha o pão comprido na mão)
*Baker: And the long one for… (she looks at the long loaf in her hand)*
**Ivo:** Só o redondo.
*Ivo: Just the round one.*
(Ela devolve o comprido à prateleira, devagar.)
**Padeira** (baixo): Só o redondo.
*Baker (quietly): Just the round one.*
→ Aviso: **Pão redondo**. Intenção: "Para casa." / "Home."

### 5. Em casa: a música [CENA → violão → CENA]
Ivo entra. A filha está sentada na beira da caminha, balançando as pernas. Vê o pão e sorri.
**Filha:** Achou o redondo!
*Daughter: You found the round one!*
**Ivo:** O último.
*Ivo: The last one.*
Ela pula da cama, vai até a parede, tira o violão do prego e traz até ele, segurando com os dois braços.
**Filha:** Toca a da manhã? A que a mamãe cantava.
*Daughter: Play the morning one? The one Mama used to sing.*
(Ivo pega o violão. Olha para ele um instante.)
**Ivo:** Faz tempo…
*Ivo: It's been a while…*
**Filha:** Eu lembro o começo. Você lembra o resto.
*Daughter: I remember the start. You remember the rest.*

> **[Violão]** Ivo toca. Na lacuna, **a música corta**. A câmera fecha no rosto dele. Ele aperta a próxima nota: uma corda morta. Outra vez: nada. O sorriso dela se desfaz.

★ **Escolha A** (`morning_song`), sem palavras:
1. **[Tentar de novo]** (HOLD). Ele toca de novo, do começo. Desta vez a lacuna vem uma nota antes.
   **Ivo:** Espera. Eu sei essa. Eu sei essa…
   *Ivo: Wait. I know this one. I know it…*
2. **[Baixar o violão]** (LET). Ele baixa o violão. Ela cantarola as quatro primeiras notas e para no mesmo lugar.
   **Filha:** Só sei até aí.
   *Daughter: That's all I know.*

**Filha** (baixo): Tá tudo bem, pai.
*Daughter (quietly): It's all right, Papa.*
**Ivo:** Não tá.
*Ivo: It isn't.*
[CENA] Ela baixa os olhos, dá as costas, anda até a caminha e deita virada para a parede. A câmera fica nela um instante.
Lá fora, abafada, uma voz velha começa uma história:
**Ancião** (fora de cena): …e o guardião subia a escada toda noite…
*Elder (offscreen): …and the keeper climbed the stairs every night…*
(Ivo olha para a porta.)
→ Intenção: "A história do ancião." / "The elder's story."

### 6. A casa do ancião
As paredes são todas farol. O ancião conta a história às duas crianças no banco.
**Ancião:** …e acendia a lâmpada, e os barcos voltavam pra casa, até que um inverno ele—
*Elder: …and he lit the lamp, and the ships came home, until one winter he—*
**Ancião:** Ele…
*Elder: He…*
**Menino:** Até que ele o quê, vô?
*Boy: Until he what?*
(Ele olha o quadro do farol.)
**Ancião:** Tinha um fim. Tinha um fim bom.
*Elder: It had an end. It had a good end.*

★ **Escolha B** (`elder_story`):
1. **[Esperar por ele]** (HOLD). **Ancião:** …até que um inverno— até que um— (desiste; aponta o quadro) Leste. Ainda está lá.
   *Elder: …until one winter— until one— (he gives up; points at the painting) East. It's still there.*
2. **[Olhar o quadro]** (LET). Ivo vai até o quadro.
   **Ivo:** Esse farol ainda existe?
   *Ivo: Is that lighthouse still there?*
   **Ancião** (atrás dele): Leste. Depois dos campos. Faz anos que ninguém vai.
   *Elder (behind him): East. Past the fields. Nobody's gone in years.*

**Ivo:** Vou até lá.
*Ivo: I'm going.*
**Ancião:** Leva um casaco. Lá o inverno não acaba.
*Elder: Take a coat. The winter there doesn't end.*
**Menina:** Traz o fim da história!
*Girl: Bring back the end of the story!*
→ O portão leste abre (o som do ferrolho, lá fora). Intenção: "O farol, a leste." / "The lighthouse, east."

---

## Ato 2: o Limiar
Os campos parados no meio do balanço. O sítio: a refeição parada, a cadeira afastada, a espada na mesa.
Ao pegar a espada:
**Ivo:** …Desculpa. Vou precisar disso.
*Ivo: …Sorry. I'll need this.*
→ Aviso: **Espada**.

---

## Ato 3: o farol

Ivo sobe a escada. No andar do meio, uma figura alta, quase toda cinza, a mão ainda erguida com uma flauta.
[CENA]
**Mentor:** …Você veio pelo caminho ~longo~.
*Mentor: …You came the ~long~ way.*
**Ivo:** Disseram que você guarda as coisas.
*Ivo: They say you keep things.*
(Ele leva a flauta à máscara e toca uma frase curta. A cor abre em volta dos dois por um fôlego e fecha.)
**Mentor:** Guardo. Guardava. ~Guardava~.
*Mentor: I keep. I kept. ~I kept~.*
**Mentor:** Muitas mãos. Nenhuma ~guardou~. (estende a flauta)
*Mentor: Many hands. None of them ~kept~ it. (holds the flute out)*

> **[Presente]** Ivo pega a Memorina. Aviso: **Memorina**.
> **[Lampejo]** Quando a mão dele fecha na flauta, as primeiras notas da música da manhã soam numa voz de mulher, em cor, por um segundo.

**Ivo** (baixo): Essa é… essa é a música dela.
*Ivo (quietly): That's… that's her song.*

★ **Escolha C** (`mentor_flicker`):
1. **[Tocar de novo]** (HOLD). Ele sopra: uma nota chata, cinza.
2. **[Baixar a flauta]** (LET). Ele baixa a flauta e olha o mentor.

**Mentor:** Sua ~também~. Talvez. Se você—
*Mentor: Yours ~too~. Maybe. If you—*
[CENA] Ele não termina. A mão erguida para. O cinza fecha sobre ele.
**Ivo:** Se eu o quê?
*Ivo: If I what?*
(Silêncio. A câmera segura no mentor parado.)
→ Intenção: "De volta à vila." / "Back to the village."

---

## Ato 4: a volta

### O ancião (na casa dele, na primeira vez com a Memorina)
Ele vê a flauta. Pega o modelo do farol da estante e vira. [retrato: a base com a flauta entalhada]
**Ancião:** …Meu pai entalhou isso. Nunca soube o que era.
*Elder: …My father carved this. I never knew what it was.*
**Ivo:** Ele me deu. O guardião.
*Ivo: He gave it to me. The keeper.*
**Ancião:** Então ele existe. (pausa) Então o fim da história ainda não aconteceu.
*Elder: Then he's real. (beat) Then the end of the story hasn't happened yet.*

### A filha (em casa, depois da Memorina)
↺ (A = HOLD) Ela está no violão, tentando sozinha. Para uma nota antes, onde ele parou.
**Ivo:** Quase.
*Ivo: Almost.*
**Filha:** Você também parou aí.
*Daughter: You stopped there too.*
↺ (A = LET) Ela cantarola as notas dela. Cinco, desta vez. Percebe, e para.
**Ivo:** Tinha mais uma.
*Ivo: There was one more.*
**Filha:** Eu sei! Lembrei sozinha.
*Daughter: I know! I remembered it myself.*
Então ela vê a flauta.
**Filha:** Que estranha. Toca alguma coisa?
*Daughter: That's a strange one. Does it play anything?*
**Ivo:** Ainda não.
*Ivo: Not yet.*

## Act 4 (continued): later visits

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
| **Seller** (stays to trade) | "Apples. West orchards. Last ones, till someone goes out there." / *"Maçãs. Pomares do oeste. As últimas, até alguém ir lá."* | No apples line; she and her stall stay, and she trades season seeds (LIFE-04). |
| **Boy** | Playing statues with the girl. "Don't move. You moved." / *"Não mexe. Mexeu."* | Alone. "Don't move." He waits for the girl, who isn't there. / *"Não mexe."* |

*A vendedora fica para trocar (decisão do usuário, "He stays to trade (Recommended)", 2026-10-28; é uma mulher, como na arte aprovada: "A woman, fix the text (Recommended)", 2026-10-29): só a fala das maçãs acaba em 0.6; ela e a banca ficam na vila o jogo todo, e desde a primeira semente de estação que Ivo carrega ela troca sementes por mapas, boatos e o replantio da vila (LIFE-04, `docs/knowledge/systems/seeds-and-the-seller.md`).*

---

## O que esta versão pede além do texto
- **Arte:** Ivo sentado na cama e levantando (cena 1); a filha sentada na beira da cama balançando as pernas, pulando da cama e pegando o violão na parede (cena 5); a padeira devolvendo o pão (cena 4, já temos os dois estados).
- **Som:** ambiente da manhã (passarinhos, uma carroça); o ferrolho do portão leste.
- **A voz do ancião fora de cena:** uma fala na caixa de diálogo marcada como vinda de fora (sem retrato, nome "Ancião"), ou um balão no canto da tela. Decidir no motor.
- **Ivo andando:** ele só tem o clipe de corrida, então uma caminhada de cena precisa de um clipe de andar (STORY-17).

## Open points
1. Names stay unspoken: no one in these scenes needs one.
2. Does the opening start **at 1a (waking, the errand)**, or straight at the song (1d)? I recommend 1a: §9.1 asks that the player sees the symptoms first.

---

## Os guardiões (STORY-18)

Falas aprovadas: "Aprovar as falas" (usuário, 2026-10-30). Decisões do mesmo dia: "Dentro da própria lição", "Uma flauta da sua estação", "Balão no mundo (Recommended)", "Sim, um por guardião (Recommended)". Plano: `docs/knowledge/architecture/guardian-performance-and-talks.md`. English, then Portuguese.

---

### Guardião da Flor (cervo-árvore, Mata Florida)

A loucura dele é uma primavera que começa e nunca chega. Mais perto da lucidez que o do gelo: frases inteiras.

#### Balões na luta

| Chave | EN | PT |
|---|---|---|
| `BARK_GUARDIAN_BLOOM_LUCID_0` (1ª lucidez) | …Is it you? No. Your hands are wrong. | …É você? Não. As mãos são outras. |
| `BARK_GUARDIAN_BLOOM_LUCID_1` (antes da lição) | That tune. Play it with me, quick. | Essa música. Toca comigo, rápido. |
| `BARK_GUARDIAN_BLOOM_RETRY` (depois de errar) | Again. Before it ~closes~. | De novo. Antes que ~feche~. |

#### Primeira conversa (Up, depois da lição)

1. **Guardião:** The roots found each other. / As raízes se acharam.
2. **Guardião:** That flute has been in many hands. Yours are warm. / Essa flauta passou por muitas mãos. As suas são quentes.
3. **Ivo:** Do you know a morning song? E, G, E, D… / Conhece uma música da manhã? Mi, sol, mi, ré…
4. **Guardião:** Not one of mine. Someone made that one for someone. / Não é minha. Essa, alguém fez pra alguém.
5. **Guardião:** A bird in these woods still sings a tune of ours. Listen when it rains. / Um pássaro desta mata ainda canta uma música nossa. Escuta quando chover.
6. **Guardião:** (estende uma flor do chifre) Take it. It won't last. / Leva. Não vai durar.
   - ★ **[Take the blossom] / [Pegar a flor]** (HOLD). **Guardião:** Hold it gently. It goes anyway. / Segura de leve. Vai embora mesmo assim.
   - ★ **[Let it fall] / [Deixar cair]** (LET). **Guardião:** Yes. That is how it comes back. / Isso. É assim que ela volta.

#### De novo (repetível)

| Chave | EN | PT |
|---|---|---|
| `AGAIN` | The woods are loud again. I like it. | A mata está barulhenta de novo. Gosto disso. |
| `AGAIN_V1` (2+ restaurados) | Somewhere another one is standing. I hear it in the sap. | Em algum lugar, outro está de pé. Ouço na seiva. |
| `AGAIN_V2` (todos os 4) | The sea pulls at the roots. Something there still holds on. | O mar puxa as raízes. Alguma coisa lá ainda segura. |

---

### Guardião do Gelo (golem de gelo, Lago Congelado)

A loucura dele é guardar que virou parar: água segurada tempo demais. Mais fundo no cinza: palavras soltas, que viram frase só no fim.

#### Balões na luta

| Chave | EN | PT |
|---|---|---|
| `BARK_GUARDIAN_FROST_LUCID_0` | …Cold. | …Frio. |
| `BARK_GUARDIAN_FROST_LUCID_1` | You. …Small. Moving. | Você. …Pequeno. Andando. |
| `BARK_GUARDIAN_FROST_LUCID_2` (antes da lição) | That song. Take it. Before I ~hold~ it. | Essa música. Leva. Antes que eu ~segure~. |
| `BARK_GUARDIAN_FROST_RETRY` | …Again. | …De novo. |

#### Primeira conversa (Up, depois da lição)

1. **Guardião:** The lake moves. / O lago se mexe.
2. **Guardião:** I held it still. So nothing would go. / Eu segurei ele parado. Pra nada ir embora.
3. **Ivo:** And nothing went? / E nada foi?
4. **Guardião:** Nothing came, either. / Nada veio, também.
5. **Guardião:** I watched a light, once. Far. I left it. / Eu vigiava uma luz, uma vez. Longe. Deixei.
6. **Guardião:** (arranca um cristal do ombro) Take. It melts in a hand. / Toma. Derrete na mão.
   - ★ **[Close your hand] / [Fechar a mão]** (HOLD). **Guardião:** Yes. Hold. …It still goes. / Isso. Segura. …Vai mesmo assim.
   - ★ **[Open your hand] / [Abrir a mão]** (LET). **Guardião:** Water. Good. Let it run. / Água. Bom. Deixa correr.

#### De novo (repetível)

| Chave | EN | PT |
|---|---|---|
| `AGAIN` | The ice talks at night. I let it. | O gelo fala de noite. Eu deixo. |
| `AGAIN_V1` (2+ restaurados) | Another one woke. The cold knows. | Outro acordou. O frio sabe. |
| `AGAIN_V2` (todos os 4) | By the sea there is a tower. Go slow. | Junto ao mar tem uma torre. Vai devagar. |

## Os guardiões de outono e verão (GRD-04)

Aprovado 2026-10-30 ("Aprovar as falas"). Mesmas regras de STORY-18.

### Guardião da Folha (espantalho de osso, Pomar dos Ventos)

A loucura dele é não soltar: guarda as últimas folhas do pomar, contadas, há anos. Fala em contas e posses, em sussurro; só no fim abre a mão.

#### Nome e caderno

| Chave | EN | PT |
|---|---|---|
| `GUARDIAN_AUTUMN` / `SPEAKER_GUARDIAN_AUTUMN` | Leaf Guardian | Guardião da Folha |
| `NOTEBOOK_GUARDIAN_AUTUMN_BODY` | A scarecrow of hollow bone in the orchards. When the colour came back, the leaves could fall. | Um espantalho de osso oco no pomar. Quando a cor voltou, as folhas puderam cair. |

#### Balões na luta

| Chave | EN | PT |
|---|---|---|
| `BARK_GUARDIAN_AUTUMN_LUCID_0` | …Don't touch them. They're counted. | …Não toca. Estão contadas. |
| `BARK_GUARDIAN_AUTUMN_LUCID_1` | Thirty-one. Thirty… one? | Trinta e uma. Trinta e… uma? |
| `BARK_GUARDIAN_AUTUMN_LUCID_2` (antes da lição) | Listen. A tune that opens hands. Take it. | Escuta. Uma música que abre a mão. Pega. |
| `BARK_GUARDIAN_AUTUMN_RETRY` | Again. My fingers ~close~. | De novo. Meus dedos ~fecham~. |

#### Primeira conversa (Up, depois da lição)

1. **Guardião:** They fell. All of them. / Caíram. Todas.
2. **Guardião:** I kept them through the snow. Through the blossom. Through the snow again. / Guardei na neve. Na flor. Na neve de novo.
3. **Ivo:** Why keep them? / Por que guardar?
4. **Guardião:** So the orchard would still look full. / Pro pomar ainda parecer cheio.
5. **Guardião:** Bare is lighter. I can hear the mill again. / Vazio pesa menos. Já ouço o moinho de novo.
6. **Guardião:** (estende os dedos de osso; uma folha ainda presa neles) The last one. I couldn't. You choose. / A última. Eu não consegui. Escolhe você.
   - ★ **[Keep the leaf] / [Guardar a folha]** (HOLD). **Guardião:** Press it flat in a book. That's allowed. / Guarda num livro, bem lisa. Isso pode.
   - ★ **[Let the wind take it] / [Deixar o vento levar]** (LET). **Guardião:** There. …There. That's how it's done. / Pronto. …Pronto. É assim que se faz.

#### De novo (repetível)

| Chave | EN | PT |
|---|---|---|
| `AGAIN` | The wind goes through me now. I don't mind. | O vento passa por mim agora. Não me importo. |
| `AGAIN_V1` (2+ restaurados) | Somewhere a fire woke. The air tastes of smoke. | Em algum lugar, um fogo acordou. O ar tem gosto de fumaça. |
| `AGAIN_V2` (todos os 4) | Something by the sea still won't open its hand. | Alguma coisa junto ao mar ainda não abre a mão. |


### Guardião do Sol (leão de pedra vulcânica, Caldeira de Verão)

A loucura dele é o meio-dia que não acaba: segurou o sol no alto para ninguém ver a tarde. Fala devagar, como um rei; frases curtas e inteiras. As sombras queimadas na pedra são as de quem ficou.

#### Nome e caderno

| Chave | EN | PT |
|---|---|---|
| `GUARDIAN_SUMMER` / `SPEAKER_GUARDIAN_SUMMER` | Sun Guardian | Guardião do Sol |
| `NOTEBOOK_GUARDIAN_SUMMER_BODY` | A lion of holed stone under the caldera. When the colour came back, the sun set at last. | Um leão de pedra furada sob a caldeira. Quando a cor voltou, o sol enfim se pôs. |

#### Balões na luta

| Chave | EN | PT |
|---|---|---|
| `BARK_GUARDIAN_SUMMER_LUCID_0` | …Who casts a shadow in my noon? | …Quem faz sombra no meu meio-dia? |
| `BARK_GUARDIAN_SUMMER_LUCID_1` (antes da lição) | Stand still. Let the sun mark you. Learn this. | Fica parado. Deixa o sol te marcar. Aprende. |
| `BARK_GUARDIAN_SUMMER_RETRY` | Again. The day is long. | De novo. O dia é longo. |

#### Primeira conversa (Up, depois da lição)

1. **Guardião:** The sun moved. / O sol andou.
2. **Guardião:** I held it at the top of the sky, so no one I loved would see the evening. / Segurei ele no alto do céu, pra ninguém que eu amava ver a tarde cair.
3. **Ivo:** And they stayed? / E eles ficaram?
4. **Guardião:** They stood in the light until they were only shadows on the stone. / Ficaram na luz até serem só sombra na pedra.
5. **Guardião:** A shadow keeps the shape. That is all it is for. / A sombra guarda a forma. É só pra isso que ela serve.
6. **Guardião:** (deita; a sombra dele, larga e fresca, cobre o chão) Rest here. Or go on into the sun. / Descansa aqui. Ou segue pro sol.
   - ★ **[Stay in the shade] / [Ficar na sombra]** (HOLD). **Guardião:** Then rest. A little. Not forever. / Então descansa. Um pouco. Não pra sempre.
   - ★ **[Walk into the sun] / [Andar pro sol]** (LET). **Guardião:** Good. Let it set behind you. / Bom. Deixa ele se pôr atrás de você.

#### De novo (repetível)

| Chave | EN | PT |
|---|---|---|
| `AGAIN` | Evening came. It was kind. | A tarde caiu. Foi gentil. |
| `AGAIN_V1` (2+ restaurados) | Far off, someone else let go. The stone cooled. | Longe, mais alguém soltou. A pedra esfriou. |
| `AGAIN_V2` (todos os 4) | At the sea, a light still will not set. | No mar, uma luz ainda não quer se pôr. |

## O mentor na luta final (GRD-06)

Aprovado 2026-10-30 ("Aprovar as falas"). A revelação não tem fala; o nome dele não é dito (01 §4), e por quem ele segurou a primavera fica em aberto.

### Balões na luta

| Chave | Quando | EN | PT |
|---|---|---|---|
| `BARK_MENTOR_LUCID_0` | a janela de inverno, antes da revelação | …Long way. You ~kept~ it. | …Caminho longo. Você ~guardou~. |
| `BARK_MENTOR_DUAL` | o primeiro chamado de duas trilhas | Both. I wanted ~both~. | As duas. Eu quis as ~duas~. |
| `BARK_MENTOR_RETRY` | depois de uma falha | Again. Not both. | De novo. As duas não. |
| `BARK_MENTOR_FINAL` | quando o chamado final começa | Yes. Let the other go. | Isso. Solta a outra. |

### Primeira conversa (na lanterna, depois da vitória)

1. **Mentor:** The lamp is lit. / A lâmpada acendeu.
2. **Mentor:** I held the cold so the blossom would wait for someone. It waited. Everything waited. / Segurei o frio pra flor esperar alguém. Ela esperou. Tudo esperou.
3. **Ivo:** For who? / Por quem?
4. **Mentor:** …I don't have it anymore. Good. / …Não tenho mais. Que bom.
5. **Mentor:** Your song was never mine to give. You carried it the whole way. / Sua música nunca foi minha pra dar. Você carregou ela o caminho todo.
6. **Mentor:** (estende a mão vazia, a mesma que ficou erguida tanto tempo) …Go home. Someone left the window open. / …Vai pra casa. Alguém deixou a janela aberta.
   - ★ **[Keep the flute] / [Ficar com a flauta]** (HOLD). **Mentor:** Good. Play it at home. Badly, at first. / Bom. Toca em casa. Mal, no começo.
   - ★ **[Hold it out to him] / [Estender a flauta pra ele]** (LET). **Mentor:** (fecha os dedos de Ivo de volta sobre ela) Not to me. I only kept it. / Pra mim não. Eu só guardei.

### De novo (repetível)

| Chave | EN | PT |
|---|---|---|
| `AGAIN` | The sea is loud again. I listen to all of it. | O mar está alto de novo. Escuto ele inteiro. |
