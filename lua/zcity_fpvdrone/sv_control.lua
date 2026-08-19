ZCFpv = ZCFpv or {}

function ZCFpv.GetJamStrength(drone)
	if not IsValid(drone) then return 0 end

	local strength = 0
	for _, ent in ipairs(ents.FindInSphere(drone:GetPos(), 6000)) do
		if not ent.ZCFpvJammer or not ent:GetNWBool("ZCFpvJammerActive", true) then continue end

		local range = ent.JamDistance or 6000
		local full = ent.FullJamDistance or 2000
		local dist = drone:GetPos():Distance(ent:GetPos())
		local frac = 1 - math.Clamp((dist - full) / math.max(range - full, 1), 0, 1)
		strength = math.max(strength, frac)
	end

	return strength
end

function ZCFpv.EnsureViewCam(drone)
	if not IsValid(drone) then return nil end
	if IsValid(drone.ViewCam) then return drone.ViewCam end

	local pos, ang = drone:GetViewPosAng()
	local cam = ents.Create("prop_dynamic")
	if not IsValid(cam) then return nil end

	cam:SetModel("models/hunter/plates/plate.mdl")
	cam:SetModelScale(0)
	cam:SetPos(pos)
	cam:SetAngles(ang)
	cam:Spawn()
	cam:SetSolid(SOLID_NONE)
	cam:SetMoveType(MOVETYPE_NONE)
	cam:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
	cam:SetNoDraw(true)
	cam:DrawShadow(false)
	cam:SetNotSolid(true)
	cam.ZCFpvCam = true
	cam:AddEFlags(EFL_DONTBLOCKLOS)

	drone.ViewCam = cam
	return cam
end

function ZCFpv.DestroyViewCam(drone)
	if not IsValid(drone) then return end
	if IsValid(drone.ViewCam) then
		drone.ViewCam:Remove()
	end
	drone.ViewCam = nil
end

function ZCFpv.SyncViewCam(drone)
	if not IsValid(drone) or not IsValid(drone.ViewCam) then return end
	local pos, ang = drone:GetViewPosAng()
	if drone.FixedWing then
		ang = drone:GetAngles()
		pos = drone:LocalToWorld(Vector(drone:OBBMaxs().x + 1, 0, 2))
	else
		pos = pos - ang:Forward() * 3.5 + ang:Up() * 2
	end
	drone.ViewCam:SetPos(pos)
	drone.ViewCam:SetAngles(ang)
end

function ZCFpv.StartControl(ply, drone)
	if not IsValid(ply) or not ZCFpv.IsDrone(drone) then return false end
	if not ply:Alive() then return false end
	if ply.organism and ply.organism.otrub then return false end
	if IsValid(ply.FakeRagdoll) then return false end
	if ZCFpv.GetDroneOwner(drone) ~= ply then return false end
	if drone.Dead or drone.ZCFpvNetTrapped then return false end

	local old = ZCFpv.GetLinkedDrone(ply)
	if IsValid(old) and old ~= drone then
		ZCFpv.StopControl(ply)
	end

	if drone.Strike then
		local eye = ply:EyeAngles()
		ply:SetEyeAngles(Angle(0, eye.y, 0))
	end

	drone:SetController(ply)
	drone:SetLinked(true)
	drone.ControlEyeAng = ply:EyeAngles()
	drone.ControlBaseAng = Angle(0, drone:GetAngles().y, 0)
	drone.TargetAng = Angle(0, drone:GetAngles().y, 0)
	drone.MavicYaw = drone:GetAngles().y
	drone.PayloadReadyAt = math.max(drone.PayloadReadyAt or 0, CurTime() + 0.4)
	drone.WasPayloadAttack = true
	if drone:GetSignal() < 0.05 then
		drone:SetSignal(1)
	end

	if drone:GetPowered() then
		drone.HoverZ = math.max(drone.HoverZ or drone:GetPos().z, drone:GetPos().z + 24)
		drone.LaunchBoostUntil = CurTime() + 1.25
		local phys = drone:GetPhysicsObject()
		if IsValid(phys) then
			phys:EnableMotion(true)
			phys:Wake()
			phys:AddVelocity(Vector(0, 0, 8))
		end
	else
		drone.LaunchBoostUntil = 0
	end

	ply:SetNWEntity("ZCFpvDrone", drone)
	ply:SetNWAngle("ZCFpvBodyAng", Angle(0, ply:EyeAngles().y, 0))
	ply.ZCFpvLinked = drone
	ply.ZCFpvLockPos = ply:GetPos()
	ply:SetLocalVelocity(vector_origin)

	local cam = ZCFpv.EnsureViewCam(drone)
	ZCFpv.SyncViewCam(drone)
	if IsValid(cam) then
		ply:SetViewEntity(cam)
	else
		ply:SetViewEntity(drone)
	end

	net.Start("zc_fpv_link")
		net.WriteBool(true)
		net.WriteEntity(drone)
	net.Send(ply)

	return true
end

function ZCFpv.StopControl(ply, silent)
	if not IsValid(ply) then return end

	local drone = ply.ZCFpvLinked or ZCFpv.GetLinkedDrone(ply)
	ply.ZCFpvLinked = nil
	ply.ZCFpvLockPos = nil
	ply.ZCFpvButtons = nil
	ply:SetNWEntity("ZCFpvDrone", NULL)
	ply:SetViewEntity(NULL)

	if ZCFpv.IsDrone(drone) then
		drone:SetLinked(false)
		drone:SetController(NULL)
		drone.ControlEyeAng = nil
		drone.ControlBaseAng = nil

		local phys = drone:GetPhysicsObject()
		if drone:GetClass() == "ent_zc_fpv_mavic" and drone:GetPowered() then
			drone:SetHover(true)
			drone.HoverZ = drone:GetPos().z
			drone.MavicYaw = drone:GetAngles().y
			drone.TargetAng = Angle(0, drone.MavicYaw, 0)
		elseif drone.Strike then
			drone:SetHover(false)
			drone.MavicYaw = nil
		end

		if IsValid(phys) then phys:Wake() end
		ZCFpv.DestroyViewCam(drone)
	end

	if not silent then
		net.Start("zc_fpv_link")
			net.WriteBool(false)
			net.WriteEntity(NULL)
		net.Send(ply)
	end
end

function ZCFpv.ClearOwned(ply)
	local owned = ply.ZCFpvOwned
	ply.ZCFpvOwned = nil
	if ZCFpv.IsDrone(owned) and not owned.Dead then
		if owned:GetLinked() then
			ZCFpv.StopControl(ply)
		end
		owned:Break()
	end
end

local function shouldDrop(ply)
	if not IsValid(ply) then return true end
	if not ply:Alive() then return true end
	if ply.organism and ply.organism.otrub then return true end
	if IsValid(ply.FakeRagdoll) then return true end
	return false
end

hook.Add("PlayerDeath", "ZCFpv_Death", function(ply)
	ZCFpv.StopControl(ply)
end)

hook.Add("PlayerDisconnected", "ZCFpv_DC", function(ply)
	ZCFpv.StopControl(ply, true)
	ZCFpv.ClearOwned(ply)
end)

hook.Add("PlayerSilentDeath", "ZCFpv_SilentDeath", function(ply)
	ZCFpv.StopControl(ply)
end)

hook.Add("PlayerSpawn", "ZCFpv_Spawn", function(ply)
	ZCFpv.StopControl(ply)
end)

-- otrub / fake: only linked pilots
hook.Add("Think", "ZCFpv_Organism", function()
	for _, ply in ipairs(player.GetAll()) do
		if not ply.ZCFpvLinked then continue end
		if shouldDrop(ply) then
			ZCFpv.StopControl(ply)
		end
	end
end)

hook.Add("StartCommand", "ZCFpv_Freeze", function(ply, cmd)
	if not ply.ZCFpvLinked then return end
	ply.ZCFpvButtons = cmd:GetButtons()
	cmd:SetButtons(bit.band(cmd:GetButtons(), bit.bnot(bit.bor(IN_JUMP, IN_DUCK))))
	cmd:SetForwardMove(0)
	cmd:SetSideMove(0)
	cmd:SetUpMove(0)
end)

hook.Add("SetupMove", "ZCFpv_Freeze", function(ply, mv)
	if not ply.ZCFpvLinked then return end
	mv:SetMaxClientSpeed(0)
	mv:SetMaxSpeed(0)
	mv:SetForwardSpeed(0)
	mv:SetSideSpeed(0)
	mv:SetUpSpeed(0)
	mv:SetVelocity(vector_origin)
	if ply.ZCFpvLockPos then
		mv:SetOrigin(ply.ZCFpvLockPos)
	end
end)

hook.Add("Move", "ZCFpv_Freeze", function(ply, mv)
	if not ply.ZCFpvLinked then return end
	mv:SetVelocity(vector_origin)
	if ply.ZCFpvLockPos then
		mv:SetOrigin(ply.ZCFpvLockPos)
	end
end)

local pvsForward = {512, 1024, 2048, 4096, 8192}
local pvsForwardLong = {512, 1024, 2048, 4096, 8192, 16384, 32768}
local pvsAround = {1024, 2048}

hook.Add("SetupPlayerVisibility", "ZCFpv_PVS", function(ply, viewEnt)
	local drone = ply.ZCFpvLinked
	if not IsValid(drone) then return end

	local origin = IsValid(viewEnt) and viewEnt:GetPos() or drone:GetPos()
	if IsValid(drone.ViewCam) then origin = drone.ViewCam:GetPos() end

	local ang = drone:GetAngles()
	if drone:GetClass() == "ent_zc_fpv_mavic" and drone.ControlEyeAng then
		ang = Angle(0, ang.y + math.AngleDifference(ply:EyeAngles().y, drone.ControlEyeAng.y), 0)
	end

	local fwd, right, up = ang:Forward(), ang:Right(), ang:Up()
	AddOriginToPVS(ply:GetPos())
	AddOriginToPVS(drone:GetPos())
	AddOriginToPVS(origin)

	for _, dist in ipairs((drone.SignalRangeMul or 1) > 1 and pvsForwardLong or pvsForward) do
		AddOriginToPVS(origin + fwd * dist)
	end

	for _, dist in ipairs(pvsAround) do
		AddOriginToPVS(origin - fwd * dist)
		AddOriginToPVS(origin + right * dist)
		AddOriginToPVS(origin - right * dist)
		AddOriginToPVS(origin + up * dist)
		AddOriginToPVS(origin - up * dist)
	end
end)
