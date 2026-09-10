-- COIN HUNT: ADVENTURE EDITION
-- Put in Roblox Studio: ServerScriptService > CoinGame
-- Gameplay: explore -> collect -> build combo -> finish quest -> catch Golden Rush

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local MAP_SIZE = 650
local COIN_COUNT = 110
local COIN_RESPAWN = 7
local COMBO_WINDOW = 4
local QUEST_GOAL = 25
local QUEST_REWARD = 50
local GOLDEN_RUSH_LENGTH = 30
local GOLDEN_RUSH_INTERVAL = 120

local rng = Random.new(os.time())

-- Clean generated folders when the server starts.
for _, name in ipairs({"CoinHuntWorld", "CoinHuntCoins"}) do
	local old = Workspace:FindFirstChild(name)
	if old then old:Destroy() end
end

local world = Instance.new("Folder")
world.Name = "CoinHuntWorld"
world.Parent = Workspace

local coinFolder = Instance.new("Folder")
coinFolder.Name = "CoinHuntCoins"
coinFolder.Parent = Workspace

local function makePart(name, size, position, material, parent, color, transparency)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = position
	p.Anchored = true
	p.Material = material or Enum.Material.SmoothPlastic
	p.Color = color or Color3.fromRGB(255, 255, 255)
	p.Transparency = transparency or 0
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function addBillboard(parent, text, width, height, offset)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Sign"
	gui.Size = UDim2.fromOffset(width, height)
	gui.StudsOffset = offset or Vector3.new(0, 5, 0)
	gui.AlwaysOnTop = true
	gui.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 0.15
	label.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
	label.Text = text
	label.TextColor3 = Color3.fromRGB(255, 236, 120)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = label

	return gui
end

-- =========================
-- WORLD
-- =========================

makePart(
	"MainGrass",
	Vector3.new(MAP_SIZE, 2, MAP_SIZE),
	Vector3.new(0, -1, 0),
	Enum.Material.Grass,
	world,
	Color3.fromRGB(78, 168, 89)
)

local plaza = makePart(
	"SpawnPlaza",
	Vector3.new(110, 1, 110),
	Vector3.new(0, 0.05, 0),
	Enum.Material.Slate,
	world,
	Color3.fromRGB(86, 89, 102)
)

local glow = makePart(
	"PlazaGlow",
	Vector3.new(72, 0.25, 72),
	Vector3.new(0, 0.7, 0),
	Enum.Material.Neon,
	world,
	Color3.fromRGB(45, 200, 125),
	0.72
)

local spawn = Instance.new("SpawnLocation")
spawn.Name = "HiddenSpawn"
spawn.Size = Vector3.new(8, 1, 8)
spawn.Position = Vector3.new(0, 2, 0)
spawn.Anchored = true
spawn.Transparency = 1
spawn.CanCollide = true
spawn.Neutral = true
spawn.Parent = world

addBillboard(plaza, "COIN HUNT\nEXPLORE • COLLECT • COMBO", 300, 78, Vector3.new(0, 9, 0))

-- Roads pull players toward the outer zones.
for _, data in ipairs({
	{Vector3.new(0, 0.2, -175), Vector3.new(32, 0.4, 260)},
	{Vector3.new(0, 0.2, 175), Vector3.new(32, 0.4, 260)},
	{Vector3.new(-175, 0.2, 0), Vector3.new(260, 0.4, 32)},
	{Vector3.new(175, 0.2, 0), Vector3.new(260, 0.4, 32)},
}) do
	makePart("Path", data[2], data[1], Enum.Material.Cobblestone, world, Color3.fromRGB(145, 140, 120))
end

local zones = {
	{
		name = "Emerald Forest",
		pos = Vector3.new(-205, 0, -205),
		color = Color3.fromRGB(55, 190, 100),
		accent = Color3.fromRGB(120, 255, 160)
	},
	{
		name = "Sunny Village",
		pos = Vector3.new(205, 0, -205),
		color = Color3.fromRGB(244, 198, 78),
		accent = Color3.fromRGB(255, 236, 130)
	},
	{
		name = "Crystal Valley",
		pos = Vector3.new(-205, 0, 205),
		color = Color3.fromRGB(90, 160, 230),
		accent = Color3.fromRGB(150, 230, 255)
	},
	{
		name = "Mystic Ruins",
		pos = Vector3.new(205, 0, 205),
		color = Color3.fromRGB(165, 100, 205),
		accent = Color3.fromRGB(220, 170, 255)
	},
}

for _, zone in ipairs(zones) do
	local platform = makePart(
		"ZonePlatform",
		Vector3.new(130, 1, 130),
		zone.pos + Vector3.new(0, 0.2, 0),
		Enum.Material.SmoothPlastic,
		world,
		zone.color,
		0.1
	)

	local sign = makePart(
		"ZoneSign",
		Vector3.new(3, 10, 3),
		zone.pos + Vector3.new(0, 5, -57),
		Enum.Material.Wood,
		world,
		Color3.fromRGB(110, 76, 44)
	)
	addBillboard(sign, zone.name, 220, 50, Vector3.new(0, 6, 0))

	for _, offset in ipairs({
		Vector3.new(-58, 5, -58),
		Vector3.new(58, 5, -58),
		Vector3.new(-58, 5, 58),
		Vector3.new(58, 5, 58),
	}) do
		local pillar = makePart(
			"Pillar",
			Vector3.new(5, 10, 5),
			zone.pos + offset,
			Enum.Material.SmoothPlastic,
			world,
			zone.accent
		)

		local light = Instance.new("PointLight")
		light.Color = zone.accent
		light.Brightness = 1.5
		light.Range = 18
		light.Parent = pillar
	end
end

local function createTree(pos, scale)
	scale = scale or 1

	local model = Instance.new("Model")
	model.Name = "Tree"
	model.Parent = world

	local trunk = makePart(
		"Trunk",
		Vector3.new(2.3, 10, 2.3) * scale,
		pos + Vector3.new(0, 5 * scale, 0),
		Enum.Material.Wood,
		model,
		Color3.fromRGB(100, 68, 40)
	)

	local crown = Instance.new("Part")
	crown.Name = "Leaves"
	crown.Shape = Enum.PartType.Ball
	crown.Size = Vector3.new(11, 11, 11) * scale
	crown.Position = pos + Vector3.new(0, 11 * scale, 0)
	crown.Anchored = true
	crown.Material = Enum.Material.Grass
	crown.Color = Color3.fromRGB(43, 146, 72)
	crown.Parent = model
end

for _ = 1, 120 do
	local x = rng:NextInteger(-MAP_SIZE / 2 + 20, MAP_SIZE / 2 - 20)
	local z = rng:NextInteger(-MAP_SIZE / 2 + 20, MAP_SIZE / 2 - 20)

	if math.abs(x) > 60 or math.abs(z) > 60 then
		createTree(Vector3.new(x, 0, z), rng:NextNumber(0.8, 1.25))
	end
end

local function createHouse(pos, roofColor)
	local model = Instance.new("Model")
	model.Name = "House"
	model.Parent = world

	makePart(
		"HouseBody",
		Vector3.new(24, 14, 20),
		pos + Vector3.new(0, 7, 0),
		Enum.Material.SmoothPlastic,
		model,
		Color3.fromRGB(235, 221, 195)
	)

	makePart(
		"Roof",
		Vector3.new(27, 3, 23),
		pos + Vector3.new(0, 15, 0),
		Enum.Material.Slate,
		model,
		roofColor or Color3.fromRGB(132, 70, 70)
	)

	makePart(
		"Door",
		Vector3.new(4, 7, 1),
		pos + Vector3.new(0, 3.5, -10.5),
		Enum.Material.Wood,
		model,
		Color3.fromRGB(92, 62, 40)
	)

	local w1 = makePart(
		"Window",
		Vector3.new(5, 4, 1),
		pos + Vector3.new(-7, 7, -10.5),
		Enum.Material.Glass,
		model,
		Color3.fromRGB(115, 210, 255),
		0.25
	)

	local w2 = makePart(
		"Window",
		Vector3.new(5, 4, 1),
		pos + Vector3.new(7, 7, -10.5),
		Enum.Material.Glass,
		model,
		Color3.fromRGB(115, 210, 255),
		0.25
	)
end

createHouse(Vector3.new(175, 0, -250), Color3.fromRGB(196, 85, 95))
createHouse(Vector3.new(235, 0, -175), Color3.fromRGB(85, 117, 196))
createHouse(Vector3.new(130, 0, -185), Color3.fromRGB(80, 170, 90))

for i = 1, 18 do
	local angle = (math.pi * 2 / 18) * i
	local r = 48
	local p = zones[4].pos + Vector3.new(math.cos(angle) * r, 4, math.sin(angle) * r)

	makePart(
		"RuinStone",
		Vector3.new(6, 8, 4),
		p,
		Enum.Material.Rock,
		world,
		Color3.fromRGB(94, 82, 110)
	)
end

-- =========================
-- PLAYER STATE + HUD
-- =========================

local playerState = {}

local function getCoins(player)
	local stats = player:FindFirstChild("leaderstats")
	return stats and stats:FindFirstChild("Coins")
end

local function updateHUD(player)
	local state = playerState[player]
	local gui = player:FindFirstChild("PlayerGui") and player.PlayerGui:FindFirstChild("CoinHuntHUD")
	if not state or not gui then return end

	local stats = player:FindFirstChild("leaderstats")
	local coins = stats and stats:FindFirstChild("Coins")
	local level = stats and stats:FindFirstChild("Level")

	gui.TopBar.Coins.Text = "Coins  " .. tostring(coins and coins.Value or 0)
	gui.TopBar.Level.Text = "Level  " .. tostring(level and level.Value or 1)
	gui.TopBar.Streak.Text = "Streak  " .. tostring(state.streak)

	local progress = math.clamp(state.questCoins / QUEST_GOAL, 0, 1)
	gui.Quest.BarBack.Fill.Size = UDim2.fromScale(progress, 1)

	if state.questComplete then
		gui.Quest.Title.Text = "QUEST COMPLETE!  +50 BONUS"
	else
		gui.Quest.Title.Text = string.format(
			"QUEST • COLLECT %d COINS  (%d/%d)",
			QUEST_GOAL,
			math.min(state.questCoins, QUEST_GOAL),
			QUEST_GOAL
		)
	end
end

local function popup(player, text)
	local gui = player:FindFirstChild("PlayerGui") and player.PlayerGui:FindFirstChild("CoinHuntHUD")
	if not gui then return end

	local label = gui.Pop
	label.Text = text
	label.TextTransparency = 0
	label.Position = UDim2.new(0.5, -250, 0.40, 0)

	local tween = TweenService:Create(
		label,
		TweenInfo.new(1.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			TextTransparency = 1,
			Position = UDim2.new(0.5, -250, 0.34, 0)
		}
	)

	tween:Play()
end

local function makeHUD(player)
	local playerGui = player:WaitForChild("PlayerGui")
	local old = playerGui:FindFirstChild("CoinHuntHUD")
	if old then old:Destroy() end

	local screen = Instance.new("ScreenGui")
	screen.Name = "CoinHuntHUD"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.Parent = playerGui

	local top = Instance.new("Frame")
	top.Name = "TopBar"
	top.Size = UDim2.fromOffset(560, 78)
	top.Position = UDim2.new(0.5, -280, 0, 18)
	top.BackgroundColor3 = Color3.fromRGB(24, 25, 34)
	top.BackgroundTransparency = 0.08
	top.Parent = screen

	local topCorner = Instance.new("UICorner")
	topCorner.CornerRadius = UDim.new(0, 18)
	topCorner.Parent = top

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 222, 80)
	stroke.Transparency = 0.4
	stroke.Thickness = 2
	stroke.Parent = top

	local function statLabel(name, x, prefix)
		local label = Instance.new("TextLabel")
		label.Name = name
		label.Size = UDim2.fromOffset(165, 64)
		label.Position = UDim2.fromOffset(x, 7)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBold
		label.TextSize = 22
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.Text = prefix .. " 0"
		label.Parent = top
		return label
	end

	statLabel("Coins", 12, "Coins")
	statLabel("Level", 194, "Level")
	statLabel("Streak", 376, "Streak")

	local quest = Instance.new("Frame")
	quest.Name = "Quest"
	quest.Size = UDim2.fromOffset(420, 84)
	quest.Position = UDim2.new(0.5, -210, 1, -110)
	quest.BackgroundColor3 = Color3.fromRGB(24, 25, 34)
	quest.BackgroundTransparency = 0.08
	quest.Parent = screen

	local qCorner = Instance.new("UICorner")
	qCorner.CornerRadius = UDim.new(0, 18)
	qCorner.Parent = quest

	local qTitle = Instance.new("TextLabel")
	qTitle.Name = "Title"
	qTitle.Size = UDim2.new(1, -28, 0, 30)
	qTitle.Position = UDim2.fromOffset(14, 7)
	qTitle.BackgroundTransparency = 1
	qTitle.Font = Enum.Font.GothamBold
	qTitle.TextSize = 18
	qTitle.TextXAlignment = Enum.TextXAlignment.Left
	qTitle.TextColor3 = Color3.fromRGB(255, 231, 112)
	qTitle.Text = "QUEST • COLLECT 25 COINS  (0/25)"
	qTitle.Parent = quest

	local barBack = Instance.new("Frame")
	barBack.Name = "BarBack"
	barBack.Size = UDim2.new(1, -28, 0, 18)
	barBack.Position = UDim2.fromOffset(14, 46)
	barBack.BackgroundColor3 = Color3.fromRGB(52, 54, 68)
	barBack.Parent = quest

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(1, 0)
	barCorner.Parent = barBack

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = Color3.fromRGB(255, 210, 55)
	fill.Parent = barBack

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = fill

	local event = Instance.new("TextLabel")
	event.Name = "Event"
	event.Size = UDim2.fromOffset(300, 42)
	event.Position = UDim2.new(1, -320, 0, 115)
	event.BackgroundColor3 = Color3.fromRGB(70, 45, 125)
	event.BackgroundTransparency = 0.1
	event.Font = Enum.Font.GothamBold
	event.TextSize = 17
	event.TextColor3 = Color3.fromRGB(255, 240, 170)
	event.Text = "Golden Rush soon..."
	event.Parent = screen

	local eventCorner = Instance.new("UICorner")
	eventCorner.CornerRadius = UDim.new(0, 14)
	eventCorner.Parent = event

	local pop = Instance.new("TextLabel")
	pop.Name = "Pop"
	pop.Size = UDim2.fromOffset(500, 90)
	pop.Position = UDim2.new(0.5, -250, 0.38, 0)
	pop.BackgroundTransparency = 1
	pop.Font = Enum.Font.GothamBlack
	pop.TextScaled = true
	pop.TextColor3 = Color3.fromRGB(255, 229, 82)
	pop.TextTransparency = 1
	pop.Text = ""
	pop.Parent = screen

	return screen
end

local function setupPlayer(player)
	if playerState[player] then return end

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = 0
	coins.Parent = leaderstats

	local level = Instance.new("IntValue")
	level.Name = "Level"
	level.Value = 1
	level.Parent = leaderstats

	local best = Instance.new("IntValue")
	best.Name = "BestStreak"
	best.Value = 0
	best.Parent = leaderstats

	playerState[player] = {
		streak = 0,
		lastCollect = 0,
		questCoins = 0,
		questComplete = false
	}

	coins.Changed:Connect(function()
		level.Value = math.floor(coins.Value / 50) + 1
		updateHUD(player)
	end)

	task.spawn(function()
		makeHUD(player)
		updateHUD(player)
	end)
end

Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(function(player)
	playerState[player] = nil
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(setupPlayer, player)
end

-- =========================
-- COINS
-- =========================

local COIN_TYPES = {
	{name = "Gold", value = 1, color = Color3.fromRGB(255, 220, 70), scale = 1.00, weight = 70},
	{name = "Blue", value = 3, color = Color3.fromRGB(90, 200, 255), scale = 1.05, weight = 20},
	{name = "Purple", value = 5, color = Color3.fromRGB(205, 120, 255), scale = 1.12, weight = 8},
	{name = "Diamond", value = 10, color = Color3.fromRGB(255, 125, 210), scale = 1.22, weight = 2},
}

local function pickCoinType()
	local roll = rng:NextInteger(1, 100)
	local total = 0

	for _, info in ipairs(COIN_TYPES) do
		total += info.weight
		if roll <= total then
			return info
		end
	end

	return COIN_TYPES[1]
end

local function rewardPlayer(player, baseValue, coinName)
	local coins = getCoins(player)
	local state = playerState[player]
	if not coins or not state then return end

	local now = os.clock()

	if now - state.lastCollect <= COMBO_WINDOW then
		state.streak += 1
	else
		state.streak = 1
	end

	state.lastCollect = now

	local multiplier = 1
	if state.streak >= 25 then
		multiplier = 4
	elseif state.streak >= 15 then
		multiplier = 3
	elseif state.streak >= 8 then
		multiplier = 2
	end

	local streakBonus = math.floor((state.streak - 1) / 5)
	local amount = baseValue * multiplier + streakBonus

	coins.Value += amount
	state.questCoins += 1

	local best = player.leaderstats:FindFirstChild("BestStreak")
	if best and state.streak > best.Value then
		best.Value = state.streak
	end

	if state.questCoins >= QUEST_GOAL and not state.questComplete then
		state.questComplete = true
		coins.Value += QUEST_REWARD
		popup(player, "QUEST COMPLETE!  +50 COINS")
	elseif state.streak >= 25 then
		popup(player, "25 COMBO!  4X COINS")
	elseif state.streak >= 15 then
		popup(player, "15 COMBO!  3X COINS")
	elseif state.streak >= 8 then
		popup(player, "8 COMBO!  2X COINS")
	elseif baseValue >= 5 then
		popup(player, coinName .. "  +" .. amount)
	end

	updateHUD(player)
end

local function createCoin(position, forcedInfo, temporary)
	local info = forcedInfo or pickCoinType()

	local coin = Instance.new("Part")
	coin.Name = info.name .. "Coin"
	coin.Shape = Enum.PartType.Cylinder
	coin.Size = Vector3.new(0.9, 4.2, 4.2) * info.scale
	coin.Position = position + Vector3.new(0, 3, 0)
	coin.Orientation = Vector3.new(0, 0, 90)
	coin.Anchored = true
	coin.CanCollide = false
	coin.CanTouch = true
	coin.Material = Enum.Material.Neon
	coin.Color = info.color
	coin.Parent = coinFolder

	local light = Instance.new("PointLight")
	light.Color = info.color
	light.Brightness = 1.8
	light.Range = 13 * info.scale
	light.Parent = coin

	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Rate = info.value >= 5 and 7 or 2
	sparkles.Lifetime = NumberRange.new(0.3, 0.7)
	sparkles.Speed = NumberRange.new(0.2, 1)
	sparkles.SpreadAngle = Vector2.new(360, 360)
	sparkles.Parent = coin

	local collected = false
	local baseY = coin.Position.Y

	local spinConnection
	spinConnection = RunService.Heartbeat:Connect(function(dt)
		if not coin.Parent then
			spinConnection:Disconnect()
			return
		end

		coin.Orientation += Vector3.new(0, 180 * dt, 0)
		coin.Position = Vector3.new(
			coin.Position.X,
			baseY + math.sin(os.clock() * 2.7) * 0.7,
			coin.Position.Z
		)
	end)

	coin.Touched:Connect(function(hit)
		if collected or not coin.Parent then return end

		local character = hit.Parent
		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end

		collected = true
		rewardPlayer(player, info.value, info.name)

		coin.CanTouch = false
		coin.Transparency = 1
		light.Enabled = false
		sparkles.Enabled = false

		if temporary then
			task.delay(0.2, function()
				if coin.Parent then coin:Destroy() end
			end)
		else
			task.delay(COIN_RESPAWN, function()
				if coin.Parent then
					coin.Transparency = 0
					coin.CanTouch = true
					light.Enabled = true
					sparkles.Enabled = true
					collected = false
				end
			end)
		end
	end)

	return coin
end

for _ = 1, COIN_COUNT do
	local x = rng:NextInteger(-MAP_SIZE / 2 + 25, MAP_SIZE / 2 - 25)
	local z = rng:NextInteger(-MAP_SIZE / 2 + 25, MAP_SIZE / 2 - 25)

	if math.abs(x) > 45 or math.abs(z) > 45 then
		createCoin(Vector3.new(x, 0, z))
	end
end

-- =========================
-- GOLDEN RUSH
-- =========================

local goldenInfo = {
	name = "Golden",
	value = 10,
	color = Color3.fromRGB(255, 184, 30),
	scale = 1.35,
	weight = 1
}

local function setEventText(text)
	for _, player in ipairs(Players:GetPlayers()) do
		local gui = player:FindFirstChild("PlayerGui") and player.PlayerGui:FindFirstChild("CoinHuntHUD")
		if gui then
			gui.Event.Text = text
		end
	end
end

local function goldenRush()
	setEventText("GOLDEN RUSH! 30s")

	for _, player in ipairs(Players:GetPlayers()) do
		popup(player, "GOLDEN RUSH STARTED!")
	end

	local eventCoins = {}

	for i = 1, 22 do
		local angle = (i / 22) * math.pi * 2
		local radius = rng:NextInteger(120, 235)
		local pos = Vector3.new(
			math.cos(angle) * radius,
			0,
			math.sin(angle) * radius
		)

		eventCoins[#eventCoins + 1] = createCoin(pos, goldenInfo, true)
	end

	for seconds = GOLDEN_RUSH_LENGTH, 1, -1 do
		setEventText("GOLDEN RUSH! " .. seconds .. "s")
		task.wait(1)
	end

	for _, coin in ipairs(eventCoins) do
		if coin and coin.Parent then
			coin:Destroy()
		end
	end

	setEventText("Next Golden Rush in 120s")
end

task.spawn(function()
	while true do
		task.wait(GOLDEN_RUSH_INTERVAL)
		goldenRush()
	end
end)

task.spawn(function()
	while true do
		task.wait(1)

		local now = os.clock()

		for player, state in pairs(playerState) do
			if now - state.lastCollect > COMBO_WINDOW and state.streak ~= 0 then
				state.streak = 0
				updateHUD(player)
			end
		end
	end
end)

print("[Coin Hunt] Adventure Edition loaded")
print("[Coin Hunt] Coins:", COIN_COUNT)
print("[Coin Hunt] Golden Rush every", GOLDEN_RUSH_INTERVAL, "seconds")
