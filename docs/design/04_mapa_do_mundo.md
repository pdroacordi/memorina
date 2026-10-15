# Cantomória / Memorina — Mapa do Mundo

*Documento de design, versão de trabalho*

> Responde à pendência "mapa concreto" de `01_lore_e_narrativa.md`, seção 10, e às pendências de valor de memória inicial de `03_mundo_e_ambiente.md`, seção 7. Lore em `01`, mecânicas em `02`, ambiente em `03`.

---

## 1. Decisões (usuário, 2026-10-08)

- **Mapa:** "Approve as proposed" — sete áreas, cerca de 45 salas, com a ordem, os portões e os valores de memória das seções 2 e 3.
- **Habilidades dos guardiões novos (GRD-04):** "Autumn: wall climb; summer: none". O guardião de outono devolve a escalada de parede (`WALL_CLIMB`); o de verão ensina só canções.
- **Interiores:** "All doors". Toda construção tem uma porta (apertar para cima) que leva, com um fade, a uma sala interior própria.
- **Habitantes:** "Idle villagers, no dialogue". Aldeões parados em seus afazeres, com um ciclo curto de idle, mais animais e sinais de vida. Tudo isso congela no cinza. Diálogo fica para um item de história.
- **Terra na Caldeira e na Borda Gelada:** "No earth there" — só pedra (basalto, arenito, rocha escura, gelo); Enraizar não serve nesses dois biomas, e o material diz isso ao jogador.
- **Chão construído (calçamento, tábuas):** "Seasonal top" — um pulso deita neve ou folhas na borda de cima do calçamento, como na terra. Isso muda a seção 6 só para o chão: construções e interiores continuam com uma versão.
- **Estilo e paleta:** "Rewrite to the concept, palette per biome" — o texto de estilo compartilhado (`tools/art/prompts/style.md`) passa a descrever o conceito aprovado ("Yes, aim for this", a pintura da rua da vila), e cada bioma tem a própria paleta, tirada do seu quadro de estilo aprovado.
- **Portas:** "Buffer it ~0.1 s" — um Cima apertado um instante antes de alcançar a porta ainda a toma; entrar andando continua valendo.
- **Movimento ambiente no cinza (2026-10-09):** "Stop below 0.2 memory" — abaixo de 0.2 de memória o ciclo para (o aldeão fica parado no meio do gesto); acima, acelera com a memória.
- **Moinhos e roda d'água (2026-10-09):** "Baked pixel frames" — a rotação é desenhada em quadros de pixel art, nunca girada em tempo real.
- **Construções sem porta (2026-10-09):** "Give both doors and interiors" — a casa do meio da Praça e o moinho do rio ganham porta e interior (dois interiores novos na Vila).
- **Recomeço:** as regiões atuais (vila e borda gelada) são refeitas do zero. As salas de prova de canções (`trials_*`) continuam como laboratório de puzzles, só em builds de debug.
- **Vila plana (2026-10-10):** "The village, I think, shouldn't be so vertical. The village is the beginning of the game and is not the place for exploration, you know? That should be further from the village." Escolha: "Street only; climbs move out (Recommended)". A Vila é uma rua só, no nível do chão (Rua do Mercado, Praça, Moinho, Portão Leste), sem plataformas no ar. A Torre do Sino vira um interior opcional atrás de uma porta (o coletável continua no topo). A cisterna alagada passa para a Caldeira como sua entrada (`caldera_cistern`), alcançada pelo poço da Praça.
- **Grama gerada (2026-10-10):** "What if the grass was generated instead of pixels? it moves when int contact with the player." Escolha: "Freeze in the grey (Recommended)". As folhas de grama são geradas, balançam e se curvam quando Ivo passa, no relógio da memória como os props: abaixo de 0.2 ficam presas no meio do gesto. Primavera e verão: folhas verdes; outono: folhas secas; inverno: nenhuma (a neve continua no tile).
- **Segredos (2026-10-10):** "Secret places (such as the image) should be more hidden. Not impossible to find, but with only subtle hints." Escolha: "False wall that fades (Recommended)". Um espaço secreto é desenhado como chão sólido (os mesmos tiles, sem colisão) até Ivo entrar nele, e então se abre; as dicas são sutis (uma rachadura, uma falha na grama, um sopro de poeira).
- **Emenda entre salas (2026-10-10):** "The transition in kind of the same room when a part of the room is grey and the other isn't is not that good, its just a line, could have more of a gradient or something like that." Os fundos de duas salas vizinhas se misturam numa faixa na emenda, e salas subterrâneas têm fundo próprio (seção 6, "Fundos verticais").

- **Mundo mais lógico, vertical e ramificado (WORLD-35, 2026-10-14):** "the map distribution should, maybe, be a bit more logical, a bit more useful. For ex., why would I actually want to fight a guardian, if it's region is a dead end?" / "the map right now is a bit boring. We should explore more vertically. Create more branches of exploration, more things that connect. Expand this scenario!" Escolha: "Plan + board first (Recommended)". Depois do quadro do mundo: Guardião Florido "Hollow tree to the orchards (Recommended)" (uma árvore oca a oeste da arena sobe até o poço da vila do moinho, terceira entrada do Pomar); Guardião de Gelo "Glacier, then icefall (Recommended)" (geleira que só Congelar atravessa, depois queda de mão única na ravina do Limiar, a uma sala do banco); guardião de verão "Grate in the village road (Recommended)" (a escada do sol termina sob uma grade na rua do Portão Leste); atalhos "When the guardian is restored (Recommended)" (a grade abre com o guardião de verão restaurado); recompensas "18 letters + 11 caches (Recommended)" (18 coletáveis de lore, STORY-06; 11 esconderijos vazios até LIFE-04 ser decidido); "Yes, invisible markers (Recommended)" (cada lugar de recompensa marcado agora no texto da sala); bancos "Mill town + chimney base (Recommended)"; salas opcionais "Woods crown later, falls head with MEM-10 (Recommended)": "woods_crown (a canopy room with a cache) is built in the woods step; lake_falls_head waits for the waterfall memory item (MEM-10); woods_root_tunnel is skipped."; "Yes (Recommended)" para uma checagem de progressão por etapa do kit (TECH-08); vida "A fourth note somewhere late" (uma quarta nota de vida como recompensa escondida tardia; muda 02, "Vida", LIFE-05); escadas leste da base do farol "Keep, add a lookout cache (Recommended)"; flashbacks e criaturas-professoras nos lugares de recompensa "Decide in those items (Recommended)". O plano e o quadro: WORLD-35 no roadmap.
- **A Queda Gelada cai em neve funda (WORLD-35, 2026-10-15):** "Straight drop into deep snow (Recommended)": "One long drop down the shaft that lands in a drift of deep snow at the bottom, which breaks the fall: no stun, about 2 s. Needs a small 'soft landing' rule (a snow/water cell that cancels the hard landing)." Um poço reto da Geleira até o vão caído da Ponte Velha, onde um monte de neve funda (uma zona de aterrissagem macia, `n`) impede a aterrissagem pesada; a última tela do poço é do Limiar.
- **Onde fica a quarta nota de vida (LIFE-05, 2026-10-14):** "Caldera temple sanctum": a quarta nota fica no lugar de recompensa `caldera_temple_sanctum`, o santuário de caldera_temple_gate atrás do portão que só Sombra abre (Verão Espacial 1).
- **Muro de raízes no Bosque Fundo (TECH-08, 2026-10-14):** "Root wall that opens with Enraizar (Recommended)": "A tangle of roots before the hole that only opens once Ivo knows Enraizar, so he can't drop in without the song that brings him back. Keeps the design's "Enraizar (retorno)" true; needs a small notch in the tunnel ceiling and a new save fact." A checagem de progressão por etapa do kit achou que a Redoma atravessava o poço d'água de `woods_deep` e levava às Grutas de Raízes, cujo retorno pede Enraizar. Agora um muro de raízes, antes do buraco, só se abre quando Ivo conhece Enraizar.

## 2. Visão geral

```
                        [OUTONO · Pomar dos Ventos]      alto, noroeste
                          ▲ pulo duplo (copas)   ▲ Enraizar (abismo da montanha)
[PRIMAVERA · Bosque Florido] ◄── [VILA · hub] ──► [Estrada do Limiar] ──► [BORDA GELADA · Farol]
       oeste                      │       │                leste             extremo leste
                                  │       └─ rio, para cima ──► [INVERNO · Lago Gelado]   norte
                                  └─ poço da Praça, para baixo: cisterna alagada (Redoma) ──► [VERÃO · Caldeira]   subterrâneo
                                                                   ▲ escalada (chaminé do penhasco do outono)
```

| Área | Estação nativa | Memória inicial | Guardião → o que dá | Portão de entrada |
|---|---|---|---|---|
| Vila (hub) | primavera | 0.8; 0.6 a partir do 2º guardião restaurado; 1.0 no Retorno | nenhum | — |
| Estrada do Limiar | inverno | 0.3 | nenhum | aberta |
| Borda Gelada: o farol | inverno | 0.05 | o mentor: entrega a Memorina e entra em estase; batalha final | aberta (a jornada de abertura) |
| Bosque Florido | primavera | 0.4 | Guardião Florido → Enraizar + pulo duplo; fragmento: Chuva | ter a Memorina |
| Lago Gelado | inverno | 0.3 | Guardião de Gelo → Congelar + rolamento; fragmento: Redoma | ter a Memorina |
| Pomar dos Ventos | outono | 0.25 | guardião de outono → Soltar + escalada de parede; fragmento: Vendaval | pulo duplo **ou** Enraizar |
| Caldeira de Verão | verão | 0.15 | guardião de verão → Sombra; fragmento: Solstício | Redoma (cisterna) **ou** escalada (chaminé) |
| Topo do farol | — | — | batalha final (GRD-06) | os quatro guardiões restaurados |

**Ordem resultante:** abertura linear Vila → Limiar → Farol. Depois, Bosque e Lago em qualquer ordem. O Pomar exige o Bosque (as duas entradas pedem o que o Guardião Florido devolve). A Caldeira exige o Lago (Redoma) ou o Pomar (escalada). O final exige as quatro.

**O Guardião de Gelo não é o mentor** (usuário, 2026-10-02, STORY-03). Ele sai do farol e passa a guardar o Lago Gelado. O farol é do mentor.

**Portão "ter a Memorina":** a cerca do oeste (Bosque) e a trilha do rio (Lago) se abrem quando Ivo possui a Memorina (`PlayerItem.MEMORINA`). O ancião as abre ao vê-lo voltar com o instrumento; na prática, um portão que lê esse fato do save.

## 3. Salas por área

Convenções: o id é o nome do arquivo (`scenes/world/rooms/<área>/<id>.tscn`). "Interior" é uma sala acessada por porta (seção 4). "Atalho" é uma consequência física permanente da primeira resolução (`02_mecanicas.md`, seção 6.1). Puzzles citam `02_mecanicas.md`, seção 8.

### 3.1 Vila (`home_village`) — primavera, 0.8

| Id | Nome | Função | Portões e puzzles | Banco |
|---|---|---|---|---|
| `village_square` | Praça | Hub. O poço desce para a cisterna da Caldeira; portas da taverna, da casa de Ivo, da casa do ancião e da Torre do Sino. Aldeões. | — | sim |
| `village_lane_west` | Rua do Mercado | Bancas, padaria (porta). Leva ao Bosque. | cerca do oeste: ter a Memorina | — |
| `village_mill` | Moinho do Rio | Roda d'água, rio. Leva ao Lago (para cima). | trilha do rio: ter a Memorina | — |
| `village_gate_east` | Portão Leste | Saída para o Limiar. | — | — |
| `village_house` | Casa de Ivo (interior) | Início do jogo. Violão, cama da filha. | — | — |
| `village_tavern` | Taverna (interior, dois andares) | Balcão, mesas, lareira, barris, quartos em cima. Taverneiro e fregueses. | — | — |
| `village_tavern_cellar` | Adega (interior) | Segredo sob a taverna. | Enraizar (retorno) | — |
| `village_elder` | Casa do Ancião (interior) | O ancião (que conta a história do farol). | — | — |
| `village_bakery` | Padaria (interior) | Forno, pães, sacos de farinha. Padeira. | — | — |
| `village_empty_house` | A Casa Vazia (interior) | Combinado 4 ("A Casa Vazia"). Recompensa tardia. | Solstício + Sombra + Soltar | — |
| `village_bell_tower` | Torre do Sino (interior, vertical) | Porta na Praça. Escalada opcional; coletável no topo. | pulo duplo (retorno) | — |

### 3.2 Estrada do Limiar (`threshold`) — inverno, 0.3

Curta e atmosférica, antes de qualquer canção (`01_lore_e_narrativa.md`, seção 9.2).

| Id | Nome | Função | Portões e puzzles | Banco |
|---|---|---|---|---|
| `threshold_fields` | Campos Parados | Trigo cinza parado no meio do balanço, espantalho, sítio abandonado (porta). | — | — |
| `threshold_farmhouse` | Sítio (interior) | Mesa posta, refeição parada. Marca da espada (STORY-02). | — | — |
| `threshold_bridge` | Ponte Velha | Ponte de pedra quebrada sobre ravina seca. Primeiro inimigo. A Queda Gelada desce sobre o vão caído, num monte de neve funda que amortece a queda (WORLD-35). A parede oeste da ravina é um segredo (rachadura, sopro de poeira) que desce à Gruta da Ravina. | — | — |
| `threshold_ravine_cave` | Gruta da Ravina | WORLD-35: uma gruta de terra sob a ravina, o primeiro segredo do mundo, achado antes de qualquer canção. Uma saliência sob o túnel devolve Ivo à ravina com um pulo. Esconderijo num oco (`threshold_ravine_cache`). | — (segredo) | — |
| `threshold_icefall_foot` | Pé da Queda Gelada | WORLD-35: a última tela do poço da Queda Gelada, do Limiar, para que nenhum pulo da Ponte Velha entre na região do Lago (e gaste o título do Lago). Nada ali se pisa; a rocha deixa livre o pulo no tabuleiro leste da ponte. | — | — |
| `threshold_wayshrine` | Capela da Estrada | Neve parada no ar começa aqui. | — | sim |

### 3.3 Borda Gelada (`frost_edge`) — inverno, 0.05

| Id | Nome | Função | Portões e puzzles | Banco |
|---|---|---|---|---|
| `frost_shore` | Praia Gelada | Arrebentação parada (crista congelada, `03`, seção 6.2), barco naufragado. | — | — |
| `frost_cliffs` | Penhascos | Subida vertical até o farol. Banco numa gruta abrigada. | — | sim |
| `lighthouse_base` | Base do Farol | Porta da torre. | — | — |
| `lighthouse_interior` | Torre do Farol (interior, vertical) | Escada em espiral. Sala do mentor no meio (marca de STORY-03). Alçapão do topo selado. | alçapão: os quatro guardiões | — |
| `lighthouse_top` | Lanterna do Farol | Arena da batalha final (GRD-06). | — | — |

### 3.4 Bosque Florido (`spring_woods`) — primavera, 0.4

| Id | Nome | Função | Portões e puzzles | Banco |
|---|---|---|---|---|
| `woods_edge` | Orla do Bosque | Vem da Rua do Mercado. Cabana do lenhador (porta). | — | sim |
| `woods_hut` | Cabana do Lenhador (interior) | Coletável (carta). | — | — |
| `woods_deep` | Bosque Fundo | Árvores enormes, plataformas nas copas. Ressalto alto para as Copas. | pulo duplo (para `woods_canopy`); Enraizar (muro de raízes, para `woods_root_caves`) | — |
| `woods_root_caves` | Grutas de Raízes | Subterrâneo de terra e pedra. Ponte de raízes, poço de terra, terra e pedra (Primavera Espacial 1 e 2, Lógico 1). | Enraizar (retorno) | — |
| `woods_pond` | Lagoa | "A bacia seca" (Primavera Lógico 2). | Chuva (retorno) | — |
| `bloom_hollow` | Clareira Florida | Arena do Guardião Florido (GRD-02). A oeste, a passagem para o Oco da Árvore Velha (WORLD-35). | — | — |
| `woods_hollow_tree` | Oco da Árvore Velha | WORLD-35, "Hollow tree to the orchards (Recommended)" (usuário, 2026-10-14): o interior de uma árvore gigante a oeste da arena; sobe quatro telas por nós de madeira até o poço da Vila dos Moinhos, terceira entrada do Pomar. Esconderijo num oco lateral (`woods_hollow_tree_cache`). | pulo duplo ou Enraizar (pilares de raiz entre os nós) | — |
| `woods_canopy` | Copas | Liga ao Pomar dos Ventos (para cima). | pulo duplo | — |
| `woods_crown` | Copa da Orla | WORLD-35, sala opcional, "Woods crown later, falls head with MEM-10 (Recommended)": "woods_crown (a canopy room with a cache) is built in the woods step; lake_falls_head waits for the waterfall memory item (MEM-10); woods_root_tunnel is skipped." (usuário, 2026-10-14): a copa de uma árvore sobre a Orla, do telhado da cabana para cima; a oeste liga ao alto do Bosque Fundo (atalho do banco para as Copas). Esconderijo no galho alto (`woods_crown_cache`). | pulo duplo | — |

### 3.5 Lago Gelado (`frozen_lake`) — inverno, 0.3

| Id | Nome | Função | Portões e puzzles | Banco |
|---|---|---|---|---|
| `lake_waterfall_path` | Trilha da Cascata | Sobe do Moinho do Rio. Sala vertical. Cascata estática até MEM-10. | — | sim |
| `lake_fishing_village` | Vila dos Pescadores | Palafitas na margem, cabana do pescador (porta). Lago morto. | — | — |
| `lake_fisher_hut` | Cabana do Pescador (interior) | Redes, barris, peixe seco. | — | — |
| `lake_shore` | Margem | Lago largo; a margem distante guarda um segredo. | Congelar (retorno) | — |
| `lake_ice_caves` | Grutas de Gelo | Caminho até a arena. | — | — |
| `lake_frost_arena` | Gruta do Guardião | Arena do Guardião de Gelo (GRD-03). A leste, a passagem para a Geleira (WORLD-35); o golem não passa por ela. | — | — |
| `lake_glacier` | Geleira | WORLD-35, "Glacier, then icefall (Recommended)": "East of the arena a glacier pool only Congelar crosses (a letter there), then a one-way icefall drop into the Threshold ravine, one room from the wayshrine bench: a shortcut home." (usuário, 2026-10-14): um poço congelável de 34 células entre duas margens de pedra, mais largo que qualquer pulo; só Congelar, tocado da margem oeste, o atravessa. A carta (`lake_glacier_alcove`) fica numa saliência sobre o meio do poço, a um pulo do gelo e a 16 células de cada margem: só quem tem Congelar a alcança. | Congelar | — |
| `lake_icefall` | Queda Gelada | WORLD-35, "Glacier, then icefall (Recommended)": "East of the arena a glacier pool only Congelar crosses (a letter there), then a one-way icefall drop into the Threshold ravine, one room from the wayshrine bench: a shortcut home." (usuário, 2026-10-14); "Straight drop into deep snow (Recommended)": "One long drop down the shaft that lands in a drift of deep snow at the bottom, which breaks the fall: no stun, about 2 s. Needs a small 'soft landing' rule (a snow/water cell that cancels the hard landing)." (usuário, 2026-10-15): um poço reto de rocha; Ivo cai cerca de 2,4 s e cai na neve funda sobre o vão caído da ravina da Ponte Velha, sem aterrissagem pesada (regra de aterrissagem macia), a uma sala do banco da Capela. De mão única para todo kit sem escalada; a escalada sobe de volta: decisão do orquestrador (2026-10-14), a recompensa de retorno do plano, ao lado do "one-way icefall drop" do usuário (`gotchas/a-one-screen-shaft-cannot-shut-out-wall-climb`). | — (queda de mão única) | — |
| `lake_well` | O Poço | "O fundo do poço" em versão de lago; "Tocar dentro da ventania" (Inverno Lógico 1). | Redoma | — |
| `lake_high_wall` | A Parede Alta | "A parede d'água" (Inverno Lógico 2) e "A onda parada" (Combinado 2) até uma saída alta com coletável. | Redoma + Congelar; Vendaval + Congelar | — |
| `lake_chasm` | Abismo da Montanha | Paredes de terra. Ponte de raízes até o Pomar. | Enraizar | — |

### 3.6 Pomar dos Ventos (`wind_orchards`) — outono, 0.25

| Id | Nome | Função | Portões e puzzles | Banco |
|---|---|---|---|---|
| `orchard_terraces` | Terraços | Chega das Copas. | — | sim |
| `orchard_chasm_bridge` | Ponte do Abismo | Chega do Abismo da Montanha. A oeste, a passagem para a Colina do Moinho Grande (WORLD-35). | — | — |
| `orchard_mill_town` | Vila dos Moinhos | Moinhos de vento (giram com a memória), casas, estalagem (porta), ponte levadiça. Poço no oeste da rua que desce ao Oco da Árvore Velha (WORLD-35, "Hollow tree to the orchards (Recommended)"). Banco junto à estalagem, a duas salas da arena (WORLD-35, "Mill town + chimney base (Recommended)": "One by the orchards' inn in the mill town, one at the foot of the cliff chimney in the Caldera (today 11 screens from the crater bench)." (usuário, 2026-10-14)). | Soltar (ponte levadiça; atalho) | sim |
| `orchard_inn` | Estalagem (interior) | Taverna menor, estalajadeiro. | — | — |
| `orchard_leaf_path` | Trilha sob a Folhagem | Outono Espacial 1. | Soltar | — |
| `orchard_counterweights` | Os Contrapesos | Outono Lógico 1 (elevador). Atalho para os Terraços. A câmara de cima, onde o elevador para, abre a leste para a Colina do Moinho Grande (WORLD-35). | Soltar | — |
| `orchard_windy_gap` | O Vão do Vento | Outono Espacial 2 e Lógico 2 ("A carga ao vento"). O nicho atrás do portão do Lógico 2 abre a oeste para a Crista do Vento, a recompensa do puzzle (WORLD-35). | Vendaval; Soltar + Vendaval | — |
| `orchard_well` | O Poço das Raízes | "Apanhar no ar" (Combinado 3). Coletável. | Soltar + Enraizar | — |
| `orchard_arena` | Colina do Guardião | Arena do guardião de outono (vazia até GRD-04). A parede leste sobe, com escalada de parede, ao Penhasco (WORLD-35); o lintel da passagem leste desce uma linha, para que um pulo junto à passagem pegue a parede (decisão do orquestrador, 2026-10-15). | escalada de parede (ao Penhasco) | — |
| `orchard_crag` | Penhasco | WORLD-35: o segundo caminho depois do guardião de outono, como no plano aprovado com o quadro (2026-10-14): a chaminé como hoje, mais uma escalada de parede até o penhasco, a crista e uma queda de volta à trilha. Sobe-se pela parede leste da arena e segue-se pela do penhasco até a boca da crista. O poço que desce à arena tem as bordas a 512 px do chão dela, além do pulo duplo e da Redoma com pulo duplo (462 px): só a escalada sobe. Esconderijo no alto de uma agulha de pedra seca (`orchard_crag_cache`), só com escalada. | escalada de parede | — |
| `orchard_ridge` | Crista do Vento | WORLD-35: uma crista sobre a Trilha sob a Folhagem, a recompensa do Lógico 2 (pelo portão do Vão do Vento) e a chegada do Penhasco. Carta no outeiro (`orchard_ridge_letter`). Um poço a oeste cai na trilha, junto à boca da arena: as bordas ficam a 512 px do chão da trilha e a crista cobre a trilha toda, então é de mão única para todo kit sem escalada. Cai-se num monte fundo de folhas que amortece a queda (decisão do orquestrador, 2026-10-15, seguindo a escolha do usuário na Queda Gelada, "Straight drop into deep snow (Recommended)"). | Soltar + Vendaval; escalada de parede | — |
| `orchard_cliff_chimney` | Chaminé do Penhasco | Desce até a Caldeira. | escalada de parede | — |
| `orchard_summit` | Colina do Moinho Grande | WORLD-35: o elevador dos Contrapesos agora leva a algum lugar (plano aprovado com o quadro, 2026-10-14). A colina do grande moinho (o moinho ainda está por desenhar), entre a câmara de cima dos Contrapesos e a Ponte do Abismo; um poço cai no terraço da linha 10 dos Terraços, num monte fundo de folhas (a mesma decisão do orquestrador). A borda oeste fica a 480 px do terraço e a 448 px do morro oeste dos Terraços, abaixo da Redoma com pulo duplo (462): com a Redoma dá para subir de volta, aceito (decisão do orquestrador, 2026-10-15), porque não prende ninguém e o kit do Bosque já entra a pé pela Ponte do Abismo. Esconderijo num penedo no alto, ao lado do moinho (`orchard_summit_cache`). | Soltar (elevador) ou a pé da Ponte do Abismo | — |

### 3.7 Caldeira de Verão (`summer_caldera`) — verão, 0.15, subterrâneo

| Id | Nome | Função | Portões e puzzles | Banco |
|---|---|---|---|---|
| `caldera_cistern` | Cisterna | Poço vertical alagado sob o poço da Praça; a entrada da Caldeira pela Vila. | Redoma ("O fundo do poço", Inverno Espacial 2) | — |
| `caldera_cistern_bottom` | Fundo da Cisterna | Chega da Cisterna. | — | — |
| `caldera_chimney_base` | Base da Chaminé | Chega do Pomar. | — | — |
| `caldera_open_crater` | Cratera Aberta | A caldeira se abre para o céu (sala vertical alta). | — | sim |
| `caldera_temple_gate` | Porta do Templo | "A porta que precisa de alguém" (Verão Espacial 1). | Sombra | — |
| `caldera_seesaw` | A Gangorra | Verão Espacial 2. | Sombra | — |
| `caldera_bait` | A Isca | Verão Lógico 1. | Sombra (ou combate) | — |
| `caldera_dry_moat` | O Fosso Seco | "O lago que não havia" (Combinado 1). | Chuva + Congelar | — |
| `caldera_long_corridor` | O Corredor Longo | Verão Lógico 2. Coletável. | Solstício + Sombra | — |
| `caldera_arena` | Câmara do Sol | Arena do guardião de verão (vazia até GRD-04). | — | — |

## 4. Interiores (por portas)

- Toda construção visitável tem uma **porta** na fachada. Ivo para diante dela e aperta para cima; a tela escurece, ele aparece na porta correspondente do interior, a tela clareia. Sair é o mesmo gesto na porta de dentro.
- Um interior é uma sala comum, da mesma região da construção (mesma estação, mesma memória, mesmas marcas de morte), posicionada fora da área jogável da região. **Interiores não aparecem no mapa**: a fachada já está nele.
- Um interior pode ser maior por dentro que por fora (a taverna tem dois andares, a torre do farol é vertical).
- Portas que só abrem com uma condição (o alçapão do farol) usam o mesmo componente, travado por um fato do save.

## 5. Habitantes

- **Aldeões** parados em seus afazeres: taverneiro, fregueses, padeira, ancião, crianças, lavradores, pescador, estalajadeiro. Um ciclo curto de idle (PixelLab). Sem diálogo e sem colisão de combate.
- **Animais:** gatos, galinhas, pássaros nos telhados, um cachorro dormindo, peixes secando. Parados ou com um idle curto.
- **Sinais de vida:** fumaça de chaminé, roupa no varal, janelas acesas, bandeiras, moinhos girando.
- **Tudo congela no cinza** (`03_mundo_e_ambiente.md`, seção 2): idle, fumaça, varal e moinho correm no relógio da memória do ponto onde estão. Um aldeão numa área esquecida fica parado no meio do gesto e retoma quando um pulso passa.
- Na Vila, a população cai quando a memória cai para 0.6 (alguns aldeões somem das ruas). No Retorno, todos estão de volta.

## 6. Direção de arte por bioma

Densidade de pixel: o mundo é 1x (1 pixel de arte = 1 pixel de jogo), tiles de 32 px. Arte de natureza tem três versões (primavera, outono, inverno; o verão usa a da primavera, `systems/seasonal-art`); construções e interiores têm uma.

| Bioma | Chão | Props principais | Fundo (camadas) | Primeiro plano |
|---|---|---|---|---|
| Vila | terra escura, calçamento de pedra | casas de enxaimel, poço, bancas, barris, varal, lampiões, cercas, carroça, vasos | colinas com campos, montanhas ao norte, céu | galhos, cercas, varal |
| Limiar | terra seca, pedra de estrada | trigo, espantalho, cercas quebradas, carroça abandonada | planície vazia, horizonte baixo, neblina | trigo alto |
| Borda Gelada | rocha escura, gelo, neve | farol de pedra branca, naufrágio, boias, cordas | mar congelado, penhascos | estalactites, rochas |
| Bosque | terra com musgo, raízes | árvores enormes, cogumelos, troncos, flores | troncos em camadas, copas; subterrâneo: grutas de terra | galhos, samambaias |
| Lago Gelado | pedra azulada, gelo, madeira | palafitas, redes, barcos, varais de peixe | montanhas nevadas, lago; grutas de gelo | gelo pendente |
| Pomar | terra ocre, muro de pedra seca | árvores frutíferas, moinhos, feno, cercas | colinas com moinhos, céu de vento; penhascos | folhas, galhos |
| Caldeira | basalto furado, arenito de templo | colunas, braseiros, estátuas solares | paredes de cratera abertas para o céu; basalto colunar | colunas, raízes queimadas |
| Interiores | tábuas, reboco, vigas | por casa: mesas, cadeiras, balcão, lareira, prateleiras, camas, barris | parede do fundo do próprio interior | vigas, cortinas |

**Fundos verticais.** Cada camada tem parallax horizontal e vertical próprios e uma altura de âncora (o horizonte da sala). Acima da arte, o céu continua; abaixo, a terra continua. Salas subterrâneas usam camadas próprias (grutas, estratos) que se repetem nos dois eixos. Uma sala alta que atravessa o horizonte mostra o céu em cima e os estratos embaixo.

## 7. Fora deste mapa

- Os guardiões de outono e de verão (GRD-04): as arenas existem e estão vazias até lá.
- A cena do mentor, a entrega da espada e da Memorina, os fragmentos de portador e os coletáveis (STORY-02, -03, -04, -06): o mapa marca onde acontecem.
- Quedas d'água (MEM-10): a cascata da Trilha da Cascata é estática até a passada de design própria.
