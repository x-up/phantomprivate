local players = game:GetService("Players")
local localPlayer = players.LocalPlayer

local modules = debug.getupvalue(getrenv().shared.require, 1); if not modules then return error'ERROR [PF-A]' end
local _cache = rawget(modules, "_cache"); if not _cache then return error'ERROR [PF-B]' end
local function getModule(name)
	return rawget(rawget(_cache, name), "module")
end

local pfModules = {}; do
	for i,v in getnilinstances() do
		if v:IsA("Module") then
			local module = pcall(function() return getmodule(v.Name) end)
			if module then
				pfModules[v.Name] = module
			end
		end
	end
end

local localPlayerValues = {
	isAlive = false;
	weaponController = nil;
}

local networksend = rawget(pfModules["network"], "send")
local weaponControllerInterface = debug.getupvalue(rawget(pfModules["WeaponControllerInterface"], "spawn"), 1)

local particlenew = rawget(pfModules["particle"], "new")
local tPOnew = rawget(pfModules["ThirdPersonObject"], "new")
local newWeapon = rawget(weaponControllerInterface, "new")

local solve = filtergc("function", { IgnoreSyn = true;
	Name = "solve";
	Upvalues = { math.atan2; math.cos; math.sin; }
}, true)


local closestPlayer = playerObject --// this will be handled somewhere else in the main script


--// get weapon stats
local activeWeaponRegistry;

local loadFirearms; loadFirearms = hookfunction(newWeapon, function(...)
	local ret = loadFirearms(...)

	activeWeaponRegistry = ret

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






--// third person object
local fakeReplicationObject; do
	local fakePlayer = Instance.new("Player")
	fakeReplicationObject = rawget(pfModules["ReplicationObject"], "new")(fakePlayer)
	rawset(fakeReplicationObject, "_player", localPlayer)
end
local function createThirdPersonObject()
	local fakeThirdPersonObject;
	if activeWeaponRegistry then
		local weaponReg = rawget(fakeReplicationObject, "_activeWeaponRegistry")

		for i = 1, 4 do
			local weapon = rawget(activeWeaponRegistry, i)
			local tbl = { weaponName = rawget(weapon, "_weaponName"); weaponData = rawget(weapon, "_weaponData"); }

			local attachmentData = rawget(weapon, "_weaponAttachments"); if attachmentdata then tbl["attachmentData"] = attachmentdata end
			local camoData = rawget(weapon, "_camoList"); if camoData then tbl["camoData"] = camoData end

			rawset(weaponReg, i, tbl)
		end

		fakeThirdPersonObject = tPOnew(fakePlayer, nil, fakeReplicationObject)
		rawset(fakeReplicationObject, "_thirdPersonObject", fakeThirdPersonObject)
		rawget(fakeThirdPersonObject, "equip")(1, true)
		rawset(fakeReplicationObject, "_alive", true)
	end

	return fakeThirdPersonObject
end

local fakeThirdPersonObject = createThirdPersonObject()







--// silent aim

local dot = Vector3.zero.Dot;
local function trajectory(acceleration, position, bulletspeed)
	local cameraCfr = rawget(cameraObject, "_cframe")
	local diff = position - cameraCfr; acceleration = -acceleration

	local var1, var2, var3, var4 = solve(dot(acceleration, acceleration) / 4, 0, dot(acceleration, diff) - bulletspeed * bulletspeed, 0, dot(diff, diff))
	local value = var1 > 0 and var1 or var2 > 0 and var2 or var3 > 0 and var3 or var4 and var4 > 0

	local ret1 = acceleration * value / 2 + diff / value, value
end






--// hooks
local oldParticleNew; oldParticleNew = hookfunction(particlenew, function(args)
	if args["penetrationdepth"] and closestPlayer and closestPlayer[settings.Aimbot.HitPart] then
		args["position"] = closestPlayer[settings.Aimbot.HitPart].position
	end

	return unpack(args)
end)

local oldNetworkSend; oldNetworkSend = hookfunction(networksend, function(self, num, type, ...)
	local args = {...}

	if type == "repupdate" then
		if localPlayerValues.isAlive then
			if fakeReplicationObject then
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
                fakeThirdPersonObject:popCharacterModel():Destroy()
                fakeReplicationObject:despawn()
            end
		end
	end

	if type == "spawn" then


		if fakeThirdPersonObject then
			fakeThirdPersonObject:popCharacterModel():Destroy()
			fakeReplicationObject:despawn()
		end
		task.spawn(function()
			if not activeWeaponRegistry then repeat task.wait() until activeWeaponRegistry end
			fakeThirdPersonObject = createThirdPersonObject()
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

		if fakeThirdPersonObject then
			

			local equipWeapon = fakeThirdPersonObject[method]
			equipWeapon(fakeThirdPersonObject, weaponIndex)
		end
	end

	if command == "forcereset" then


		if fakeThirdPersonObject then
			fakeThirdPersonObject:popCharacterModel():Destroy()
			fakeReplicationObject:despawn()
		end
	end

	

	return oldNetworkSend(self, num, type, unpack(args))
end)
