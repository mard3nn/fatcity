AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
function ENT:OnDetonate()
	local pos = self:LocalToWorld(self:OBBCenter())
	local owner = ZCFpv.GetDroneOwner(self)
	local attacker = IsValid(owner) and owner or self
	local cfg = ZCFpv.Types and ZCFpv.Types.crocus_incendiary or {}
	local burnRadius = cfg.burnRadius or 420
	local burnTime = cfg.burnTime or 18
	local count = cfg.fireballs or 32
	local velocity = self:GetVelocity()
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_NONE)
	util.BlastDamage(self, attacker, pos, cfg.blastRadius or 220, cfg.blastDamage or 120)
	for _, ent in ipairs(ents.FindInSphere(pos, burnRadius)) do
		if ent == self or ent == attacker then continue end
		if not ent:IsPlayer() and not ent:IsNPC() and not ent:IsNextBot() then continue end
		local target = ent:WorldSpaceCenter()
		local tr = util.TraceLine({
			start = pos,
			endpos = target,
			filter = {self, attacker},
			mask = MASK_SHOT,
		})
		if tr.Hit and tr.Entity ~= ent then continue end
		local frac = 1 - pos:Distance(target) / burnRadius
		ent:Ignite(math.max(burnTime * frac, 5), 0)
		local dmg = DamageInfo()
		dmg:SetAttacker(attacker)
		dmg:SetInflictor(self)
		dmg:SetDamage(25 + 35 * frac)
		dmg:SetDamageType(bit.bor(DMG_BURN, DMG_SLOWBURN))
		dmg:SetDamagePosition(target)
		ent:TakeDamageInfo(dmg)
	end
	for i = 1, count do
		local dir = (VectorRand() + Vector(0, 0, math.Rand(-0.25, 0.5))):GetNormalized()
		local tr = util.TraceLine({
			start = pos,
			endpos = pos + dir * math.Rand(180, burnRadius),
			filter = self,
			mask = MASK_SOLID,
		})
		local firePos = tr.Hit and tr.HitPos or pos + dir * math.Rand(40, 120)
		local normal = tr.Hit and tr.HitNormal or vector_up
		CreateVFireBall(35, 10, firePos + normal * 5, velocity * 0.1 + dir * math.Rand(180, 500), attacker)
	end
	local ed = EffectData()
	ed:SetOrigin(pos)
	ed:SetScale(0.5)
	ed:SetMagnitude(0.35)
	util.Effect("Explosion", ed, true, true)
	if ZCFpv.PlayBoomSound then
		ZCFpv.PlayBoomSound(pos, "snd_jack_firebomb.wav", "mortar_strike_far_dist_03.wav")
	end
	local ground = util.QuickTrace(pos, Vector(0, 0, -96), self)
	if ground.Hit then
		util.Decal("Scorch", ground.HitPos + ground.HitNormal, ground.HitPos - ground.HitNormal)
	end
	self:Break(true)
end
