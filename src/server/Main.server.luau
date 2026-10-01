-- Ponto de entrada do servidor do LATE CHECKOUT: NIGHT SERVICE.
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Services = script.Parent:WaitForChild("Services")

-- Remotes (criados aqui para o projeto não depender de nada salvo no place)
local remotes = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage
local function event(name)
	local r = remotes:FindFirstChild(name) or Instance.new("RemoteEvent")
	r.Name = name
	r.Parent = remotes
	return r
end
local R = {}
for _, name in ipairs({ "Transicao", "FimTransmissao", "Falar", "Aviso", "Som", "Movimento", "SoltarCarrinho", "SairEsconderijo" }) do
	R[name] = event(name)
end

-- Luz: tudo é interno, escuro e esverdeado
Lighting.ClockTime = 0
Lighting.Brightness = 0
Lighting.Ambient = Color3.fromRGB(46, 46, 42)
Lighting.OutdoorAmbient = Color3.fromRGB(20, 20, 20)
Lighting.EnvironmentDiffuseScale = 0.15
Lighting.EnvironmentSpecularScale = 0.2
Lighting.ExposureCompensation = 0.2
Lighting.GlobalShadows = true
Lighting.FogColor = Color3.fromRGB(10, 10, 10)
Lighting.FogEnd = 400
for _, child in ipairs(Lighting:GetChildren()) do
	if child:IsA("SunRaysEffect") or child:IsA("DepthOfFieldEffect") then
		child.Enabled = false
	elseif child:IsA("Atmosphere") then
		child.Density = 0
		child.Haze = 0
		child.Glare = 0
	end
end
Players.RespawnTime = Config.Death.RespawnTime
Players.CharacterAutoLoads = true

local State = require(Services.State)
local Noise = require(Services.Noise)
local Floors = require(Services.Floors)
local Trolley = require(Services.Trolley)
local Lobby = require(Services.Lobby)
local Tape = require(Services.Tape)

State.Init(R)
Noise.Init()
Floors.Init()
Trolley.Init(R)
Lobby.Init()
Tape.Init(R)

-- Ferramenta de teste, só existe no Studio: ServerStorage.TesteTerror:Invoke("Andar", 6)
if game:GetService("RunService"):IsStudio() then
	local bf = Instance.new("BindableFunction")
	bf.Name = "TesteTerror"
	bf.OnInvoke = function(cmd, a)
		if cmd == "Iniciar" then
			task.spawn(Tape.Start, Players:GetPlayers(), a or 1)
			return "ok"
		elseif cmd == "Andar" then
			task.spawn(Tape.DebugJump, a)
			return "ok"
		elseif cmd == "Camareira" then
			Tape.DebugMaid()
			return "ok"
		elseif cmd == "Tarefas" then
			Tape.DebugCompleteTasks()
			return "ok"
		elseif cmd == "Estado" then
			local run = Tape.Run()
			return string.format("estado=%s andar=%s vivos=%d", Tape.State(), tostring(run and run.Floor), #Tape.ActivePlayers())
		end
		return "comando desconhecido"
	end
	bf.Parent = game:GetService("ServerStorage")
end
