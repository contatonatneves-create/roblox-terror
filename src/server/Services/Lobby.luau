-- A Sala de Descanso (GDD v2, seção 12.4 e 6.1): lobby diegético.
-- Pegar uma fita na estante, colocar no videocassete e sentar no sofá para começar.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Build = require(script.Parent.Build)
local State = require(script.Parent.State)

local Lobby = {}
local M = Enum.Material
local W, D, HT = 32, 24, 10 -- largura (X), profundidade (Z), altura

local model = nil
local seats = {}
local tvText = nil
local vcrPrompt = nil
local onInsert = nil

local C = {
	Wall = Color3.fromRGB(196, 184, 150),
	WallLow = Color3.fromRGB(112, 108, 82),
	FloorA = Color3.fromRGB(184, 178, 160),
	FloorB = Color3.fromRGB(118, 112, 96),
	Ceiling = Color3.fromRGB(206, 200, 182),
	Wood = Color3.fromRGB(92, 62, 42),
	Sofa = Color3.fromRGB(122, 74, 52),
	Metal = Color3.fromRGB(128, 132, 128),
	Plastic = Color3.fromRGB(38, 36, 34),
	Stain = Color3.fromRGB(70, 56, 34),
}

function Lobby.SpawnCFrame()
	return CFrame.new(0, 3, 8) * CFrame.Angles(0, math.pi, 0)
end

function Lobby.Seats()
	return seats
end

function Lobby.SetTV(text)
	if tvText then
		tvText.Text = text
	end
end

function Lobby.OnInsert(fn)
	onInsert = fn
end

function Lobby.SetVcrEnabled(on)
	if vcrPrompt then
		vcrPrompt.Enabled = on
	end
end

local function wall(name, size, cf)
	-- reboco manchado em cima, lambri verde-oliva embaixo
	local up = Build.Part(name, Vector3.new(size.X, HT - 3.4, size.Z), cf * CFrame.new(0, 3.4 + (HT - 3.4) / 2, 0), C.Wall, M.Plaster, model)
	Build.Part(name .. "Baixo", Vector3.new(size.X + 0.1, 3.4, size.Z + 0.1), cf * CFrame.new(0, 1.7, 0), C.WallLow, M.SmoothPlastic, model)
	return up
end

local function build()
	model = Instance.new("Model")
	model.Name = "SalaDeDescanso"
	local rng = Random.new(1987)

	-- piso xadrez de linóleo
	for x = -W / 2 + 1, W / 2 - 1, 2 do
		for z = -D / 2 + 1, D / 2 - 1, 2 do
			local dark = ((x + z) / 2) % 2 == 0
			Build.Part("Piso", Vector3.new(2, 1, 2), CFrame.new(x, -0.5, z), Build.Vary(dark and C.FloorB or C.FloorA, rng, 0.03), M.SmoothPlastic, model, { shadow = false })
		end
	end
	Build.Part("Teto", Vector3.new(W + 2, 1, D + 2), CFrame.new(0, HT + 0.5, 0), C.Ceiling, M.SmoothPlastic, model)
	wall("ParedeN", Vector3.new(W + 2, HT, 1), CFrame.new(0, 0, -D / 2 - 0.5))
	wall("ParedeS", Vector3.new(W + 2, HT, 1), CFrame.new(0, 0, D / 2 + 0.5))
	wall("ParedeO", Vector3.new(1, HT, D + 2), CFrame.new(-W / 2 - 0.5, 0, 0))
	wall("ParedeL", Vector3.new(1, HT, D + 2), CFrame.new(W / 2 + 0.5, 0, 0))
	-- manchas de fumaça e umidade
	for _ = 1, 9 do
		local side = rng:NextInteger(1, 2)
		local x = rng:NextNumber(-W / 2 + 3, W / 2 - 3)
		local y = rng:NextNumber(5, HT - 1.5)
		local s = Vector3.new(rng:NextNumber(1.5, 4), rng:NextNumber(1, 3), 0.05)
		local z = side == 1 and (-D / 2 + 0.03) or (D / 2 - 0.03)
		Build.Deco("Mancha", s, CFrame.new(x, y, z), C.Stain, M.SmoothPlastic, model, { transp = 0.75, shadow = false })
	end

	-- luzes fluorescentes no teto (o cliente faz piscar)
	for _, x in ipairs({ -9, 0, 9 }) do
		for _, z in ipairs({ -6, 5 }) do
			local fixture = Build.Deco("Luminaria", Vector3.new(4.4, 0.2, 1.4), CFrame.new(x, HT - 0.12, z), Color3.fromRGB(236, 240, 220), M.Neon, model, { shadow = false })
			Build.Light(fixture, "PointLight", Color3.fromRGB(226, 236, 210), 22, 0.75)
			fixture:SetAttribute("Pisca", x == 9 and z == 5)
			CollectionService:AddTag(fixture, "LuzLobby")
		end
	end
	local hum = Build.Deco("Zumbido", Vector3.new(1, 1, 1), CFrame.new(0, HT - 1, 0), C.Ceiling, M.SmoothPlastic, model, { transp = 1 })
	Build.Sound(hum, Config.Sounds.Hum, { volume = 0.2, looped = true, maxDistance = 50, play = true })

	-- TV CRT sobre o rack, parede norte
	Build.Part("Rack", Vector3.new(7, 2.6, 2.6), CFrame.new(0, 1.3, -D / 2 + 1.6), C.Wood, M.Wood, model)
	Build.Part("TV", Vector3.new(5, 4, 3.6), CFrame.new(0, 4.6, -D / 2 + 1.9), C.Plastic, M.SmoothPlastic, model)
	local screen = Build.Deco("Tela", Vector3.new(4.1, 3.1, 0.1), CFrame.new(0, 4.65, -D / 2 + 3.78), Color3.fromRGB(16, 22, 18), M.SmoothPlastic, model)
	local _, t = Build.Text(screen, Enum.NormalId.Back, "", { font = Enum.Font.Code, color = Color3.fromRGB(130, 255, 160), light = 0, brightness = 2.5, bg = Color3.fromRGB(10, 20, 12), pad = 3, pps = 70 })
	tvText = t
	screen:SetAttribute("TV", true)
	Build.Deco("Antena", Vector3.new(0.12, 2.6, 0.12), CFrame.new(-0.8, 7.6, -D / 2 + 1.9) * CFrame.Angles(0, 0, math.rad(25)), C.Metal, M.Metal, model)
	Build.Deco("Antena", Vector3.new(0.12, 2.6, 0.12), CFrame.new(0.8, 7.6, -D / 2 + 1.9) * CFrame.Angles(0, 0, math.rad(-25)), C.Metal, M.Metal, model)
	-- videocassete na prateleira do rack
	local vcr = Build.Part("Videocassete", Vector3.new(3.2, 0.7, 2), CFrame.new(0, 1.9, -D / 2 + 2.7), Color3.fromRGB(26, 26, 28), M.SmoothPlastic, model)
	Build.Deco("Gaveta", Vector3.new(1.8, 0.2, 0.05), CFrame.new(-0.4, 1.95, -D / 2 + 3.72), Color3.fromRGB(10, 10, 10), M.SmoothPlastic, model)
	local led = Build.Deco("Relogio", Vector3.new(0.8, 0.25, 0.05), CFrame.new(1, 1.95, -D / 2 + 3.72), Color3.fromRGB(80, 255, 120), M.Neon, model, { shadow = false })
	Build.Text(led, Enum.NormalId.Back, "12:00", { font = Enum.Font.Arcade, color = Color3.fromRGB(80, 255, 120), light = 0, brightness = 3 })
	vcrPrompt = Build.Prompt(vcr, "PromptFita", "Colocar a fita", "Videocassete", { distance = 8, hold = 0.5 })
	vcrPrompt.Triggered:Connect(function(player)
		if onInsert then
			onInsert(player)
		end
	end)

	-- estante de fitas (parede oeste)
	Build.Part("Estante", Vector3.new(1.4, 7, 6), CFrame.new(-W / 2 + 0.9, 3.5, -4), C.Wood, M.Wood, model)
	for i, y in ipairs({ 1.6, 3.4, 5.2 }) do
		Build.Deco("Prateleira", Vector3.new(1.6, 0.2, 6), CFrame.new(-W / 2 + 1.7, y - 0.1, -4), C.Wood, M.Wood, model)
		for k = 0, 9 do
			local labelColor = ({ Color3.fromRGB(220, 210, 180), Color3.fromRGB(180, 60, 50), Color3.fromRGB(60, 90, 160) })[(k + i) % 3 + 1]
			Build.Deco("Fita", Vector3.new(1.2, 1.5, 0.45), CFrame.new(-W / 2 + 1.75, y + 0.75, -6.6 + k * 0.58), Color3.fromRGB(28, 28, 30), M.SmoothPlastic, model)
			Build.Deco("Lombada", Vector3.new(0.05, 1, 0.35), CFrame.new(-W / 2 + 2.38, y + 0.75, -6.6 + k * 0.58), labelColor, M.SmoothPlastic, model)
		end
	end
	local shelfPrompt = Build.Prompt(model:FindFirstChild("Estante"), "PromptPegarFita", "Pegar uma fita", "Fita de Treinamento nº 4", { distance = 8 })
	shelfPrompt.Triggered:Connect(function(player)
		State.GiveTape(player)
	end)

	-- sofá de 3 lugares + poltrona, virados para a TV
	local sofaZ = 1
	Build.Part("SofaBase", Vector3.new(10, 1.6, 3.4), CFrame.new(-1.5, 0.8, sofaZ), C.Sofa, M.Fabric, model)
	Build.Part("SofaEncosto", Vector3.new(10, 3.2, 1), CFrame.new(-1.5, 2.6, sofaZ + 1.6), C.Sofa, M.Fabric, model)
	for _, x in ipairs({ -6.9, 3.9 }) do
		Build.Part("SofaBraco", Vector3.new(0.9, 2.6, 3.4), CFrame.new(x, 1.3, sofaZ), C.Sofa, M.Fabric, model)
	end
	seats = {}
	for i, x in ipairs({ -4.6, -1.5, 1.6 }) do
		local seat = Instance.new("Seat")
		seat.Name = "Assento" .. i
		seat.Size = Vector3.new(2.8, 0.6, 2.6)
		seat.CFrame = CFrame.new(x, 1.9, sofaZ - 0.2)
		seat.Color = Color3.fromRGB(132, 82, 58)
		seat.Material = M.Fabric
		seat.Anchored = true
		seat.TopSurface = Enum.SurfaceType.Smooth
		seat.Parent = model
		table.insert(seats, seat)
	end
	-- poltrona
	Build.Part("PoltronaBase", Vector3.new(3.6, 1.6, 3.4), CFrame.new(8, 0.8, sofaZ - 1), C.Sofa, M.Fabric, model)
	Build.Part("PoltronaEncosto", Vector3.new(3.6, 3.2, 1), CFrame.new(8, 2.6, sofaZ + 0.6), C.Sofa, M.Fabric, model)
	local seat4 = Instance.new("Seat")
	seat4.Name = "Assento4"
	seat4.Size = Vector3.new(2.8, 0.6, 2.6)
	seat4.CFrame = CFrame.new(8, 1.9, sofaZ - 1.2)
	seat4.Color = Color3.fromRGB(132, 82, 58)
	seat4.Material = M.Fabric
	seat4.Anchored = true
	seat4.Parent = model
	table.insert(seats, seat4)
	-- mesinha de centro com controle remoto e cinzeiro
	Build.Part("Mesinha", Vector3.new(5, 0.3, 2.2), CFrame.new(-1, 1.6, -3.4), C.Wood, M.Wood, model)
	for _, x in ipairs({ -3.2, 1.2 }) do
		Build.Part("PeMesinha", Vector3.new(0.3, 1.5, 1.8), CFrame.new(x, 0.75, -3.4), C.Wood, M.Wood, model)
	end
	Build.Deco("Controle", Vector3.new(0.5, 0.2, 1.3), CFrame.new(0, 1.85, -3.4), Color3.fromRGB(30, 30, 30), M.SmoothPlastic, model)
	Build.Deco("Caneca", Vector3.new(0.6, 0.6, 0.6), CFrame.new(-2.4, 2.05, -3.2), Color3.fromRGB(220, 214, 196), M.SmoothPlastic, model)

	-- máquina de venda (loja da Etapa 7)
	Build.Part("MaquinaVenda", Vector3.new(3.4, 7, 3), CFrame.new(W / 2 - 1.8, 3.5, -6), Color3.fromRGB(140, 30, 30), M.SmoothPlastic, model)
	local glass = Build.Deco("Vitrine", Vector3.new(0.1, 4.2, 2.2), CFrame.new(W / 2 - 3.55, 4.4, -6.2), Color3.fromRGB(255, 236, 190), M.Neon, model, { transp = 0.35, shadow = false })
	Build.Text(glass, Enum.NormalId.Left, "AETHELGARD\nSNACKS\n\nEM BREVE", { font = Enum.Font.Arcade, color = Color3.fromRGB(70, 20, 20), light = 0 })
	-- terminal MS-DOS (Etapa 5)
	Build.Part("Escrivaninha", Vector3.new(4, 2.8, 2.4), CFrame.new(W / 2 - 2.2, 1.4, 6), C.Wood, M.Wood, model)
	Build.Part("Monitor", Vector3.new(2.2, 2, 2), CFrame.new(W / 2 - 2.4, 3.8, 6.2), Color3.fromRGB(196, 190, 170), M.SmoothPlastic, model)
	local crt = Build.Deco("TelaDOS", Vector3.new(0.1, 1.5, 1.7), CFrame.new(W / 2 - 3.55, 3.85, 6.2), Color3.fromRGB(8, 14, 8), M.SmoothPlastic, model)
	Build.Text(crt, Enum.NormalId.Left, "C:\\AETHEL> _", { font = Enum.Font.Code, color = Color3.fromRGB(110, 255, 140), light = 0, brightness = 2, alignX = Enum.TextXAlignment.Left, alignY = Enum.TextYAlignment.Top, pad = 2 })
	Build.Deco("Teclado", Vector3.new(0.9, 0.15, 1.8), CFrame.new(W / 2 - 3.6, 2.9, 6.2), Color3.fromRGB(190, 184, 164), M.SmoothPlastic, model)
	-- armários (parede sul)
	for i = 0, 4 do
		Build.Part("Armario", Vector3.new(1.9, 7, 1.6), CFrame.new(-W / 2 + 2 + i * 2, 3.5, D / 2 - 0.9), Color3.fromRGB(82, 102, 96), M.Metal, model)
		Build.Deco("Fresta", Vector3.new(1.2, 0.1, 0.05), CFrame.new(-W / 2 + 2 + i * 2, 6, D / 2 - 1.72), Color3.fromRGB(30, 34, 32), M.Metal, model)
	end
	-- cafeteira no balcão
	Build.Part("Balcao", Vector3.new(6, 3, 2.2), CFrame.new(8, 1.5, D / 2 - 1.2), Color3.fromRGB(150, 140, 120), M.SmoothPlastic, model)
	Build.Deco("Cafeteira", Vector3.new(1.2, 1.6, 1.1), CFrame.new(6.8, 3.8, D / 2 - 1.2), Color3.fromRGB(34, 34, 34), M.SmoothPlastic, model)
	Build.Deco("Jarra", Vector3.new(0.8, 0.8, 0.8), CFrame.new(6.8, 3.4, D / 2 - 1.9), Color3.fromRGB(60, 34, 20), M.Glass, model, { transp = 0.3 })
	-- relógio parado em 3:33
	local clock = Build.Deco("Relogio", Vector3.new(1.8, 1.8, 0.2), CFrame.new(-6, 7.8, -D / 2 + 0.12), Color3.fromRGB(236, 232, 214), M.SmoothPlastic, model)
	Build.Text(clock, Enum.NormalId.Back, "3:33", { font = Enum.Font.Antique, color = Color3.fromRGB(40, 30, 20) })
	-- quadro de avisos com o tutorial
	local board = Build.Part("Quadro", Vector3.new(7, 4.6, 0.3), CFrame.new(9, 5.6, -D / 2 + 0.2), Color3.fromRGB(160, 120, 80), M.Wood, model)
	Build.Text(board, Enum.NormalId.Back,
		"AVISO AOS FUNCIONÁRIOS\n\n1. Pegue a FITA Nº 4 na estante.\n2. Coloque no VIDEOCASSETE.\n3. Sentem no SOFÁ (até 4).\n\nNOS ANDARES:\n- Empurre o carrinho. Não corra.\n- Cumpra as tarefas do elevador.\n- LUZES ÂMBAR: pare, limpe, silêncio.",
		{ font = Enum.Font.Code, color = Color3.fromRGB(30, 22, 14), bg = Color3.fromRGB(236, 228, 204), alignX = Enum.TextXAlignment.Left, alignY = Enum.TextYAlignment.Top, pad = 3, pps = 70 })
	-- porta de saída trancada
	Build.Part("Porta", Vector3.new(4.4, 8, 0.4), CFrame.new(-8, 4, D / 2 + 0.05), Color3.fromRGB(110, 96, 70), M.Wood, model)
	local exitSign = Build.Deco("Saida", Vector3.new(2.4, 0.8, 0.2), CFrame.new(-8, 8.8, D / 2 - 0.2), Color3.fromRGB(200, 40, 30), M.Neon, model, { shadow = false })
	Build.Text(exitSign, Enum.NormalId.Front, "SAÍDA", { font = Enum.Font.Arcade, color = Color3.fromRGB(255, 230, 220), light = 0 })

	model.Parent = workspace
end

function Lobby.Init()
	local old = workspace:FindFirstChild("SalaDeDescanso")
	if old then
		old:Destroy()
	end
	local base = workspace:FindFirstChild("Baseplate")
	if base then
		base:Destroy()
	end
	build()
	-- ponto de nascimento dentro da sala
	local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
	if not spawn then
		spawn = Instance.new("SpawnLocation")
		spawn.Parent = workspace
	end
	spawn.Size = Vector3.new(6, 0.2, 4)
	spawn.CFrame = CFrame.new(0, 0.1, 8)
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	local decal = spawn:FindFirstChildOfClass("Decal")
	if decal then
		decal:Destroy()
	end
	Lobby.SetTV("SEM SINAL\n\nPEGUE A FITA Nº 4\nNA ESTANTE")
end

return Lobby
