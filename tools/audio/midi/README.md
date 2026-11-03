# MIDIs para o AIVA

Gerados por `python -I tools/audio/make_aiva_midis.py`. Para mudar uma nota, mude o script e rode de novo; não edite os `.mid` à mão.

Todos estão em **Dó maior**, com as notas da Memorina: Sol4 (↑), Dó4 (↓), Ré4 (←), Mi4 (→). Cada arquivo tem faixas com nome (melodia, dobra, acordes, baixo) e os instrumentos já escolhidos.

## Como usar cada arquivo no AIVA

O AIVA aceita MIDI de dois jeitos. Use o que o arquivo pede na tabela:

- **Influência** ("Create track" → "Upload influence"): o AIVA compõe uma peça nova no estilo e na melodia do MIDI. Use para peças longas.
- **Importar no editor** ("Create track" → "Import MIDI", ou abrir uma faixa e arrastar o MIDI para o editor): o AIVA toca exatamente estas notas com os instrumentos dele. Use para versões reduzidas, respostas e qualquer peça cujas notas não podem mudar.

Depois de importar: troque os instrumentos por timbres melhores do AIVA (mantendo a família), ajuste o volume das faixas e exporte em **WAV** (e em **stems**, onde a tabela pede).

**Regra das notas:** nas reduzidas e nas canções do jogo, a melodia precisa tocar exatamente as notas do MIDI, nos mesmos tempos. O jogo acende cada glifo da partitura no momento em que a nota soa (`note_cues`). Pode mudar os timbres, nunca as notas da faixa "Melodia".

## As 8 canções: versão reduzida

As versões completas já existem em `assets/audios/soundtrack/`. Falta a reduzida de cada canção. A Sombra já está feita (`sombra_*.mid`, de `tools/audio/make_sombra_midis.py`); as outras sete são miniaturas (`miniatura_<canção>.mid`).

| Arquivo | Uso no jogo | Duração | Modo no AIVA |
|---|---|---|---|
| `miniatura_<canção>.mid` | o `excerpt`: toca toda vez que o jogador completa a canção no mundo, com o mundo parado | notas até 7,9-10,9 s; 11-14 s com a cauda de reverb do AIVA | Importar no editor |
| `motivo_<canção>.mid` | só a melodia, se quiser compor algo novo com a canção (tema de região, luta) | 3,6 s | Influência |

As miniaturas vêm de `tools/audio/make_miniature_midis.py`: o motivo com o ritmo e o andamento exatos da abertura da peça completa (os mesmos `note_cues`), uma frase de resposta, uma cadência de verdade no modo da peça com ritardando, e o gesto da estação no acorde final (inverno gelo: notas agudas soltas; outono folhas: um arpejo caindo; primavera gotas: harpa aguda irregular; verão calor: a quarta aumentada tremendo nas violas). As faixas usam os nomes de patch do AIVA da peça completa. Não ponha introdução: a primeira nota precisa soar no instante 0. O total audível (entrada de ~0,57 s do AIVA + notas + cauda de ~2,6 s) fica entre 11 e 14 s.

| Canção | Notas | Estação | Melodia | Acompanhamento |
|---|---|---|---|---|
| Congelar | Sol Mi Ré Dó Dó Dó | Inverno | flauta + celesta uma oitava acima | cordas sustentadas, contrabaixo |
| Redoma | Ré Mi Ré Mi Sol Dó | Inverno | flauta + celesta | cordas sustentadas, contrabaixo |
| Soltar | Sol Dó Ré Dó Mi Dó | Outono | clarinete | violão de nylon em arpejo, violoncelo |
| Vendaval | Mi Mi Ré Ré Sol Mi | Outono | clarinete | violão em arpejo, violoncelo |
| Enraizar | Dó Ré Dó Mi Dó Sol | Primavera | harpa + flauta acima | cordas pizzicato pulsando, violoncelo |
| Chuva | Mi Mi Mi Sol Dó Sol | Primavera | harpa + flauta | pizzicato, violoncelo |
| Sombra | Dó Ré Mi Sol Sol Sol | Verão | oboé | pad quente e um bordão de Dó e Sol |
| Solstício | Mi Dó Sol Mi Dó Sol | Verão | oboé | pad e bordão |

Para combinar com a versão completa que você já tem: se ainda tiver o projeto dela no AIVA, abra-o, troque os instrumentos da reduzida pelos mesmos, e exporte. Assim as três versões soam como a mesma música.

## A canção da esposa

Proposta de 2026-11-02, aguardando aprovação; gerada por `tools/audio/make_wife_song_midis.py` (veja `docs/knowledge/music/wifes-song.md`). Semínima = 0,42 s (`morning_song.tres`), 4/4, Dó maior. Importar no editor (as notas precisam ficar exatas); os nomes das faixas de voz e violão não são ids verificados do AIVA: escolher o patch pela busca.

| Arquivo | Uso | Duração | Faixas |
|---|---|---|---|
| `esposa_inteira.mid` | flashback 1, Estabelecimento (STORY-05) | ~27 s | voz + violão de Ivo |
| `esposa_ninar.mid` | flashback 5, a canção de ninar (STORY-05) | ~50 s | só voz, metade do andamento |
| `esposa_sopro.mid` | o lampejo do mentor (`wife_hum_opening.wav`) | ~2 s | só voz, quatro notas |
| `esposa_epilogo.mid` | epílogo (STORY-07) | ~15 s | flauta (Memorina) + voz + viola + baixo |

## A canção final

| Arquivo | Uso | Duração | Modo |
|---|---|---|---|
| `cancao_final_12.mid` | as 12 notas harmonizadas (frase A e frase B) | ~13 s | Influência para a batalha; importar no editor para ouvir |
| `finale_luta.mid` | a luta (GRD-06), loop de 16 compassos: inverno (flauta, viola, baixos, piano, taiko) + camada de primavera (harpa, clarinete) | 48 s | Importar no editor; exportar **stems** (`make_finale_midis.py`) |
| `finale_chamado.mid` | fundo do chamado final, loop de 4 compassos, nada entre C4 e G4 | 16 s | Importar no editor |
| `finale_restauracao.mid` | a cena da lâmpada: pedal em Dó sob a voz do mentor, depois a frase B na flauta | ~11.4 s | Importar no editor |

Na batalha, peça **stems**: cada faixa marcada `(primavera)` precisa sair separada, porque o jogo a cala quando o jogador escolhe uma trilha.

## Quando os WAVs estiverem prontos

Ponha-os em `assets/audios/soundtrack/` com o mesmo nome do MIDI (`reduzida_congelar.wav`, ...) e me avise. Eu converto para OGG, ligo cada um na canção (`excerpt`, a resposta, a cena) e ajusto os `note_cues` pelo áudio real.
