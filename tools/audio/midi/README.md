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

As versões completas já existem em `assets/audios/soundtrack/`. Falta a reduzida de cada canção. A Sombra já está feita (`sombra_*.mid`, de `tools/audio/make_sombra_midis.py`); ignore `reduzida_sombra.mid`.

| Arquivo | Uso no jogo | Duração | Modo no AIVA |
|---|---|---|---|
| `reduzida_<canção>.mid` | o `excerpt`: toca toda vez que o jogador completa a canção no mundo | ~6,6 s | Importar no editor |
| `motivo_<canção>.mid` | só a melodia, se quiser compor algo novo com a canção (tema de região, luta) | 3,6 s | Influência |

Nas reduzidas, as 6 notas soam em **0,0 / 0,6 / 1,2 / 1,8 / 2,4 / 3,0 s** (100 BPM), e o acorde final segura até ~6,6 s. Não ponha introdução: a primeira nota precisa soar no instante 0.

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

A canção que ela cantava, que Ivo esqueceu e o violão não termina (design 01, seções 4 e 9.1; roteiro, cena 5). 76 BPM.

| Arquivo | Uso | Duração | Modo |
|---|---|---|---|
| `cancao_da_esposa_completa.mid` | a canção inteira: memória, flashback, epílogo | ~47 s | Importar no editor; voz + violão + violoncelo |
| `cancao_da_esposa_curta.mid` | o caderno, um momento curto | ~22 s | Importar no editor |
| `cancao_da_esposa_cantarolada.mid` | a filha cantarolando as quatro primeiras notas e parando | ~3 s | Importar no editor; só voz |

Forma (A A' B A + final):
- **A**: Mi Sol Mi. Ré | Dó Ré Mi Dó. É exatamente a canção da manhã do jogo (`morning_song.tres`), a parte que o violão alcança.
- **A'**: a resposta, que sobe ao Lá e para em Ré, pedindo continuação.
- **B**: a ponte, Lá Lá Sol Mi.
- **A** de novo e **o final perdido: Ré Mi Ré Dó**, Dó longo. É o que Ivo esqueceu. O violão nunca chega lá. Na batalha final, a frase dele (Mi Sol Mi Ré Ré Dó) termina em Dó por outro caminho: ele não recupera o final dela, faz o dele.

No AIVA, a faixa "Voz" usa "Voice Oohs". Se o AIVA tiver voz feminina ("Female Choir" / "Solo Soprano"), use-a; uma flauta macia também serve. O violão deve soar simples, um pouco torto (velocidades irregulares ajudam).

## A canção final

| Arquivo | Uso | Duração | Modo |
|---|---|---|---|
| `cancao_final_12.mid` | as 12 notas harmonizadas (frase A e frase B) | ~13 s | Influência para a batalha; importar no editor para ouvir |
| `batalha_final_esboco.mid` | esboço da luta: o inverno três vezes, a harpa da primavera entrando por cima (a revelação), depois o chamado final | ~33 s | Influência; peça 3 a 4 min e **stems** |
| `restauracao.mid` | a cena da lâmpada: a frase B ao piano, cordas lentas, terminando em Dó | ~12 s | Importar no editor |

Na batalha, peça **stems** separados: a harpa da primavera precisa ser uma faixa própria, porque o jogo a cala quando o jogador escolhe uma trilha.

## Quando os WAVs estiverem prontos

Ponha-os em `assets/audios/soundtrack/` com o mesmo nome do MIDI (`reduzida_congelar.wav`, ...) e me avise. Eu converto para OGG, ligo cada um na canção (`excerpt`, a resposta, a cena) e ajusto os `note_cues` pelo áudio real.
