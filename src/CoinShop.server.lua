-- COIN HUNT SHOP
-- Put this file in Roblox Studio: ServerScriptService > CoinShop

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local SHOP_COSTS = {
	Speed = 25,
	DoubleCoins = 100,
}

local SHOP_FOLDER_NAME = "CoinHuntShop"

local oldShop = Workspace:FindFirstChild(SHOP_FOLDER_NAME)
if oldShop then
	oldShop:Destroy()
end

local shopFolder = Instance.new("Folder")
shopFolder.Name = SHOP_FOLDER_NAME
shopFolder.Parent = Workspace

local function createShop(name, position, color)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = Vector3.new(12, 8, 12)
	part.Position = position
	part.Anchored = true
	part.Material = Enum.Material.SmoothPlastic
	part.Color = color
	part.Parent = shopFolder

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Buy"
	prompt.ObjectText = name
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 12
	prompt.Parent = part

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(220, 70)
	billboard.StudsOffset = Vector3.new(0, 7, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = part

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 0.15
	label.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Text = name
	label.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = label

	return prompt
end

-- Put the shop near the center plaza.
local speedPrompt = createShop(
	"Speed Boost - 25 Coins",
	Vector3.new(-20, 4, 0),
	Color3.fromRGB(70, 170, 255)
)

local doublePrompt = createShop(
	"2x Coins - 100 Coins",
	Vector3.new(20, 4, 0),
	Color3.fromRGB(255, 190, 55)
)

local function getCoins(player)
	local stats = player:FindFirstChild("leaderstats")
	return stats and stats:FindFirstChild("Coins")
end

speedPrompt.Triggered:Connect(function(player)
	local coins = getCoins(player)
	if not coins or coins.Value < SHOP_COSTS.Speed then
		return
	end

	coins.Value -= SHOP_COSTS.Speed

	player:SetAttribute("SpeedBoost", true)

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	if humanoid then
		humanoid.WalkSpeed = 24
	end
end)

doublePrompt.Triggered:Connect(function(player)
	local coins = getCoins(player)
	if not coins or coins.Value < SHOP_COSTS.DoubleCoins then
		return
	end

	if player:GetAttribute("DoubleCoins") then
		return
	end

	coins.Value -= SHOP_COSTS.DoubleCoins
	player:SetAttribute("DoubleCoins", true)
end)

Players.PlayerAdded:Connect(function(player)
	player:SetAttribute("SpeedBoost", false)
	player:SetAttribute("DoubleCoins", false)

	player.CharacterAdded:Connect(function(character)
		if player:GetAttribute("SpeedBoost") then
			local humanoid = character:WaitForChild("Humanoid")
			humanoid.WalkSpeed = 24
		end
	end)
end)

print("[Coin Hunt] Shop loaded!")