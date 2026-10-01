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
| 1. Fita jogável (lobby, fita, andares, carrinho, ruído, tarefas, Camareira, morte, check-out) | Pronto e testado no Studio |
| 2. Bestiário (Hóspede do 302, Instrutor, Falso Colega, Polaroid, itens do carrinho, rodas, conserto) | Pronto e testado no Studio |
| 3. Fases e módulos (degradação visual, loops, inundação, Lavanderia, Piscinas, Fita-Cassete, relatório final) | A fazer |
| 4. Metagame e save (Gorjetas, XP, cargos, Arquivo, Desmagnetizadora, DataStore) | A fazer |
| 5. Lore e viral (frames subliminares, tinta UV, Quarto Fora da Fita, terminal, Fita Limpa) | A fazer |
| 6. Social e acessibilidade (Justa Causa, RH, Fita Legendada, Reduzir Efeitos, celular) | A fazer |
| 7. Monetização e lançamento | A fazer |

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

### Testado na Etapa 2

- **Hóspede do 302** (andares 3–18): campainha, porta em fresta com braços, marca no carpete.
  Bandeja na marca + de costas + frase [G] = serviço feito. Dizer de frente, entregar em mãos [R],
  não dizer em 6 s ou fazer barulho perto da porta = puxado para dentro do quarto.
- **Instrutor** (andares 13–20): rosto 2D sempre virado para quem olha. Encarar por 1,5 s = morte.
  Cobrir os olhos [V] (tela escura, anda devagar e de costas). Dar as costas sem cobrir = morte.
  Flash da Polaroid fecha os olhos dele por 3 s e o faz sumir logo depois. Imita ruídos do grupo.
- **Falso Colega** (andares 9–20): cópia silenciosa de alguém do grupo, andar escurece.
  Barulho a até 15 studs = rosto de estática, cegueira e passos pesados por 60 s.
- **Polaroid** no carrinho [P]: 3 flashes por fita, cada flash faz ruído 70.
- **Itens do carrinho**: bandeja [B], fita isolante [X], toalhas [T].
- **Conserto** (andar 6+): fio soltando faíscas sobre uma poça; pisar na água = eletrocutado.
- **Rodas travam** (andar 6+): o carrinho fica lento e range alto por 5 s.
- Só uma entidade age por vez (as outras esperam a vez).

## Controles

| Ação | Teclado | Celular |
|---|---|---|
| Correr | Shift (segurar) | CORRER |
| Andar com cuidado | C (liga/desliga) | CUIDADO |
| Empurrar o carrinho | E na barra | Botão do prompt |
| Esconder-se na portinhola | F (segurar) | Botão do prompt |
| Soltar o carrinho / sair da portinhola | Q | SOLTAR / SAIR |
| Pegar toalhas / bandeja / fita isolante / Polaroid | T / B / X / P no carrinho | Botão do prompt |
| Varrer, usar a Polaroid | Clique com a ferramenta | Toque |
| Deixar a bandeja na marca | E (segurar) | Botão do prompt |
| Dizer a frase ao Hóspede | G | DIZER A FRASE |
| Cobrir os olhos | V | COBRIR OLHOS |
| Consertar o fio | E (segurar) no fio | Botão do prompt |

## Ferramenta de teste (só no Studio)

Durante o Play, na aba Server da Command Bar:

```lua
local t = game.ServerStorage.TesteTerror
t:Invoke("Iniciar", 1)   -- começa a fita no andar 1 (com quem estiver no jogo)
t:Invoke("Andar", 6)     -- pula para o andar 6
t:Invoke("Camareira")    -- chama a Camareira agora
t:Invoke("Tarefas")      -- completa as tarefas do andar
t:Invoke("Toalhas")      -- dá toalhas para todos
t:Invoke("Itens")        -- dá bandeja, fita isolante e a Polaroid
t:Invoke("Hospede")      -- o Hóspede pede serviço de quarto agora
t:Invoke("Instrutor")    -- o Instrutor aparece à frente do grupo
t:Invoke("Colega")       -- o Falso Colega aparece
t:Invoke("Travar")       -- trava uma roda do carrinho
t:Invoke("Calmo")        -- desliga as entidades automáticas (Calmo, false liga de novo)
t:Invoke("Matar", 1)     -- mata o jogador 1
t:Invoke("Estado")       -- mostra estado, andar e vivos
```

## Estrutura

```
default.project.json   Mapa do Rojo: qual pasta vira qual lugar no Studio
docs/                  GDD (texto original e PDF v2)
src/
  shared/Config.luau   Números de balanceamento (ReplicatedStorage.Shared)
  server/              Main + Services/ (Build, State, Noise, Floors, Trolley, Maid, Lobby, Tape,
                       Threat, Guest, Trainer, Colleague, Polaroid)
  client/              VHS (filtro, OSD, telas), Controls (controles, voz, luzes, sons)
                       e Entidades (cobrir os olhos, olhar, frase, cegueira)
```

## Como trabalhar com o Rojo

1. Instale o Rojo: https://github.com/rojo-rbx/rojo/releases (ou `aftman install`).
2. No Studio, instale o plugin do Rojo (Plugins → Manage Plugins → procure "Rojo").
3. Na pasta deste repositório, rode `rojo serve`.
4. No Studio, abra o plugin do Rojo e clique em **Connect**.

Em Game Settings, coloque **Max Players = 4**.
