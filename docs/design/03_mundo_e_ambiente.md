# Cantomória / Memorina — Mundo e Ambiente

*Documento de design, versão de trabalho*

> Este documento cobre como o cinzesquecimento se manifesta no mundo jogável, como regiões e estações funcionam, o clima regional e a água. Premissa, lore e personagens estão em `01_lore_e_narrativa.md`. Combate, sistema musical e puzzles estão em `02_mecanicas.md`. Referências cruzadas indicam onde os três se encontram.

---

## 1. Nome em inglês: the Greyhush

**Decisão fechada nesta sessão.** *Cinzesquecimento* passa a ter um nome fixo em inglês: **the Greyhush**.

- **Grey** — o cinza, a cor que resta.
- **Hush** — silenciar, calar, fazer parar. Não "destruir": *hush* é o que se faz a um som que ainda existe.

A escolha privilegia o núcleo da lore (`01_lore_e_narrativa.md`, seção 3: *"não destrói. Prende."*) e ecoa o fato de o jogo inteiro girar em torno de som e memória. *Greyforgetting* (calco literal), *Stillgrey* e *Ashen Quiet* foram considerados e descartados — registrados aqui para não serem re-propostos.

**Nota de implementação:** `greyhush` é o identificador em código (conforme a regra de identificadores em inglês do `CLAUDE.md`). Ele nunca aparece em texto exibido ao jogador — toda string de interface passa por chave de tradução —, então uma eventual troca de nome não toca a localização. O documento continua usando *cinzesquecimento* em prosa, que é a língua de trabalho do design.

---

## 2. O princípio central: o cinza é tempo parado

**Decisão fechada nesta sessão, e é a decisão da qual todo o resto deste documento decorre.**

A lore já dizia (`01_lore_e_narrativa.md`, seção 3):

> "O cinzesquecimento não destrói. Prende. Um lugar tomado por ele não explode nem desaba, apenas cessa, e fica assim para sempre: sem ciclo, sem estações, sem nada que passe de verdade."

A leitura anterior tratava isso como uma regra de cor: o mundo é grayscale, e a Memorina devolve cor. Isso é insuficiente e, na prática, deixa o cinza como um filtro de imagem. A leitura correta é literal:

**Uma área tomada pelo cinzesquecimento não está sem cor. Está sem tempo.**

Cada elemento ambiental do mundo — galho que balança, poeira que assenta, engrenagem que gira, floco de neve que cai, onda que corre — avança seu próprio relógio numa taxa dada pelo quanto aquele ponto do mundo ainda é lembrado. Onde a lembrança é zero, o relógio não avança.

A diferença entre isso e "reduzir a intensidade da animação" é a diferença entre o design certo e o errado:

- **Reduzir amplitude** dá uma árvore balançando timidamente. Ela ainda se mexe. Ainda há ciclo. A lore está sendo desobedecida.
- **Parar a integração** congela a árvore **no meio do gesto** — um galho travado no ponto exato em que estava, e assim para sempre. Quando o pulso de cor passa por cima, ela **retoma exatamente de onde parou**. Isso é o que o documento de lore descreve.

**Consequência para a leitura do jogador:** a cor é como o jogador *lê* o campo. O tempo é o que o campo *faz*. Cor e movimento chegam juntos e saem juntos, e é essa coincidência que faz o mundo parecer vivo em vez de colorido.

*Nota de design:* isso também resolve o problema estético de "mundo cinza é um mundo chato de olhar". Um mundo parado não é um mundo apagado — é um mundo perturbador. E o instante em que ele volta a se mexer vira o momento de maior impacto do jogo, repetível a cada sequência tocada.

---

## 3. O campo de memória

O estado do mundo em qualquer ponto é um valor contínuo de 0 a 1:

- **0** — tomado pelo cinzesquecimento. Sem cor, sem movimento, sem ciclo.
- **1** — plenamente lembrado. Cor cheia, tempo correndo normalmente.

Esse valor vem da soma de três coisas:

1. **A linha de base da região** — o quanto aquela região inteira ainda é lembrada (seção 4).
2. **Manchas autorais dentro da região** — o design de nível pode pintar áreas mais ou menos corroídas dentro de uma mesma região. *"Este canto da sala está pior."* Serve tanto para leitura visual quanto para dificuldade.
3. **Fontes temporárias** — os pulsos de cor gerados ao tocar a Memorina, os flashbacks pessoais, e (na Batalha Final) a própria aura do herói.

### 3.1 O pulso de cor

Já estabelecido em `02_mecanicas.md`, seção 6.1: *"cor sustenta, depois contrai conforme o cinza reconquista o espaço"*. Detalhando o comportamento:

- **Ataque** — o pulso se abre rápido, com um anel de frente mais claro correndo para fora. É o momento de leitura: o jogador vê até onde vai alcançar.
- **Sustentação** — o raio se mantém. É a janela de resolução do puzzle.
- **Contração** — o cinza volta, e volta **acelerando**. Não é um desvanecer educado; é reconquista.

**A contração é irregular de propósito**, em dois eixos independentes:

- **Na forma:** a borda não é um círculo limpo. Ela avança e recua em setores, de modo grosseiro e visível, como algo que morde de volta.
- **Na velocidade:** um pulso tocado numa área muito corroída **morre mais rápido**. Isso torna o perigo da região legível na própria luz que o jogador acende, e dá ao design de nível um botão de dificuldade que não depende de inimigos nem de plataformas.

**Pendência:** as durações exatas de ataque, sustentação e contração continuam pendentes de prototipagem, como já registrado em `02_mecanicas.md`, seção 9.

### 3.2 Estética da borda

Coerente com a direção de arte já fechada em `02_mecanicas.md`, seção 5.2 (*"dithering que normalmente seria transição suave ficando errático"*): **a fronteira entre cor e cinza nunca é um degradê suave**. É um padrão de pontilhado que se resolve — técnica nativa de pixel art, não filtro.

A mesma lógica vale para a assinatura de corrupção já estabelecida (*"borda perdendo definição"*): não é um borrão. São **pixels individuais desertando da silhueta**, num padrão que se refaz em ritmo lento o bastante para ler como corrupção e não como chuvisco de televisão.

---

## 4. Regiões, estações e restauração

### 4.1 A memória de uma região é um valor, não um interruptor

**Decisão fechada nesta sessão.** Uma região não é "corrompida" ou "restaurada". Ela tem um valor de memória, autorável, entre 0 e 1.

Isso resolve dois problemas que a leitura binária criava:

- **A vila natal.** A lore a descreve como *"uma das últimas ilhas de cor"* (`01_lore_e_narrativa.md`, seção 9), e a praga já a corroía devagar antes do chamado (seção 9.1). Com interruptor, ou a vila está perfeita ou está morta — e a cena mais importante em termos de tom do jogo inteiro fica sem meio-termo.
- **A progressão narrativa da vila.** Com valor contínuo, a vila abre o jogo em 0.8 (viva, mas já rareando), é revisitada no meio do jogo mais baixa (visivelmente pior, sem uma linha de diálogo precisar dizer isso), e volta a 1.0 no Retorno. **Narrativa contada por um número.**

Restaurar o guardião de uma região leva o valor dela permanentemente a 1.0 — é a *"estação de repouso permanente do local"* já descrita em `02_mecanicas.md`, seção 6.1. Isso não impede pulsos temporários de qualquer outra estação por cima, conforme a regra de reativação livre já fechada no mesmo trecho.

### 4.2 O que define uma região

Consolidando o que já está espalhado pelos outros dois documentos:

| Elemento | Fonte |
|---|---|
| Estação nativa | `01_lore_e_narrativa.md`, seção 2 — estações se repetem entre regiões |
| Material do tubo | `01_lore_e_narrativa.md`, seção 5 |
| Criatura-professora | `02_mecanicas.md`, seção 2 |
| Fauna corrompida com silhueta local | `02_mecanicas.md`, seção 2 |
| Fragmento de portador | `01_lore_e_narrativa.md`, seção 6 |
| **Valor de memória inicial** | Este documento, seção 4.1 |
| **Perfil de clima** | Este documento, seção 5 |

**Pendência herdada:** quantas regiões existem (5 a 6 como ponto de partida), quais estações se repetem onde, e a ordem não linear de conexão. Continua em aberto em `01_lore_e_narrativa.md`, seção 10.

### 4.3 As marcas de morte

Já estabelecido em `02_mecanicas.md`: morrer acrescenta um pequeno símbolo do cinzesquecimento ao cenário da região, acumulável e sem efeito de gameplay. Registrando aqui a integração: essas marcas são **fontes negativas no campo de memória**, de raio pequeno. Ou seja, elas não são só um decalque — elas de fato abaixam localmente a memória naquele ponto, o que significa que um pulso tocado ali contrai um pouco mais rápido.

O efeito é deliberadamente pequeno demais para virar punição mecânica, e grande o bastante para que um jogador que morreu muitas vezes no mesmo lugar sinta, sem ser avisado, que aquele canto do mundo está pior por causa dele.

---

## 5. Clima regional

**Sistema novo — não existia nos documentos anteriores.**

Cada região tem clima próprio, ligado à sua estação: um inverno rigoroso com nevascas, um verão de tempestades repentinas, um outono de ventos. O clima **afeta o jogador fisicamente**, não é só cenário.

### 5.1 A regra: o clima existe em todo lugar, mas fica congelado no cinza

**Decisão fechada nesta sessão.**

Numa região tomada pelo cinzesquecimento, o clima **não desaparece — ele para**. A neve fica pendurada no ar, imóvel. A chuva fica suspensa. Um relâmpago fica parado no céu.

Tocar uma sequência acende um pulso, e **dentro do pulso os flocos voltam a cair** — e voltam a congelar conforme o cinza reconquista o espaço. O jogador atravessa uma nevasca petrificada e abre, com música, um bolsão onde a neve volta a nevar.

Isso é aplicação direta do princípio da seção 2, e é a imagem mais forte que a regra produz.

### 5.2 A intensidade do clima acompanha a memória da região

O clima não é ligado/desligado por restauração — ele escala com o valor de memória da região (seção 4.1):

- **Região em 0** — clima presente mas totalmente congelado. Nada se move. Coerente com a lore.
- **Região restaurada em 1.0** — clima pleno. É a recompensa sensorial de ter restaurado o guardião, e ao mesmo tempo um novo perigo.
- **Vila em 0.8** — neve leve, vento fraco, visivelmente viva mas já rareando.

Um pulso tocado numa região morta acorda o ambiente **local** (folhas se mexem, poeira volta a assentar) mas **não** invoca uma nevasca regional inteira. A escala está certa: música devolve vida ao redor de você, não um sistema meteorológico.

*Frase de resumo para a equipe:* **o clima é o pulso do mundo, e o cinzesquecimento é uma parada cardíaca. A intensidade do clima é o campo de memória, expresso em escala regional.**

### 5.3 Gramática visual — separando clima de efeito de nota

Existe risco real de confusão entre a nevasca ambiente e a sequência **Ventania/Nevasca**, e entre a tempestade ambiente e **Tempestade Repentina**. A separação é visual e absoluta:

| | Efeito de nota (invocado) | Clima (ambiente) |
|---|---|---|
| Origem | o corpo do herói / o instrumento | o céu, a região |
| Geometria | **radial** — abre a partir de um ponto | **direcional** — camadas atravessando a tela |
| Cor | carrega o pulso de cor, tingido pelo material do tubo | já colorido, porque a região está viva |
| Borda | pontilhado que **contrai** visivelmente | sem borda; ocupa a tela |
| Duração | segundos | minutos, com ciclos internos |
| Fim | o cinza **reconquista** | o clima **vai embora** |

O discriminador que o jogador aprende sem ser ensinado: **radial e contraindo = fui eu. Direcional e em camadas = foi o mundo.**

**Regra rígida:** clima ambiente **nunca** emite pulso de cor. Se emitisse, a gramática inteira de "cor = memória verdadeira" (`01_lore_e_narrativa.md`, seção 9.3) desmoronaria.

**Consequência boa e não planejada:** o puzzle Inverno Espacial 2 (`02_mecanicas.md`, seção 8) diz que *"tocar Ventania numa rajada existente amplifica-a"*. Como a nota e o clima empurram o jogador pelo mesmo canal físico, isso acontece **naturalmente**, sem regra especial. Os dois sistemas se compõem sozinhos.

### 5.4 O problema da imobilidade — e sua solução

**O conflito mais agudo deste documento.** `02_mecanicas.md`, seção 6.2, é categórico: *"a Memorina só é tocada com o personagem completamente parado, em chão firme."* E uma nevasca empurra o jogador.

Pior: pela regra da seção 5.1, **tocar acorda a própria nevasca que vai te empurrar**. O ato de restaurar cria a própria oposição.

Isso é tensão excelente e pode ser fúria pura. A solução tem quatro camadas, e todas as quatro são necessárias:

1. **As calmarias entre rajadas são a janela.** O vento não é constante: ele pulsa, e boa parte de cada ciclo é quase parada. O jogador aprende a tocar **na calmaria**. Isso não é contorno do problema — converte o clima num desafio de **timing**, e timing é explicitamente o fio condutor declarado do jogo (`02_mecanicas.md`, seção 1). O clima vira um terceiro professor da mesma habilidade que o parry e o call-and-response já ensinam. **É a melhor ideia deste documento; deve ser a primeira coisa citada ao explicar o sistema.**

2. **Sacar o instrumento acalma o vento ao redor.** Ao sacar a Memorina (tecla C), o vento perde força num raio pequeno em torno do herói, com pequena floração de cor aos pés dele e flocos desviando ao redor. Diegese: a memória empurrando de volta no ponto onde está sendo invocada. **Não cancela por completo** — no pico das rajadas ainda quebra —, então o timing da calmaria continua importando. Efeito colateral desejável: dá ao gesto de sacar o instrumento uma consequência física visível, em vez de parecer abrir um menu.

3. **A interrupção reaproveita o vocabulário de falha que já existe.** Ser empurrado no meio de uma sequência faz exatamente o que uma nota errada faz: *"a sequência tocada até ali pisca brevemente e volta a vazio, sem popup, sem penalidade"*. Sem estado de falha novo, sem interface nova, sem sensação nova.

4. **Abrigo como ferramenta de level design.** Sotavento de rochas, bocas de caverna — e, importante, **todo banco de restauração é abrigo pleno**, o que reforça o papel já declarado do banco como pausa contemplativa deliberada (`02_mecanicas.md`, seção Vida/Derrota). Qualquer puzzle que **exija** tocar durante uma nevasca ganha um abrigo autoral no ponto certo, de modo que o design de nível tenha uma ferramenta visível em vez de brigar contra o sistema.

*Nota de design:* **ser empurrado é diferente de andar.** A regra de imobilidade é sobre o jogador não comandar movimento; o mundo empurrando é justamente o desafio. A execução só quebra quando a força acumulada passa de um limiar, conforme o item 3.

### 5.5 Problemas a evitar desde já

- **Cansaço de nevasca.** O estado padrão de toda região é calmo; eventos severos são pontuação, não o normal. Nenhum evento severo deve começar logo após o jogador entrar numa região, para que uma transição de sala nunca o jogue numa rajada no meio de um salto.
- **Clima durante combate de guardião.** Vento alterando a distância do dash no meio de um chefe é injusto. A intensidade do clima cai drasticamente durante confrontos de guardião.
- **Relâmpago ambiente é armadilha.** A tempestade ambiente de Verão tem relâmpago e trovão **visuais**, atingindo apenas o plano de fundo, e **nunca causa dano nem ativa mecanismos**. Se causasse, colidiria de frente com **Tempestade Repentina** e o jogador perguntaria "quem disparou aquilo?". O raio que age no mundo é exclusivamente invocado pelo jogador.
- **Vento de Outono versus Ventania.** Diferenciados pela gramática da seção 5.3: o vento ambiente carrega **folhas**, em camadas, sempre na mesma direção durante todo o evento; a nota carrega um **anel de cor** e é radial.
- **Acessibilidade.** O branco-total da nevasca e a quantidade de movimento em tela precisam de um controle de intensidade nas opções desde a primeira versão. Barato agora, caro depois.

---

## 6. Água

**Sistema novo.** A água aparecia nos documentos anteriores apenas dentro de puzzles individuais (Congelar, Sol Concentrado, a queda d'água de Inverno Espacial 1, o lodo de Combinado 1). Aqui ela vira sistema.

### 6.1 A água é gerada, não desenhada

A água não é um sprite animado. Ela é calculada: superfície com ondas, reflexo do mundo acima dela, profundidade, refração do que está atrás, e correnteza. Isso vale tanto por beleza quanto por mecânica — uma água desenhada à mão não pode congelar progressivamente nem baixar de nível.

**Correnteza é propriedade de primeira classe desde o início**, porque quedas d'água e água corrente estão planejadas. A correnteza empurra o jogador pelo mesmo canal físico que o vento e a nota Ventania.

### 6.2 Água morta não reflete

**A melhor consequência do princípio da seção 2, e a que deve ser mostrada primeiro.**

Numa área tomada pelo cinzesquecimento, a água fica **lisa, parada e sem reflexo nenhum** — uma chapa cinza com uma linha mais clara no topo. Conforme a cor volta, **o mundo começa a aparecer dentro dela**.

Isso é muito mais forte do que simplesmente dessaturar a água, porque a água literalmente **volta a lembrar o que está acima dela**. É a gramática de "cor = memória verdadeira" aplicada a uma superfície que, por natureza, já é um objeto de memória.

Três coisas param juntas quando a memória chega a zero:

1. **O reflexo** desaparece.
2. **As ondas** somem — a superfície fica geometricamente plana, não apenas calma.
3. **As ondulações reagem, mas não relaxam.** Esta é a mais importante: um mergulho em água tomada pelo cinzesquecimento levanta uma crista — **e a crista fica lá, parada, para sempre.**

Aquela crista congelada é a imagem mais literal que o jogo pode produzir de *"não explode nem desaba, apenas cessa, e fica assim para sempre"*. Deve ser a primeira coisa mostrada num protótipo jogável.

### 6.3 Congelar exige água em movimento — e isso fecha sozinho

`02_mecanicas.md`, seção 7.1, define **Congelar** como algo que *"solidifica água em movimento"*.

Pela seção 2 deste documento, água numa área morta **está parada**. Logo, ela não pode ser congelada enquanto o tempo não voltar àquele ponto.

Isso poderia ser um impasse, mas não é: **Congelar é ela própria uma sequência**. Tocá-la gera o pulso, o pulso devolve tempo à água, a água volta a correr, e então congela. A cadeia se fecha sozinha, sem regra especial e sem travamento possível.

*Nota de design:* esse é o tipo de coerência que o jogador não percebe conscientemente, mas que faz o sistema parecer que existia antes do jogo. Vale preservá-la em qualquer decisão futura sobre a água.

### 6.4 Congelar e descongelar

Comportamento, ainda sem números (pendente de prototipagem, como já registrado em `02_mecanicas.md`, seção 9):

- O gelo cresce a partir do ponto onde o jogador tocou, numa frente que avança visivelmente.
- A superfície **endurece antes de parecer sólida** — ela para de responder a respingos enquanto a frente ainda está crescendo. Detalhe pequeno, leitura boa.
- **O degelo começa pela origem e avança para fora.** Ou seja: o gelo derrete **atrás** do jogador, a partir de onde ele estava parado tocando. Ele precisa se comprometer para frente e não pode voltar.

**Decisão de design fechada:** degelo a partir da origem é o padrão, porque é mais legível, mais dramático, e é exatamente o que o Combinado 1 descreve (*"travessia contra o tempo até a borda oposta"*). O degelo a partir das bordas fica disponível como variante autoral para casos como Inverno Espacial 1, onde o jogador talvez precise atravessar de volta.

O jogador **realmente cai** quando o pedaço sob os pés dele derrete. A travessia cronometrada só funciona se isso for verdade.

### 6.5 Sol Concentrado

O nível da água baixa e volta. A superfície, a área de colisão e o comportamento das ondas acompanham.

O chão revelado por baixo **não é gerado automaticamente** — é chão autoral, colocado pelo design de nível, que apenas passa a existir fisicamente enquanto a água estiver baixa. Isso mantém o controle na mão de quem desenha a sala, e evita que a geometria do mundo mude de forma imprevisível. Mesma lógica vale para o lodo do Combinado 1.

### 6.6 Disciplina de pixel art

**Registrado aqui porque é o maior risco estético do projeto.** Água procedural é a coisa mais fácil do mundo de fazer parecer um efeito de jogo em alta definição colado por cima de pixel art. Se isso acontecer, a água estraga a arte inteira em vez de embelezá-la.

A regra em linguagem de design: **a água precisa parecer desenhada à mão, mesmo sendo calculada.** A linha d'água anda de pixel em pixel, nunca deslizando suavemente; as cores da água pertencem à mesma paleta do cenário; o reflexo é nítido e quadriculado, nunca borrado; os cáusticos são faixas grossas, não luz difusa.

Verificação obrigatória: olhar a água com a janela ampliada, em cada etapa da construção — nunca só no fim.

---

## 7. Pendências desta sessão

- **Quedas d'água** precisam de uma passada de design própria. Água **vertical** é um caso diferente: não reflete como espelho, tem geometria e colisão diferentes, e a relação dela com Congelar (congelar uma queda d'água inteira? só a base?) não está resolvida. Inverno Espacial 1 depende disso.
- **Números de clima:** força do vento, duração das rajadas, duração das calmarias, quanto o abrigo do instrumento reduz. Tudo pendente de prototipagem, junto com as durações de efeito já listadas em `02_mecanicas.md`, seção 9.
- **Valores de memória inicial por região.** Depende do mapa concreto, que continua em aberto (`01_lore_e_narrativa.md`, seção 10). Só a vila está parcialmente decidida: 0.8 na abertura e 1.0 no Retorno; o valor da revisita do meio do jogo fica para a sessão de mapa.
- **Perfis de clima por estação.** Inverno (nevasca) está descrito. Verão (tempestade), Outono (vento de folhas) e Primavera (garoa? pólen?) estão apenas esboçados. Primavera em particular ainda não tem um clima que a caracterize com a mesma força.
- **Inconsistência herdada, não resolvida aqui:** `02_mecanicas.md`, seção 7.1, lista Inverno com **Congelar + Ventania/Nevasca**, mas diz que **Hibernação** substitui Ventania em puzzles com criaturas — e a seção 8 usa as três. Com a grade fixa de 8 posições (2 por estação), Inverno teria três sequências. A matriz e a interface não fecham entre si. Não bloqueia este documento, mas bloqueia a construção da interface da Memorina.
