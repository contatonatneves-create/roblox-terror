# Jogo de terror (Roblox)

Jogo de terror para Roblox. O código fica neste repositório e é sincronizado com o Roblox Studio
pelo [Rojo](https://rojo.space).

## Estado atual

| Etapa | Situação |
|---|---|
| 0. Estrutura do projeto | Pronto |
| Design do jogo (GDD) | A definir |

## Estrutura

```
default.project.json   Mapa do Rojo: qual pasta vira qual lugar no Studio
src/
  shared/Config.luau   Números de balanceamento (ReplicatedStorage.Shared)
  server/              Scripts do servidor (ServerScriptService)
  client/              Scripts do cliente (StarterPlayerScripts)
tools/                 Ferramentas de apoio (ex.: montar o mapa pela Command Bar)
```

## Como trabalhar com o Rojo

1. Instale o Rojo: https://github.com/rojo-rbx/rojo/releases (ou `aftman install`).
2. No Studio, instale o plugin do Rojo (Plugins → Manage Plugins → procure "Rojo").
3. Na pasta deste repositório, rode `rojo serve`.
4. No Studio, abra o plugin do Rojo e clique em **Connect**.
