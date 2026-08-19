AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

game.AddParticles("particles/pcfs_jack_explosions_small3.pcf")
game.AddParticles("particles/pcfs_jack_explosions_incendiary2.pcf")
PrecacheParticleSystem("pcf_jack_airsplode_small3")

function ENT:OnDetonate()
	local pos = self:GetPos()
	local ang = self:GetAngles()
	local owner = ZCFpv.GetDroneOwner(self)
	local attacker = IsValid(owner) and owner or self
	local cfg = ZCFpv.Types.crocus
	local blastDmg = cfg and cfg.blastDamage or 300
	local blastRad = cfg and cfg.blastRadius or 180
	local heatDmg = cfg and cfg.heatDamage or 2500
	local heatForce = cfg and cfg.heatForce or 50000
	local heatHull = cfg and cfg.heatHull or 2
	local heatLen = cfg and cfg.heatLength or 150
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_NONE)
	local tr = util.TraceHull({
		start = pos,
		endpos = pos + ang:Forward() * heatLen,
		mins = Vector(-heatHull, -heatHull, -heatHull),
		maxs = Vector(heatHull, heatHull, heatHull),
		filter = self,
		mask = MASK_SHOT,
	})
	if IsValid(tr.Entity) then
		local dmg = DamageInfo()
		dmg:SetDamage(heatDmg)
		dmg:SetAttacker(attacker)
		dmg:SetInflictor(self)
		dmg:SetDamageType(bit.bor(DMG_BLAST, DMG_CLUB))
		dmg:SetDamageForce(ang:Forward() * heatForce)
		dmg:SetDamagePosition(tr.HitPos)
		tr.Entity:TakeDamageInfo(dmg)
	end
	self:FireBullets({
		Attacker = attacker,
		Damage = heatDmg * 0.25,
		Force = heatForce * 0.02,
		Dir = ang:Forward(),
		Src = pos,
		Tracer = 0,
		HullSize = heatHull,
		Distance = heatLen,
		IgnoreEntity = self,
	})
	local disorientRad = blastRad * 2.5
	for _, enta in ipairs(ents.FindInSphere(pos, disorientRad)) do
		if enta == owner or enta == attacker or enta == self then continue end
		local victim = enta
		if enta.organism and IsValid(enta.organism.owner) then
			victim = enta.organism.owner
		end
		if victim == owner or victim == attacker then continue end
		if not (hg and hg.ExplosionDisorientation and enta.organism and IsValid(enta.organism.owner) and enta.organism.owner:IsPlayer()) then
			continue
		end
		local tracePos = enta:IsPlayer() and (enta:GetPos() + enta:OBBCenter()) or enta:GetPos()
		local etr = hg.ExplosionTrace and hg.ExplosionTrace(pos, tracePos, {self}) or {Entity = enta}
		local len = pos:Distance(enta:GetPos())
		local frac = math.Clamp((disorientRad - len) / disorientRad, 0.1, 1)
		local behindwall = etr.Entity ~= enta and etr.MatType ~= MAT_GLASS
		if not behindwall then
			hg.ExplosionDisorientation(enta, 4 * frac, 5 * frac)
			if hg.RunZManipAnim then
				hg.RunZManipAnim(enta.organism.owner, "shieldexplosion")
			end
		end
	end
	util.BlastDamage(self, attacker, pos, blastRad, blastDmg)
	if hgWreckBuildings then
		hgWreckBuildings(self, pos, blastDmg / 100, blastRad / 80, false)
	end
	if hgBlastDoors then
		hgBlastDoors(self, pos, blastDmg / 100, blastRad / 80, false)
	end
	local ed = EffectData()
	ed:SetOrigin(pos)
	ed:SetScale(1.25)
	ed:SetMagnitude(1)
	ed:SetNormal(ang:Forward())
	util.Effect("Explosion", ed, true, true)
	ParticleEffect("pcf_jack_airsplode_small3", pos, -ang:Forward():Angle())
	if ZCFpv.PlayBoomSound then
		ZCFpv.PlayBoomSound(pos, "snd_jack_bigsplodeclose.wav", "mortar_strike_far_dist_03.wav")
	end
	local ground = util.QuickTrace(pos, Vector(0, 0, -64), self)
	if ground.Hit then
		util.Decal("Scorch", ground.HitPos + ground.HitNormal, ground.HitPos - ground.HitNormal)
	end
	if IsValid(owner) and owner.ZCFpvOwned == self then
		owner.ZCFpvOwned = nil
	end
	timer.Simple(0, function()
		if IsValid(self) then self:Remove() end
	end)
end
