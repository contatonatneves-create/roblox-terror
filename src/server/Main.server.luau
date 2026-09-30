-- Ponto de entrada do servidor.
local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)
	print("[Terror] " .. player.Name .. " entrou")
end)
