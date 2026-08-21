//credits to fuzyaker 
//однажды я переделаю это а пусть пока что лежит бурмалдит
MH = MH or {}

util.AddNetworkString("mh_close_sound")
util.AddNetworkString("mh_black")

local IsValid, CurTime, random = IsValid, CurTime, math.random

local gore_cv = CreateConVar("mh_gore", "1", FCVAR_ARCHIVE + FCVAR_NOTIFY,
	"Let heads come off (0 keeps them on)")

local debug_cv = CreateConVar("mh_debug", "0", FCVAR_ARCHIVE,
	"Print which execution started")

local npc_cv = CreateConVar("mh_npc", "1", FCVAR_ARCHIVE + FCVAR_NOTIFY,
	"Allow executions on NPCs")

local RANGE = 200
local BEHIND = -0.4
local live = {}

local FLESH = {
	"physics/flesh/flesh_squishy_impact_hard1.wav",
	"physics/flesh/flesh_squishy_impact_hard2.wav",
	"physics/flesh/flesh_squishy_impact_hard3.wav",
	"physics/flesh/flesh_squishy_impact_hard4.wav",
	"weapons/knife/knife_hit1.wav",
	"weapons/knife/knife_hit2.wav",
	"weapons/knife/knife_hit3.wav",
	"weapons/knife/knife_hit4.wav"
}

local BLUNT = {
	"physics/body/body_medium_impact_hard1.wav",
	"physics/body/body_medium_impact_hard3.wav",
	"physics/body/body_medium_impact_hard5.wav",
	"physics/body/body_medium_impact_hard6.wav"
}

MH.Sounds = {
	Cleaver = { impacts = { FLESH[1], FLESH[2], FLESH[3], FLESH[4], "physics/flesh/flesh_bloody_break.wav" } },
	Knife = { impacts = { FLESH[1], FLESH[2], FLESH[3], FLESH[4] } },
	IceAxe = { impacts = { "weapons/iceaxe/iceaxe_impact1.wav", FLESH[2], "physics/flesh/flesh_bloody_break.wav" } },
	Bat = { impacts = { BLUNT[1], BLUNT[2], BLUNT[3], BLUNT[4], "physics/flesh/flesh_bloody_break.wav" } },
	Hammer = { impacts = { BLUNT[2], BLUNT[3], "physics/flesh/flesh_bloody_break.wav" } },
	Crowbar = { impacts = { "weapons/crowbar/crowbar_impact1.wav", "weapons/crowbar/crowbar_impact2.wav", BLUNT[1] } },
	BlackJack = { impacts = { BLUNT[1], BLUNT[2] } }
}

local CLOTH = {}
for i = 1, 8 do
	CLOTH[#CLOTH + 1] = string.format("fzk/cloth_movement_sneak_%02d.wav", i)
	CLOTH[#CLOTH + 1] = string.format("fzk/cloth_movement_walk_%02d.wav", i)
end
for i = 1, 5 do
	CLOTH[#CLOTH + 1] = string.format("fzk/me_cloth_sidestep%d.wav", i)
end

local BLADE = { Knife = true, Cleaver = true, IceAxe = true }

local function famOf(name)
	return string.match(name, "^(%a+)_") or "Bat"
end

local HEAVY = 2
local EXTRA = 0.15

local function costOf(ply, wep, k)
	local per = (IsValid(wep) and wep.StaminaPrimary) or 10
	local cost = per * HEAVY * (1 + EXTRA * (#k.blows - 1))

	local org = ply.organism
	local max = org and org.stamina and org.stamina.max
	return max and math.min(cost, max * 0.6) or cost
end

local function stamina(ply)
	local org = ply.organism
	return org and org.stamina and org.stamina[1]
end

local function drain(ply, cost)
	local org = ply.organism
	if !org or !org.stamina then return end
	org.stamina.subadd = (org.stamina.subadd or 0) + cost
end

hook.Add("Should Fake Up", "manhunt_kills_hold", function(ply)
	if (ply.MH_HoldUntil or 0) > CurTime() then return false end
end)

hook.Add("CanControlFake", "manhunt_kills_hold", function(ply)
	if (ply.MH_HoldUntil or 0) > CurTime() then return false end
end)

hook.Add("StartCommand", "manhunt_kills_lock", function(ply, cmd)
	if (ply.MH_HoldUntil or 0) > CurTime() then cmd:ClearButtons() end
end)

local function busy(ent)
	if !IsValid(ent) then return false end

	local ply = ent
	if !ent:IsPlayer() then
		ply = (isfunction(hg.RagdollOwner) and hg.RagdollOwner(ent)) or ent.ply or ent
	end
	return IsValid(ply) and ((ply.MH_HoldUntil or 0) > CurTime() or live[ply] != nil)
end

hook.Add("ZB_CanLootInventory", "manhunt_kills_noloot", function(ply, ent, canloot)
	if busy(ply) or busy(ent) then return ply, ent, false end
end)

hook.Add("PlayerUse", "manhunt_kills_nouse", function(ply, ent)
	if busy(ply) or busy(ent) then return false end
end)

hook.Add("EntityTakeDamage", "manhunt_kills_nodamage", function(target, dmginfo)
	if !IsValid(target) then return end
	local ply = target:IsPlayer() and target or (IsValid(target.ply) and target.ply) or target
	if IsValid(ply) and (ply.MH_HoldUntil or 0) > CurTime() then
		local scene = live[ply] or live[target]
		if scene and scene.finishing then return end
		return true
	end
end)

local function validSound(s)
	if !isstring(s) or s == "" then return end
	if file.Exists("sound/" .. s, "GAME") or file.Exists(s, "GAME") then return s end
	if string.find(s, "/") and !string.find(s, "hmcd") then return s end
end

local function hitSound(wep, fam)
	if IsValid(wep) then
		local s = validSound(wep.AttackHitFlesh) or validSound(wep.AttackHit)
		if s then return s end
	end
	local set = MH.Sounds[fam] and MH.Sounds[fam].impacts
	if set then return set[random(#set)] end
	return (BLADE[fam] and FLESH or BLUNT)[random(#set or BLUNT)]
end

local function close(scene, snd, pitch)
	local who = {}
	if IsValid(scene.killer) then who[#who + 1] = scene.killer end
	if IsValid(scene.victim) and scene.victim:IsPlayer() then who[#who + 1] = scene.victim end
	if #who == 0 then return end

	net.Start("mh_close_sound")
		net.WriteString(snd)
		net.WriteUInt(pitch or 100, 8)
	net.Send(who)
end

local function rustle(scene)
	local ent = IsValid(scene.vbody) and scene.vbody or scene.victim
	if !IsValid(ent) then return end

	local snd, pitch = CLOTH[random(#CLOTH)], random(95, 105)
	close(scene, snd, pitch)
	sound.Play(snd, ent:GetPos() + Vector(0, 0, 40), 95, pitch, 1)
end

local NECK_SND = "bones/bone7.mp3"
local BONES = {}
for i = 1, 8 do BONES[i] = "bones/bone" .. i .. ".mp3" end

local BLUNT_FAM = { Hammer = true }

local function orgOf(scene)
	return IsValid(scene.victim) and scene.victim.organism
end

local function spot(scene, bone)
	local ent = IsValid(scene.vbody) and scene.vbody or scene.victim
	if !IsValid(ent) then return end

	local b = ent:LookupBone("ValveBiped.Bip01_" .. (bone or "Head1"))
	return (b and ent:GetBonePosition(b)) or (ent:GetPos() + Vector(0, 0, 55)), ent
end

local function snap(scene, bone, snd)
	local at, ent = spot(scene, bone)
	if !at then return end

	local pitch = random(94, 102)
	snd = snd or BONES[random(#BONES)]
	sound.Play(snd, at, 100, pitch, 1)
	ent:EmitSound(snd, 100, pitch, 1, CHAN_ITEM)
	close(scene, snd, pitch)
end

local function gore(scene, bone, scale)
	local at, ent = spot(scene, bone)
	if !at then return end

	local ed = EffectData()
	ed:SetOrigin(at)
	ed:SetScale(scale or 4)
	ed:SetFlags(3)
	util.Effect("BloodImpact", ed)
	util.Decal("Blood", at, at - Vector(random(-20, 20), random(-20, 20), 80), ent)
end

local function hurt(scene, amount, dtype, bone)
	local body, victim = scene.vbody, scene.victim
	if !IsValid(victim) or !victim:Alive() then return end

	local into = victim
	if victim:IsPlayer() and IsValid(body) then into = body end

	if !victim:IsPlayer() then amount = math.min(amount, math.max(victim:Health() - 1, 0)) end

	local killer = scene.killer
	local dmg = DamageInfo()
	dmg:SetAttacker(IsValid(killer) and killer or game.GetWorld())
	dmg:SetInflictor(IsValid(killer) and killer or game.GetWorld())
	dmg:SetDamage(amount)
	dmg:SetDamageType(dtype or DMG_CLUB)
	dmg:SetDamagePosition(spot(scene, bone) or into:GetPos())

	scene.letpass = true
	into:TakeDamageInfo(dmg)
	scene.letpass = nil
end

local KNOCK = { weapon_hg_sledgehammer = true }

local function knockout(scene)
	local org = orgOf(scene)
	if !org then return end

	org.otrub = true
	org.disorientation = math.max(org.disorientation or 0, 15)
end

local function wound(scene, bone)
	local victim = scene.victim
	if !IsValid(victim) or !victim.organism then return end

	local fam = famOf(scene.name)
	local blade = BLADE[fam]

	if !BLUNT_FAM[fam] and isfunction(hg.organism.AddWoundManual) then
		hg.organism.AddWoundManual(victim, blade and random(30, 60) or random(4, 10),
			vector_origin, angle_zero, "ValveBiped.Bip01_" .. bone, CurTime())
	end

	hurt(scene, blade and 12 or 18, blade and DMG_SLASH or DMG_CLUB, bone)
end

local EV = {}

EV.black = function(scene)
	local v = scene.victim
	if !IsValid(v) or !v:IsPlayer() or scene.blacked then return end

	scene.blacked = true
	net.Start("mh_black")
		net.WriteFloat(math.max((v.MH_HoldUntil or 0) - CurTime(), 0) + 2)
	net.Send(v)
end

EV.stun = knockout

EV.neck = function(scene)
	snap(scene, "Neck1", NECK_SND)

	local org = orgOf(scene)
	if org then org.spine1 = 1 end

	knockout(scene)
end

EV.behead = function(scene)
	snap(scene, "Neck1")
	snap(scene, "Neck1", "physics/flesh/flesh_bloody_break.wav")
	gore(scene, "Neck1", 14)

	local org = orgOf(scene)
	if org then org.spine1 = 1 end

	knockout(scene)
end

EV.gib = function(scene)
	local v = scene.victim
	if !IsValid(v) or v.noHead or !isfunction(hg.ExplodeHead) then return end
	if !gore_cv:GetBool() then knockout(scene) return end

	hg.ExplodeHead(v)
	snap(scene, "Head1", "physics/flesh/flesh_bloody_break.wav")
	gore(scene, "Head1", 12)
end

EV.skull = function(scene)
	snap(scene, "Head1")
	snap(scene, "Head1", "physics/flesh/flesh_bloody_break.wav")
	gore(scene, "Head1", 6)

	local org = orgOf(scene)
	if org then
		org.skull = 1
		org.brain = 1
	end

	knockout(scene)
end

EV.jaw = function(scene)
	snap(scene, "Head1")

	local org = orgOf(scene)
	if org then org.jaw = 1 end
	hurt(scene, 20, DMG_CLUB, "Head1")
end

EV.spine = function(scene)
	snap(scene, "Spine2")

	local org = orgOf(scene)
	if org then org.spine2 = 1 end

	knockout(scene)
	hurt(scene, 25, DMG_CLUB, "Spine2")
end

EV.chest = function(scene)
	snap(scene, "Spine2")

	local org = orgOf(scene)
	if org then
		org.chest = 1
		if random(2) == 1 then org.spine2 = 1 end
	end

	hurt(scene, 30, DMG_CLUB, "Spine2")
end

EV.gut = function(scene)
	local org = orgOf(scene)
	if org then org.internalBleed = (org.internalBleed or 0) + 12 end

	hurt(scene, 20, DMG_CLUB, "Spine1")
end

EV.bleed = function(scene, ev)
	local bone = ev.bone or "Neck1"
	local v = scene.victim
	if IsValid(v) and v.organism and isfunction(hg.organism.AddWoundManual) then
		hg.organism.AddWoundManual(v, random(70, 110), vector_origin, angle_zero,
			"ValveBiped.Bip01_" .. bone, CurTime())
	end

	sound.Play(FLESH[random(4)], spot(scene, bone) or vector_origin, 85, random(90, 105), 1)
	gore(scene, bone, 8)
end

EV.tear = function(scene, ev)
	local bone = ev.bone or "Neck1"
	local dur = math.max((ev.till or 0) - ev.t, 0.3)
	local t = "mh_tear_" .. scene.killer:EntIndex()

	timer.Create(t, 0.25, math.max(math.ceil(dur / 0.25), 1), function()
		local v = scene.victim
		if !IsValid(v) or !v.organism then timer.Remove(t) return end

		if isfunction(hg.organism.AddWoundManual) then
			hg.organism.AddWoundManual(v, random(25, 45), vector_origin, angle_zero,
				"ValveBiped.Bip01_" .. bone, CurTime())
		end

		sound.Play(FLESH[random(#FLESH)], spot(scene, bone) or vector_origin, 80,
			random(85, 100), 0.9)
		gore(scene, bone, 5)
	end)

	scene.timers[#scene.timers + 1] = t
end

EV.choke = function(scene, ev)
	local org = orgOf(scene)
	if !org or !org.o2 then return end

	local from = org.o2[1] or 0
	local dur = math.max((ev.till or 0) - ev.t, 0.5)
	local start = CurTime()
	local t = "mh_choke_" .. scene.killer:EntIndex()

	timer.Create(t, 0.1, math.ceil(dur / 0.1) + 1, function()
		local o = orgOf(scene)
		if !o or !o.o2 then timer.Remove(t) return end

		local f = math.Clamp((CurTime() - start) / dur, 0, 1)
		o.o2[1] = math.min(o.o2[1] or from, from * (1 - f))
		o.o2.regen = 0
		o.o2.curregen = 0
	end)

	scene.timers[#scene.timers + 1] = t
end

local function fire(scene, ev)
	if ev.chance and math.Rand(0, 1) > ev.chance then
		local alt = ev.alt and EV[ev.alt]
		if alt then alt(scene, ev) end
		return
	end

	local f = EV[ev.k]
	if f then f(scene, ev) end
end

local function thud(scene, swing, bone, ev)
	if ev then fire(scene, ev) return end

	local ent = IsValid(scene.vbody) and scene.vbody or scene.victim
	if !IsValid(ent) then return end

	local pos = ent:GetPos() + Vector(0, 0, 45)
	local b = ent:LookupBone("ValveBiped.Bip01_" .. (bone or "Spine2"))
	if b then pos = ent:GetBonePosition(b) or pos end

	local wep = IsValid(scene.killer) and scene.killer:GetActiveWeapon()
	local fam = famOf(scene.name)

	if swing then
		local snd = (IsValid(wep) and validSound(wep.SwingSound)) or "weapons/iceaxe/iceaxe_swing1.wav"
		sound.Play(snd, pos, 70, random(95, 105), 1)
		return
	end

	local snd = hitSound(wep, fam)
	sound.Play(snd, pos, 85, random(92, 108), 1)
	ent:EmitSound(snd, 85, random(92, 108), 1, CHAN_AUTO)

	if BLADE[fam] then
		sound.Play(FLESH[random(#FLESH)], pos, 80, random(90, 110), 0.9)
	end

	if !BLUNT_FAM[fam] then gore(scene, bone or "Spine2", 2) end

	wound(scene, bone or "Spine2")
	if scene.knock then knockout(scene) end

end

local function loose(rag, on)
	if !IsValid(rag) then return end

	rag.LootingDisabled = on or nil

	if on then
		rag.MH_Group = rag.MH_Group or rag:GetCollisionGroup()
		rag:SetCollisionGroup(COLLISION_GROUP_WORLD)
	else
		rag:SetCollisionGroup(rag.MH_Group or COLLISION_GROUP_WEAPON)
		rag.MH_Group = nil
	end
end

local function down(ply, pos, ang, dur)
	ply:SetPos(pos)
	ply:SetEyeAngles(ang)
	ply.illbeback = ply.illbeback or 0

	if !IsValid(ply.FakeRagdoll) then hg.Fake(ply) end
	ply.MH_HoldUntil = CurTime() + dur
	ply:SetNWFloat("MH_Kill", CurTime() + dur)

	if isfunction(hg.SetFreemove) then
		hg.SetFreemove(ply, false)
	else
		ply:SetMoveType(MOVETYPE_NOCLIP)
	end
	loose(ply.FakeRagdoll, true)

	return ply.FakeRagdoll
end

local function humanoid(ent)
	return IsValid(ent) and ent:IsNPC() and ent:LookupBone("ValveBiped.Bip01_Spine") != nil
end

local function downNPC(npc, pos, ang, dur)
	local rag = ents.Create("prop_ragdoll")
	if !IsValid(rag) then return end

	rag:SetModel(npc:GetModel())
	rag:SetSkin(npc:GetSkin())
	rag:SetPos(pos)
	rag:SetAngles(ang)
	rag:Spawn()

	for i = 0, #rag:GetBodyGroups() - 1 do
		rag:SetBodygroup(i, npc:GetBodygroup(i))
	end

	npc.MH_HoldUntil = CurTime() + dur
	npc:SetNoDraw(true)
	npc:SetSolid(SOLID_NONE)
	npc:SetMoveType(MOVETYPE_NONE)
	npc:AddFlags(FL_NOTARGET)
	if npc.SetSchedule then npc:SetSchedule(SCHED_NONE) end

	loose(rag, true)
	return rag
end

local function animator(pos, ang, seq, rag)
	local e = ents.Create("mh_anim")
	e:SetPos(pos)
	e:SetAngles(ang)
	e:Spawn()
	if !e:Play(seq) then e:Remove() return end
	e:Drive(rag)
	return e
end

local function finish(scene, kill)
	scene.finishing = true

	for _, e in ipairs(scene.anims) do
		if IsValid(e) then e:Remove() end
	end
	if IsValid(scene.nocollide) then scene.nocollide:Remove() end
	for _, t in ipairs(scene.timers) do timer.Remove(t) end
	for who, s in pairs(live) do
		if s == scene then live[who] = nil end
	end

	local killer = scene.killer
	if IsValid(killer) then
		killer.MH_HoldUntil = nil
		killer:SetNWFloat("MH_Kill", 0)
		loose(scene.kbody, false)

		if killer:Alive() then
			local want, was = scene.ang, killer.LastFakeUp
			hg.FakeUp(killer)

			local t = "mh_face_" .. killer:EntIndex()
			timer.Create(t, 0.05, 40, function()
				if !IsValid(killer) then timer.Remove(t) return end
				if killer.LastFakeUp != was then
					killer:SetEyeAngles(want)
					timer.Remove(t)
				end
			end)
		end
	end

	local victim = scene.victim
	if !IsValid(victim) then return end
	victim.MH_HoldUntil = nil

	if !victim:IsPlayer() then
		loose(scene.vbody, false)
		if !kill then
			if IsValid(scene.vbody) then scene.vbody:Remove() end
			victim:SetNoDraw(false)
			victim:SetSolid(SOLID_BBOX)
			victim:SetMoveType(MOVETYPE_STEP)
			victim:RemoveFlags(FL_NOTARGET)
			return
		end

		local wep = IsValid(killer) and killer:GetActiveWeapon()
		local dmg = DamageInfo()
		dmg:SetAttacker(IsValid(killer) and killer or game.GetWorld())
		dmg:SetInflictor(IsValid(wep) and wep or (IsValid(killer) and killer or game.GetWorld()))
		dmg:SetDamage(1000)
		dmg:SetDamageType(DMG_SLASH)
		dmg:SetDamagePosition(IsValid(scene.vbody) and scene.vbody:GetPos() or victim:GetPos())

		scene.letpass = true
		victim:TakeDamageInfo(dmg)
		scene.letpass = nil

		local own = victim.GetRagdollEntity and victim:GetRagdollEntity()
		if IsValid(own) then own:Remove() end
		if IsValid(victim) then victim:Remove() end
		return
	end

	victim:SetNWFloat("MH_Kill", 0)
	loose(scene.vbody, false)

	if !kill then
		if victim:Alive() then hg.FakeUp(victim) end
		return
	end

	local k = MH.Kills[scene.name]
	local body, parts = scene.vbody, k and k.parts
	local blade = BLADE[famOf(scene.name)]

	local function finisher(into)
		if !IsValid(victim) or !victim:Alive() or !IsValid(into) then return end

		local wep = IsValid(killer) and killer:GetActiveWeapon()
		local dmg = DamageInfo()
		dmg:SetAttacker(IsValid(killer) and killer or game.GetWorld())
		dmg:SetInflictor(IsValid(wep) and wep or (IsValid(killer) and killer or game.GetWorld()))
		dmg:SetDamage(blade and 60 or 90)
		dmg:SetDamageType(blade and DMG_SLASH or DMG_CLUB)

		local last = parts and parts[#parts] or "Neck1"
		local b = into:LookupBone("ValveBiped.Bip01_" .. last)
		dmg:SetDamagePosition(b and into:GetBonePosition(b) or into:GetPos())

		scene.letpass = true
		into:TakeDamageInfo(dmg)
		scene.letpass = nil
	end

	local function bleedout()
		if !IsValid(victim) or !victim:Alive() then return end

		local org = victim.organism
		if !org then
			finisher(victim)
			return
		end

		org.blood = 0
		if org.o2 then org.o2[1] = 0 end
		org.otrub = true
	end

	timer.Simple(0.1, function() finisher(IsValid(body) and body or victim) end)
	if k and k.soft then return end

	timer.Simple(0.4, bleedout)
	timer.Simple(1.5, bleedout)
end

hook.Add("PlayerDeath", "manhunt_kills_dead", function(ply)
	local scene = live[ply]
	if !scene then return end

	timer.Simple(0.05, function()
		if live[ply] != scene then return end

		local ours = scene.victim == ply and scene.vbody or scene.kbody
		local now = isfunction(hg.GetCurrentCharacter) and hg.GetCurrentCharacter(ply)
		if IsValid(now) and IsValid(ours) and now != ours then finish(scene, false) end
	end)
end)

function MH.Play(killer, victim, name)
	local k = MH.Kills[name]
	if !k then return false, "no such kill: " .. tostring(name) end
	if !IsValid(killer) or !IsValid(victim) then return false, "invalid target" end
	if live[killer] or busy(killer) then return false, "already busy with someone" end
	if live[victim] or busy(victim) then return false, "he is already in an execution" end
	if !isfunction(hg.Fake) then return false, "this gamemode has no hg.Fake" end

	for _, s in pairs(live) do
		if s.victim == victim or s.killer == victim then return false, "he is already in an execution" end
		if s.victim == killer or s.killer == killer then return false, "already busy with someone" end
	end

	local wep = killer:GetActiveWeapon()
	local cost = costOf(killer, wep, k)
	local have = stamina(killer)
	if have and have < cost then return false, "out of breath" end

	local ang = Angle(0, killer:EyeAngles().yaw, 0)
	local pos = killer:GetPos()
	local dur = k.len + 0.5

	local kbody = down(killer, pos, ang, dur)
	local vbody = victim:IsPlayer() and down(victim, pos, ang, dur)
		or downNPC(victim, pos, ang, dur)
	if !IsValid(kbody) or !IsValid(vbody) then return false, "could not put them down" end

	local nocollide = constraint.NoCollide(kbody, vbody, 0, 0)
	local ka = animator(pos, ang, name, kbody)
	local va = animator(pos, ang, "Damage_" .. name, vbody)

	if !ka or !va then
		if IsValid(nocollide) then nocollide:Remove() end
		if IsValid(ka) then ka:Remove() end
		if IsValid(va) then va:Remove() end
		return false, "no sequences in " .. MH.MODEL
	end

	local id = killer:EntIndex()
	local scene = {
		killer = killer, victim = victim,
		kbody = kbody, vbody = vbody,
		anims = { ka, va }, nocollide = nocollide,
		name = name, ang = ang,
		knock = KNOCK[IsValid(wep) and wep:GetClass() or ""],
		timers = { "mh_hit_" .. id, "mh_end_" .. id }
	}
	live[killer] = scene
	live[victim] = scene
	drain(killer, cost)

	timer.Create(scene.timers[1], k.hit, 1, function()
		if IsValid(va) then va:Play("Die_" .. name) end
	end)
	timer.Create(scene.timers[2], k.len, 1, function() finish(scene, true) end)

	local marks = {}
	for i, at in ipairs(k.blows) do
		local bone = k.parts and k.parts[i] or "Spine2"
		marks[#marks + 1] = { t = math.max(at - 0.15, 0.05), swing = true, bone = bone }
		marks[#marks + 1] = { t = at, swing = false, bone = bone }
	end
	local dark = k.blows[#k.blows] or 0
	for _, ev in ipairs(k.events or {}) do
		marks[#marks + 1] = { t = ev.t, ev = ev }
		dark = math.max(dark, ev.till or ev.t)
	end
	marks[#marks + 1] = { t = dark, ev = { k = "black" } }

	ka:HitsAt(marks, function(_, swing, bone, ev) thud(scene, swing, bone, ev) end)
	if k.cloth then ka:ClothAt(k.cloth, function() rustle(scene) end) end

	return true
end

local function pick(ply, want)
	if want and want != "" then
		if MH.Kills[want] then return want end
		for _, n in ipairs(table.GetKeys(MH.Kills)) do
			if string.find(string.lower(n), string.lower(want), 1, true) then return n end
		end
		return nil, "no kill matching " .. want
	end

	local wep = ply:GetActiveWeapon()
	if !IsValid(wep) then return nil, "nothing in your hands" end

	local cls = wep:GetClass()
	local set = {}

	for _, n in ipairs((MH.KillsFor and MH.KillsFor[cls]) or {}) do
		if MH.Kills[n] then set[#set + 1] = n end
	end

	if #set == 0 then
		local fams = MH.ByWeapon[cls]
		if !fams then return nil, "you cannot finish anyone with that" end

		for _, fam in ipairs(fams) do
			for n in pairs(MH.Kills) do
				if string.StartWith(n, fam .. "_") then set[#set + 1] = n end
			end
		end
	end
	if #set == 0 then return nil, "no kills compiled for that weapon" end

	local have = stamina(ply)
	if have then
		local can = {}
		for _, n in ipairs(set) do
			if costOf(ply, wep, MH.Kills[n]) <= have then can[#can + 1] = n end
		end
		if #can == 0 then return nil, "out of breath" end
		set = can
	end

	return set[random(#set)]
end

local function aimAt(ply)
	local function whois(e)
		if !IsValid(e) then return end
		if !e:IsPlayer() and isfunction(hg.RagdollOwner) then e = hg.RagdollOwner(e) or e end
		if IsValid(e) and e != ply and (e:IsPlayer() or humanoid(e)) then return e end
	end

	local hit = whois(ply:GetEyeTrace().Entity)
	if hit then return hit end

	local eye, aim = ply:EyePos(), ply:GetAimVector()
	local best, dot = nil, 0.75

	for _, e in ipairs(ents.FindInSphere(eye, RANGE)) do
		local who = whois(e)
		if who then
			local d = who:WorldSpaceCenter() - eye
			local len = d:Length()
			if len > 1 and aim:Dot(d / len) > dot then best, dot = who, aim:Dot(d / len) end
		end
	end

	return best
end

concommand.Add("mh_kill", function(ply, _, args)
	if !IsValid(ply) or !ply:IsSuperAdmin() then return end
	if !ply:Alive() then return end
	if busy(ply) or live[ply] then return end

	local target = aimAt(ply)
	if !IsValid(target) then ply:ChatPrint("aim at a player") return end

	if busy(target) or live[target] then
		ply:ChatPrint("he is already in an execution")
		return
	end

	local isnpc = humanoid(target)
	if isnpc and !npc_cv:GetBool() then ply:ChatPrint("NPC executions are off") return end
	if target == ply or target:GetPos():Distance(ply:GetPos()) > RANGE then
		ply:ChatPrint("too far")
		return
	end

	local org = target.organism
	if !target:Alive() or (org and org.otrub) then
		ply:ChatPrint("he is out cold already")
		return
	end

	local behind = ply:GetPos() - target:GetPos()
	behind.z = 0
	if behind:GetNormalized():Dot(Angle(0, target:EyeAngles().yaw, 0):Forward()) > BEHIND then
		ply:ChatPrint("get behind him")
		return
	end

	local name, why = pick(ply, args[1])
	if !name then ply:ChatPrint(why or "no kill") return end

	local ok, err = MH.Play(ply, target, name)
	if !ok then ply:ChatPrint(err) return end
	if debug_cv:GetBool() then ply:ChatPrint(name) end
end)

concommand.Add("mh_kill_list", function(ply)
	for _, n in ipairs(table.GetKeys(MH.Kills)) do
		if IsValid(ply) then ply:PrintMessage(HUD_PRINTCONSOLE, n) else print(n) end
	end
end)

hook.Add("Initialize", "manhunt_kills_check", function()
	if !file.Exists(MH.MODEL, "GAME") then
		ErrorNoHalt("[manhunt] missing " .. MH.MODEL .. " - addon is not mounted, check the models folder\n")
	end
end)

hook.Add("PlayerDisconnected", "manhunt_kills_cleanup", function(ply)
	for who, scene in pairs(live) do
		if who == ply or scene.victim == ply or scene.killer == ply then finish(scene, false) end
	end
end)
