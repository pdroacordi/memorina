# Música no AIVA (rascunho, 2026-11-02)

A canção final foi aprovada ("Aprovar a sequência", usuário, 2026-11-02) e está no jogo (`resources/songs/final_phrase_a.tres`, `final_phrase_b.tres`). O resto é guia. Os MIDIs dos motivos estão em `tools/audio/midi/`: flauta, uma nota por vez, já no andamento indicado.

## A regra que liga tudo

A Memorina tem 4 notas: **Sol4 (cima), Dó4 (baixo), Ré4 (esquerda), Mi4 (direita)**. Isso é a pentatônica de Dó sem o Lá. Toda a trilha fica em **Dó maior / Lá menor**, e a melodia evita Fá e Si quando cita um motivo. Assim o que o jogador toca sempre cabe dentro da música que está soando. Harmonia e contracanto podem usar as 7 notas.

## A canção final (12 notas)

O HUD tem seis posições, por isso o chamado final são **duas frases de 6 notas** (`FinaleStats.final_phrases`).

| Frase | Notas | Botões | Ideia |
|---|---|---|---|
| A, a do mentor | Sol Mi Ré Dó Ré Mi | ↑ → ← ↓ ← → | Começa como Congelar (Sol Mi Ré Dó), mas em vez de se fechar em Dó Dó Dó, sobe de volta. O inverno solta. |
| B, a de Ivo | Mi Sol Mi Ré Ré Dó | → ↑ → ← ← ↓ | Começa com as quatro notas da canção da manhã que a filha cantarola e onde ela para. Em vez da lacuna que o violão nunca vence, Ivo termina em Dó, um final dele, não o da mãe. |

O sentido: ele não recupera o final perdido, mas aceita terminar a música do jeito dele. Isso é o verbo do jogo, soltar, e não contradiz a regra "o violão nunca termina a canção da manhã".

- Nenhuma das duas frases coincide com uma das 8 canções, então não disparam um poder por engano.
- Andamento: 72 BPM. A frase B tem o ritmo da canção da manhã (Mi Sol Mi. Ré) e termina num Dó longo de 3 tempos.
- MIDIs: `cancao_final_frase_a.mid`, `cancao_final_frase_b.mid` e `cancao_final_12.mid` (as duas frases juntas).

### A música da batalha final no AIVA

1. Crie com **"From influence"** e suba o `cancao_final_12.mid`. Estilo **Cinematic** ou **Chamber**, Dó maior, 72 BPM, 3 a 4 minutos.
2. Faça em três seções, exportadas como **stems** (o AIVA exporta faixas separadas) para o jogo trocar de camada:
   - **Inverno:** cordas graves e flauta, com o motivo de Congelar.
   - **Revelação / dissonância:** a mesma base com a camada da Primavera por cima (Enraizar, Chuva) em outro timbre, por exemplo celesta ou harpa. As duas camadas soam juntas e brigam. O jogo baixa uma delas quando o jogador escolhe uma trilha.
   - **Chamado final:** só a frase A, depois a B, com a orquestra saindo. Termine em Dó, sustentado.
3. A **restauração** (a cena da lâmpada, cerca de 14 s) é a frase B inteira, devagar, em piano e cordas, abrindo para o acorde de Dó maior quando a lâmpada acende.

## Versões reduzidas das 8 canções

Cada canção precisa de três tamanhos. Gere a peça longa uma vez e corte as outras a partir dela, no editor do AIVA (apagando compassos) ou no Audacity:

| Versão | Duração | Uso | Como fazer |
|---|---|---|---|
| **Resposta** (stinger) | 1,5 a 3 s | quando a canção é completada (o pulso abre) | Só as 6 notas do motivo, no timbre da estação, com um acorde final. Sem introdução. |
| **Curta** | 8 a 15 s | lição do guardião, o livro de canções achado, a nota do caderno | O motivo duas vezes: a primeira simples, a segunda harmonizada, cadência em Dó (ou Lá menor). |
| **Completa** | 1,5 a 3 min, em loop | tema da região ou da luta do guardião daquela estação | "From influence" com o `motivo_<canção>.mid`. Peça loop no fim. |

Dicas:
- Gere **primeiro a completa**. A curta e a resposta saem dela, então as três ficam com o mesmo timbre e o mesmo acorde.
- No AIVA, ponha o motivo no compasso 1 (piano roll) e trave-o. Ao cortar, guarde os compassos 1 e 2 para a curta e só o compasso 1 para a resposta.
- Exporte em **WAV** e converta para OGG para o Godot (loop: marque "Loop" na importação).
- As notas soltas da Memorina (`assets/audios/sfx/memorina/`) continuam sendo as que o jogador toca. A resposta entra **depois** da última nota, nunca por cima.

Timbre por estação:

| Estação | Canções | Timbre principal | Clima |
|---|---|---|---|
| Inverno | Congelar, Redoma | flauta grave, cordas em harmônicos, celesta | parado, guardado |
| Outono | Soltar, Vendaval | clarinete, violão dedilhado, sopro de ar | descendo, solto |
| Primavera | Enraizar, Chuva | harpa, marimba, cordas pizzicato | crescendo, ligado |
| Verão | Sombra, Solstício | oboé, tambor de mão, drone em Dó | quente, demorado |

## Outras músicas que faltam

Do roteiro e dos sistemas já construídos (hoje só existem as 4 notas e sons provisórios):

1. **Canção da manhã** (`cancao_da_manha.mid`): a voz da mãe. Duas versões: a cantarolada (só voz, ou flauta macia) e a do violão torto, que **para na lacuna**. O violão é o que o jogador toca; a música de fundo só acompanha e corta.
2. **Abertura** (20 a 40 s): a manhã na casa, piano leve, cita a canção da manhã sem terminá-la.
3. **Tema da vila** e **tema do mentor** (o motivo de Congelar, solene).
4. **Regiões**: uma por região, da sua estação (veja a tabela acima), em versão "cor" e versão "cinza". A versão cinza é a mesma peça, só o drone e poucas notas, para os lugares parados no tempo.
5. **Luta de guardião**, uma por estação. Os stems separam pressão de lucidez: na janela de lucidez a percussão sai.
6. **Criaturas-professoras**: não são música, são as notas da Memorina uma oitava acima. Já existem.
7. **Jingles curtos** (1 a 3 s): banco ou salvar, morte, item novo (aviso), título da região, metade de canção aprendida, canção completa aprendida, loja da vendedora.
8. **Menu / título** e **epílogo** (STORY-07): o epílogo cita a frase B.

Ordem sugerida: a canção final e a restauração primeiro (destravam a GRD-06), depois as 8 respostas, depois os temas longos.
