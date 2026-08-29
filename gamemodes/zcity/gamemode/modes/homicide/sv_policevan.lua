local MODE = MODE

local baseSpawnForce = MODE.SpawnForce
if not baseSpawnForce then return end

local GUARD_GREEN = Color(60, 85, 45)

local approaching = {}

local function givePoliceRifle(ply)
	local rifle = ply:Give("weapon_ar15")
	if not IsValid(rifle) then return end

	ply:GiveAmmo(rifle:GetMaxClip1() * 3, rifle:GetPrimaryAmmoType(), true)

	local inv = ply:GetNetVar("Inventory") or {}
	inv["Weapons"] = inv["Weapons"] or {}
	inv["Weapons"]["hg_sling"] = true
	ply:SetNetVar("Inventory", inv)
end

local FORCES = {
	police = {
		Car = "gtav_police_cruiser",
		Siren = true,
		Equip = function(mode, ply, index)
			local typeTbl = mode.Types[mode.Type]
			if not typeTbl or not typeTbl.PoliceEquipment then return end

			typeTbl.PoliceEquipment(ply)
			givePoliceRifle(ply)
		end
	},
	swat = {
		Car = "gtav_police_cruiser",
		Siren = true,
		Equip = function(mode, ply, index)
			mode:EquipSWAT(ply, index)
		end
	},
	nationalguard = {
		Car = "gtav_insurgent",
		CarColor = GUARD_GREEN,
		Heli = "glide_gtav_cargobob",
		HeliColor = GUARD_GREEN,
		Equip = function(mode, ply, index)
			mode:EquipNationalGuard(ply, index)
		end
	}
}

local function pointYaw(point)
	return point.ang and point.ang.y or 0
end

local function heliCruise(point)
	local tr = util.TraceLine({
		start = point.pos,
		endpos = point.pos + Vector(0, 0, 850),
		mask = MASK_SOLID_BRUSHONLY
	})

	if not tr.Hit then return 700 end

	return math.max(tr.HitPos.z - point.pos.z - 150, 0)
end

local function approachStart(point, height, back)
	local forward = Angle(0, pointYaw(point), 0):Forward()
	local from = point.pos + Vector(0, 0, height)

	local tr = util.TraceHull({
		start = from,
		endpos = from - forward * back,
		mins = Vector(-70, -70, 10),
		maxs = Vector(70, 70, 90),
		mask = MASK_SOLID_BRUSHONLY
	})

	return tr.HitPos + forward * 100
end

local function flyTo(heli, dest, yaw, cruise)
	local deadline = CurTime() + 45
	local driver = heli:GetSeatDriver(1)

	if IsValid(driver) then
		Glide.DeactivateInput(driver)
	end

	approaching[heli] = function()
		local pos = heli:GetPos()
		local ang = Angle(0, heli:GetAngles().y, 0)

		local flat = dest - pos
		flat.z = 0

		local dist = flat:Length()

		if (dist < 350 and pos.z - dest.z < 130) or CurTime() > deadline then
			heli:SetInputFloat(1, "pitch", 0)
			heli:SetInputFloat(1, "roll", 0)
			heli:SetInputFloat(1, "yaw", 0)
			heli:SetInputFloat(1, "throttle", 0)

			local ply = heli:GetSeatDriver(1)

			if IsValid(ply) then
				Glide.ActivateInput(ply, heli, 1)
			end

			return true
		end

		local vel = heli:GetVelocity()
		local fwd, right = ang:Forward(), ang:Right()
		local wantZ = dest.z + math.min(math.max(dist - 300, 0) * 0.6, cruise)

		heli:SetInputFloat(1, "pitch", math.Clamp((flat:Dot(fwd) - vel:Dot(fwd) * 2.5) / 900, -0.6, 0.6))
		heli:SetInputFloat(1, "roll", math.Clamp((flat:Dot(right) - vel:Dot(right) * 2.5) / 900, -0.5, 0.5))
		heli:SetInputFloat(1, "yaw", math.Clamp(-math.AngleDifference(yaw, ang.y) / 45, -1, 1))
		heli:SetInputFloat(1, "throttle", math.Clamp((wantZ - pos.z) * 0.012 - vel.z * 0.05, -1, 1))

		return false
	end
end

hook.Add("Think", "zc_force_approach", function()
	for veh, think in pairs(approaching) do
		if not IsValid(veh) or think() then
			approaching[veh] = nil
		end
	end
end)

local function pickPoints(group, needed)
	if needed <= 0 then return {} end

	local points = zb.GetMapPoints(group)
	if not points then return {} end

	local scored = {}

	for _, point in ipairs(points) do
		if not point.pos then continue end

		local nearest = math.huge

		for _, ply in player.Iterator() do
			if not ply:Alive() then continue end

			nearest = math.min(nearest, ply:GetPos():DistToSqr(point.pos))
		end

		scored[#scored + 1] = { point = point, dist = nearest }
	end

	table.sort(scored, function(a, b) return a.dist > b.dist end)

	local chosen = {}

	for i = 1, math.min(needed, #scored) do
		chosen[i] = scored[i].point
	end

	return chosen
end

local function pickHeliPoint()
	local points = pickPoints("POLICE_HELI", 1)

	if #points == 0 then
		points = pickPoints("UWU_GlideHeli", 1)
	end

	return points[1]
end

local function spawnVehicle(class, pos, yaw, color)
	local veh = ents.Create(class)
	if not IsValid(veh) then return end

	veh:SetPos(pos + (veh.SpawnPositionOffset or Vector(0, 0, 10)))
	veh:SetAngles(Angle(0, yaw, 0))
	veh:Spawn()
	veh:Activate()

	if not IsValid(veh) then return end

	if color then
		veh:SetColor(color)
	end

	return veh
end

local function gatherCandidates(count)
	local candidates = {}

	for _, ply in RandomPairs(player.GetAll()) do
		if #candidates >= count then break end

		if ply:Alive() then continue end
		if ply.isTraitor then continue end
		if ply:Team() == TEAM_SPECTATOR then continue end
		if (ply.afkTime2 or 0) > 60 then continue end

		candidates[#candidates + 1] = ply
	end

	return candidates
end

local function prepare(ply)
	ply.isPolice = true
	ply.isTraitor = false
	ply.isGunner = false
	ply:Spawn()
end

function MODE:SpawnForce(teamtype, count)
	local force = FORCES[teamtype]
	if not force then return baseSpawnForce(self, teamtype, count) end

	local candidates = gatherCandidates(count)
	if #candidates == 0 then return 0 end

	local spawned = 0
	local nextIndex = 1

	local function board(veh, limit)
		local boarded = 0

		while nextIndex <= #candidates and boarded < limit do
			local seat = veh:GetFreeSeat()
			if not seat then break end

			local ply = candidates[nextIndex]
			nextIndex = nextIndex + 1

			if not IsValid(ply) then continue end

			prepare(ply)
			force.Equip(self, ply, spawned + 1)

			ply:EnterVehicle(seat)

			if IsValid(ply:GetVehicle()) then
				ply:SetAllowWeaponsInVehicle(false)
				ply:SetActiveWeapon(NULL)
			else
				hg.tpPlayer(veh:GetPos(), ply, boarded + 1)
			end

			spawned = spawned + 1
			boarded = boarded + 1
		end

		return boarded
	end

	if force.Heli then
		local point = pickHeliPoint()

		if point then
			local yaw, cruise = pointYaw(point), heliCruise(point)
			local heli = spawnVehicle(force.Heli, approachStart(point, cruise, 2200), yaw, force.HeliColor)

			if IsValid(heli) then
				heli:TurnOn()
				heli:SetPower(1)

				if board(heli, math.ceil(#candidates / 2)) == 0 then
					heli:Remove()
				else
					flyTo(heli, point.pos, yaw, cruise)
				end
			end
		end
	end

	for _, point in ipairs(pickPoints("POLICE_VAN", #candidates - nextIndex + 1)) do
		if nextIndex > #candidates then break end

		local car = spawnVehicle(force.Car, point.pos, pointYaw(point), force.CarColor)
		if not IsValid(car) then break end

		car:TurnOn()

		if board(car, #candidates) == 0 then
			car:Remove()

			break
		end

		if force.Siren then
			timer.Simple(math.Rand(0, 3), function()
				if IsValid(car) then car:ChangeSirenState(2) end
			end)
		end
	end

	if nextIndex <= #candidates then
		spawned = spawned + baseSpawnForce(self, teamtype, #candidates - nextIndex + 1)
	end

	return spawned
end

local function forceSpawn(teamtype, count)
	teamtype = teamtype or "police"

	if not FORCES[teamtype] then return end

	local mode = CurrentRound()
	if not mode or not mode.SpawnForce or not mode.Type then return end

	mode:SpawnForce(teamtype, math.Clamp(tonumber(count) or 6, 1, 32))
end

COMMANDS = COMMANDS or {}
COMMANDS.policevan = {
	function(ply, args)
		forceSpawn(args[1], args[2])
	end,
	1,
	"Spawns the given force with their vehicles\nArgs - police|swat|nationalguard, count"
}

concommand.Add("zc_policevan", function(ply, cmd, args)
	if IsValid(ply) and not hg.HasAdminAccess(ply) then return end

	forceSpawn(args[1], args[2])
end)
