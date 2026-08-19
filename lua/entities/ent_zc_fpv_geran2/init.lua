AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

util.AddNetworkString("ZCFpvGeranBoom")

game.AddParticles("particles/pcfs_jack_explosions_small3.pcf")
game.AddParticles("particles/pcfs_jack_explosions_medium.pcf")
game.AddParticles("particles/pcfs_jack_explosions_large.pcf")
PrecacheParticleSystem("pcf_jack_airsplode_medium")
PrecacheParticleSystem("pcf_jack_airsplode_large")
PrecacheParticleSystem("pcf_jack_airsplode_small3")
PrecacheParticleSystem("pcf_jack_groundsplode_large")
PrecacheParticleSystem("pcf_jack_groundsplode_medium")

local goldenAngle = math.pi * (3 - math.sqrt(5))

local function fragHit(_, _, dmg)
	dmg:SetDamageType(DMG_BULLET)
end

function ENT:OnDetonate()
	local pos = self:LocalToWorld(self:OBBCenter())
	local owner = ZCFpv.GetDroneOwner(self)
	local attacker = IsValid(owner) and owner or self
	local cfg = ZCFpv.Types and ZCFpv.Types.geran2 or {}
	local lethalRadius = cfg.lethalRadius or 586
	local lethalDamage = cfg.lethalDamage or 15000
	local blastRadius = cfg.blastRadius or 880
	local blastDamage = cfg.blastDamage or 7500
	local fragCount = cfg.fragCount or 100

	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_NONE)

	local ed = EffectData()
	ed:SetOrigin(pos)
	ed:SetScale(18)
	ed:SetMagnitude(16)
	ed:SetRadius(900)
	ed:SetNormal(vector_up)
	util.Effect("HelicopterMegaBomb", ed, true, true)
	util.Effect("HelicopterMegaBomb", ed, true, true)
	util.Effect("Explosion", ed, true, true)
	ed:SetScale(12)
	ed:SetOrigin(pos + vector_up * 40)
	util.Effect("Explosion", ed, true, true)
	ed:SetOrigin(pos + Vector(60, 0, 20))
	util.Effect("HelicopterMegaBomb", ed, true, true)
	ed:SetOrigin(pos + Vector(-50, 40, 10))
	util.Effect("HelicopterMegaBomb", ed, true, true)
	ed:SetOrigin(pos)

	ParticleEffect("pcf_jack_airsplode_large", pos + vector_up * 24, angle_zero)
	ParticleEffect("pcf_jack_airsplode_medium", pos + vector_up * 16, angle_zero)
	ParticleEffect("pcf_jack_airsplode_medium", pos + Vector(80, 40, 20), angle_zero)
	ParticleEffect("pcf_jack_airsplode_medium", pos + Vector(-70, -50, 10), angle_zero)
	ParticleEffect("pcf_jack_airsplode_small3", pos, angle_zero)
	ParticleEffect("pcf_jack_airsplode_small3", pos + vector_up * 50, angle_zero)

	local groundFx = util.QuickTrace(pos, Vector(0, 0, -320), self)
	if groundFx.Hit then
		ParticleEffect("pcf_jack_groundsplode_large", groundFx.HitPos, groundFx.HitNormal:Angle())
		ParticleEffect("pcf_jack_groundsplode_medium", groundFx.HitPos, groundFx.HitNormal:Angle())
	end

	util.ScreenShake(pos, 80, 200, 4, 4500)

	for i = 1, 3 do
		local flash = ents.Create("env_explosion")
		if not IsValid(flash) then break end
		local off = i == 1 and vector_origin or VectorRand() * 70
		off.z = math.abs(off.z) + (i - 1) * 25
		flash:SetPos(pos + off)
		flash:SetOwner(attacker)
		flash:SetKeyValue("iMagnitude", tostring(350 + i * 80))
		flash:SetKeyValue("iRadiusOverride", "1")
		flash:SetKeyValue("spawnflags", "65")
		flash:Spawn()
		flash:Activate()
		flash:Fire("Explode", "", 0)
	end

	if ZCFpv.PlayBoomSound then
		ZCFpv.PlayBoomSound(pos, "snd_jack_bigsplodeclose.wav", "mortar_strike_far_dist_03.wav", true)
	end

	for _, ent in ipairs(ents.FindInSphere(pos, lethalRadius)) do
		if ent == self then continue end

		local target = ent:WorldSpaceCenter()
		local tr = util.TraceLine({
			start = pos,
			endpos = target,
			filter = self,
			mask = MASK_SHOT,
		})
		if tr.Hit and tr.Entity ~= ent then continue end

		local dmg = DamageInfo()
		dmg:SetAttacker(attacker)
		dmg:SetInflictor(self)
		dmg:SetDamage(lethalDamage)
		dmg:SetDamageType(bit.bor(DMG_BLAST, DMG_CLUB))
		dmg:SetDamagePosition(target)
		dmg:SetDamageForce((target - pos):GetNormalized() * lethalDamage * 40)
		ent:TakeDamageInfo(dmg)
	end

	util.BlastDamage(self, attacker, pos, blastRadius, blastDamage)

	for i = 1, fragCount do
		local z = 1 - 2 * (i - 0.5) / fragCount
		local radius = math.sqrt(1 - z * z)
		local phi = i * goldenAngle
		local dir = Vector(math.cos(phi) * radius, math.sin(phi) * radius, z * 0.5):GetNormalized()

		self:FireBullets({
			Attacker = attacker,
			Callback = fragHit,
			Damage = cfg.fragDamage or 25,
			Distance = cfg.fragDistance or 1172,
			Force = 12,
			HullSize = 1,
			IgnoreEntity = self,
			Num = 1,
			Src = pos,
			Dir = dir,
			Spread = vector_origin,
			Tracer = i % 10 == 0 and 1 or 0,
		})
	end

	if hgWreckBuildings then hgWreckBuildings(self, pos, 12, 10, false) end
	if hgBlastDoors then hgBlastDoors(self, pos, 12, 10, false) end

	local ground = util.QuickTrace(pos, Vector(0, 0, -256), self)
	if ground.Hit then
		util.Decal("Scorch", ground.HitPos + ground.HitNormal, ground.HitPos - ground.HitNormal)
	end

	self.Removing = true
	if IsValid(owner) and owner.ZCFpvOwned == self then
		owner.ZCFpvOwned = nil
	end
	timer.Simple(0, function()
		if IsValid(self) then self:Remove() end
	end)
end
