-- The round system for one of my hobby projects:

-- It loads all players from the lobby into the round. It also updates
-- state through a value called "Status". Handles the game's entire core-loop.
-- Core Loop: Lobby -> Map -> Round Ended (no more remaining players or all players survived) -> Lobby

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local mapsFolder = ReplicatedStorage.Maps
local settingsFolder = ReplicatedStorage.Settings

local previousMapName = ""

local function getBaseMap()
	if #mapsFolder:GetChildren() == 1 then
		return mapsFolder:GetChildren()[1]
	end
	
	local baseMap = mapsFolder:GetChildren()[Random.new():NextInteger(1, #mapsFolder:GetChildren())]
	if baseMap.Name == previousMapName then
		RunService.Heartbeat:Wait()
		return getBaseMap()
	end
	
	return baseMap
end

local function canStartRound()
	if #Players:GetPlayers() <= 0 then
		return
	end
	
	for _, player in ipairs(Players:GetPlayers()) do
		if not player.Character then
			return
		end
		
		if player.Character.Humanoid.Health <= 0 then
			return
		end
		
		if player.Character.Humanoid:GetState() == Enum.HumanoidStateType.Dead then
			return
		end
	end
	
	return true
end

local function checkRound()
	if not canStartRound() then
		ReplicatedStorage.Status.Value = "WAITING FOR PLAYERS..."
		repeat RunService.Heartbeat:Wait() until canStartRound()
	end
end

assert(#mapsFolder:GetChildren() > 0, "Expected at least one map inside " .. mapsFolder:GetFullName())

while true do
	checkRound()

	for i = settingsFolder.IntermissionTime.Value, 0, -1 do
		ReplicatedStorage.Status.Value = "INTERMISSION: ".. i
		wait(1)
	end
	
	checkRound()
	
	local map = getBaseMap():Clone()
	map.Parent = Workspace.Round
	
	previousMapName = map.Name
	
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if not character then
			continue
		end
		
		character.HumanoidRootPart.Anchored = true
		character.HumanoidRootPart.CFrame = map.Requirements.PlayerSpawn.CFrame
		character.Humanoid.Died:Connect(function()
			CollectionService:RemoveTag(player, "InRound")
		end)
		
		CollectionService:AddTag(player, "InRound")
		
		delay(5, function()
			character.HumanoidRootPart.Anchored = false
		end)
	end
	
	local mapScript = map:FindFirstChild("MapScript")
	if mapScript then
		mapScript.Disabled = false
	end
	
	local canFinishRound = false
	local roundStart = os.clock()
	
	local checkFinishRound
	checkFinishRound = RunService.Heartbeat:Connect(function()
		if os.clock() - roundStart >= map.Settings.RoundTime.Value then
			canFinishRound = true
			return
		end
		
		if #CollectionService:GetTagged("InRound") == 0 then
			canFinishRound = true
			return
		end
	end)
	
	coroutine.wrap(function()
		for i = map.Settings.RoundTime.Value, 0, -1 do
			if canFinishRound then 
				break
			end
			ReplicatedStorage.Status.Value = "TIME LEFT: ".. i
			wait(1)
		end
	end)()
	
	repeat RunService.Heartbeat:Wait() until canFinishRound
	
	map:Destroy()
	map = nil
	
	checkFinishRound:Disconnect()
	checkFinishRound = nil
	
	for _, inRoundPlayer in ipairs(CollectionService:GetTagged("InRound")) do
		CollectionService:RemoveTag(inRoundPlayer, "InRound")
		
		local character = inRoundPlayer.Character
		if not character then
			continue
		end
		
		for _, descendant in ipairs(character:GetDescendants()) do
			if descendant:IsA("Tool") then
				descendant:Destroy()
				descendant = nil
			end
		end
		
		for _, descendant in ipairs(inRoundPlayer.Backpack:GetDescendants()) do
			if descendant:IsA("Tool") then
				descendant:Destroy()
				descendant = nil
			end
		end

		character.HumanoidRootPart.CFrame = Workspace.LobbySpawn.CFrame
	end
	
	ReplicatedStorage.Status.Value = "ROUND ENDED!"
	wait(3)
end
