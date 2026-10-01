-- A fita (a corrida): do videocassete da Sala de Descanso até o check-out (GDD v2, seção 6).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local State = require(script.Parent.State)
local Floors = require(script.Parent.Floors)
local Trolley = require(script.Parent.Trolley)
local Lobby = require(script.Parent.Lobby)
local Maid = require(script.Parent.Maid)

local Tape = {}
local remotes = nil
local run = nil -- { Players = {player = true}, Floor, Seed, Busy, Rng, StartClock }
local state = "Lobby"

local function setState(s)
	state = s
	workspace:SetAttribute("FitaEstado", s)
end

function Tape.State()
	return state
end

function Tape.Run()
	return run
end

local function runPlayers()
	local list = {}
	if run then
		for p in pairs(run.Players) do
			if p.Parent then
				table.insert(list, p)
			end
		end
	end
	return list
end

local function activePlayers()
	local list = {}
	for _, p in ipairs(runPlayers()) do
		if State.IsActive(p) then
			table.insert(list, p)
		end
	end
	return list
end
Tape.ActivePlayers = activePlayers

local function fireRun(name, ...)
	for _, p in ipairs(runPlayers()) do
		remotes[name]:FireClient(p, ...)
	end
end

---------------------------------------------------------------- textos dos andares
local function ruleFor(n)
	if n >= (Config.Maid.DebugFromFloor or Config.Maid.FromFloor) then
		return Config.Rules.Maid
	end
	return Config.Rules.Default
end

local function updateTexts(floor)
	if not floor then
		return
	end
	local phase = Config.PhaseOf(floor.Number)
	local tasks = Floors.TaskText(floor)
	local header = string.format("ANDAR %02d  -  %s\n", floor.Number, phase.Name)
	local tv = header .. "\n" .. tasks .. "\n\nREGRA: " .. ruleFor(floor.Number)
	Floors.SetTV(floor.Start, tv)
	Floors.SetTV(floor.End, tv)
	if run and run.Floor == floor.Number then
		workspace:SetAttribute("Tarefas", tasks)
	end
end

---------------------------------------------------------------- chegada a um andar
local function isCurrent(floor)
	return run ~= nil and run.Floor == floor.Number and not run.Busy
end

local function arriveFloor(n)
	local floor = Floors.Get(n)
	run.Floor = n
	workspace:SetAttribute("Andar", n)
	workspace:SetAttribute("Fase", Config.PhaseOf(n).Label)
	Floors.SetDoors(floor.Start, false, true)
	Floors.SetDoors(floor.End, false, true)
	updateTexts(floor)
	-- voz robótica na TV do elevador
	local speech = Floors.TaskSpeech(floor)
	if ruleFor(n) == Config.Rules.Maid then
		speech ..= " Se as luzes ficarem âmbar: pare, limpe e não faça barulho."
	end
	fireRun("Falar", speech)
	task.delay(Config.Run.ArrivalDoorDelay, function()
		if run and run.Floor == n then
			Floors.Ding(floor.Start)
			Floors.SetDoors(floor.Start, true)
		end
	end)
	Maid.Schedule(floor, isCurrent, activePlayers, run.Rng)
	-- carrega o próximo e descarta o antigo
	task.spawn(function()
		if n < Config.Run.Floors and not Floors.Get(n + 1) then
			Floors.Build(n + 1, run.Seed + n + 1)
		end
		for k in pairs(Floors.All()) do
			if k < n - 1 or k > n + 1 then
				Floors.Destroy(k)
			end
		end
	end)
end

---------------------------------------------------------------- fim da fita
local function endRun(success)
	if not run then
		return
	end
	local list = runPlayers()
	Maid.Cancel()
	for _, p in ipairs(list) do
		Trolley.PlayerGone(p)
		local wasAlive = State.IsActive(p)
		State.SetInRun(p, false)
		State.ClearTools(p)
		if wasAlive and p.Character then
			p.Character:PivotTo(Lobby.SpawnCFrame() * CFrame.new((math.random() - 0.5) * 6, 0, (math.random() - 0.5) * 3))
		end
	end
	Trolley.Remove()
	Floors.DestroyAll()
	run = nil
	setState("Lobby")
	workspace:SetAttribute("Andar", 0)
	workspace:SetAttribute("Tarefas", "")
	workspace:SetAttribute("Ameaca", "")
	Lobby.SetTV(success and "CHECK-OUT REGISTRADO\n\nOBRIGADO PELO\nSEU SERVIÇO" or "FITA REJEITADA\n\nPEGUE OUTRA FITA\nNA ESTANTE")
	Lobby.SetVcrEnabled(true)
	task.delay(12, function()
		if state == "Lobby" then
			Lobby.SetTV("SEM SINAL\n\nPEGUE A FITA Nº 4\nNA ESTANTE")
		end
	end)
end

local function checkAllDead()
	if not run or run.Busy then
		return
	end
	if #activePlayers() == 0 then
		run.Busy = true
		fireRun("Transicao", "Rejeitada")
		task.wait(Config.Run.ReturnToLobbyDelay)
		endRun(false)
	end
end

function Tape.Kill(player, reason)
	if not State.IsActive(player) then
		return
	end
	State.SetAlive(player, false)
	Trolley.PlayerGone(player)
	State.ClearTools(player)
	remotes.FimTransmissao:FireClient(player, reason or "Sinal perdido.")
	for _, p in ipairs(activePlayers()) do
		State.Notify(p, player.DisplayName .. " saiu do ar.")
	end
	task.delay(0.2, function()
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.Health = 0
		end
	end)
	task.delay(0.5, checkAllDead)
end

---------------------------------------------------------------- subir de andar
local function teleportGroup(transform)
	Trolley.Teleport(transform)
	for _, p in ipairs(activePlayers()) do
		local c = p.Character
		if c then
			State.SetPushing(p, false)
			c:PivotTo(transform * c:GetPivot())
		end
	end
end

local function checkOut()
	run.Busy = true
	Maid.Cancel()
	local floor = Floors.Get(run.Floor)
	Floors.SetDoors(floor.End, false)
	local elapsed = os.clock() - run.StartClock
	fireRun("Transicao", "CheckOut", { Tempo = elapsed, Andares = run.Floor, Vivos = #activePlayers() })
	task.wait(Config.Run.ReturnToLobbyDelay + 2)
	endRun(true)
end

local function ride()
	run.Busy = true
	Maid.Cancel()
	local n = run.Floor
	local floor = Floors.Get(n)
	Floors.SetDoors(floor.End, false)
	task.wait(1.3)
	if not run then
		return
	end
	fireRun("Transicao", "Subir", n + 1)
	task.wait(Config.Run.ElevatorRideSeconds / 2)
	local nextFloor = Floors.Get(n + 1) or Floors.Build(n + 1, run.Seed + n + 1)
	teleportGroup(nextFloor.Start.Frame * floor.End.Frame:Inverse())
	task.wait(Config.Run.ElevatorRideSeconds / 2)
	if not run then
		return
	end
	arriveFloor(n + 1)
	run.Busy = false
end

local warnedCart = {}
local function elevatorCheck()
	if not run or run.Busy then
		return
	end
	local floor = Floors.Get(run.Floor)
	if not floor or not floor.AllDone or not floor.End.Open then
		return
	end
	local list = activePlayers()
	if #list == 0 then
		return
	end
	for _, p in ipairs(list) do
		local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		if not root or not Floors.IsInside(floor.End, root.Position) then
			return
		end
	end
	local cartPos = Trolley.Position()
	if cartPos and not Floors.IsInside(floor.End, cartPos) then
		if not warnedCart[run.Floor] then
			warnedCart[run.Floor] = true
			for _, p in ipairs(list) do
				State.Notify(p, "Tragam o carrinho para dentro do elevador.")
			end
		end
		return
	end
	if run.Floor >= Config.Run.Floors then
		checkOut()
	else
		ride()
	end
end

---------------------------------------------------------------- início
function Tape.Start(list, startFloor)
	startFloor = startFloor or 1
	if run then
		endRun(false)
	end
	local seed = math.random(1, 1000000000)
	run = { Players = {}, Floor = startFloor, Seed = seed, Busy = true, Rng = Random.new(seed), StartClock = os.clock() }
	warnedCart = {}
	for _, p in ipairs(list) do
		run.Players[p] = true
	end
	setState("Rodando")
	Lobby.SetVcrEnabled(false)
	Lobby.SetTV("▶ PLAY\n\nFITA DE TREINAMENTO\nINSTITUCIONAL Nº 4")
	workspace:SetAttribute("AndarTotal", Config.Run.Floors)
	workspace:SetAttribute("FitaInicio", workspace:GetServerTimeNow())
	Floors.DestroyAll()
	local first = Floors.Build(startFloor, seed + startFloor)
	Trolley.Spawn(first.Start.Frame * CFrame.new(0, 1.4, 1.2))
	for _, p in ipairs(list) do
		State.SetInRun(p, true)
		State.ClearTools(p)
		State.GiveBroom(p)
		remotes.Transicao:FireClient(p, "Entrar", startFloor)
	end
	task.wait(1.4)
	local spots = { -3.3, 3.3, -3.3, 3.3 }
	local zs = { 3.6, 3.6, 0.2, 0.2 }
	for i, p in ipairs(list) do
		local c = p.Character
		local hum = c and c:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.Sit = false
			for _, seat in ipairs(Lobby.Seats()) do
				local weld = seat:FindFirstChild("SeatWeld")
				if weld and weld.Part1 and weld.Part1:IsDescendantOf(c) then
					weld:Destroy()
				end
			end
			task.wait()
			c:PivotTo(first.Start.Frame * CFrame.new(spots[i] or 0, 3, zs[i] or 2))
		end
	end
	run.Busy = false
	arriveFloor(startFloor)
end

local counting = false
local function onInsert(player)
	if state ~= "Lobby" or counting then
		State.Notify(player, "Já tem uma fita rodando.")
		return
	end
	if not State.HasTool(player, "FitaVHS") then
		State.Notify(player, "Pegue a Fita nº 4 na estante primeiro.")
		return
	end
	State.TakeTool(player, "FitaVHS")
	counting = true
	setState("Contagem")
	Lobby.SetVcrEnabled(false)
	remotes.Som:FireAllClients("TapeInsert")
	local list = {}
	for i = Config.Run.CountdownSeconds, 1, -1 do
		Lobby.SetTV(string.format("FITA INSERIDA\n\nSENTEM NO SOFÁ\n\n%d", i))
		workspace:SetAttribute("Contagem", i)
		task.wait(1)
	end
	workspace:SetAttribute("Contagem", 0)
	for _, seat in ipairs(Lobby.Seats()) do
		local hum = seat.Occupant
		local p = hum and Players:GetPlayerFromCharacter(hum.Parent)
		if p and #list < Config.Run.MaxPlayers then
			table.insert(list, p)
		end
	end
	counting = false
	if #list == 0 then
		setState("Lobby")
		Lobby.SetVcrEnabled(true)
		Lobby.SetTV("NINGUÉM NO SOFÁ\n\nA FITA FOI EJETADA")
		State.GiveTape(player)
		return
	end
	Tape.Start(list)
end

---------------------------------------------------------------- testes (só no Studio)
function Tape.DebugJump(n)
	if not run then
		Tape.Start(Players:GetPlayers(), n)
		return
	end
	run.Busy = true
	Maid.Cancel()
	local old = Floors.Get(run.Floor)
	local target = Floors.Build(n, run.Seed + n)
	teleportGroup(target.Start.Frame * old.Start.Frame:Inverse())
	run.Busy = false
	arriveFloor(n)
end

function Tape.DebugMaid()
	if run then
		local floor = Floors.Get(run.Floor)
		task.spawn(Maid.Trigger, floor, activePlayers)
	end
end

function Tape.DebugCompleteTasks()
	if run then
		local floor = Floors.Get(run.Floor)
		for _, t in ipairs(floor.Tasks) do
			if t.Kind == "Limpeza" and t.Stain then
				t.Strokes = Config.Tasks.CleanStrokes - 1
				Floors.OnSweep(Players:GetPlayers()[1], t.Stain.Position)
			elseif t.Kind == "Entrega" and not t.Done then
				t.Done = true
			end
		end
		floor.AllDone = true
		Floors.SetDoors(floor.End, true)
		updateTexts(floor)
	end
end

---------------------------------------------------------------- init
function Tape.Init(r)
	remotes = r
	setState("Lobby")
	workspace:SetAttribute("Andar", 0)
	workspace:SetAttribute("Ameaca", "")
	Lobby.OnInsert(onInsert)
	Floors.Notify = State.Notify
	Floors.On("TaskDone", function(floor)
		updateTexts(floor)
	end)
	Floors.On("AllTasksDone", function(floor)
		updateTexts(floor)
		if run and run.Floor == floor.Number then
			Floors.Ding(floor.End)
			Floors.SetDoors(floor.End, true)
			for _, p in ipairs(activePlayers()) do
				State.Notify(p, floor.Number >= Config.Run.Floors and "Tarefas feitas. Bata o ponto no elevador." or "Tarefas feitas. O elevador foi liberado.")
			end
			fireRun("Falar", floor.Number >= Config.Run.Floors and "Turno concluído. Dirija-se ao elevador." or "Elevador liberado.")
		end
	end)
	State.OnSweep(function(player, pos)
		if State.IsActive(player) then
			Floors.OnSweep(player, pos)
		end
	end)
	Maid.SetKill(Tape.Kill)
	local function watchCharacter(player, character)
		local hum = character:WaitForChild("Humanoid", 10)
		if hum then
			hum.Died:Connect(function()
				if State.IsActive(player) then
					Tape.Kill(player, "Sinal perdido.")
				end
			end)
		end
	end
	local function setup(p)
		p.CharacterAdded:Connect(function(c)
			watchCharacter(p, c)
		end)
		if p.Character then
			task.spawn(watchCharacter, p, p.Character)
		end
	end
	Players.PlayerAdded:Connect(setup)
	for _, p in ipairs(Players:GetPlayers()) do
		setup(p)
	end
	Players.PlayerRemoving:Connect(function(p)
		if run and run.Players[p] then
			run.Players[p] = nil
			task.defer(checkAllDead)
		end
	end)
	task.spawn(function()
		while true do
			task.wait(0.4)
			local ok, err = pcall(elevatorCheck)
			if not ok then
				warn("[Tape] " .. tostring(err))
			end
		end
	end)
end

return Tape
