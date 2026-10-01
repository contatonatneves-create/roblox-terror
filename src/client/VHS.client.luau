-- Filtro VHS, OSD da filmadora, tela azul, transições e espectador (GDD v2, seções 4 e 6.6).
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local GREEN = Color3.fromRGB(96, 255, 140)
local OSD_FONT = Enum.Font.Arcade
local TEXT_FONT = Enum.Font.Code

---------------------------------------------------------------- pós-processamento
local function effect(class, name, props)
	local e = Lighting:FindFirstChild(name) or Instance.new(class)
	e.Name = name
	for k, v in pairs(props) do
		e[k] = v
	end
	e.Parent = Lighting
	return e
end
local cc = effect("ColorCorrectionEffect", "VHSCor", { Saturation = -0.35, Contrast = 0.18, Brightness = 0.02, TintColor = Color3.fromRGB(236, 242, 255) })
local blur = effect("BlurEffect", "VHSDesfoque", { Size = 1.5 })
effect("BloomEffect", "VHSBrilho", { Intensity = 0.7, Size = 26, Threshold = 1.15 })

---------------------------------------------------------------- tela
local gui = Instance.new("ScreenGui")
gui.Name = "VHS"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 10
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do
		o[k] = v
	end
	o.Parent = parent
	return o
end

local overlay = new("Frame", { Name = "Camada", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 1 }, gui)

-- linhas de varredura
local scan = new("Frame", { Name = "Varredura", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 2 }, overlay)
for i = 0, 179 do
	new("Frame", { Position = UDim2.fromScale(0, i / 180), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.86, BorderSizePixel = 0, ZIndex = 2 }, scan)
end

-- vinheta e bordas arredondadas de CRT
local function edge(pos, size, rotation)
	local f = new("Frame", { Position = pos, Size = size, BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 3 }, overlay)
	new("UIGradient", { Rotation = rotation, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 1) }) }, f)
	return f
end
edge(UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.22), 90)
edge(UDim2.fromScale(0, 0.78), UDim2.fromScale(1, 0.22), 270)
edge(UDim2.fromScale(0, 0), UDim2.fromScale(0.16, 1), 0)
edge(UDim2.fromScale(0.84, 0), UDim2.fromScale(0.16, 1), 180)
local crt = new("Frame", { Name = "CRT", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -16, 1, -16), BackgroundTransparency = 1, ZIndex = 4 }, overlay)
new("UICorner", { CornerRadius = UDim.new(0, 46) }, crt)
new("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 30, Transparency = 0 }, crt)

-- faixa de tracking
local band = new("Frame", { Name = "Tracking", Size = UDim2.new(1, 0, 0.05, 0), Position = UDim2.fromScale(0, -0.1), BackgroundColor3 = Color3.fromRGB(230, 230, 230), BackgroundTransparency = 0.88, BorderSizePixel = 0, ZIndex = 5 }, overlay)
new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.3), NumberSequenceKeypoint.new(1, 1) }) }, band)

-- estática (pontos e riscos que mudam a cada quadro)
local noiseLayer = new("Frame", { Name = "Estatica", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 6 }, overlay)
local grains = {}
for i = 1, 140 do
	grains[i] = new("Frame", { Size = UDim2.fromOffset(3, 2), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, BackgroundTransparency = 1, ZIndex = 6 }, noiseLayer)
end
local fullStatic = new("Frame", { Name = "EstaticaCheia", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(70, 70, 70), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 7 }, overlay)

---------------------------------------------------------------- OSD
local osd = new("Frame", { Name = "OSD", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 20 }, gui)

-- texto com sangramento vermelho/azul
local function osdText(name, props)
	local holder = new("Frame", { Name = name, BackgroundTransparency = 1, Position = props.Position, Size = props.Size, AnchorPoint = props.AnchorPoint or Vector2.zero, ZIndex = 20 }, osd)
	local function label(color, offset, z, transp)
		return new("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(offset, 0),
			Size = UDim2.fromScale(1, 1),
			Font = props.Font or OSD_FONT,
			TextColor3 = color,
			TextTransparency = transp,
			TextScaled = true,
			TextXAlignment = props.AlignX or Enum.TextXAlignment.Left,
			TextYAlignment = props.AlignY or Enum.TextYAlignment.Center,
			Text = props.Text or "",
			ZIndex = z,
		}, holder)
	end
	local r = label(Color3.fromRGB(255, 60, 80), -2, 20, 0.55)
	local b = label(Color3.fromRGB(70, 120, 255), 2, 20, 0.55)
	local main = label(props.Color or GREEN, 0, 21, 0)
	local obj = { Holder = holder, Labels = { r, b, main }, Main = main }
	function obj:Set(text)
		for _, l in ipairs(self.Labels) do
			l.Text = text
		end
	end
	function obj:Color(c)
		self.Main.TextColor3 = c
	end
	return obj
end

local playText = osdText("Play", { Position = UDim2.new(0, 42, 0, 34), Size = UDim2.new(0, 220, 0, 30) })
local timeText = osdText("Tempo", { Position = UDim2.new(0, 42, 0, 70), Size = UDim2.new(0, 220, 0, 26) })
local floorText = osdText("Andar", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -42, 0, 34), Size = UDim2.new(0, 300, 0, 30), AlignX = Enum.TextXAlignment.Right })
local phaseText = osdText("Fase", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -42, 0, 70), Size = UDim2.new(0, 300, 0, 20), AlignX = Enum.TextXAlignment.Right })
local tasksText = osdText("Tarefas", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -42, 1, -40), Size = UDim2.new(0, 420, 0, 74), Font = TEXT_FONT, AlignX = Enum.TextXAlignment.Right, AlignY = Enum.TextYAlignment.Bottom })
for _, l in ipairs(tasksText.Labels) do
	l.TextScaled = false
	l.TextSize = 16
	l.TextWrapped = true
end

-- medidor VU (ruído do próprio jogador)
local vu = new("Frame", { Name = "VU", Position = UDim2.new(0, 42, 1, -92), Size = UDim2.new(0, 260, 0, 54), BackgroundTransparency = 1, ZIndex = 20 }, osd)
new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(0, 120, 0, 14), Font = OSD_FONT, TextScaled = true, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = GREEN, Text = "AUDIO", ZIndex = 21 }, vu)
local bars = {}
for row = 0, 1 do
	new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 20 + row * 18), Size = UDim2.new(0, 12, 0, 12), Font = OSD_FONT, TextScaled = true, TextColor3 = GREEN, Text = row == 0 and "L" or "R", ZIndex = 21 }, vu)
	bars[row] = {}
	for i = 1, 16 do
		local color = i <= 9 and GREEN or (i <= 13 and Color3.fromRGB(255, 214, 70) or Color3.fromRGB(255, 70, 60))
		bars[row][i] = new("Frame", { Position = UDim2.new(0, 18 + (i - 1) * 14, 0, 20 + row * 18), Size = UDim2.new(0, 11, 0, 12), BackgroundColor3 = color, BackgroundTransparency = 0.8, BorderSizePixel = 0, ZIndex = 21 }, vu)
	end
end

-- avisos (texto no meio, embaixo)
local toast = osdText("Aviso", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -150), Size = UDim2.new(0, 640, 0, 26), Font = TEXT_FONT, AlignX = Enum.TextXAlignment.Center })
local toastToken = nil
local function showToast(text, seconds)
	toast:Set(text)
	toast.Holder.Visible = true
	local t = {}
	toastToken = t
	task.delay(seconds or 3, function()
		if toastToken == t then
			toast.Holder.Visible = false
		end
	end)
end
toast.Holder.Visible = false
remotes:WaitForChild("Aviso").OnClientEvent:Connect(function(text)
	showToast(string.upper(text), 3.5)
end)

-- legenda das falas da TV (Fita Legendada)
local caption = new("TextLabel", { Name = "Legenda", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -190), Size = UDim2.new(0, 760, 0, 46), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.35, Font = TEXT_FONT, TextColor3 = Color3.fromRGB(240, 240, 220), TextSize = 18, TextWrapped = true, Visible = false, ZIndex = 22 }, gui)
local captionToken
remotes:WaitForChild("Falar").OnClientEvent:Connect(function(text)
	caption.Text = "[TV] " .. text
	caption.Visible = true
	local t = {}
	captionToken = t
	task.delay(math.clamp(#text * 0.07, 3, 9), function()
		if captionToken == t then
			caption.Visible = false
		end
	end)
end)

---------------------------------------------------------------- telas cheias (morte, check-out, fita rejeitada)
local screen = new("Frame", { Name = "TelaCheia", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(16, 30, 180), Visible = false, ZIndex = 40 }, gui)
local screenTitle = new("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.new(0.8, 0, 0, 56), BackgroundTransparency = 1, Font = OSD_FONT, TextColor3 = Color3.new(1, 1, 1), TextScaled = true, ZIndex = 41 }, screen)
local screenBody = new("TextLabel", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.52), Size = UDim2.new(0.7, 0, 0, 140), BackgroundTransparency = 1, Font = TEXT_FONT, TextColor3 = Color3.fromRGB(230, 230, 255), TextSize = 22, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 41 }, screen)
local screenCorner = new("TextLabel", { Position = UDim2.new(0, 42, 0, 34), Size = UDim2.new(0, 260, 0, 30), BackgroundTransparency = 1, Font = OSD_FONT, TextColor3 = Color3.new(1, 1, 1), TextScaled = true, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 41 }, screen)

local function showScreen(color, corner, title, body, seconds)
	screen.BackgroundColor3 = color
	screenCorner.Text = corner
	screenTitle.Text = title
	screenBody.Text = body or ""
	screen.Visible = true
	if seconds then
		task.delay(seconds, function()
			screen.Visible = false
		end)
	end
end

---------------------------------------------------------------- som 2D
local function playSound(id, volume, speed)
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = volume or 0.6
	s.PlaybackSpeed = speed or 1
	s.Parent = gui
	s:Play()
	game:GetService("Debris"):AddItem(s, 12)
	return s
end

---------------------------------------------------------------- intensidade da distorção
local glitch = 0.05
local forcedGlitch = 0

local function threatLevel()
	local a = workspace:GetAttribute("Ameaca")
	if not a or a == "" then
		return 0
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local pos = workspace:GetAttribute("AmeacaPos")
	local near = 0
	if root and typeof(pos) == "Vector3" then
		near = math.clamp(1 - (root.Position - pos).Magnitude / 60, 0, 1)
	end
	if a == "CamareiraAviso" then
		return 0.35 + near * 0.3
	end
	return 0.3 + near * 0.6
end

---------------------------------------------------------------- transições
local transitioning = false
local function staticBurst(seconds, level)
	forcedGlitch = level
	fullStatic.BackgroundTransparency = 0.15
	task.delay(seconds, function()
		forcedGlitch = 0
		TweenService:Create(fullStatic, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
	end)
end

remotes:WaitForChild("Transicao").OnClientEvent:Connect(function(kind, data)
	if kind == "Entrar" then
		transitioning = true
		local lobby = workspace:FindFirstChild("SalaDeDescanso")
		local tv = lobby and lobby:FindFirstChild("Tela")
		if tv then
			camera.CameraType = Enum.CameraType.Scriptable
			local goal = tv.CFrame * CFrame.new(0, 0, 1.2) * CFrame.Angles(0, math.pi, 0)
			TweenService:Create(camera, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = goal }):Play()
		end
		playSound(Config.Sounds.Static, 0.5)
		task.wait(1.1)
		staticBurst(1.2, 1)
		task.wait(0.6)
		camera.CameraType = Enum.CameraType.Custom
		transitioning = false
	elseif kind == "Subir" then
		playSound(Config.Sounds.Rewind, 0.7)
		staticBurst(Config.Run.ElevatorRideSeconds * 0.8, 0.8)
		playText:Set("▶▶ FF")
		task.delay(Config.Run.ElevatorRideSeconds + 0.2, function()
			playText:Set("PLAY ▶")
		end)
	elseif kind == "CheckOut" then
		local d = data or {}
		playSound(Config.Sounds.Ding, 0.7)
		task.wait(1)
		showScreen(Color3.fromRGB(6, 8, 6), "■ STOP", "CHECK-OUT CONCLUÍDO",
			string.format("TEMPO DA FITA  %s\nANDARES  %d/%d\nSOBREVIVENTES  %d\n\nVOCÊ FOI ARQUIVADO COM SUCESSO.", Config.FormatTime(d.Tempo or 0), d.Andares or 0, Config.Run.Floors, d.Vivos or 0),
			Config.Run.ReturnToLobbyDelay + 1)
		screenTitle.TextColor3 = GREEN
	elseif kind == "Rejeitada" then
		playSound(Config.Sounds.TvOff, 0.7)
		task.wait(Config.Death.BlueScreenSeconds - 0.5)
		showScreen(Color3.fromRGB(6, 6, 8), "⏏ EJECT", "FITA REJEITADA", "NINGUÉM SOBREVIVEU AO TURNO.\nPEGUE OUTRA FITA NA ESTANTE.", Config.Run.ReturnToLobbyDelay)
		screenTitle.TextColor3 = Color3.fromRGB(255, 90, 80)
	end
end)

---------------------------------------------------------------- morte e espectador
local spectating = false
local spectateIndex = 1
local specBar = new("Frame", { Name = "Espectador", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -30), Size = UDim2.new(0, 520, 0, 56), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.4, Visible = false, ZIndex = 30 }, gui)
local specName = new("TextLabel", { Position = UDim2.new(0, 70, 0, 0), Size = UDim2.new(1, -230, 1, 0), BackgroundTransparency = 1, Font = OSD_FONT, TextScaled = true, TextColor3 = GREEN, ZIndex = 31 }, specBar)
local prevBtn = new("TextButton", { Size = UDim2.new(0, 56, 1, 0), BackgroundTransparency = 1, Font = OSD_FONT, Text = "◀", TextScaled = true, TextColor3 = GREEN, ZIndex = 31 }, specBar)
local nextBtn = new("TextButton", { Position = UDim2.new(1, -216, 0, 0), Size = UDim2.new(0, 56, 1, 0), BackgroundTransparency = 1, Font = OSD_FONT, Text = "▶", TextScaled = true, TextColor3 = GREEN, ZIndex = 31 }, specBar)
local leaveBtn = new("TextButton", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 8), Size = UDim2.new(0, 140, 1, -16), BackgroundColor3 = Color3.fromRGB(30, 30, 30), Font = OSD_FONT, Text = "SAIR", TextScaled = true, TextColor3 = Color3.new(1, 1, 1), ZIndex = 31 }, specBar)

local function aliveMates()
	local list = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and p:GetAttribute("NaFita") and p:GetAttribute("Vivo") then
			local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then
				table.insert(list, { Player = p, Humanoid = hum })
			end
		end
	end
	return list
end

local function stopSpectate()
	spectating = false
	specBar.Visible = false
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		camera.CameraSubject = hum
	end
end

local function updateSpectate()
	if not spectating then
		return
	end
	local mates = aliveMates()
	if #mates == 0 or workspace:GetAttribute("FitaEstado") ~= "Rodando" then
		stopSpectate()
		return
	end
	spectateIndex = ((spectateIndex - 1) % #mates) + 1
	local m = mates[spectateIndex]
	camera.CameraSubject = m.Humanoid
	specName.Text = "ASSISTINDO: " .. string.upper(m.Player.DisplayName)
end

prevBtn.Activated:Connect(function()
	spectateIndex -= 1
	updateSpectate()
end)
nextBtn.Activated:Connect(function()
	spectateIndex += 1
	updateSpectate()
end)
leaveBtn.Activated:Connect(stopSpectate)

remotes:WaitForChild("FimTransmissao").OnClientEvent:Connect(function(reason)
	playSound(Config.Sounds.TvOff, 0.8)
	showScreen(Color3.fromRGB(16, 30, 180), "■ STOP", "FIM DE TRANSMISSÃO", string.upper(reason or ""), Config.Death.BlueScreenSeconds)
	screenTitle.TextColor3 = Color3.new(1, 1, 1)
	task.delay(Config.Death.BlueScreenSeconds, function()
		if workspace:GetAttribute("FitaEstado") == "Rodando" and #aliveMates() > 0 then
			spectating = true
			specBar.Visible = true
			updateSpectate()
		end
	end)
end)

player.CharacterAdded:Connect(function()
	task.wait(0.2)
	if spectating then
		updateSpectate()
	end
end)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp or not spectating then
		return
	end
	if input.KeyCode == Enum.KeyCode.Left then
		spectateIndex -= 1
		updateSpectate()
	elseif input.KeyCode == Enum.KeyCode.Right then
		spectateIndex += 1
		updateSpectate()
	end
end)

---------------------------------------------------------------- loop
local rng = Random.new()
local acc = 0
local bandY = -0.1
local lastSpecCheck = 0

local function glitchDigits(s, amount)
	if amount < 0.35 then
		return s
	end
	local out = {}
	for i = 1, #s do
		local ch = s:sub(i, i)
		if ch:match("%d") and rng:NextNumber() < (amount - 0.3) then
			ch = ({ "#", "%", "?", "/", "8", "0" })[rng:NextInteger(1, 6)]
		end
		table.insert(out, ch)
	end
	return table.concat(out)
end

RunService.RenderStepped:Connect(function(dt)
	acc += dt
	if acc < 1 / 30 then
		return
	end
	acc = 0
	local running = workspace:GetAttribute("FitaEstado") == "Rodando" and player:GetAttribute("NaFita") and player:GetAttribute("Vivo")
	-- nível de distorção
	local target = 0.05 + threatLevel()
	if player:GetAttribute("Escondido") then
		target += 0.1
	end
	target = math.max(target, forcedGlitch)
	glitch += (target - glitch) * 0.15
	-- estática
	local count = math.floor(#grains * math.clamp(glitch, 0, 1))
	for i, g in ipairs(grains) do
		if i <= count then
			g.Position = UDim2.fromScale(rng:NextNumber(), rng:NextNumber())
			g.Size = UDim2.fromOffset(rng:NextInteger(2, 7 + math.floor(glitch * 30)), rng:NextInteger(1, 3))
			local v = rng:NextNumber(0.5, 1)
			g.BackgroundColor3 = Color3.new(v, v, v)
			g.BackgroundTransparency = rng:NextNumber(0.2, 0.7)
		else
			g.BackgroundTransparency = 1
		end
	end
	-- faixa de tracking descendo
	bandY += dt * 0 + (1 / 30) * (0.18 + glitch * 0.8)
	if bandY > 1.1 then
		bandY = -0.15 - rng:NextNumber() * (glitch > 0.3 and 0.2 or 2.5)
	end
	band.Position = UDim2.fromScale(rng:NextNumber() * glitch * 0.02, bandY)
	band.BackgroundTransparency = 0.9 - glitch * 0.4
	cc.Saturation = -0.35 - glitch * 0.3
	blur.Size = 1.5 + glitch * 3
	-- OSD
	local state = workspace:GetAttribute("FitaEstado")
	if state == "Rodando" and player:GetAttribute("NaFita") then
		if playText.Main.Text ~= "▶▶ FF" then
			playText:Set(running and "PLAY ▶" or "STOP ■")
		end
		local started = workspace:GetAttribute("FitaInicio") or workspace:GetServerTimeNow()
		timeText:Set(glitchDigits(Config.FormatTime(workspace:GetServerTimeNow() - started), glitch))
		local n = workspace:GetAttribute("Andar") or 0
		floorText:Set(string.format("ANDAR %02d/%02d", n, workspace:GetAttribute("AndarTotal") or Config.Run.Floors))
		phaseText:Set(string.upper(workspace:GetAttribute("Fase") or ""))
		tasksText:Set(running and (workspace:GetAttribute("Tarefas") or "") or "")
	else
		playText:Set(state == "Contagem" and "REW ◀◀" or "STOP ■")
		timeText:Set("00:00:00")
		floorText:Set("SALA DE DESCANSO")
		phaseText:Set(state == "Contagem" and ("INICIANDO " .. tostring(workspace:GetAttribute("Contagem") or "")) or "AETHELGARD HOSPITALITY")
		tasksText:Set("")
	end
	-- VU
	local noise = (player:GetAttribute("Ruido") or 0) / 100
	for row = 0, 1 do
		local lit = math.floor(noise * 16 + (row == 1 and rng:NextNumber() * 1.2 or 0))
		for i, b in ipairs(bars[row]) do
			b.BackgroundTransparency = i <= lit and 0.05 or 0.8
		end
	end
	vu.Visible = running == true
	-- espectador: confere de tempos em tempos se o alvo ainda está vivo
	if spectating and os.clock() - lastSpecCheck > 1 then
		lastSpecCheck = os.clock()
		local subject = camera.CameraSubject
		if not subject or not subject.Parent or (subject:IsA("Humanoid") and subject.Health <= 0) then
			updateSpectate()
		end
	end
end)
