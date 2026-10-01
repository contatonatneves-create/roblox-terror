# LATE CHECKOUT: NIGHT SERVICE

Terror cooperativo (1–4 jogadores) para Roblox. Funcionários do turno da noite do hotel Aethelgard
sobem 20 andares empurrando um carrinho de serviço, cumprindo tarefas — tudo gravado numa fita VHS.
A mecânica central é o **Sistema de Ruído**: passos, corrida, esbarrões e o carrinho fazem barulho,
e as entidades reagem a isso.

O design completo está em [`docs/GDD_Late_Checkout_v2.pdf`](docs/GDD_Late_Checkout_v2.pdf).

O código fica neste repositório e é sincronizado com o Roblox Studio pelo [Rojo](https://rojo.space).
Tudo no mundo (sala de descanso, andares, elevadores, carrinho, Camareira) é montado por código
quando o jogo roda, então o place do Studio só precisa dos scripts.

## Estado atual

| Etapa | Situação |
|---|---|
| 0. Estrutura do projeto e GDD v2 | Pronto |
| 1. Núcleo jogável (lobby, fita, andares, carrinho, ruído, tarefas, Camareira, morte, check-out) | Pronto e testado no Studio |
| 2. Mais tarefas e eventos por fase | A fazer |
| 3. Entidades da Degradação | A fazer |
| 4. Distorção e efeitos de fita | A fazer |
| 5. Fim da Fita (andares 19–20) | A fazer |
| 6. Polimento, sons, celular | A fazer |
| 7. Publicação | A fazer |

### Testado na Etapa 1

- Sala de descanso com filtro VHS, OSD e TV.
- Início da fita, andar gerado, elevador de chegada, carrinho no chão.
- Empurrar (E), soltar (Q), esconder na portinhola (F) e sair (Q) em lugar livre.
- Entregar toalhas (pegar no carrinho com T, segurar E na porta) e limpar a mancha (5 vassouradas).
- Elevador: só sobe com todos vivos e o carrinho dentro.
- Camareira (andar 6+): aviso com luz âmbar e rangido; sobrevive quem está escondido, ou parado,
  quieto e varrendo. Quem está dentro do elevador não é julgado.
- Morte (tela azul FIM DE TRANSMISSÃO), fita rejeitada quando todos morrem, check-out no andar 20.
- Medidor de ruído: andar no carpete ≈ 11, correr ≈ 38.

## Controles

| Ação | Teclado | Celular |
|---|---|---|
| Correr | Shift (segurar) | CORRER |
| Andar com cuidado | C (liga/desliga) | CUIDADO |
| Empurrar o carrinho | E na barra | Botão do prompt |
| Esconder-se na portinhola | F (segurar) | Botão do prompt |
| Soltar o carrinho / sair da portinhola | Q | SOLTAR / SAIR |
| Pegar toalhas | T no carrinho | Botão do prompt |
| Varrer | Clique com a vassoura | Toque |

## Ferramenta de teste (só no Studio)

Durante o Play, na aba Server da Command Bar:

```lua
local t = game.ServerStorage.TesteTerror
t:Invoke("Iniciar", 1)   -- começa a fita no andar 1 (com quem estiver no jogo)
t:Invoke("Andar", 6)     -- pula para o andar 6
t:Invoke("Camareira")    -- chama a Camareira agora
t:Invoke("Tarefas")      -- completa as tarefas do andar
t:Invoke("Toalhas")      -- dá toalhas para todos
t:Invoke("Matar", 1)     -- mata o jogador 1
t:Invoke("Estado")       -- mostra estado, andar e vivos
```

## Estrutura

```
default.project.json   Mapa do Rojo: qual pasta vira qual lugar no Studio
docs/                  GDD (texto original e PDF v2)
src/
  shared/Config.luau   Números de balanceamento (ReplicatedStorage.Shared)
  server/              Main + Services/ (Build, State, Noise, Floors, Trolley, Maid, Lobby, Tape)
  client/              VHS (filtro, OSD, telas) e Controls (controles, voz, luzes, sons)
```

## Como trabalhar com o Rojo

1. Instale o Rojo: https://github.com/rojo-rbx/rojo/releases (ou `aftman install`).
2. No Studio, instale o plugin do Rojo (Plugins → Manage Plugins → procure "Rojo").
3. Na pasta deste repositório, rode `rojo serve`.
4. No Studio, abra o plugin do Rojo e clique em **Connect**.

Em Game Settings, coloque **Max Players = 4**.
