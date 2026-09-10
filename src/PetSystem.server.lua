-- COIN HUNT PET SYSTEM
-- Roblox Studio: ServerScriptService > PetSystem

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local EGG_COST = 150
local PET_BONUS = 0.25 -- +25% coin reward

local petFolder = Workspace:FindFirstChild("CoinHuntPets")
if petFolder then
	petFolder:Destroy()
end

petFolder = Instance.new("Folder")
petFolder.Name = "CoinHuntPets"
petFolder.Parent = Workspace

local PETS = {
	{Name = "Bunny", Chance = 55},
	{Name = "Fox", Chance = 30},
	{Name = "Dragon", Chance = 12},
	{Name = "Golden Dragon", Chance = 3},
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

local function createPetDisplay(player, petName)
	local character = player.Character
	if not character then return end

	local old = character:FindFirstChild("EquippedPet")
	if old then
		old:Destroy()
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
	body.Material = Enum.Material.Neon
	body.Color = Color3.fromRGB(255, 220, 80)
	body.Parent = model

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(180, 45)
	gui.StudsOffset = Vector3.new(0, 2.5, 0)
	gui.AlwaysOnTop = true
	gui.Parent = body

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = petName
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Parent = gui

	task.spawn(function()
		while model.Parent and character.Parent do
			local root = character:FindFirstChild("HumanoidRootPart")
			if root then
				body.CFrame =
					root.CFrame
					* CFrame.new(3, 2, 3)
					* CFrame.Angles(0, math.rad(os.clock() * 80), 0)
			end
			task.wait()
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
	prompt.ActionText = "Hatch"
	prompt.ObjectText = "Pet Egg - 150 Coins"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 15
	prompt.Parent = egg

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(260, 70)
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

		createPetDisplay(player, pet.Name)

		-- Tell the player through a simple notification.
		local playerGui = player:FindFirstChild("PlayerGui")
		local hud = playerGui and playerGui:FindFirstChild("CoinHuntHUD")

		if hud and hud:FindFirstChild("Pop") then
			hud.Pop.Text = "HATCHED: " .. pet.Name
			hud.Pop.TextTransparency = 0

			task.delay(2, function()
				if hud and hud:FindFirstChild("Pop") then
					hud.Pop.TextTransparency = 1
				end
			end)
		end
	end)
end

Players.PlayerAdded:Connect(function(player)
	player:SetAttribute("PetName", "None")
	player:SetAttribute("PetBonus", 0)

	player.CharacterAdded:Connect(function()
		task.wait(1)

		local petName = player:GetAttribute("PetName")
		if petName and petName ~= "None" then
			createPetDisplay(player, petName)
		end
	end)
end)

for _, player in ipairs(Players:GetPlayers()) do
	player:SetAttribute("PetName", "None")
	player:SetAttribute("PetBonus", 0)
end

createEgg()

print("[Coin Hunt] Pet System loaded!")