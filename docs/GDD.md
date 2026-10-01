# GDD: LATE CHECKOUT: NIGHT SERVICE

> Documento original enviado pelo dono do projeto (texto colado sem alterações de conteúdo; só a quebra em títulos foi ajustada).

GAME DESIGN DOCUMENT (GDD): LATE CHECKOUT (NIGHT SERVICE)

## 1. Visão Geral do ProjetoTítulo: LATE CHECKOUT: NIGHT SERVICE (Roblox Tag: [HORROR] Late Checkout)Gênero: Terror Analógico / Roguelite Cooperativo / Service HorrorPlataforma: Roblox (PC, Mobile, Console) - Otimizado para Spatial Voice (13+)Formato de Sessão: 15 a 20 minutos por corrida (Foco em altíssima rejogabilidade)Premissa: Os jogadores não controlam avatares em um espaço físico, mas sim "espectadores" que foram sugados para dentro da Fita de Treinamento Institucional nº 4: Serviço Noturno, produzida pela misteriosa corporação Aethelgard Hospitality em 1987. O objetivo é sobreviver aos 20 andares gerados proceduralmente e bater o ponto no saguão térreo, seguindo regras de conduta absurdas sob a ameaça de entidades liminares.

### 1.1. Pilares de Design (Core Pillars)Paranoia Cooperativa: O grupo depende do Voice Chat para coordenar ações e avisar sobre anomalias, mas o próprio Voice Chat é usado pelos monstros para atrair e enganar os jogadores.Terror de Regras (Rule-based Horror): A punição não vem aleatoriamente. Ela é sempre consequência de uma falha do jogador em seguir uma instrução bizarra, gerando o sentimento de "a culpa foi minha".Vale da Estranheza (Uncanny Valley): Afastamento total de monstros clássicos (zumbis, monstros de gosma). O medo é gerado por rostos hiper-realistas e proporções erradas contrastando com o ambiente em blocos do Roblox.2. Direção de Arte e Audiovisual (Estética Analógica)

### 2.1. Filtros e Renderização (O Efeito VHS)Todo o jogo roda com uma camada de pós-processamento para emular uma fita VHS degradada:Taxa de Quadros Simulada: As animações das entidades operam a 15-24 FPS, dando uma sensação de "stop-motion" perturbador, enquanto o movimento do jogador flui normalmente, criando desconexão visual.Aberração Cromática e CRT: Bordas da tela levemente arredondadas e sangramento de cores (vermelho e azul) em fontes de luz intensa.Degradação de Fita (Sanity/Proximity Meter): A estática (ruído branco) e as falhas visuais (glitches) na tela aumentam conforme entidades se aproximam ou quando o jogador quebra o contato visual com regras específicas.

### 2.2. Interface de Usuário (HUD)O HUD é diegético e minimalista, emulando o On-Screen Display (OSD) de filmadoras antigas dos anos 80.Canto Superior Esquerdo: Texto verde fosforescente PLAY ⏵ e um contador de tempo 00:00:00 (que distorce quando entidades estão perto).Ausência de Barras de Vida: No lugar da vida, o nível de perigo é medido pela quantidade de distorção de áudio e vídeo. Um ataque resulta em "Fim de Transmissão" (Tela Azul de VCR) imediato.

### 2.3. Design de Áudio (A Arma Principal)Ausência total de música de fundo tradicional. O ambiente acústico é dominado por:Zumbido de lâmpadas fluorescentes que falham de forma rítmica.O rangido mecânico das rodas metálicas do carrinho de serviço.Alarmes EAS (Emergency Alert System): Substituem os rugidos de monstros. Quando o caçador principal inicia uma perseguição, um bipe contínuo de transmissão de emergência sobrepõe todos os sons.Text-to-Speech Antiquado: Os treinamentos e avisos de segurança tocados nos televisores usam geradores de voz robóticos dos anos 80 (como SAM - Software Automatic Mouth), sem entonação emocional.3. O Loop de Gameplay

### 3.1. O Carrinho de Serviço (The Trolley)O carrinho é a âncora do grupo e o único refúgio seguro em cenários abertos.Física e Movimento: Exige que pelo menos 1 jogador segure a barra traseira para ser empurrado. Dois jogadores empurrando aumentam a velocidade em 50%.Estoque Físico: Contém itens gerados aleatoriamente por andar: toalhas, chaves-mestras, bandejas de carne crua (para despistar entidades), fita isolante (para consertar fios expostos).Portinhola de Emergência: O carrinho possui um compartimento inferior de lixo. Apenas 1 jogador pode se esconder ali dentro. Em caso de perigo iminente em um corredor sem portas, os 4 jogadores terão que decidir em pânico quem sobrevive.

### 3.2. Estrutura da Corrida (20 Andares)FaseAndaresCaracterísticas e Nível de AmeaçaIntegração01 ao 05Corredores limpos. Introdução às regras de limpeza e entrega. Aparição de anomalias passivas (Espelhos, Quartos Famintos).Degradação06 ao 12O papel de parede descasca. As luzes falham. Introdução da "Camareira Sem Rosto". O Carrinho de Serviço começa a sofrer danos mecânicos aleatórios (rodas travando).Distorção13 ao 18A física do hotel quebra. Corredores formam loops infinitos. Aparição d'O Instrutor. Mutações de turno (ex: corredores inundados com água escura).O Fim da Fita19 ao 20Fuga estruturada no Lobby. Entrega do relatório. Teste de memorização das anomalias enfrentadas para destravar o elevador final.4. Bestiário e Anomalias (O Terror de Regras)

### 4.1. O Antagonista Principal: "O Instrutor" (The Trainer)A entidade máxima corporativa. Ele não é um monstro tradicional, é o "avaliador" da fita VHS.Visual: Corpo veste um terno marrom impecável. O pescoço é um cilindro preto de polígono simples que se estende por 1 metro. O rosto é uma imagem 2D fotorrealista de um executivo sorrindo (semelhante ao "This Man" de sonhos urbanos), fixada de frente para o jogador (estilo billboard sprite de DOOM clássico).A Mecânica de "Roubo de Voz" (Voice Stealing): O jogo grava silenciosamente os últimos 3 a 5 segundos de fala de cada jogador no Spatial Voice. O Instrutor não tem som próprio; ele reproduz trechos da voz do grupo, adicionando um efeito de lentidão magnética e eco, para atrair jogadores isolados em bifurcações.A Regra de Ataque (M.A.D. - Mutually Assured Destruction): Se O Instrutor aparecer em um corredor, o jogador sofre de paralisia se olhar diretamente para a entidade por mais de 1.5 segundos (a tela enche de estática e o rosto 2D ocupa o monitor inteiro antes da morte).Procedimento de Sobrevivência: O jogador deve usar um emote dedicado ("Cobrir os Olhos") e andar de costas/guiado por paredes ou comandos de voz dos colegas até que a entidade desapareça. Dar as costas fisicamente sem cobrir os olhos resulta em morte instantânea (pescoço quebrado).

### 4.2. A Camareira Sem Rosto (The Ghost Trolley)Manifestação: Luzes piscam em tom âmbar. Som de um carrinho enferrujado em alta velocidade vindo das costas do grupo.Procedimento de Sobrevivência: Todos devem equipar itens de limpeza (vassoura/espanador) e clicar no chão/parede simulando trabalho, mantendo silêncio absoluto no microfone. Qualquer ruído capta a atenção dela para um atropelamento letal.

### 4.3. O Hóspede do 302 (The Hungry Resident)Manifestação: Campainha de quarto específica toca. A porta abre apenas uma fresta, revelando braços pálidos e longos demais rastejando pelo batente.Procedimento de Sobrevivência: Colocar a bandeja a exatamente 1 metro de distância no chão. Virar 180 graus imediatamente e dizer no Voice Chat: "Bom apetite, favor não incomodar". Se entregar em mãos ou não disser a frase, o jogador é puxado para dentro do quarto.

### 4.4. A Anomalia de Manutenção (O Falso Colega)Manifestação: Em andares mais escuros, um 5º jogador idêntico ao avatar de um dos membros da equipe aparece andando silenciosamente à frente do grupo, segurando ferramentas.Procedimento de Sobrevivência: Não seguir e não interagir. Se o grupo tentar conversar no Proximity Chat próximo a ele, a entidade vira o rosto (que é um buraco negro de estática) e aplica um debuff de cegueira e mudez (desliga o microfone) no jogador por 60 segundos, desestabilizando a comunicação da equipe.5. Design de Nível e Fator Viral (FNAF-Lore)

### 5.1. Mecânica de "Frames Subliminares"Durante a transição de andares ou quando regras em televisores de CRT estão sendo exibidas, a tela pode sofrer uma falha de exatos 1 frame (1/60s). Esses frames escondem:Códigos binários, diagramas de placas-mãe sobrepostos a crânios humanos, ou coordenadas reais.Objetivo: Forçar criadores de conteúdo a gravar, baixar suas próprias lives, pausar e compartilhar os segredos no Twitter/Reddit/TikTok, gerando teoria da conspiração em torno do jogo.

### 5.2. O Sistema da Câmera Polaroid (Risco vs. Lore)O carrinho começa com uma Câmera Polaroid contendo apenas 3 flashes por corrida.Uso Funcional: Pode cegar O Instrutor por 3 segundos, permitindo uma fuga desesperada.Uso Lore/Viral: Certas paredes apresentam manchas pretas sutis. Usar o flash revela frases escritas em tinta sangue/UV invisível (Ex: "A fita está te gravando de volta", "O 15º andar não existe").Desvantagem: O som agudo do carregamento do flash atrai entidades passivas e acorda os andares. O grupo deve decidir se a sobrevivência vale a investigação.

### 5.3. O "Quarto Fora da Fita" (The Backrooms Effect)Existe um Easter Egg de 1 em 1.000 chances ao abrir uma porta padrão de quarto de hotel.A Revelação: A porta abre para uma sala de servidores moderna de 2026, com iluminação de LED azul, fios de fibra ótica e telas exibindo o próprio jogo do Roblox sendo monitorado. O efeito VHS some imediatamente assim que a porta abre, revelando gráficos super limpos. A porta bate sozinha em 4 segundos e o filtro VHS retorna com um EAS Alarm ensurdecedor.Terminal Oculto: O saguão final possui um teclado numérico camuflado atrás de um vaso de plantas. Se os jogadores conseguirem decifrar e juntar os códigos dos frames subliminares e das polaroids através de múltiplas sessões, digitar a senha correta desbloqueia a "Fita Limpa" (O Final Verdadeiro).6. Economia e Monetização SustentávelA estratégia de monetização foca rigorosamente em cosméticos e ferramentas sociais/sociais-diegéticas, abolindo qualquer Gamepass Pay-to-Win (como armas, velocidade extra ou pulo de andar), garantindo o respeito da base hardcore de terror.

### 6.1. Loja Interna do Lobby (Com Moeda "Gorjetas")Ganha-se "Gorjetas" baseadas nos quartos atendidos com sucesso e na sobrevivência.Crachás de Veterano (Patches): Cosméticos aplicados ao uniforme do avatar mostrando o número de Fitas Sobrevividas.Toca-Fitas de Cinto: Permite selecionar faixas de Elevator Pitch Jazz corrompido para tocar no próprio raio de proximidade no lobby.

### 6.2. Gamepasses Premium (Robux)Gamepass / ProdutoCusto SugeridoFuncionalidade e ApeloSkins do Carrinho de Serviço250 R$Substitui o carrinho padrão por: Carrinho de Supermercado Quebrado, Maca Hospitalar Enferrujada ou Carrinho de Golfe Destruído. Visibilidade imediata para o time inteiro.Walkie-Talkie do Além400 R$Quando o jogador morre, ele se torna um espectador. Com este passe, o jogador morto pode sussurrar estática e mensagens curtas de áudio diretamente nos rádios dos vivos. Gera infinitos "trolls" de streamers assustando os próprios amigos sobreviventes.Animações de "Demissão"150 R$Personaliza o que acontece com o corpo do jogador quando abatido. Ex: O corpo se dobra em um cubo impossível; o corpo vira um manequim de madeira; o corpo é sugado para dentro do chão.Vending Machine Revive (1x)50 R$Compra única por corrida. Adiciona um consumível "Lata de Refrigerante Vencido" no carrinho. Se um membro morrer, os vivos podem inserir a lata em uma máquina no próximo andar para trazer o jogador de volta, mas a tela dele ficará com 20% a mais de falhas visuais.

## 7. Sistema de Progressão e Metagame
Para manter a base de jogadores engajada por meses após o lançamento, o jogo utiliza um sistema de progressão estruturado em "Níveis de Acesso Corporativo" e colecionáveis investigativos.

### 7.1. Cargos Corporativos (Rank System)
Sobreviver a turnos ou realizar tarefas perfeitamente (ex: não errar nenhuma entrega de quarto) concede "Pontos de Avaliação" (XP). O jogador sobe na hierarquia da Aethelgard Hospitality, alterando o crachá do seu avatar no lobby:

Nível 0-9: Trainee Descartável (Crachá branco de papel).

Nível 10-24: Zelador Noturno (Crachá de plástico azul).

Nível 25-49: Supervisor de Andar (Crachá prateado).

Nível 50+: [REDIGIDO] (Crachá manchado de estática preta, os NPCs do lobby passam a sussurrar quando o jogador passa).

### 7.2. O Arquivo (Lore Collection)
Em andares avançados, os jogadores podem encontrar "Fitas Beta" escondidas em gavetas ou dentro de dutos de ventilação.

Ao extrair essas fitas no fim do turno, elas vão para a Sala de Arquivo (uma área privada acessada pelo Lobby principal).

Na Sala de Arquivo, o jogador pode reproduzir essas fitas em uma TV CRT. Elas contêm cutscenes curtas em live-action de baixa qualidade (imagens fotorrealistas animadas rudimentarmente) ou áudios de funcionários anteriores enlouquecendo, recompensando os "Lore Hunters" e gerando conteúdo constante para canais de teorias.

### 7.3. Modificadores de Fita (Hard Mode & Custom Matches)
Ao atingir o Nível 10, o jogador desbloqueia a máquina "Desmagnetizadora" no lobby, que permite aplicar modificadores de dificuldade na próxima corrida em troca de multiplicadores de "Gorjetas" (Moeda In-game):

Fita Mastigada (+50% Moeda): Aumenta a frequência de glitches visuais e falhas de áudio no HUD em 30%.

Corte Orçamentário (+75% Moeda): O carrinho começa sem bateria sobressalente e sem fita isolante.

Turno Duplo (+100% Moeda): Em vez de 20 andares, o gerador procedural cria 30 andares, com 2 entidades simultâneas a partir do andar 20.

## 8. Arquitetura Técnica e Integração Roblox
Para que a estética de Terror Analógico funcione sem lagar celulares ou consoles antigos, o jogo precisa de uma arquitetura inteligente no Roblox Studio.

### 8.1. Geração Procedural Modular (Client vs. Server)
Carregamento Oculto (Chunk Loading): Para evitar quedas de FPS, o jogo nunca renderiza os 20 andares de uma vez. O servidor carrega apenas o andar atual, o andar anterior e o próximo andar. As portas do elevador ou corredores de transição servem como pontos de carregamento (culling).

Física do Carrinho (Network Ownership): O carrinho de serviço tem sua física calculada no servidor para evitar que exploiters (hackers) teletransportem o carrinho para o fim da fase. Porém, a fluidez de empurrar é controlada pelo cliente (Client-Side Prediction), garantindo que não pareça pesado ou "lagado" para quem está empurrando.

### 8.2. Manipulação da API de Áudio (Spatial Voice & Echoes)
O Roblox liberou recentemente ferramentas avançadas de áudio. LATE CHECKOUT explora isso ao máximo:

AudioAnalyzer e AudioFader: Usados na entidade "O Instrutor". O jogo utiliza o AudioAnalyzer para captar o volume de quem fala. Quando "O Instrutor" está perto, a voz real do jogador passa por um AudioChorus e AudioPitchShifter em tempo real, distorcendo o que ele fala para os outros, quebrando a confiança do time.

Oclusão Acústica: Os passos de monstros e alarmes EAS são abafados por paredes e portas usando Raycasting de Áudio. Se um jogador fecha a porta de um quarto, os gritos do lado de fora ficam mecanicamente abafados.

## 9. UX/UI e Design do Lobby (A Diegese Total)
O jogador nunca interage com menus clássicos ou botões 2D espalhados na tela. Toda a interface principal é diegética (faz parte do mundo do jogo).

### 9.1. A Sala de Descanso (The Break Room - Lobby Principal)
Ao entrar no jogo, o jogador nasce em uma sala de funcionários com paredes bege sujas de fumaça, luzes fluorescentes piscando e cheiro implícito de café queimado e mofo.

Matchmaking (Seleção de Partida): Em vez de um botão "Play", há um Aparelho de Videocassete sobre uma mesa. O host do grupo pega uma Fita VHS na prateleira e insere no aparelho. O grupo deve sentar no sofá em frente à TV. Quando a fita roda, a tela foca na TV e a transição para o andar 1 acontece.

Loja de Cosméticos: É uma Máquina de Venda Automática (Vending Machine). O jogador clica no vidro para inspecionar os cosméticos. Ao comprar com Robux ou Gorjetas, a máquina cospe uma caixa de papelão.

O Terminal MS-DOS: Um computador antigo no canto da sala onde os jogadores podem digitar senhas secretas encontradas em Frames Subliminares para liberar emblemas secretos (Badges do Roblox) e fitas bônus.

### 9.2. Acessibilidade e Controles Universais
Mobile (Toque): Para facilitar a vida dos jogadores mobile (que representam mais de 70% do Roblox), o "Empurrar o Carrinho" é um botão de contexto automático. Quando o jogador encosta no carrinho, um botão de Toggle aparece na tela, travando o jogador no carrinho para que ele só precise usar o joystick direcional (Thumbstick) para guiar.

Suporte a Surdez/Deficiência Auditiva: Como o áudio é vital, o jogo possui um modo opcional de "Fita Legendada" nas configurações (mostrando legendas textuais como [SOM DE CARRINHO FANTASMA SE APROXIMANDO PELA ESQUERDA]), o que evita a exclusão de jogadores que não podem usar fones de ouvido.

## 10. Estratégia de Atualizações (LiveOps & Post-Launch)
O algoritmo do Roblox prioriza jogos que recebem grandes picos de atualizações. O roadmap é estruturado em "Novas Fitas de Treinamento".

### 10.1. Atualização 1.0 (Mês 1) - O Turnover
Lançamento oficial dos 20 primeiros andares.

Introdução das 5 anomalias básicas.

Evento de "Caça à Lore": Primeiro criador de conteúdo que postar um vídeo descobrindo a senha final no terminal MS-DOS ganha uma Skin Exclusiva dourada do carrinho.

### 10.2. Atualização 1.5 (Mês 3) - Fita de Treinamento nº 5: Manutenção do Subsolo
Nova Rota Opcional: No andar 10, o elevador quebra e o grupo é forçado a descer para os andares negativos (Boiler Room / Casa de Máquinas).

Nova Mecânica: O ambiente é 100% escuro e o carrinho não passa pelos canos. Os jogadores devem carregar caixas de suprimentos nas costas (movimento reduzido) e usar sinalizadores vermelhos que atraem uma nova entidade cega, sensível apenas a luz intensa e movimento rápido.

### 10.3. Atualização Sazonal - Turno de Feriado (Halloween/Natal Bizarro)
O Gerente obriga os funcionários a decorarem os andares.

Adição temporária de pedidos absurdos: (Ex: "Entregue perus de ação de graças que estão secretamente respirando na bandeja").

Filtros de VHS temáticos no HUD, simulando programas especiais de fim de ano dos anos 70 corrompidos.

## 11. Design Social e Sistemas Anti-Griefing (Prevenção de Toxicidade)
Jogos cooperativos no Roblox frequentemente sofrem com "trolls" — jogadores que entram apenas para sabotar a equipe (roubando itens, gritando no microfone ou trancando portas). LATE CHECKOUT utiliza mecânicas punitivas integradas à própria Lore para transformar a sabotagem em suicídio no jogo.

### 11.1. O Sistema de "Justa Causa" (Punição de Trolls)
Griefing de Áudio: Se um jogador ficar gritando de propósito no Voice Chat para atrair monstros para a equipe, "O Instrutor" ou "A Camareira" ignoram os jogadores quietos e dão Insta-Kill exclusivamente no jogador barulhento. A mensagem de morte para ele será: "Demissão por Poluição Sonora".

Retenção de Itens-Chave: Se um jogador pegar um item vital (como um fusível ou a câmera polaroid) e se recusar a usá-lo ou devolvê-lo, o Carrinho de Serviço tem um botão de "Reclamação ao RH". Ao ser pressionado pela maioria, o item é teletransportado de volta para o carrinho com um choque elétrico que tira metade da sanidade do troll.

Bloqueio de Portas (Bodyblocking): A física dos avatares permite atravessar outros jogadores (sem colisão de personagens) após 2 segundos de empurrão contínuo, impedindo que alguém tranque o time em um corredor estreito.

### 11.2. Escalabilidade de Equipe (Drop-in / Drop-out)
Desconexões: Se um jogador cair por problema de internet, o avatar dele se transforma em uma "Mochila Esquecida" no chão contendo seus itens. A dificuldade do gerador procedural se reescala automaticamente (ex: o carrinho fica mais leve para ser empurrado por 3 pessoas e menos monstros surgem).

## 12. Módulos de Geração Procedural (O Design das Salas)
O gerador do jogo não cria corredores genéricos. Ele "costura" Módulos Pré-Fabricados (Rooms). Aqui estão exemplos de módulos raros que quebram a monotonia do corredor do hotel:

### 12.1. Módulo: "A Lavanderia de Sangue" (Raridade: Incomum)
Visual: Um salão aberto cheio de máquinas de lavar industriais dos anos 70 girando violentamente. O chão está coberto de água com espuma suja.

Mecânica: O carrinho não pode passar por cima dos fios soltos na água sem dar curto-circuito. O grupo precisa usar prateleiras caídas para fazer uma ponte para o carrinho, enquanto máquinas de lavar específicas abrem suas escotilhas e "sugam" jogadores que chegarem muito perto.

### 12.2. Módulo: "As Piscinas do Hotel" (Raridade: Épico / Liminal Space)
Visual: Transição brusca da arquitetura. O papel de parede clássico some e dá lugar a azulejos brancos encardidos iluminados por uma luz azul doentia. O som fica com um eco opressivo. Não há portas de quartos aqui, apenas piscinas rasas e pilares.

Mecânica: A água desacelera o movimento em 50%. Não há regras de quartos, mas é aqui que "O Reflexo Afogado" ataca. Sombras em formato humano nadam sob o azulejo sólido e tentarão puxar as pernas dos jogadores. O grupo deve guiar o carrinho pelas bordas secas.

### 12.3. Módulo: "Corredor Fita-Cassete" (Raridade: Lendário)
Visual: O corredor é idêntico ao andar 1, mas o filtro de tela fica sépia intenso e a música do lobby começa a tocar de trás para frente.

Mecânica: A física inverte. O carrinho precisa ser puxado de costas para avançar, e os controles do teclado/analógico dos jogadores ficam invertidos durante esse corredor inteiro. É um módulo focado na desorientação total, gerando pânico e muitas risadas em chamadas de voz.

## 13. A Verdadeira Lore (O Guia para os Desenvolvedores)
Para que os "Lore Hunters" encontrem peças de um quebra-cabeça que faça sentido, a equipe de desenvolvimento precisa saber a verdade por trás da fita.

O Segredo (Não revelado aos jogadores no início):
O Grand Limbo Hotel nunca existiu. A "Aethelgard Hospitality" é, na verdade, um projeto do Departamento de Defesa focado em Controle Mental e Tortura Psicológica por Frequências de Rádio (inspirado no MKUltra).

A fita VHS de treinamento é uma armadilha cognitiva. Quem a assiste tem a consciência baixada para uma simulação hostil (um software rudimentar dos anos 80 rodando em Mainframes antigos).

As Entidades: Não são fantasmas. São instâncias de rotinas de formatação do sistema, desenhadas para fragmentar o cérebro das cobaias pelo medo extremo. "O Instrutor" é o Antivírus Mestre.

Os Hóspedes: São os resquícios digitais das cobaias anteriores (jogadores de anos atrás) que falharam no treinamento e cujas mentes ficaram presas nos "quartos" da memória do servidor.

O Check-Out: Bater o ponto no final não significa voltar à vida real. Significa ser arquivado com sucesso no banco de dados corporativo, apagando sua identidade humana (explicando por que os avatares de nível alto no Lobby começam a parecer anômalos).

## 14. Estratégia de Marketing e Lançamento (Go-to-Market)
Para romper a bolha inicial e garantir o crescimento explosivo pelo algoritmo de descoberta do Roblox:

### 14.1. Fase de Teaser (TikTok / YouTube Shorts)
Campanha "Fita Encontrada" (Found Footage): O jogo não é anunciado como um "jogo do Roblox". A equipe cria contas no TikTok e posta vídeos curtos no formato 4:3 de câmera VHS, mostrando um quarto de hotel normal, até que, no último segundo, o robloxiano padrão aparece corrompido, e a tela corta para o logo: LATE CHECKOUT.

Sem Links de Início: Apenas coordenadas ou strings de código morse nos comentários que levam ao servidor do Discord oficial, gerando uma comunidade de detetives antes mesmo do jogo lançar.

### 14.2. Acesso Antecipado "Vazamento" (Early Access)
Campanha de Influenciadores: O jogo não libera o acesso a todos imediatamente. O desenvolvedor contata 5 a 10 criadores de conteúdo focados em Roblox Horror (KreekCraft, Bandites, Flamingo, ou criadores brasileiros de grande porte) e envia uma mensagem estilo e-mail corporativo anos 80: "Você foi selecionado para o turno da madrugada. Sua fita de treinamento aguarda." junto com o acesso privado.

O público será forçado a assistir às lives para ver o jogo, acumulando Hype e desejo reprimido de jogar.

### 14.3. Lançamento Aberto & Programa de Criadores (UGC)
Ao lançar, haverá um Quadro de Funcionários do Mês no Lobby do jogo. Os streamers que mais trouxerem público ou os que conseguirem os melhores tempos de Check-Out terão a foto de seus avatares pendurada no Lobby do jogo na frente de todos os outros jogadores.

Isso incentiva criadores a jogarem repetidamente para tentarem manter seus rostos (brand awareness) no lobby principal do jogo mais quente do mês.
