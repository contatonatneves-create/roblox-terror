-- O Instrutor (GDD v2, seção 7.1): antagonista dos andares da Distorção.
-- Regra M.A.D.: olhar direto para ele por mais de 1,5 s = paralisia e morte (o cliente mede o olhar).
-- Procedimento: Cobrir os Olhos e andar de costas até ele sumir. Dar as costas sem cobrir = morte.
-- O flash da Polaroid cega o Instrutor por 3 s. Sem aparecer, ele imita os ruídos que o grupo fez.
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Build = require(script.Parent.Build)
local State = require(script.Parent.State)
local Noise = require(script.Parent.Noise)
local Threat = require(script.Parent.Threat)
local Polaroid = require(script.Parent.Polaroid)

local Trainer = {}
local TC = Config.Trainer
local M = Enum.Material

local active = nil
local token = 0
local lurkToken = 0
local recentNoises = {} -- { Reason, Time } dos ruídos do grupo, para a imitação

local function ctx()
	return Threat.Ctx
end

local function flat(v)
	return Vector3.new(v.X, 0, v.Z)
end

---------------------------------------------------------------- modelo
local function frame(parent, props)
	local f = Instance.new("Frame")
	f.BorderSizePixel = 0
	for k, v in pairs(props) do
		f[k] = v
	end
	f.Parent = parent
	return f
end

local function round(f, scale)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(scale or 0.5, 0)
	c.Parent = f
end

-- Rosto 2D de executivo sorridente: sempre virado para quem olha (BillboardGui)
local function buildFace(head)
	local bb = Instance.new("BillboardGui")
	bb.Name = "Rosto"
	bb.Size = UDim2.fromScale(3.1, 3.5)
	bb.LightInfluence = 0
	bb.Brightness = 1.15
	bb.MaxDistance = 160
	bb.AlwaysOnTop = false
	bb.Adornee = head
	local skin = Color3.fromRGB(226, 196, 170)
	local root = frame(bb, { Name = "Face", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 })
	frame(root, { Name = "Orelha", Position = UDim2.fromScale(0.02, 0.38), Size = UDim2.fromScale(0.12, 0.2), BackgroundColor3 = skin:Lerp(Color3.new(0, 0, 0), 0.1) })
	frame(root, { Name = "Orelha", Position = UDim2.fromScale(0.86, 0.38), Size = UDim2.fromScale(0.12, 0.2), BackgroundColor3 = skin:Lerp(Color3.new(0, 0, 0), 0.1) })
	local face = frame(root, { Name = "Pele", Position = UDim2.fromScale(0.09, 0.08), Size = UDim2.fromScale(0.82, 0.88), BackgroundColor3 = skin })
	round(face, 0.42)
	local shade = Instance.new("UIGradient")
	shade.Rotation = 90
	shade.Color = ColorSequence.new(skin, skin:Lerp(Color3.fromRGB(120, 80, 60), 0.35))
	shade.Parent = face
	-- cabelo penteado com gel
	local hair = frame(root, { Name = "Cabelo", Position = UDim2.fromScale(0.08, 0.02), Size = UDim2.fromScale(0.84, 0.26), BackgroundColor3 = Color3.fromRGB(38, 28, 22) })
	round(hair, 0.45)
	frame(root, { Name = "Risca", Position = UDim2.fromScale(0.34, 0.06), Size = UDim2.fromScale(0.02, 0.17), BackgroundColor3 = skin:Lerp(Color3.new(0, 0, 0), 0.3), Rotation = 8 })
	-- olhos arregalados
	local eyes = frame(root, { Name = "Olhos", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 })
	for _, x in ipairs({ 0.24, 0.56 }) do
		local white = frame(eyes, { Name = "Olho", Position = UDim2.fromScale(x, 0.36), Size = UDim2.fromScale(0.2, 0.11), BackgroundColor3 = Color3.fromRGB(246, 240, 228) })
		round(white, 0.5)
		local iris = frame(white, { Name = "Iris", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.42, 0.8), BackgroundColor3 = Color3.fromRGB(70, 56, 40) })
		round(iris, 0.5)
		local pupil = frame(iris, { Name = "Pupila", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.45, 0.45), BackgroundColor3 = Color3.new(0, 0, 0) })
		round(pupil, 0.5)
		frame(eyes, { Name = "Sobrancelha", Position = UDim2.fromScale(x - 0.01, 0.3), Size = UDim2.fromScale(0.22, 0.03), BackgroundColor3 = Color3.fromRGB(40, 30, 24), Rotation = x < 0.5 and -7 or 7 })
	end
	-- olhos fechados (quando cego pelo flash)
	local closed = frame(root, { Name = "Fechados", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false })
	for _, x in ipairs({ 0.24, 0.56 }) do
		frame(closed, { Position = UDim2.fromScale(x, 0.41), Size = UDim2.fromScale(0.2, 0.025), BackgroundColor3 = Color3.fromRGB(40, 30, 24) })
	end
	-- nariz e o sorriso largo demais
	frame(root, { Name = "Nariz", Position = UDim2.fromScale(0.48, 0.47), Size = UDim2.fromScale(0.04, 0.13), BackgroundColor3 = skin:Lerp(Color3.fromRGB(110, 70, 50), 0.35) })
	local mouth = frame(root, { Name = "Boca", Position = UDim2.fromScale(0.17, 0.64), Size = UDim2.fromScale(0.66, 0.17), BackgroundColor3 = Color3.fromRGB(70, 14, 16) })
	round(mouth, 0.5)
	local teeth = frame(mouth, { Name = "Dentes", Position = UDim2.fromScale(0.08, 0.08), Size = UDim2.fromScale(0.84, 0.45), BackgroundColor3 = Color3.fromRGB(244, 240, 222) })
	round(teeth, 0.3)
	for i = 1, 9 do
		frame(teeth, { Position = UDim2.fromScale(i / 10, 0), Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = Color3.fromRGB(150, 140, 120) })
	end
	frame(root, { Name = "Covinha", Position = UDim2.fromScale(0.12, 0.62), Size = UDim2.fromScale(0.03, 0.1), BackgroundColor3 = skin:Lerp(Color3.new(0, 0, 0), 0.25), Rotation = -20 })
	frame(root, { Name = "Covinha", Position = UDim2.fromScale(0.85, 0.62), Size = UDim2.fromScale(0.03, 0.1), BackgroundColor3 = skin:Lerp(Color3.new(0, 0, 0), 0.25), Rotation = 20 })
	bb.Parent = head
	return bb, eyes, closed
end

local function buildModel(cf)
	local m = Instance.new("Model")
	m.Name = "Instrutor"
	local suit = Color3.fromRGB(92, 62, 40)
	local function part(name, size, localCF, color, mat, opts)
		opts = opts or {}
		opts.collide = false
		return Build.Part(name, size, cf * localCF, color, mat, m, opts)
	end
	part("PernaE", Vector3.new(0.85, 2.6, 0.9), CFrame.new(-0.5, 1.3, 0), suit:Lerp(Color3.new(0, 0, 0), 0.15), M.Fabric)
	part("PernaD", Vector3.new(0.85, 2.6, 0.9), CFrame.new(0.5, 1.3, 0), suit:Lerp(Color3.new(0, 0, 0), 0.15), M.Fabric)
	part("Sapato", Vector3.new(0.9, 0.3, 1.3), CFrame.new(-0.5, 0.15, -0.15), Color3.fromRGB(16, 12, 10), M.SmoothPlastic)
	part("Sapato", Vector3.new(0.9, 0.3, 1.3), CFrame.new(0.5, 0.15, -0.15), Color3.fromRGB(16, 12, 10), M.SmoothPlastic)
	local torso = part("Paleto", Vector3.new(2.2, 2.5, 1.1), CFrame.new(0, 3.85, 0), suit, M.Fabric)
	part("Camisa", Vector3.new(0.7, 1.3, 0.05), CFrame.new(0, 4.4, -0.56), Color3.fromRGB(236, 232, 220), M.Fabric)
	part("Gravata", Vector3.new(0.22, 1.2, 0.06), CFrame.new(0, 4.3, -0.6), Color3.fromRGB(130, 24, 28), M.Fabric)
	part("Cracha", Vector3.new(0.5, 0.32, 0.05), CFrame.new(0.65, 4.6, -0.57), Color3.fromRGB(236, 236, 236), M.SmoothPlastic)
	part("BracoE", Vector3.new(0.6, 2.6, 0.7), CFrame.new(-1.45, 3.75, 0), suit, M.Fabric)
	part("BracoD", Vector3.new(0.6, 2.6, 0.7), CFrame.new(1.45, 3.75, 0), suit, M.Fabric)
	part("MaoE", Vector3.new(0.5, 0.6, 0.5), CFrame.new(-1.45, 2.2, 0), Color3.fromRGB(226, 196, 170), M.SmoothPlastic)
	part("MaoD", Vector3.new(0.5, 0.6, 0.5), CFrame.new(1.45, 2.2, 0), Color3.fromRGB(226, 196, 170), M.SmoothPlastic)
	-- pescoço de cilindro preto, esticado
	part("Pescoco", Vector3.new(2.7, 0.5, 0.5), CFrame.new(0, 6.4, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(8, 8, 8), M.SmoothPlastic, { shape = Enum.PartType.Cylinder })
	local head = part("Cabeca", Vector3.new(2.6, 3, 0.2), CFrame.new(0, 8.9, 0), Color3.new(0, 0, 0), M.SmoothPlastic, { transp = 1 })
	local face, eyes, closed = buildFace(head)
	m.PrimaryPart = torso
	return m, head, face, eyes, closed
end

---------------------------------------------------------------- regras
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function headOf(player)
	local c = player.Character
	local head = c and c:FindFirstChild("Head")
	return head and head.Position
end

-- O jogador tem linha de visão até o rosto dele?
local function canSee(player, ev)
	local eye = headOf(player)
	if not eye then
		return false, math.huge
	end
	local target = ev.Head.Position
	local dist = (target - eye).Magnitude
	if dist > TC.Range then
		return false, dist
	end
	local ignore = { ev.Model }
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character then
			table.insert(ignore, p.Character)
		end
	end
	local cart = workspace:FindFirstChild("CarrinhoServico")
	if cart then
		table.insert(ignore, cart)
	end
	rayParams.FilterDescendantsInstances = ignore
	local hit = workspace:Raycast(eye, target - eye, rayParams)
	return hit == nil, dist
end

local function vanish(ev)
	if active ~= ev then
		return
	end
	active = nil
	ctx().FireRun("Som", "Static")
	if ev.Model then
		ev.Model:Destroy()
	end
	Threat.Release("Instrutor")
end

function Trainer.Cancel()
	token += 1
	lurkToken += 1
	if active then
		local ev = active
		active = nil
		if ev.Model then
			ev.Model:Destroy()
		end
	end
	Threat.Release("Instrutor")
end

local function snap(player, reason)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root then
		local s = Build.Sound(root, Config.Sounds.Bump, { volume = 1.5, speed = 0.45, maxDistance = 60 })
		s:Play()
		game:GetService("Debris"):AddItem(s, 3)
	end
	ctx().Kill(player, reason)
end

function Trainer.Trigger(floor)
	if active or not ctx().IsCurrent(floor) then
		return false
	end
	local players = ctx().Active()
	if #players == 0 then
		return false
	end
	local lead = Threat.LeadIndex(floor, players)
	local last = #floor.Path - 1
	local idx = math.min(lead + TC.AheadCells, last)
	if idx - lead < 2 then
		return false
	end
	local pos = floor.Path[idx]
	local back = floor.Path[idx - 1]
	if not Threat.Acquire("Instrutor", pos) then
		return false
	end
	token += 1
	local myToken = token
	local cf = CFrame.lookAt(pos, Vector3.new(back.X, pos.Y, back.Z))
	local model, head, face, eyes, closed = buildModel(cf)
	model:SetAttribute("Instrutor", true)
	model.Parent = floor.Model
	CollectionService:AddTag(head, "RostoInstrutor")
	local rng = ctx().Rng()
	local ev = {
		Floor = floor,
		Model = model,
		Head = head,
		Face = face,
		Eyes = eyes,
		Closed = closed,
		Start = os.clock(),
		EndTime = os.clock() + rng:NextNumber(TC.Duration[1], TC.Duration[2]),
		Faced = {},
		BlindUntil = 0,
		Base = cf,
	}
	active = ev
	workspace:SetAttribute("AmeacaPos", head.Position)
	ctx().FireRun("Som", "EAS")
	task.spawn(function()
		while myToken == token and active == ev do
			task.wait(0.1)
			if not ctx().IsCurrent(floor) then
				Trainer.Cancel()
				return
			end
			local now = os.clock()
			if now > ev.EndTime then
				vanish(ev)
				return
			end
			local blind = now < ev.BlindUntil
			ev.Eyes.Visible = not blind
			ev.Closed.Visible = blind
			-- o corpo gira devagar para o jogador mais perto (o rosto já está sempre virado)
			local nearest, nd = nil, math.huge
			for _, p in ipairs(ctx().Active()) do
				local seen, dist = canSee(p, ev)
				local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
				if root and dist < nd then
					nearest, nd = root, dist
				end
				if seen and root and not State.Get(p).Hidden then
					local to = flat(ev.Head.Position - root.Position)
					local look = flat(root.CFrame.LookVector)
					if to.Magnitude > 0.1 and look.Magnitude > 0.1 then
						local dot = look.Unit:Dot(to.Unit)
						if dot > TC.FacedDot then
							ev.Faced[p] = true
						end
						if not blind and ev.Faced[p] and dot < TC.BackDot and not State.IsCovered(p) and now - ev.Start > TC.Grace then
							task.spawn(snap, p, "Você deu as costas ao Instrutor.")
						end
					end
				end
			end
			if nearest then
				local pivot = ev.Model:GetPivot()
				local target = Vector3.new(nearest.Position.X, pivot.Position.Y, nearest.Position.Z)
				if (target - pivot.Position).Magnitude > 0.5 then
					ev.Model:PivotTo(pivot:Lerp(CFrame.lookAt(pivot.Position, target), 0.08))
				end
			end
			-- todo mundo longe demais: ele some
			if nd > TC.Range + 30 and now - ev.Start > 4 then
				vanish(ev)
				return
			end
		end
	end)
	return true
end

-- O cliente avisa que o jogador ficou olhando para o rosto por tempo demais
function Trainer.Stared(player)
	local ev = active
	if not ev or not State.CanAct(player) or State.IsCovered(player) or State.Get(player).Hidden then
		return
	end
	if os.clock() < ev.BlindUntil or os.clock() - ev.Start < 0.5 then
		return
	end
	local seen = canSee(player, ev)
	if not seen then
		return
	end
	ctx().Kill(player, "Você encarou o Instrutor.")
end

-- Flash da Polaroid: cega o Instrutor e encurta a aparição
Polaroid.OnFlash(function(player, origin, look)
	local ev = active
	if not ev then
		return
	end
	local to = ev.Head.Position - origin
	if to.Magnitude > Config.Polaroid.Range then
		return
	end
	local fl = flat(look)
	if fl.Magnitude < 0.1 or fl.Unit:Dot(flat(to).Unit) < 0.5 then
		return
	end
	ev.BlindUntil = os.clock() + TC.BlindSeconds
	ev.EndTime = math.min(ev.EndTime, os.clock() + TC.BlindSeconds + 3)
	for _, p in ipairs(ctx().Active()) do
		ctx().Notify(p, "O Instrutor está cego! Corram!")
	end
end)

---------------------------------------------------------------- imitação dos ruídos
Noise.OnEmit(function(pos, level, player, reason)
	if player and reason then
		table.insert(recentNoises, { Reason = reason, Time = os.clock() })
		if #recentNoises > 12 then
			table.remove(recentNoises, 1)
		end
	end
end)

local MIMIC = {
	Esbarrao = { Config.Sounds.Bump, 0.9, 1 },
	Roda = { Config.Sounds.TrolleySqueak, 1.2, 0.8 },
	Flash = { Config.Sounds.Beep, 0.8, 2.2 },
	Passos = { Config.Sounds.Bump, 0.35, 1.8 },
}

local function playMimic(floor, pos)
	local reason = "Passos"
	local recent = {}
	for _, n in ipairs(recentNoises) do
		if os.clock() - n.Time < 180 and MIMIC[n.Reason] then
			table.insert(recent, n.Reason)
		end
	end
	if #recent > 0 and math.random() < 0.7 then
		reason = recent[math.random(1, #recent)]
	end
	local spec = MIMIC[reason]
	local emitter = Build.Deco("Imitacao", Vector3.new(0.5, 0.5, 0.5), CFrame.new(pos + Vector3.new(0, 2, 0)), Color3.new(), M.SmoothPlastic, floor.Model, { transp = 1 })
	local repeats = reason == "Passos" and 6 or 1
	task.spawn(function()
		for i = 1, repeats do
			local s = Build.Sound(emitter, spec[1], { volume = spec[2], speed = spec[3] * (0.9 + math.random() * 0.2), maxDistance = 140, minDistance = 12 })
			s:Play()
			task.wait(reason == "Passos" and 0.42 or 0.1)
		end
		task.wait(3)
		emitter:Destroy()
	end)
end

function Trainer.Lurk(floor)
	lurkToken += 1
	local myToken = lurkToken
	task.spawn(function()
		local rng = ctx().Rng()
		while myToken == lurkToken do
			task.wait(rng:NextNumber(TC.MimicEvery[1], TC.MimicEvery[2]))
			if myToken ~= lurkToken or not ctx().IsCurrent(floor) then
				return
			end
			if not active then
				local players = ctx().Active()
				local root = players[1] and players[1].Character and players[1].Character:FindFirstChild("HumanoidRootPart")
				if root then
					local options = {}
					for _, p in ipairs(floor.Path) do
						local d = Threat.DistXZ(p, root.Position)
						if d >= TC.MimicDistance[1] and d <= TC.MimicDistance[2] then
							table.insert(options, p)
						end
					end
					if #options > 0 then
						playMimic(floor, options[rng:NextInteger(1, #options)])
					end
				end
			end
		end
	end)
end

-- Agenda o Instrutor para um andar (chamado quando o grupo chega)
function Trainer.Schedule(floor, rng)
	if floor.Number < TC.FromFloor or floor.Number > TC.ToFloor then
		return
	end
	if Config.PhaseOf(floor.Number).Name == "DISTORCAO" then
		Trainer.Lurk(floor)
	end
	if rng:NextNumber() > TC.Chance then
		return
	end
	task.delay(rng:NextNumber(TC.Delay[1], TC.Delay[2]), function()
		Threat.WhenFree(function()
			return ctx().IsCurrent(floor) and not active
		end, function()
			if not Trainer.Trigger(floor) then
				-- grupo perto demais do fim: tenta de novo daqui a pouco
				task.wait(8)
				if ctx().IsCurrent(floor) and not active and not Threat.Busy() then
					Trainer.Trigger(floor)
				end
			end
		end)
	end)
end

function Trainer.IsActive()
	return active ~= nil
end

function Trainer.Init(remotes)
	remotes.Encarou.OnServerEvent:Connect(Trainer.Stared)
	Threat.Register("Instrutor", Trainer.Cancel)
end

return Trainer
