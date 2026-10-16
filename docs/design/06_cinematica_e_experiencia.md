# Cantomória / Memorina — Cinemática e experiência do jogador

*Documento de design, versão de trabalho*

> Nasce do playtest da abertura (STORY-03, `05_roteiro.md`) feito pelo usuário em 2026-10-15. "Quero trabalhar com duas coisas aqui principalmente pelo resto da sessão: a parte cinemática da história e a experiência do jogador. Vamos fazer brainstorming sobre isso mesmo." Depois do brainstorm: "Faz os consertos rápidos (13, 10, 3) e começa o documento 06 de cinemática e experiência com as decisões do brainstorm." Roteiro e falas em `05`; mecânicas em `02`.

---

## 1. O que o playtest mostrou (usuário, 2026-10-15)

1. "the kid here is not making anysense We can't even see there is a kid there, and her bad is too small."
2. "O sprite do banco poderia ser refeito para condizer com o estilo do mundo"
3. "tem personagens que a caixa de diálogo está estranha pela falta de retrato. O radius do diálogo também tá esquisito. Eu preciso chegar por trás da aguadeira pra conseguir disparar o dialogo com ela. E bem longe"
4. "Os diálogos poderiam ser melhorados no geral. "Pão, o redondo" é um exemplo de diálogo ruim. Não tem nem dialogo ali."
5. "O jogo começa sem quase nada. Precisamos trabalhar melhor com cutscenes."
6. "Podemos mudar a fonte do jogo? Essa está terrivelmente ruim de ler"
7. "não tem nenhuma indicação que eu peguei o pão ou algo assim. Deveria ter um inventário? Algum hud de item acquired? Algo indicando missão ou algo assim?"
8. "eu saio pra comprar pão eu volto e minha filha ja ta la pedindo a da manhã... não faz muito sentido"
9. "minha filha teleporta quando chega a hora de tocar a da manha"
10. "os botoes do hud do violão estão muito pequenos, diferente do hud da memorina"
11. "Nada deixa claro que eu errei a música depois de tocar quandoa aprece tentar de novo baixar violão. Nenhuma cutscene, nada. Poderia ser melhorado. Precisamos trabalhar com mais elementos cinemáticos. E basicamente fazer uma engine cinematica aqui."
12. "minha filha some, fica transparente após o violão tocar. Um silêncio que não diz nada. De novo, nada claro aqui. Eu sei que temos a regras de mostre, não conte. Mas precisamos mostrar algo, então, não é? E depois disso não fica claro o que fazer. A experiência está ruim."
13. "eu tenho a memorina desde o inicio do jogo e também a espada. Isso não está certo. E eu consigo utilizar a espada dentro de casa na minha filha."

## 2. O diagnóstico

**"Mostre, não conte" virou "não mostre nada".** Mostrar exige uma linguagem: câmera, corpo, tempo, som e luz. A abertura de STORY-03 troca poses paradas conforme fatos do save (`FactStaging`). Isso serve para o cenário, mas não para uma cena. Ninguém anda, vira o rosto ou abaixa a cabeça, e a câmera nunca se aproxima. Daí vêm os pontos 8, 9, 11 e 12: a filha salta de pose (x 44 para x 104), some num cross-fade que parece um fantasma, e o erro no violão passa sem que nada o marque.

**O jogador não sabe o que fez nem o que fazer** (pontos 7 e 12). Nenhum retorno marca o pão comprado, e nenhum indício diz para onde ir depois da música.

**Atrito de interface** (pontos 3, 6 e 10): zonas de conversa ao lado do personagem em vez de em volta dele, uma fonte difícil de ler e uma partitura do violão menor que a da Memorina.

**Um erro de início de jogo** (ponto 13): um jogo novo em build de debug começava com a espada e a Memorina, uma conveniência de teste que vazou para o jogo.

## 3. Princípio

O "mostre, não conte" (`05`, regras 1 a 6) continua valendo, mas mostrar não é calar. **Toda batida de história precisa de algo visível ou audível que a marque**: um movimento, um olhar, um corte de música, um enquadramento. O silêncio só funciona quando é encenado (a câmera segura, alguém vira o rosto), nunca como ausência de cena.

## 4. Pilar 1: um motor de cinemáticas (STORY-15)

- **Uma cena é dado.** Um `Resource` com uma linha do tempo de passos: câmera (enquadrar, zoom, pan, segurar), barras de letterbox, ator anda até x, ator vira, ator toca um clipe, emote (um balão sem palavra: "…", "♪", "!"), fala (a caixa de diálogo de STORY-08), espera, som e música (cortar, abafar), fade e luz. Segue a regra do projeto: variação por dados, não por ramos num script.
- **Os atores são personagens de verdade.** A filha, o ancião e o mentor viram personagens que andam e viram, com um controlador roteirizado, em vez de props trocados por `FactStaging`. Durante a cena, Ivo também é guiado por um controlador de cena no lugar do `PlayerInput`, na mesma divisão entre controle e personagem que o projeto já usa.
- **O relógio e as regras.** Roda no relógio pausável e com escala; nenhum novo escritor de `WorldFreeze`. Pode ser acelerada e pulada.
- **O `FactStaging` fica para o cenário.** Ele continua mostrando o estado de repouso de cada lugar (quem está onde quando a cena acaba); a cena é o caminho entre dois estados.

**Decisões do motor (usuário, 2026-10-16), sobre o plano `docs/knowledge/architecture/cutscenes-are-data-played-between-two-rest-states.md`:**
- Pular: "Pelo menu de pausa (Recommended)": uma entrada "Pular cena" no menu de pausa, sempre disponível; a cena salta para o estado final e grava que foi vista, e nunca escolhe pelo jogador.
- Acelerar: "Não, só pular (Recommended)": sem acelerar; o `WorldFreeze` continua o único escritor da escala de tempo.
- Arte da cena de demonstração: "Desenhar agora (Recommended)": os clipes da filha (andar, baixar os olhos, sentar, deitar virada para a parede) feitos já, com PixelLab.
- Atores no cinza: "Sim, se movem na cena (Recommended)": durante a cena o personagem anda e gesticula no relógio normal, mesmo onde o lugar está cinza; ao terminar volta a ser cenário e congela como antes.
- Padrões adotados (recomendados, não perguntados): os balões de emote ficam cinzas com o lugar; um barramento de música e o abafar ficam para quando houver música.

## 5. Pilar 2: a experiência do jogador

- **Retorno de ação (UI-11).** Um aviso de item obtido, com ícone, no mesmo espaço do aviso do caderno: o pão, a espada, a Memorina.
- **Intenção atual (UI-11).** Uma linha discreta que aparece quando a intenção muda ("O pão redondo.", "O ancião sabe do farol.") e fica no menu de pausa. Sem marcador no mapa e sem lista de missões, para não quebrar o tom.
- **Interação (STORY-14).** A zona de conversa fica centrada em quem fala, com alcance igual dos dois lados, e o aviso aparece acima da cabeça dele. Uma porta próxima vence; a zona só encolhe do lado da porta.
- **Caixa de diálogo (UI-13).** Recomendado: todo mundo que fala ganha retrato, pelo mesmo pipeline do quadro do elenco.
- **Fonte (UI-12).** Duas ou três fontes pixel de licença livre (CC0 ou OFL), com mais altura de x, comparadas numa maquete; o usuário escolhe.
- **Escala do HUD (STORY-14).** A partitura do violão no mesmo tamanho da partitura da Memorina.
- **Início e armas (STORY-14).** Um jogo novo começa sem espada e sem Memorina, em qualquer build; as salas de teste dão o próprio kit. Os interiores da vila são lugares calmos: Ivo não saca a espada dentro de casa.

## 6. Pilar 3: a abertura refeita (STORY-16)

- **Uma cena de abertura de 20 a 40 s (ponto 5).** Preto; a luz da manhã entra pela janela; a câmera passeia pela casa (o xale, o violão, os desenhos) e encontra a filha dormindo; Ivo acorda.
- **A volta com o pão (ponto 8).** Ela está sentada na beira da cama balançando as pernas, vê o pão e sorri, e só então vai buscar o violão na parede e o traz até ele.
- **O erro como cena (pontos 11 e 12).** Na lacuna, a música corta e a câmera fecha no rosto de Ivo; uma corda morta soa; o sorriso dela se desfaz. Só então aparece a escolha. Depois, ela abaixa os olhos, dá as costas, anda até a cama, senta e deita virada para a parede, e a câmera segura um instante.
- **Depois da cena, para onde ir (ponto 12).** A intenção muda (Pilar 2) e o mundo aponta: a janela do ancião acesa, a voz dele contando a história.
- **Rascunho 3 do texto (ponto 4).** O mesmo enredo, com conversas de verdade, ainda com subtexto. "Pão. O redondo." vira uma pequena troca, ela meio dormindo, ele respondendo.

## 7. Arte (STORY-17)

- **A filha na cama (ponto 1).** A cama de criança atual tem 11 px de arte, e a cabeça pintada nela some. A cama precisa crescer, e a filha precisa ser legível deitada.
- **O banco (ponto 2).** Redesenhar no estilo do mundo.

## 8. Ordem

1. Consertos rápidos: STORY-14 (pontos 3, 10 e 13).
2. Este documento.
3. O motor de cinemáticas (STORY-15), planejado antes pelo arquiteto.
4. A abertura refeita (STORY-16), com o rascunho 3, os retratos (UI-13) e a fonte (UI-12); o retorno de ação e a intenção (UI-11); a arte (STORY-17).

## 9. Em aberto (perguntas ao usuário, 2026-10-15)

- **Qual banco** (ponto 2): o banco das crianças na casa do ancião, ou o banco de descanso onde Ivo salva o jogo?
- **Inventário** (ponto 7): só uma seção no caderno, ou uma tela de inventário de verdade?
- **Ivo volta a falar,** ou fica mudo, só com gestos? (Recomendado: as escolhas seguem sendo gestos, mas Ivo tem voz nas conversas.)
- **Segunda opinião:** chamar o Codex para um brainstorm independente sobre o motor de cinemáticas?
