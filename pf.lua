local players = game:GetService("Players")
local localPlayer = players.LocalPlayer
local tweenService, runService = game:GetService("TweenService"), game:GetService("RunService")
local gameSettings = getgenv().settings[game.GameId]

local PhantomForces = {}; do
	PhantomForces.__index = PhantomForces

	function PhantomForces.new()
		local self = {}; setmetatable(self, PhantomForces)

		self.ModuleList = debug.getupvalue(getrenv().shared.require, 1)
		self.ModuleCache = rawget(self.ModuleList, "_cache")
		self.Hooks = {}
		self.LocalPlayerValues = {}
		self.Modules = self:GetModules()
		self.Gravity = self.Modules.PublicSettings.bulletAcceleration;
		self.Network = {
			self = self.Modules.network;
			send = self.Modules.network.send;
		}
		self.Functions = {
			cameraShake = self.Modules.MainCameraObject.shake;
			cameraSway = self.Modules.MainCameraObject.sway;
			cameraSuppress = self.Modules.MainCameraObject.suppress;
			particleNew = self.Modules.particle.new;
			tPONew = self.Modules.ThirdPersonObject.new;
			weaponNew = self.Modules.WeaponControllerInterface.new;
		}

		self.PlayerList = debug.getupvalue(self.Modules.PlayerStatusInterface.getEntry, 1)

		return self ._velspring.t
	end

	function PhantomForces:GetModule(name)
		local cachedModule = rawget(self.ModuleCache, name); if not cachedModule then return false end;
		return rawget(cachedModule, "module") or false
	end

	function PhantomForces:

	function PhantomForces:GetModules()
		local moduleList = {}
		for i,v in getnilinstances() do
			if v:IsA("ModuleScript") then
				local module = self:GetModule(v.Name)
				if module then
					moduleList[v.Name] = module
				end
			end
		end
		return moduleList
	end

	function PhantomForces:Destroy()
		for i,v in self.Hooks do restorefunction(v) end
		for i,v in self do if typeof(v) == "table" then table.clear(v) v = nil end

		self = nil
	end
end; local phantomForces = PhantomForces.new()

local Client = {}; do
	Client.__index = Client

	function Client.new()
		local self = {}; setmetatable(self, Client)

		self.WeaponData = self:GetWeaponData()
		self.ThirdPersonObject = nil
		self.EquippedWeapon = nil
		self.IsAlive = phantomForces.Modules.CharacterInterface.isAlive()
		self.Random = Random.new()
		self.SilentVector = nil
		self.OnDespawn = phantomForces.Modules.CharacterEvents.onDespawning
		self.OnSpawn = phantomForces.Modules.CharacterEvents.onSpawn

		return self
	end

	function Client:GetWeaponData()
		local weaponData = debug.getupvalue(phantomForces.Modules.WeaponControllerInterface.spawn, 1) or nil
		self.WeaponData = weaponData
		return weaponData
	end

	function Client:SetWeaponData(data)
		self.WeaponData = data
	end

	function Client:Trajectory(origin, victimPos, bulletSpeed)
		local origin = origin or self.Modules.MainCameraObject._cframe.Position
		local bulletSpeed = bulletSpeed or self.Random:NextNumber(0.5, 1.5)
		return phantomForces.Modules.physics.trajectory(origin, phantomForces.Gravity, victimPos, bulletSpeed)
	end

	function Client:Spawn()
		self.IsAlive = true
		self:GetWeaponData()
	end

	function Client:Despawn()
		self.IsAlive = false
		self:SetWeaponData(nil)
		self.SilentVector = nil
		self.EquippedWeapon = nil
	end

	function Client:Destroy()
		for i,v in self do
			if typeof(v) == "table" then table.clear(v) end
			v = nil
		end
		self = nil
	end
end

local Utils = {}; do
	function Utils:CreateBeam(origin, endpos)
		local timeCreated = tick()

		local attachment1 = Instance.new("Attachment", workspace.Terrain); attachment1.Position = origin
		local attachment2 = Instance.new("Attachment", workspace.Terrain); attachment2.Position = endpos
		
		local newBeam = Instance.new("Beam")
		newBeam.Brightness = 1
		newBeam.LightEmission = 0.6
		newBeam.LightInfluence = 0
		newBeam.Texture = "rbxassetid://13478261395"
		newBeam.TextureLength = 12
		newBeam.TextureMode = "Wrap"
		newBeam.TextureSpeed = 5
		newBeam.Transparency = NumberSequence.new(0,0)
		newBeam.ZOffset = -5
		newBeam.Width0 = 4
		newBeam.Width1 = 4
		newBeam.Attachment0 = attachment1
		newBeam.Attachment1 = attachment2

		tweenService:Create(newBeam, TweenInfo.new(gameSettings.Beam.SpeedTime, Enum.EasingStyle.Circular))

		task.defer(gameSettings.Beam.TransparencyTime, function() newBeam:Destroy() att1:Destroy() att2:Destroy() end)
		task.spawn(function()
			while newBeam and newBeam.Parent do
				local t = math.clamp((tick() - time) - gameSettings.Beam.TransparencyTime, 0, 1)
				newBeam.Transparency = NumberSequence.new(t, t)
			end
		end)
	end
end

local FakeCharacter = {}; do
	FakeCharacter.__index = FakeCharacter

	function FakeCharacter.new()
		local self = {}; setmetatable(self, FakeCharacter)

		self.FakePlayer = self:CreatePlayer()
		self.ReplicationObject = self:CreateReplicationObject(self.FakePlayer)
		self.ThirdPersonObject = self:CreateThirdPersonObject(self.ReplicationObject)

		return self
	end

	function FakeCharacter:CreatePlayer()
		local fakePlayer = Instance.new("Player")
		fakePlayer.Name = tostring(math.random(1, 999999999))
		fakePlayer.Parent = game:GetService("Players")
		return fakePlayer
	end

	function FakeCharacter:CreateReplicationObject(fakePlayer)
		local repObject = phantomForces.Modules.ReplicationObject:new(fakePlayer)
		repObject._player = localPlayer
		fakePlayer:Destroy()
		return repObject
	end

	function FakeCharacter:CreateThirdPersonObject(repObject)
		local weaponRegistry = client.WeaponData; if not weaponRegistry then return nil end
		
		for i = 1, 4 do
			local weapon = weaponRegistry[i]
			local tbl = { weaponName = weapon._weaponName; weaponData = weapon._weaponData; }

			local attachmentData = weapon._weaponAttachments; if attachmentdata then tbl["attachmentData"] = attachmentdata end
			local camoData = weapon._camoList; if camoData then tbl["camoData"] = camoData end

			repObject._activeWeaponRegistry[i] = tbl
		end

		local fakeThirdPersonObject = phantomForces.Modules.ThirdPersonObject:new(fakePlayer, nil, repObject)
		repObject._thirdPersonObject = fakeThirdPersonObject
		repObject._alive = true
		fakeThirdPersonObject:equip(1, true)

		self.ThirdPersonObject = fakeThirdPersonObject
		client.FakeCharacter.ThirdPersonObject

		return fakeThirdPersonObject
	end

	function FakeCharacter:Kill()
		if self.ThirdPersonObject and self.ThirdPersonObject._character then
			self.ThirdPersonObject:popCharacterModel():Destroy()
			self.ReplicationObject:despawn()
		end
		self.ThirdPersonObject = nil
	end

	function FakeCharacter:Destroy()
		self:Kill()
		if self.FakePlayer then self.FakePlayer:Destroy() end
		for i,v in self do self[i] = nil end
		self = nil
	end
end



local closestPlayer = playerObject --// this will be handled somewhere else in the main script


--// get weapon stats
local activeWeaponRegistry;

local loadFirearms; loadFirearms = hookfunction(phantomForces.Functions.weaponNew, function(...)
	local ret = loadFirearms(...)

	Client = ret

	return ret
end)





--// penetration checks
local function raycast(origin, direction, ignorePart) --// ripped from pf
	local ignore = {workspace.Terrain, workspace.Ignore, workspace.CurrentCamera, ignorePart}
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsIntances = ignore
	raycastParams.IgnoreWater = true

	local ret;
	while true do 
		ret = workspace:Raycast(origin, direction, raycastParams)
		local instance = ret and ret.Instance; if not ret then break end
		if not ret or not ret.Instance or ret.Instance.CanCollide or not ret.Instance.Transparency == 1 then break end 
		table.insert(ignore, ret.Instance);
		raycastParams.FilterDescendantsIntances = ignore
	end
	return ret
end

local function bulletCheck(part, penetrationdepth)
	local depth = 0
	local origin, direction = camera.CFrame.Position, part.Position
	if not origin or not direction then return depth end

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Whitelist
	raycastParams.FilterDescendantsIntances = {part}
	raycastParams.IgnoreWater = true

	local hit = raycast(origin, direction)
	while hit and hit.Instance do
		local exitHit = workspace:Raycast(hit.Position + direction, -direction.Unit * 1e5, raycastParams)
		local hitDepth = math.abs((hit.Position - exitHit.Position).Magnitude)
		depth += hitDepth
		hit = raycast(hit.Position, direction, hit.Instance)
	end
	
	return depth < penetrationdepth
end




--// connects
client.OnSpawned:Connect(function() client:Spawn() end)
client.OnDespawn:Connect(function() client:Despawn() end)



--// hooks
phantomForces.Hooks["particleNew"] = hookfunction(phantomForces.Functions.particleNew, function(particle, ...)

	if gameSettings.SilentAim and not particle.thirdperson then
		local closestPlayer, closestPos, hitPartName = aimObj.ClosestPosition, aimObj:GetHitPart()
		local victimEntry = phantomForces.PlayerList[closestPlayer]

		if not victimEntry or not closestPlayer then return phantomForces.Hooks["particleNew"](particle, ...) end

		local bulletVelocity, travelTime = client:Trajectory(phantomForces.Modules.MainCameraObject._cframe.Position, closestPos, client.EquippedWeapon._weaponData["bulletspeed"])
		if settings.Aimbot.Prediction then
			local hitPart = entry._character[hitPartName]
			local velocity = entry._velspring.t * travelTime
			closestPos += velocity
			bulletVelocity, travelTime = client:Trajectory(phantomForces.Modules.MainCameraObject._cframe.Position, closestPos, client.EquippedWeapon._weaponData["bulletspeed"])
			bulletVelocity = bulletVelocity.Unit
		end

		particle.velocity = bulletVelocity * particle.Velocity.Magnitude
	end

	return phantomForces.Hooks["particleNew"](particle, ...)
end)

phantomForces.Hooks["cameraShake"] = hookfunction(phantomForces.Functions.cameraShake, function(...) --// no recoil
	local args = {...}

	if gameSettings.RecoilControl and #args == 2 and typeof(args[2]) == "Vector3" then
		args[2] = Vector3.new(args[2].X / gameSettings.RecoilControl.X, args[2].Y / gameSettings.RecoilControl.Y, args[2].Z / gameSettings.RecoilControl.Z)
	end

	return phantomForces.Hooks["shake"](unpack(args))
end)

phantomForces.Hooks["cameraSway"] = hookfunction(phantomForces.Functions.cameraSway, function(...) --// no sway
	local args = {...}

	if gameSettings.NoSway and #args == 2 and typeof(args[2]) == "number" and gameSettings.NoSway then
		args[2] = 0
	end

	return phantomForces.Hooks["sway"](unpack(args))
end)

phantomForces.Hooks["cameraSuppress"] = hookfunction(phantomForces.Functions.cameraSuppress, function(...) --// no sway
	local args = {...}

	if gameSettings.NoCameraSuppression and #args == 2 and typeof(args[2]) == "number" and gameSettings.NoSway then
		args[2] = 0
	end

	return unpack(args)
end)


phantomForces.Hooks["networkSend"] = hookfunction(phantomForces.Network.send, function(self, num, type, ...) --// networksend hook (third person)
	local args = {...}

	local fakeReplicationObject, fakeThirdPersonObject = client.FakeCharacter.ReplicationObject, client.FakeCharacter.ThirdPersonObject

	if type == "debug" or type == "logmessage" then 
		local message = args[#args]
		if gameSettings.ServerHopOnKick and message:lower():find("kick") then
			--server hop here
		end
		return 
	end

	if type == "repupdate" then


		if client.IsAlive then
			if fakeThirdPersonObject then
				local pos, angles = args[1], args[2]
				local time = pfModules["network"]:getTime()
				local _tick = tick()
				local velocity = Vector3.zero

				if fakeReplicationObject._receivedPosition and fakeReplicationObject._receivedFrameTime then
					velocity = (pos - fakeReplicationObject._receivedPosition) / (_tick - fakeReplicationObject._receivedFrameTime);
				end
				
				local broken = false
				if fakeReplicationObject._lastPacketTime and time - fakeReplicationObject._lastPacketTime > 0.5 then
					broken = true
					fakeReplicationObject._breakcount = fakeReplicationObject._breakcount + 1
				end

				fakeReplicationObject._smoothReplication:receive(time, _tick, {
					t = _tick, 
					position = pos;
					velocity = velocity;
					angles = angles;
					breakcount = fakeReplicationObject._breakcount;
				}, broken);

				fakeReplicationObject._updaterecieved = true
				fakeReplicationObject._receivedPosition = pos
				fakeReplicationObject._receivedFrameTime = _tick
				fakeReplicationObject._lastPacketTime = time
				fakeReplicationObject:step(3, true)
			end
		else
			if fakeThirdPersonObject then
				client.FakeCharacter:Kill()
			end
		end
	end

	if type == "spawn" then


		if fakeThirdPersonObject then
			client.FakeCharacter:Kill()
		end
		task.spawn(function()
			if not client.WeaponData then repeat task.wait() until client.WeaponData end
			FakeCharacter:CreateThirdPersonObject(FakeCharacter.ReplicationObject)
			client.IsAlive = true
		end)
	end

	if type == "swapweapon" then
		local groundWeapon, weaponIndex = args[1], args[2]


		if fakeThirdPersonObject then
			if weaponIndex > 2 then
				local weaponValue = groundWeapon.Knife.Value
				fakeReplicationObject._activeWeaponRegistry[weaponIndex] = {
					weaponName = weaponValue;
					weaponData = pfModules["ContentDatabase"].getWeaponData(weaponValue);
				}
			else
				local weaponValue = groundWeapon.Gun.Value
				fakeReplicationObject._activeWeaponRegistry[weaponIndex] = {
					weaponName = weaponValue;
					weaponData = pfModules["ContentDatabase"].getWeaponData(weaponValue);
				}
			end
		end
	end

	if type == "newbullets" then

		if settings.SilentAim then
			for i = 1, #args[1].bullets do 
				local bullet = args[2].bullets[i]
				bullet[1] = client.SilentVector
			end
		end

		if fakeThirdPersonObject then
			fakeThirdPersonObject:kickWeapon()
		end
	end

	if command == "stab" then


		if fakeThirdPersonObject then
			fakeThirdPersonObject:stab()
		end
	end

	if command == "sprint" then


		if fakeThirdPersonObject then
			fakeThirdPersonObject:setSprint(args[1])
		end
	end

	if command == "stance" then
		local newStance = args[1]


		if fakeThirdPersonObject then
			fakeThirdPersonObject:setAim(newStance)
		end
	end

	if command == "aim" then
		local newAim = args[1]


		if fakeThirdPersonObject then
			fakeThirdPersonObject:setAim(newAim)
		end
	end

	if command == "equip" then
		local weaponIndex = args[1]
		local method = weaponIndex == 3 and "equipMelee" or "equip"
		client.EquippedWeapon = activeWeaponRegistry[weaponIndex]

		if fakeThirdPersonObject then
			

			local equipWeapon = fakeThirdPersonObject[method]
			equipWeapon(fakeThirdPersonObject, weaponIndex)
		end
	end

	if command == "forcereset" then
		client.IsAlive = false

		if fakeThirdPersonObject then
			client.FakeCharacter:Kill()
		end
	end

	

	return phantomForces.Hooks["networkSend"](self, num, type, unpack(args))
end)
