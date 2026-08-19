AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
game.AddParticles("particles/pcfs_jack_explosions_small3.pcf")
PrecacheParticleSystem("pcf_jack_airsplode_medium")
PrecacheParticleSystem("pcf_jack_airsplode_small3")

local goldenAngle = math.pi * (3 - math.sqrt(5))

local function fragHit(_, _, dmg)
	dmg:SetDamageType(DMG_BULLET)
end

local function saveWindows(pos)
	local windows = {}
	for _, ent in ipairs(ents.FindInSphere(pos, 900)) do
		local class = ent:GetClass()
		if class ~= "func_breakable_surf" and (class ~= "func_breakable" or ent:GetMaterialType() ~= MAT_GLASS) then
			continue
		end
		windows[#windows + 1] = {
			ent = ent, -- хуйня
			class = class,
			model = ent:GetModel(),
			pos = ent:GetPos(),
			center = ent:LocalToWorld(ent:OBBCenter()),
			ang = ent:GetAngles(),
			name = ent:GetName(),
			health = math.max(ent:GetInternalVariable("m_iHealth") or ent:Health(), 1),
			material = ent:GetInternalVariable("m_Material") or 0,
		}
	end
	return windows
end

local function cutByGlass(windows, attacker, inflictor)
	local victims = {}
	for _, data in ipairs(windows) do
		for _, ply in ipairs(player.GetAll()) do
			if not ply:Alive() then continue end
			local target = ply:WorldSpaceCenter()
			local dist = target:Distance(data.center)
			if dist > 140 then continue end
			local tr = util.TraceLine({
				start = data.center,
				endpos = target,
				filter = {data.ent, inflictor},
				mask = MASK_SHOT,
			})
			if tr.Hit and tr.Entity ~= ply then continue end
			local frac = 1 - dist / 140
			local damage = 4 + frac * 12
			if not victims[ply] or damage > victims[ply].damage then
				victims[ply] = {
					damage = damage,
					pos = data.center,
				}
			end
		end
	end
	for ply, data in pairs(victims) do
		local dir = (ply:WorldSpaceCenter() - data.pos):GetNormalized()
		local dmg = DamageInfo()
		dmg:SetAttacker(attacker)
		dmg:SetInflictor(inflictor)
		dmg:SetDamage(data.damage)
		dmg:SetDamageType(DMG_SLASH)
		dmg:SetDamagePosition(ply:WorldSpaceCenter())
		dmg:SetDamageForce(dir * data.damage * 80)
		ply:TakeDamageInfo(dmg)
	end
end

local function restoreWindows(windows)
	timer.Simple(20, function()
		for _, data in ipairs(windows) do
			local ent = data.ent
			if not IsValid(ent) then
				ent = ents.Create(data.class)
				if not IsValid(ent) then continue end
				ent:SetModel(data.model)
				ent:SetPos(data.pos)
				ent:SetAngles(data.ang)
				ent:SetKeyValue("health", data.health)
				ent:SetKeyValue("material", data.material)
				if data.name ~= "" then ent:SetKeyValue("targetname", data.name) end
			end
			ent:Spawn()
			ent:Activate()
			ent:SetSaveValue("m_bIsBroken", false)
			ent:SetHealth(data.health)
			ent:SetNoDraw(false)
			ent:SetNotSolid(false)
			ent:Fire("Enable")
		end
	end)
end

function ENT:OnDetonate()
	local pos = self:GetPos()
	local ang = self:GetAngles()
	local owner = ZCFpv.GetDroneOwner(self)
	local attacker = IsValid(owner) and owner or self
	local cfg = ZCFpv.Types and ZCFpv.Types.crocus_frag or {}
	local count = cfg.fragCount or 128
	local windows = saveWindows(pos)
	local ed = EffectData()
	ed:SetOrigin(pos)
	ed:SetScale(4)
	ed:SetMagnitude(3)
	ed:SetNormal(ang:Forward())
	util.Effect("Explosion", ed, true, true)
	util.Effect("HelicopterMegaBomb", ed, true, true)
	ParticleEffect("pcf_jack_airsplode_medium", pos + vector_up, angle_zero)
	ParticleEffect("pcf_jack_airsplode_small3", pos, -ang:Forward():Angle())
	util.BlastDamage(self, attacker, pos, cfg.blastRadius or 360, cfg.blastDamage or 450)
	for i = 1, count do
		local z = 1 - 2 * (i - 0.5) / count
		local radius = math.sqrt(1 - z * z)
		local phi = i * goldenAngle
		local dir = Vector(math.cos(phi) * radius, math.sin(phi) * radius, z)
		self:FireBullets({
			Attacker = attacker,
			Callback = fragHit,
			Damage = cfg.fragDamage or 85,
			Distance = cfg.fragDistance or 1600,
			Force = cfg.fragForce or 18,
			HullSize = 1,
			IgnoreEntity = self,
			Num = 1,
			Src = pos,
			Dir = dir,
			Spread = vector_origin,
			Tracer = i % 8 == 0 and 1 or 0,
		})
	end
	if hgWreckBuildings then
		hgWreckBuildings(self, pos, 4.5, 4.5, false)
	end
	if hgBlastDoors then
		hgBlastDoors(self, pos, 4.5, 4.5, false)
	end
	cutByGlass(windows, attacker, self)
	restoreWindows(windows)
	local stored = scripted_ents.GetStored("ent_zc_fpv_crocus")
	local base = stored and stored.t
	if base and base.OnDetonate then
		base.OnDetonate(self)
	else
		self:Break()
	end
end
