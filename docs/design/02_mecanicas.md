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
 
- **Memorina (grade de 8 posições):** aparece apenas quando o jogador saca o instrumento (tecla C); tubos não aprendidos aparecem bloqueados/cinzas. Some ao guardar. (Ver seção 6.2 para a regra de execução.)
- **Caderno de campo (tecla E):** dividido em seções — Lore (diário do personagem + fragmentos de portador), Canções aprendidas, Itens colecionáveis, Guardiões (registro de guardiões conhecidos e estado de corrupção).
- **Mapa (tecla M):** elemento separado do caderno. Estilo Metroid clássico — contorno se desenha por exploração. Deliberadamente pouco detalhado mesmo depois de revelado, sem indicar posição exata ou rota ótima — reforça a intenção de tentativa e erro na navegação.
- **Indicador de vida:** ícone temático (estilo máscara/coração), sempre visível, não barra.
- Telas de menu (inicial, pause, vitória): a definir.
---
 
## 1. Princípios gerais
 
- **Dois domínios mecânicos separados, sem mistura fora do confronto com guardião:** trilha física (combate e mobilidade pessoal) e trilha musical (mundo, exploração, puzzle, lore). Cada uma tem seu próprio verbo — física é para agir rápido no mundo, música é para entender e curar o mundo.
- **Timing preciso é o fio condutor entre os dois domínios.** Tanto o combate físico (parry) quanto a execução musical (call-and-response, puzzles) pedem a mesma habilidade central do jogador: sentir o tempo certo de agir. Jogador bom em um fica naturalmente melhor no outro, sem serem sistemas didaticamente desconectados.
- **A Memorina nunca é usada em combate comum.** Só entra em jogo dentro do confronto com guardiões — reservar a fusão física+musical para esse momento único preserva seu peso ritual.
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
 
- **UI:** grade de 8 posições fixas (2 por estação), sempre visíveis. Tubos ainda não aprendidos aparecem bloqueados/cinzas — reforça visualmente a lore do instrumento remendado se completando ao longo da jornada.
- **Execução em tempo real, sem pausa do mundo** — mesma implementação usada no call-and-response de guardião. Sistema único, não dois modelos diferentes.
- **Restrição obrigatória: a Memorina só é tocada com o personagem completamente parado, em chão firme.** Nunca no ar, nunca em movimento. Essa regra existe antes de qualquer outra consideração de puzzle — puzzles que dependeriam de tocar durante queda ou salto foram redesenhados para respeitá-la (ver seção 7.4).
- **Input:** sequência de botões direcionais (referência: Ocarina of Time), não seleção de item por menu ou lista.
- **Erro de sequência:** reseta silenciosamente — a sequência tocada até ali pisca brevemente e volta a vazio, sem popup, sem penalidade de recurso (vida, tempo). O jogador tenta de novo imediatamente.
- **Apoio de memória:** o caderno de campo registra as sequências já aprendidas, consultável fora do momento de execução — decorar é necessário para jogar fluido, mas existe rede de segurança contra esquecimento.
- **Nenhuma sugestão contextual na UI.** O ambiente (cor, textura do material) é responsável por comunicar qual sequência resolve o quê — coerente com a filosofia geral de não expor mecânica.
## 7. Sistema de sequências de notas — as 8 sequências
 
Cada estação carrega duas sequências de notas distintas, não uma. Isso amplia o vocabulário de puzzle e evita reciclagem de função disfarçada entre estações.
 
### 7.1 Matriz de sequências por estação
 
**Inverno (galho petrificado)**
- **Congelar** — solidifica água em movimento, cria plataforma temporária.
- **Ventania/Nevasca** — rajada de vento gelado que empurra objetos leves ou o próprio jogador.
- *(Terceira opção discutida e mantida como reserva conceitual: Hibernação — adormece uma criatura ou mecanismo por tempo prolongado, oferecendo alternativa tática ao combate. Adotada como a segunda sequência de Inverno no lugar de Ventania em puzzles que envolvem criaturas — ver seção 7.3.)*
**Verão (pedra vulcânica furada)**
- **Sol Concentrado** — evapora água rasa ou seca lama, revelando chão sólido; pode secar umidade que isola outros materiais.
- **Tempestade Repentina** — invoca um raio pontual, ativa mecanismos elétricos ou atinge alvos à distância.
**Outono (osso oco e leve)**
- **Fragilizar** — torna uma estrutura (viva ou morta) oca e quebradiça, destrutível depois por golpe físico simples. Ponte entre trilha musical e trilha física.
- **Despir** — remove folhagem/casca densa, revelando passagens ou mecanismos camuflados. Efeito permanente assim que aplicado (é revelação, não criação temporária).
**Primavera (caule vivo)**
- **Brotar** — faz crescer um caule/planta até virar plataforma ou ponte; altura e direção controláveis sustentando a nota.
- **Eclodir** — força casulos, sementes endurecidas ou botões fechados a abrir instantaneamente, liberando conteúdo, esporos ou efeito de área.
*Notas descartadas ao longo do processo de design (registradas para não serem re-propostas): Miragem, Renascer, Florescer, Chamado/Convocar vida, Fermentar/Converter, Polinizar em cadeia, Amolecer, Acelerar ciclo, Brotar em cadeia vertical.*
 
### 7.2 Distribuição entre guardiões e forma de aprendizado
 
- Nem toda sequência é ensinada no mesmo guardião/batalha. Com múltiplos guardiões por estação, a sequência "faltante" de um guardião pode vir de outro guardião da mesma estação, em região diferente.
- **Regra:** pelo menos um guardião de cada estação ensina a sequência base pelo call-and-response do próprio combate. A segunda sequência daquela estação é ensinada através do fragmento de portador — do mesmo guardião ou de outro da mesma estação, a critério do design de cada região.
- Isso separa claramente "o que aprendo lutando" de "o que aprendo ouvindo a história", e dá ao jogador razão mecânica para visitar todos os guardiões de uma estação, não só o primeiro que encontrar.
### 7.3 Sequência Hibernação — nota de duração
 
Hibernação segue a mesma regra de temporariedade de qualquer sequência: dura enquanto o pulso de cor estiver ativo, contraindo junto com o resto do efeito conforme o cinza reconquista o espaço. Sem duração especial própria.
 
## 8. Puzzles concretos por estação
 
Dois puzzles espaciais e dois lógicos por estação — base de repertório, não lista fechada.
 
### Inverno
 
**Espacial 1 — Ponte de gelo cronometrada.** Queda d'água bloqueia passagem horizontal. Congelar cria ponte que descongela progressivamente; travessia contra o tempo. Primeira resolução trava um mecanismo lateral em posição permanente (atalho).
 
**Espacial 2 — Empurrado pela Nevasca.** Abismo largo com corrente de vento natural na sala. Tocar Ventania numa rajada existente amplifica-a, empurrando o jogador através do vão — exige posicionamento exato antes de tocar.
 
**Lógico 1 — Hibernar ou lutar.** Criatura territorial bloqueia passagem única. Pode ser enfrentada em combate propositalmente mais difícil que o padrão da região, ou hibernada — sem recompensa de combate, reforçando escolha tática, não "a certa".
 
**Lógico 2 — Trio de rajadas em sequência.** Três correntes de vento cruzadas, cada uma capaz de arrastar o jogador. Congelar uma corrente específica, na ordem certa, abre passagem segura; ordem errada falha sem dano grave, só reposiciona.
 
### Verão
 
**Espacial 1 — Secar o lodo.** Extensão de lama funda impede travessia. Sol Concentrado evapora a umidade, endurecendo em chão sólido por tempo limitado.
 
**Espacial 2 — Revelar sob a luz.** Plataforma visível apenas por reflexo intenso sob luz forte (cristal ou espelho natural) — Sol Concentrado revela uma passagem que sempre esteve lá, mas invisível sem luz direta.
 
**Lógico 1 — Raio no mecanismo distante.** Mecanismo elétrico fora de alcance físico direto. Tempestade Repentina, mirada à distância, ativa-o remotamente.
 
**Lógico 2 — Sequência sol-relâmpago.** Porta de metal isolada por umidade residual. Sol Concentrado seca a umidade primeiro; só então Tempestade consegue atingir e ativar a porta — combinação obrigatória das duas sequências de Verão em sequência.
 
### Outono
 
**Espacial 1 — Atravessar o galho fragilizado.** Galho grosso resistente demais para golpe normal. Fragilizar torna-o quebradiço; ataque físico simples em seguida o destrói.
 
**Espacial 2 — Revelar a trilha sob a folhagem.** Parede de vegetação densa esconde passagem lateral. Despir remove a folhagem, revelando a abertura — permanente assim que aplicado uma vez.
 
**Lógico 1 — Fragilizar seletivo.** Plataforma elevada sustentada por três pilares; fragilizar o pilar errado a derruba. Exige identificar visualmente qual pilar é estrutural antes de agir.
 
**Lógico 2 — Despir em cadeia.** Mecanismo de engrenagens coberto por vegetação parasita em múltiplos pontos; Despir precisa ser aplicado em 2-3 pontos, na ordem certa, para não acionar defesa (espinhos reativos a remoção rápida demais).
 
### Primavera
 
**Espacial 1 — Escada de caules guiada.** Sementes no chão; sustentar Brotar controla altura e leve inclinação de crescimento, formando escada até ponto exato.
 
**Espacial 2 — Eclodir o casulo-ponte.** Casulo grande pende sobre abismo; Eclodir libera filamento/teia elástico que funciona como ponte pênsil temporária.
 
**Lógico 1 — Ordem de eclosão.** Múltiplos casulos numa sala, cada um libera efeito diferente ao eclodir; ordem certa necessária para usar o efeito de um antes que outro o apague.
 
**Lógico 2 — Brotar sob peso.** Plataforma pesada só se move se algo a empurrar de baixo; Brotar sustentado até altura máxima ergue-a o suficiente para destravar passagem.
 
## 8.4 Puzzles combinados (segunda metade do jogo)
 
*Nota: um quarto puzzle combinado (Verão + Primavera, "Câmara de Eclosão Solar") foi proposto e depois removido — registrado aqui para não ser re-sugerido.*
 
**Combinado 1 — Inverno + Verão: A Passagem Efêmera.**
Fosso com lodo no fundo. O jogador usa Congelar, parado numa borda, para criar uma plataforma de gelo temporária sobre o lodo — não escala paredes, atravessa por cima a pé. A plataforma começa a descongelar assim que criada; travessia contra o tempo até a borda oposta. Cair no lodo (ainda mole, sem Sol Concentrado aplicado) reposiciona sem ser necessariamente letal.
 
**Combinado 2 — Outono + Primavera: O Pilar Vivo.**
Coluna de pedra com trepadeira seca enrolada (Outono: Despir remove), escondendo brotos dormentes por baixo. Despir revela os brotos; Brotar os faz crescer em degraus espiral ao redor da coluna. Ordem importa: usar Brotar antes de Despir não funciona — matéria morta impede o broto vivo de emergir, sem penalidade de dano, forçando o jogador a entender causalidade material.
 
**Combinado 3 — Inverno + Outono: Sala do Pilar Frágil-Congelado.**
Pilar de apoio coberto de gelo fino por fora, com núcleo de madeira podre por dentro. O jogador usa Congelar numa poça ao lado para alcançar altura e escalar até o topo do pilar — **parado completamente no topo** antes de agir — e de lá usa Fragilizar no núcleo exposto, colapsando o pilar de forma controlada e criando uma rampa de escombros até o andar de baixo. A queda controlada É o transporte — intencional, não falha de design.
 
## 9. Pendências desta sessão
 
- **Duração exata (em segundos) do descongelamento/dissipação de cada efeito de puzzle** — a ser calibrado em prototipagem, não decidido em design puro.
- Puzzles concretos ainda não foram testados quanto a variações de dificuldade dentro da mesma categoria (fácil/médio/difícil por estação).
- Detalhamento visual exato da UI de partitura (layout dos 8 botões, mapeamento físico dos inputs direcionais) — decisão de UI/UX, não fechada aqui.