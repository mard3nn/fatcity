-- Admin organism control menu (server)

util.AddNetworkString("hg_orgmenu_open")
util.AddNetworkString("hg_orgmenu_request")
util.AddNetworkString("hg_orgmenu_snapshot")
util.AddNetworkString("hg_orgmenu_set")
util.AddNetworkString("hg_orgmenu_action")

local NESTED_KEYS = {
	stamina = true,
	o2 = true,
	lungsL = true,
	lungsR = true,
}

local SNAPSHOT_FIELDS = {
	"alive", "otrub", "canmove", "superfighter", "godmode",
	"health", "temperature", "consciousness", "disorientation", "fear", "fearadd",
	"blood", "bleed", "internalBleed", "bloodtype", "bleedingmul",
	"arteria", "rarmartery", "larmartery", "rlegartery", "llegartery", "spineartery",
	"pain", "avgpain", "painadd", "shock", "hurt", "hurtadd", "immobilization",
	"painkiller", "analgesia", "analgesiaAdd", "naloxone", "tranquilizer",
	"adrenaline", "adrenalineAdd", "adrenalineStorage",
	"pulse", "heartbeat", "bloodPressure", "systolic", "diastolic", "cardiacOutput",
	"heart", "heartstop", "fibrillation", "arrhythmia", "myocardialOxygen", "heartStrain",
	"hypertension", "hypotension", "lungsfunction",
	"brain", "brainFrontal", "brainParietal", "brainTemporal", "brainOccipital",
	"brainHemorrhage", "brainBleedRate", "skull", "jaw",
	"spine1", "spine2", "spine3", "chest", "pelvis",
	"stomach", "liver", "intestines", "thiamine",
	"eyeL", "eyeR", "trachea", "pneumothorax", "needle", "CO",
	"lleg", "rleg", "larm", "rarm",
	"llegdislocation", "rlegdislocation", "larmdislocation", "rarmdislocation", "jawdislocation",
	"llegamputated", "rlegamputated", "larmamputated", "rarmamputated", "headamputated",
	"berserk", "noradrenaline", "assimilated", "furryinfected",
	"panicattack", "panicattackadd", "seizure", "seizureActive",
	"recoilmul", "meleespeed", "legstrength", "hungry", "satiety",
	"stun", "lightstun", "holdingbreath", "wantToVomit",
}

local function canUse(ply)
	return IsValid(ply) and ply:IsPlayer() and ply:IsAdmin()
end

local function resolveTarget(ent)
	if not IsValid(ent) then return nil end
	if ent:IsPlayer() then return ent end
	local owner = hg.RagdollOwner and hg.RagdollOwner(ent)
	if IsValid(owner) then return owner end
	if ent.organism then return ent end
	return nil
end

local function getOrg(ent)
	local target = resolveTarget(ent)
	if not IsValid(target) then return nil, nil end
	return target.organism, target
end

local function readPath(org, path)
	if not org or not path then return nil end

	local parts = string.Explode(".", path)
	local cur = org

	for i = 1, #parts do
		local key = parts[i]
		local asNum = tonumber(key)
		if asNum ~= nil then key = asNum end

		if type(cur) ~= "table" then return nil end
		cur = cur[key]
	end

	return cur
end

local function writePath(org, path, value)
	if not org or not path then return false end

	local parts = string.Explode(".", path)
	local cur = org

	for i = 1, #parts - 1 do
		local key = parts[i]
		local asNum = tonumber(key)
		if asNum ~= nil then key = asNum end

		if type(cur[key]) ~= "table" then
			cur[key] = {}
		end
		cur = cur[key]
	end

	local last = parts[#parts]
	local asNum = tonumber(last)
	if asNum ~= nil then last = asNum end

	cur[last] = value
	return true
end

local function coerceValue(old, value, valueType)
	if valueType == "bool" or type(old) == "boolean" then
		return tobool(value)
	end

	if valueType == "string" or type(old) == "string" then
		return tostring(value)
	end

	local num = tonumber(value)
	if num ~= nil then return num end

	return value
end

local function buildSnapshot(org, owner)
	local snap = {
		entindex = IsValid(owner) and owner:EntIndex() or 0,
		name = IsValid(owner) and (owner.GetName and owner:GetName() or tostring(owner)) or "?",
		alivePlayer = IsValid(owner) and owner:IsPlayer() and owner:Alive() or false,
	}

	for i = 1, #SNAPSHOT_FIELDS do
		local key = SNAPSHOT_FIELDS[i]
		local val = org[key]
		if val ~= nil and type(val) ~= "table" and type(val) ~= "function" and type(val) ~= "userdata" then
			snap[key] = val
		end
	end

	if type(org.stamina) == "table" then
		snap["stamina.1"] = org.stamina[1]
		snap["stamina.max"] = org.stamina.max
		snap["stamina.regen"] = org.stamina.regen
		snap["stamina.sub"] = org.stamina.sub
		snap["stamina.range"] = org.stamina.range
	end

	if type(org.o2) == "table" then
		snap["o2.1"] = org.o2[1]
		snap["o2.range"] = org.o2.range
		snap["o2.regen"] = org.o2.regen
		snap["o2.curregen"] = org.o2.curregen
	end

	if type(org.lungsL) == "table" then
		snap["lungsL.1"] = org.lungsL[1]
		snap["lungsL.2"] = org.lungsL[2]
	end

	if type(org.lungsR) == "table" then
		snap["lungsR.1"] = org.lungsR[1]
		snap["lungsR.2"] = org.lungsR[2]
	end

	return snap
end

local function syncOrg(org, owner)
	if not org then return end
	if IsValid(owner) then
		owner.fullsend = true
		if owner:IsPlayer() and owner:Alive() then
			hg.send_organism(org, owner)
		end
	end
	hg.send_bareinfo(org)
end

local function sendSnapshot(ply, target)
	local org, owner = getOrg(target)
	if not org then return end

	net.Start("hg_orgmenu_snapshot")
		net.WriteEntity(owner)
		net.WriteTable(buildSnapshot(org, owner))
	net.Send(ply)
end

concommand.Add("hg_organism_menu", function(ply)
	if not canUse(ply) then return end

	net.Start("hg_orgmenu_open")
	net.Send(ply)
end)

net.Receive("hg_orgmenu_request", function(_, ply)
	if not canUse(ply) then return end

	local target = net.ReadEntity()
	if not IsValid(target) then return end

	sendSnapshot(ply, target)
end)

net.Receive("hg_orgmenu_set", function(_, ply)
	if not canUse(ply) then return end

	local target = net.ReadEntity()
	local path = net.ReadString()
	local valueType = net.ReadString()
	local value = net.ReadType()

	local org, owner = getOrg(target)
	if not org or path == "" then return end

	-- disallow writing raw nested tables as a whole through this path except known nested keys via dotted paths
	local root = string.Explode(".", path)[1]
	if NESTED_KEYS[path] then return end

	local old = readPath(org, path)
	local newValue = coerceValue(old, value, valueType)

	if not writePath(org, path, newValue) then return end

	if path == "health" and IsValid(owner) and owner:IsPlayer() then
		owner:SetHealth(math.Clamp(tonumber(newValue) or owner:Health(), 1, owner:GetMaxHealth()))
	end

	syncOrg(org, owner)
	sendSnapshot(ply, owner)
end)

local ACTIONS = {}

ACTIONS.clear = function(org, owner)
	hg.organism.Clear(org)
end

ACTIONS.heartstop = function(org)
	org.heartstop = true
	org.pulse = 0
	org.heartbeat = 0
end

ACTIONS.heartstart = function(org)
	org.heartstop = false
	org.fibrillation = false
	org.pulse = math.max(org.pulse or 0, 70)
	org.heartbeat = math.max(org.heartbeat or 0, 70)
	org.lungsfunction = true
end

ACTIONS.fibrillation = function(org)
	if hg.organism.StartFibrillation then
		hg.organism.StartFibrillation(org)
	else
		org.fibrillation = true
	end
end

ACTIONS.otrub = function(org)
	org.needotrub = true
	org.otrub = true
	org.consciousness = 0
end

ACTIONS.wake = function(org)
	org.needotrub = false
	org.otrub = false
	org.consciousness = 1
	org.shock = 0
	org.pain = math.min(org.pain or 0, 40)
	org.avgpain = math.min(org.avgpain or 0, 40)
end

ACTIONS.seizure_start = function(org)
	hg.organism.AddSeizure(org, 1)
	org.seizure = 1
end

ACTIONS.seizure_stop = function(org, owner)
	org.seizure = 0
	org.seizureActive = false
	org.seizureStart = 0
	org.seizureEnd = 0
end

ACTIONS.panic = function(org)
	hg.organism.AddPanicAttack(org, 1, true)
	org.panicattackadd = 1
	org.panicattack = 1
end

ACTIONS.berserk = function(org)
	org.berserk = math.max(org.berserk or 0, 3)
end

ACTIONS.noradrenaline = function(org)
	org.noradrenaline = math.max(org.noradrenaline or 0, 3)
end

ACTIONS.bleedout = function(org)
	org.blood = 1500
	org.bleed = 20
	org.internalBleed = 5
end

ACTIONS.fullheal = function(org, owner)
	hg.organism.Clear(org)
	if IsValid(owner) and owner:IsPlayer() and owner:Alive() then
		owner:SetHealth(owner:GetMaxHealth())
	end
end

ACTIONS.killbrain = function(org)
	org.brain = 1
	org.brainFrontal = 1
	org.brainParietal = 1
	org.brainTemporal = 1
	org.brainOccipital = 1
	org.consciousness = 0
	org.needotrub = true
	org.otrub = true
end

ACTIONS.amputate_lleg = function(org)
	if hg.organism.AmputateLimb then hg.organism.AmputateLimb(org, "lleg") end
end

ACTIONS.amputate_rleg = function(org)
	if hg.organism.AmputateLimb then hg.organism.AmputateLimb(org, "rleg") end
end

ACTIONS.amputate_larm = function(org)
	if hg.organism.AmputateLimb then hg.organism.AmputateLimb(org, "larm") end
end

ACTIONS.amputate_rarm = function(org)
	if hg.organism.AmputateLimb then hg.organism.AmputateLimb(org, "rarm") end
end

ACTIONS.explode_head = function(org, owner)
	if IsValid(owner) and hg.ExplodeHead then
		hg.ExplodeHead(hg.GetCurrentCharacter and hg.GetCurrentCharacter(owner) or owner, 500, false, Vector(0, 0, 100))
	end
end

ACTIONS.fake = function(org, owner)
	if IsValid(owner) and owner:IsPlayer() and hg.Fake then
		hg.Fake(owner)
	end
end

ACTIONS.god_on = function(org)
	org.godmode = true
end

ACTIONS.god_off = function(org)
	org.godmode = false
end

net.Receive("hg_orgmenu_action", function(_, ply)
	if not canUse(ply) then return end

	local target = net.ReadEntity()
	local action = net.ReadString()

	local org, owner = getOrg(target)
	if not org then return end

	local fn = ACTIONS[action]
	if not fn then return end

	fn(org, owner)
	syncOrg(org, owner)
	sendSnapshot(ply, owner)
end)
