-- Sistema de Ruído (GDD v2, seção 5). O servidor mede o ruído de cada jogador pela velocidade
-- real do personagem, pela superfície do chão e pelos eventos (esbarrões, portas, carrinho).
-- O valor vai para o atributo "Ruido" (0-100), que o OSD mostra no medidor VU.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local State = require(script.Parent.State)

local Noise = {}
local N = Config.Noise
local levels = {}
local bursts = {}
local surfaceCache = {}
local listeners = {}

local HARD = {
	[Enum.Material.Metal] = true,
	[Enum.Material.DiamondPlate] = true,
	[Enum.Material.Wood] = true,
	[Enum.Material.WoodPlanks] = true,
	[Enum.Material.Marble] = true,
	[Enum.Material.CeramicTiles] = true,
	[Enum.Material.Concrete] = true,
	[Enum.Material.Slate] = true,
}

function Noise.OnEmit(fn)
	table.insert(listeners, fn)
end

-- Ruído pontual (esbarrão, porta, flash...). player pode ser nil.
function Noise.Emit(pos, level, player, reason)
	if player then
		bursts[player] = math.max(bursts[player] or 0, level)
	end
	for _, fn in ipairs(listeners) do
		task.spawn(fn, pos, level, player, reason)
	end
end

function Noise.Get(player)
	return levels[player] or 0
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function surfaceFactor(player, root)
	local cache = surfaceCache[player]
	if cache and os.clock() - cache.T < 0.3 then
		return cache.F
	end
	rayParams.FilterDescendantsInstances = { player.Character }
	local hit = workspace:Raycast(root.Position, Vector3.new(0, -7, 0), rayParams)
	local f = 1
	if hit then
		local m = hit.Material
		if m == Enum.Material.Fabric or m == Enum.Material.Carpet then
			f = N.Surface.Carpet
		elseif m == Enum.Material.Water or hit.Instance:GetAttribute("Agua") then
			f = N.Surface.Water
		elseif HARD[m] then
			f = N.Surface.Hard
		end
	end
	surfaceCache[player] = { T = os.clock(), F = f }
	return f
end

local function movementLevel(player, root)
	local v = root.AssemblyLinearVelocity
	local speed = Vector3.new(v.X, 0, v.Z).Magnitude
	local base = 0
	if speed > N.RunSpeed then
		base = N.RunLevel
	elseif speed > N.WalkSpeed then
		base = N.WalkLevel
	elseif speed > N.StillSpeed then
		base = N.CarefulLevel
	end
	local level = base * surfaceFactor(player, root)
	if player:GetAttribute("Empurrando") and speed > N.TrolleyFastSpeed then
		level = math.max(level, N.TrolleyFast)
	end
	return level, speed
end

function Noise.Speed(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return 0
	end
	local v = root.AssemblyLinearVelocity
	return Vector3.new(v.X, 0, v.Z).Magnitude
end

---------------------------------------------------------------- esbarrões
local function characterOf(part)
	local model = part:FindFirstAncestorOfClass("Model")
	while model do
		local p = Players:GetPlayerFromCharacter(model)
		if p then
			return p, model
		end
		model = model.Parent and model.Parent:FindFirstAncestorOfClass("Model")
	end
	return nil
end

local function watchProp(prop)
	if not prop:IsA("BasePart") then
		return
	end
	local last = 0
	prop.Touched:Connect(function(hit)
		if os.clock() - last < 1 then
			return
		end
		local player = characterOf(hit)
		if not player or not State.IsActive(player) then
			return
		end
		if Noise.Speed(player) < N.BumpSpeed then
			return
		end
		last = os.clock()
		local s = Instance.new("Sound")
		s.SoundId = Config.Sounds.Bump
		s.Volume = 0.8
		s.RollOffMaxDistance = 60
		s.PlaybackSpeed = 0.9 + math.random() * 0.4
		s.Parent = prop
		s:Play()
		game:GetService("Debris"):AddItem(s, 3)
		Noise.Emit(prop.Position, N.Bump, player, "Esbarrao")
	end)
end

---------------------------------------------------------------- loop
function Noise.Init()
	for _, p in ipairs(CollectionService:GetTagged("Ruidoso")) do
		watchProp(p)
	end
	CollectionService:GetInstanceAddedSignal("Ruidoso"):Connect(watchProp)

	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 0.1 then
			return
		end
		local step = acc
		acc = 0
		for _, player in ipairs(Players:GetPlayers()) do
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			local level = 0
			if root and State.IsActive(player) and not player:GetAttribute("Escondido") then
				local move = movementLevel(player, root)
				if player:GetAttribute("PassosPesados") then
					move *= 2
				end
				local burst = math.max((bursts[player] or 0) - N.DecayPerSecond * step, 0)
				bursts[player] = burst
				level = math.max((levels[player] or 0) - N.DecayPerSecond * step, move, burst)
			else
				bursts[player] = 0
			end
			level = math.clamp(level, 0, N.Max)
			levels[player] = level
			local shown = math.floor(level + 0.5)
			if player:GetAttribute("Ruido") ~= shown then
				player:SetAttribute("Ruido", shown)
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(p)
		levels[p] = nil
		bursts[p] = nil
		surfaceCache[p] = nil
	end)
end

return Noise
