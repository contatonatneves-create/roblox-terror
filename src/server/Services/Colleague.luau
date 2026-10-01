-- O Falso Colega (GDD v2, seção 7.4): anomalia de manutenção dos andares escuros (andar 9+).
-- Um 5º funcionário idêntico a alguém do grupo anda em silêncio à frente, segurando ferramentas.
-- Regra: não seguir, não interagir e passar por perto com cuidado (ruído baixo).
-- Falha: barulho a até 15 studs dele → ele vira o rosto (um buraco de estática) e aplica
-- cegueira (tela de estática) e passos pesados (ruído em dobro) por 60 segundos.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Build = require(script.Parent.Build)
local State = require(script.Parent.State)
local Noise = require(script.Parent.Noise)
local Threat = require(script.Parent.Threat)

local Colleague = {}
local CC = Config.Colleague
local M = Enum.Material

local active = nil
local token = 0

local function ctx()
	return Threat.Ctx
end

---------------------------------------------------------------- cópia do jogador
local function copyCharacter(player)
	local character = player.Character
	if not character then
		return nil
	end
	local was = character.Archivable
	character.Archivable = true
	local clone = character:Clone()
	character.Archivable = was
	if not clone then
		return nil
	end
	for _, d in ipairs(clone:GetDescendants()) do
		if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") or d:IsA("Tool") or d:IsA("Sound") or d:IsA("ProximityPrompt") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
			if d:GetAttribute("AlphaAntes") ~= nil then
				d.Transparency = d:GetAttribute("AlphaAntes")
			end
			d.Anchored = d.Name == "HumanoidRootPart"
		elseif d:IsA("Decal") and d:GetAttribute("AlphaAntes") ~= nil then
			d.Transparency = d:GetAttribute("AlphaAntes")
		elseif d:IsA("Weld") and d.Name == "SoldaCarrinho" then
			d:Destroy()
		end
	end
	for _, d in ipairs(clone:GetDescendants()) do
		if d:IsA("WeldConstraint") and (d.Name == "SoldaCarrinho" or d.Name == "SoldaEsconderijo") then
			d:Destroy()
		end
	end
	local hum = clone:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
		hum.NameDisplayDistance = 0
		hum.BreakJointsOnDeath = false
	end
	clone.Name = "FalsoColega"
	-- chave inglesa na mão
	local hand = clone:FindFirstChild("RightHand") or clone:FindFirstChild("Right Arm")
	if hand then
		local wrench = Build.Part("Chave", Vector3.new(0.3, 2, 0.2), hand.CFrame * CFrame.new(0, -0.9, -0.3) * CFrame.Angles(math.rad(70), 0, 0), Color3.fromRGB(150, 152, 150), M.Metal, clone, { collide = false, anchored = false })
		wrench.Massless = true
		local w = Instance.new("WeldConstraint")
		w.Part0 = hand
		w.Part1 = wrench
		w.Parent = wrench
	end
	return clone
end

-- o rosto vira um buraco de estática
local function revealFace(clone)
	local head = clone:FindFirstChild("Head")
	if not head then
		return
	end
	for _, d in ipairs(head:GetChildren()) do
		if d:IsA("Decal") then
			d:Destroy()
		end
	end
	for _, a in ipairs(clone:GetChildren()) do
		if a:IsA("Accessory") then
			a:Destroy()
		end
	end
	head.Color = Color3.new(0, 0, 0)
	head.Material = M.SmoothPlastic
	local static = Instance.new("ParticleEmitter")
	static.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	static.Color = ColorSequence.new(Color3.fromRGB(200, 200, 200), Color3.fromRGB(90, 90, 90))
	static.Size = NumberSequence.new(0.25)
	static.Lifetime = NumberRange.new(0.05, 0.15)
	static.Speed = NumberRange.new(0.5, 2)
	static.Rate = 120
	static.LightEmission = 0.6
	static.Parent = head
	local s = Build.Sound(head, Config.Sounds.Static, { volume = 1.3, maxDistance = 80, speed = 0.8 })
	s:Play()
end

---------------------------------------------------------------- ciclo
local function setDark(floor, dark)
	if floor.Model.Parent then
		local cur = floor.Model:GetAttribute("Luzes")
		if dark and cur ~= "Ambar" then
			floor.Model:SetAttribute("Luzes", "Escuro")
		elseif not dark and cur == "Escuro" then
			floor.Model:SetAttribute("Luzes", "Normal")
		end
	end
end

function Colleague.Cancel()
	token += 1
	if active then
		local ev = active
		active = nil
		if ev.Clone then
			ev.Clone:Destroy()
		end
		setDark(ev.Floor, false)
	end
end

local function finish(ev)
	if active ~= ev then
		return
	end
	Colleague.Cancel()
end

local function punish(ev, player)
	ev.Triggered = true
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local cRoot = ev.Clone:FindFirstChild("HumanoidRootPart")
	if root and cRoot then
		local p = cRoot.Position
		ev.Clone:PivotTo(CFrame.lookAt(p, Vector3.new(root.Position.X, p.Y, root.Position.Z)))
	end
	revealFace(ev.Clone)
	State.SetEffect(player, "Cego", CC.EffectSeconds)
	State.SetEffect(player, "PassosPesados", CC.EffectSeconds)
	ctx().Notify(player, "Ele ouviu você. Cegueira e passos pesados por " .. CC.EffectSeconds .. " s.")
	task.wait(2.2)
	finish(ev)
end

function Colleague.Trigger(floor)
	if active or not ctx().IsCurrent(floor) then
		return false
	end
	local players = ctx().Active()
	local candidates = {}
	for _, p in ipairs(players) do
		if not State.Get(p).Hidden and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
			table.insert(candidates, p)
		end
	end
	if #candidates == 0 then
		return false
	end
	local rng = ctx().Rng()
	local target = candidates[rng:NextInteger(1, #candidates)]
	local lead = Threat.LeadIndex(floor, players)
	local idx = math.min(lead + 2, #floor.Path - 1)
	if idx >= #floor.Path - 1 then
		return false
	end
	local clone = copyCharacter(target)
	if not clone then
		return false
	end
	token += 1
	local myToken = token
	local root = target.Character.HumanoidRootPart
	local height = root.Position.Y - floor.Origin.Y
	local ev = { Floor = floor, Clone = clone, Index = idx, Height = height, Start = os.clock() }
	active = ev
	local pos = floor.Path[idx] + Vector3.new(0, height, 0)
	local nextPos = floor.Path[idx + 1] + Vector3.new(0, height, 0)
	clone:PivotTo(CFrame.lookAt(pos, nextPos))
	clone.Parent = floor.Model
	setDark(floor, true)
	-- anda em silêncio à frente do grupo, em stop-motion, com paradas
	task.spawn(function()
		local step = 1 / 12
		local current = pos
		local target = idx + 1
		local pauseUntil = os.clock() + 2
		while myToken == token and active == ev do
			task.wait(step)
			if not ctx().IsCurrent(floor) then
				Colleague.Cancel()
				return
			end
			if os.clock() - ev.Start > CC.LifeSeconds then
				finish(ev)
				return
			end
			-- regra: barulho perto dele
			if not ev.Triggered then
				local cRoot = clone:FindFirstChild("HumanoidRootPart")
				for _, p in ipairs(ctx().Active()) do
					local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
					if r and cRoot and (r.Position - cRoot.Position).Magnitude <= CC.Radius and Noise.Get(p) > Config.Noise.LoudThreshold then
						task.spawn(punish, ev, p)
						break
					end
				end
			end
			if not ev.Triggered and os.clock() > pauseUntil then
				if target >= #floor.Path then
					finish(ev)
					return
				end
				local goal = floor.Path[target] + Vector3.new(0, height, 0)
				local dir = goal - current
				local move = math.min(dir.Magnitude, CC.Speed * step)
				if dir.Magnitude > 0.05 then
					current += dir.Unit * move
					local bob = math.abs(math.sin(os.clock() * 7)) * 0.15
					clone:PivotTo(CFrame.lookAt(current + Vector3.new(0, bob, 0), current + Vector3.new(dir.X, bob, dir.Z)))
				else
					target += 1
					if rng:NextNumber() < 0.35 then
						pauseUntil = os.clock() + rng:NextNumber(1.5, 4)
					end
				end
			end
		end
	end)
	return true
end

-- Agenda o Falso Colega para um andar (chamado quando o grupo chega)
function Colleague.Schedule(floor, rng)
	if floor.Number < CC.FromFloor or floor.Number > CC.ToFloor or #ctx().Active() == 0 then
		return
	end
	if rng:NextNumber() > CC.Chance then
		return
	end
	task.delay(rng:NextNumber(CC.Delay[1], CC.Delay[2]), function()
		if ctx().IsCurrent(floor) and not active then
			Colleague.Trigger(floor)
		end
	end)
end

function Colleague.IsActive()
	return active ~= nil
end

function Colleague.Init()
	Threat.Register("FalsoColega", Colleague.Cancel)
end

return Colleague
