-- Lado do cliente das entidades da Etapa 2 (GDD v2, seção 7):
-- Cobrir os Olhos (Instrutor), olhar medido pela câmera, rosto tomando a tela, botão Dizer
-- (Hóspede do 302) e a cegueira de estática do Falso Colega.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local GREEN = Color3.fromRGB(96, 255, 140)
local FONT = Enum.Font.Arcade
local TC = Config.Trainer

local gui = Instance.new("ScreenGui")
gui.Name = "Entidades"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 11 -- acima do filtro VHS (10), abaixo dos botões (12)
gui.Parent = player:WaitForChild("PlayerGui")

local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do
		o[k] = v
	end
	o.Parent = parent
	return o
end

local function inRun()
	return player:GetAttribute("NaFita") == true and player:GetAttribute("Vivo") == true
end

---------------------------------------------------------------- botões de contexto
local touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local function osdButton(name, text, pos, size)
	local b = new("TextButton", { Name = name, AnchorPoint = Vector2.new(1, 1), Position = pos, Size = size, BackgroundColor3 = Color3.fromRGB(8, 12, 8), BackgroundTransparency = 0.25, Font = FONT, Text = text, TextScaled = true, TextColor3 = GREEN, AutoButtonColor = true, Visible = false, ZIndex = 5 }, gui)
	new("UIStroke", { Color = GREEN, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, b)
	new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6) }, b)
	return b
end

local coverBtn = osdButton("CobrirOlhos", touch and "COBRIR OLHOS" or "COBRIR OLHOS [V]", UDim2.new(1, -42, 1, -314), UDim2.fromOffset(240, 44))
local sayBtn = osdButton("Dizer", touch and "DIZER A FRASE" or "DIZER A FRASE [G]", UDim2.new(0.5, 150, 1, -230), UDim2.fromOffset(300, 54))
sayBtn.AnchorPoint = Vector2.new(0.5, 1)
sayBtn.Position = UDim2.new(0.5, 0, 1, -230)

---------------------------------------------------------------- cobrir os olhos
local covered = false
-- quase preto, só as bordas da visão
-- fica abaixo do filtro VHS (o OSD da filmadora continua visível)
local shadeGui = Instance.new("ScreenGui")
shadeGui.Name = "OlhosCobertos"
shadeGui.ResetOnSpawn = false
shadeGui.IgnoreGuiInset = true
shadeGui.DisplayOrder = 9
shadeGui.Parent = player:WaitForChild("PlayerGui")
local shade = new("Frame", { Name = "Mao", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, ZIndex = 1 }, shadeGui)
-- as mãos tapam o centro; só sobram frestas nas bordas
local shadeH = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(4, 3, 3), BorderSizePixel = 0, ZIndex = 1 }, shade)
new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.82), NumberSequenceKeypoint.new(0.2, 0.08), NumberSequenceKeypoint.new(0.8, 0.08), NumberSequenceKeypoint.new(1, 0.82) }) }, shadeH)
local shadeV = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(4, 3, 3), BorderSizePixel = 0, ZIndex = 1 }, shade)
new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.85), NumberSequenceKeypoint.new(0.22, 0.15), NumberSequenceKeypoint.new(0.78, 0.15), NumberSequenceKeypoint.new(1, 0.85) }) }, shadeV)
new("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0.5, 0, 0, 22), BackgroundTransparency = 1, Font = FONT, TextScaled = true, TextColor3 = Color3.fromRGB(90, 130, 100), Text = "OLHOS COBERTOS - ANDE DE COSTAS", ZIndex = 2 }, shade)

local function humanoid()
	return player.Character and player.Character:FindFirstChildOfClass("Humanoid")
end

local function setCovered(on)
	if on and not inRun() then
		on = false
	end
	covered = on
	shade.Visible = on
	coverBtn.TextColor3 = on and Color3.fromRGB(255, 214, 70) or GREEN
	-- com os olhos cobertos o corpo não gira sozinho: dá para andar de costas
	local hum = humanoid()
	if hum then
		hum.AutoRotate = not on
	end
	remotes.CobrirOlhos:FireServer(on)
end

coverBtn.Activated:Connect(function()
	setCovered(not covered)
end)
player:GetAttributeChangedSignal("OlhosCobertos"):Connect(function()
	-- o servidor desliga ao morrer / sair da fita
	if player:GetAttribute("OlhosCobertos") ~= true and covered then
		covered = false
		shade.Visible = false
		local hum = humanoid()
		if hum then
			hum.AutoRotate = true
		end
	end
end)
player.CharacterAdded:Connect(function()
	covered = false
	shade.Visible = false
end)

---------------------------------------------------------------- dizer a frase (Hóspede)
sayBtn.Activated:Connect(function()
	remotes.Dizer:FireServer()
end)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then
		return
	end
	if input.KeyCode == Enum.KeyCode.V or input.KeyCode == Enum.KeyCode.ButtonL1 then
		if inRun() then
			setCovered(not covered)
		end
	elseif input.KeyCode == Enum.KeyCode.G or input.KeyCode == Enum.KeyCode.ButtonR1 then
		if inRun() then
			remotes.Dizer:FireServer()
		end
	end
end)

---------------------------------------------------------------- estática (olhar e cegueira)
local staticFrame = new("Frame", { Name = "Estatica", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(46, 46, 46), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 3 }, gui)
local grains = {}
for i = 1, 220 do
	grains[i] = new("Frame", { Size = UDim2.fromOffset(4, 2), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 4 }, staticFrame)
end
local blindLabel = new("TextLabel", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 110), Size = UDim2.new(0, 420, 0, 24), BackgroundTransparency = 1, Font = FONT, TextScaled = true, TextColor3 = Color3.fromRGB(255, 214, 70), Text = "", ZIndex = 6 }, gui)

-- rosto tomando a tela (paralisia do Instrutor)
local faceHolder = new("Frame", { Name = "RostoNaTela", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.2, 0.25), BackgroundTransparency = 1, Visible = false, ZIndex = 8 }, gui)
new("UIAspectRatioConstraint", { AspectRatio = 3.1 / 3.5 }, faceHolder)

local function showFace(head)
	local bb = head and head:FindFirstChild("Rosto")
	local face = bb and bb:FindFirstChild("Face")
	for _, c in ipairs(faceHolder:GetChildren()) do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	if face then
		local copy = face:Clone()
		copy.Size = UDim2.fromScale(1, 1)
		copy.Position = UDim2.fromScale(0, 0)
		for _, d in ipairs(copy:GetDescendants()) do
			if d:IsA("GuiObject") then
				d.ZIndex = 9
			end
		end
		copy.ZIndex = 9
		copy.Parent = faceHolder
	end
	faceHolder.Size = UDim2.fromScale(0.2, 0.25)
	faceHolder.Visible = true
	TweenService:Create(faceHolder, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Size = UDim2.fromScale(1.6, 1.8) }):Play()
	task.delay(1.6, function()
		faceHolder.Visible = false
	end)
end

---------------------------------------------------------------- olhar para o Instrutor
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
local stare = 0
local fired = false

local function visibleHead()
	for _, head in ipairs(CollectionService:GetTagged("RostoInstrutor")) do
		if head:IsDescendantOf(workspace) then
			return head
		end
	end
	return nil
end

local function isLookingAt(head)
	local camPos = camera.CFrame.Position
	local dist = (head.Position - camPos).Magnitude
	if dist > TC.Range then
		return false
	end
	local screenPos, onScreen = camera:WorldToViewportPoint(head.Position)
	if not onScreen or screenPos.Z <= 0 then
		return false
	end
	local vp = camera.ViewportSize
	local dx = screenPos.X / vp.X - 0.5
	local dy = screenPos.Y / vp.Y - 0.5
	if math.sqrt(dx * dx + dy * dy) > TC.StareCone then
		return false
	end
	-- ele está cego (olhos fechados): não paralisa
	local bb = head:FindFirstChild("Rosto")
	local closed = bb and bb:FindFirstChild("Fechados", true)
	if closed and closed.Visible then
		return false
	end
	local ignore = { head.Parent }
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
	return workspace:Raycast(camPos, head.Position - camPos, rayParams) == nil
end

---------------------------------------------------------------- loop
local rng = Random.new()
local acc = 0
RunService.RenderStepped:Connect(function(dt)
	acc += dt
	if acc < 1 / 30 then
		return
	end
	local step = acc
	acc = 0
	local running = inRun()
	local andar = workspace:GetAttribute("Andar") or 0
	local threat = workspace:GetAttribute("Ameaca") or ""
	-- botões
	coverBtn.Visible = running and (andar >= TC.FromFloor or threat == "Instrutor")
	local sayUntil = player:GetAttribute("DizerAte")
	if running and typeof(sayUntil) == "number" then
		local left = sayUntil - workspace:GetServerTimeNow()
		sayBtn.Visible = left > -0.5
		sayBtn.Text = string.format(touch and "DIZER A FRASE (%d)" or "DIZER A FRASE [G] (%d)", math.max(0, math.ceil(left)))
	else
		sayBtn.Visible = false
	end
	if covered and not running then
		setCovered(false)
	end
	-- olhar
	local head = running and threat == "Instrutor" and visibleHead() or nil
	if head and not covered and isLookingAt(head) then
		stare += step
	else
		stare = math.max(0, stare - step * 2)
	end
	if not head then
		fired = false
	end
	if stare >= TC.StareSeconds and not fired and head then
		fired = true
		showFace(head)
		remotes.Encarou:FireServer()
	end
	-- estática: cegueira do Falso Colega ou olhar fixo no Instrutor
	local blind = running and player:GetAttribute("Cego") == true
	local level = 0
	if blind then
		level = 0.72
		blindLabel.Text = "CEGUEIRA DE ESTÁTICA  -  PASSOS PESADOS"
	else
		blindLabel.Text = ""
	end
	if stare > 0.15 then
		level = math.max(level, math.clamp(stare / TC.StareSeconds, 0, 1) * 0.65)
	end
	staticFrame.BackgroundTransparency = 1 - level
	local count = math.floor(#grains * math.clamp(level * 1.3, 0, 1))
	for i, g in ipairs(grains) do
		if i <= count then
			g.Position = UDim2.fromScale(rng:NextNumber(), rng:NextNumber())
			g.Size = UDim2.fromOffset(rng:NextInteger(3, 26), rng:NextInteger(1, 4))
			local v = rng:NextNumber(0.4, 1)
			g.BackgroundColor3 = Color3.new(v, v, v)
			g.BackgroundTransparency = rng:NextNumber(0.1, 0.5)
		else
			g.BackgroundTransparency = 1
		end
	end
end)
