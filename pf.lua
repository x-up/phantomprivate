local req = getrenv().shared.require
local modules = debug.getupvalue(req, 1); if not modules then return error'ERROR [PF-B]' end
local _cache = rawget(modules, "_cache"); if not _cache then return error'ERROR [PF-C]' end
local function getModule(name)
	return rawget(rawget(_cache, name), "module")
end

local mainCameraObject = getModule("MainCameraObject"); if not mainCameraObject then return end
local particleObject = getModule("particle"); if not particleObject then return end
local physicsObject = getModule("physics"); if not physicsObject then return end
local raycastObject = getModule("Raycast"); if not raycastObject then return end
local weaponControllerInterface = getModule("WeaponControllerInterface"); if not weaponControllerInterface then return end

local weaponControllerObject = debug.getupvalue(rawget(weaponControllerInterface, "WeaponControllerObject"), 1)
local particlenew = rawget(particle, "new")

local solve = filtergc("function", { IgnoreSyn = true;
	Name = "solve";
	Upvalues = { math.atan2; math.cos; math.sin; }
}, true)


local closestPlayer = playerObject --// this will be handled somewhere else in the main script


--// get weapon stats
local function setWeaponStats(weaponControllerObject)
	local activeWeaponRegistry = rawget(weaponControllerObject, "_activeWeaponRegistry")
	primaryGunStats = rawget(rawget(activeWeaponRegistry, 1), "_weaponData")
	secondaryGunStats = rawget(rawget(activeWeaponRegistry, 2), "_weaponData")
end

local primaryGunStats, secondaryGunStats; do

local loadFirearms; loadFirearms = hookfunction(rawget(weaponControllerObject, "new"), function(...)
	local activeWeaponRegistry = loadFirearms(...)

	setWeaponStats(activeWeaponRegistry)

	return activeWeaponRegistry
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






--// silent aim

local dot = Vector3.zero.Dot;
local function trajectory(acceleration, position, bulletspeed)
	local cameraCfr = rawget(cameraObject, "_cframe")
	local diff = position - cameraCfr; acceleration = -acceleration

	local var1, var2, var3, var4 = solve(dot(acceleration, acceleration) / 4, 0, dot(acceleration, diff) - bulletspeed * bulletspeed, 0, dot(diff, diff))
	local value = var1 > 0 and var1 or var2 > 0 and var2 or var3 > 0 and var3 or var4 and var4 > 0

	local ret1 = acceleration * value / 2 + diff / value, value
end

local oldParticleNew; oldParticleNew = hookfunction(particlenew, function(args)
	if args["penetrationdepth"] and closestPlayer and closestPlayer[settings.Aimbot.HitPart] then
		args["position"] = closestPlayer[settings.Aimbot.HitPart].position
	end

	return unpack(args)
end)
