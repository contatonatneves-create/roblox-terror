-- Câmera Polaroid (GDD v2, seção 9.2): começa no carrinho com 3 flashes por fita.
-- O flash cega o Instrutor por 3 s, mas carregar e disparar faz ruído 70.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local State = require(script.Parent.State)
local Noise = require(script.Parent.Noise)

local Polaroid = {}
local PC = Config.Polaroid

local flashes = PC.Flashes
local holder = nil -- jogador com a câmera
local tool = nil
local listeners = {}
local availabilityListeners = {}

function Polaroid.OnFlash(fn)
	table.insert(listeners, fn)
end

-- Avisado quando a câmera volta (ou sai) do carrinho
function Polaroid.OnAvailability(fn)
	table.insert(availabilityListeners, fn)
end

local function setAvailable()
	for _, fn in ipairs(availabilityListeners) do
		task.spawn(fn, Polaroid.Available())
	end
end

function Polaroid.Available()
	return tool == nil
end

function Polaroid.Flashes()
	return flashes
end

-- Nova fita: câmera de volta ao carrinho com todos os flashes
function Polaroid.Reset()
	if tool then
		local t = tool
		tool = nil
		holder = nil
		t:Destroy()
	end
	flashes = PC.Flashes
	setAvailable()
end

local function flashLabel()
	return string.format("Polaroid (%d flash%s)", flashes, flashes == 1 and "" or "es")
end

local function build(player)
	local t = State.NewTool("Polaroid", flashLabel())
	local handle = State.HandlePart(t, Vector3.new(1.3, 1, 0.8), Color3.fromRGB(232, 228, 214), Enum.Material.SmoothPlastic)
	State.AttachPart(t, handle, "Lente", Vector3.new(0.55, 0.55, 0.3), CFrame.new(0, 0, -0.5), Color3.fromRGB(20, 20, 22), Enum.Material.Glass)
	State.AttachPart(t, handle, "Faixa", Vector3.new(1.32, 0.18, 0.82), CFrame.new(0, 0.25, 0), Color3.fromRGB(200, 60, 50), Enum.Material.SmoothPlastic)
	local bulb = State.AttachPart(t, handle, "Flash", Vector3.new(0.4, 0.22, 0.1), CFrame.new(0.35, 0.36, -0.42), Color3.fromRGB(240, 240, 255), Enum.Material.Neon)
	local light = Instance.new("PointLight")
	light.Name = "Clarao"
	light.Range = PC.Range
	light.Brightness = 0
	light.Color = Color3.fromRGB(240, 244, 255)
	light.Shadows = true
	light.Parent = bulb
	local shutter = Instance.new("Sound")
	shutter.Name = "Disparo"
	shutter.SoundId = Config.Sounds.Beep
	shutter.PlaybackSpeed = 2.2
	shutter.Volume = 0.8
	shutter.RollOffMaxDistance = 80
	shutter.Parent = handle
	t.GripPos = Vector3.new(0, -0.2, 0.2)
	local last = 0
	t.Activated:Connect(function()
		if not State.CanAct(player) or os.clock() - last < PC.Cooldown then
			return
		end
		last = os.clock()
		if flashes <= 0 then
			State.Notify(player, "Sem flash.")
			return
		end
		flashes -= 1
		t.ToolTip = flashLabel()
		shutter:Play()
		light.Brightness = 9
		task.delay(0.12, function()
			light.Brightness = 0
		end)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local origin = bulb.Position
		local look = root and root.CFrame.LookVector or Vector3.new(0, 0, -1)
		Noise.Emit(origin, PC.Noise, player, "Flash")
		for _, fn in ipairs(listeners) do
			task.spawn(fn, player, origin, look)
		end
		State.Notify(player, flashes > 0 and string.format("Flash! Restam %d.", flashes) or "Último flash usado.")
	end)
	-- se a câmera some (morte, fim da fita), volta para o carrinho
	t.Destroying:Connect(function()
		if tool == t then
			tool = nil
			holder = nil
			setAvailable()
		end
	end)
	return t
end

function Polaroid.Take(player)
	if tool then
		State.Notify(player, "A Polaroid já está com " .. (holder and holder.DisplayName or "alguém") .. ".")
		return
	end
	if not State.CanAct(player) then
		return
	end
	holder = player
	tool = build(player)
	State.Equip(player, tool)
	setAvailable()
	State.Notify(player, flashes > 0 and string.format("Polaroid: %d flash%s.", flashes, flashes == 1 and "" or "es") or "A Polaroid está sem flash.")
end

Players.PlayerRemoving:Connect(function(p)
	if holder == p and tool then
		tool:Destroy()
	end
end)

return Polaroid
