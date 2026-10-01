-- Config central do LATE CHECKOUT: NIGHT SERVICE.
-- Todos os números de balanceamento ficam aqui (GDD v2.0), para ajustar sem mexer no código.
local Config = {}

-- Corrida (seção 6)
Config.Run = {
	Floors = 20,
	MaxPlayers = 4,
	CountdownSeconds = 8, -- depois de colocar a fita no videocassete
	FloorSpacing = 1200, -- distância entre os andares no mundo (cada andar é montado longe dos outros)
	FloorOrigin = Vector3.new(0, 0, 3000),
	ArrivalDoorDelay = 2, -- segundos até a porta do elevador de chegada abrir
	ElevatorRideSeconds = 3, -- tempo da "viagem" entre andares
	ReturnToLobbyDelay = 6,
}

Config.Phases = {
	{ Name = "INTEGRACAO", Label = "Integração", From = 1, To = 5 },
	{ Name = "DEGRADACAO", Label = "Degradação", From = 6, To = 12 },
	{ Name = "DISTORCAO", Label = "Distorção", From = 13, To = 18 },
	{ Name = "FIM DA FITA", Label = "O Fim da Fita", From = 19, To = 20 },
}

-- Gerador de andares (seção 8): grade de células de 12 studs
Config.Grid = {
	Cell = 12,
	Height = 11,
	Wall = 1,
	MinCells = 9, -- células de corredor entre os elevadores
	MaxCells = 16,
	CellsPerFloorBonus = 0.35, -- + células por andar
	TurnChance = 0.3,
	PropChance = 0.35, -- chance de um objeto barulhento solto numa célula
	DoorChance = 0.75, -- chance de cada lado de um corredor ter porta
}

-- Tarefas (seção 6.4)
Config.Tasks = {
	CleanStrokes = 5, -- vassouradas para limpar a mancha
	CleanRange = 9,
	DeliverRange = 7,
	SecondTaskFromFloor = 4, -- a partir daqui o andar tem 2 tarefas
}

-- Movimento e Ruído (seção 5)
Config.Move = {
	Run = 22,
	Walk = 14,
	Careful = 7,
	PushOne = 11,
	PushTwo = 16.5,
}

Config.Noise = {
	Max = 100,
	DecayPerSecond = 40,
	-- nível de ruído enquanto se move, conforme a velocidade horizontal real do personagem
	RunLevel = 55, -- "45 por passo": correr é sempre ouvido
	WalkLevel = 15,
	CarefulLevel = 3,
	RunSpeed = 18, -- acima disso conta como correndo
	WalkSpeed = 9, -- acima disso conta como andando
	StillSpeed = 1.5, -- abaixo disso conta como parado
	Bump = 60, -- esbarrar em objeto solto
	BumpSpeed = 6, -- velocidade mínima para o esbarrão fazer barulho
	Door = 50,
	TrolleyFast = 25, -- rangido do carrinho empurrado rápido
	TrolleyFastSpeed = 12,
	Surface = { Carpet = 0.7, Hard = 1.3, Water = 1.6 },
	LoudThreshold = 35, -- acima disso o jogador "está fazendo barulho"
}

-- Carrinho de serviço (seção 6.2)
Config.Trolley = {
	MaxPushers = 2,
	HideSlots = 1,
	MaxSpeedCheck = 40, -- studs/s; acima disso o servidor considera teleporte e solta o carrinho
	Towels = 99,
}

-- Camareira Sem Rosto (seção 7.2)
Config.Maid = {
	FromFloor = 6,
	ToFloor = 20,
	Chance = 0.75, -- chance de aparecer num andar elegível
	FirstDelay = { 22, 40 }, -- segundos depois da chegada ao andar
	WarningSeconds = 5,
	Speed = 34, -- studs/s ao longo do corredor
	Fps = 12, -- anima em stop-motion
	KillRadius = 6,
	CleanWindow = 1.6, -- segundos desde a última vassourada para contar como "limpando"
	StillSpeed = 2.5,
	DebugFromFloor = nil, -- para testes: forçar a partir de um andar
}

-- Morte e espectador
Config.Death = {
	BlueScreenSeconds = 4,
	RespawnTime = 5,
}

-- Sons (Creator Store, livres)
Config.Sounds = {
	Hum = "rbxassetid://4227579935",
	TrolleySqueak = "rbxassetid://9112778413",
	Static = "rbxassetid://96891705634188",
	EAS = "rbxassetid://9113089565",
	Ding = "rbxassetid://18192219147",
	Rewind = "rbxassetid://9071933477",
	TapeInsert = "rbxassetid://107601815810038",
	Broom = "rbxassetid://93860596430492",
	ElevatorDoors = "rbxassetid://9114305290",
	Beep = "rbxassetid://91072655090313",
	Bump = "rbxassetid://9125743356",
	TvOff = "rbxassetid://78535264432518",
}

-- Voz robótica das TVs (AudioTextToSpeech)
Config.Voice = {
	VoiceId = "1001", -- português (masculino)
	Pitch = -3,
	Speed = 0.92,
	Enabled = true,
}

-- Textos das regras mostradas nas TVs
Config.Rules = {
	Default = "MANTENHA O CARRINHO COM VOCÊ. NÃO CORRA NOS CORREDORES.",
	Maid = "SE AS LUZES FICAREM ÂMBAR: PARE. LIMPE. NÃO FAÇA BARULHO.",
}

function Config.PhaseOf(floor: number)
	for _, p in ipairs(Config.Phases) do
		if floor >= p.From and floor <= p.To then
			return p
		end
	end
	return Config.Phases[#Config.Phases]
end

function Config.FloorOrigin(floor: number): Vector3
	return Config.Run.FloorOrigin + Vector3.new((floor - 1) * Config.Run.FloorSpacing, 0, 0)
end

-- Direções da grade: 0 = -Z, 1 = +X, 2 = +Z, 3 = -X
Config.Dirs = {
	[0] = Vector3.new(0, 0, -1),
	[1] = Vector3.new(1, 0, 0),
	[2] = Vector3.new(0, 0, 1),
	[3] = Vector3.new(-1, 0, 0),
}

function Config.DirVector(d: number): Vector3
	return Config.Dirs[d % 4]
end

function Config.FormatTime(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	return string.format("%02d:%02d:%02d", seconds // 3600, (seconds // 60) % 60, seconds % 60)
end

return Config
