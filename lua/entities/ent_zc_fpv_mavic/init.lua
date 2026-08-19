AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local function payloadTransform(drone)
	local id = drone:LookupAttachment("drop")
	local att = id and id > 0 and drone:GetAttachment(id)
	if att then return att.Pos, att.Ang end
	return drone:LocalToWorld(Vector(0, 0, -5)), drone:LocalToWorldAngles(Angle(0, 0, 90))
end

local function hardenPayload(grenade)
	local oldCollide = grenade.PhysicsCollide
	grenade.PhysicsCollide = function(self, data, ...)
		if self.ZCFpvSafePayload then return end
		if CurTime() < (self.ZCFpvIgnoreUntil or 0) then return end
		local ignore = self.ZCFpvIgnoreEnt
		if IsValid(ignore) then
			if data.HitEntity == ignore then return end
			if self:GetPos():DistToSqr(ignore:GetPos()) < 6400 then return end
		end
		if oldCollide then return oldCollide(self, data, ...) end
	end

	local oldThink = grenade.Think
	grenade.Think = function(self, ...)
		if SERVER and (self.ZCFpvSafePayload or IsValid(self:GetParent()) and self:GetParent().ZCFpvDrone) then
			self:NextThink(CurTime())
			return true
		end
		if oldThink then return oldThink(self, ...) end
	end
end

function ENT:AttachPayload(ply, wep)
	if IsValid(self.PayloadGrenade) then return false end
	if not ZCFpv.IsPayloadGrenade(wep) then return false end

	local class = wep.ENT
	local grenade = ents.Create(class)
	if not IsValid(grenade) then return false end

	local pos, ang = payloadTransform(self)
	grenade.ZCFpvSafePayload = true
	grenade:SetPos(pos)
	grenade:SetAngles(ang)
	grenade:SetOwner(ply)
	grenade.owner = ply
	grenade.owner2 = ply
	grenade:Spawn()
	hardenPayload(grenade)
	grenade:SetParent(self)
	grenade:SetMoveType(MOVETYPE_NONE)
	grenade:SetSolid(SOLID_NONE)
	grenade:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
	grenade:SetNotSolid(true)

	local phys = grenade:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableMotion(false)
		phys:EnableCollisions(false)
		phys:Sleep()
	end

	self.PayloadGrenade = grenade
	self.PayloadReadyAt = CurTime() + 0.75
	self:SetNWEntity("ZCFpvPayload", grenade)
	self:SetNWBool("ZCFpvRGD", true)
	self:EmitSound("buttons/button17.wav", 60, 115)

	wep.count = math.max((wep.count or 1) - 1, 0)
	if wep.count < 1 then
		ply:SelectWeapon("weapon_hands_sh")
		wep:Remove()
	end

	net.Start("zc_fpv_payload_notice")
		net.WriteString("PAYLOAD ATTACHED")
	net.Send(ply)
	return true
end

ENT.AttachRGD = ENT.AttachPayload

function ENT:ReleasePayload(ply)
	local grenade = self.PayloadGrenade
	if not IsValid(grenade) then
		self.PayloadGrenade = nil
		self:SetNWEntity("ZCFpvPayload", NULL)
		self:SetNWBool("ZCFpvRGD", false)
		return
	end

	if CurTime() < (self.PayloadReadyAt or 0) then return end

	local vel = self:GetVelocity() - self:GetUp() * 80
	local pos, ang = payloadTransform(self)

	grenade.ZCFpvIgnoreEnt = self
	grenade.ZCFpvIgnoreUntil = CurTime() + 1
	grenade:SetParent(nil)
	grenade:SetPos(pos)
	grenade:SetAngles(ang)
	grenade:PhysicsInit(SOLID_VPHYSICS)
	grenade:SetMoveType(MOVETYPE_VPHYSICS)
	grenade:SetSolid(SOLID_VPHYSICS)
	grenade:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	grenade:SetNotSolid(false)

	local phys = grenade:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableCollisions(true)
		phys:EnableMotion(true)
		phys:Wake()
		phys:SetVelocity(vel)
	end

	if grenade.Arm then
		grenade:Arm(CurTime(), vel)
	end

	timer.Simple(0.75, function()
		if IsValid(grenade) then
			grenade.ZCFpvSafePayload = nil
		end
	end)

	timer.Simple(0.2, function()
		if IsValid(grenade) then
			grenade:SetCollisionGroup(COLLISION_GROUP_NONE)
		end
	end)

	self.PayloadGrenade = nil
	self:SetNWEntity("ZCFpvPayload", NULL)
	self:SetNWBool("ZCFpvRGD", false)
	self:EmitSound("buttons/lightswitch2.wav", 60, 120)

	if IsValid(ply) then
		net.Start("zc_fpv_payload_notice")
			net.WriteString("BOTTOM PAYLOAD RELEASED")
		net.Send(ply)
	end
end

net.Receive("zc_fpv_attach_rgd", function(_, ply)
	if not IsValid(ply) or not ply:Alive() then return end
	local drone = net.ReadEntity()
	if not IsValid(drone) or drone:GetClass() ~= "ent_zc_fpv_mavic" then return end
	if ZCFpv.GetDroneOwner(drone) ~= ply and ply.ZCFpvOwned ~= drone then return end
	if ply:GetPos():DistToSqr(drone:GetPos()) > 90000 then return end
	if IsValid(drone.PayloadGrenade) or drone:GetNWBool("ZCFpvRGD") then return end

	local wep = ply:GetActiveWeapon()
	if not ZCFpv.IsPayloadGrenade(wep) then return end
	if (wep.count or 1) < 1 then return end
	if wep.SpoonTime then return end

	local hitOk = false
	local tr = hg and hg.eyeTrace and hg.eyeTrace(ply, 320)
	if tr and tr.Entity == drone then
		hitOk = true
	else
		tr = util.TraceLine({
			start = ply:EyePos(),
			endpos = ply:EyePos() + ply:GetAimVector() * 320,
			filter = ply,
			mask = MASK_SHOT,
		})
		if tr.Entity == drone then
			hitOk = true
		else
			local dir = (drone:WorldSpaceCenter() - ply:EyePos())
			if dir:LengthSqr() > 1 and ply:GetAimVector():Dot(dir:GetNormalized()) >= 0.82 then
				hitOk = true
			end
		end
	end
	if not hitOk then return end

	drone:AttachPayload(ply, wep)
end)
