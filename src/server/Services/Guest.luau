-- O Hóspede do 302 (GDD v2, seção 7.3).
-- Aviso: a campainha de um quarto toca e a porta abre uma fresta, com braços pálidos e longos demais.
-- Procedimento: deixar a bandeja na marca a 1 metro da porta, virar de costas e dizer
-- "Bom apetite, favor não incomodar" em até 6 segundos.
-- Falha: entregar na mão, não virar de costas, não dizer a tempo ou fazer barulho perto da porta.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Build = require(script.Parent.Build)
local State = require(script.Parent.State)
local Noise = require(script.Parent.Noise)
local Floors = require(script.Parent.Floors)
local Threat = require(script.Parent.Threat)

local Guest = {}
local GC = Config.Guest
local M = Enum.Material
local SKIN = Color3.fromRGB(226, 222, 214)

local active = nil
local token = 0

local function ctx()
	return Threat.Ctx
end

local function flat(v)
	return Vector3.new(v.X, 0, v.Z)
end

local function notifyAll(text)
	for _, p in ipairs(ctx().Active()) do
		ctx().Notify(p, text)
	end
end

---------------------------------------------------------------- escolha da porta
local function pathIndexOf(floor, pos)
	local best, bd = 1, math.huge
	for i, p in ipairs(floor.Path) do
		local d = Threat.DistXZ(p, pos)
		if d < bd then
			best, bd = i, d
		end
	end
	return best
end

local function pickDoor(floor, players)
	local taken = {}
	for _, t in ipairs(floor.Tasks) do
		if t.Door then
			taken[t.Door] = true
		end
	end
	local lead = Threat.LeadIndex(floor, players)
	local ahead, any = {}, {}
	for _, door in ipairs(floor.Doors) do
		if not taken[door] then
			table.insert(any, door)
			if pathIndexOf(floor, door.Part.Position) >= lead + 1 then
				table.insert(ahead, door)
			end
		end
	end
	local list = #ahead > 0 and ahead or any
	if #list == 0 then
		return nil
	end
	-- o 302 (ou qualquer quarto terminado em 02) tem preferência
	for _, door in ipairs(list) do
		if door.Number % 100 == 2 then
			return door
		end
	end
	return list[ctx().Rng():NextInteger(1, #list)]
end

---------------------------------------------------------------- peças do evento
local function alongOf(inward)
	return Vector3.new(math.abs(inward.Z), 0, math.abs(inward.X))
end

-- gira a folha da porta pela dobradiça, para dentro do quarto
local function crackCFrame(door, angle)
	local cf = door.Closed
	local along = alongOf(door.Inward)
	local hinge = cf.Position - along * 2.1
	local best, bestScore = nil, -math.huge
	for _, sign in ipairs({ 1, -1 }) do
		local rotated = CFrame.new(hinge) * CFrame.Angles(0, sign * angle, 0) * CFrame.new(-hinge) * cf
		local score = (rotated.Position - cf.Position):Dot(-door.Inward)
		if score > bestScore then
			best, bestScore = rotated, score
		end
	end
	return best
end

local function floorPoint(door)
	local p = (door.Closed or door.Part.CFrame).Position
	return Vector3.new(p.X, door.FloorY, p.Z)
end

local function buildArms(ev)
	local door = ev.Door
	local along = alongOf(door.Inward)
	local base = floorPoint(door) + door.Inward * 0.1
	local arms = {}
	for i, side in ipairs({ -1.1, 0.9 }) do
		local start = base + along * side + Vector3.new(0, 0.25 + i * 0.05, 0)
		local arm = Build.Deco("Braco", Vector3.new(0.32, 0.3, 0.2), CFrame.lookAt(start, start + door.Inward), SKIN, M.SmoothPlastic, ev.Model)
		local hand = Build.Deco("Mao", Vector3.new(0.6, 0.12, 0.7), CFrame.lookAt(start, start + door.Inward), SKIN, M.SmoothPlastic, ev.Model)
		-- dedos compridos demais, soldados à mão (acompanham o movimento dela)
		for f = -2, 2 do
			local finger = Build.Deco("Dedo", Vector3.new(0.07, 0.07, 0.75), hand.CFrame * CFrame.new(f * 0.13, 0, -0.65) * CFrame.Angles(0, f * 0.12, 0), SKIN, M.SmoothPlastic, ev.Model, { anchored = false })
			finger.Massless = true
			local w = Instance.new("WeldConstraint")
			w.Part0 = hand
			w.Part1 = finger
			w.Parent = finger
		end
		table.insert(arms, { Arm = arm, Hand = hand, Start = start, Side = side })
	end
	ev.Arms = arms
end

-- estica os braços até "reach" studs para fora da porta
local function reachArms(ev, reach, seconds)
	for _, a in ipairs(ev.Arms) do
		local dir = ev.Door.Inward
		local len = math.max(reach, 0.2)
		local mid = a.Start + dir * (len / 2)
		local info = TweenInfo.new(seconds or 1.2, Enum.EasingStyle.Sine)
		TweenService:Create(a.Arm, info, { Size = Vector3.new(0.32, 0.3, len), CFrame = CFrame.lookAt(mid, mid + dir) }):Play()
		local handPos = a.Start + dir * (len + 0.2)
		TweenService:Create(a.Hand, info, { CFrame = CFrame.lookAt(handPos, handPos + dir) }):Play()
	end
end

local function buildMark(ev)
	local door = ev.Door
	local center = floorPoint(door) + door.Inward * GC.MarkDistance + Vector3.new(0, 0.05, 0)
	ev.MarkPos = center
	for _, a in ipairs({ math.rad(45), math.rad(-45) }) do
		Build.Deco("Marca", Vector3.new(2, 0.04, 0.22), CFrame.new(center) * CFrame.Angles(0, a, 0), Color3.fromRGB(236, 232, 214), M.SmoothPlastic, ev.Model, { shadow = false })
	end
	local spot = Build.Part("MarcaBandeja", Vector3.new(2, 0.2, 2), CFrame.new(center + Vector3.new(0, 0.1, 0)), Color3.new(), M.SmoothPlastic, ev.Model, { collide = false, transp = 1 })
	ev.MarkPart = spot
	local pp = Build.Prompt(spot, "PromptBandeja", "Deixar bandeja", "Marca no carpete", { distance = 6, hold = 0.5 })
	ev.MarkPrompt = pp
	pp.Triggered:Connect(function(player)
		Guest.PlaceTray(player)
	end)
	-- armadilha: entregar em mãos
	local hand = Build.Prompt(door.Part, "PromptEmMaos", "Entregar em mãos", "Quarto " .. door.Number, { distance = 6, hold = 0.4, key = Enum.KeyCode.R, pad = Enum.KeyCode.ButtonY })
	ev.HandPrompt = hand
	hand.Triggered:Connect(function(player)
		if active == ev and State.CanAct(player) and State.HasTool(player, "Bandeja") then
			Guest.Pull(player, "Você entregou a bandeja em mãos.")
		elseif active == ev and State.CanAct(player) then
			ctx().Notify(player, "Você não tem bandeja. Pegue uma no carrinho.")
		end
	end)
end

local function ring(ev, times)
	for i = 1, times do
		local s = Build.Sound(ev.Door.Part, Config.Sounds.Ding, { volume = 1, speed = 1.45, maxDistance = 120, minDistance = 10 })
		s:Play()
		game:GetService("Debris"):AddItem(s, 3)
		if i < times then
			task.wait(0.55)
		end
	end
end

---------------------------------------------------------------- ciclo
local function cleanup(ev)
	if ev.Model then
		ev.Model:Destroy()
	end
	if ev.HandPrompt then
		ev.HandPrompt:Destroy()
	end
	if ev.Door and ev.Door.Part.Parent then
		ev.Door.Part.CFrame = ev.Door.Closed
	end
end

function Guest.Cancel()
	token += 1
	if active then
		cleanup(active)
		active = nil
	end
	Threat.Release("Hospede")
end

local function resetTray(ev)
	if ev.TrayPart then
		ev.TrayPart:Destroy()
		ev.TrayPart = nil
	end
	ev.Placer = nil
	ev.Deadline = nil
	if ev.MarkPrompt then
		ev.MarkPrompt.Enabled = true
	end
end

function Guest.PlaceTray(player)
	local ev = active
	if not ev or ev.Pulling or not State.CanAct(player) then
		return
	end
	if ev.TrayPart then
		return
	end
	if not State.HasTool(player, "Bandeja") then
		ctx().Notify(player, "Pegue uma bandeja no carrinho [B].")
		return
	end
	State.TakeTool(player, "Bandeja")
	ev.MarkPrompt.Enabled = false
	local tray = Build.Part("BandejaServida", Vector3.new(2, 0.15, 1.4), CFrame.new(ev.MarkPos + Vector3.new(0, 0.1, 0)), Color3.fromRGB(170, 172, 168), M.Metal, ev.Model, { collide = false })
	Build.Part("Cloche", Vector3.new(0.9, 1.2, 1.2), CFrame.new(ev.MarkPos + Vector3.new(0, 0.62, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(200, 200, 196), M.Metal, tray, { collide = false, shape = Enum.PartType.Cylinder })
	ev.TrayPart = tray
	ev.Placer = player
	ev.Deadline = os.clock() + GC.SayWindow
	player:SetAttribute("DizerAte", workspace:GetServerTimeNow() + GC.SayWindow)
	ctx().Notify(player, "Vire de costas para a porta e diga a frase [G]!")
end

function Guest.Pull(player, reason)
	local ev = active
	if not ev or ev.Pulling then
		return
	end
	ev.Pulling = true
	local myToken = token
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root then
		-- os braços alcançam o jogador e o arrastam para dentro do quarto
		local reach = math.clamp(Threat.DistXZ(root.Position, floorPoint(ev.Door)), 1, 14)
		reachArms(ev, reach, 0.25)
		task.wait(0.25)
		root.Anchored = true
		local from = character:GetPivot()
		local doorIn = floorPoint(ev.Door) - ev.Door.Inward * 1.5 + Vector3.new(0, from.Position.Y - ev.Door.FloorY, 0)
		for i = 1, 8 do
			if not character.Parent then
				break
			end
			local a = i / 8
			character:PivotTo(CFrame.new(from.Position:Lerp(doorIn, a * a)) * from.Rotation * CFrame.Angles(-a * 1.2, 0, 0))
			task.wait(0.04)
		end
	end
	if myToken ~= token then
		return
	end
	ev.Door.Part.CFrame = ev.Door.Closed
	local slam = Build.Sound(ev.Door.Part, Config.Sounds.Bump, { volume = 1.4, speed = 0.7, maxDistance = 120 })
	slam:Play()
	game:GetService("Debris"):AddItem(slam, 3)
	player:SetAttribute("DizerAte", nil)
	ctx().Kill(player, "Puxado para dentro do quarto " .. ev.Door.Number .. ". " .. (reason or ""))
	if root and root.Parent then
		task.delay(0.6, function()
			if root.Parent then
				root.Anchored = false
			end
		end)
	end
	-- o pedido continua: a porta volta a se abrir e a marca reaparece
	reachArms(ev, 0.2, 0.3)
	resetTray(ev)
	task.wait(2.5)
	if myToken ~= token or active ~= ev then
		return
	end
	ev.Door.Part.CFrame = crackCFrame(ev.Door, math.rad(16))
	reachArms(ev, 1.6, 1.5)
	ev.Pulling = false
end

local function succeed(ev, player)
	ev.Done = true
	player:SetAttribute("DizerAte", nil)
	notifyAll(player.DisplayName .. ": \"" .. GC.Phrase .. "\"")
	-- os braços puxam a bandeja e a porta fecha devagar
	local tray = ev.TrayPart
	if tray then
		local target = floorPoint(ev.Door) - ev.Door.Inward * 1 + Vector3.new(0, 0.1, 0)
		for _, a in ipairs(ev.Arms) do
			local mid = a.Start + ev.Door.Inward * ((GC.MarkDistance + 0.4) / 2)
			a.Arm.Size = Vector3.new(0.32, 0.3, GC.MarkDistance + 0.4)
			a.Arm.CFrame = CFrame.lookAt(mid, mid + ev.Door.Inward)
		end
		task.wait(0.5)
		reachArms(ev, 0.2, 1)
		local cloche = tray:FindFirstChild("Cloche")
		TweenService:Create(tray, TweenInfo.new(1), { CFrame = CFrame.new(target) }):Play()
		if cloche then
			TweenService:Create(cloche, TweenInfo.new(1), { CFrame = CFrame.new(target + Vector3.new(0, 0.52, 0)) * CFrame.Angles(0, 0, math.rad(90)) }):Play()
		end
		task.wait(1.1)
	end
	TweenService:Create(ev.Door.Part, TweenInfo.new(0.8), { CFrame = ev.Door.Closed }):Play()
	task.wait(0.9)
	if active ~= ev then
		return
	end
	Floors.CompleteTask(ev.Floor, ev.Task)
	notifyAll("O hóspede do " .. ev.Door.Number .. " agradece.")
	cleanup(ev)
	active = nil
	Threat.Release("Hospede")
end

function Guest.Say(player)
	local ev = active
	if not ev or ev.Pulling or ev.Done or not State.CanAct(player) then
		return
	end
	if not ev.TrayPart then
		ctx().Notify(player, "Primeiro deixe a bandeja na marca.")
		return
	end
	if player ~= ev.Placer then
		ctx().Notify(player, "Quem deixou a bandeja precisa dizer a frase.")
		return
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local doorPos = floorPoint(ev.Door)
	if Threat.DistXZ(root.Position, doorPos) > GC.SayRange then
		ctx().Notify(player, "Longe demais da porta.")
		return
	end
	local look = flat(root.CFrame.LookVector)
	local toDoor = flat(doorPos - root.Position)
	if look.Magnitude < 0.1 or toDoor.Magnitude < 0.1 then
		return
	end
	if look.Unit:Dot(toDoor.Unit) > GC.BackDot then
		task.spawn(Guest.Pull, player, "Você não virou de costas.")
		return
	end
	task.spawn(succeed, ev, player)
end

function Guest.Trigger(floor)
	if active or floor.AllDone or not ctx().IsCurrent(floor) then
		return false
	end
	local players = ctx().Active()
	local door = pickDoor(floor, players)
	if not door then
		return false
	end
	if not Threat.Acquire("Hospede", door.Part.Position) then
		return false
	end
	token += 1
	local myToken = token
	door.Closed = door.Closed or door.Part.CFrame
	door.FloorY = floor.Origin.Y
	local model = Instance.new("Model")
	model.Name = "PedidoQuarto" .. door.Number
	model.Parent = floor.Model
	local ev = { Floor = floor, Door = door, Model = model }
	active = ev
	-- escuro atrás da fresta
	local along = alongOf(door.Inward)
	local gapSize = along.X > 0 and Vector3.new(4, 7.8, 0.05) or Vector3.new(0.05, 7.8, 4)
	Build.Deco("Escuro", gapSize, CFrame.new(floorPoint(door) + Vector3.new(0, 3.95, 0) + door.Inward * 0.02), Color3.new(0, 0, 0), M.SmoothPlastic, model)
	ev.Task = Floors.AddTask(floor, "Servir", { Number = door.Number })
	task.spawn(ring, ev, 2)
	notifyAll("O quarto " .. door.Number .. " pediu serviço de quarto. Silêncio perto da porta.")
	task.wait(1.2)
	if myToken ~= token then
		return true
	end
	-- a porta abre uma fresta e os braços aparecem
	local creak = Build.Sound(door.Part, Config.Sounds.TrolleySqueak, { volume = 0.9, speed = 0.45, maxDistance = 80 })
	creak:Play()
	game:GetService("Debris"):AddItem(creak, 4)
	TweenService:Create(door.Part, TweenInfo.new(1.6, Enum.EasingStyle.Sine), { CFrame = crackCFrame(door, math.rad(16)) }):Play()
	buildArms(ev)
	reachArms(ev, 1.6, 1.6)
	buildMark(ev)
	-- vigia o barulho e o prazo da frase
	task.spawn(function()
		while myToken == token and active == ev do
			task.wait(0.1)
			if not ctx().IsCurrent(floor) then
				Guest.Cancel()
				return
			end
			if not ev.Pulling and not ev.Done then
				local doorPos = floorPoint(door)
				for _, p in ipairs(ctx().Active()) do
					local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
					if root and Threat.DistXZ(root.Position, doorPos) <= GC.NoiseRadius and Noise.Get(p) > Config.Noise.LoudThreshold then
						task.spawn(Guest.Pull, p, "Você fez barulho na porta.")
						break
					end
				end
				if ev.Deadline and os.clock() > ev.Deadline and not ev.Pulling then
					local placer = ev.Placer
					local root = placer and placer.Character and placer.Character:FindFirstChild("HumanoidRootPart")
					if placer and State.IsActive(placer) and root and Threat.DistXZ(root.Position, doorPos) <= GC.GiveUpRange then
						task.spawn(Guest.Pull, placer, "Você não disse a frase a tempo.")
					else
						if placer then
							placer:SetAttribute("DizerAte", nil)
						end
						resetTray(ev)
						notifyAll("A bandeja sumiu. O quarto " .. door.Number .. " ainda espera.")
						ev.TrayPart = nil
					end
				end
			end
		end
	end)
	return true
end

-- Agenda o Hóspede para um andar (chamado quando o grupo chega)
function Guest.Schedule(floor, rng)
	if floor.Number < GC.FromFloor or floor.Number > GC.ToFloor or #floor.Doors < 2 then
		return
	end
	if rng:NextNumber() > GC.Chance then
		return
	end
	task.delay(rng:NextNumber(GC.Delay[1], GC.Delay[2]), function()
		Threat.WhenFree(function()
			return ctx().IsCurrent(floor) and not active and not floor.AllDone
		end, function()
			Guest.Trigger(floor)
		end)
	end)
end

function Guest.IsActive()
	return active ~= nil
end

function Guest.Init(remotes)
	remotes.Dizer.OnServerEvent:Connect(Guest.Say)
	Threat.Register("Hospede", Guest.Cancel)
	Players.PlayerRemoving:Connect(function(p)
		if active and active.Placer == p then
			resetTray(active)
		end
	end)
end

return Guest
