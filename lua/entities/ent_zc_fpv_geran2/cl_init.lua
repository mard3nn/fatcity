include("shared.lua")

function ENT:Initialize()
	self:SetNextClientThink(CurTime())
end

function ENT:StopMotorSound()
	if not self.MotorPatch then return end
	self.MotorPatch:Stop()
	self.MotorPatch = nil
end

function ENT:Think()
	local powered = self:GetPowered()
	if powered then
		if not self.MotorPatch then
			self.MotorPatch = CreateSound(self, self.IdleSound)
			if self.MotorPatch then
				self.MotorPatch:SetSoundLevel(0)
				self.MotorPatch:PlayEx(0.12, 95)
			end
		elseif not self.MotorPatch:IsPlaying() then
			self:StopMotorSound()
		end

		if self.MotorPatch then
			local speed = math.Clamp(self:GetVelocity():Length() / (self.MaxVel or 2200), 0, 1)
			local thr = self:GetThrottleFrac()
			local bat = self:GetBattery()
			local pmin = self.RpmPitchMin or 70
			local pmax = self.RpmPitchMax or 115
			local pitch = Lerp(math.Clamp(thr * 0.7 + speed * 0.3, 0, 1), pmin, pmax)
			if bat < 0.15 then pitch = pitch * (0.85 + bat) end

			local view = render.GetViewSetup and render.GetViewSetup(true)
			local origin = view and view.origin or EyePos()
			local dist = origin:Distance(self:GetPos())
			-- inverse: рядом громко, через пару тысяч юнитов уже далеко
			local atten = math.Clamp((900 / math.max(dist, 60)) ^ 1.4, 0.012, 1)
			local vol = (0.5 + thr * 0.35) * atten
			if bat <= 0 then vol = vol * 0.35 end
			if dist > 8000 then pitch = pitch * math.Clamp(1.05 - dist / 80000, 0.82, 1) end

			self.MotorPatch:ChangePitch(pitch, 0.12)
			self.MotorPatch:ChangeVolume(vol, 0.1)
		end
		self:GroundWash()
	else
		self:StopMotorSound()
	end

	local ft = math.max(RealFrameTime(), 0.001)
	local ang = self:GetAngles()
	local old = self.LastAnimAng or ang
	local pitchRate = math.AngleDifference(ang.p, old.p) / ft
	local rollRate = math.AngleDifference(ang.r, old.r) / ft
	self.LastAnimAng = Angle(ang.p, ang.y, ang.r)

	self.SurfacePitch = Lerp(math.min(ft * 8, 1), self.SurfacePitch or 0, math.Clamp(pitchRate * 0.08, -30, 30))
	self.SurfaceRoll = Lerp(math.min(ft * 8, 1), self.SurfaceRoll or 0, math.Clamp(rollRate * 0.08, -30, 30))
	self.PropSpeed = Lerp(math.min(ft * 4, 1), self.PropSpeed or 0, powered and (900 + self:GetThrottleFrac() * 2200) or 0)
	self.PropAngle = ((self.PropAngle or 0) + self.PropSpeed * ft) % 360

	self:ManipulateBoneAngles(1, Angle(self.PropAngle, 0, 0))
	self:ManipulateBoneAngles(2, Angle(0, 0, -self.SurfacePitch))
	self:ManipulateBoneAngles(3, Angle(0, 0, self.SurfaceRoll))
	self:ManipulateBoneAngles(4, Angle(0, 0, -self.SurfaceRoll))
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
