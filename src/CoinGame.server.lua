-- Coin Hunt - Main Server Script
-- Put this file in ServerScriptService as CoinGame.server.lua

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local COIN_VALUE = 1
local COIN_RESPAWN_TIME = 5
local COIN_COUNT = 60
local MAP_SIZE = 500

-- Folders
local mapFolder = Instance.new("Folder")
mapFolder.Name = "CoinHuntMap"
mapFolder.Parent = Workspace

local coinFolder = Instance.new("Folder")
coinFolder.Name = "Coins"
coinFolder.Parent = Workspace

-- Create leaderstats
local function setupPlayer(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = 0
	coins.Parent = leaderstats
end

Players.PlayerAdded:Connect(setupPlayer)

-- Grass ground
local ground = Instance.new("Part")
ground.Name = "GrassGround"
ground.Size = Vector3.new(MAP_SIZE, 2, MAP_SIZE)
ground.Position = Vector3.new(0, -1, 0)
ground.Anchored = true
ground.Material = Enum.Material.Grass
ground.Color = Color3.fromRGB(85, 170, 85)
ground.Parent = mapFolder

-- Spawn
local spawn = Instance.new("SpawnLocation")
spawn.Name = "HiddenSpawn"
spawn.Size = Vector3.new(8, 1, 8)
spawn.Position = Vector3.new(0, 1, 0)
spawn.Anchored = true
spawn.Neutral = true
spawn.Transparency = 1
spawn.CanCollide = true
spawn.Parent = mapFolder

-- Create simple tree
local function createTree(position)
	local model = Instance.new("Model")
	model.Name = "Tree"

	local trunk = Instance.new("Part")
	trunk.Name = "Trunk"
	trunk.Size = Vector3.new(2, 8, 2)
	trunk.Position = position + Vector3.new(0, 4, 0)
	trunk.Anchored = true
	trunk.Material = Enum.Material.Wood
	trunk.Color = Color3.fromRGB(101, 67, 33)
	trunk.Parent = model

	local leaves = Instance.new("Part")
	leaves.Name = "Leaves"
	leaves.Shape = Enum.PartType.Ball
	leaves.Size = Vector3.new(8, 8, 8)
	leaves.Position = position + Vector3.new(0, 9, 0)
	leaves.Anchored = true
	leaves.Material = Enum.Material.Grass
	leaves.Color = Color3.fromRGB(45, 140, 55)
	leaves.Parent = model

	model.Parent = mapFolder
end

-- Create houses
local function createHouse(position)
	local model = Instance.new("Model")
	model.Name = "House"

	local base = Instance.new("Part")
	base.Size = Vector3.new(16, 10, 14)
	base.Position = position + Vector3.new(0, 5, 0)
	base.Anchored = true
	base.Material = Enum.Material.SmoothPlastic
	base.Color = Color3.fromRGB(230, 210, 180)
	base.Parent = model

	local roof = Instance.new("Part")
	roof.Size = Vector3.new(18, 2, 16)
	roof.Position = position + Vector3.new(0, 11, 0)
	roof.Anchored = true
	roof.Material = Enum.Material.Slate
	roof.Color = Color3.fromRGB(120, 60, 60)
	roof.Parent = model

	local door = Instance.new("Part")
	door.Size = Vector3.new(3, 6, 1)
	door.Position = position + Vector3.new(0, 3, -7.1)
	door.Anchored = true
	door.Material = Enum.Material.Wood
	door.Color = Color3.fromRGB(90, 60, 40)
	door.Parent = model

	model.Parent = mapFolder
end

-- Map decoration
math.randomseed(os.clock())

for _ = 1, 80 do
	local x = math.random(-MAP_SIZE / 2 + 20, MAP_SIZE / 2 - 20)
	local z = math.random(-MAP_SIZE / 2 + 20, MAP_SIZE / 2 - 20)

	-- Keep center clear
	if math.abs(x) > 35 or math.abs(z) > 35 then
		createTree(Vector3.new(x, 0, z))
	end
end

createHouse(Vector3.new(100, 0, 100))
createHouse(Vector3.new(-110, 0, 80))
createHouse(Vector3.new(120, 0, -100))
createHouse(Vector3.new(-100, 0, -110))

-- Create coin
local function createCoin(position)
	local coin = Instance.new("Part")
	coin.Name = "Coin"
	coin.Shape = Enum.PartType.Cylinder
	coin.Size = Vector3.new(1, 4, 4)
	coin.Position = position + Vector3.new(0, 2.5, 0)
	coin.Anchored = true
	coin.CanCollide = false
	coin.Material = Enum.Material.Neon
	coin.Color = Color3.fromRGB(255, 221, 0)
	coin.Orientation = Vector3.new(0, 0, 90)
	coin.Parent = coinFolder

	local light = Instance.new("PointLight")
	light.Brightness = 2
	light.Range = 10
	light.Parent = coin

	local collected = false

	-- Floating animation
	task.spawn(function()
		while coin.Parent do
			local tweenUp = TweenService:Create(
				coin,
				TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Position = coin.Position + Vector3.new(0, 1, 0)}
			)

			tweenUp:Play()
			tweenUp.Completed:Wait()

			if not coin.Parent then
				break
			end

			local tweenDown = TweenService:Create(
				coin,
				TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Position = coin.Position - Vector3.new(0, 1, 0)}
			)

			tweenDown:Play()
			tweenDown.Completed:Wait()
		end
	end)

	coin.Touched:Connect(function(hit)
		if collected then
			return
		end

		local character = hit.Parent
		local player = Players:GetPlayerFromCharacter(character)

		if not player then
			return
		end

		local leaderstats = player:FindFirstChild("leaderstats")
		local coins = leaderstats and leaderstats:FindFirstChild("Coins")

		if not coins then
			return
		end

		collected = true
		coins.Value += COIN_VALUE

		coin.Transparency = 1
		coin.CanTouch = false

		for _, child in ipairs(coin:GetChildren()) do
			if child:IsA("PointLight") then
				child.Enabled = false
			end
		end

		task.wait(COIN_RESPAWN_TIME)

		if coin.Parent then
			coin.Transparency = 0
			coin.CanTouch = true
			collected = false
		end
	end)
end

-- Spawn coins
for _ = 1, COIN_COUNT do
	local x = math.random(-MAP_SIZE / 2 + 15, MAP_SIZE / 2 - 15)
	local z = math.random(-MAP_SIZE / 2 + 15, MAP_SIZE / 2 - 15)

	createCoin(Vector3.new(x, 0, z))
end

print("Coin Hunt loaded!")
print("Coins:", COIN_COUNT)