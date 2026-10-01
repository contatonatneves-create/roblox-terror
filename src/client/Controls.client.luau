-- Controles e ambiente do cliente: correr / andar com cuidado, soltar o carrinho, sair do esconderijo,
-- botões de celular, voz robótica das TVs, luzes que piscam (e ficam âmbar) e sons de ameaça.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local player = Players.LocalPlayer

local GREEN = Color3.fromRGB(96, 255, 140)
local FONT = Enum.Font.Arcade

---------------------------------------------------------------- modos de movimento
local careful = false
local running = false

local function sendMode()
	local mode = "Andar"
	if running and not careful then
		mode = "Correr"
	elseif careful then
		mode = "Cuidado"
	end
	remotes.Movimento:FireServer(mode)
end

local function setRunning(on)
	if running ~= on then
		running = on
		sendMode()
	end
end

local function toggleCareful()
	careful = not careful
	sendMode()
end

---------------------------------------------------------------- interface (botões de contexto)
local gui = Instance.new("ScreenGui")
gui.Name = "Controles"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 12
gui.Parent = player:WaitForChild("PlayerGui")

local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do
		o[k] = v
	end
	o.Parent = parent
	return o
end

local function osdButton(name, text, pos, size)
	local b = new("TextButton", { Name = name, AnchorPoint = Vector2.new(1, 1), Position = pos, Size = size or UDim2.fromOffset(150, 44), BackgroundColor3 = Color3.fromRGB(8, 12, 8), BackgroundTransparency = 0.25, Font = FONT, Text = text, TextScaled = true, TextColor3 = GREEN, AutoButtonColor = true }, gui)
	new("UIStroke", { Color = GREEN, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, b)
	new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6) }, b)
	return b
end

local touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local releaseBtn = osdButton("Soltar", touch and "SOLTAR" or "SOLTAR [Q]", UDim2.new(1, -42, 1, -150), UDim2.fromOffset(190, 44))
releaseBtn.Visible = false
local unhideBtn = osdButton("Sair", touch and "SAIR DO CARRINHO" or "SAIR [Q]", UDim2.new(1, -42, 1, -150), UDim2.fromOffset(240, 44))
unhideBtn.Visible = false
local runBtn = osdButton("Correr", "CORRER", UDim2.new(1, -200, 1, -210))
local carefulBtn = osdButton("Cuidado", "CUIDADO", UDim2.new(1, -200, 1, -262))
runBtn.Visible = touch
carefulBtn.Visible = touch

releaseBtn.Activated:Connect(function()
	remotes.SoltarCarrinho:FireServer()
end)
unhideBtn.Activated:Connect(function()
	remotes.SairEsconderijo:FireServer()
end)
runBtn.MouseButton1Down:Connect(function()
	setRunning(true)
end)
runBtn.MouseButton1Up:Connect(function()
	setRunning(false)
end)
carefulBtn.Activated:Connect(function()
	toggleCareful()
	carefulBtn.TextColor3 = careful and Color3.fromRGB(255, 214, 70) or GREEN
end)

-- escuro dentro da portinhola
local hideShade = new("Frame", { Name = "Escuro", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.25, Visible = false, ZIndex = 0 }, gui)
new("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.new(0.6, 0, 0, 30), BackgroundTransparency = 1, Font = FONT, TextScaled = true, TextColor3 = GREEN, Text = "ESCONDIDO NA PORTINHOLA", ZIndex = 1 }, hideShade)

local function refreshButtons()
	local pushing = player:GetAttribute("Empurrando") == true
	local hidden = player:GetAttribute("Escondido") == true
	releaseBtn.Visible = pushing
	unhideBtn.Visible = hidden
	hideShade.Visible = hidden
	local inRun = player:GetAttribute("NaFita") and player:GetAttribute("Vivo")
	runBtn.Visible = touch and not pushing and not hidden
	carefulBtn.Visible = touch and not hidden and inRun == true
end
player:GetAttributeChangedSignal("Empurrando"):Connect(refreshButtons)
player:GetAttributeChangedSignal("Escondido"):Connect(refreshButtons)
player:GetAttributeChangedSignal("Vivo"):Connect(refreshButtons)
player:GetAttributeChangedSignal("NaFita"):Connect(refreshButtons)
refreshButtons()

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then
		return
	end
	local k = input.KeyCode
	if k == Enum.KeyCode.LeftShift or k == Enum.KeyCode.RightShift or k == Enum.KeyCode.ButtonL3 then
		setRunning(true)
	elseif k == Enum.KeyCode.C or k == Enum.KeyCode.ButtonR3 then
		toggleCareful()
	elseif k == Enum.KeyCode.Q or k == Enum.KeyCode.ButtonB then
		if player:GetAttribute("Escondido") then
			remotes.SairEsconderijo:FireServer()
		elseif player:GetAttribute("Empurrando") then
			remotes.SoltarCarrinho:FireServer()
		end
	end
end)
UserInputService.InputEnded:Connect(function(input)
	local k = input.KeyCode
	if k == Enum.KeyCode.LeftShift or k == Enum.KeyCode.RightShift or k == Enum.KeyCode.ButtonL3 then
		setRunning(false)
	end
end)
player:GetAttributeChangedSignal("NaFita"):Connect(function()
	careful = false
	running = false
end)

---------------------------------------------------------------- voz robótica (AudioTextToSpeech)
local ttsOk = Config.Voice.Enabled
local function speak(text)
	if not ttsOk then
		return
	end
	local ok, err = pcall(function()
		local folder = Instance.new("Folder")
		folder.Name = "VozTV"
		local tts = Instance.new("AudioTextToSpeech")
		tts.Text = string.sub(text, 1, 290)
		tts.VoiceId = Config.Voice.VoiceId
		tts.Pitch = Config.Voice.Pitch
		tts.Speed = Config.Voice.Speed
		tts.Volume = 1.6
		tts.Parent = folder
		local dist = Instance.new("AudioDistortion")
		dist.Level = 0.35
		dist.Parent = folder
		local eq = Instance.new("AudioEqualizer")
		eq.LowGain = -18
		eq.MidGain = 4
		eq.HighGain = -10
		eq.Parent = folder
		local out = Instance.new("AudioDeviceOutput")
		out.Parent = folder
		local function wire(a, b)
			local w = Instance.new("Wire")
			w.SourceInstance = a
			w.TargetInstance = b
			w.Parent = folder
		end
		wire(tts, dist)
		wire(dist, eq)
		wire(eq, out)
		folder.Parent = SoundService
		tts:Play()
		tts.Ended:Connect(function()
			folder:Destroy()
		end)
		task.delay(30, function()
			if folder.Parent then
				folder:Destroy()
			end
		end)
	end)
	if not ok then
		warn("[Voz] " .. tostring(err))
	end
end
remotes:WaitForChild("Falar").OnClientEvent:Connect(speak)

---------------------------------------------------------------- sons pedidos pelo servidor
local function play2D(id, volume, speed)
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = volume or 0.6
	s.PlaybackSpeed = speed or 1
	s.Parent = SoundService
	s:Play()
	game:GetService("Debris"):AddItem(s, 15)
	return s
end
remotes:WaitForChild("Som").OnClientEvent:Connect(function(name)
	local id = Config.Sounds[name]
	if id then
		play2D(id, 0.7)
	end
end)

-- estática que cresce enquanto a Camareira está por perto
local staticLoop = Instance.new("Sound")
staticLoop.Name = "EstaticaAmeaca"
staticLoop.SoundId = Config.Sounds.Static
staticLoop.Looped = true
staticLoop.Volume = 0
staticLoop.Parent = SoundService
staticLoop:Play()

---------------------------------------------------------------- luzes
local AMBER = Color3.fromRGB(255, 150, 50)
local lights = {}
local function track(fixture)
	local light = fixture:FindFirstChildWhichIsA("Light")
	lights[fixture] = { Light = light, Base = light and light.Brightness or 1, Color = fixture.Color, LightColor = light and light.Color, Seed = math.random() * 100 }
end
for _, tag in ipairs({ "LuzAndar", "LuzLobby" }) do
	for _, f in ipairs(CollectionService:GetTagged(tag)) do
		track(f)
	end
	CollectionService:GetInstanceAddedSignal(tag):Connect(track)
	CollectionService:GetInstanceRemovedSignal(tag):Connect(function(f)
		lights[f] = nil
	end)
end

local function floorModelOf(fixture)
	local m = fixture:FindFirstAncestorOfClass("Model")
	while m and not m.Name:match("^Andar%d+$") do
		m = m.Parent and m.Parent:FindFirstAncestorOfClass("Model")
	end
	return m
end

---------------------------------------------------------------- loop
local acc = 0
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < 1 / 20 then
		return
	end
	local step = acc
	acc = 0
	local t = os.clock()
	local threat = workspace:GetAttribute("Ameaca") or ""
	-- luzes
	for fixture, info in pairs(lights) do
		if fixture.Parent and info.Light then
			local floor = fixture:GetAttribute("Andar") and floorModelOf(fixture)
			local amber = floor and floor:GetAttribute("Luzes") == "Ambar"
			local level = 1
			if fixture:GetAttribute("Pisca") then
				local n = math.noise(t * 4, info.Seed)
				level = n > 0.25 and 0.1 or 1
			end
			if amber then
				level = (math.noise(t * 9, info.Seed) > -0.1) and 0.9 or 0.15
				info.Light.Color = AMBER
				fixture.Color = AMBER
			else
				info.Light.Color = info.LightColor
				fixture.Color = info.Color
			end
			info.Light.Brightness = info.Base * level
			fixture.Transparency = level < 0.3 and 0.6 or 0
		end
	end
	-- estática de ameaça
	local targetVol = (threat == "CamareiraAviso" and 0.35) or (threat == "Camareira" and 0.55) or 0
	if not player:GetAttribute("NaFita") then
		targetVol = 0
	end
	staticLoop.Volume += (targetVol - staticLoop.Volume) * math.min(1, step * 3)
	-- rangido do carrinho conforme a velocidade
	local cart = workspace:FindFirstChild("CarrinhoServico")
	local body = cart and cart:FindFirstChild("Corpo")
	local squeak = body and body:FindFirstChild("Rangido")
	if squeak then
		local v = body.AssemblyLinearVelocity
		local speed = Vector3.new(v.X, 0, v.Z).Magnitude
		squeak.Volume = math.clamp(speed / 16, 0, 1) * 0.55
		squeak.PlaybackSpeed = 0.85 + math.clamp(speed / 20, 0, 0.5)
	end
end)
