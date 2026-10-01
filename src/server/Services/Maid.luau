-- A Camareira Sem Rosto (GDD v2, seção 7.2).
-- Aviso: luzes âmbar, estática e rangido de carrinho vindo de trás (5 s).
-- Regra: parar, empunhar a vassoura e limpar, sem barulho. Quem está na portinhola do carrinho se salva.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Build = require(script.Parent.Build)
local State = require(script.Parent.State)
local Noise = require(script.Parent.Noise)
local Floors = require(script.Parent.Floors)

local Maid = {}
local MC = Config.Maid
local M = Enum.Material

local killFn = function() end
local active = nil -- { Floor, Token }
local token = 0

function Maid.SetKill(fn)
	killFn = fn
end

local function buildModel(cf)
	local m = Instance.new("Model")
	m.Name = "CamareiraSemRosto"
	local function part(name, size, localCF, color, mat, opts)
		opts = opts or {}
		opts.collide = false
		return Build.Part(name, size, cf * localCF, color, mat, m, opts)
	end
	local black = Color3.fromRGB(16, 15, 16)
	local skin = Color3.fromRGB(222, 212, 198)
	-- corpo alto e magro demais
	part("Saia", Vector3.new(2.6, 3.4, 2.4), CFrame.new(0, 1.7, 0), black, M.Fabric)
	part("Tronco", Vector3.new(1.7, 3, 1.1), CFrame.new(0, 4.9, 0), black, M.Fabric)
	part("Avental", Vector3.new(1.5, 4.2, 0.1), CFrame.new(0, 3.2, -0.62), Color3.fromRGB(232, 228, 216), M.Fabric)
	part("Gola", Vector3.new(1.4, 0.25, 1), CFrame.new(0, 6.45, 0), Color3.fromRGB(232, 228, 216), M.Fabric)
	part("Pescoco", Vector3.new(0.45, 1.1, 0.45), CFrame.new(0, 7.1, 0), skin, M.SmoothPlastic)
	local head = part("Cabeca", Vector3.new(1.35, 1.9, 1.35), CFrame.new(0, 8.4, 0), skin, M.SmoothPlastic, { shape = Enum.PartType.Ball })
	head.Size = Vector3.new(1.5, 1.5, 1.5)
	part("Rosto", Vector3.new(1.3, 1.6, 1.1), CFrame.new(0, 8.35, -0.15), skin, M.SmoothPlastic)
	part("Touca", Vector3.new(1.4, 0.35, 0.9), CFrame.new(0, 9.25, 0.05) * CFrame.Angles(math.rad(-15), 0, 0), Color3.fromRGB(240, 236, 226), M.Fabric)
	-- braços longos demais segurando o carrinho
	for _, x in ipairs({ -1.05, 1.05 }) do
		part("Braco", Vector3.new(0.35, 3.8, 0.35), CFrame.new(x, 5.4, -1.3) * CFrame.Angles(math.rad(62), 0, 0), black, M.Fabric)
		part("Mao", Vector3.new(0.4, 0.9, 0.3), CFrame.new(x, 4.4, -3.05), skin, M.SmoothPlastic)
	end
	-- carrinho enferrujado
	local rust = Color3.fromRGB(110, 62, 36)
	part("CarrinhoCorpo", Vector3.new(3, 1.6, 3.6), CFrame.new(0, 1.5, -5), rust, M.CorrodedMetal)
	part("CarrinhoTopo", Vector3.new(3, 0.2, 3.6), CFrame.new(0, 3.4, -5), rust, M.CorrodedMetal)
	part("CarrinhoBarra", Vector3.new(2.8, 0.2, 0.2), CFrame.new(0, 4.3, -3.2), Color3.fromRGB(40, 30, 24), M.Metal)
	part("Lencois", Vector3.new(2.4, 0.9, 2.6), CFrame.new(0, 3.95, -5.2), Color3.fromRGB(150, 138, 120), M.Fabric)
	m.PrimaryPart = m:FindFirstChild("Saia")
	-- som do carrinho dela
	Build.Sound(m.PrimaryPart, Config.Sounds.TrolleySqueak, { name = "Rangido", volume = 1.4, looped = true, maxDistance = 90, speed = 1.35, play = true })
	local light = Build.Light(head, "PointLight", Color3.fromRGB(255, 150, 60), 10, 0.6)
	light.Name = "Brilho"
	return m
end

local function distXZ(a, b)
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

-- O jogador cumpre a regra?
local function isSafe(player)
	if player:GetAttribute("Escondido") then
		return true, nil
	end
	if Noise.Speed(player) > MC.StillSpeed then
		return false, "Você se moveu enquanto ela passava."
	end
	if Noise.Get(player) > 8 then
		return false, "Ela ouviu você."
	end
	if not State.IsCleaning(player) then
		return false, "Você não estava limpando."
	end
	return true, nil
end

function Maid.Cancel()
	token += 1
	if active and active.Model then
		active.Model:Destroy()
	end
	if active then
		workspace:SetAttribute("Ameaca", "")
		active.Floor.Model:SetAttribute("Luzes", "Normal")
	end
	active = nil
end

function Maid.IsActive()
	return active ~= nil
end

-- Dispara a Camareira no andar agora
function Maid.Trigger(floor, playersOnFloor)
	if active then
		return
	end
	token += 1
	local myToken = token
	active = { Floor = floor }
	-- aviso
	workspace:SetAttribute("Ameaca", "CamareiraAviso")
	workspace:SetAttribute("AmeacaPos", floor.Path[1])
	floor.Model:SetAttribute("Luzes", "Ambar")
	local warnPart = Build.Deco("RangidoAviso", Vector3.new(1, 1, 1), CFrame.new(floor.Path[1] + Vector3.new(0, 4, 0)), Color3.new(), M.SmoothPlastic, floor.Model, { transp = 1 })
	local squeak = Build.Sound(warnPart, Config.Sounds.TrolleySqueak, { volume = 0.2, looped = true, maxDistance = 400, minDistance = 40, speed = 1.35, play = true })
	local t0 = os.clock()
	while os.clock() - t0 < MC.WarningSeconds do
		if myToken ~= token then
			warnPart:Destroy()
			return
		end
		squeak.Volume = 0.2 + (os.clock() - t0) / MC.WarningSeconds * 1.2
		task.wait(0.1)
	end
	warnPart:Destroy()
	if myToken ~= token then
		return
	end
	-- passagem
	workspace:SetAttribute("Ameaca", "Camareira")
	local path = floor.Path
	local first = path[1]
	local model = buildModel(CFrame.lookAt(first, first + (path[2] - first).Unit))
	model.Parent = floor.Model
	active.Model = model
	local judged = {}
	local step = 1 / MC.Fps
	local pos = first
	for i = 2, #path - 1 do
		local target = path[i]
		while distXZ(pos, target) > 0.05 do
			if myToken ~= token then
				return
			end
			local dir = (target - pos)
			local move = math.min(dir.Magnitude, MC.Speed * step)
			pos += dir.Unit * move
			local up = pos + Vector3.new(0, 1.7, 0)
			model:PivotTo(CFrame.lookAt(up, up + Vector3.new(dir.X, 0, dir.Z).Unit) * CFrame.new(0, 0, 3))
			workspace:SetAttribute("AmeacaPos", pos)
			for _, player in ipairs(playersOnFloor()) do
				if not judged[player] then
					local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
					-- quem está dentro de um elevador não está no corredor dela
					local inElevator = root and (Floors.IsInside(floor.Start, root.Position) or Floors.IsInside(floor.End, root.Position))
					if root and not inElevator and distXZ(root.Position, pos) <= MC.KillRadius then
						judged[player] = true
						local safe, why = isSafe(player)
						if not safe then
							killFn(player, "Atropelado pela Camareira. " .. (why or ""))
						end
					end
				end
			end
			task.wait(step)
		end
	end
	if myToken ~= token then
		return
	end
	-- some no fim do corredor
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Transparency = 1
		end
	end
	task.wait(0.3)
	Maid.Cancel()
end

-- Agenda a Camareira para um andar (chamado quando o grupo chega)
function Maid.Schedule(floor, isCurrent, playersOnFloor, rng)
	local from = MC.DebugFromFloor or MC.FromFloor
	if floor.Number < from or floor.Number > MC.ToFloor or floor.Number >= Config.Run.Floors then
		return
	end
	if not MC.DebugFromFloor and rng:NextNumber() > MC.Chance then
		return
	end
	local delay = rng:NextNumber(MC.FirstDelay[1], MC.FirstDelay[2])
	task.delay(delay, function()
		if isCurrent(floor) and not active then
			Maid.Trigger(floor, playersOnFloor)
		end
	end)
end

return Maid
