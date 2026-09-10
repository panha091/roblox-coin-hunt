-- COIN HUNT SHOP - FIXED
-- Roblox Studio: ServerScriptService > CoinShop
-- Speed Boost costs 25 coins. 2x Coins costs 100 coins.
-- The 2x upgrade uses CoinMultiplier so CoinGame can reliably apply it.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local SPEED_COST = 25
local DOUBLE_COST = 100

local SHOP_FOLDER_NAME = "CoinHuntShop"

local oldShop = Workspace:FindFirstChild(SHOP_FOLDER_NAME)
if oldShop then
	oldShop:Destroy()
end

local shopFolder = Instance.new("Folder")
shopFolder.Name = SHOP_FOLDER_NAME
shopFolder.Parent = Workspace

local function makeShopPart(name, position, color, actionText, objectText)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = Vector3.new(12, 8, 12)
	part.Position = position
	part.Anchored = true
	part.Material = Enum.Material.SmoothPlastic
	part.Color = color
	part.Parent = shopFolder

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 15
	prompt.RequiresLineOfSight = false
	prompt.Parent = part

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(250, 72)
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
	label.Text = objectText
	label.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = label

	return prompt
end

local speedPrompt = makeShopPart(
	"SpeedBoostShop",
	Vector3.new(-22, 4, 0),
	Color3.fromRGB(70, 170, 255),
	"Buy for 25",
	"Speed Boost\n25 Coins"
)

local doublePrompt = makeShopPart(
	"DoubleCoinsShop",
	Vector3.new(22, 4, 0),
	Color3.fromRGB(255, 190, 55),
	"Buy for 100",
	"2x Coins\n100 Coins"
)

local function getCoins(player)
	local stats = player:FindFirstChild("leaderstats")
	return stats and stats:FindFirstChild("Coins")
end

local function buySpeed(player)
	if player:GetAttribute("SpeedBoost") then
		return
	end

	local coins = getCoins(player)
	if not coins or coins.Value < SPEED_COST then
		return
	end

	coins.Value -= SPEED_COST
	player:SetAttribute("SpeedBoost", true)

	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = 24
		end
	end
end

local function buyDouble(player)
	if player:GetAttribute("CoinMultiplier") and player:GetAttribute("CoinMultiplier") >= 2 then
		return
	end

	local coins = getCoins(player)
	if not coins or coins.Value < DOUBLE_COST then
		return
	end

	coins.Value -= DOUBLE_COST
	player:SetAttribute("DoubleCoins", true)
	player:SetAttribute("CoinMultiplier", 2)
end

speedPrompt.Triggered:Connect(buySpeed)
doublePrompt.Triggered:Connect(buyDouble)

local function setupPlayer(player)
	if player:GetAttribute("SpeedBoost") == nil then
		player:SetAttribute("SpeedBoost", false)
	end

	if player:GetAttribute("DoubleCoins") == nil then
		player:SetAttribute("DoubleCoins", false)
	end

	if player:GetAttribute("CoinMultiplier") == nil then
		player:SetAttribute("CoinMultiplier", player:GetAttribute("DoubleCoins") and 2 or 1)
	end

	player.CharacterAdded:Connect(function(character)
		if player:GetAttribute("SpeedBoost") then
			local humanoid = character:WaitForChild("Humanoid", 10)
			if humanoid then
				humanoid.WalkSpeed = 24
			end
		end
	end)
end

Players.PlayerAdded:Connect(setupPlayer)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(setupPlayer, player)
end

print("[Coin Hunt] Fixed Shop loaded")
