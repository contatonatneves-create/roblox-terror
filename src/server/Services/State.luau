-- Estado de cada jogador: na fita ou não, vivo, modo de andar, empurrando, escondido, ferramentas e avisos.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local State = {}
local data = {}
local remotes = nil
local sweepHandlers = {}

local function get(player)
	local d = data[player]
	if not d then
		d = { Mode = "Andar", Pushing = false, PushSpeed = Config.Move.PushOne, Hidden = false, Covered = false, LastSweep = -100, InRun = false, Alive = true, Effects = {} }
		data[player] = d
	end
	return d
end
State.Get = get

local function humanoid(player)
	local c = player.Character
	return c and c:FindFirstChildOfClass("Humanoid")
end

function State.ApplySpeed(player)
	local d = get(player)
	local hum = humanoid(player)
	if not hum then
		return
	end
	if d.Hidden then
		hum.WalkSpeed = 0
	elseif d.Pushing then
		hum.WalkSpeed = d.PushSpeed
	elseif d.Covered then
		hum.WalkSpeed = Config.Move.Careful
	elseif d.Mode == "Correr" then
		hum.WalkSpeed = Config.Move.Run
	elseif d.Mode == "Cuidado" then
		hum.WalkSpeed = Config.Move.Careful
	else
		hum.WalkSpeed = Config.Move.Walk
	end
	hum.UseJumpPower = false
	hum.JumpHeight = (d.Pushing or d.Hidden or d.InRun) and 0 or 4
end

-- Olhos cobertos (Instrutor): anda devagar e o cliente escurece a tela
function State.SetCovered(player, covered)
	local d = get(player)
	if d.Covered == covered then
		return
	end
	d.Covered = covered
	player:SetAttribute("OlhosCobertos", covered)
	State.ApplySpeed(player)
end

function State.IsCovered(player)
	local d = data[player]
	return d ~= nil and d.Covered
end

-- Efeitos temporários vistos pelo cliente e pelo Ruído (ex.: Cego, PassosPesados do Falso Colega)
function State.SetEffect(player, name, seconds)
	local d = get(player)
	local token = {}
	d.Effects[name] = token
	player:SetAttribute(name, true)
	task.delay(seconds, function()
		if d.Effects[name] == token then
			d.Effects[name] = nil
			player:SetAttribute(name, nil)
		end
	end)
end

function State.ClearEffects(player)
	local d = get(player)
	for name in pairs(d.Effects) do
		player:SetAttribute(name, nil)
	end
	d.Effects = {}
	State.SetCovered(player, false)
end

function State.SetPushing(player, pushing, speed)
	local d = get(player)
	d.Pushing = pushing
	if speed then
		d.PushSpeed = speed
	end
	player:SetAttribute("Empurrando", pushing)
	State.ApplySpeed(player)
end

function State.SetHidden(player, hidden)
	local d = get(player)
	d.Hidden = hidden
	player:SetAttribute("Escondido", hidden)
	State.ApplySpeed(player)
end

function State.SetInRun(player, inRun)
	local d = get(player)
	d.InRun = inRun
	d.Alive = inRun
	d.Mode = "Andar"
	if not inRun then
		State.ClearEffects(player)
	end
	player:SetAttribute("NaFita", inRun)
	player:SetAttribute("Vivo", inRun)
	State.ApplySpeed(player)
end

function State.SetAlive(player, alive)
	local d = get(player)
	d.Alive = alive
	player:SetAttribute("Vivo", alive)
	if not alive then
		State.ClearEffects(player)
	end
end

function State.IsActive(player)
	local d = data[player]
	return d ~= nil and d.InRun and d.Alive and player.Parent ~= nil
end

function State.CanAct(player)
	if not State.IsActive(player) then
		return false
	end
	local hum = humanoid(player)
	return hum ~= nil and hum.Health > 0
end

function State.IsCleaning(player)
	local d = data[player]
	if not d then
		return false
	end
	local c = player.Character
	local broom = c and c:FindFirstChild("Vassoura")
	return broom ~= nil and os.clock() - d.LastSweep <= Config.Maid.CleanWindow
end

function State.Notify(player, text)
	if remotes then
		remotes.Aviso:FireClient(player, text)
	end
end

function State.NotifyAll(text, filter)
	for _, p in ipairs(Players:GetPlayers()) do
		if not filter or filter(p) then
			State.Notify(p, text)
		end
	end
end

function State.OnSweep(fn)
	table.insert(sweepHandlers, fn)
end

---------------------------------------------------------------- ferramentas
local function newTool(name, tip)
	local tool = Instance.new("Tool")
	tool.Name = name
	tool.ToolTip = tip
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	return tool
end

local function handlePart(tool, size, color, material)
	local h = Instance.new("Part")
	h.Name = "Handle"
	h.Size = size
	h.Color = color
	h.Material = material
	h.CanCollide = false
	h.Massless = true
	h.TopSurface = Enum.SurfaceType.Smooth
	h.BottomSurface = Enum.SurfaceType.Smooth
	h.Parent = tool
	return h
end

local function attachPart(tool, handle, name, size, offset, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material
	p.CanCollide = false
	p.Massless = true
	p.CFrame = handle.CFrame * offset
	local w = Instance.new("WeldConstraint")
	w.Part0 = handle
	w.Part1 = p
	w.Parent = p
	p.Parent = tool
	return p
end

State.NewTool = newTool
State.HandlePart = handlePart
State.AttachPart = attachPart

local function hasAny(player, name)
	local c = player.Character
	return player.Backpack:FindFirstChild(name) ~= nil or (c ~= nil and c:FindFirstChild(name) ~= nil)
end

-- Entrega a ferramenta ao jogador e já equipa
function State.Equip(player, tool)
	tool.Parent = player.Backpack
	local hum = humanoid(player)
	if hum then
		hum:EquipTool(tool)
	end
	return tool
end

-- Bandeja do serviço de quarto (Hóspede do 302)
function State.GiveTray(player)
	if hasAny(player, "Bandeja") then
		State.Notify(player, "Você já está com uma bandeja.")
		return
	end
	local tool = newTool("Bandeja", "Deixe na marca do carpete")
	local handle = handlePart(tool, Vector3.new(2, 0.15, 1.4), Color3.fromRGB(170, 172, 168), Enum.Material.Metal)
	local cloche = attachPart(tool, handle, "Cloche", Vector3.new(0.9, 1.2, 1.2), CFrame.new(0, 0.5, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(200, 200, 196), Enum.Material.Metal)
	cloche.Shape = Enum.PartType.Cylinder
	tool.GripPos = Vector3.new(0, 0, 0.4)
	State.Equip(player, tool)
end

-- Fita isolante (Conserto)
function State.GiveDuctTape(player)
	if hasAny(player, "FitaIsolante") then
		State.Notify(player, "Você já está com fita isolante.")
		return
	end
	local tool = newTool("FitaIsolante", "Use no fio exposto")
	local handle = handlePart(tool, Vector3.new(0.4, 0.9, 0.9), Color3.fromRGB(28, 28, 30), Enum.Material.Plastic)
	handle.Shape = Enum.PartType.Cylinder
	State.Equip(player, tool)
end

function State.GiveBroom(player)
	if player.Backpack:FindFirstChild("Vassoura") or (player.Character and player.Character:FindFirstChild("Vassoura")) then
		return
	end
	local tool = newTool("Vassoura", "Clique para limpar")
	local handle = handlePart(tool, Vector3.new(0.22, 4.6, 0.22), Color3.fromRGB(150, 108, 66), Enum.Material.Wood)
	attachPart(tool, handle, "Cerdas", Vector3.new(1.5, 0.8, 0.45), CFrame.new(0, -2.6, 0), Color3.fromRGB(196, 168, 92), Enum.Material.Fabric)
	attachPart(tool, handle, "Amarra", Vector3.new(1.2, 0.3, 0.5), CFrame.new(0, -2.1, 0), Color3.fromRGB(140, 40, 36), Enum.Material.Fabric)
	tool.GripPos = Vector3.new(0, 0.6, 0)
	tool.GripForward = Vector3.new(0, 0, -1)
	tool.GripUp = Vector3.new(0, 1, 0)
	local sound = Instance.new("Sound")
	sound.Name = "Varrer"
	sound.SoundId = Config.Sounds.Broom
	sound.Volume = 0.35
	sound.RollOffMaxDistance = 30
	sound.Parent = handle
	local dust = Instance.new("ParticleEmitter")
	dust.Name = "Poeira"
	dust.Enabled = false
	dust.Rate = 0
	dust.Lifetime = NumberRange.new(0.6, 1.1)
	dust.Speed = NumberRange.new(1, 3)
	dust.SpreadAngle = Vector2.new(60, 60)
	dust.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1.2) })
	dust.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1) })
	dust.Color = ColorSequence.new(Color3.fromRGB(200, 190, 170))
	dust.Parent = tool:FindFirstChild("Cerdas")
	tool.Activated:Connect(function()
		local d = get(player)
		if os.clock() - d.LastSweep < 0.35 then
			return
		end
		d.LastSweep = os.clock()
		sound:Play()
		dust:Emit(6)
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root then
			for _, fn in ipairs(sweepHandlers) do
				task.spawn(fn, player, root.Position)
			end
		end
	end)
	tool.Parent = player.Backpack
end

function State.GiveTowels(player)
	local c = player.Character
	if player.Backpack:FindFirstChild("Toalhas") or (c and c:FindFirstChild("Toalhas")) then
		State.Notify(player, "Você já está com toalhas.")
		return
	end
	local tool = newTool("Toalhas", "Entregue na porta do quarto")
	local handle = handlePart(tool, Vector3.new(1.4, 0.7, 1), Color3.fromRGB(236, 232, 220), Enum.Material.Fabric)
	attachPart(tool, handle, "Dobra", Vector3.new(1.3, 0.25, 0.9), CFrame.new(0, 0.48, 0), Color3.fromRGB(224, 220, 206), Enum.Material.Fabric)
	tool.GripPos = Vector3.new(0, 0, 0.2)
	tool.Parent = player.Backpack
	local hum = humanoid(player)
	if hum then
		hum:EquipTool(tool)
	end
end

function State.GiveTape(player)
	local c = player.Character
	if player.Backpack:FindFirstChild("FitaVHS") or (c and c:FindFirstChild("FitaVHS")) then
		return
	end
	local tool = newTool("FitaVHS", "Coloque no videocassete")
	local handle = handlePart(tool, Vector3.new(1.5, 0.3, 0.9), Color3.fromRGB(24, 24, 26), Enum.Material.SmoothPlastic)
	attachPart(tool, handle, "Etiqueta", Vector3.new(1.1, 0.32, 0.5), CFrame.new(0, 0.01, -0.1), Color3.fromRGB(230, 222, 196), Enum.Material.SmoothPlastic)
	tool.Parent = player.Backpack
	local hum = humanoid(player)
	if hum then
		hum:EquipTool(tool)
	end
end

function State.HasTool(player, name)
	local c = player.Character
	return player.Backpack:FindFirstChild(name) ~= nil or (c ~= nil and c:FindFirstChild(name) ~= nil)
end

function State.TakeTool(player, name)
	local c = player.Character
	local t = (c and c:FindFirstChild(name)) or player.Backpack:FindFirstChild(name)
	if t then
		t:Destroy()
		return true
	end
	return false
end

function State.ClearTools(player)
	local hum = humanoid(player)
	if hum then
		hum:UnequipTools()
	end
	for _, t in ipairs(player.Backpack:GetChildren()) do
		if t:IsA("Tool") then
			t:Destroy()
		end
	end
end

---------------------------------------------------------------- init
function State.Init(r)
	remotes = r
	remotes.Movimento.OnServerEvent:Connect(function(player, mode)
		if mode ~= "Correr" and mode ~= "Andar" and mode ~= "Cuidado" then
			return
		end
		get(player).Mode = mode
		player:SetAttribute("Modo", mode)
		State.ApplySpeed(player)
	end)
	remotes.CobrirOlhos.OnServerEvent:Connect(function(player, covered)
		if typeof(covered) ~= "boolean" then
			return
		end
		State.SetCovered(player, covered and State.IsActive(player))
	end)
	local function setup(player)
		get(player)
		player:SetAttribute("NaFita", false)
		player:SetAttribute("Vivo", false)
		player:SetAttribute("Ruido", 0)
		player.CharacterAdded:Connect(function(character)
			local d = get(player)
			d.Pushing = false
			d.Hidden = false
			d.Covered = false
			player:SetAttribute("OlhosCobertos", false)
			player:SetAttribute("Empurrando", false)
			player:SetAttribute("Escondido", false)
			character:WaitForChild("Humanoid")
			State.ApplySpeed(player)
		end)
	end
	Players.PlayerAdded:Connect(setup)
	for _, p in ipairs(Players:GetPlayers()) do
		setup(p)
	end
	Players.PlayerRemoving:Connect(function(player)
		data[player] = nil
	end)
end

return State
