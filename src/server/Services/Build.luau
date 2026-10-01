-- Ajudantes para montar o mundo com peças simples (lobby, andares, carrinho e entidades).
local Build = {}

local M = Enum.Material

-- opts: collide (padrão true), transp, shadow, query, touch, shape, anchored
function Build.Part(name, size, cf, color, material, parent, opts)
	opts = opts or {}
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color or Color3.fromRGB(200, 200, 200)
	p.Material = material or M.SmoothPlastic
	p.Anchored = opts.anchored ~= false
	p.CanCollide = opts.collide ~= false
	p.CanQuery = opts.query ~= false
	p.CanTouch = opts.touch == true
	p.CastShadow = opts.shadow ~= false
	p.Transparency = opts.transp or 0
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if opts.shape then
		p.Shape = opts.shape
	end
	p.Parent = parent
	return p
end

-- Peça decorativa: sem colisão, sem consulta
function Build.Deco(name, size, cf, color, material, parent, opts)
	opts = opts or {}
	opts.collide = false
	opts.query = opts.query == true
	return Build.Part(name, size, cf, color, material, parent, opts)
end

function Build.Wedge(name, size, cf, color, material, parent)
	local w = Instance.new("WedgePart")
	w.Name = name
	w.Size = size
	w.CFrame = cf
	w.Color = color
	w.Material = material or M.SmoothPlastic
	w.Anchored = true
	w.CanTouch = false
	w.Parent = parent
	return w
end

-- Cilindro em pé (eixo Y)
function Build.CylY(name, height, diameter, pos, color, material, parent, opts)
	return Build.Part(name, Vector3.new(height, diameter, diameter), CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)), color, material, parent,
		(function()
			local o = opts or {}
			o.shape = Enum.PartType.Cylinder
			return o
		end)())
end

-- Texto numa face da peça
function Build.Text(part, face, text, opts)
	opts = opts or {}
	local sg = Instance.new("SurfaceGui")
	sg.Name = opts.name or "Texto"
	sg.Face = face
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = opts.pps or 50
	sg.LightInfluence = opts.light or 1
	sg.Brightness = opts.brightness or 1
	sg.CanvasSize = Vector2.new(0, 0)
	local t = Instance.new("TextLabel")
	t.Name = "Label"
	t.BackgroundTransparency = opts.bg and 0 or 1
	t.BackgroundColor3 = opts.bg or Color3.new(0, 0, 0)
	t.Size = UDim2.fromScale(1, 1)
	t.Font = opts.font or Enum.Font.Code
	t.TextColor3 = opts.color or Color3.new(1, 1, 1)
	t.TextScaled = true
	t.TextWrapped = true
	t.Text = text
	t.TextXAlignment = opts.alignX or Enum.TextXAlignment.Center
	t.TextYAlignment = opts.alignY or Enum.TextYAlignment.Center
	local pad = Instance.new("UIPadding")
	local px = opts.pad or 0
	pad.PaddingLeft = UDim.new(0.02 * px, 0)
	pad.PaddingRight = UDim.new(0.02 * px, 0)
	pad.PaddingTop = UDim.new(0.03 * px, 0)
	pad.PaddingBottom = UDim.new(0.03 * px, 0)
	pad.Parent = t
	t.Parent = sg
	sg.Parent = part
	return sg, t
end

function Build.Light(part, kind, color, range, brightness, opts)
	opts = opts or {}
	local l = Instance.new(kind or "PointLight")
	l.Color = color or Color3.fromRGB(255, 236, 200)
	l.Range = range or 14
	l.Brightness = brightness or 1
	l.Shadows = opts.shadows == true
	if l:IsA("SurfaceLight") or l:IsA("SpotLight") then
		l.Face = opts.face or Enum.NormalId.Bottom
		l.Angle = opts.angle or 120
	end
	l.Parent = part
	return l
end

function Build.Sound(parent, id, opts)
	opts = opts or {}
	local s = Instance.new("Sound")
	s.Name = opts.name or "Som"
	s.SoundId = id
	s.Volume = opts.volume or 0.5
	s.Looped = opts.looped == true
	s.RollOffMaxDistance = opts.maxDistance or 60
	s.RollOffMinDistance = opts.minDistance or 6
	s.PlaybackSpeed = opts.speed or 1
	s.Parent = parent
	if opts.play then
		s:Play()
	end
	return s
end

function Build.Prompt(parent, name, action, object, opts)
	opts = opts or {}
	local pp = Instance.new("ProximityPrompt")
	pp.Name = name
	pp.ActionText = action
	pp.ObjectText = object or ""
	pp.HoldDuration = opts.hold or 0
	pp.MaxActivationDistance = opts.distance or 8
	pp.RequiresLineOfSight = false
	pp.KeyboardKeyCode = opts.key or Enum.KeyCode.E
	pp.GamepadKeyCode = opts.pad or Enum.KeyCode.ButtonX
	pp.Style = Enum.ProximityPromptStyle.Default
	pp.Parent = parent
	return pp
end

-- Cor com leve variação aleatória (para paredes e pisos não ficarem chapados)
function Build.Vary(color, rng, amount)
	amount = amount or 0.04
	local h, s, v = color:ToHSV()
	return Color3.fromHSV(h, s, math.clamp(v + (rng:NextNumber() - 0.5) * 2 * amount, 0, 1))
end

return Build
