# Rascunho: flashbacks, fragmentos de portador e epílogo (STORY-05, -04, -07)

Rascunho de 2026-11-11, aprovado: "Aprovar o rascunho" (usuário, 2026-11-11). Fontes: `01_lore_e_narrativa.md` §6, §8, §9.3, §9.4; `docs/knowledge/music/wifes-song.md`; `07_achados.md`. As falas estão em português; o inglês entra na construção, depois da aprovação.

## Decisões do usuário (2026-11-11)

- "Um rascunho, depois construir (Recommended)": um rascunho dos três; depois a arte da esposa; depois a construção, na ordem 05, 04, 07.
- "Pelo progresso (Recommended)": o 1º flashback depois de receber a Memorina; do 2º ao 5º, um por guardião restaurado. A ordem da curva nunca quebra.
- Onde: "Acho interessante um lugar que era importante para o casal. um lugar muito bonito, como um jardim, com cachoeira, algo assim. Talvez seja necessário inserir isso em algum lugar do mapa".
- "Cena curta assistida (Recommended)": o fragmento de portador é uma cena de uns 30 s, numa estética própria, e depois fica no caderno.

Segunda rodada (usuário, 2026-11-11):

- "Podemos sim definir um nome para a esposa. Gostaria de um nome tão simbólico quanto é Ivo": **Alba** ("Alba (Recommended)"): "aurora", e o gênero de canção medieval dos amantes que se separam ao amanhecer. Ela é a canção da manhã.
- "Podemos fazer os gatilhos, transições para flashbacks e plays bem cinemáticos e dramáticos." (seção 2, "Linguagem cinemática").
- A volta para casa: "a" (a pé, pelo mundo restaurado).
- As estações da vila: "O ano volta a passar (Recommended)".
- Depois dos créditos: "a" (de volta ao jardim, com o jogo salvo).
- Os portadores: primeiro "alguns sim, outros não", depois marcados os quatro (Primavera, Inverno, Outono, Verão) como as mãos dos cadernos.
- O visual: "gostaria que ela fosse ruiva".
- O plano técnico (`docs/knowledge/architecture/story-05-playable-flashbacks.md`, "Decisions"): o jardim pela trilha do Lago; a travessia sem câmera lenta; a fita em toda região restaurada; flashbacks pendentes ainda tocam depois da batalha final e o epílogo exige os cinco; cenas puláveis, jogo não; a morte esquece um flashback visto como o resto; a fala "Mais devagar" sai ("Tirar a fala (Recommended)"); o HUD de vida some no passado (usuário, 2026-11-11).
- A prancha de estilo do jardim (`tools/art/references/regions/garden_concept.png`, Codex): "Isso é apenas o conceito, certo? Se sim, aprovada. Na implementação real, a água tem que ser das nossas, gerada automaticamente, com reflexo. E deve ser mais perto dos personagens para que fique um cenário bem bonito" (usuário, 2026-11-12). Na sala: o poço é água do jogo (`systems/water`, legenda da água no `.room`, com reflexo), nunca pintada; a árvore, o balanço, a pedra, as flores e a cachoeira ficam perto de Ivo, na escala dos personagens, e a vista da vila e do farol vai para o fundo distante.
- As páginas do caderno dos flashbacks 1, 3 e 4: "Aprovar" (usuário, 2026-11-12). 1: "A única inteira", "Ela sabia a canção inteira. Eu só sabia o começo, e ela cantava o resto por mim."; 3: "O balanço", "Ela pediu que eu ficasse, e eu parei de empurrar. Não respondi. O balanço parou sozinho."; 4: "Antes do sol", "Eu já tinha falado com o carroceiro antes de perguntar. Ela disse que sim por mim, e amarrou a fita no meu pulso."
- A prancha de conceito (Codex, `tools/art/sources/story/alba_concept_codex.png`: retrato, de pé, sentada na pedra, com a filha): "Aprovar a arte" (usuário, 2026-11-11). Ajustes nos clipes: a filha deitada dormindo no colo (na prancha está ajoelhada, abraçada), os olhos abertos fora do canto, a altura de adulta (cerca de 26 px de arte).

Decisões anteriores que valem aqui: o epílogo é uma cena, uma peça só ("Cena (Recommended)"); a canção de ninar é a mesma melodia ("A mesma (Recommended)"); o fim perdido dela sobe ao Lá, nota que a Memorina não tem ("Sim, o Lá (Recommended)"), todos de 2026-11-02.

## 1. O jardim da cachoeira (sala nova)

Um lugar só do casal, fora da vila e perto dela. O mesmo lugar recebe os cinco flashbacks e o epílogo, de modo que a cena final acontece num lugar que o jogador já viveu cinco vezes, sem que ninguém o explique (01 §9.4: "um lugar já visto de relance").

- **Onde:** `village_garden`, uma tela nova rio acima do Moinho do Rio (`village_mill`), um andar acima da vila, com entrada pela trilha da cachoeira do Lago (`lake_waterfall_path`); na primeira ida o título do Lago Gelado aparece antes. Abre com a mesma cerca da trilha do rio: "ter a Memorina". Fica na região da vila (`home_village`) e não tem título próprio.
- **Como é:** uma clareira funda entre pedras: uma cachoeira estreita cai num poço raso, com uma pedra lisa à beira d'água, um balanço de corda num galho, canteiros de flores selvagens e uma árvore velha. Sem banco de salvar, sem inimigos.
- **No presente, ele está cinza.** A vila está a 0.8, mas o jardim tem um poço de esquecimento próprio (MEM-03): é a memória de Ivo que está indo, não a da vila. A água para no meio da queda e as flores ficam paradas. **Cada flashback visto enfraquece o poço**, e o jardim volta um pouco a cada um: depois do 5º está quase todo colorido; no epílogo está inteiro.
- **A cachoeira** é arte (tiles ou prop animado no relógio da memória): parada no cinza, correndo na cor. Não depende do MEM-10, que trata de cachoeiras como peça de puzzle; uma canção não age sobre ela.

## 2. Os cinco flashbacks (STORY-05)

Regras de 01 §9.3: cor persistente, não invocada pelo jogador; jogáveis e curtos (1 a 2 minutos cada); três tipos de gatilho (som, objeto recorrente, interação ambiental). Nenhum mostra a morte. A esposa se chama **Alba**: a caixa de diálogo mostra o nome com o retrato; a filha diz "mãe"; Ivo só diz o nome dela uma vez, no epílogo.

**Como funciona um flashback:** Ivo entra no jardim de antes, em cor, sem a espada e sem a Memorina (o passado não tem nenhuma das duas). Ele anda, usa Up e, quando a cena pede, toca o violão. Ao final ele volta ao presente, onde estava. Nada no flashback machuca, e não há como morrer.

**O objeto recorrente: a fita dela.** Alba é ruiva; a fita é de pano azul de centáurea, com que ela prende a trança. O azul contra o ruivo se lê de longe, e a fita é a única cor que o jogador vê sozinha no mundo cinza fora de um pulso. Aparece amarrada em lugares do mundo, e ela a usa em todos os flashbacks.

### Linguagem cinemática

Os flashbacks são o momento mais cuidado do jogo. Cada um tem quatro tempos, feitos com o motor de cenas (câmera, faixas pretas, zoom, luz, som; `systems/cutscenes`):

1. **O chamado (o gatilho).** Antes de o jogador agir, o mundo avisa: o som ambiente baixa, a música da região sai, e o gatilho fica sozinho na cena (o som dela de longe, a fita se mexendo sem vento, o balanço rangendo). Ao chegar perto, as faixas pretas entram devagar e a câmera fecha no gatilho. O jogador ainda está no controle: ele escolhe chegar.
2. **A travessia (presente → memória).** Up (ou chegar, no gatilho de som) para o mundo: o tempo desacelera, Ivo fica imóvel, a cor nasce do gatilho e se espalha em ondas pelo cinza, com o pontilhado da memória ao contrário (o cinza se desfaz em vez de chegar). Quando a cor cobre a tela, um branco sobe com o som dela crescendo. Corte no ápice do som.
3. **A memória (o jogo).** Abre num detalhe, nunca no plano geral: as mãos dela na corda do balanço, a água caindo, a fita no cabelo. A câmera recua até mostrar os dois. As faixas pretas ficam finas enquanto o jogador anda, e voltam grossas nas falas. A luz é a da hora daquela memória (dia, fim de tarde, noite, crepúsculo). A música é dela, nunca da região.
4. **A volta (memória → presente).** No último momento, a cor começa a falhar pelas bordas da tela, com o pontilhado da memória comendo a imagem de fora para dentro, enquanto ela ainda fala ou canta; o som dela fica abafado, como debaixo d'água. A imagem dela é a última a sumir. Corte seco para o presente, em silêncio: Ivo de joelhos onde estava, um segundo inteiro sem som nenhum antes de o ambiente voltar. Cada flashback deixa o jardim um pouco mais colorido, e o jogador vê isso na próxima vez que entrar.

O que cada um faz de diferente está no item **Cinema** de cada flashback.

### 1. Estabelecimento (gatilho: som)

- **Quando:** com a Memorina. **Onde:** no jardim, na primeira vez que Ivo entra.
- **Gatilho:** Ivo chega à beira do poço parado e ouve o cantarolar dela vindo de dentro da cachoeira congelada (`wife_hum_opening.wav`, as quatro notas). Fica parado (o jogador não escolhe nada), e a cor se espalha a partir da água.
- **Jogo:** ela está sentada na pedra lisa, cantarolando (`wife_song_full`). O violão está encostado na árvore. Up pega o violão, e Ivo a acompanha numa batida de violão livre: qualquer nota vale, e as notas saem tortas. Ela ri na terceira nota errada.
- **Falas** ("Eu gostaria de dar uma mudada no diálogo dessa cena, pq tá muito estranho. nada natural"; "A única que sei inteira (Recommended)", usuário, 2026-11-12):
  - **Ivo:** De novo essa?
  - **Alba:** É a única que eu sei inteira.
  - **Ivo:** Eu nunca acerto o meio.
  - **Alba:** Então toca o começo comigo. O meio eu canto.
  - (ele toca; erra a terceira; ela ri sem parar de cantar)
  - **Alba:** Viu? Ninguém percebeu.
- **Fim:** ela continua cantando enquanto a cor falha pelas bordas. A canção é cortada antes do fim, e o fim perdido nunca é ouvido aqui.
- **Cinema:** o chamado é o mais longo de todos, porque o jogador ainda não sabe o que é: a cachoeira parada no ar, uma nota dela de dentro da água, silêncio, outra nota. A travessia nasce da água: a queda volta a correr de cima para baixo e a cor desce com ela. A memória abre na água caindo e recua até Alba na pedra, de costas, cantando. Na volta, a voz dela continua um instante depois que a imagem já é cinza.

### 2. O primeiro sinal ignorado (gatilho: objeto recorrente)

- **Quando:** com 1 guardião restaurado. **Onde:** a fita aparece amarrada num galho na região do guardião restaurado, perto da saída da arena. Up nela.
- **Jogo:** dia claro no jardim. Ela colhe flores num canteiro e pede a Ivo as do outro lado do poço (Up em três flores, um pulo de pedra em pedra). Quando ele volta, ela está sentada, com a mão no peito, e se levanta rápido demais.
- **Falas:**
  - **Alba:** Essas não, as amarelas. As que ninguém colhe.
  - (ele traz as três)
  - **Ivo:** Você tá pálida.
  - **Alba:** Subi a trilha correndo. Foi só cansaço.
  - **Alba:** Me dá. (amarra as flores com a fita) Pronto. Agora não morrem tão cedo.
- **Fim:** ela segura o buquê contra a luz; a cor falha pelas bordas.
- **Cinema:** o chamado: num lugar cinza do mundo, um ponto azul se mexendo num galho sem vento. De perto, a câmera fecha na fita. Up: Ivo a desamarra e ela se solta da mão dele no ar, e a travessia segue a fita voando até o branco. A memória abre na fita já no cabelo dela. O momento da mão no peito tem a câmera de longe, do outro lado do poço, com Ivo de costas trazendo as flores: o jogador vê o que Ivo não viu. Na volta, a fita fica na mão de Ivo no presente.

### 3. O pedido para não buscar ajuda fora (gatilho: interação ambiental)

- **Quando:** com 2 guardiões restaurados. **Onde:** no jardim, no presente: o balanço de corda caído no chão, enroscado no cinza. Ivo segura Up para erguê-lo e prendê-lo de novo no galho (uma ação de dois segundos que o jogador tem de fazer).
- **Jogo:** fim de tarde. Ela está no balanço, mais devagar que antes, com um xale. Ivo a empurra (Up a cada volta, sem pontos, sem falha). Entre um empurrão e outro, ela fala.
- **Falas:**
  - **Ivo:** O ancião disse que no porto tem gente que cura essas coisas.
  - **Alba:** Essas coisas.
  - **Ivo:** Isso que você tem.
  - **Alba:** É longe, Ivo. É muito longe pra levar uma tosse.
  - **Alba:** Eu tenho um pressentimento ruim sobre essa estrada. Não sei explicar.
  - **Alba:** Fica. A gente fica. Aqui eu melhoro.
  - (ele para de empurrar; o balanço para sozinho)
- **Fim:** ele não responde. A cor falha pelas bordas.
- **Cinema:** o chamado é um rangido de corda vindo do balanço caído, ritmado, como se alguém estivesse nele. Segurar Up é a travessia: a cada meio segundo segurando, o balanço sobe um pouco e a cor sobe junto pela corda; soltar Up antes do fim faz a cor recuar. Quando o balanço chega ao galho, ele balança sozinho uma vez, e o branco. A memória abre nas mãos dela na corda, em plano fechado, no fim de tarde laranja. Quando o balanço para sozinho, a câmera não corta: fica parada nos dois em silêncio até a cor falhar.

### 4. A insistência, e ela cedendo por amor (gatilho: objeto recorrente)

- **Quando:** com 3 guardiões restaurados. **Onde:** a fita, de novo, numa região do mundo (a do terceiro guardião restaurado). É a segunda vez que o objeto aparece: o jogador já sabe o que ela é.
- **Jogo:** noite. O jardim só com a luz da lua. Ela está de pé à beira do poço, de costas. Ivo anda até ela (o único controle é andar; Up perto dela). É o mais contido de todos: quase sem música, só a água.
- **Falas:**
  - **Ivo:** A carroça sai antes do sol. Eu já falei com o carroceiro.
  - (silêncio)
  - **Ivo:** Eu não vou ficar parado vendo.
  - (ela vira; olha para ele muito tempo)
  - **Alba:** Está bem.
  - **Alba:** Por você.
- **A assinatura:** quando ela diz "Por você.", a borda dela falha por um instante (o glitch de borda das criaturas e dos guardiões, uns 0,3 s). Ninguém comenta, e não se repete em nenhum outro flashback.
- **Fim:** ela tira a fita do cabelo e amarra no pulso dele. A cor falha pelas bordas.
- **Cinema:** o chamado é a fita outra vez, agora parada, sem se mexer: o jogador já sabe o que ela traz. A travessia é a mais curta, sem ondas de cor: um corte quase direto para a noite. A memória quase não tem música, só a água e a luz fria da lua; a câmera fica larga e distante, e só fecha nela no "Por você.", onde a borda dela falha. É o único corte seco dentro de uma memória. A volta é sem som: a imagem some em silêncio, e o presente também.

### 5. A canção de ninar (gatilho: som, o mais forte)

- **Quando:** com os 4 guardiões restaurados (antes da batalha final). **Onde:** no jardim, que a essa altura já voltou quase todo. A cachoeira corre, e o som da água vira, aos poucos, a voz dela cantando a canção de ninar.
- **Jogo:** crepúsculo. Ela está sentada sob a árvore velha, com a filha dormindo no colo (a filha na idade de hoje, um pouco menor). Ivo anda até elas; Down senta ao lado. Depois de sentado, o jogador não faz mais nada: só escuta. A canção de ninar inteira (`wife_song_lullaby`), menos o fim.
- **Falas:** nenhuma, até o último verso.
  - **Alba:** (baixinho, para a filha) Lembra dessa, tá? Mesmo se esquecer o resto.
- **Fim:** a canção chega à lacuna e a cor falha antes do fim. Ela nunca é vista doente nesta cena (01 §9.3: "nunca mostrada diretamente").
- **Cinema:** o chamado começa fora do jardim: ao chegar ao moinho, o som da cachoeira já vem com a voz dela por baixo, e cresce a cada passo rio acima. No jardim não há corte: a travessia é contínua, a cor sobe ao ritmo da canção enquanto Ivo anda, e o jogador entra na memória sem perder o controle. O crepúsculo vai escurecendo ao longo da canção. Quando Ivo senta, a câmera recua devagar até o plano mais largo do jogo: os três pequenos sob a árvore, a cachoeira, o céu. Na lacuna, a voz para no meio da nota e a imagem falha toda de uma vez. O presente fica cinco segundos em silêncio.

### No caderno

Cada flashback visto deixa uma página na aba Memórias (o diário de Ivo), escrita por ele, curta. Exemplo do 1º: "Ela cantava sem esperar por mim. Eu sempre chegava atrasado na nota." Os textos das cinco páginas entram na construção, para aprovação.

## 3. Os fragmentos de portador (STORY-04)

Um por tubo: os quatro tubos que os quatro guardiões dão (01 §5). O tubo de inverno do mentor não tem fragmento comum: o dele é o fragmento final, já construído na batalha final (GRD-06).

- **Quando:** na primeira vez que Ivo toca a canção do guardião restaurado, fora de uma luta, depois que o efeito da canção termina. É o "tocar o tubo pela primeira vez" de 01 §6.
- **Estética:** só a cor da estação desenhada como gravura (traço de uma cor sobre o cinza do mundo), em quatro ou cinco quadros fixos com um movimento lento de câmera e poucas camadas que se mexem, com faixas pretas. Uma ou duas linhas de legenda por quadro, sem retrato e sem caixa de diálogo. Não reaproveita a cor persistente dos flashbacks nem a estética do fragmento final. Uns 30 s, e dá para pular.
- **Quem são os portadores:** proposta: **cada portador é a mão que escreveu o caderno de canções da mesma estação** (`07_achados.md`). O caderno é o que a pessoa escreveu; o fragmento é o que o tubo lembra dela. Se o caderno já foi achado, o jogador reconhece a pessoa; se não, acha depois. O fragmento nunca fala da rachadura (reservada ao fragmento final).

### Primavera: o caule vivo (Guardião da Flor, Enraizar) — "a mão de terra"

1. Neve num campo vazio. Uma mulher velha, de joelhos, enterra um caule verde na neve.
   *Ninguém plantava no inverno. Ela plantava assim mesmo.*
2. O caule cresce sob a neve; ela canta para ele.
   *Ela dizia que a terra escuta quem volta todo dia.*
3. Anos depois: um bosque onde era o campo. Ela, curvada, corta um único caule e o entrega ao cervo de madeira.
   *Deixou o bosque com quem ia ficar.*
4. O caule na mão do guardião: ainda verde.
   *O caule nunca parou de crescer.*

### Inverno: o galho petrificado (Guardião do Gelo, Congelar) — "a mão de inverno"

1. Um lago escuro de noite; uma aldeia na margem de lá, sem ponte.
   *A aldeia do outro lado não tinha ponte, e o inverno chegava tarde.*
2. Um homem com uma lanterna na margem toca, e o lago congela sob os pés dele, passo a passo.
   *Ele não sabia nadar. Sabia esperar o frio.*
3. Gente atravessa atrás dele, com fardos.
   *Fez a estrada por um inverno inteiro.*
4. Ele, velho, enterra o galho no gelo; o golem de pedra o recolhe.
   *Quando parou de andar, deixou o caminho onde estava.*

### Outono: o osso oco (Guardião da Folha, Soltar) — "a mão inquieta"

1. Um rapaz no alto de um penhasco, com o vento nas costas.
   *Ele nunca ficava num lugar até a folha cair.*
2. Ele segue um bando de pássaros pelos pomares; uma ave cai, e ele a segura.
   *A ave que ele não conseguiu manter.*
3. Ele faz uma flauta do osso da asa e toca; as folhas se soltam das árvores todas juntas.
   *Aprendeu que soltar também é uma canção.*
4. Ele deixa a flauta pendurada no espantalho e vai embora com o vento.
   *Foi o único que partiu sem pedir para ficar.*

### Verão: a pedra furada (Guardião do Sol, Sombra) — "a mão antiga"

1. A caldeira ao meio-dia; uma mulher muito velha sentada na pedra, imóvel.
   *Ela era velha quando a montanha ainda fumava.*
2. O sol para no alto enquanto ela toca; as sombras queimam na pedra.
   *Segurava o dia mais longo para quem precisava de mais tempo.*
3. Ela fura uma pedra vulcânica com um espinho, devagar, ao longo de muitos dias.
   *Ninguém viu quanto tempo levou. Ela tinha tempo.*
4. A pedra entre as patas do leão; a sombra dela fica na pedra quando ela já não está.
   *Ficou a sombra. Isso basta para o verão.*

### No caderno

Cada fragmento visto deixa uma página na aba Memórias (01 §6: o caderno guarda os fragmentos, um por tubo), com o tubo desenhado e as legendas do fragmento. Proposta para reabrir: só leitura na página; reassistir fica para depois.

## 4. O retorno e o epílogo (STORY-07)

Ordem de 01 §9.4: batalha final → restauração do mundo (já construída: `world_restoration`) → **retorno** → **cena final da Memorina** → **créditos**.

### O retorno (vila a 1.0)

- Depois da conversa do mentor na lanterna, Ivo volta para casa **a pé**, pelo mundo restaurado inteiro: uma volta de vitória, com o jogador no controle.
- **A vila lembra todas as estações** (01 §8): "O ano volta a passar (Recommended)". A 1.0 a vila percorre as quatro estações devagar, com a arte nas faixas de estação que já existem (`systems/seasonal-art`): o cinza era o tempo parado, e agora o tempo anda. O ritmo (uma estação a cada poucos minutos, ou uma a cada volta à vila) se decide na construção, no playtest.
- **As vozes da vila a 1.0:** uma fala nova para cada aldeão (padeira, taverneiro, aguadeira, vendedora, menino), escrita na construção para aprovação. A regra do sistema vale: cada voz de 0.6 ganha um `unless` para 1.0 antes.
- **A filha:** em casa. Ela corre até ele. Ele não pega o violão.
  - **Filha:** Você voltou colorido.
  - **Ivo:** O mundo voltou.
  - **Filha:** E a música da mãe?
  - **Ivo:** Ainda falta um pedaço.
  - **Filha:** Ela cantava no jardim. Você me levava lá, lembra? Vai lá.
  - (ela devolve a fita — achada no pulso dele no 4º flashback e caída em casa — ou a cena segue sem a fita; detalhe da construção)
- Daí em diante, o jardim tem um gatilho do epílogo (todos os guardiões restaurados e o mundo restaurado).

### A cena final da Memorina (no jardim)

Cena, uma peça só (`wife_song_epilogue`). Proposta: as falas de referência de 01 §9.4, inteiras (a versão principal, não a de reserva):

- *Ele toca a melodia dela na Memorina. A mesma lacuna de sempre. Para. Ela está ali.*
- **Alba:** Você ainda carrega aquele dia.
- **Ivo:** Eu devia ter escutado você.
- **Alba:** (silêncio) Aquele dia nunca pesou em mim do jeito que pesa em você.
- **Ivo:** Por quê?
- **Alba:** Porque eu te amava. Isso nunca dependeu de você ter acertado.
- **Ivo:** Eu ainda erro a mesma nota.
- **Alba:** (um leve sorriso) Erra. Toca assim mesmo.
- *Ele toca. No ponto exato da falha, o som continua: a voz dela segue a flauta um tempo atrás e canta o fim perdido, subindo ao Lá que a Memorina não tem; ele sustenta o Sol embaixo. A melodia termina inteira e imperfeita. Ele levanta o olhar; ela não está mais lá.*

A regra do sistema ("o violão nunca termina a canção da manhã") continua intacta: quem termina é a voz dela, na Memorina, numa cena.

- **Cinema:** o jardim inteiro em cor pela primeira vez no presente, ao fim da tarde. Ivo senta na pedra lisa onde ela cantava no 1º flashback e toca; a câmera fica nele, de perto. Na lacuna ele para, e o silêncio dura. A câmera recua e Alba está sentada ao lado dele, sem transição nenhuma: ela não aparece, já estava ali. Sem faixas pretas, sem pontilhado, sem a borda que falha: ela está em cor plena, como o mundo. Na última frase ("Erra. Toca assim mesmo.") a câmera fecha nos dois. Quando ele toca de novo, a câmera sobe devagar pela cachoeira até o céu enquanto as duas vozes seguem; quando volta para baixo, só Ivo está na pedra, e a última nota é só dele. Antes de tocar de novo, ele diz o nome dela: **Ivo:** Alba.

### Os créditos

Rolam sobre o jardim em cor, com a música do epílogo e depois o tema do título. **Depois dos créditos**, Ivo está de volta no jardim, com o jogo salvo, para continuar andando pelo mundo restaurado ("a"). Se a tela de vitória (UI-06) ainda tem sentido com isso fica para depois.

## 5. O que isto pede além do texto

**Arte (cada peça com um contrato em `tools/art/prompts/`, prancha primeiro):**
- **Alba**, personagem nova, ruiva, com a trança presa pela fita azul: conceito (Codex) para aprovar; depois clipes (PixelLab): parada, andando, sentada na pedra, cantarolando, colhendo, mão no peito e levantando, no balanço, de pé de costas e virando, sentada com a filha no colo; um retrato para a caixa de diálogo. Uns 10 clipes.
- **A filha dormindo no colo** (um clipe junto com a mãe) e **Ivo sentado no chão** (o 5º flashback).
- **O jardim:** tileset ou adereços (pedras, poço, cachoeira animada, árvore velha, balanço de corda, canteiros), nas versões de dia, fim de tarde, noite e crepúsculo (a noite e o crepúsculo podem ser luz sobre a mesma arte).
- **A fita** no mundo e no pulso de Ivo.
- **Os quatro fragmentos:** 16 quadros de gravura (4 por estação).

**Som:** a água da cachoeira; o vento no jardim. As vozes dela já existem (`wife_song_full`, `_lullaby`, `_epilogue`).

**Mapa:** `village_garden`, uma tela nova junto do `village_mill` (sala, região e `.room` pelo `gen_world_shells.py`, `systems/world`).

## 6. Pontos em aberto

1. **O visual de Alba, além de ruiva:** proposta: trança comprida e solta, presa pela fita azul de centáurea; vestido simples de linho cru com avental; sardas. A prancha de conceito mostra isso para aprovar.
2. **O ritmo do ano na vila a 1.0** (uma estação a cada poucos minutos, ou uma a cada volta), no playtest.
3. **A tela de vitória (UI-06)** depois dos créditos, se ainda tiver sentido.
