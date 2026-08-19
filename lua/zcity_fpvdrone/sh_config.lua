ZCFpv = ZCFpv or {}

ZCFpv.SignalRange = 11000
ZCFpv.SignalGrace = 3500
ZCFpv.SignalCheckInterval = 0.2
ZCFpv.DeployCooldown = 1.5
ZCFpv.FOV = 75

-- defaults
ZCFpv.Flight = {
	inputSmooth = 6,
	accelRate = 1,
	drag = 1,
	angDamp = 0.16,
	batteryTime = 180,
	rpmPitchMin = 85,
	rpmPitchMax = 135,
}

ZCFpv.Types = {
	crocus = {
		class = "ent_zc_fpv_crocus",
		name = "Crocus PG-7",
		model = "models/sw/avia/crocus/crocus_pg7.mdl",
		sound = "sw/crocus/crocus_idle.wav",
		maxHealth = 5,
		maxVelocity = 2800,
		mass = 6,
		thrust = 1200,
		turnRate = 200,
		hoverForce = 1.08,
		strike = true,
		signalRangeMultiplier = 4,
		blastDamage = 300,
		blastRadius = 180,
		heatDamage = 2500,
		heatForce = 50000,
		heatHull = 2,
		heatLength = 150,
		collideDetonateSpeed = 180,
		inputSmooth = 7,
		accelRate = 1.05,
		drag = 0.95,
		angDamp = 0.15,
		batteryTime = 150,
		rpmPitchMin = 90,
		rpmPitchMax = 140,
	},
	crocus_frag = {
		class = "ent_zc_fpv_crocus_frag",
		name = "Crocus Frag",
		model = "models/sw/avia/crocus/crocus_tbg7.mdl",
		sound = "sw/crocus/crocus_idle.wav",
		maxHealth = 5,
		maxVelocity = 2700,
		mass = 7,
		thrust = 1200,
		turnRate = 190,
		hoverForce = 1.08,
		strike = true,
		signalRangeMultiplier = 4,
		blastDamage = 450,
		blastRadius = 360,
		fragCount = 128,
		fragDamage = 85,
		fragForce = 18,
		fragDistance = 1600,
		collideDetonateSpeed = 180,
		inputSmooth = 6.5,
		accelRate = 1,
		drag = 1,
		angDamp = 0.16,
		batteryTime = 150,
		rpmPitchMin = 90,
		rpmPitchMax = 138,
	},
	crocus_incendiary = {
		class = "ent_zc_fpv_crocus_incendiary",
		name = "Crocus Incendiary",
		model = "models/sw/avia/crocus/crocus_tbg7.mdl",
		sound = "sw/crocus/crocus_idle.wav",
		maxHealth = 5,
		maxVelocity = 2650,
		mass = 7,
		thrust = 1180,
		turnRate = 185,
		hoverForce = 1.08,
		strike = true,
		signalRangeMultiplier = 4,
		blastDamage = 120,
		blastRadius = 220,
		burnRadius = 420,
		burnTime = 18,
		fireballs = 32,
		collideDetonateSpeed = 180,
		inputSmooth = 6.5,
		accelRate = 0.98,
		drag = 1.02,
		angDamp = 0.16,
		batteryTime = 150,
		rpmPitchMin = 90,
		rpmPitchMax = 136,
	},
	mavic = {
		class = "ent_zc_fpv_mavic",
		name = "Mavic 2",
		model = "models/sw/avia/mavic2/mavic2.mdl",
		sound = "sw/mavic2/mavic2_idle.wav",
		maxHealth = 100,
		maxVelocity = 1700,
		mass = 10,
		thrust = 850,
		turnRate = 130,
		hoverForce = 1.04,
		strike = false,
		collideBreakSpeed = 400,
		inputSmooth = 5,
		accelRate = 0.85,
		drag = 1.15,
		angDamp = 0.2,
		batteryTime = 240,
		rpmPitchMin = 80,
		rpmPitchMax = 125,
	},
	geran2 = {
		class = "ent_zc_fpv_geran2",
		name = "Geran-2",
		model = "models/sw/avia/geran2/geran2.mdl",
		sound = "sw/geran2/geran_idle.wav",
		maxHealth = 250,
		maxVelocity = 2200,
		mass = 180,
		thrust = 900,
		turnRate = 95,
		hoverForce = 1,
		strike = true,
		signalRangeMultiplier = 4,
		lethalDamage = 15000,
		lethalRadius = 586,
		blastDamage = 7500,
		blastRadius = 880,
		fragCount = 100,
		fragDamage = 25,
		fragDistance = 1172,
		collideDetonateSpeed = 120,
		engineForce = 68000,
		stallSpeed = 480,
		maxBank = 65,
		steeringPower = 1.45,
		inputSmooth = 6,
		accelRate = 0.85,
		drag = 1.05,
		maxVelocity = 2300,
		turnRate = 140,
		batteryTime = 900,
		rpmPitchMin = 70,
		rpmPitchMax = 115,
	},
}

ZCFpv.TypeOrder = {"crocus", "crocus_frag", "crocus_incendiary", "mavic"}

ZCFpv.PayloadWeapons = {
	["weapon_hg_hl2nade_tpik"] = true,
	["weapon_hg_f1_tpik"] = true,
	["weapon_hg_flashbang_tpik"] = true,
	["weapon_hg_m18_tpik"] = true,
	["weapon_hg_grenade_tpik"] = true,
	["weapon_hg_mk2_tpik"] = true,
	["weapon_hg_nebelgranate_tpik"] = true,
	["weapon_hg_pipebomb_tpik"] = true,
	["weapon_hg_rgd_tpik"] = true,
	["weapon_hg_rpg40"] = true,
	["weapon_hg_type59_tpik"] = true,
	["weapon_hg_rgo_tpik"] = true,
}

function ZCFpv.IsPayloadGrenade(wep)
	return IsValid(wep) and ZCFpv.PayloadWeapons[wep:GetClass()] and isstring(wep.ENT) and wep.ENT ~= ""
end

function ZCFpv.GetFlightParam(drone, key)
	local def = ZCFpv.Flight and ZCFpv.Flight[key]
	if not IsValid(drone) then return def end
	if drone[key] ~= nil then return drone[key] end
	local class = drone:GetClass()
	if ZCFpv.Types then
		for _, cfg in pairs(ZCFpv.Types) do
			if cfg.class == class and cfg[key] ~= nil then return cfg[key] end
		end
	end
	return def
end

sound.Add({
	name = "zc_fpv.crocus_idle",
	channel = CHAN_STATIC,
	volume = 1,
	level = 70,
	pitch = {95, 105},
	sound = "sw/crocus/crocus_idle.wav",
})
sound.Add({
	name = "zc_fpv.mavic_idle",
	channel = CHAN_STATIC,
	volume = 1,
	level = 70,
	pitch = {95, 105},
	sound = "sw/mavic2/mavic2_idle.wav",
})
sound.Add({
	name = "zc_fpv.geran_idle",
	channel = CHAN_STATIC,
	volume = 1,
	level = 0,
	pitch = {90, 125},
	sound = "sw/geran2/geran_idle.wav",
})
