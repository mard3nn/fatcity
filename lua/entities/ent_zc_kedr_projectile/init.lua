AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local fallback = "models/Combine_Helicopter/helicopter_bomb01.mdl"

function ENT:Initialize()
	local model = "models/codeecho/yolka_interceptor/kedr_drone.mdl"
	self:SetModel(util.IsValidModel(model) and model or fallback)
	self:SetModelScale(util.IsValidModel(model) and 1 or 0.15)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_NONE)
	self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)

	self.SpawnTime = CurTime()
	self.DieTime = CurTime() + 45
	self.FlyDir = self:GetForward()
	self.Speed = 520
	self.FlightSound = CreateSound(self, "codeecho/yolka_interceptor/kedr_launch_flight.ogg")
	if self.FlightSound then self.FlightSound:PlayEx(0.85, 100) end
end

function ENT:OnRemove()
	if self.FlightSound then self.FlightSound:Stop() end
end

function ENT:BecomeDebris(drone)
	if self.Debris then return end
	self.Debris = true
	self.Impacted = true

	if self.FlightSound then
		self.FlightSound:Stop()
		self.FlightSound = nil
	end

	local vel = (self.FlyDir or vector_up) * math.min(self.Speed or 400, 650) + Vector(0, 0, -450) + VectorRand() * 220
	if IsValid(drone) then
		local dphys = drone:GetPhysicsObject()
		if IsValid(dphys) then
			vel = dphys:GetVelocity() * 0.35 + Vector(0, 0, -350) + VectorRand() * 220
		end
		self:SetPos(drone:WorldSpaceCenter() + VectorRand() * 18)
	end

	self:SetParent(NULL)
	self:PhysicsDestroy()
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:PhysicsInitBox(Vector(-12, -12, -6), Vector(12, 12, 6))
	self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:Wake()
		phys:EnableMotion(true)
		phys:EnableGravity(true)
		phys:EnableDrag(true)
		phys:SetMass(5)
		phys:SetAngleDragCoefficient(1.5)
		phys:SetVelocityInstantaneous(vel)
		phys:AddAngleVelocity(VectorRand() * 1200)
	else
		self:SetMoveType(MOVETYPE_FLYGRAVITY)
		self:SetMoveCollide(MOVECOLLIDE_FLY_BOUNCE)
		self:SetLocalVelocity(vel)
		self:SetGravity(1)
	end

	timer.Simple(12, function()
		if IsValid(self) then self:Remove() end
	end)
end

function ENT:KillDrone(ent)
	if not IsValid(ent) or ent.Dead then return end
	ent.ZCFpvSilentHit = CurTime() + 3
	if ent.Strike and ent.Detonate then
		ent:Detonate()
	elseif ent.Crash then
		ent:Crash()
	elseif ent.TakeDroneDamage then
		ent:TakeDroneDamage(99999)
	else
		ent:Remove()
	end
end

function ENT:Impact(ent, hitPos)
	if self.Impacted then return end

	local pos = hitPos or self:GetPos()
	local target = self:GetTarget()
	local drone = NULL

	if IsValid(ent) and (ent.ZCFpvDrone or ent.LVSUAV) then
		drone = ent
	elseif IsValid(target) and (target.ZCFpvDrone or target.LVSUAV) then
		drone = target
	end

	if IsValid(drone) then
		local strike = drone.Strike
		self:BecomeDebris(drone)
		self:KillDrone(drone)
		if not strike and IsValid(drone) then
			local phys = drone:GetPhysicsObject()
			if IsValid(phys) then
				local kick = self.FlyDir * math.min(self.Speed, 600)
				phys:EnableMotion(true)
				phys:EnableGravity(true)
				phys:Wake()
				phys:SetVelocity(phys:GetVelocity() * 0.35 + kick + Vector(0, 0, -350) + VectorRand() * 120)
				phys:AddAngleVelocity(VectorRand() * 400)
			end
		end
		return
	end

	self.Impacted = true
	local fx = EffectData()
	fx:SetOrigin(pos)
	fx:SetNormal(-self.FlyDir)
	fx:SetScale(0.4)
	util.Effect("AR2Impact", fx, true, true)
	self:BecomeDebris(NULL)
end

function ENT:Think()
	if self.Debris then
		self:NextThink(CurTime() + 1)
		return true
	end

	if CurTime() >= self.DieTime then
		self:Remove()
		return
	end

	local target = self:GetTarget()
	local old = self:GetPos()

	if IsValid(target) and (target.ZCFpvDrone or target.LVSUAV) and not target.Dead then
		local aimPos = target:WorldSpaceCenter()
		local phys = target:GetPhysicsObject()
		if IsValid(phys) then
			aimPos = aimPos + phys:GetVelocity() * math.Clamp(old:Distance(aimPos) / math.max(self.Speed, 1), 0, 0.55)
		end

		local want = (aimPos - old):GetNormalized()
		self.FlyDir = LerpVector(math.min(FrameTime() * 8, 1), self.FlyDir, want):GetNormalized()
		self.Speed = math.Approach(self.Speed, 2800, FrameTime() * 1800)

		if old:DistToSqr(target:WorldSpaceCenter()) <= (120 * 120) then
			self:SetPos(target:WorldSpaceCenter())
			self:Impact(target, target:WorldSpaceCenter())
			return
		end
	else
		self.Speed = math.Approach(self.Speed, 1100, FrameTime() * 600)
	end

	local step = math.min(self.Speed * FrameTime(), 90)
	local nextPos = old + self.FlyDir * step

	local filter = {self, self:GetOwner()}
	if IsValid(target) and IsValid(target.ViewCam) then
		filter[#filter + 1] = target.ViewCam
	end

	local tr = util.TraceHull({
		start = old,
		endpos = nextPos,
		mins = Vector(-18, -18, -14),
		maxs = Vector(18, 18, 14),
		filter = filter,
		mask = MASK_SHOT,
	})

	if IsValid(target) and not target.Dead then
		local ab = nextPos - old
		local lenSqr = ab:LengthSqr()
		local closest
		if lenSqr < 1 then
			closest = old:Distance(target:WorldSpaceCenter())
		else
			local t = math.Clamp((target:WorldSpaceCenter() - old):Dot(ab) / lenSqr, 0, 1)
			closest = (old + ab * t):Distance(target:WorldSpaceCenter())
		end
		if closest <= 70 then
			self:SetPos(target:WorldSpaceCenter())
			self:Impact(target, target:WorldSpaceCenter())
			return
		end
	end

	if tr.Hit then
		local hit = tr.Entity
		if IsValid(target) and (not IsValid(hit) or hit:IsWorld() or not (hit.ZCFpvDrone or hit.LVSUAV)) then
			if old:DistToSqr(target:WorldSpaceCenter()) < (400 * 400) then
				hit = target
			end
		end
		self:SetPos(tr.HitPos)
		self:Impact(hit, tr.HitPos)
		return
	end

	self:SetPos(nextPos)
	self:SetAngles(self.FlyDir:Angle())
	self:NextThink(CurTime())
	return true
end
