-- COIN HUNT PET SYSTEM - FIXED
-- Roblox Studio: ServerScriptService > PetSystem
-- Egg costs 150 coins. Equipped pets give +25% coin reward.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local EGG_COST = 150
local PET_BONUS = 0.25

local old = Workspace:FindFirstChild("CoinHuntPets")
if old then
	old:Destroy()
end

local petFolder = Instance.new("Folder")
petFolder.Name = "CoinHuntPets"
petFolder.Parent = Workspace

local PETS = {
	{Name = "Bunny", Chance = 55, Color = Color3.fromRGB(245, 245, 245)},
	{Name = "Fox", Chance = 30, Color = Color3.fromRGB(255, 145, 70)},
	{Name = "Dragon", Chance = 12, Color = Color3.fromRGB(115, 200, 255)},
	{Name = "Golden Dragon", Chance = 3, Color = Color3.fromRGB(255, 215, 70)},
}

local function getCoins(player)
	local stats = player:FindFirstChild("leaderstats")
	return stats and stats:FindFirstChild("Coins")
end

local function choosePet()
	local roll = math.random(1, 100)
	local total = 0

	for _, pet in ipairs(PETS) do
		total += pet.Chance
		if roll <= total then
			return pet
		end
	end

	return PETS[1]
end

local function createPetDisplay(player, pet)
	local character = player.Character
	if not character then return end

	local oldPet = character:FindFirstChild("EquippedPet")
	if oldPet then
		oldPet:Destroy()
	end

	local model = Instance.new("Model")
	model.Name = "EquippedPet"
	model.Parent = character

	local body = Instance.new("Part")
	body.Name = "Pet"
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.new(2.8, 2.8, 2.8)
	body.Anchored = true
	body.CanCollide = false
	body.CanTouch = false
	body.Material = Enum.Material.Neon
	body.Color = pet.Color
	body.Parent = model

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(190, 45)
	gui.StudsOffset = Vector3.new(0, 2.5, 0)
	gui.AlwaysOnTop = true
	gui.Parent = body

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 0.1
	label.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	label.Text = pet.Name .. "  +25%"
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Parent = gui

	local connection
	connection = game:GetService("RunService").Heartbeat:Connect(function()
		if not model.Parent or not character.Parent then
			connection:Disconnect()
			return
		end

		local root = character:FindFirstChild("HumanoidRootPart")
		if root then
			body.CFrame = root.CFrame
				* CFrame.new(3, 2, 3)
				* CFrame.Angles(0, math.rad(os.clock() * 80), 0)
		end
	end)
end

local function createEgg()
	local egg = Instance.new("Part")
	egg.Name = "PetEgg"
	egg.Shape = Enum.PartType.Ball
	egg.Size = Vector3.new(8, 10, 8)
	egg.Position = Vector3.new(0, 5, -28)
	egg.Anchored = true
	egg.Material = Enum.Material.Neon
	egg.Color = Color3.fromRGB(180, 100, 255)
	egg.Parent = petFolder

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Hatch for 150"
	prompt.ObjectText = "Pet Egg"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 15
	prompt.RequiresLineOfSight = false
	prompt.Parent = egg

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(270, 75)
	gui.StudsOffset = Vector3.new(0, 7, 0)
	gui.AlwaysOnTop = true
	gui.Parent = egg

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 0.15
	label.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	label.Text = "PET EGG\n150 COINS"
	label.TextColor3 = Color3.fromRGB(255, 230, 120)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = label

	prompt.Triggered:Connect(function(player)
		local coins = getCoins(player)
		if not coins or coins.Value < EGG_COST then
			return
		end

		coins.Value -= EGG_COST

		local pet = choosePet()
		player:SetAttribute("PetName", pet.Name)
		player:SetAttribute("PetBonus", PET_BONUS)
		createPetDisplay(player, pet)

		local playerGui = player:FindFirstChild("PlayerGui")
		local hud = playerGui and playerGui:FindFirstChild("CoinHuntHUD")
		if hud and hud:FindFirstChild("Pop") then
			hud.Pop.Text = "HATCHED: " .. pet.Name .. "  (+25%)"
			hud.Pop.TextTransparency = 0
			task.delay(2, function()
				if hud and hud:FindFirstChild("Pop") then
					hud.Pop.TextTransparency = 1
				end
			end)
		end
	end)
end

local function setupPlayer(player)
	if player:GetAttribute("PetName") == nil then
		player:SetAttribute("PetName", "None")
	end

	if player:GetAttribute("PetBonus") == nil then
		player:SetAttribute("PetBonus", 0)
	end

	player.CharacterAdded:Connect(function()
		task.wait(1)
		local petName = player:GetAttribute("PetName")
		if petName and petName ~= "None" then
			for _, pet in ipairs(PETS) do
				if pet.Name == petName then
					createPetDisplay(player, pet)
					break
				end
			end
		end
	end)
end

Players.PlayerAdded:Connect(setupPlayer)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(setupPlayer, player)
end

createEgg()

print("[Coin Hunt] Fixed Pet System loaded")
