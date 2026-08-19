include("shared.lua")

function ENT:StopMotorSound()
	if not self.MotorPatch then return end
	self.MotorPatch:Stop()
	self.MotorPatch = nil
end

function ENT:GetWashEmitter()
	if self.WashEmit then return self.WashEmit end
	self.WashEmit = ParticleEmitter(self:GetPos(), false)
	return self.WashEmit
end

function ENT:GroundWash()
	if not self:GetPowered() or self.Dead then return end
	if CurTime() < (self.NextWash or 0) then return end

	local thr = math.max(self:GetThrottleFrac(), 0.35)
	local speed = self:GetVelocity():Length()
	local maxH = self.FixedWing and 280 or 160
	local power = self.FixedWing
		and math.Clamp(thr * 0.6 + speed / 2200, 0.25, 1)
		or math.Clamp(thr, 0.35, 1)

	local pos = self:GetPos()
	local tr = util.TraceLine({
		start = pos + vector_up * 8,
		endpos = pos - vector_up * maxH,
		filter = self,
		mask = MASK_SOLID,
	})
	if not tr.Hit or tr.HitSky then return end

	local h = pos.z - tr.HitPos.z
	if h > maxH * 0.95 then return end

	local near = 1 - math.Clamp(h / maxH, 0, 1)
	if near < 0.08 then return end

	local force = power * near
	self.NextWash = CurTime() + (force > 0.55 and 0.05 or 0.1)

	local hit = tr.HitPos + tr.HitNormal * 3
	local em = self:GetWashEmitter()
	if not em then return end
	em:SetPos(hit)

	local mats = {
		"particle/smokesprites_0001",
		"particle/smokesprites_0003",
		"particle/smokesprites_0005",
		"particle/particle_smokegrenade",
	}
	local vel = self:GetVelocity()
	local n = math.floor(2 + force * 4)
	for i = 1, n do
		local p = em:Add(mats[math.random(#mats)], hit + VectorRand() * 18)
		if p then
			local dir = (tr.HitNormal * math.Rand(0.15, 0.65) + VectorRand() * 1.1):GetNormalized()
			p:SetVelocity(dir * math.Rand(40, 90 + force * 110) + vel * 0.1)
			p:SetDieTime(math.Rand(0.5, 1.1))
			p:SetStartAlpha(math.floor(28 + force * 32))
			p:SetEndAlpha(0)
			p:SetStartSize(math.Rand(8, 16))
			p:SetEndSize(math.Rand(30, 55 + force * 25))
			p:SetRoll(math.Rand(0, 360))
			p:SetRollDelta(math.Rand(-2, 2))
			local w = math.random(230, 255)
			p:SetColor(w, w, w)
			p:SetGravity(Vector(0, 0, 25))
			p:SetAirResistance(90)
			p:SetCollide(false)
			p:SetLighting(false)
		end
	end
end

function ENT:Initialize()
	self:SetNextClientThink(CurTime())
end

function ENT:Think()
	if self:GetPowered() then
		if not self.MotorPatch then
			self.MotorPatch = CreateSound(self, self.IdleSound or "sw/crocus/crocus_idle.wav")
			if self.MotorPatch then
				self.MotorPatch:SetSoundLevel(self.FixedWing and 95 or 85)
				self.MotorPatch:PlayEx(1, 100)
			end
		elseif not self.MotorPatch:IsPlaying() then
			self:StopMotorSound()
		end
		if self.MotorPatch then
			local speedFrac = math.Clamp(self:GetVelocity():Length() / (self.MaxVel or 2500), 0, 1)
			local thr = self:GetThrottleFrac()
			local bat = self:GetBattery()
			local pmin = self.RpmPitchMin or (ZCFpv.GetFlightParam and ZCFpv.GetFlightParam(self, "rpmPitchMin")) or 85
			local pmax = self.RpmPitchMax or (ZCFpv.GetFlightParam and ZCFpv.GetFlightParam(self, "rpmPitchMax")) or 135
			local pitch = Lerp(math.Clamp(thr * 0.65 + speedFrac * 0.35, 0, 1), pmin, pmax)
			if bat < 0.15 then pitch = pitch * (0.85 + bat)
			elseif bat <= 0 then pitch = pmin * 0.7 end
			local vol = 0.55 + thr * 0.35 + speedFrac * 0.15
			if bat <= 0 then vol = vol * 0.35 end
			self.MotorPatch:ChangePitch(pitch, 0.12)
			self.MotorPatch:ChangeVolume(math.Clamp(vol, 0.2, 1), 0.12)
		end
		self:GroundWash()
	else
		self:StopMotorSound()
	end

	local first = self:GetClass() == "ent_zc_fpv_mavic" and 1 or 2
	local ft = RealFrameTime()
	local wantRotor = 0
	if self:GetPowered() then
		wantRotor = 1800 + self:GetThrottleFrac() * 4200
	end
	self.RotorSpeed = Lerp(math.min(ft * 4, 1), self.RotorSpeed or 0, wantRotor)
	self.RotorAng = ((self.RotorAng or 0) + ft * self.RotorSpeed) % 360
	for bone = first, first + 3 do
		self:ManipulateBoneAngles(bone, Angle(0, self.RotorAng, 0))
	end
	self:InvalidateBoneCache()
	self:SetNextClientThink(CurTime())
	return true
end

function ENT:OnRemove()
	self:StopMotorSound()
	if self.WashEmit then
		self.WashEmit:Finish()
		self.WashEmit = nil
	end
end

function ENT:Draw()
	self:DrawModel()
	if self:GetPowered() then
		self:GroundWash()
	end
end

hook.Add("PostDrawOpaqueRenderables", "ZCFpv_ForceDrone", function()
	local ply = LocalPlayer()
	local drone = IsValid(ply) and ZCFpv.GetLinkedDrone(ply)
	if not IsValid(drone) then return end
	drone:DrawModel()
end)
