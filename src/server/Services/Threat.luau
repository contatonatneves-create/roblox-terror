-- Coordena as ameaças de cada andar: só uma entidade "ativa" por vez (o atributo Ameaca do workspace
-- alimenta a estática do cliente) e um contexto comum com o que as entidades precisam da fita
-- (matar, lista de vivos, andar atual). Assim as entidades não dependem do Tape diretamente.
local Threat = {}

local current = nil -- nome da ameaça ativa
local cancels = {}

-- Preenchido pelo Tape no Init
Threat.Ctx = {
	Kill = function() end,
	Active = function()
		return {}
	end,
	IsCurrent = function()
		return false
	end,
	Notify = function() end,
	Rng = function()
		return Random.new()
	end,
}

function Threat.SetContext(ctx)
	for k, v in pairs(ctx) do
		Threat.Ctx[k] = v
	end
end

-- Tenta ocupar a vez. Devolve false se outra entidade já está agindo.
function Threat.Acquire(name, pos)
	if current and current ~= name then
		return false
	end
	current = name
	workspace:SetAttribute("Ameaca", name)
	if pos then
		workspace:SetAttribute("AmeacaPos", pos)
	end
	return true
end

function Threat.Set(name, pos)
	if current ~= name then
		return
	end
	workspace:SetAttribute("Ameaca", name)
	if pos then
		workspace:SetAttribute("AmeacaPos", pos)
	end
end

-- Ameaças podem trocar de "fase" (ex.: CamareiraAviso → Camareira) mantendo a vez
function Threat.Rename(from, to)
	if current == from then
		current = to
		workspace:SetAttribute("Ameaca", to)
	end
end

function Threat.Release(name)
	if current == name then
		current = nil
		workspace:SetAttribute("Ameaca", "")
	end
end

function Threat.Current()
	return current
end

function Threat.Busy()
	return current ~= nil
end

-- Cada entidade registra como se cancela (troca de andar, fim da fita)
function Threat.Register(name, cancelFn)
	cancels[name] = cancelFn
end

function Threat.CancelAll()
	for _, fn in pairs(cancels) do
		local ok, err = pcall(fn)
		if not ok then
			warn("[Threat] " .. tostring(err))
		end
	end
	current = nil
	workspace:SetAttribute("Ameaca", "")
end

-- Tenta de novo mais tarde se outra entidade estiver ocupando a vez
function Threat.WhenFree(isStillValid, fn, retry)
	task.spawn(function()
		for _ = 1, 12 do
			if not isStillValid() then
				return
			end
			if not current then
				fn()
				return
			end
			task.wait(retry or 6)
		end
	end)
end

-- Distância no plano (ignora altura)
function Threat.DistXZ(a, b)
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

-- Índice do caminho mais adiantado entre os jogadores (o caminho vai do elevador de chegada ao de saída)
function Threat.LeadIndex(floor, players)
	local best = 1
	for _, p in ipairs(players) do
		local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		if root then
			local nearest, nd = 1, math.huge
			for i, pos in ipairs(floor.Path) do
				local d = Threat.DistXZ(pos, root.Position)
				if d < nd then
					nearest, nd = i, d
				end
			end
			best = math.max(best, nearest)
		end
	end
	return best
end

return Threat
