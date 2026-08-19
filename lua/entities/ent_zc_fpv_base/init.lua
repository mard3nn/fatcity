AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
	local cfg
	if ZCFpv and ZCFpv.Types then
		for _, v in pairs(ZCFpv.Types) do
			if v.class == self:GetClass() then
				cfg = v
				break
			end
		end
	end
	if cfg then
		self.DroneModel = cfg.model
		self.IdleSound = cfg.sound
		self.MaxHP = cfg.maxHealth
		self.MaxVel = cfg.maxVelocity
		self.Mass = cfg.mass
		self.Thrust = cfg.thrust
		self.TurnRate = cfg.turnRate
		self.HoverForce = cfg.hoverForce
		self.Strike = cfg.strike
		self.SignalRangeMul = cfg.signalRangeMultiplier or self.SignalRangeMul
		self.CollideDetonate = cfg.collideDetonateSpeed or self.CollideDetonate
		self.CollideBreak = cfg.collideBreakSpeed or self.CollideBreak
		self.InputSmooth = cfg.inputSmooth
		self.AccelRate = cfg.accelRate
		self.Drag = cfg.drag
		self.AngDamp = cfg.angDamp
		self.BatteryTime = cfg.batteryTime
		self.RpmPitchMin = cfg.rpmPitchMin
		self.RpmPitchMax = cfg.rpmPitchMax
		self.EngineForce = cfg.engineForce or self.EngineForce
		self.StallSpeed = cfg.stallSpeed or self.StallSpeed
		self.MaxBank = cfg.maxBank or self.MaxBank
		self.SteeringPower = cfg.steeringPower or self.SteeringPower
	end
	self:SetModel(self.DroneModel or "models/sw/avia/crocus/crocus_pg7.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_NONE)
	self:SetUseType(SIMPLE_USE)
	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:Wake()
		phys:SetMass(self.Mass or 8)
		phys:EnableGravity(true)
		phys:EnableDrag(true)
		phys:SetAngleDragCoefficient(4)
		phys:SetDamping(0.4, 0.8)
	end
	self:StartMotionController()
	self:SetHealth(self.MaxHP or 5)
	self:SetMaxHealth(self.MaxHP or 5)
	self:SetLinked(false)
	self:SetHover(false)
	self:SetPowered(false)
	self:SetSignal(0)
	self:SetBattery(1)
	self:SetThrottleFrac(0)
	self:SetOwner(NULL)
	self.Dead = false
	self.NextSignal = 0
	self.HoverZ = self:GetPos().z
	self.TargetAng = self:GetAngles()
	self.Throttle = 0
	self.StickF = 0
	self.StickS = 0
	self.StickU = 0
	self.StickB = 0
	self.WasReload = false
	self.LastImpactPos = self:GetPos()
end

function ENT:SetPower(on)
	on = on and true or false
	if self:GetPowered() == on then return end
	self:SetPowered(on)
	self:SetHover(on and not self.FixedWing)
	if on then
		self:SetSignal(1)
	end
	self.HoverZ = self:GetPos().z + (on and 36 or 0)
	self.TargetAng = self:GetAngles()
	self.Throttle = 0
	self.LastImpactPos = self:GetPos()
	self.LaunchBoostUntil = on and CurTime() + 1.25 or 0
	if on then
		local phys = self:GetPhysicsObject()
		if IsValid(phys) then
			phys:EnableMotion(true)
			phys:Wake()
			if self:GetLinked() then
				phys:AddVelocity(Vector(0, 0, 8))
			end
		end
		return
	end
	self:SetThrottleFrac(0)
end

function ENT:Use(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return end
	if self.Dead or self.ZCFpvNetTrapped then return end
	local wep = ply:GetActiveWeapon()
	if self:GetClass() == "ent_zc_fpv_mavic" and ZCFpv.IsPayloadGrenade(wep) and not self:GetNWBool("ZCFpvRGD") then return end
	if CurTime() < (self.NextPowerUse or 0) then return end
	local owner = ZCFpv.GetDroneOwner(self)
	if IsValid(owner) and owner ~= ply then return end
	if not IsValid(owner) then ZCFpv.SetDroneOwner(self, ply) end
	self.NextPowerUse = CurTime() + 0.5
	self:SetPower(not self:GetPowered())
	self:EmitSound(self:GetPowered() and "buttons/button14.wav" or "buttons/button19.wav", 55, self:GetPowered() and 115 or 90)
end

function ENT:OnRemove()
	ZCFpv.DestroyViewCam(self)
	if IsValid(self.PayloadGrenade) then self.PayloadGrenade:Remove() end
	local owner = ZCFpv.GetDroneOwner(self)
	if IsValid(owner) and owner.ZCFpvOwned == self then
		owner.ZCFpvOwned = nil
	end
	if self:GetLinked() then
		local ctl = self:GetController()
		if IsValid(ctl) then
			ZCFpv.StopControl(ctl)
		end
	end
end

function ENT:CheckPlayerImpact()
	local pos = self:GetPos()
	local old = self.LastImpactPos or pos
	self.LastImpactPos = pos
	if old:DistToSqr(pos) < 1 then return false end
	local owner = ZCFpv.GetDroneOwner(self)
	local tr = util.TraceHull({
		start = old,
		endpos = pos,
		mins = Vector(-5, -5, -5),
		maxs = Vector(5, 5, 5),
		filter = {self, owner, self.ViewCam},
		mask = MASK_SHOT,
		collisiongroup = COLLISION_GROUP_NONE,
	})
	local hit = tr.Entity
	if not IsValid(hit) or not hit:IsPlayer() then return false end
	if self.Strike then
		self:Detonate()
		return true
	end
	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		local vel = phys:GetVelocity()
		local dir = vel:GetNormalized()
		self:SetPos(tr.HitPos - dir * 6)
		phys:SetVelocity(-vel * 0.15)
		if vel:Length() >= (self.CollideBreak or 400) then
			self:TakeDroneDamage(vel:Length() / 20)
		end
	end

	return true
end

function ENT:Think()
	if self.Dead then return end
	if self.ZCFpvNetTrapped then
		self:NextThink(CurTime() + 0.1)
		return true
	end
	if self:GetNWBool("ZCFpvRGD") and not IsValid(self.PayloadGrenade) then
		self:SetNWEntity("ZCFpvPayload", NULL)
		self:SetNWBool("ZCFpvRGD", false)
	end
	if not self:GetPowered() then
		self.LastImpactPos = self:GetPos()
		local ply = self:GetController()
		if IsValid(ply) and self:GetLinked() then
			ZCFpv.SyncViewCam(self)
			local down = ply:KeyDown(IN_RELOAD)
			if down and not self.WasReload then
				self:SetPower(true)
				self:EmitSound("buttons/button14.wav", 55, 115)
			end
			self.WasReload = down
		else
			self.WasReload = false
		end
		self:NextThink(CurTime())
		return true
	end
	if self:CheckPlayerImpact() then return end
	if CurTime() >= (self.NextAdrenaline or 0) then
		self.NextAdrenaline = CurTime() + 1
		local pos = self:GetPos()
		for _, ply in ipairs(player.GetAll()) do
			local org = ply.organism
			if not ply:Alive() or not org or (org.adrenaline or 0) >= 2.5 then continue end
			local dist = ply:WorldSpaceCenter():Distance(pos)
			if dist > 1400 then continue end
			local frac = 1 - dist / 1400
			if ply.AddNaturalAdrenaline then
				ply:AddNaturalAdrenaline(0.01 + frac * 0.035)
			else
				org.adrenalineAdd = (org.adrenalineAdd or 0) + 0.01 + frac * 0.035
			end
		end
	end
	if CurTime() >= (self.NextSignal or 0) then
		self.NextSignal = CurTime() + (ZCFpv.SignalCheckInterval or 0.2)
		self:UpdateSignal()
	end
	local ply = self:GetController()
	if IsValid(ply) and self:GetLinked() then
		ZCFpv.SyncViewCam(self)

		local down = ply:KeyDown(IN_RELOAD)
		if down and not self.WasReload then
			self:SetPower(false)
			self:EmitSound("buttons/button19.wav", 55, 90)
		end
		self.WasReload = down

		local attack = bit.band(ply.ZCFpvButtons or 0, IN_ATTACK) ~= 0
		if attack and not self.WasPayloadAttack and self.ReleasePayload and CurTime() >= (self.PayloadReadyAt or 0) then
			self:ReleasePayload(ply)
		end
		self.WasPayloadAttack = attack
	else
		self.WasReload = false
		self.WasPayloadAttack = false
	end

	self:NextThink(CurTime())
	return true
end

function ENT:UpdateSignal()
	local owner = ZCFpv.GetDroneOwner(self)
	if not IsValid(owner) then
		self:SetSignal(0)
		self:SetNWFloat("ZCFpvJam", 0)
		if self:GetLinked() then
			local ctl = self:GetController()
			if IsValid(ctl) then ZCFpv.StopControl(ctl) end
		end
		return
	end
	local dist = owner:GetPos():Distance(self:GetPos())
	local rangeMul = self.SignalRangeMul or 1
	local range = (ZCFpv.SignalRange or 11000) * rangeMul
	local grace = (ZCFpv.SignalGrace or 3500) * rangeMul
	local hard = range + grace
	local frac
	if dist <= range then
		local t = dist / range
		frac = math.Clamp(1 - (t ^ 1.35) * 0.85, 0.12, 1)
	elseif dist <= hard then
		local g = (dist - range) / grace
		frac = math.Clamp(0.12 * (1 - g * g), 0.01, 0.12)
	else
		frac = 0
	end
	local tr = util.TraceLine({
		start = owner:EyePos(),
		endpos = self:GetPos(),
		filter = {owner, self, self.ViewCam},
		mask = MASK_SOLID_BRUSHONLY,
	})
	if tr.Hit then
		frac = frac * 0.82
	end

	local jam = ZCFpv.GetJamStrength and ZCFpv.GetJamStrength(self) or 0
	self:SetNWFloat("ZCFpvJam", jam)
	frac = frac * (1 - jam * jam * jam * 0.94)
	self.SignalSmooth = self.SignalSmooth or frac
	self.SignalSmooth = Lerp(0.25, self.SignalSmooth, frac)
	self:SetSignal(self.SignalSmooth)
	if self:GetLinked() and dist > hard then
		ZCFpv.StopControl(owner)
		if self.Strike then self:SetHover(false) end
	end
	if jam >= 0.98 and self:GetLinked() then
		self.JamDropAt = self.JamDropAt or CurTime() + 1.25
		if CurTime() >= self.JamDropAt then
			ZCFpv.StopControl(owner)
			if self.Strike then self:SetHover(false) end
		end
	else
		self.JamDropAt = nil
	end
end

function ENT:ReadPilotInput()
	local ply = self:GetController()
	if not IsValid(ply) or not self:GetLinked() then
		return false, Angle(0, 0, 0), 0, 0, 0, false
	end
	local buttons = ply.ZCFpvButtons or 0
	local eye = ply:EyeAngles()
	local fwd = (bit.band(buttons, IN_FORWARD) ~= 0 and 1 or 0) - (bit.band(buttons, IN_BACK) ~= 0 and 1 or 0)
	local side = (bit.band(buttons, IN_MOVELEFT) ~= 0 and 1 or 0) - (bit.band(buttons, IN_MOVERIGHT) ~= 0 and 1 or 0)
	local rise = bit.band(buttons, IN_JUMP) ~= 0 or (self.Strike and bit.band(buttons, IN_ATTACK) ~= 0)
	local up = (rise and 1 or 0) - (bit.band(buttons, IN_DUCK) ~= 0 and 1 or 0)
	return true, eye, fwd, side, up, bit.band(buttons, IN_SPEED) ~= 0
end

function ENT:SmoothStick(fwd, side, up, boost, dt)
	local rate = (self.InputSmooth or ZCFpv.GetFlightParam(self, "inputSmooth") or 6) * dt
	self.StickF = math.Approach(self.StickF or 0, fwd, rate)
	self.StickS = math.Approach(self.StickS or 0, side, rate)
	self.StickU = math.Approach(self.StickU or 0, up, rate)
	self.StickB = math.Approach(self.StickB or 0, boost and 1 or 0, rate * 1.2)
	return self.StickF, self.StickS, self.StickU, self.StickB
end

function ENT:GetBatteryMul()
	local bat = self:GetBattery()
	if bat <= 0 then return 0 end
	if bat < 0.15 then return 0.45 + bat * 2 end
	return 1
end

function ENT:UpdateBattery(dt)
	if self.Dead or not self:GetPowered() then return end
	local life = self.BatteryTime or ZCFpv.GetFlightParam(self, "batteryTime") or 180
	if life <= 0 then return end
	dt = math.min(math.max(dt or 0, 0), 0.1)
	local load = 0.55 + math.abs(self.StickF or 0) * 0.2 + math.abs(self.StickU or 0) * 0.15 + (self.StickB or 0) * 0.25
	local nextBat = math.max(0, self:GetBattery() - dt / life * load)
	self:SetBattery(nextBat)
	if nextBat <= 0 and self:GetHover() and not self.FixedWing then
		self:SetHover(false)
	end
end

function ENT:SoftSpeedDrag(force, vel, cap, mass, dragMul)
	local speed = vel:Length()
	if speed <= cap then return force - vel * (dragMul or 1) end
	local over = (speed / cap) - 1
	return force - vel:GetNormalized() * over * over * mass * 18 - vel * ((dragMul or 1) + over * 2)
end

function ENT:PhysicsSimulate(phys, dt)
	if self.Dead or self.ZCFpvNetTrapped or not self:GetPowered() or self:IsPlayerHolding() or self.PhysgunHeld then
		return vector_origin, vector_origin, SIM_NOTHING
	end
	phys:Wake()

	local linked, eye, fwd, side, up, boost = self:ReadPilotInput()
	fwd, side, up, boost = self:SmoothStick(linked and fwd or 0, linked and side or 0, linked and up or 0, linked and boost, dt)
	self:UpdateBattery(dt)

	local ang = self:GetAngles()
	local maxVel = self.MaxVel or 2500
	local thrust = (self.Thrust or 900) * self:GetBatteryMul()
	local turn = (self.TurnRate or 180) / (1 + self:GetNWFloat("ZCFpvJam", 0) * 7)
	local mass = phys:GetMass()
	local grav = mass * 600
	local accel = self.AccelRate or ZCFpv.GetFlightParam(self, "accelRate") or 1
	local drag = self.Drag or ZCFpv.GetFlightParam(self, "drag") or 1
	local angDamp = self.AngDamp or ZCFpv.GetFlightParam(self, "angDamp") or 0.16
	local batMul = self:GetBatteryMul()

	if linked and self:GetClass() == "ent_zc_fpv_mavic" then
		self.MavicYaw = self.MavicYaw or ang.y
		self.MavicYaw = self.MavicYaw + side * turn * dt * (1 + boost * 0.35)
		local move = Angle(0, ang.y, 0):Forward() * fwd + Angle(0, ang.y, 0):Right() * side * 0.35
		local cur = self.TargetAng or Angle(0, ang.y, 0)
		local want = Angle(fwd * 10, self.MavicYaw, -side * 7)
		local rate = turn * (1 + boost * 0.25)
		cur.p = math.ApproachAngle(cur.p, want.p, rate * dt)
		cur.y = math.ApproachAngle(cur.y, want.y, rate * dt)
		cur.r = math.ApproachAngle(cur.r, want.r, rate * dt)
		self.TargetAng = cur

		local diff = self:WorldToLocalAngles(cur)
		local angVel = phys:GetAngleVelocity()
		phys:AddAngleVelocity(Vector(
			math.Clamp(diff.r * 42, -320, 320),
			math.Clamp(diff.p * 42, -320, 320),
			math.Clamp(diff.y * 48, -400, 400)
		) * dt - angVel * angDamp)

		local hoverPower = batMul > 0 and (0.92 + up * 0.38) or 0.2
		self.Throttle = Lerp(math.min(dt * 4, 1), self.Throttle or 0, hoverPower)
		self:SetThrottleFrac(self.Throttle)

		if math.abs(up) > 0.05 then self.HoverZ = self:GetPos().z end
		local zErr = (self.HoverZ or self:GetPos().z) - self:GetPos().z
		local vel = phys:GetVelocity()
		local force = Vector(0, 0, grav * self.Throttle * (self.HoverForce or 1.04) + zErr * 28 * batMul - vel.z * 4.5 * drag)
		force = force + move * thrust * (1.8 + boost * 0.55) * accel
		if CurTime() < (self.LaunchBoostUntil or 0) then force.z = force.z + grav * 0.15 end

		local cap = maxVel * (0.85 + boost * 0.2)
		force = self:SoftSpeedDrag(force, Vector(vel.x, vel.y, 0), cap, mass, 1.8 * drag)
		force.z = force.z - vel.z * 0.4
		return vector_origin, force, SIM_GLOBAL_FORCE
	end

	if linked and not self.FixedWing then
		local startEye = self.ControlEyeAng or eye
		local startAng = self.ControlBaseAng or Angle(0, ang.y, 0)
		local pitch = math.Clamp(math.AngleDifference(eye.p, startEye.p), -120, 120)
		local yaw = startAng.y + math.AngleDifference(eye.y, startEye.y)
		local want = Angle(pitch, yaw, -side * 38)
		local cur = self.TargetAng or ang
		local rate = turn * (1 + boost * 0.28)
		cur.p = math.ApproachAngle(cur.p, want.p, rate * dt)
		cur.y = math.ApproachAngle(cur.y, want.y, rate * dt)
		cur.r = math.ApproachAngle(cur.r, want.r, rate * dt * 1.05)
		self.TargetAng = cur

		local diff = self:WorldToLocalAngles(cur)
		local angVel = phys:GetAngleVelocity()
		phys:AddAngleVelocity(Vector(
			math.Clamp(diff.r * 48, -420, 420),
			math.Clamp(diff.p * 48, -420, 420),
			math.Clamp(diff.y * 55, -500, 500)
		) * dt - angVel * angDamp)

		local tilt = math.Clamp(math.abs(ang.p) / 55, 0, 1)
		local wantThrust = (self:GetHover() and 0.95 or 0.7) + fwd * 0.5 + up * 0.38 + tilt * 0.32
		if CurTime() < (self.LaunchBoostUntil or 0) then wantThrust = wantThrust + 0.2 end
		wantThrust = math.Clamp(wantThrust, 0.12, 2) * batMul
		self.Throttle = Lerp(math.min(dt * 5 * accel, 1), self.Throttle or 0, wantThrust)
		self:SetThrottleFrac(math.Clamp(self.Throttle / 2, 0, 1))

		local force = ang:Up() * (grav * self.Throttle * (self.HoverForce or 1.05))
		force = force + ang:Right() * side * thrust * 0.24 * accel
		force = force + ang:Forward() * math.max(ang.p, 0) / 55 * thrust * 0.75 * accel
		if boost > 0.2 and tilt > 0.1 then
			force = force + ang:Forward() * thrust * 0.4 * tilt * boost
		end

		if self:GetHover() and tilt < 0.12 and math.abs(fwd) < 0.12 and math.abs(up) < 0.12 and batMul > 0 then
			local zErr = (self.HoverZ or self:GetPos().z) - self:GetPos().z
			force = force + Vector(0, 0, zErr * 42)
		elseif math.abs(up) > 0.08 or tilt > 0.15 or math.abs(fwd) > 0.08 then
			self.HoverZ = self:GetPos().z
		end

		local vel = phys:GetVelocity()
		local speedCap = maxVel * (0.5 + tilt * 0.65 + boost * 0.05)
		force = self:SoftSpeedDrag(force, vel, speedCap, mass, (1.6 + tilt) * drag)
		return vector_origin, force, SIM_GLOBAL_FORCE
	end

	if self:GetHover() and not self.FixedWing then
		local hoverMul = batMul > 0 and 1.01 or 0.15
		self.Throttle = Lerp(math.min(dt * 3, 1), self.Throttle or 0, hoverMul)
		self:SetThrottleFrac(self.Throttle)
		local zErr = (self.HoverZ or self:GetPos().z) - self:GetPos().z
		local force = Vector(0, 0, grav * self.Throttle + zErr * 28 * batMul) - phys:GetVelocity() * (8 * drag)
		local angVel = phys:GetAngleVelocity()
		if self:GetClass() == "ent_zc_fpv_mavic" then
			local target = Angle(0, self.MavicYaw or ang.y, 0)
			local diff = self:WorldToLocalAngles(target)
			phys:AddAngleVelocity(Vector(
				math.Clamp(diff.r * 40, -280, 280),
				math.Clamp(diff.p * 40, -280, 280),
				math.Clamp(diff.y * 40, -320, 320)
			) * dt - angVel * angDamp)
		else
			phys:AddAngleVelocity(-angVel * angDamp)
		end
		return vector_origin, force, SIM_GLOBAL_FORCE
	end

	self:SetThrottleFrac(0)
	return vector_origin, vector_origin, SIM_NOTHING
end

function ENT:PhysicsCollide(data)
	if self.Crashing then
		if not self.CrashHit and (data.Speed or 0) > 100 then
			self.CrashHit = true
			if not (self.ZCFpvSilentHit and self.ZCFpvSilentHit > CurTime()) then
				self:EmitSound("physics/metal/metal_box_impact_hard" .. math.random(1, 3) .. ".wav", 75, math.random(90, 110))
				local ed = EffectData()
				ed:SetOrigin(data.HitPos)
				ed:SetNormal(data.HitNormal)
				ed:SetMagnitude(1)
				ed:SetScale(1)
				util.Effect("Sparks", ed, true, true)
			end
		end
		return
	end
	if CurTime() < (self.LaunchSafeUntil or 0) then return end
	if self.Dead or not self:GetPowered() then return end
	local hit = data.HitEntity
	if IsValid(hit) and hit.ZCFpvAntiNet then
		hit:CatchDrone(self)
		return
	end
	local speed = data.Speed or 0
	if self.Strike then
		if speed >= (self.CollideDetonate or 200) or (IsValid(data.HitEntity) and not data.HitEntity:IsWorld()) then
			self:Detonate()
			return
		end
	else
		if speed >= (self.CollideBreak or 400) then
			self:TakeDroneDamage(speed / 20)
		end
	end
end

function ENT:OnTakeDamage(dmg)
	if self.Dead then return end
	local amt = dmg:GetDamage()
	-- взрывы/пули иногда отдают мало или 0 — всё равно считаем попадание
	if amt < 1 then
		local typ = dmg:GetDamageType()
		if bit.band(typ, DMG_BLAST) ~= 0 then
			amt = math.max(amt, self:GetMaxHealth())
		elseif bit.band(typ, bit.bor(DMG_BULLET, DMG_BUCKSHOT, DMG_CLUB, DMG_SLASH)) ~= 0 then
			amt = math.max(amt, 2)
		end
	end
	self:TakeDroneDamage(amt, dmg)
end

function ENT:TakeDroneDamage(amt, dmg)
	if self.Dead then return end
	local hp = self:Health() - amt
	self:SetHealth(hp)
	if hp > 0 then return end

	-- страйк: любое добивание = взрыв (вкл/выкл не важно)
	if self.Strike then
		self:Detonate()
		return
	end
	self:Crash()
end

function ENT:Crash()
	if self.Dead then return end
	self.Dead = true
	self.Crashing = true
	self:SetHealth(0)
	self:SetPowered(false)
	self:SetHover(false)
	self:SetSignal(0)
	self:StopMotionController()

	local ctl = self:GetController()
	if IsValid(ctl) then ZCFpv.StopControl(ctl) end

	local owner = ZCFpv.GetDroneOwner(self)
	if IsValid(owner) and owner.ZCFpvOwned == self then
		owner.ZCFpvOwned = nil
	end

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableMotion(true)
		phys:EnableGravity(true)
		phys:Wake()
		phys:SetVelocity(phys:GetVelocity() * 0.5 + VectorRand() * 150 + Vector(0, 0, -400))
		phys:AddAngleVelocity(VectorRand() * 320)
	end

	timer.Simple(20, function()
		if IsValid(self) then self:Remove() end
	end)
end

function ENT:Detonate()
	if self.Dead then return end
	self.Dead = true
	local ctl = self:GetController()
	if IsValid(ctl) then
		ZCFpv.StopControl(ctl)
	end
	self:OnDetonate()
end

function ENT:OnDetonate()
	self:Break(true)
end

function ENT:Break(silent)
	if self.Removing then return end
	self.Removing = true
	self.Dead = true
	local ctl = self:GetController()
	if IsValid(ctl) and self:GetLinked() then
		ZCFpv.StopControl(ctl)
	end
	local owner = ZCFpv.GetDroneOwner(self)
	if IsValid(owner) and owner.ZCFpvOwned == self then
		owner.ZCFpvOwned = nil
	end
	if not silent then
		local ed = EffectData()
		ed:SetOrigin(self:GetPos())
		ed:SetScale(self.Strike and 1.2 or 0.4)
		util.Effect(self.Strike and "Explosion" or "cball_explode", ed, true, true)
		self:EmitSound("physics/metal/metal_box_break1.wav", 75, 120)
	end
	self:Remove()
end

hook.Add("PhysgunPickup", "ZCFpv_DronePickup", function(_, ent)
	if not IsValid(ent) or not ent.ZCFpvDrone then return end
	if ent.Dead or ent.CatapultMounted or ent.ZCFpvNetTrapped then return false end
	ent:SetOwner(NULL)
	ent.PhysgunHeld = true
	ent:StopMotionController()
	local phys = ent:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableMotion(true)
		phys:Wake()
	end
	return true
end)

hook.Add("OnPhysgunPickup", "ZCFpv_DroneHeld", function(_, ent)
	if not IsValid(ent) or not ent.ZCFpvDrone then return end
	ent:SetOwner(NULL)
	ent.PhysgunHeld = true
	ent:StopMotionController()
	local phys = ent:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableMotion(true)
		phys:Wake()
	end
end)

hook.Add("PhysgunDrop", "ZCFpv_DroneDrop", function(_, ent)
	if not IsValid(ent) or not ent.ZCFpvDrone then return end
	ent.PhysgunHeld = nil
	local phys = ent:GetPhysicsObject()
	if IsValid(phys) then
		phys:Wake()
		phys:EnableMotion(true)
	end
	if not ent.Dead and not ent.CatapultMounted and not ent.ZCFpvNetTrapped then
		ent:StartMotionController()
	end
end)
