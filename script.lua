if not DrawFont then return error'you need v3 for this script' end
--// start esp
if getgenv().Destroy then Destroy() end
local startTime = tick()
local unloaded, window = false

local players = game:GetService("Players")
local localPlayer = players.LocalPlayer
local mouse = localPlayer:GetMouse()

local runService = game:GetService("RunService")

local camera = game:GetService("Workspace").CurrentCamera
local getPartsObscuringTarget = camera.getPartsObscuringTarget; getPartsObscuringTarget = function(...) getPartsObscuringTarget(camera, ...) end
local viewportSize = camera.ViewportSize

local highlightFolder = Instance.new("Folder"); highlightFolder.Name = syn.crypto.random(math.random(12, 16)); highlightFolder.Parent = gethui()

local textFont, fontSize = nil, 13; do
	if not isfolder("x_up/fonts") then
		makefolder("x_up/fonts")
	end
	local function getFont(fontName)
		local filePath, font = "x_up/fonts/"..fontName..".otf", nil
		if not isfile(filePath) then
			font = game:HttpGet("http://phantomgui.xyz/dev/espfonts/"..fontName..".otf")
			writefile(filePath, font)
		else
			font = readfile(filePath)
		end
		return font
	end

	textFont = DrawFont.Register(getFont("Montserrat-Medium"), {
		Scale = false;
		Bold = false;
		UseStb = false;
		PixelSize = fontSize
	})
end

local playerList, connects, playerTable, customCharacterFuncs, colors, games, settings, aimbotSettings = {}, {}, {}, {}, {
	Green = Color3.new(0, 1, 0);
	Red = Color3.new(1, 0, 0);
	White = Color3.new(1,1,1);
	Black = Color3.new();
}, {
	Rogue = game.GameId == 1087859240;
	Deepwoken = game.GameId == 1359573625;
	PF = game.GameId == 113491250;
	BB = game.GameId == 1168263273;
}, {
	ESP = {
		Enabled = true;
		ShowHealth = true;
		TeamColor = true;
		Chams = false;
		ChamsHealthColor = false;
		Tracers = false;
		Skeleton = true;
		Boxes = false;

		Text = {
			GameName = true;
			DisplayName = false;
			LowerCase = true;
			Distance = true;
			Health = true;
			HeldItem = true;
		}

		TransparencyRolloff = 350;
		MouseDistanceRolloff = 150;
	};
	Aimbot = {
		Enabled = false;
		FOV = 30;
		Prediction = true;
		SmoothingX = 10;
		SmoothingY = 10;
		TargetAll = false;
		TeamCheck = true;
		Wallcheck = true;
		BulletPenCheck = true;
		SmoothingType = "Linear";

		AimPart = "Head";
		HeadshotPercentage = 1;
		RealisticMovement = true;

		XRandomization = 3;
		YRandomization = 3;
		
		Smoothing = 1;
		WaitForZoomIn = true;
		ZoomInDelay = 0.15;

		TriggerBot = false;
		TriggerDelay = 0.04;
		TriggerHitPart = "Head";
		TriggerWhenAiming = true;
	};
}
local defaultProperties = {
	Box = {
		Thickness = 2;
		Color = colors.White; 
		Outlined = true;
		Rounding = 4;
		Visible = false;
	};
	Text = {
		Size = fontSize;
		Color = colors.White;
		Visible = false;
		YAlignment = YAlignment.Bottom;
		Font = textFont;
	};
	Highlight = {
		Enabled = false;
		FillColor = colors.White;
		OutlineColor = colors.Black;
		OutlineTransparency = 0.5;
		FillTransparency = 0.25;
	};
	Line = {
		Thickness = 2;
		Visible = false;
		Color = colors.White;
		Outlined = false;
	};
}
getgenv().Destroy = function()
	settings.ESP.Enabled = false;
	runService:UnbindFromRenderStep("x_upESP")

	for _,v in connects do v:Disconnect() end table.clear(connects) connects = nil
	for _,v in playerList do v:Destroy() end table.clear(playerList) playerList = nil

	highlightFolder:Destroy()

	getgenv().Destroy = nil

	if games.PF then
		actorEvent:Fire("Destroy")
		task.wait()
		table.clear(playerTable)
		playerTable = nil
	end

	if window then window:Remove() end
	unloaded = true
end


local customGames = {
	[1087859240] = { -- rogue / deepwoken
		init = function()
			customCharacterFuncs.getDisplayName = function(player)
				local character = player.Character; if not character then return "" end
				local humanoid = character:FindFirstChild("Humanoid"); if not humanoid then return "" end
				return self.Humanoid.DisplayName:split("\n")[1]
			end
		end
	};
	[113491250] = { -- phantom forces
		init = function()
			local actor, actorEvent
			for i,v in getactors() do if v.Name == "lol" then actor = v break end end; if not actor then return error'ERROR [PF-A]' end
			actorEvent = getluastate(actor).Event

			playerTable = {}
			customCharacterFuncs.characterAdded = SynSignal.new()
			customCharacterFuncs.characterRemoving = SynSignal.new()

			connects["pfUpdateEvent"] = actorEvent:Connect(function(event, ...)
				local args = {...}
				if event == "Update" then
					playerTable = args[1]
				elseif event == "CharacterAdded" then
					customCharacterFuncs.characterAdded:Fire(args[2], args[3])
				elseif event == "CharacterRemoving" then
					customCharacterFuncs.characterRemoving:Fire(args[2])
				end
			end)

			syn.run_on_actor(actor, [[
				local connects = {}
				local eventTable = {}

				local actorEvent = getluastate(actor).Event

				local req = getrenv().shared.require
				local modules = debug.getupvalue(req, 1); if not modules then return error'ERROR [PF-B]' end
				local _cache = rawget(modules, "_cache"); if not _cache then return error'ERROR [PF-C]' end
				local playerStatusEvents = rawget(rawget(_cache, "PlayerStatusEvents"), "module"); if not playerStatusEvents then return error'ERROR [PF-D]' end
				local repInterface = rawget(rawget(_cache, "ReplicationInterface"), "module"); if not repInterface then return error'ERROR [PF-E]' end
				local bulletCheck = rawget(rawget(_cache, "BulletCheck"), "module"); if not repInterface then return error'ERROR [PF-E]' end

				local onPlayerDied, onPlayerSpawned = rawget(playerStatusEvents, "onPlayerDied"), rawget(playerStatusEvents, "onPlayerSpawned"); if not onPlayerDied or not onPlayerSpawned then return error'ERROR [PF-F]' end

				local playerTable = debug.getupvalue(rawget(repInterface, "getEntry"), 1); if not playerTable then return error'ERROR [PF-G]' end

				local function getEntry(plr) return playerTable[plr] end

				local function isAlive(entry) return rawget(entry, "_alive") end

				local function getCharacterModel(entry)
					if typeof(entry) == "Instance" and entry:IsA("Player") then entry = getEntry(entry) end; if not entry then return end
					return isAlive(entry) and rawget(rawget(entry, "_thirdPersonObject"), "_character")
				end

				local function getPlayerHealth(entry)
					if typeof(entry) == "Instance" and entry:IsA("Player") then entry = getEntry(entry) end; if not entry then return end
					local healthState = rawget(entry, "_healthstate"); if not healthState then return 0, 100 end
					return rawget(healthState, "health0"), rawget(healthState, "maxhealth")
				end

				connects["CharacterAdded"] = onPlayerSpawned:Connect(function(player)
					actorEvent:Fire("CharacterAdded", player, getCharacterModel(entry))
				end)

				connects["CharacterRemoving"] = onPlayerDied:Connect(function(player)
					actorEvent:Fire("CharacterRemoving", player)
				end)

				connects["PFUpdate"] = game:GetService("RunService").RenderStepped:Connect(function()
					for player, entry in playerTable do
						local health, maxHealth = getPlayerHealth(entry)

						eventTable[player] = {
							Character = getCharacterModel(entry);
							Health = health;
							MaxHealth = maxHealth;
							Alive = isAlive(entry);
							Velocity = rawget(rawget(entry, "_velspring"), "t")
						}
					end
					actorEvent:Fire("Update", eventTable)
				end)

				connects["pfActorEvent"] = actorEvent:Connect(function(event, ...)
					if event == "Destroy" then
						for i,v in connects do v:Disconnect() end
						table.clear(connects)
						table.clear(eventTable)
					end
				end)
			]])
		end;
		getCharacter = function(player) 
			local entry = playerTable[player];
			return entry and entry.Character
		end;
		getRoot = function(character) 
			return character:WaitForChild("Torso", 3) 
		end;
		getHealth = function(player) 
			local entry = playerTable[player];
			return entry and entry.Health or 0, entry and entry.MaxHealth or 100
		end;
		getPredictedPosition = function(player)
			
		end
	};
	[1168263273] = { -- bad business
		init = function()
			local TS = require(game:GetService("ReplicatedStorage").TS) if typeof(TS) == "function" then TS = debug.getupvalue(TS, 2) end
			TS = getupvalue(getrawmetatable(TS).__index, 1); if typeof(TS) ~= "table" then return error'ERROR [BB-A]' end

			local characters = rawget(TS, "Characters"); if not characters then return error'ERROR [BB-B]' end
			local getCharacterFunc = rawget(characters, "GetCharacter"); if not getCharacterFunc then return error'ERROR [BB-C]' end
			playerTable = debug.getupvalue(getCharacterFunc, 1); if not playerTable then return error'ERROR [BB-D]' end

			local characterAddedSignal, characterRemovingSignal = SynSignal.new(), SynSignal.new()
			customCharacterFuncs.characterAdded = characterAddedSignal
			customCharacterFuncs.characterRemoving = characterRemovingSignal

			connects["bbCharacterAdded"] = rawget(characters, "CharacterAdded"):Connect(function(plr, char)
				characterAddedSignal:Fire(plr, char)
			end)

			connects["bbCharacterRemoving"] = rawget(rawget(TS, "Damage"), "CharacterKilled"):Connect(function(character, _, plr)
				characterRemovingSignal:Fire(plr)
			end)
		end;
		getCharacter = function(player)
			return playerTable[player]
		end;
		getRoot = function(character)
			return character:WaitForChild("Root", 3) 
		end;
		getHealth = function(player)
			local character = getCharacter(player); if not character then return 0, 100 end
			local hp = character and character:WaitForChild("Health", 1); if not hp then return 0,100 end
			local maxHP = hp:FindFirstChild("MaxHealth"); if not maxHP then return 0,100 end
			return math.floor(hp.Value + 0.5), math.floor(maxHP.Value + 0.5)
		end;
		getTeam = function(player)
			for i,v in game:GetService("Teams"):GetChildren() do
				if not v.Players:FindFirstChild(player.Name) then continue end
				return v
			end
		end;
	};
}; customGames[1359573625] = customGames[1087859240]

if customGames[game.GameId] then
	local customGame = customGames[game.GameId]
	customGame.init()

	customCharacterFuncs.getCharacter = customGame.getCharacter or nil
	customCharacterFuncs.getRoot = customGame.getRoot or nil
	customCharacterFuncs.getHealth = customGame.getHealth or nil
	customCharacterFuncs.getTeam = customGame.getTeam or nil
	customCharacterFuncs.getDisplayName = customGame.getDisplayName or nil
end


--// start aimbot
local Aimbot = {}; do 
	Aimbot.__index = Aimbot

	function Aimbot.new()
		local self = {}; setmetatable(self, Aimbot)

		self.ClosestPlayer = {
			Player = nil;
			Visible = false;
			WallsInbetween = {};
		}

		return self
	end

	function Aimbot:IsOnScreen(vector2)
		if typeof(vector2) == "Instance" and vector2:IsA("Part") then vector2 = self:WorldToScreen(vector2) end
		return vector2.X > 0 and vector2.X < viewportSize.X and vector2.Y > 0 and vector2.Y < viewportSize.Y
	end

	function Aimbot:WorldToScreen(part)
		local screenPoint = worldtoscreen({part.Position})[1]
		return screenPoint, self:IsOnScreen(screenPoint)
	end

	function Aimbot:Wallcheck(enemyPlayerObj)
		if not localPlayerObj or not localPlayerObj.RootPart then return false end
		if not enemyPlayerObj or not localPlayerObj.RootPart then return false end

		local localCharacter = lPlayerObj.Character; if not localCharacter then return false end
		local enemyCharacter = enemyPlayerObj.Character; if not enemyCharacter then return false end

		local list = {localCharacter, enemyCharacter}
		local obscuringTargets = getPartsObscuringTarget(list, list)

		return obscuringTargets
	end
	
	function Aimbot:GetClosestPlayer(minDistance)
		local closestDistance, closestPlayer, closestVisible = minDistance or 9e9, nil, false

		for i,v in playerList do
			if playerList[localPlayer] ~= v.Player and v.Player and v.RootPart then
				if phantomSettings.Wallcheck then closestVisible = self:Wallcheck(v.Player) if not #closestVisible == 0 then continue end end 
				if v.DistanceFromMouse <= closestDistance and vis then
					closestPlayer = v
					closestDistance = closestDistance
				end
			end
		end
		self.ClosestPlayer = {
			Player = closestPlayer;
			Visible = not #closestVisible == 0;
			WallsInbetween = closestVisible

		}
		return closestPlayer
	end

	function Aimbot:AimTowardsPart(part, data)
		if data then
			local WindForce = Vector2.zero
			local Velocity = Vector2.zero
			while (true) do
				-- // Check distance
				local Distance = (Data.Destination - Data.Start).Magnitude
				if (Distance < 1) then
					break
				end

				-- // Vars
				local FM = math.min(Data.Fluctuation, Distance)

				-- // Random wind
				WindForce = WindForce / sqrt3
				if (Distance >= Data.DampedDistance) then
					WindForce = WindForce + self:RandomWind(FM)
				else
					Data.StepSize = Data.StepSize < 3 and (math.random() * 3 + 3) or (Data.StepSize / sqrt5)
				end

				-- // Workout velocity
				local GravityForce = Data.Gravity * (Data.Destination - Data.Start) / Distance
				Velocity = Velocity + WindForce + GravityForce

				-- // Velocity clip threshold
				if (Velocity.Magnitude > Data.StepSize) then
					local VelocityClip = Data.StepSize / 2 + math.random() * Data.StepSize / 2
					Velocity = Velocity.Unit * VelocityClip
				end

			end

			-- // Return
			return Data.Start
		end
	end
end
local aimObj = Aimbot.new()
--// end aimbot



local Player = {}; do
	Player.__index = Player

	function Player.new(player)
		local self = {}; setmetatable(self, Player)

		self.Player = player
		self.Character = self:GetCharacter()
		self.Humanoid = nil
		self.RigType = nil
		self.RootPart = nil
		self.HPP = nil
		self.Health = nil
		self.MaxHealth = nil
		self.Distance = 0
		self.DistanceFromMouse = 9e9
		self.OnScreen = false
		self.Visible = false
		self.LastCFrame = CFrame.new()
		self.PredictionCFrame = CFrame.new()
		self.Name = player.Name
		self.Team = self:GetTeam()
		self.Highlight = Instance.new("Highlight", highlightFolder)
		self.Drawings = {}
		self.SkeletonDrawings = {}
		self.Connects = {}
		self.Points = {}

		if customCharacterFuncs.characterAdded and customCharacterFuncs.characterRemoving then
			self.Connects["CharacterAdded"] = customCharacterFuncs.characterAdded:Connect(function(plr, char)
				if plr == player then
					self:SetupCharacter(char)
				end 
			end)

			self.Connects["CharacterRemoving"] = customCharacterFuncs.characterRemoving:Connect(function(plr)
				if plr == player then 
					self:Died() 
				end
			end)
		else
			self.Connects["CharacterAdded"] = player.CharacterAdded:Connect(function(char) 
				self:SetupCharacter(player.Character) 
			end)
			self.Connects["CharacterRemoving"] = player.CharacterRemoving:Connect(function() 
				self:Died()
			end)
		end
		self.Connects["TeamChanged"] = player:GetPropertyChangedSignal("Team"):Connect(function()
			self.Team = player.Team ~= nil and player.Team.Name or nil
		end)

		self:SetupCharacter(self.Character)

		playerList[self.Name] = self

		return self
	end

	function Player:Died()
		for i,v in {"Character", "RootPart", "Humanoid"} do self[v] = nil end
	end

	function Player:GetCharacter()
		return customCharacterFuncs.getCharacter and customCharacterFuncs.getCharacter(self.Player) or self.Player.Character
	end

	function Player:GetRootPart()
		return self.Character and (customCharacterFuncs.getRoot and customCharacterFuncs.getRoot(self.Character) or self.Character:WaitForChild("HumanoidRootPart", 3)) or nil
	end

	function Player:GetHealth()
		return customCharacterFuncs.getHealth and customCharacterFuncs.getHealth(self.Player) or self.Humanoid and self.Humanoid.Health, self.Humanoid.MaxHealth or 100,100
	end

	function Player:GetTeam()
		return (customCharacterFuncs.getTeam and customCharacterFuncs.getTeam(self.Player)) or (self.Player.Team ~= nil and self.Player.Team.Name) or nil

	function Player:GetHeldTool()
		if self.Character then
			local t = game.FindFirstChildOfClass(self.Character, "Tool")
			return t and t.Name or "N/A"
		end
		return "N/A"
	end

	function Player:UpdateHealth()
		local Health, MaxHealth = self:GetHealth()

		self.HPP = Health / MaxHealth
		
		self.Points.TopLeftHealth.Point.Offset = CFrame.new(-2, (self.HPP * 5.5) - 3, 0)

		self.Drawings.HealthBar.Color = colors.Green:Lerp(colors.Red, math.clamp(1 - self.HPP, 0, 1)) --// thx ic3 
	end

	function Player:UpdateTracerLine()
		self.Drawings.Line.Visible = false
		self.Drawings.Line = LineDynamic.new(Point2D.new(viewportSize.X / 2, viewportSize.Y), self.Points.RootPart); for i,v in defaultProperties.Line do self.Drawings.Line[i] = v end
		self.Drawings.Line.ZIndex = 0
	end

	function Player:SetupCharacter(Character)
		if Character then
			self.Character = Character
			self.RootPart = self:GetRootPart()

			local health, maxHealth = self:GetHealth()
			self.Health = health
			self.MaxHealth = maxHealth
			self.Humanoid = (not games.PF and not games.BB) and Character:WaitForChild("Humanoid", 5) or nil
			self.RigType = self.Humanoid and self.Humanoid.RigType or games.PF and Enum.HumanoidRigType.R6 or nil
			self.HPP = self.Health / self.MaxHealth
			self.Highlight.Adornee = self.Character

			if workspace.StreamingEnabled and self.Character and not self.RootPart then
				self.Connects["ChildAdded"] = self.Character.ChildAdded:Connect(function(part)
					if part.Name == "HumanoidRootPart" and part:WaitForChild("RootRigAttachment", 3) then
						self.RootPart = part
						self:SetupESP()
					end
				end)
			end

			if self.RootPart then
				self:SetupESP()
			end
		end
	end

	function Player:SetupESP()
		if self.Player == localplayer then return end
		--// create points
		local rootPartPoint = PointInstance.new(self.RootPart)

		local topLeftBoxPoint = PointInstance.new(self.RootPart, CFrame.new(-2, 2.5, 0))
		local bottomLeftBoxPoint = PointInstance.new(self.RootPart, CFrame.new(-2, -3, 0))
		local bottomRightBoxPoint = PointInstance.new(self.RootPart, CFrame.new(2, -3, 0))
		
		local middleHealthPoint = PointInstance.new(self.RootPart, CFrame.new(-2, 2.5, 0))
		local topLeftHealthPoint = PointOffset.new(PointInstance.new(self.RootPart, CFrame.new(-2, 2.5, 0)), -4, 0)
		local bottomRightHealthPoint = PointOffset.new(bottomLeftBoxPoint, -3, 0)

		local textPoint = PointInstance.new(self.RootPart, CFrame.new(2, 2.5, 0))
		
		if self.Humanoid then
			if self.RigType == Enum.HumanoidRigType.R15 then
				for i, part in self.Character:GetChildren() do
					local limb = part and self.Humanoid:GetLimb(part)
					if limb and limb ~= Enum.Limb.Unknown then
						local motor6D = game.FindFirstChildOfClass(part, "Motor6D")
						if motor6D and motor6D.Part0 and motor6D.Part1 and motor6D.Part0 ~= self.RootPart then
							self.Points[part.Name.."1"] = PointInstance.new(motor6D.Part0)
							self.Points[part.Name.."2"] = PointInstance.new(motor6D.Part1)

							local skeletonLine = LineDynamic.new(self.Points[part.Name.."1"], self.Points[part.Name.."2"]); for i,v in defaultProperties.Line do skeletonLine[i] = v end skeletonLine.Outlined = true
							
							self.SkeletonDrawings[part.Name] = skeletonLine
						end
					end
				end
			elseif self.RigType == Enum.HumanoidRigType.R6 then
				local limbs = {"Left Arm", "Right Arm", "Left Leg", "Right Leg"}
				for i,v in self.Character:GetChildren() do
					if v:IsA("Part") and game.FindFirstChildOfClass(v, "Attachment") and table.find(limbs, v.Name) then
						local limbName = v.Name:gsub(" ", "")
						
						local point1, point2 = PointInstance.new(v, CFrame.new(0, 0.75, 0)), PointInstance.new(v, CFrame.new(0, -0.75, 0)); point1.RotationType = CFrameRotationType.TargetRelative; point2.RotationType = CFrameRotationType.TargetRelative
						local skeletonLine = LineDynamic.new(point1, point2) skeletonLine.Thickness = 2 skeletonLine.Color = colors.White skeletonLine.Outlined = true

						self.Points[limbName.."Top"] = point1
						self.Points[limbName.."Bottom"] = point2
						self.SkeletonDrawings[limbName] = skeletonLine
					end
				end
				local headPoint, topTorsoPoint, bottomTorsoPoint = PointInstance.new(self.Character.Head), PointInstance.new(self.Character.Torso, CFrame.new(0, 0.75, 0)), PointInstance.new(self.Character.Torso, CFrame.new(0, -0.75, 0)); for i,v in {headPoint, topTorsoPoint, bottomTorsoPoint} do v.RotationType = CFrameRotationType.TargetRelative end

				for _,point in {"LeftArmTop", "RightArmTop"} do local line = LineDynamic.new(topTorsoPoint, self.Points[point]); for i,v in defaultProperties.Line do line[i] = v end; line.Outlined = true; self.SkeletonDrawings[point] = line end
				for _,point in {"LeftLegTop", "RightLegTop"} do local line = LineDynamic.new(bottomTorsoPoint, self.Points[point]); for i,v in defaultProperties.Line do line[i] = v end; line.Outlined = true; self.SkeletonDrawings[point] = line end

				local headtoTorso = LineDynamic.new(headPoint, topTorsoPoint) for i,v in defaultProperties.Line do headtoTorso[i] = v end; headtoTorso.Outlined = true; self.SkeletonDrawings["headtoTorso"] = headtoTorso
				local torsoLine = LineDynamic.new(topTorsoPoint, bottomTorsoPoint) or i,v in defaultProperties.Line do torsoLine[i] = v end; torsoLine.Outlined = true; self.SkeletonDrawings["torsoLine"] = torsoLine
			end
		elseif games.BB then
			for i, part in self.Character.Body:GetChildren() do
				local motor6D = game.FindFirstChildOfClass(part, "Motor6D")
				if motor6D and motor6D.Part0 and motor6D.Part1 and motor6D.Part0 ~= self.RootPart then
					self.Points[part.Name.."1"] = PointInstance.new(motor6D.Part0)
					self.Points[part.Name.."2"] = PointInstance.new(motor6D.Part1)

					local skeletonLine = LineDynamic.new(self.Points[part.Name.."1"], self.Points[part.Name.."2"]); for i,v in defaultProperties.Line do skeletonLine[i] = v end skeletonLine.Outlined = true
					
					self.SkeletonDrawings[part.Name] = skeletonLine
				end
			end
		end

		for i,v in defaultProperties.Highlight do self.Highlight[i] = v end
		
		--// create drawings
		local PrimaryBox = RectDynamic.new(topLeftBoxPoint, bottomRightBoxPoint); for i,v in defaultProperties.Box do PrimaryBox[i] = v end
		PrimaryBox.ZIndex = 3

		local PrimaryText = TextDynamic.new(textPoint); for i,v in defaultProperties.Text do PrimaryText[i] = v end
		PrimaryText.Text = self.Name
		PrimaryText.ZIndex = 2

		local TextShadow = TextDynamic.new(PointOffset.new(textPoint, 1, 1)); for i,v in defaultProperties.Text do TextShadow[i] = v end
		TextShadow.Text = self.Name
		TextShadow.Color = colors.Black
		TextShadow.ZIndex = 1
		
		local HealthBox = RectDynamic.new(topLeftHealthPoint, bottomRightHealthPoint); for i,v in defaultProperties.Box do HealthBox[i] = v end
		HealthBox.Filled = true
		HealthBox.Color = colors.Green
		HealthBox.Rounding = 0
		HealthBox.ZIndex = 3

		local TracerLine = LineDynamic.new(Point2D.new(viewportSize.X / 2, viewportSize.Y), rootPartPoint); for i,v in defaultProperties.Line do TracerLine[i] = v end
		TracerLine.ZIndex = 0

		--// add to table for updates
		self.Drawings.Box = PrimaryBox
		self.Drawings.Text = PrimaryText
		self.Drawings.TextShadow = TextShadow
		self.Drawings.HealthBar = HealthBox
		self.Drawings.Line = TracerLine

		self.Points.TopLeftBox = topLeftBoxPoint
		self.Points.BottomLeftBox = bottomLeftBoxPoint
		self.Points.BottomRightBox = bottomRightBoxPoint

		self.Points.MiddleHealth = middleHealthPoint 
		self.Points.TopLeftHealth = topLeftHealthPoint
		self.Points.BottomRightHealth = bottomRightHealthPoint

		self.Points.RootPart = rootPartPoint

		self:UpdateHealth()
		if self.Humanoid then
			self.Connects["HealthChanged"] = self.Humanoid.HealthChanged:Connect(function()
				local Health, MaxHealth = self:GetHealth()
				self.Health = Health
				self.MaxHealth = MaxHealth
				self:UpdateHealth()
			end)
		elseif games.BB then
			self.Connects["HealthChanged"] = self.Character.Health:GetPropertyChangedSignal("Value"):Connect(function()
				local Health, MaxHealth = self:GetHealth()
				self.Health = Health
				self.MaxHealth = MaxHealth
				self:UpdateHealth()
			end)
		end
	end

	function Player:Update()
		if not self.Player then self:Destroy() return end
		local Box = self.Drawings.Box
		local Text, TextShadow = self.Drawings.Text, self.Drawings.TextShadow
		local HealthBar = self.Drawings.HealthBar
		local Line = self.Drawings.Line
		local SkeletonDrawings = self.SkeletonDrawings

		if not Box or not Text or not Line or not self.Character or not self.RootPart then return end

		for i,v in {Text, HealthBar, TextShadow} do v.Visible = settings.ESP.Enabled end 
		for i,v in SkeletonDrawings do v.Visible = settings.ESP.Enabled and settings.ESP.Skeleton end
		Box.Visible = settings.ESP.Enabled and settings.ESP.Boxes
		Line.Visible = settings.ESP.Enabled and settings.ESP.Tracers
		self.Highlight.Enabled = settings.ESP.Enabled and settings.ESP.Chams

		--// set vars
		local Health, MaxHealth = self:GetHealth()

		--// var updates
		if games.PF then
			self:UpdateHealth()
		end

		self.Health = Health
		self.MaxHealth = MaxHealth

		if not self.RootPart then
			self.RootPart = self:GetRootPart()
			if not self.RootPart then self:Died() return end
		end
		self.LastCFrame = self.RootPart.CFrame
		local rootVelocity = (self.LastCFrame - self.RootPart.CFrame)
		self.PredictionCFrame =  * 
		self.Distance = (self.RootPart.Position - camera.CFrame.Position).Magnitude

		local inGameName = "";
		if customCharacterFuncs.getDisplayName then 
			inGameName = " ["..customCharacterFuncs.getDisplayName(self.Player).."]"
		end

		local displayName = (self.Player.DisplayName and #self.Player.DisplayName > 0) and " ["..self.Player.DisplayName.."]" or ""


		Text = {
			GameName = true;
			DisplayName = false;
			LowerCase = true;
			Distance = true;
			Health = true;
			HeldItem = true;
		}


		--// update text
		local newText = self.Name..(settings.ESP.Text.DisplayName and displayName or "")..(settings.ESP.Text.GameName and inGameName or "")..(settings.ESP.Text.Distance and "\n["..math.floor((camera.CFrame.p - self.RootPart.Position).Magnitude).."] [" or "")..(settings.ESP.Text.Health and math.floor(self.Health).."/"..math.floor(self.MaxHealth).."]\n[" or "")..settings.ESP.Text.HeldItem and self:GetHeldTool().."]" or ""
		Text.Text = newText
		TextShadow.Text = newText

		--// update box transparency
		local newOpacity = math.clamp(1 - self.Distance / settings.ESP.TransparencyRolloff, 0.2, 1)

		self.DistanceFromMouse = (Vector2.new(mouse.X, mouse.Y + 36) - self.Points.RootPart.ScreenPos).Magnitude
		if settings.ESP.MouseDistanceRolloff <= 200 then
			newOpacity = math.clamp(1 - self.DistanceFromMouse / settings.ESP.MouseDistanceRolloff, newOpacity, 1)
		end

		for i,v in {HealthBar, Text, Box, Line} do v.Opacity = newOpacity v.OutlineOpacity = newOpacity end
		for i,v in SkeletonDrawings do v.Opacity = newOpacity v.OutlineOpacity = newOpacity end
		TextShadow.Opacity = math.clamp(Text.Opacity - 0.1, 0.2, 1)


		--// update colors
		if games.BB then
			self.Team = self:GetTeam()
		end

		if settings.ESP.TeamColor and self.Player.TeamColor ~= nil then
			local newColor = self.Player.TeamColor.Color;
			if games.BB and self.Team then
				newColor = self.Team.Color.Value
			end
			for i,v in {Text, Box, Line} do v.Color = newColor end
			for i,v in SkeletonDrawings do v.Color = newColor end
			self.Highlight.FillColor = newColor
		elseif not settings.ESP.TeamColor and Text.Color ~= colors.White then
			for i,v in {Text, Box, Line} do v.Color = colors.White end
			for i,v in SkeletonDrawings do v.Color = colors.White end
			self.Highlight.FillColor = colors.White
		end
	end

	function Player:Destroy()
		playerList[self.Name] = nil
		for i,v in self.Connects do v:Disconnect() end
		for i,v in {unpack(self.Drawings), unpack(self.SkeletonDrawings)} do v.Visible = false v:Remove() end
		self.Highlight:Destroy()
	end
end
--// end esp


local sqrt5, sqrt3 = math.sqrt(5), math.sqrt(3)
local WindMouse = {}; do
	WindMouse.__index = WindMouse

	function WindMouse.new()
		local self = {}; setmetatable(self, WindMouse)

		self.DefaultData = {
			Gravity = 9;
			Flucation = 3;
			StepSize = 15;
			DampedDistance = 12;
		}
		self.Random = Random.new(math.randomseed(tick()))


		return self
	end

	function WindMouse:RandomWind(FM)
		return (2 * self.Random:NextNumber() - 1) * FM / sqrt5
	end
end

runService:BindToRenderStep("x_upESP", 200, function()
	for i,v in playerList do
		v:Update()
	end
end)




--// start ui
local UI = {}; do
	UI.__index = UI

	function UI.new(name)
		local self = {}; setmetatable(self, UI)

		self.Name = name
		self.Window = RenderWindow.new(name)
		self.TabMenu = self.Window:TabMenu()
		self.Tabs = {"ESP", "Aimbot"} -- comment this line if you only want a single window
		self.Objects = {}
		self.Separators = {}

		self.Colors = {
			Background = {
				Color = colors.Black;
				Alpha = 1;

				ColorOptions = {
					"TitleBg";
					"TitleBgActive";
					"TitleBgCollapsed";
					"Button";
					"ChildBg";
					"FrameBg";
					"Header";
				};
			};
			Hover = {
				Color = colors.Red;
				Alpha = 0.5;

				ColorOptions = {
					"ButtonHovered";
					"SliderGrab";
					"ResizeGripHovered";
					"HeaderHovered";
					"SeparatorHovered";
					"FrameBgHovered";
				};
			};
			Active = {
				Color = colors.Red;
				Alpha = 1;

				ColorOptions = {
					"CheckMark";
					"ButtonActive";
					"ResizeGripActive";
					"SliderGrabActive";
					"TextSelectedBg";
					"HeaderActive";
					"SeparatorActive";
				};
			};
		}

		self.Window.CanResize = true
		self.Window.DefaultSize = Vector2.new(465, 600)

		for _, styleOption in {"WindowRounding", "ChildRounding", "GrabRounding", "FrameRounding"} do 
			self:SetStyle(styleOption, 6) 
		end
		self:SetBackgroundColor();
		self:SetHoverColor()
		self:SetActiveColor()
		self:SetColor(RenderColorOption["WindowBG"], Color3.new(0.05, 0.05, 0.05), 1)
		self:SetStyle("WindowBorderSize", 1)
		
		self:CreateTabs()

		return self
	end

	function UI:CreateTabs()
		local tabsTable = {}; for i,v in self.Tabs do tabsTable[i] = v end; table.clear(self.Tabs); if #tabsTable == 0 then self.Tabs = nil return end
		for i,v in tabsTable do
			local tab = self.TabMenu:Add(v)
			self.Tabs[v] = tab 
		end
	end

	function UI:SetColor(colorOption, color, alpha)
		self.Window:SetColor(RenderColorOption[colorOption], color, alpha)
	end

	function UI:SetStyle(styleOption, value)
		self.Window:SetStyle(RenderStyleOption[styleOption], value)
	end

	function UI:SetBackgroundColor(colorTable, color, alpha)
		colorTable = colorTable or self.Colors.Background
		for _, colorOption in self.Colors.Active.ColorOptions do 
			self:SetColor(colorOption, color or colorTable.Color, alpha or colorTable.Alpha)
		end
	end

	function UI:SetHoverColor(colorTable, color, alpha)
		colorTable = colorTable or self.Colors.Hover
		for _, colorOption in self.Colors.Active.ColorOptions do 
			self:SetColor(colorOption, color or colorTable.Color, alpha or colorTable.Alpha)
		end
	end

	function UI:SetActiveColor(colorTable, color, alpha)
		colorTable = colorTable or self.Colors.Active
		for _, colorOption in self.Colors.Active.ColorOptions do 
			self:SetColor(colorOption, color or colorTable.Color, alpha or colorTable.Alpha)
		end
	end

	function UI:CreateObject(objProperties)
		if objProperties.Name and (self.Tabs and self.Objects[objProperties.Tab][objProperties.Name] or self.Objects[objProperties.Name]) then return error'ERROR [UI-A]' end
		
		local tab = self.Tabs and self.Tabs[objProperties.Tab] or self.Window
		local object = tab[objProperties.Type](tab)

		if objProperties.Name then
			object.Label = objProperties.Name
		end
		
		if objProperties.Callback then
			object.OnUpdated:Connect(objProperties.Callback)
		end

		if objProperties.Properties and typeof(objProperties) == "table" then
			for i,v in objProperties.Properties do object[i] = v end
			if objProperties.Properties.Checked then
				objProperties.Callback(true)
			end
		end
		
		local fakeObject = setmetatable({}, {
			__index = function(self, idx)
				return object[idx] or objProperties[idx]
			end,
			__newindex = function(self, idx, key)
				object[idx] = key
				if idx == "Checked" or idx == "Value" or idx == "Text" or idx == "Color" then
					objProperties.Callback(key)
				end
			end,
		})

		local table = {Real = object; Fake = fakeObject}
		if self.Tabs then
			self.Objects[objProperties.Tab][objProperties.Name] = table
		else
			self.Objects[objProperties.Name] = table
		end
		
		return fakeObject
	end

	function UI:CreateLabel(name, tab)
		local labelName, obj = "Label"..name, nil;
		if self.Tabs then
			local tab = self.Tabs[tab]; if not tab then return error'ERROR [UI-B]: '..name end
			self.Objects[tab][labelName] = tab:Label(name)
		else
			self.Objects[labelName] = self.Window:Label(name)
		end
		
		table.insert(self.Separators, self.Window:Separator())
	end

	function UI:Destroy()
		for i,v in self.Objects do v:Remove() end
		for i,v in self.Separators do v:Remove() end
		self.Window:Remove()
		for i,v in self do v = nil end
	end
end

local uiObject = UI.new("x_up Universal")

--// ui toggles
uiObject:CreateLabel("Toggles", "ESP")
uiObject:CreateObject({
	Tab = "ESP";
	Name = "Enabled";
	Type = "CheckBox";
	Properties = { Value = settings.ESP.Enabled };
	Callback = function(value)
		settings.ESP.Enabled = value
	end;
})
local teamColorToggle = uiObject:CreateObject({
	Tab = "ESP";
	Name = "Team Color";
	Type = "CheckBox";
	Properties = { Value = settings.ESP.TeamColor };
	Callback = function(value)
		settings.ESP.TeamColor = value
	end;
})
local chamsToggle = uiObject:CreateObject({
	Tab = "ESP";
	Name = "Chams";
	Type = "CheckBox";
	Properties = { Value = settings.ESP.Chams };
	Callback = function(value)
		settings.ESP.Chams = value
	end;
})
local tracersToggle = uiObject:CreateObject({
	Tab = "ESP";
	Name = "Tracers";
	Type = "CheckBox";
	Properties = { Value = settings.ESP.Tracers };
	Callback = function(value)
		settings.ESP.Tracers = value
	end;
})
local skeletonToggle = uiObject:CreateObject({
	Tab = "ESP";
	Name = "Skeleton";
	Type = "CheckBox";
	Properties = { Value = settings.ESP.Skeleton };
	Callback = function(value)
		settings.ESP.Skeleton = value
	end;
})
local boxesToggle = uiObject:CreateObject({
	Tab = "ESP";
	Name = "Box";
	Type = "CheckBox";
	Properties = { Value = settings.ESP.Boxes };
	Callback = function(value)
		settings.ESP.Boxes = value
	end;
})

--// ui sliders
uiObject:CreateLabel("Sliders", "ESP")
local transparencyRolloffSlider = uiObject:CreateObject({ 
	Tab = "ESP";
	Name = "Transparency Rolloff";
	Type = "IntSlider";
	Properties = {
		Min = 10;
		Max = 500;
		Value = settings.ESP.TransparencyRolloff;
		Clamped = true;
	};
	Callback = function(value)
		settings.ESP.TransparencyRolloff = value
	end;
})

local mouseDistanceRolloffSlider = uiObject:CreateObject({ 
	Tab = "ESP";
	Name = "Mouse Distance Rolloff";
	Type = "IntSlider";
	Properties = {
		Min = 50;
		Max = 200;
		Value = settings.ESP.MouseDistanceRolloff;
		Clamped = true;
	};
	Callback = function(value)
		settings.ESP.MouseDistanceRolloff = value
	end;
})
uiObject.Tabs["ESP"]:Separator()

--// settings
local fileList = {}
local function setupFileList() fileList = listfiles("x_up/settings/esp/") for i,v in fileList do fileList[i] = v:split("\\")[4]:gsub(".json", "") end end
if not isfolder("x_up/settings/esp/") then makefolder("x_up/settings/esp/") end
if not isfile("x_up/settings/esp/Default.json") then writefile("x_up/settings/esp/Default.json", game:GetService("HttpService"):JSONEncode(espSettings)) end

setupFileList()

local selectedSettings, newName, textBox = 1, "", nil
uiObject:CreateLabel("Settings", "ESP")
local combo = uiObject:CreateObject({
	Tab = "ESP";
	Name = "Settings";
	Type = "Combo";
	Properties = {
		Items = fileList
	};
	Callback = function(item)
		selectedSettings = item
		textBox.Value = fileList[item]
	end
})
textBox = uiObject:CreateObject({
	Tab = "ESP";
	Name = "Name";
	Type = "TextBox";
	Properties = {
		MaxTextLength = 16;
		Value = "Default";
	};
	Callback = function(name)
		newName = name
	end
})
uiObject:CreateObject({
	Tab = "ESP";
	Name = "Save Settings";
	Type = "Button";
	Callback = function()
		local success, err = pcall(function()
			writefile("x_up/settings/esp/"..textBox.Value..".json", game:GetService("HttpService"):JSONEncode(espSettings))
		end)
		if not success then 
			syn.toast_notification({
				Type = ToastType.Warning;
				Duration = 3;
				Title = "x_up ESP";
				Content = "Something went wrong when creating/writing file\n(you cannot use special characters)";
				IconColor = true;
			})
		else
			setupFileList()
			combo.Items = fileList
		end
	end
})
uiObject:CreateObject({
	Tab = "ESP";
	Name = "Load Settings";
	Type = "Button";
	Callback = function()
		local newSettings = game:GetService("HttpService"):JSONDecode(readfile("x_up/settings/esp/"..fileList[selectedSettings]..".json"))
		enabledToggle.Value = newSettings.Enabled
		teamColorToggle.Value = newSettings.TeamColor
		chamsToggle.Value = newSettings.Chams
		boxesToggle.Value = newSettings.Boxes
		tracersToggle.Value = newSettings.Tracers
		skeletonToggle.Value = newSettings.Skeleton

		mouseDistanceRolloffSlider.Value = newSettings.MouseDistanceRolloff
		transparencyRolloffSlider.Value = newSettings.TransparencyRolloff
	end
})
uiObject:CreateObject({
	Tab = "ESP";
	Name = "Delete Settings";
	Type = "Button";
	Callback = function()
		delfile("x_up/settings/esp/"..fileList[selectedSettings]..".json")
		setupFileList()
		combo.Items = fileList
	end
})
--// end settings
uiObject.Tabs["ESP"]:Separator()
uiObject:CreateObject({
	Tab = "ESP";
	Name = "Unload ESP";
	Type = "Button";
	Callback = Destroy
})


--// keybinds
local binds = {
	[Enum.KeyCode.F3] = enabledToggle;
	[Enum.KeyCode.F4] = teamColorToggle;
	[Enum.KeyCode.F5] = chamsToggle;
	[Enum.KeyCode.F6] = teamColorToggle;
	[Enum.KeyCode.F8] = skeletonToggle;
	[Enum.KeyCode.F10] = boxesToggle;
}
table.insert(connects, game:GetService("UserInputService").InputBegan:Connect(function(inputObject, gp)
	if gp then return end
	if inputObject.KeyCode and binds[inputObject.KeyCode] ~= nil then
		binds[inputObject.KeyCode].Value = not binds[inputObject.KeyCode].Value
	end
end))
--// end keybinds

--// end ui



--// connects
table.insert(connects, players.PlayerAdded:Connect(Player.new)); for _,v in players:GetPlayers() do task.spawn(Player.new, v) end
table.insert(connects, camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	viewportSize = camera.ViewportSize
	for i,v in playerList do
		v:UpdateTracerLine()
	end
end))


--// end connects


syn.toast_notification({
	Type = ToastType.Success;
	Duration = 3;
	Title = "x_up Universal";
	Content = ("Successfully loaded x_up Universal in %s seconds"):format(tostring((tick() - startTime)):format("%.3f"));
	IconColor = true;
})

while true do if unloaded then break end task.wait() end
