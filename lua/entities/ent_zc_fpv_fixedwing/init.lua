AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

DEFINE_BASECLASS("ent_zc_fpv_base")

function ENT:Initialize()
	BaseClass.Initialize(self)
	self:SetHover(false)
	self.EngineThrottle = 0.55
	self.CruiseYaw = self:GetAngles().y

	local phys = self:GetPhysicsObject()
	if not IsValid(phys) then return end
	phys:SetAngleDragCoefficient(1.4)
	phys:SetDamping(0.12, 0.28)
end

function ENT:SetPower(on)
	on = on and true or false
	if self:GetPowered() == on then return end

	self:SetPowered(on)
	self:SetHover(false)
	if on then
		self:SetSignal(1)
	end
	self.TargetAng = Angle(0, self:GetAngles().y, 0)
	self.CruiseYaw = self:GetAngles().y
	self.LastImpactPos = self:GetPos()
	self.LaunchBoostUntil = on and CurTime() + 2 or 0
	if on then
		self.EngineThrottle = math.max(self.EngineThrottle or 0.55, 0.8)
	else
		self:SetThrottleFrac(0)
	end

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then phys:Wake() end
end

function ENT:CheckPlayerImpact()
	local pos = self:GetPos()
	local old = self.LastImpactPos or pos
	self.LastImpactPos = pos
	if old:DistToSqr(pos) < 1 then return false end

	local tr = util.TraceHull({
		start = old,
		endpos = pos,
		mins = Vector(-24, -24, -12),
		maxs = Vector(24, 24, 12),
		filter = {self, ZCFpv.GetDroneOwner(self), self.ViewCam},
		mask = MASK_SHOT,
		collisiongroup = COLLISION_GROUP_NONE,
	})
	if not IsValid(tr.Entity) or not tr.Entity:IsPlayer() then return false end

	self:Detonate()
	return true
end

function ENT:PhysicsSimulate(phys, dt)
	if self.Dead or self.ZCFpvNetTrapped or not self:GetPowered() or self.CatapultMounted or self:IsPlayerHolding() or self.PhysgunHeld then
		return vector_origin, vector_origin, SIM_NOTHING
	end

	dt = math.min(math.max(dt or 0, 0), 0.05)
	phys:Wake()

	local linked, eye, fwd, side, _, boost = self:ReadPilotInput()
	local smooth = (self.InputSmooth or 5) * dt
	self.StickF = math.Approach(self.StickF or 0, linked and fwd or 0, smooth)
	self.StickS = math.Approach(self.StickS or 0, linked and side or 0, smooth * 1.4)
	self.StickB = math.Approach(self.StickB or 0, (linked and boost) and 1 or 0, smooth * 1.5)
	fwd, side, boost = self.StickF, self.StickS, self.StickB
	self:UpdateBattery(dt)

	local ang = self:GetAngles()
	local vel = phys:GetVelocity()
	local mass = phys:GetMass()
	local grav = mass * 600
	local maxVel = self.MaxVel or 2000
	local stall = self.StallSpeed or 520
	local turn = (self.TurnRate or 130) / (1 + self:GetNWFloat("ZCFpvJam", 0) * 7)
	local steering = self.SteeringPower or 1.35
	local batMul = self:GetBatteryMul()
	local drag = self.Drag or 1.05
	local maxBank = self.MaxBank or 62

	local wantThrottle = 0.72 + fwd * 0.26 + boost * 0.2
	if CurTime() < (self.LaunchBoostUntil or 0) then wantThrottle = math.max(wantThrottle, 0.98) end
	wantThrottle = math.Clamp(wantThrottle, 0.4, 1.08) * math.max(batMul, 0.18)
	self.EngineThrottle = Lerp(math.min(dt * 3.5, 1), self.EngineThrottle or 0.7, wantThrottle)
	self:SetThrottleFrac(self.EngineThrottle)

	local forwardSpeed = math.max(vel:Dot(ang:Forward()), 0)
	local airspeed = math.Clamp(forwardSpeed / stall, 0, 2.2)
	local auth = math.Clamp(0.45 + airspeed * 0.7, 0.45, 1.25)

	local pitchStick, rollStick = 0, 0
	if linked then
		local start = self.ControlEyeAng or eye
		pitchStick = math.Clamp(math.AngleDifference(eye.p, start.p) / 32, -1, 1)
		rollStick = math.Clamp(math.AngleDifference(eye.y, start.y) / 36 + side * 0.9, -1, 1)
		self.CruiseYaw = ang.y
	end

	local wantPitch = pitchStick * 52
	local wantBank = -rollStick * maxBank
	if not linked then
		wantPitch = 0
		wantBank = 0
	end

	local cur = self.TargetAng or Angle(0, ang.y, 0)
	local rate = turn * 2.1 * auth
	cur.p = math.ApproachAngle(cur.p, wantPitch, rate * dt)
	cur.r = math.ApproachAngle(cur.r, wantBank, rate * dt * 1.25)
	cur.y = ang.y
	self.TargetAng = cur

	local diff = self:WorldToLocalAngles(Angle(cur.p, ang.y, cur.r))
	local angVel = phys:GetAngleVelocity()

	local yawRate = -rollStick * 110 * auth
	if forwardSpeed > 90 then
		local bankRad = math.rad(math.Clamp(ang.r, -maxBank, maxBank))
		yawRate = yawRate - math.tan(bankRad) * math.Clamp(forwardSpeed * 0.11, 40, 220) * auth
	end
	if not linked then
		local yawErr = math.AngleDifference(self.CruiseYaw or ang.y, ang.y)
		yawRate = yawRate + math.Clamp(yawErr * 1.8, -50, 50)
	end

	phys:AddAngleVelocity(Vector(
		math.Clamp(diff.r * 48 * steering * auth, -380, 380),
		math.Clamp(diff.p * 44 * steering * auth, -340, 340),
		math.Clamp(yawRate, -260, 260)
	) * dt - angVel * (0.07 + 0.03 * auth))

	local liftFrac = math.Clamp(airspeed * airspeed, 0, 1.2)
	if forwardSpeed < stall * 0.8 then
		liftFrac = liftFrac * 0.7
		phys:AddAngleVelocity(Vector(0, 18 * (1 - airspeed), 0) * dt)
	end

	local engine = (self.EngineForce or 62000) * self.EngineThrottle * batMul
	local force = ang:Forward() * engine
	force = force + ang:Up() * grav * liftFrac
	force = force - ang:Right() * vel:Dot(ang:Right()) * mass * 3.2
	force = force - ang:Up() * vel:Dot(ang:Up()) * mass * 0.55
	force = force - vel * (mass * 0.028 * drag)

	local speed = vel:Length()
	if speed > maxVel then
		local over = (speed / maxVel) - 1
		force = force - vel:GetNormalized() * over * over * mass * 24
	end

	return vector_origin, force, SIM_GLOBAL_FORCE
end
