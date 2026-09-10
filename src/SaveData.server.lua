-- COIN HUNT SAVE DATA
-- Roblox Studio: ServerScriptService > SaveData
-- Saves Coins, Level, BestStreak, DoubleCoins, and equipped Pet.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local store = DataStoreService:GetDataStore("CoinHuntPlayerData_v1")
local AUTOSAVE_SECONDS = 60

local function collectData(player)
	local data = {
		Coins = 0,
		Level = 1,
		BestStreak = 0,
		DoubleCoins = player:GetAttribute("DoubleCoins") == true,
		PetName = player:GetAttribute("PetName") or "None",
		PetBonus = player:GetAttribute("PetBonus") or 0,
	}

	local stats = player:FindFirstChild("leaderstats")
	if stats then
		local coins = stats:FindFirstChild("Coins")
		local level = stats:FindFirstChild("Level")
		local best = stats:FindFirstChild("BestStreak")

		if coins then data.Coins = coins.Value end
		if level then data.Level = level.Value end
		if best then data.BestStreak = best.Value end
	end

	return data
end

local function applyData(player, data)
	if type(data) ~= "table" then
		return
	end

	local stats = player:WaitForChild("leaderstats", 15)
	if stats then
		local coins = stats:FindFirstChild("Coins")
		local level = stats:FindFirstChild("Level")
		local best = stats:FindFirstChild("BestStreak")

		if coins then
			coins.Value = math.max(0, tonumber(data.Coins) or 0)
		end

		if level then
			level.Value = math.max(1, tonumber(data.Level) or 1)
		end

		if best then
			best.Value = math.max(0, tonumber(data.BestStreak) or 0)
		end
	end

	player:SetAttribute("DoubleCoins", data.DoubleCoins == true)
	player:SetAttribute("PetName", data.PetName or "None")
	player:SetAttribute("PetBonus", tonumber(data.PetBonus) or 0)
end

local function loadPlayer(player)
	local success, data = pcall(function()
		return store:GetAsync("Player_" .. player.UserId)
	end)

	if success then
		if data then
			applyData(player, data)
			print("[Coin Hunt] Loaded data for", player.Name)
		else
			print("[Coin Hunt] New player:", player.Name)
		end
	else
		warn("[Coin Hunt] Could not load data for " .. player.Name .. ": " .. tostring(data))
	end
end

local function savePlayer(player)
	local data = collectData(player)

	local success, err = pcall(function()
		store:UpdateAsync("Player_" .. player.UserId, function()
			return data
		end)
	end)

	if success then
		print("[Coin Hunt] Saved data for", player.Name)
	else
		warn("[Coin Hunt] Could not save data for " .. player.Name .. ": " .. tostring(err))
	end
end

Players.PlayerAdded:Connect(function(player)
	-- Give CoinGame/PetSystem a moment to create stats and attributes.
	task.defer(loadPlayer, player)
end)

Players.PlayerRemoving:Connect(function(player)
	savePlayer(player)
end)

-- Autosave while the server is running.
task.spawn(function()
	while true do
		task.wait(AUTOSAVE_SECONDS)

		for _, player in ipairs(Players:GetPlayers()) do
			task.spawn(savePlayer, player)
		end
	end
end)

-- Save when Roblox is shutting down.
game:BindToClose(function()
	local players = Players:GetPlayers()
	local remaining = #players

	if remaining == 0 then
		return
	end

	for _, player in ipairs(players) do
		task.spawn(function()
			savePlayer(player)
			remaining -= 1
		end)
	end

	local deadline = os.clock() + 10
	while remaining > 0 and os.clock() < deadline do
		task.wait(0.1)
	end
end)

print("[Coin Hunt] Save Data system loaded!")
