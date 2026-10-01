-- Gerador e construtor de andares (GDD v2, seções 6.3, 6.4 e 8).
-- Cada andar é um caminho de células numa grade de 12 studs: elevador de chegada, corredores e curvas
-- com portas numeradas e o elevador de saída. Andares ficam longe uns dos outros no mundo.
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Build = require(script.Parent.Build)

local Floors = {}
local G = Config.Grid
local CELL, H, WALL = G.Cell, G.Height, G.Wall
local HALF = CELL / 2
local M = Enum.Material

local folder = nil
local floors = {}
local listeners = { TaskDone = {}, AllTasksDone = {} }

local function fire(name, ...)
	for _, fn in ipairs(listeners[name]) do
		task.spawn(fn, ...)
	end
end

function Floors.On(name, fn)
	table.insert(listeners[name], fn)
end

---------------------------------------------------------------- paleta
local C = {
	Carpet = Color3.fromRGB(104, 28, 34),
	CarpetBorder = Color3.fromRGB(150, 112, 52),
	Wallpaper = Color3.fromRGB(96, 110, 86),
	WallpaperDirty = Color3.fromRGB(84, 88, 70),
	Wainscot = Color3.fromRGB(72, 48, 34),
	Rail = Color3.fromRGB(122, 86, 56),
	Ceiling = Color3.fromRGB(196, 190, 172),
	Door = Color3.fromRGB(112, 70, 44),
	DoorFrame = Color3.fromRGB(58, 38, 26),
	Brass = Color3.fromRGB(182, 150, 82),
	Light = Color3.fromRGB(236, 240, 222),
	ElevWall = Color3.fromRGB(70, 50, 38),
	ElevFloor = Color3.fromRGB(86, 86, 82),
	Steel = Color3.fromRGB(150, 152, 150),
	Stain = Color3.fromRGB(58, 22, 18),
}

---------------------------------------------------------------- utilidades
local function dirVec(d)
	return Config.DirVector(d)
end

local function faceTowards(v)
	if v.X > 0.5 then
		return Enum.NormalId.Right
	elseif v.X < -0.5 then
		return Enum.NormalId.Left
	elseif v.Z > 0.5 then
		return Enum.NormalId.Back
	else
		return Enum.NormalId.Front
	end
end

local function key(x, z)
	return x .. "," .. z
end

---------------------------------------------------------------- geração do caminho
-- Devolve uma lista de células { X, Z, In, Out, Kind } sem sobreposição.
function Floors.Generate(floorNumber, seed)
	local rng = Random.new(seed)
	local n = math.clamp(rng:NextInteger(G.MinCells, G.MaxCells) + math.floor(floorNumber * G.CellsPerFloorBonus), G.MinCells, G.MaxCells + 6)
	for _ = 1, 80 do
		local occ = { [key(0, 0)] = true }
		local cells = { { X = 0, Z = 0, Kind = "ElevChegada", Out = 0 } }
		local x, z, dir = 0, 0, 0
		local straight = 0
		local ok = true
		for i = 1, n + 1 do
			local turn = nil
			if straight >= 2 and rng:NextNumber() < G.TurnChance then
				turn = (dir + (rng:NextNumber() < 0.5 and 1 or 3)) % 4
			end
			local tries = turn and { turn, dir } or { dir, (dir + 1) % 4, (dir + 3) % 4 }
			local chosen = nil
			for _, d in ipairs(tries) do
				local v = dirVec(d)
				local nx, nz = x + v.X, z + v.Z
				if not occ[key(nx, nz)] then
					-- evita encostar em células antigas (mantém o caminho legível)
					local touches = 0
					for s = 0, 3 do
						local w = dirVec(s)
						if occ[key(nx + w.X, nz + w.Z)] and not (nx + w.X == x and nz + w.Z == z) then
							touches += 1
						end
					end
					if touches == 0 then
						chosen = d
						break
					end
				end
			end
			if not chosen then
				ok = false
				break
			end
			cells[#cells].Out = chosen
			local v = dirVec(chosen)
			x, z = x + v.X, z + v.Z
			occ[key(x, z)] = true
			straight = chosen == dir and straight + 1 or 0
			dir = chosen
			table.insert(cells, { X = x, Z = z, In = chosen, Kind = i == n + 1 and "ElevSaida" or "Corredor" })
		end
		if ok then
			for _, c in ipairs(cells) do
				if c.Kind == "Corredor" then
					c.Kind = c.In == c.Out and "Reto" or "Curva"
				end
			end
			return cells
		end
	end
	error("Não consegui gerar o andar " .. floorNumber)
end

---------------------------------------------------------------- construção de peças
local function wallSegment(model, center, d, rng, dirty)
	local v = dirVec(d)
	local along = (v.X ~= 0) and Vector3.new(0, 0, 1) or Vector3.new(1, 0, 0)
	local function size(len, height, thick)
		if v.X ~= 0 then
			return Vector3.new(thick, height, len)
		end
		return Vector3.new(len, height, thick)
	end
	local base = center + v * (HALF - WALL / 2)
	local paper = dirty and C.WallpaperDirty or C.Wallpaper
	Build.Part("Parede", size(CELL, H - 3.6, WALL), CFrame.new(base + Vector3.new(0, 3.6 + (H - 3.6) / 2, 0)), Build.Vary(paper, rng, 0.03), M.Fabric, model)
	Build.Part("Lambri", size(CELL, 3.6, WALL + 0.2), CFrame.new(base + Vector3.new(0, 1.8, 0)), C.Wainscot, M.Wood, model)
	Build.Deco("Moldura", size(CELL, 0.25, WALL + 0.5), CFrame.new(base + Vector3.new(0, 3.7, 0)), C.Rail, M.Wood, model)
	Build.Deco("Sanca", size(CELL, 0.4, WALL + 0.5), CFrame.new(base + Vector3.new(0, H - 0.2, 0)), C.Ceiling, M.SmoothPlastic, model)
	return along
end

local function buildDoor(floor, model, center, d, number, rng)
	local v = dirVec(d)
	local along = (v.X ~= 0) and Vector3.new(0, 0, 1) or Vector3.new(1, 0, 0)
	local inward = -v
	local wallFace = center + v * (HALF - WALL)
	local function size(len, height, thick)
		if v.X ~= 0 then
			return Vector3.new(thick, height, len)
		end
		return Vector3.new(len, height, thick)
	end
	local doorModel = Instance.new("Model")
	doorModel.Name = "Porta" .. number
	doorModel:SetAttribute("Numero", number)
	local door = Build.Part("Folha", size(4.2, 8, 0.35), CFrame.new(wallFace + inward * 0.18 + Vector3.new(0, 4, 0)), C.Door, M.Wood, doorModel)
	-- frisos da porta
	for _, y in ipairs({ 2.2, 5.6 }) do
		Build.Deco("Friso", size(3, 2.4, 0.08), CFrame.new(wallFace + inward * 0.38 + Vector3.new(0, y, 0)), Color3.fromRGB(96, 60, 38), M.Wood, doorModel)
	end
	Build.Deco("Batente", size(0.4, 8.4, 0.5), CFrame.new(wallFace + inward * 0.25 + along * 2.3 + Vector3.new(0, 4.2, 0)), C.DoorFrame, M.Wood, doorModel)
	Build.Deco("Batente", size(0.4, 8.4, 0.5), CFrame.new(wallFace + inward * 0.25 - along * 2.3 + Vector3.new(0, 4.2, 0)), C.DoorFrame, M.Wood, doorModel)
	Build.Deco("Batente", size(5, 0.4, 0.5), CFrame.new(wallFace + inward * 0.25 + Vector3.new(0, 8.3, 0)), C.DoorFrame, M.Wood, doorModel)
	Build.Deco("Macaneta", Vector3.new(0.35, 0.35, 0.35), CFrame.new(wallFace + inward * 0.45 + along * 1.55 + Vector3.new(0, 3.6, 0)), C.Brass, M.Metal, doorModel, { shape = Enum.PartType.Ball })
	local plate = Build.Deco("Placa", size(1.5, 0.6, 0.08), CFrame.new(wallFace + inward * 0.4 + Vector3.new(0, 6.9, 0)), C.Brass, M.Metal, doorModel)
	Build.Text(plate, faceTowards(inward), tostring(number), { font = Enum.Font.Antique, color = Color3.fromRGB(40, 28, 16), pps = 60 })
	doorModel.PrimaryPart = door
	doorModel.Parent = model
	table.insert(floor.Doors, { Model = doorModel, Number = number, Part = door, Inward = inward })
	return doorModel
end

local function buildProp(floor, model, center, d, rng)
	local v = dirVec(d)
	local along = (v.X ~= 0) and Vector3.new(0, 0, 1) or Vector3.new(1, 0, 0)
	local pos = center + v * (HALF - WALL - 1.1) + along * rng:NextNumber(-3.5, 3.5)
	local kind = rng:NextInteger(1, 3)
	local p
	if kind == 1 then
		p = Build.Part("BaldeGelo", Vector3.new(1.4, 1.2, 1.2), CFrame.new(pos + Vector3.new(0, 0.75, 0)) * CFrame.Angles(0, 0, math.rad(90)), C.Steel, M.Metal, model, { anchored = false, shape = Enum.PartType.Cylinder, touch = true })
	elseif kind == 2 then
		p = Build.Part("Garrafa", Vector3.new(1.3, 0.5, 0.5), CFrame.new(pos + Vector3.new(0, 0.7, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(40, 90, 50), M.Glass, model, { anchored = false, shape = Enum.PartType.Cylinder, touch = true })
		p.Transparency = 0.2
	else
		p = Build.Part("Bandeja", Vector3.new(2, 0.2, 1.4), CFrame.new(pos + Vector3.new(0, 0.15, 0)), C.Steel, M.Metal, model, { anchored = false, touch = true })
		local cloche = Build.Part("Cloche", Vector3.new(1, 1.2, 1.2), CFrame.new(pos + Vector3.new(0, 0.6, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(190, 190, 186), M.Metal, model, { anchored = false, shape = Enum.PartType.Cylinder, touch = true })
		local w = Instance.new("WeldConstraint")
		w.Part0 = p
		w.Part1 = cloche
		w.Parent = p
		cloche:SetAttribute("Ruidoso", true)
		CollectionService:AddTag(cloche, "Ruidoso")
	end
	p:SetAttribute("Ruidoso", true)
	CollectionService:AddTag(p, "Ruidoso")
	return p
end

local function ceilingLight(floor, model, center, rng, flickery)
	local fixture = Build.Deco("Luminaria", Vector3.new(3.2, 0.15, 1.2), CFrame.new(center + Vector3.new(0, H - 0.1, 0)), C.Light, M.Neon, model, { shadow = false })
	local light = Build.Light(fixture, "PointLight", Color3.fromRGB(228, 234, 212), 18, 0.85)
	fixture:SetAttribute("Andar", floor.Number)
	if flickery then
		fixture:SetAttribute("Pisca", true)
	end
	CollectionService:AddTag(fixture, "LuzAndar")
	return fixture, light
end

---------------------------------------------------------------- elevador
local function buildElevator(floor, model, center, openDir, kind)
	local F = CFrame.lookAt(center, center + dirVec(openDir))
	local e = Instance.new("Model")
	e.Name = kind == "ElevChegada" and "ElevadorChegada" or "ElevadorSaida"
	local function part(name, size, localCF, color, mat, opts)
		return Build.Part(name, size, F * localCF, color, mat, e, opts)
	end
	local function deco(name, size, localCF, color, mat, opts)
		return Build.Deco(name, size, F * localCF, color, mat, e, opts)
	end
	part("Piso", Vector3.new(CELL, 1, CELL), CFrame.new(0, -0.5, 0), C.ElevFloor, M.DiamondPlate)
	part("Teto", Vector3.new(CELL, 1, CELL), CFrame.new(0, H + 0.5, 0), C.Ceiling, M.SmoothPlastic)
	part("Fundo", Vector3.new(CELL, H, 1), CFrame.new(0, H / 2, HALF - 0.5), C.ElevWall, M.Wood)
	part("Lado", Vector3.new(1, H, CELL), CFrame.new(-(HALF - 0.5), H / 2, 0), C.ElevWall, M.Wood)
	part("Lado", Vector3.new(1, H, CELL), CFrame.new(HALF - 0.5, H / 2, 0), C.ElevWall, M.Wood)
	part("Frente", Vector3.new(3, H, 1), CFrame.new(-4.5, H / 2, -(HALF - 0.5)), C.ElevWall, M.Wood)
	part("Frente", Vector3.new(3, H, 1), CFrame.new(4.5, H / 2, -(HALF - 0.5)), C.ElevWall, M.Wood)
	part("Verga", Vector3.new(6, H - 8, 1), CFrame.new(0, 8 + (H - 8) / 2, -(HALF - 0.5)), C.ElevWall, M.Wood)
	-- espelhos de latão por dentro
	for _, x in ipairs({ -HALF + 1.1, HALF - 1.1 }) do
		deco("Painel", Vector3.new(0.12, 5, 7), CFrame.new(x, 4.5, 0.5), C.Brass, M.Metal)
	end
	deco("Corrimao", Vector3.new(10, 0.2, 0.25), CFrame.new(0, 3.3, HALF - 1.2), C.Brass, M.Metal)
	-- portas de correr
	local left = part("PortaE", Vector3.new(3, 8, 0.4), CFrame.new(-1.5, 4, -(HALF - 0.5)), C.Brass, M.Metal)
	local right = part("PortaD", Vector3.new(3, 8, 0.4), CFrame.new(1.5, 4, -(HALF - 0.5)), C.Brass, M.Metal)
	left:SetAttribute("Fechada", left.CFrame)
	right:SetAttribute("Fechada", right.CFrame)
	left:SetAttribute("Aberta", F * CFrame.new(-4.3, 4, -(HALF - 0.3)))
	right:SetAttribute("Aberta", F * CFrame.new(4.3, 4, -(HALF - 0.3)))
	-- mostrador do andar (lado de fora)
	local dial = deco("Mostrador", Vector3.new(2.4, 1, 0.2), CFrame.new(0, 9.1, -(HALF + 0.1)), Color3.fromRGB(20, 18, 14), M.SmoothPlastic)
	Build.Text(dial, Enum.NormalId.Front, string.format("%02d", floor.Number), { font = Enum.Font.Arcade, color = Color3.fromRGB(255, 120, 40), light = 0, brightness = 2 })
	-- TV CRT no fundo, de frente para a porta
	deco("TV", Vector3.new(4.2, 3.2, 1.8), CFrame.new(0, 7.4, HALF - 1.6), Color3.fromRGB(34, 32, 30), M.SmoothPlastic)
	local screen = deco("Tela", Vector3.new(3.5, 2.5, 0.1), CFrame.new(0, 7.45, HALF - 2.55), Color3.fromRGB(12, 20, 14), M.SmoothPlastic)
	local _, tvText = Build.Text(screen, Enum.NormalId.Front, "", { font = Enum.Font.Code, color = Color3.fromRGB(120, 255, 150), light = 0, brightness = 2.5, bg = Color3.fromRGB(8, 18, 10), pad = 3, pps = 80 })
	tvText.TextScaled = true
	screen:SetAttribute("TV", true)
	-- painel de botões
	local panel = deco("Botoeira", Vector3.new(0.2, 2.2, 1), CFrame.new(HALF - 1.1, 4.2, -(HALF - 1.8)), C.Brass, M.Metal)
	for i = 0, 3 do
		deco("Botao", Vector3.new(0.25, 0.3, 0.3), CFrame.new(HALF - 1.25, 3.4 + i * 0.5, -(HALF - 1.8)), Color3.fromRGB(240, 220, 160), M.Neon, { shadow = false })
	end
	-- luz
	local lamp = deco("Luz", Vector3.new(4, 0.15, 4), CFrame.new(0, H - 0.08, 0), Color3.fromRGB(255, 236, 200), M.Neon, { shadow = false })
	Build.Light(lamp, "PointLight", Color3.fromRGB(255, 230, 190), 16, 0.9)
	local speaker = deco("AltoFalante", Vector3.new(1, 0.2, 1), CFrame.new(0, H - 0.1, 2.5), Color3.fromRGB(40, 40, 40), M.Metal)
	e.Parent = model
	return {
		Model = e,
		Frame = F,
		Center = center,
		DoorL = left,
		DoorR = right,
		Screen = screen,
		TVText = tvText,
		Panel = panel,
		Speaker = speaker,
		Open = false,
		Kind = kind,
	}
end

function Floors.SetDoors(elev, open, instant)
	if elev.Open == open and not instant then
		return
	end
	elev.Open = open
	for _, door in ipairs({ elev.DoorL, elev.DoorR }) do
		local target = door:GetAttribute(open and "Aberta" or "Fechada")
		if instant then
			door.CFrame = target
		else
			TweenService:Create(door, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { CFrame = target }):Play()
		end
		door.CanCollide = not open
	end
	local s = Build.Sound(elev.Speaker, Config.Sounds.ElevatorDoors, { volume = 0.5, maxDistance = 50 })
	s:Play()
	game:GetService("Debris"):AddItem(s, 5)
end

function Floors.Ding(elev)
	local s = Build.Sound(elev.Speaker, Config.Sounds.Ding, { volume = 0.7, maxDistance = 70 })
	s:Play()
	game:GetService("Debris"):AddItem(s, 4)
end

function Floors.SetTV(elev, text)
	if elev and elev.TVText then
		elev.TVText.Text = text
	end
end

-- Está dentro do elevador? (posição no mundo)
function Floors.IsInside(elev, pos)
	local p = elev.Frame:PointToObjectSpace(pos)
	return math.abs(p.X) < HALF - 0.6 and p.Z > -(HALF - 0.2) and p.Z < HALF - 0.6 and p.Y > -2 and p.Y < H
end

---------------------------------------------------------------- tarefas
local function newTask(floor, kind, data)
	local t = { Kind = kind, Done = false, Floor = floor }
	for k, v in pairs(data) do
		t[k] = v
	end
	table.insert(floor.Tasks, t)
	return t
end

local function completeTask(floor, t)
	if t.Done then
		return
	end
	t.Done = true
	fire("TaskDone", floor, t)
	for _, other in ipairs(floor.Tasks) do
		if not other.Done then
			return
		end
	end
	floor.AllDone = true
	fire("AllTasksDone", floor)
end

function Floors.TaskText(floor)
	local lines = {}
	for _, t in ipairs(floor.Tasks) do
		local mark = t.Done and "[X] " or "[ ] "
		if t.Kind == "Entrega" then
			table.insert(lines, mark .. "ENTREGAR TOALHAS NO QUARTO " .. t.Number)
		elseif t.Kind == "Limpeza" then
			local left = Config.Tasks.CleanStrokes - (t.Strokes or 0)
			table.insert(lines, mark .. "LIMPAR A MANCHA NO CARPETE" .. (t.Done and "" or (" (" .. left .. ")")))
		elseif t.Kind == "Conserto" then
			table.insert(lines, mark .. "CONSERTAR O FIO EXPOSTO (FITA ISOLANTE)")
		elseif t.Kind == "Servir" then
			table.insert(lines, mark .. "SERVIR O QUARTO " .. t.Number .. " (BANDEJA NA MARCA)")
		end
	end
	if floor.AllDone then
		table.insert(lines, floor.Number >= Config.Run.Floors and ">> BATA O PONTO NO ELEVADOR" or ">> ELEVADOR LIBERADO")
	end
	return table.concat(lines, "\n")
end

function Floors.TaskSpeech(floor)
	local parts = { "Andar " .. floor.Number .. "." }
	for _, t in ipairs(floor.Tasks) do
		if t.Kind == "Entrega" then
			table.insert(parts, "Entregue toalhas no quarto " .. t.Number .. ".")
		elseif t.Kind == "Limpeza" then
			table.insert(parts, "Limpe a mancha no carpete.")
		elseif t.Kind == "Conserto" then
			table.insert(parts, "Conserte o fio exposto.")
		end
	end
	return table.concat(parts, " ")
end

-- Entrega de toalhas: chamado pelo prompt da porta
local function setupDelivery(floor, t, rng)
	local door = t.Door
	local pp = Build.Prompt(door.Part, "PromptEntrega", "Entregar toalhas", "Quarto " .. t.Number, { distance = Config.Tasks.DeliverRange, hold = 0.6 })
	pp.Triggered:Connect(function(player)
		if t.Done then
			return
		end
		local character = player.Character
		local towel = character and (character:FindFirstChild("Toalhas") or player.Backpack:FindFirstChild("Toalhas"))
		if not towel then
			Floors.Notify(player, "Pegue toalhas no carrinho primeiro.")
			return
		end
		towel:Destroy()
		pp.Enabled = false
		local knock = Build.Sound(door.Part, Config.Sounds.Bump, { volume = 0.4, speed = 1.6 })
		knock:Play()
		completeTask(floor, t)
	end)
end

-- Tarefas criadas por eventos (ex.: o Hóspede pedindo serviço de quarto)
function Floors.AddTask(floor, kind, data)
	local t = newTask(floor, kind, data)
	floor.AllDone = false
	fire("TaskDone", floor, nil)
	return t
end

Floors.CompleteTask = completeTask

-- Algum fio ainda vivo neste andar?
function Floors.HasLiveWire(floor)
	for _, t in ipairs(floor.Tasks) do
		if t.Kind == "Conserto" and t.Live then
			return true
		end
	end
	return false
end

function Floors.OnSweep(player, pos)
	for _, floor in pairs(floors) do
		for _, t in ipairs(floor.Tasks) do
			if t.Kind == "Limpeza" and not t.Done and t.Stain and t.Stain.Parent then
				if (t.Stain.Position - pos).Magnitude <= Config.Tasks.CleanRange then
					t.Strokes = (t.Strokes or 0) + 1
					t.Stain.Transparency = math.clamp(t.Strokes / Config.Tasks.CleanStrokes, 0, 1) * 0.9
					if t.Strokes >= Config.Tasks.CleanStrokes then
						t.Stain:Destroy()
						completeTask(floor, t)
					else
						fire("TaskDone", floor, nil) -- só atualiza o texto
					end
					return true
				end
			end
		end
	end
	return false
end

Floors.Notify = function() end -- substituído pelo Tape
Floors.Kill = function() end -- substituído pelo Tape
Floors.IsActive = function()
	return false
end

---------------------------------------------------------------- conserto: fio exposto e poça (seção 6.4)
local R = Config.Repair

local function buildRepair(floor, model, spot, rng)
	local v = dirVec(spot.Side)
	local inward = -v
	local wallFace = spot.Center + v * (HALF - WALL)
	local along = (v.X ~= 0) and Vector3.new(0, 0, 1) or Vector3.new(1, 0, 0)
	local offset = along * rng:NextNumber(-2, 2)
	local function size(len, height, thick)
		if v.X ~= 0 then
			return Vector3.new(thick, height, len)
		end
		return Vector3.new(len, height, thick)
	end
	local rep = Instance.new("Model")
	rep.Name = "FioExposto"
	-- caixa de força arrebentada e o fio pendurado
	Build.Part("Caixa", size(1.4, 1.6, 0.5), CFrame.new(wallFace + offset + inward * 0.25 + Vector3.new(0, 6.6, 0)), Color3.fromRGB(120, 124, 118), M.Metal, rep)
	Build.Deco("Tampa", size(1.2, 0.2, 0.1), CFrame.new(wallFace + offset + inward * 0.55 + Vector3.new(0, 5.9, 0)) * CFrame.Angles(0.5, 0, 0.3), Color3.fromRGB(96, 100, 94), M.Metal, rep)
	local top = wallFace + offset + inward * 0.6 + Vector3.new(0, 6, 0)
	local tip = wallFace + offset + inward * 1.1 + Vector3.new(0, 1.6, 0)
	local mid = (top + tip) / 2
	local wire = Build.Part("Fio", Vector3.new(0.2, (top - tip).Magnitude, 0.2), CFrame.lookAt(mid, tip) * CFrame.Angles(math.rad(90), 0, 0), Color3.fromRGB(20, 20, 20), M.Rubber, rep, { collide = false })
	local tipPart = Build.Deco("Ponta", Vector3.new(0.3, 0.3, 0.3), CFrame.new(tip), Color3.fromRGB(190, 120, 60), M.Metal, rep)
	local sparks = Instance.new("ParticleEmitter")
	sparks.Name = "Faiscas"
	sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparks.Color = ColorSequence.new(Color3.fromRGB(255, 240, 170), Color3.fromRGB(255, 150, 40))
	sparks.LightEmission = 1
	sparks.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
	sparks.Brightness = 3
	sparks.Lifetime = NumberRange.new(0.15, 0.45)
	sparks.Speed = NumberRange.new(5, 12)
	sparks.SpreadAngle = Vector2.new(70, 70)
	sparks.Acceleration = Vector3.new(0, -35, 0)
	sparks.Rate = 35
	sparks.Parent = tipPart
	local glow = Build.Light(tipPart, "PointLight", Color3.fromRGB(255, 190, 110), 9, 1.2)
	glow.Name = "Brilho"
	tipPart:SetAttribute("Pisca", true)
	local buzz = Build.Sound(tipPart, Config.Sounds.Static, { name = "Zumbido", volume = 0.25, looped = true, maxDistance = 35, speed = 1.6, play = true })
	-- poça de água encostada na parede
	local puddleCenter = wallFace + offset + inward * R.PuddleFromWall
	local puddle = Build.Part("Poca", Vector3.new(0.06, R.PuddleRadius * 2, R.PuddleRadius * 2), CFrame.new(puddleCenter + Vector3.new(0, 0.04, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(16, 24, 30), M.SmoothPlastic, rep, { collide = false, shape = Enum.PartType.Cylinder })
	puddle.Transparency = 0.12
	puddle.Reflectance = 0.45
	puddle:SetAttribute("Agua", true)
	rep.Parent = model
	return { Model = rep, Wire = wire, Tip = tipPart, Sparks = sparks, Glow = glow, Buzz = buzz, Puddle = puddle, PuddleCenter = puddleCenter }
end

---------------------------------------------------------------- construção do andar
function Floors.Build(n, seed)
	if floors[n] then
		return floors[n]
	end
	local rng = Random.new(seed)
	local cells = Floors.Generate(n, seed)
	local origin = Config.FloorOrigin(n)
	local model = Instance.new("Model")
	model.Name = "Andar" .. n
	local floor = { Number = n, Model = model, Cells = cells, Doors = {}, Tasks = {}, Path = {}, Origin = origin, AllDone = false, Corridor = {} }
	local phase = Config.PhaseOf(n)
	local dirty = phase.Name ~= "INTEGRACAO"
	local doorCount = 0
	local freeWalls = {}

	for i, c in ipairs(cells) do
		local center = origin + Vector3.new(c.X * CELL, 0, c.Z * CELL)
		c.Center = center
		if c.Kind == "ElevChegada" then
			floor.Start = buildElevator(floor, model, center, c.Out, c.Kind)
			table.insert(floor.Path, center + dirVec(c.Out) * (HALF - 0.5))
		elseif c.Kind == "ElevSaida" then
			floor.End = buildElevator(floor, model, center, (c.In + 2) % 4, c.Kind)
			table.insert(floor.Path, center - dirVec(c.In) * (HALF - 0.5))
		else
			table.insert(floor.Corridor, c)
			table.insert(floor.Path, center)
			local cellModel = Instance.new("Model")
			cellModel.Name = "Celula" .. i
			Build.Part("Carpete", Vector3.new(CELL, 1, CELL), CFrame.new(center - Vector3.new(0, 0.5, 0)), Build.Vary(C.Carpet, rng, 0.02), M.Fabric, cellModel)
			Build.Part("Forro", Vector3.new(CELL, 1, CELL), CFrame.new(center + Vector3.new(0, H + 0.5, 0)), C.Ceiling, M.SmoothPlastic, cellModel)
			local open = { [(c.In + 2) % 4] = true, [c.Out] = true }
			for s = 0, 3 do
				if not open[s] then
					wallSegment(cellModel, center, s, rng, dirty)
					-- faixa dourada do carpete junto à parede
					local v = dirVec(s)
					local sz = v.X ~= 0 and Vector3.new(0.6, 0.06, CELL) or Vector3.new(CELL, 0.06, 0.6)
					Build.Deco("Faixa", sz, CFrame.new(center + v * (HALF - WALL - 0.6) + Vector3.new(0, 0.03, 0)), C.CarpetBorder, M.Fabric, cellModel)
					if c.Kind == "Reto" and rng:NextNumber() < G.DoorChance then
						doorCount += 1
						buildDoor(floor, cellModel, center, s, n * 100 + doorCount, rng)
					else
						table.insert(freeWalls, { Center = center, Side = s, Index = i, Model = cellModel })
						if rng:NextNumber() < G.PropChance then
							buildProp(floor, cellModel, center, s, rng)
						end
					end
				end
			end
			ceilingLight(floor, cellModel, center, rng, rng:NextNumber() < (dirty and 0.45 or 0.15))
			if i % 3 == 0 then
				local hum = Build.Deco("Zumbido", Vector3.new(0.5, 0.5, 0.5), CFrame.new(center + Vector3.new(0, H - 0.5, 0)), C.Ceiling, M.SmoothPlastic, cellModel, { transp = 1 })
				Build.Sound(hum, Config.Sounds.Hum, { volume = 0.12, looped = true, maxDistance = 30, play = true })
			end
			cellModel.Parent = model
		end
	end

	-- tarefas
	if #floor.Doors > 0 then
		-- entrega numa das portas mais longe do começo
		local idx = rng:NextInteger(math.max(1, math.floor(#floor.Doors * 0.4)), #floor.Doors)
		local door = floor.Doors[idx]
		local t = newTask(floor, "Entrega", { Door = door, Number = door.Number })
		setupDelivery(floor, t, rng)
	end
	if #floor.Doors == 0 or n >= Config.Tasks.SecondTaskFromFloor then
		local c = floor.Corridor[rng:NextInteger(math.max(1, math.floor(#floor.Corridor * 0.3)), #floor.Corridor)]
		local stain = Build.Deco("Mancha", Vector3.new(0.06, 3.4, 4.2), CFrame.new(c.Center + Vector3.new(rng:NextNumber(-2, 2), 0.04, rng:NextNumber(-2, 2))) * CFrame.Angles(0, rng:NextNumber(0, 6), math.rad(90)), C.Stain, M.SmoothPlastic, model, { shape = Enum.PartType.Cylinder })
		stain.Size = Vector3.new(0.06, 3.4, 3.4)
		newTask(floor, "Limpeza", { Stain = stain })
	end
	if n >= R.FromFloor and #freeWalls > 0 and rng:NextNumber() < R.Chance then
		local lo = math.max(1, math.floor(#freeWalls * 0.25))
		local spot = freeWalls[rng:NextInteger(lo, #freeWalls)]
		local parts = buildRepair(floor, spot.Model, spot, rng)
		local t = newTask(floor, "Conserto", parts)
		t.Live = true
		local pp = Build.Prompt(parts.Wire, "PromptConserto", "Consertar fio", "Fio exposto", { distance = 9, hold = R.Hold })
		pp.Triggered:Connect(function(player)
			if t.Done or not Floors.IsActive(player) then
				return
			end
			local character = player.Character
			local tape = character and (character:FindFirstChild("FitaIsolante") or player.Backpack:FindFirstChild("FitaIsolante"))
			if not tape then
				Floors.Notify(player, "Pegue fita isolante no carrinho.")
				return
			end
			tape:Destroy()
			pp.Enabled = false
			t.Live = false
			parts.Sparks.Enabled = false
			parts.Glow.Enabled = false
			parts.Buzz:Stop()
			parts.Tip:SetAttribute("Pisca", nil)
			Build.Deco("Fita", Vector3.new(0.34, 0.6, 0.34), CFrame.new(parts.Tip.Position + Vector3.new(0, 0.2, 0)), Color3.fromRGB(28, 28, 30), M.Plastic, parts.Model)
			completeTask(floor, t)
		end)
	end

	model.Parent = folder
	floors[n] = floor
	return floor
end

function Floors.Get(n)
	return floors[n]
end

function Floors.All()
	return floors
end

function Floors.Destroy(n)
	local f = floors[n]
	if f then
		f.Model:Destroy()
		floors[n] = nil
	end
end

function Floors.DestroyAll()
	for n in pairs(floors) do
		Floors.Destroy(n)
	end
end

-- Em qual andar está esta posição?
function Floors.FloorAt(pos)
	for n, f in pairs(floors) do
		local o = f.Origin
		if math.abs(pos.X - o.X) < Config.Run.FloorSpacing / 2 and math.abs(pos.Z - o.Z) < Config.Run.FloorSpacing then
			return n, f
		end
	end
	return nil
end

local function shockCheck()
	for _, floor in pairs(floors) do
		for _, t in ipairs(floor.Tasks) do
			if t.Kind == "Conserto" and t.Live then
				for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
					local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
					if root and Floors.IsActive(player) then
						local d = Vector3.new(root.Position.X - t.PuddleCenter.X, 0, root.Position.Z - t.PuddleCenter.Z).Magnitude
						if d <= R.PuddleRadius - 0.4 and math.abs(root.Position.Y - t.PuddleCenter.Y) < 6 then
							t.Sparks:Emit(40)
							Floors.Kill(player, "Eletrocutado. Você pisou na água perto do fio.")
						end
					end
				end
			end
		end
	end
end

function Floors.Init()
	folder = workspace:FindFirstChild("Andares") or Instance.new("Folder")
	folder.Name = "Andares"
	-- o place pode ter andares de prévia montados no modo Edit; no jogo eles são gerados de novo
	folder:ClearAllChildren()
	folder.Parent = workspace
	task.spawn(function()
		while true do
			task.wait(0.2)
			local ok, err = pcall(shockCheck)
			if not ok then
				warn("[Floors] " .. tostring(err))
			end
		end
	end)
end

return Floors
