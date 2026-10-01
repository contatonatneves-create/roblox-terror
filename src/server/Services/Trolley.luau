-- Carrinho de serviço (GDD v2, seção 6.2): empurrar (1 ou 2 jogadores), estoque de toalhas
-- e portinhola de emergência para 1 jogador escondido.
-- O carrinho fica soldado ao personagem de quem empurra (física fluida no cliente) e o servidor
-- confere a velocidade para impedir teleporte.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Build = require(script.Parent.Build)
local State = require(script.Parent.State)

local Trolley = {}
local M = Enum.Material

local cart = nil -- { Model, Body, Pushers = {player = weld}, Hidden = player?, Last = CFrame }
local listeners = {}

function Trolley.OnChanged(fn)
	table.insert(listeners, fn)
end

local function changed()
	for _, fn in ipairs(listeners) do
		task.spawn(fn)
	end
end

local function weldAll(model, root)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and d ~= root then
			local w = Instance.new("WeldConstraint")
			w.Part0 = root
			w.Part1 = d
			w.Parent = d
			d.Anchored = false
			d.Massless = true
		end
	end
end

local function makeModel(cf)
	local m = Instance.new("Model")
	m.Name = "CarrinhoServico"
	local function part(name, size, localCF, color, mat, opts)
		return Build.Part(name, size, cf * localCF, color, mat, m, opts)
	end
	local metal = Color3.fromRGB(122, 128, 120)
	local dark = Color3.fromRGB(58, 64, 58)
	-- corpo inferior (compartimento de lixo / esconderijo)
	local body = part("Corpo", Vector3.new(3.4, 1.8, 5), CFrame.new(0, 1.4, 0), dark, M.Metal)
	part("Portinhola", Vector3.new(3, 1.3, 0.1), CFrame.new(0, 1.4, -2.55), Color3.fromRGB(80, 88, 78), M.Metal, { collide = false })
	part("Aviso", Vector3.new(1.6, 0.35, 0.05), CFrame.new(0, 1.85, -2.62), Color3.fromRGB(220, 180, 40), M.SmoothPlastic, { collide = false })
	-- prateleiras e colunas
	part("Prateleira", Vector3.new(3.4, 0.2, 5), CFrame.new(0, 3.3, 0), metal, M.Metal)
	for _, x in ipairs({ -1.6, 1.6 }) do
		for _, z in ipairs({ -2.4, 2.4 }) do
			part("Coluna", Vector3.new(0.2, 2, 0.2), CFrame.new(x, 3.2, z), metal, M.Metal, { collide = false })
		end
	end
	part("Topo", Vector3.new(3.4, 0.15, 5), CFrame.new(0, 4.2, 0), metal, M.Metal, { collide = false })
	-- barra de empurrar (atrás = +Z)
	part("Barra", Vector3.new(3.2, 0.25, 0.25), CFrame.new(0, 3.9, 2.85), Color3.fromRGB(30, 30, 30), M.Plastic, { collide = false })
	for _, x in ipairs({ -1.5, 1.5 }) do
		part("Suporte", Vector3.new(0.15, 0.15, 0.5), CFrame.new(x, 3.9, 2.6), metal, M.Metal, { collide = false })
	end
	-- rodas
	for _, x in ipairs({ -1.4, 1.4 }) do
		for _, z in ipairs({ -2, 2 }) do
			part("Roda", Vector3.new(0.4, 0.8, 0.8), CFrame.new(x, 0.4, z), Color3.fromRGB(25, 25, 25), M.Rubber, { collide = false, shape = Enum.PartType.Cylinder })
		end
	end
	-- estoque: toalhas, produtos e vassoura
	local towels = part("Toalhas", Vector3.new(1.6, 0.9, 1.6), CFrame.new(-0.7, 3.85, 0.9), Color3.fromRGB(236, 232, 220), M.Fabric, { collide = false })
	part("Toalhas", Vector3.new(1.5, 0.6, 1.5), CFrame.new(0.9, 3.7, 1.1), Color3.fromRGB(224, 220, 204), M.Fabric, { collide = false })
	part("Frasco", Vector3.new(0.5, 0.9, 0.5), CFrame.new(1, 3.85, -1.2), Color3.fromRGB(70, 140, 170), M.SmoothPlastic, { collide = false })
	part("Frasco", Vector3.new(0.5, 0.8, 0.5), CFrame.new(0.4, 3.8, -1.4), Color3.fromRGB(200, 190, 60), M.SmoothPlastic, { collide = false })
	part("Cabo", Vector3.new(0.18, 4, 0.18), CFrame.new(-1.45, 4.4, -1.8) * CFrame.Angles(math.rad(12), 0, 0), Color3.fromRGB(150, 110, 70), M.Wood, { collide = false })
	part("Saco", Vector3.new(2.6, 2.2, 0.9), CFrame.new(0, 2.6, -2.9), Color3.fromRGB(196, 186, 160), M.Fabric, { collide = false })
	m.PrimaryPart = body
	weldAll(m, body)
	body.Anchored = true
	body.Massless = false
	m:SetAttribute("Carrinho", true)
	return m, body, towels
end

---------------------------------------------------------------- empurrar
local function floorY()
	return cart.Body.Position.Y - 1.4
end

local function flatCFrame()
	local cf = cart.Body.CFrame
	local look = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
	if look.Magnitude < 0.1 then
		look = Vector3.new(0, 0, -1)
	end
	local pos = Vector3.new(cf.Position.X, floorY() + 1.4, cf.Position.Z)
	return CFrame.lookAt(pos, pos + look.Unit)
end

local function pusherCount()
	local n = 0
	for p in pairs(cart.Pushers) do
		if p.Parent then
			n += 1
		end
	end
	return n
end

local function updateSpeeds()
	local n = pusherCount()
	for p in pairs(cart.Pushers) do
		State.SetPushing(p, true, n >= 2 and Config.Move.PushTwo or Config.Move.PushOne)
	end
end

function Trolley.Release(player)
	if not cart or not cart.Pushers[player] then
		return
	end
	local w = cart.Pushers[player]
	cart.Pushers[player] = nil
	if w then
		w:Destroy()
	end
	State.SetPushing(player, false)
	if pusherCount() == 0 then
		local cf = flatCFrame()
		cart.Body.Anchored = true
		cart.Body.CFrame = cf
		cart.Last = cf
	end
	updateSpeeds()
	changed()
end

function Trolley.ReleaseAll()
	if not cart then
		return
	end
	for p in pairs(cart.Pushers) do
		Trolley.Release(p)
	end
end

local function attach(player)
	if not cart or cart.Pushers[player] or cart.Hidden == player then
		return
	end
	if not State.CanAct(player) then
		return
	end
	if pusherCount() >= Config.Trolley.MaxPushers then
		State.Notify(player, "Já tem duas pessoas empurrando.")
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local hum = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health <= 0 then
		return
	end
	local cf = flatCFrame()
	if pusherCount() == 0 then
		cart.Body.CFrame = cf
	end
	local side = pusherCount() == 0 and 0 or 1.5
	for _, w in pairs(cart.Pushers) do
		if w and w:GetAttribute("Lado") == 1.5 then
			side = -1.5
		end
	end
	local height = (hum.RigType == Enum.HumanoidRigType.R15) and (hum.HipHeight + root.Size.Y / 2) or 3
	local target = cf * CFrame.new(side, height - 1.4, 4.1)
	character:PivotTo(target * root.CFrame:ToObjectSpace(character:GetPivot()))
	local w = Instance.new("WeldConstraint")
	w.Name = "SoldaCarrinho"
	w:SetAttribute("Lado", side)
	w.Part0 = root
	w.Part1 = cart.Body
	w.Parent = root
	cart.Pushers[player] = w
	cart.Body.Anchored = false
	updateSpeeds()
	changed()
end

---------------------------------------------------------------- esconderijo
local function setHiddenLook(character, hidden)
	for _, d in ipairs(character:GetDescendants()) do
		if d:IsA("BasePart") or d:IsA("Decal") then
			if hidden then
				d:SetAttribute("AlphaAntes", d.Transparency)
				d.Transparency = 1
			elseif d:GetAttribute("AlphaAntes") ~= nil then
				d.Transparency = d:GetAttribute("AlphaAntes")
				d:SetAttribute("AlphaAntes", nil)
			end
		end
		if d:IsA("BasePart") then
			if hidden then
				d:SetAttribute("ColideAntes", d.CanCollide)
				d.CanCollide = false
			elseif d:GetAttribute("ColideAntes") ~= nil then
				d.CanCollide = d:GetAttribute("ColideAntes")
				d:SetAttribute("ColideAntes", nil)
			end
		end
	end
end

-- Lugar livre ao lado do carrinho para quem sai da portinhola (evita sair dentro da parede do elevador)
local function freeSpot(character)
	local cf = flatCFrame()
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character, cart.Model }
	for _, offset in ipairs({ Vector3.new(0, 0, 4.2), Vector3.new(3.2, 0, 0), Vector3.new(-3.2, 0, 0), Vector3.new(0, 0, -4.2), Vector3.new(2.8, 0, 3.6), Vector3.new(-2.8, 0, 3.6) }) do
		local spot = cf * CFrame.new(offset + Vector3.new(0, 1.6, 0))
		local hits = workspace:GetPartBoundsInBox(spot, Vector3.new(2.2, 4.6, 2.2), params)
		local blocked = false
		for _, part in ipairs(hits) do
			if part.CanCollide then
				blocked = true
				break
			end
		end
		if not blocked then
			return CFrame.new(spot.Position) * cf.Rotation
		end
	end
	return cf * CFrame.new(0, 1.6, 4.2)
end

function Trolley.Unhide(player)
	if not cart or cart.Hidden ~= player then
		return
	end
	cart.Hidden = nil
	local character = player.Character
	if character then
		local root = character:FindFirstChild("HumanoidRootPart")
		local weld = root and root:FindFirstChild("SoldaEsconderijo")
		if weld then
			weld:Destroy()
		end
		if root then
			-- o cliente é dono da física do boneco: ele mesmo se move para este ponto (Controls)
			local spot = freeSpot(character)
			player:SetAttribute("SaidaEsconderijo", spot)
			character:PivotTo(spot)
			root.AssemblyLinearVelocity = Vector3.zero
		end
		setHiddenLook(character, false)
	end
	State.SetHidden(player, false)
	cart.HidePrompt.Enabled = true
	changed()
end

local function hide(player)
	if not cart or cart.Hidden or cart.Pushers[player] then
		if cart and cart.Hidden and cart.Hidden ~= player then
			State.Notify(player, "A portinhola só cabe uma pessoa.")
		end
		return
	end
	if not State.CanAct(player) then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local hum = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health <= 0 then
		return
	end
	cart.Hidden = player
	cart.HidePrompt.Enabled = false
	setHiddenLook(character, true)
	character:PivotTo(cart.Body.CFrame * CFrame.new(0, 0.5, 0))
	local w = Instance.new("WeldConstraint")
	w.Name = "SoldaEsconderijo"
	w.Part0 = root
	w.Part1 = cart.Body
	w.Parent = root
	State.SetHidden(player, true)
	changed()
end

---------------------------------------------------------------- API
function Trolley.Spawn(cf)
	Trolley.Remove()
	local model, body, towels = makeModel(cf)
	cart = { Model = model, Body = body, Pushers = {}, Hidden = nil, Last = body.CFrame }
	-- prompts
	local barra = model:FindFirstChild("Barra")
	local push = Build.Prompt(barra, "PromptEmpurrar", "Empurrar", "Carrinho de serviço", { distance = 7 })
	push.Triggered:Connect(attach)
	cart.PushPrompt = push
	local hidePrompt = Build.Prompt(model:FindFirstChild("Portinhola"), "PromptEsconder", "Esconder-se", "Portinhola", { distance = 6, hold = 0.4, key = Enum.KeyCode.F, pad = Enum.KeyCode.ButtonY })
	hidePrompt.Triggered:Connect(hide)
	cart.HidePrompt = hidePrompt
	local towelPrompt = Build.Prompt(towels, "PromptToalhas", "Pegar toalhas", "Estoque", { distance = 7, key = Enum.KeyCode.T, pad = Enum.KeyCode.DPadUp })
	towelPrompt.Triggered:Connect(function(player)
		if State.CanAct(player) then
			State.GiveTowels(player)
		end
	end)
	-- rangido das rodas (o cliente controla o volume pela velocidade)
	Build.Sound(body, Config.Sounds.TrolleySqueak, { name = "Rangido", volume = 0, looped = true, maxDistance = 70, play = true })
	model.Parent = workspace
	return model
end

function Trolley.Remove()
	if cart then
		Trolley.ReleaseAll()
		if cart.Hidden then
			Trolley.Unhide(cart.Hidden)
		end
		cart.Model:Destroy()
		cart = nil
	end
end

function Trolley.Get()
	return cart
end

function Trolley.Position()
	return cart and cart.Body.Position
end

function Trolley.Teleport(transform)
	-- transform: CFrame que leva do elevador antigo para o novo
	if not cart then
		return
	end
	Trolley.ReleaseAll()
	if cart.Hidden then
		Trolley.Unhide(cart.Hidden)
	end
	cart.Body.Anchored = true
	cart.Body.CFrame = transform * cart.Body.CFrame
	cart.Last = cart.Body.CFrame
end

function Trolley.IsHidden(player)
	return cart ~= nil and cart.Hidden == player
end

function Trolley.Speed()
	if not cart then
		return 0
	end
	local v = cart.Body.AssemblyLinearVelocity
	return Vector3.new(v.X, 0, v.Z).Magnitude
end

function Trolley.PlayerGone(player)
	if not cart then
		return
	end
	if cart.Pushers[player] ~= nil then
		Trolley.Release(player)
	end
	if cart.Hidden == player then
		Trolley.Unhide(player)
	end
end

function Trolley.Init(remotes)
	remotes.SoltarCarrinho.OnServerEvent:Connect(function(player)
		Trolley.Release(player)
	end)
	remotes.SairEsconderijo.OnServerEvent:Connect(function(player)
		Trolley.Unhide(player)
	end)
	-- validação simples contra teleporte do carrinho
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 0.5 or not cart then
			return
		end
		local elapsed = acc
		acc = 0
		local cf = cart.Body.CFrame
		local moved = (cf.Position - cart.Last.Position).Magnitude
		if moved / elapsed > Config.Trolley.MaxSpeedCheck * 1.5 and not cart.Body.Anchored then
			Trolley.ReleaseAll()
			cart.Body.CFrame = cart.Last
		else
			cart.Last = cf
		end
		-- empurradores que morreram ou sumiram
		for p, w in pairs(cart.Pushers) do
			local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
			if not p.Parent or not hum or hum.Health <= 0 or not w.Parent then
				Trolley.Release(p)
			end
		end
	end)
	Players.PlayerRemoving:Connect(Trolley.PlayerGone)
end

return Trolley
