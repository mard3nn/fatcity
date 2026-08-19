ZCFpv = ZCFpv or {}

if SERVER then
	AddCSLuaFile()
	AddCSLuaFile("zcity_fpvdrone/sh_config.lua")
	AddCSLuaFile("zcity_fpvdrone/sh_net.lua")
	AddCSLuaFile("zcity_fpvdrone/cl_fpv.lua")
	AddCSLuaFile("zcity_fpvdrone/cl_vhs_engine. lua")
	AddCSLuaFile("zcity_fpvdrone/cl_fx.lua")

	local allowExt = {
		mdl = true, vtx = true, vvd = true, phy = true, ani = true,
		vmt = true, vtf = true,
		wav = true, ogg = true, mp3 = true,
		png = true, jpg = true,
		ttf = true, otf = true,
	}

	local function addFile(path)
		if file.Exists(path, "GAME") then
			resource.AddFile(path)
		end
	end

	local function addTree(dir)
		local files, dirs = file.Find(dir .. "/*", "GAME")
		for _, f in ipairs(files or {}) do
			local ext = string.GetExtensionFromFilename(f)
			if ext and allowExt[string.lower(ext)] then
				addFile(dir .. "/" .. f)
			end
		end
		for _, d in ipairs(dirs or {}) do
			addTree(dir .. "/" .. d)
		end
	end

	addTree("models/sw/avia/crocus")
	addTree("models/sw/avia/mavic2")
	addTree("models/sw/avia/geran2")
	addTree("models/sw/shared")
	addTree("models/dronesrewrite/c_controller")
	addTree("models/dronesrewrite/w_controller")
	addTree("models/codeecho/yolka_interceptor")
	addTree("models/kortez")
	addTree("models/shtormer")

	addTree("materials/models/sw/avia/crocus")
	addTree("materials/models/sw/avia/mavic2")
	addTree("materials/models/sw/avia/geran2")
	addTree("materials/models/sw/shared")
	addTree("materials/models/dronesrewrite/w_controller")
	addTree("materials/models/codeecho/yolka_interceptor")
	addTree("materials/models/kortez")
	addTree("materials/models/shtormer")
	addTree("materials/codeecho/yolka_interceptor")
	addTree("materials/osd")

	addFile("materials/effects/fpv_noise.vmt")
	addFile("materials/effects/fpv_noise.vtf")
	addFile("resource/fonts/vcr osd mono cyr.ttf")

	addFile("materials/entities/weapon_yolka_interceptor.png")
	addTree("sound/sw/crocus")
	addTree("sound/sw/mavic2")
	addTree("sound/sw/geran2")
	addTree("sound/codeecho/yolka_interceptor")

	for _, f in ipairs(file.Find("materials/entities/net*.png", "GAME") or {}) do
		addFile("materials/entities/" .. f)
	end
	for _, f in ipairs(file.Find("materials/entities/sw_*.png", "GAME") or {}) do
		addFile("materials/entities/" .. f)
	end
end

include("zcity_fpvdrone/sh_config.lua")
include("zcity_fpvdrone/sh_net.lua")

if SERVER then
	include("zcity_fpvdrone/sv_control.lua")
	include("zcity_fpvdrone/sv_npc.lua")
else
	include("zcity_fpvdrone/cl_vhs_engine.lua")
	include("zcity_fpvdrone/cl_fpv.lua")
	include("zcity_fpvdrone/cl_fx.lua")
end
