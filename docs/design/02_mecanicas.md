# Cantomória / Memorina — Mecânicas de Jogo
 
*Documento de design, versão de trabalho*
 
> Este documento cobre combate, sistema musical, puzzles e a estrutura mecânica da Grande Provação/Batalha Final. Lore e narrativa estão em `01_Lore_e_Narrativa.md`. Referências cruzadas indicam onde os dois se encontram.
 
---
 
## Visão Geral
 
**Gênero:** Metroidvania 2D, exploração e ação.
 
**Core loop:** Explorar região → enfrentar criaturas comuns em combate físico → encontrar criatura-professora ou fragmento de lore → chegar a um guardião → resolver puzzles musicais no caminho → enfrentar guardião (pressão física → janela de lucidez → call-and-response) → restaurar guardião (nova sequência musical, novo tubo, possível habilidade física via memória pessoal) → repetir em nova região, com vocabulário musical maior e puzzles mais complexos.
 
### Controles
 
| Ação | Tecla |
|---|---|
| Movimento | Setas |
| Rolar | Shift |
| Pular | Z |
| Atacar | X |
| Abrir caderno de campo | E |
| Pause | Esc |
| Sacar Memorina | C |
| Abrir mapa | M |
| Notas da ocarina (com Memorina sacada, parado em chão firme) | WASD + Setas |
 
*Nota de design:* WASD e Setas cumprem dupla função (movimento do personagem e notas da Memorina) sem conflito, porque a Memorina só pode ser tocada com o personagem parado — os dois contextos nunca ocorrem ao mesmo tempo.
 
## Vida, Derrota e Pontos de Restauração
 
**Vida:** o herói tem 3 unidades de vida, representadas por um ícone temático (não barra). Formato visual exato a definir.
 
**Derrota:** não existe game over tradicional. Ao perder toda a vida, o jogador reaparece no último ponto de restauração (banco), sem perder progresso material — nenhum item, sequência musical ou habilidade é perdida. A única consequência é atmosférica: um pequeno símbolo do cinzesquecimento aparece a mais na região da morte, um detalhe de cenário sem efeito em gameplay. Mortes acumuladas numa mesma região se somam visualmente, de forma discreta.
 
*Nota de design:* essa penalidade é deliberadamente fraca em termos de custo tático — decisão consciente de manter o risco real concentrado no QTE de habilidades físicas (ver seção 4), não na morte geral. A ausência de "recuperar o que foi perdido" reforça o tema central do jogo: aceitar a perda, não insistir em reter à força.
 
**Vitória:** derrotar o guardião-mentor na Grande Provação/Batalha Final, restaurando o mundo.
 
**Pontos de restauração (bancos):** espalhados pelo mapa com mais frequência que os marcos de guardião. Sentar num banco recupera a vida cheia e salva o progresso no mesmo gesto. Função dupla: mecânica (cura e checkpoint) e de ritmo — força uma pausa deliberada, reforçando o tom contemplativo do jogo. Coexistem com os pontos de restauração de guardião, que continuam marcando progresso de história/mundo.
 
## Interface de Usuário (UI/HUD)
 
- **Memorina (partitura):** aparece apenas quando o jogador saca o instrumento (tecla C), com um zoom suave da câmera sobre o herói, no espaço livre à frente dele (ou atrás, se ele já estiver encostado nesse lado). É uma pauta: cada nota tocada é desenhada na linha da sua altura (G4 em cima, C4 embaixo) com o ícone do botão físico usado — seta, WASD, Xbox ou PlayStation. Some ao guardar. (Ver seção 6.2 para a regra de execução.)
- **Caderno de campo (tecla E):** dividido em seções — Lore (diário do personagem + fragmentos de portador), Canções aprendidas, Itens colecionáveis, Guardiões (registro de guardiões conhecidos e estado de corrupção).
- **Mapa (tecla M):** elemento separado do caderno. Estilo Metroid clássico — contorno se desenha por exploração. Deliberadamente pouco detalhado mesmo depois de revelado, sem indicar posição exata ou rota ótima — reforça a intenção de tentativa e erro na navegação.
- **Indicador de vida:** ícone temático (estilo máscara/coração), sempre visível, não barra.
- Telas de menu (inicial, pause, vitória): a definir.
---
 
## 1. Princípios gerais
 
- **Dois domínios mecânicos separados, sem mistura fora do confronto com guardião:** trilha física (combate e mobilidade pessoal) e trilha musical (mundo, exploração, puzzle, lore). Cada uma tem seu próprio verbo — física é para agir rápido no mundo, música é para entender e curar o mundo.
- **Timing preciso é o fio condutor entre os dois domínios.** Tanto o combate físico (parry) quanto a execução musical (call-and-response, puzzles) pedem a mesma habilidade central do jogador: sentir o tempo certo de agir. Jogador bom em um fica naturalmente melhor no outro, sem serem sistemas didaticamente desconectados.
- **A Memorina nunca é usada em combate comum.** Só entra em jogo dentro do confronto com guardiões — reservar a fusão física+musical para esse momento único preserva seu peso ritual. Única exceção, deliberada e sem ataque: a sombra deixada por **Sombra** é vista pelas criaturas como o herói e pode atraí-las (seção 7.1).
## 2. Combate físico (mobs comuns e criaturas-professoras)
 
Estilo fluido e rápido — referência Hollow Knight com tempero de jogo de ação rítmico (Hi-Fi Rush), nunca modelo tanque-e-pare (Souls).
 
- **Movimento é arma:** rolamento com i-frames — restrito ao chão, ferramenta de esquiva ofensiva no combate, não de mobilidade aérea —, ataque aéreo, wall-jump. Repertório clássico de metroidvania, construído para permitir combo fluido entre mobilidade e ataque, sem pausas.
- **Combo leve/pesado simples**, não árvore de combo profunda — dois ou três inputs que se encadeiam, priorizando ritmo de execução sobre memorização de combo.
- **Parry como ferramenta central**, não nicho — usa o mesmo timing que a Memorina pede, reforçando a coerência entre os dois sistemas.
### Inimigos comuns
 
- **Criaturas corrompidas:** fauna local distorcida por tempo demais numa região em avançado cinzesquecimento. Silhueta e comportamento reconhecíveis da região, mas com o mesmo glitch visual de borda perdendo definição usado em guardiões e flashbacks — assinatura visual coesa em todo o jogo.
- **Criaturas-professoras:** encontros especiais, não hostis por padrão. Cada região tem uma criatura ligada à sua estação/material que ensina um fragmento de padrão musical através do próprio comportamento — tutorial diegético por observação e imitação, antes do guardião daquela região.
## 3. Guardiões comuns — estrutura de três fases
 
1. **Fase de pressão física:** o guardião ataca através de padrões ligados à sua estação. O jogador desvia, se posiciona, ataca para abrir brechas — não para "matar", mas para forçar instabilidade que abre a fase seguinte.
2. **Janela de lucidez:** o guardião pausa, tremendo entre a versão corrompida e a lúcida. Aqui entra o call-and-response — o jogo apresenta uma sequência (literal para guardiões mais lúcidos, fragmentada/sugerida para os mais corrompidos) e o jogador reproduz **com timing real**, sem pausa do mundo.
3. **Consequência:** acertar com bom timing estabiliza o guardião, abre dano real ou avança a cura. Errar não é game over — o guardião recai na fase de pressão mais cedo e mais agressivo.
Estações não limitam o número de guardiões — múltiplos guardiões por estação, cada um com variação regional dentro do vocabulário melódico daquela estação (ver seção 7).
 
## 4. Habilidades progressivas — duas trilhas paralelas
 
### Trilha física — habilidades pessoais recuperadas
 
**Decisão fechada:** habilidades físicas não vêm do ambiente restaurado nem são recompensa por vencer o guardião. Vêm do próprio herói recuperando, sob pressão extrema, uma capacidade física que ele já tinha antes do luto — o corpo lembrando o que a mente esqueceu. Coerente com o tema central de memória.
 
Cada habilidade deveria ecoar algo específico da vida do herói antes do luto (a definir em sessão de lore): um rolamento que lembra correr atrás da filha, um golpe carregado ligado a um ofício antigo, a última habilidade — perto do fim — mais carregada emocionalmente, talvez ligada à esposa.
 
#### O QTE de emergência — versão final
 
- **Gatilho:** ataque inesquivável específico daquele guardião, único por habilidade, não reutilizado como padrão geral do jogo.
- **Sinal:** tempo desacelera, cor nasce ao redor da cabeça/olhos do herói — origem no corpo, não no instrumento. Reaproveita a gramática visual de "cor = memória verdadeira" já estabelecida nos flashbacks.
- **Comando:** prompt de botão claro, ensinado na hora — sem ambiguidade de execução.
- **Falha:** possível, com custo tático real (dano ou equivalente em risco). Sem penalidade de progressão — o mesmo gatilho reaparece mais adiante na fase de pressão daquele guardião, quantas vezes for necessário.
- **Garantia:** a habilidade é sempre adquirível dentro daquele encontro — necessária para progressão, o jogador não sai do combate sem ela.
- **Confirmação:** caderno de campo, pós-combate, registro curto e não-didático — nunca popup de UI, nunca explicação na hora.
### Trilha musical — sequências de notas
 
Ver seção 7 para o sistema completo. Cada guardião restaurado libera um novo tubo (material da região) e, potencialmente, uma ou duas sequências de notas novas — não necessariamente as duas de sua estação de uma vez (ver seção 7.2).
 
## 5. A Grande Provação / Batalha Final
 
**Decisão estrutural fechada nesta sessão:** Grande Provação e Batalha Final são o mesmo evento — o confronto final contra o guardião-mentor, que é também o guardião da rachadura (ver `01_Lore_e_Narrativa.md`, seção 4). É o pico de dificuldade mecânica do jogo, e dificuldade/lore convergem sem forçar nada: ele é o guardião mais corrompido porque é a própria origem da corrupção.
 
A recompensa não é a saúde do mentor (relação funcional, não afetiva) — é sistêmica: o mundo inteiro se restaura como consequência direta da vitória. Isso substitui a "restauração da vila em escala total" como evento jogável separado; ela vira consequência automática/cinemática.
 
### 5.1 Estrutura do confronto
 
**Fase de pressão física (só Inverno):** o combate começa como qualquer outro guardião — só o padrão de Inverno, lento e pesado. O jogador não sabe ainda que existe uma segunda frequência.
 
**Gatilho da revelação:** dispara por dano acumulado ou número de ciclos de lucidez completados — o jogador precisa ter vencido pelo menos uma janela de lucidez normal (só Inverno) antes da revelação acontecer. Garante que ele já teve sucesso com a mecânica-base antes do jogo complicar tudo.
 
**O evento de revelação (único, não se repete):**
 
- Acontece **dentro** de uma janela de lucidez — não é pausa externa nem cutscene separada. É tratada como uma janela de lucidez anômala e mais profunda, usando o mesmo vocabulário que o jogador já reconhece (tempo desacelera, cor muda).
- O jogador **nunca solta o controle** da Memorina — usa o mesmo input de call-and-response que já vem usando na luta. Não aprende comando novo.
- O sprite do herói perde contorno definido, vira **silhueta ambígua** pulsando na cor de dissonância — não troca literalmente para o guardião original; é deliberadamente incerto de quem é a memória.
- O jogador tenta tocar as duas frequências ao mesmo tempo (sem alternativa disponível ainda) — revivendo o próprio erro do guardião original, sem punição real porque é passado, fixo.
- Termina em colisão/estilhaçamento visual.
- Duração curta — poucos segundos de gameplay real, o suficiente para sentir a dissonância bater, não o suficiente para virar sequência narrativa longa.
- **Retorno sem re-entrada:** combate retoma imediatamente na mesma pose/estado físico de quando a janela começou, sem hiato, sem tela de carregamento. Padrão de duas frequências já ativo dali em diante.
### 5.2 Estética da revelação (pixel art 2D)
 
Técnicas nativas de pixel art, não geometria de "tela rasgando":
 
- **Glitch de paleta/dithering progressivo:** cores de Inverno invadindo áreas neutras, dithering que normalmente seria transição suave ficando errático — estética de memória corrompida.
- **Deslocamento de scanlines:** fileiras horizontais do cenário presente deslizando horizontalmente, alternando com fileiras do cenário passado — entrelaçamento de vídeo quebrado, tecnicamente barato (shader de offset por linha).
- **Flicker de sprite:** o herói e a versão passada (guardião original) alternam visibilidade em ritmo acelerado até fundir — técnica clássica 2D para sobreposição temporal, sem precisar de efeito 3D.
- **Freeze frame** no momento de impacto/colisão (technique clássica de pixel art para peso de impacto), depois estabilização rápida — scanlines param, paleta normaliza, contorno do herói volta.
Todas as três técnicas atingem pico simultâneo no momento da tentativa de tocar as duas frequências juntas.
 
### 5.3 Mecânica de dissonância — punição e resolução
 
Aplicada tanto na cena de revelação (sem solução disponível) quanto no restante da luta (agora como desafio real, com solução).
 
**UI:** duas trilhas de notas apresentadas simultaneamente — duas trilhas visuais distintas ou duas cores de prompt na mesma linha de tempo, deixando claro que são dois "chamados" concorrentes.
 
**Se o jogador tenta tocar as duas juntas:**
- A partir do segundo input misturado, a tela perde saturação de um jeito distinto do grayscale padrão do mundo — cinza instável, tremendo, quase estática.
- Dano ao jogador escala progressivamente: primeira tentativa é aviso brando, tentativas seguintes doem mais.
- A janela de lucidez encolhe mais rápido com dissonância ativa — o guardião recai na fase de pressão mais cedo.
**Quando o jogador para e escolhe uma trilha só:**
- A trilha ignorada desaparece visualmente aos poucos, sem punição — silenciar não é falhar, é a ação correta.
- Cor estabiliza de forma limpa (pulso normal de invocação musical), call-and-response final começa — a sequência mais longa/complexa do jogo, agora sem ruído da segunda estação competindo.
Isso testa a lição central do jogo (aceitar, soltar, não insistir em reter com força) em sistema, não em diálogo — o jogo pune ativamente tentar ter as duas coisas e recompensa com alívio de pressão o ato de escolher.
 
## 6. Puzzles ambientais
 
### 6.1 Princípios
 
- Puzzles são resolvidos pela trilha musical (sequências de notas), não pela trilha física — mantém a separação de domínios.
- Mistura equilibrada de puzzles **espaciais** (travessia, plataformas, alcançar lugares) e **lógicos** (mecanismos, ordem de ativação), variando por região.
- **Curva de complexidade:** primeira metade do jogo — um tubo por puzzle. Segunda metade — combinação rotineira de 2-3 tubos.
- **Nenhum efeito de puzzle é permanente.** Toda sequência de notas gera um pulso temporário (mesma regra visual do mundo: cor sustenta, depois contrai conforme o cinza reconquista o espaço). Puzzles são, por natureza, sempre contra o relógio.
- **Atalhos permanentes pós-resolução** (modelo Hollow Knight): a primeira vez que um puzzle é resolvido, abre uma consequência física permanente no mundo (alavanca destravada, escada solidificada, elevador que passa a operar sozinho) — o efeito de nota em si continua temporário, mas o mundo guarda o resultado de tê-lo resolvido.
- **Reativação livre:** a Memorina nunca foi limitada por região. O jogador pode tocar qualquer sequência já aprendida em qualquer lugar do mapa, independente da estação nativa daquele local — mesmo depois de um guardião restaurar a estação natural da região permanentemente. Restaurar um guardião adiciona a estação de repouso permanente do local; não remove a possibilidade de pulsos temporários de qualquer outra sequência por cima.
### 6.2 Regra de execução — como o jogador toca
 
- **UI:** uma partitura de seis posições, preenchida nota a nota conforme o jogador toca. Nenhuma indicação de quais canções existem ou estão travadas — a UI mostra o que foi tocado, não o que pode ser. (A grade de 8 tubos foi descartada; a lore do instrumento remendado fica para o caderno de campo.)
- **Execução em tempo real, sem pausa do mundo** — mesma implementação usada no call-and-response de guardião. Sistema único, não dois modelos diferentes. Cada nota tem seu som, e a próxima só pode ser tocada quando o som da anterior termina — o ritmo do instrumento é o ritmo do jogador.
- **Resposta do instrumento:** completada a sequência, a última nota soa até o fim e então o mundo congela enquanto o instrumento responde com um trecho curto da canção (o motivo, as mesmas seis notas), acendendo na partitura cada nota conforme ela soa. O pulso de cor nasce exatamente quando o trecho termina, o mundo volta a andar e a Memorina é guardada sozinha — a resposta encerra o gesto. A canção completa só é ouvida uma vez, ao ser aprendida, com o mesmo congelamento e a mensagem "Você aprendeu a tocar" mais o título da peça no topo da partitura.
- **Restrição obrigatória: a Memorina só é tocada com o personagem completamente parado, em chão firme.** Nunca no ar, nunca em movimento. Essa regra existe antes de qualquer outra consideração de puzzle — puzzles que dependeriam de tocar durante queda ou salto foram redesenhados para respeitá-la (ver seção 7.4).
- **Input:** sequência de botões direcionais (referência: Ocarina of Time), não seleção de item por menu ou lista.
- **Erro de sequência:** a nota errada não soa — o som de erro da Memorina toca no lugar dela, o ícone é desenhado e a partitura pisca; só então a sequência volta a vazio. Sem popup, sem penalidade de recurso (vida, tempo). O jogador tenta de novo assim que o som de erro termina. Uma sequência que não corresponde a nenhuma canção aprendida falha da mesma forma.
- **Apoio de memória:** o caderno de campo registra as sequências já aprendidas, consultável fora do momento de execução — decorar é necessário para jogar fluido, mas existe rede de segurança contra esquecimento.
- **Nenhuma sugestão contextual na UI.** O ambiente (cor, textura do material) é responsável por comunicar qual sequência resolve o quê — coerente com a filosofia geral de não expor mecânica.
## 7. Sistema de sequências de notas — as 8 sequências

Cada estação carrega duas sequências de notas distintas, não uma. Isso amplia o vocabulário de puzzle e evita reciclagem de função disfarçada entre estações.

**Critério de toda sequência (decisão fechada, 2026-09-23):** uma sequência é um **verbo físico sobre um sistema que o mundo já tem** — água, vento, peso, terra, o próprio pulso —, nunca uma chave para uma fechadura feita sob medida para ela. Ela abre uma janela que o jogador então usa com o corpo, antes que o cinza a feche. E ela se relaciona com o tempo: o cinza é o tempo parado, e cada estação lembra um jeito diferente de o tempo correr.

### 7.1 Matriz de sequências por estação

**Inverno (galho petrificado) — o inverno guarda**
- **Congelar** — solidifica água em movimento, cria plataforma temporária. Ver `03_mundo_e_ambiente.md`, seções 6.3 e 6.4.
- **Redoma** — a borda do pulso vira uma casca fina de geada, que encolhe junto com ele. Regra única: **nada entra, tudo pode sair.** Segura a água do lado de fora (tocada na beira de um poço, deixa o fundo seco para atravessar, e a água volta a entrar atrás do jogador conforme a casca encolhe), abriga do vento (Vendaval e clima), da chuva e do que cai. Por fora é sólida: o que cai em cima rola pela curva, e quem saiu pode subir nela. Barra **matéria, não criaturas** — criaturas atravessam, para que a Redoma nunca vire escudo de combate. Nome e imagem: a redoma de vidro que conserva o que está debaixo dela; e sair dela nunca é impedido.

**Outono (osso oco e leve) — o outono solta**
- **Soltar** — tudo o que está preso dentro do pulso se solta: folhas caem e revelam o que escondiam, frutos, casulos, contrapesos, cargas penduradas e pontes levadiças descem. É o verbo temático do jogo (*aceitar, soltar, não insistir em reter* — seção 5.3) ensinado como mecânica, muito antes da dissonância pedir o mesmo gesto.
- **Vendaval** — rajada de vento radial, soprando para fora a partir da origem do pulso. Empurra objetos leves e o próprio jogador pelo mesmo canal físico do clima e da correnteza (`03_mundo_e_ambiente.md`, seções 5.3 e 6.1); o jogador, parado no olho, não é arrastado até sair dele. Numa corrente de vento natural, soma-se a ela.

**Primavera (caule vivo) — a primavera liga**
- **Enraizar** — regra única: **raízes ligam terra a terra.** Onde duas superfícies de terra se encaram e ambas estão dentro do pulso, raízes crescem atravessando o vão. Entre duas margens, uma ponte; entre as paredes de um poço vertical, degraus empilhados; do chão ao teto, um pilar; em volta de um objeto que esteja no vão (um bloco caindo, uma plataforma balançando), raízes que o seguram. Só terra enraíza, nunca pedra — o material diz ao jogador onde a canção serve (seção 6.2). Não se mira: o jogador se posiciona de modo que o pulso cubra as duas pontas. As raízes crescem na velocidade da memória sob elas (como o gelo) e murcham onde o cinza volta, então uma ponte se rompe pelas pontas primeiro.
- **Chuva** — chove dentro do pulso: poças sobem, bacias secas enchem, nascentes voltam a correr, o que boia sobe junto. Conforme o pulso contrai, a água baixa ao nível de antes. Os níveis que a água alcança são autorais (`03_mundo_e_ambiente.md`, seção 6.5). É também o clima que faltava à Primavera: a garoa.

**Verão (pedra vulcânica furada) — o verão fica**
- **Sombra** — o sol a pino, a luz mais dura do ano, queima a sombra do herói no chão onde ele tocou. A sombra **conta como o herói estando ali**, até o pulso fechar: pesa o que ele pesa (placas de pressão, balanças, plataformas que afundam, portas que só ficam abertas com alguém em cima) e **é vista pelas criaturas como ele** — elas se viram para ela, vão até ela, atacam-na, enquanto o herói está em outro lugar. É a exceção deliberada à regra da seção 1 (ver nota abaixo). A imagem prepara a Batalha Final: o jogador passa o jogo deixando silhuetas de si mesmo para trás antes de o próprio sprite virar silhueta ambígua (seção 5.1).
- **Solstício** — o dia mais longo. Age sobre a memória, não sobre o mundo: todo outro pulso que se sobreponha ao seu dura mais e alcança mais longe. Sozinho, segura a cor num lugar morto por mais tempo (a água corre, o relógio anda). É o que torna possíveis as combinações longas da segunda metade do jogo, e por isso é ensinado tarde, por fragmento de portador (seção 7.2).

**Nota de design — Sombra e o combate comum.** A seção 1 diz que a Memorina nunca é usada em combate comum. A Sombra é a única canção que toca nesse limite, e toca de propósito: ela **não fere**, só distrai, e tocá-la exige estar parado em chão firme, então ela é preparada antes do confronto, nunca executada no meio dele. A Memorina continua sem ataque. Atrair uma criatura com a Sombra é uma alternativa tática ao combate, na linha da antiga Hibernação (ver "A isca", seção 8).

*Sequências descartadas ao longo do processo de design (registradas para não serem re-propostas):*
- *Primeira rodada: Miragem, Renascer, Florescer, Chamado/Convocar vida, Fermentar/Converter, Polinizar em cadeia, Amolecer, Acelerar ciclo, Brotar em cadeia vertical.*
- *Matriz anterior, substituída em 2026-09-23: **Ventania/Nevasca** (virou Vendaval, no Outono), **Hibernação** (a terceira canção de Inverno, que não cabia na grade), **Sol Concentrado**, **Tempestade Repentina** (mirada à distância, contra a regra de tocar parado com pulso radial), **Fragilizar** e **Despir** (chaves de fechadura; Despir ainda era permanente, contra a seção 6.1; Soltar absorve o que Despir revelava), **Brotar** (absorvida por Enraizar), **Eclodir**.*
- *Propostas e recusadas na mesma sessão: **Quietude** (parar o que se move — confunde com o cinza, que já é o tempo parado), **Térmica** e **Fervura** (a mesma corrente ascendente com outra aparência), **Rastro** e **Eco** (mostram o passado em vez de mudar o mundo), **Nevar** (três efeitos sem uma ideia única), **Geada** (atrito zero, perto demais do gelo de Congelar), **Queimada**, **Dilatar** (só funciona onde houver metal posto para isso), **Mormaço** (lentidão, parente de Quietude), **Ressonância** (o pulso renascendo em pedras ocas; dependente demais de objetos autorais e inerte sozinha).*

### 7.2 Distribuição entre guardiões e forma de aprendizado

- Nem toda sequência é ensinada no mesmo guardião/batalha. Com múltiplos guardiões por estação, a sequência "faltante" de um guardião pode vir de outro guardião da mesma estação, em região diferente.
- **Regra:** pelo menos um guardião de cada estação ensina a sequência base pelo call-and-response do próprio combate. A segunda sequência daquela estação é ensinada através do fragmento de portador — do mesmo guardião ou de outro da mesma estação, a critério do design de cada região.
- Isso separa claramente "o que aprendo lutando" de "o que aprendo ouvindo a história", e dá ao jogador razão mecânica para visitar todos os guardiões de uma estação, não só o primeiro que encontrar.
- **Solstício é sempre de fragmento**, e tardio: sozinho ele faz pouco, e só se entende depois de o jogador já ter corrido contra o relógio de outras canções.

### 7.3 Regras comuns a todas as sequências

- **Nada vive fora da memória.** Tudo o que uma canção faz cresce na velocidade da memória sob ele (a frente de gelo, as raízes, a água subindo) e termina onde o cinza volta. Nenhuma canção atravessa um trecho morto.
- **O cinza guarda o estado antigo.** Quando o pulso contrai, o mundo volta a ser como era antes dele: a água volta ao nível, as raízes murcham, as folhas caídas voltam ao galho, a sombra some. É a regra da seção 6.1 (nenhum efeito é permanente) dita em termos do mundo. O que permanece é só o atalho autoral da primeira resolução.
- **A borda de gameplay é o disco limpo** do campo de memória, nunca o recorte pontilhado que o shader desenha — vale para a casca da Redoma, para as pontas das raízes e para o alcance de toda canção.

### 7.4 Composição

As sequências se compõem porque agem sobre os mesmos sistemas, sem regra especial para cada par:

- **Chuva → Congelar:** uma bacia seca enche e vira chão de gelo — gelo onde nunca houve água.
- **Chuva → Enraizar:** terra molhada deixa as raízes alcançarem mais longe.
- **Vendaval sobre água → Congelar:** o vento levanta uma crista, o gelo a prende — uma rampa (a crista parada de `03_mundo_e_ambiente.md`, seção 6.2, agora escalável).
- **Soltar → Enraizar:** o que foi solto é apanhado no meio da queda, na altura certa. O outono solta, a primavera segura.
- **Redoma + Congelar:** a água apertada contra a casca congela numa parede curva, que fica quando a casca some.
- **Redoma + Chuva:** chove em volta, o bolsão continua seco.
- **Sombra + Soltar:** a sombra segura uma placa enquanto uma carga solta segura outra.
- **Solstício sob qualquer outra:** mais tempo, mais alcance — a ponte de raízes mais longa, o gelo que dura a travessia inteira, a sombra que segura a porta até o fim do corredor.

## 8. Puzzles concretos por estação

Dois puzzles espaciais e dois lógicos por estação — base de repertório, não lista fechada.

### Inverno

**Espacial 1 — Ponte de gelo cronometrada.** Queda d'água bloqueia passagem horizontal. Congelar cria ponte que descongela progressivamente; travessia contra o tempo. Primeira resolução trava um mecanismo lateral em posição permanente (atalho). *(Depende da pendência das quedas d'água, `03_mundo_e_ambiente.md`, seção 7.)*

**Espacial 2 — O fundo do poço.** Um poço cheio d'água, com uma passagem baixa na parede do fundo. Redoma tocada na beira empurra a água para fora da casca; o jogador desce pelo fundo seco até a passagem enquanto a casca encolhe e a água volta a entrar atrás dele.

**Lógico 1 — Tocar dentro da ventania.** Um mecanismo só responde a uma canção tocada num ponto varrido por rajadas naturais que interrompem qualquer sequência. Redoma primeiro abre um abrigo; dentro dele, o jogador toca a segunda canção. A ordem é a solução.

**Lógico 2 — A parede d'água.** Redoma na beira de um lago segura a água numa parede curva contra a casca; Congelar a prende. Quando a casca some, fica um arco de gelo que serve de rampa até uma saída alta — até derreter. Na ordem inversa não há parede para congelar.

### Outono

**Espacial 1 — A trilha sob a folhagem.** Uma parede de folhas secas esconde uma passagem lateral. Soltar derruba as folhas; a passagem fica aberta enquanto o pulso durar, e as folhas voltam ao lugar quando o cinza retorna.

**Espacial 2 — Empurrado pelo Vendaval.** Abismo largo com corrente de vento natural na sala. Tocar Vendaval na corrente existente soma-se a ela, empurrando o jogador através do vão — exige posicionamento exato antes de tocar.

**Lógico 1 — Os contrapesos.** Um elevador preso por dois contrapesos pendurados; soltar o errado trava o elevador embaixo. O jogador escolhe onde tocar para que o pulso cubra só o contrapeso certo — o raio do pulso é a ferramenta de seleção.

**Lógico 2 — A carga ao vento.** Um casulo pesado pendurado sobre uma borda, uma placa de pressão no fim dela. Soltar derruba o casulo na borda, Vendaval o empurra até a placa. Na ordem inversa, o vento não tem o que empurrar.

### Primavera

**Espacial 1 — A ponte de raízes.** Duas margens de terra sobre um abismo. De quase todo lugar o pulso não cobre as duas; o jogador precisa achar o ressalto de onde ele cobre, e atravessar antes que a ponte se rompa pelas pontas.

**Espacial 2 — O poço de terra.** Um poço vertical com paredes de terra. Enraizar enche o poço de degraus entre as paredes; a subida é por saltos, degrau a degrau, até o pulso contrair.

**Lógico 1 — Terra e pedra.** Uma sala que mistura faces de terra e de pedra. Só alguns pares se ligam; o jogador lê o material e escolhe o ponto de tocar que monta uma rota inteira.

**Lógico 2 — A bacia seca.** Uma bacia vazia com um tronco caído no fundo e uma passagem alta numa das paredes. Chuva enche a bacia e o tronco sobe boiando até a altura da passagem; o jogador sobe nele antes que a água baixe.

### Verão

**Espacial 1 — A porta que precisa de alguém.** Uma porta só fica aberta enquanto houver peso na placa diante dela, e a passagem fica além da porta. Sombra na placa, o herói passa.

**Espacial 2 — A gangorra.** Uma plataforma em gangorra: com peso num lado, o outro sobe até uma borda alta. A sombra fica no lado de baixo, o herói sobe pelo outro.

**Lógico 1 — A isca.** Uma criatura territorial guarda uma passagem única. Pode ser enfrentada em combate propositalmente mais difícil que o padrão da região, ou atraída por uma sombra deixada longe da passagem — sem recompensa de combate, reforçando escolha tática, não "a certa".

**Lógico 2 — O corredor longo.** Placa e porta separadas por um corredor longo demais: a sombra se apaga antes de o jogador chegar. Solstício primeiro, Sombra dentro do seu pulso — a sombra dura o corredor inteiro. É aqui que Solstício se explica sozinho.

## 8.4 Puzzles combinados (segunda metade do jogo)

*Nota: os combinados da matriz anterior (A Passagem Efêmera, O Pilar Vivo, Sala do Pilar Frágil-Congelado) e a "Câmara de Eclosão Solar", proposta e removida antes deles, saíram junto com as canções de que dependiam — registrados aqui para não serem re-sugeridos.*

**Combinado 1 — Primavera + Inverno: O Lago Que Não Havia.**
Um fosso seco e largo demais para qualquer salto. Chuva enche o fosso; Congelar, tocado na borda enquanto a água ainda está alta, faz dela um chão. O gelo derrete a partir da origem e a água baixa por baixo dele: travessia contra dois relógios.

**Combinado 2 — Outono + Inverno: A Onda Parada.**
Um lago diante de uma parede alta. Vendaval tocado na margem levanta uma crista; Congelar, antes que ela assente, prende a crista numa rampa até o topo da parede. O tempo entre as duas canções é o puzzle — tocar Congelar cedo demais congela uma onda baixa.

**Combinado 3 — Outono + Primavera: Apanhar no Ar.**
Uma plataforma pendurada sobre um poço de paredes de terra, alta demais para alcançar. Soltar a derruba; Enraizar, tocado de modo que o pulso cubra o poço, a apanha entre as paredes na altura de uma saída lateral. Tocar Enraizar primeiro não funciona: as raízes cruzam o vão antes de haver algo para segurar, e a plataforma cai sobre elas longe da saída.

**Combinado 4 — Verão + Outono: A Casa Vazia.**
Uma porta com duas placas, afastadas uma da outra num corredor longo, e o herói do lado errado de ambas. Solstício, depois Sombra numa placa; Soltar derruba uma carga pendurada sobre a outra. A porta abre com o herói em nenhuma das duas — ninguém está ali, e a casa se lembra de que alguém esteve.
 
## 9. Pendências desta sessão
 
- **Duração exata (em segundos) do descongelamento/dissipação de cada efeito de puzzle** — a ser calibrado em prototipagem, não decidido em design puro.
- Puzzles concretos ainda não foram testados quanto a variações de dificuldade dentro da mesma categoria (fácil/médio/difícil por estação).
- Detalhamento visual exato da UI de partitura (layout dos 8 botões, mapeamento físico dos inputs direcionais) — decisão de UI/UX, não fechada aqui.
- **Sombra atacada:** a sombra se desfaz ao ser atingida (uma isca que se gasta) ou aguenta até o pulso fechar? A primeira é mais tensa; a segunda, mais simples de ler.
- **Enraizar em poço vertical:** degraus para subir por saltos (ponto de partida, não exige movimento novo) ou um estado de escalada próprio?
- **Vendaval sobre a água:** o vento precisa levantar crista na superfície (`WaterSurfaceField`) para o Combinado 2 existir — é um acoplamento novo entre o canal de empurrão e a água.
- **Redoma e a água:** a água precisa respeitar um disco que encolhe (a bacia recortada pela casca) — trabalho real no sistema de água.