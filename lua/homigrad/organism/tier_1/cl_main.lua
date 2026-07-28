hg.bonetohitgroup = {
	["ValveBiped.Bip01_Head1"] = HITGROUP_HEAD,
	["ValveBiped.Bip01_L_UpperArm"] = HITGROUP_LEFTARM,
	["ValveBiped.Bip01_L_Forearm"] = HITGROUP_LEFTARM,
	["ValveBiped.Bip01_L_Hand"] = HITGROUP_LEFTARM,
	["ValveBiped.Bip01_R_UpperArm"] = HITGROUP_RIGHTARM,
	["ValveBiped.Bip01_R_Forearm"] = HITGROUP_RIGHTARM,
	["ValveBiped.Bip01_R_Hand"] = HITGROUP_RIGHTARM,
	["ValveBiped.Bip01_Pelvis"] = HITGROUP_CHEST,
	["ValveBiped.Bip01_Spine2"] = HITGROUP_CHEST,
	["ValveBiped.Bip01_Spine1"] = HITGROUP_STOMACH,
	["ValveBiped.Bip01_Spine4"] = HITGROUP_CHEST,
	["ValveBiped.Bip01_Spine"] = HITGROUP_STOMACH,
	["ValveBiped.Bip01_L_Thigh"] = HITGROUP_LEFTLEG,
	["ValveBiped.Bip01_L_Calf"] = HITGROUP_LEFTLEG,
	["ValveBiped.Bip01_L_Foot"] = HITGROUP_LEFTLEG,
	["ValveBiped.Bip01_R_Thigh"] = HITGROUP_RIGHTLEG,
	["ValveBiped.Bip01_R_Calf"] = HITGROUP_RIGHTLEG,
	["ValveBiped.Bip01_R_Foot"] = HITGROUP_RIGHTLEG
}

hg.amputeetable = {
	--["ValveBiped.Bip01_L_UpperArm"] = "larm",
	["ValveBiped.Bip01_L_Forearm"] = "larm",
	["ValveBiped.Bip01_L_Hand"] = "larm",
	--["ValveBiped.Bip01_R_UpperArm"] = "rarm",
	["ValveBiped.Bip01_R_Forearm"] = "rarm",
	["ValveBiped.Bip01_R_Hand"] = "rarm",
	--["ValveBiped.Bip01_L_Thigh"] = "lleg",
	["ValveBiped.Bip01_L_Calf"] = "lleg",
	["ValveBiped.Bip01_L_Foot"] = "lleg",
	--["ValveBiped.Bip01_R_Thigh"] = "rleg",
	["ValveBiped.Bip01_R_Calf"] = "rleg",
	["ValveBiped.Bip01_R_Foot"] = "rleg"
}

--[[hg.amputeetable = {
	[HITGROUP_LEFTLEG] = "lleg",
	[HITGROUP_RIGHTLEG] = "rleg",
	[HITGROUP_LEFTARM] = "larm",
	[HITGROUP_RIGHTARM] = "rarm",
	//[HITGROUP_HEAD] = 0.5
}--]]

hook.Add("ScalePlayerDamage", "remove-effects", function(ent, hitgroup, dmgInfo)
	if dmgInfo:IsDamageType(DMG_BUCKSHOT + DMG_BULLET + DMG_SLASH) then
		return true
	end
end)

local min = math.min
local pain_mat = Material("sprites/mat_jack_hmcd_narrow")

local tab = {
	["$pp_colour_addr"] = 0,
	["$pp_colour_addg"] = 0,
	["$pp_colour_addb"] = 0,
	["$pp_colour_brightness"] = 0,
	["$pp_colour_contrast"] = 1,
	["$pp_colour_colour"] = 1,
	["$pp_colour_mulr"] = 0,
	["$pp_colour_mulg"] = 0,
	["$pp_colour_mulb"] = 0,
}

local tabblood = {
	["$pp_colour_addr"] = 0,
	["$pp_colour_addg"] = 0,
	["$pp_colour_addb"] = 0,
	["$pp_colour_brightness"] = 0,
	["$pp_colour_contrast"] = 1,
	["$pp_colour_colour"] = 1,
	["$pp_colour_mulr"] = 0,
	["$pp_colour_mulg"] = 0,
	["$pp_colour_mulb"] = 0,
}

local k1, k2, k3

local upDir = Vector(0, 0, 1)
local fwdDir = Vector(0, 2.5, 0)
local rightDir = Vector(2.5, 0, 0)

local function plyCommand(ply,cmd)
	local time = CurTime()
	ply.cmdtimer = ply.cmdtimer or time

	if cmd == "soundfade 100 99999" then
		if IsValid(hg.chat) then
			hg.chat:SetRealAlpha(0)

			timer.Create("otrubhuy", 1, 1, function()
				if lply.organism and not lply.organism.otrub then lply:ConCommand("soundfade 0 1") end
				hg.chat:AnimateRealAlpha(255)
			end)
		end
	end

	if ply.cmdtimer < time then
		ply.cmdtimer = time + 0.1

		ply:ConCommand(cmd)
	end
end

local clr_black1 = Color( 0, 0, 0, 255)
local clr_black2 = Color( 0, 0, 0, 255)

local mat1 = Material("vgui/gradient-u")
local mat2 = Material("vgui/gradient-d")

local ang1 = Angle()
local ang2 = Angle()

hook.Add("HUDShouldDraw", "hg.HUDShouldDraw", function(id)
	if (fakeTimer and fakeTimer - 2 > CurTime()) then
		return false
	end
end)

hook.Add("HG_OnOtrub", "adsadsadhuy!!", function(ply)	
	if ply == LocalPlayer() then
		lply:SetDSP(17)
		plyCommand(lply,"soundfade 100 99999")
	end
end)

hook.Add("Player_Death", "adsadsadhuy!!", function(ply)	
	if ply == LocalPlayer() then
		lply:SetDSP(17)
		plyCommand(lply,"soundfade 100 99999")
	end
end)

local alivestart = CurTime()
hg.screens = hg.screens or {}
local screens = hg.screens
local screened = 0
local curscreen = 1
local switch = false
local file_Delete = file.Delete
hg.alivecntr = hg.alivecntr or 0

local function remove_imgs()
	if file.Exists("dreams", "DATA") then
		local files, _ = file.Find("dreams/*", "DATA")

		for i, file in pairs(files) do
			file_Delete("dreams/"..file)
		end
	end
end

local disorientationLerp = 0

hook.Add("Player Spawn", "screenshot_game", function(ply)
	if OverrideSpawn then return end

	if ply == lply then
		disorientationLerp = 0

		alivestart = CurTime()
		lply.tried_fixing_limb = nil

		hg.alivecntr = hg.alivecntr + 1

		for i, screen in ipairs(hg.screens) do
			hg.screens[i] = nil
		end

		remove_imgs()
	end
end)

hook.Add("InitPostEntity", "removeshits", function()
	remove_imgs()
end)

hook.Add("Player Disconnected", "removeshits", function()
	remove_imgs()
end)

hook.Add("radialOptions", "DislocatedJoint", function()
    if !lply:Alive() or !lply.organism or lply.organism.otrub then return end
	if (lply.tried_fixing_limb or 0) > CurTime() then return end
	local org = lply.organism
	if org.pain > 60 then return end
    
    if org.llegdislocation or org.rlegdislocation then
        local tbl = {
            function()
				lply.tried_fixing_limb = CurTime() + 0.5
				RunConsoleCommand("hg_fixdislocation", 1, 0)
            end,
            "Fix dislocation (leg)"
        }
        hg.radialOptions[#hg.radialOptions + 1] = tbl
	else
		local ent = hg.eyeTrace(lply).Entity

		if ent.organism and (ent.organism.llegdislocation or ent.organism.rlegdislocation) then
			local tbl = {
				function()
					lply.tried_fixing_limb = CurTime() + 0.5
					RunConsoleCommand("hg_fixdislocation", 1, 1)
				end,
				"Fix "..ent:GetPlayerName().."'s dislocation (leg)"
			}
			hg.radialOptions[#hg.radialOptions + 1] = tbl
		end
    end
end)

hook.Add("radialOptions", "DislocatedJoint2", function()
    if !lply:Alive() or !lply.organism or lply.organism.otrub then return end
	if (lply.tried_fixing_limb or 0) > CurTime() then return end
	local org = lply.organism
	if org.pain > 60 then return end
	
    if org.larmdislocation or org.rarmdislocation then
        local tbl = {
            function()
				lply.tried_fixing_limb = CurTime() + 0.5
				RunConsoleCommand("hg_fixdislocation", 2, 0)
            end,
            "Fix dislocation (arm)"
        }
        hg.radialOptions[#hg.radialOptions + 1] = tbl
	else
		local ent = hg.eyeTrace(lply).Entity

		if ent.organism and (ent.organism.larmdislocation or ent.organism.rarmdislocation) then
			local tbl = {
				function()
					lply.tried_fixing_limb = CurTime() + 0.5
					RunConsoleCommand("hg_fixdislocation", 2, 1)
				end,
				"Fix "..ent:GetPlayerName().."'s dislocation (arm)"
			}
			hg.radialOptions[#hg.radialOptions + 1] = tbl
		end
    end
end)

hook.Add("radialOptions", "DislocatedJaw", function()
    if !lply:Alive() or !lply.organism or lply.organism.otrub then return end
	if (lply.tried_fixing_limb or 0) > CurTime() then return end
	local org = lply.organism
	if org.pain > 60 then return end
	
    if org.jawdislocation then
        local tbl = {
            function()
				lply.tried_fixing_limb = CurTime() + 0.5
				RunConsoleCommand("hg_fixdislocation", 3, 0)
            end,
            "Fix dislocation (jaw)"
        }
        hg.radialOptions[#hg.radialOptions + 1] = tbl
	else
		local ent = hg.eyeTrace(lply).Entity

		if ent.organism and ent.organism.jawdislocation then
			local tbl = {
				function()
					lply.tried_fixing_limb = CurTime() + 0.5
					RunConsoleCommand("hg_fixdislocation", 3, 1)
				end,
				"Fix "..ent:GetPlayerName().."'s dislocation (jaw)"
			}
			hg.radialOptions[#hg.radialOptions + 1] = tbl
		end
    end
end)

hook.Add("PostRender", "screenshot_think", function()
	local org = lply.organism
	
	if not org or not org.brain or org.otrub or !lply:Alive() then return end
	
	local part = CurTime() - alivestart
	//print(part)
	if part % 60 > 59 and (screened != math.Round(part / 60, 0)) then
		screened = math.Round(part / 60, 0)
		//gui.HideGameUI()

		if gui.IsGameUIVisible() or gui.IsConsoleVisible() or IsValid(vgui.GetHoveredPanel()) then return end

		local data = render.Capture( {
			format = "jpeg",
			x = 0,
			y = 0,
			w = ScrW(),
			h = ScrH(),
			quality = 1,
			//alpha = false
		} )

		if not data then return end

		local name = "dreams/dream"..hg.alivecntr.."_"..(#screens + 1)..".jpeg"
		
		if not file.Exists("dreams", "DATA") then file.CreateDir("dreams") end
		file.Write(name, data)
		
		timer.Simple(1, function()
			screens[#screens + 1] = Material("data/"..name)
		end)
	end
end)

local braindeathstart = CurTime() + 20
local lerpedpart = 0
local lerpedbrain = 0

local brainFlashStart = 0
local brainFlashDur = 0
local brainFlashIdx = 1
local brainFlashPause = 0

hook.Add("Post Post Pre Post Processing", "ShowScreens", function()
	local org = lply.organism
	
	if !lply:Alive() then return end
	if not org or not org.brain then return end

	local part = CurTime() - braindeathstart

	local show_multiki = org.brain > 0.1 and org.otrub

	if show_multiki then
		lerpedbrain = LerpFT(0.05, lerpedbrain, org.brain)
		local time = 40 - (lerpedbrain - 0.1) * 20
		if part % time > time / 3 and curscreen <= #screens and screens[curscreen] and !screens[curscreen]:IsError() then
			switch = true
			local part2 = math.ease.InOutSine(math.sin(((part % time) - time / 3) / (time / 3 * 2) * math.pi))
			lerpedpart = LerpFT(0.1, lerpedpart, part2)
			
			surface.SetDrawColor(255, 255, 255, math.Clamp(lerpedpart * 50, 0, 255))
			surface.SetMaterial(screens[curscreen])
			surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
			
			DrawToyTown(4, ScrH())
		else
			if switch then
				curscreen = curscreen == #screens and 1 or curscreen + 1
				switch = false
			end
		end
	elseif org.brain >= 0.2 and not org.otrub then
		-- Лоботомия без отруба: вспышки скринов, 20% прозрачность
		local now = CurTime()

		-- если screens пустой — пробуем загрузить из файлов
		if #screens == 0 then
			local files = file.Find("dreams/*.jpeg", "DATA")
			if files and #files > 0 then
				for _, f in ipairs(files) do
					local mat = Material("data/dreams/" .. f)
					if mat and not mat:IsError() then
						screens[#screens + 1] = mat
					end
				end
			end
		end

		print("[brain flash] brain="..org.brain.." screens="..#screens.." pause="..brainFlashPause.." now="..now)


		local scr = screens[brainFlashIdx]
		if not scr or scr:IsError() then
			print("[brain flash] scr invalid!")
			brainFlashStart = 0
			return
		end
	end
end)

local blindoverlay = Material("zcity/neurotrauma/blindoverlay.png")

local hg_potatopc
local old = false
local tinnitusSoundFactor
local hg_gopro = ConVarExists("hg_gopro") and GetConVar("hg_gopro") or CreateClientConVar("hg_gopro", "0", true, false, "Toggle GoPro-like first-person camera view", 0, 1)
hook.Add("Post Post Pre Post Processing", "organism-effects", function()
	local spect = IsValid(lply:GetNWEntity("spect")) and lply:GetNWEntity("spect")
	local organism = lply:Alive() and lply.organism or (viewmode == 1 and IsValid(spect) and spect.organism) or {}
	local new_organism = lply:Alive() and lply.new_organism or (viewmode == 1 and IsValid(spect) and spect.new_organism) or {}

	//hg.DrawAffliction(0, 0, 100, 100, 1, "pale")

	if organism.owner == LocalPlayer() then
		if new_organism.otrub and !old then
			hook.Run("HG_OnOtrub", new_organism.owner)
		end
		
		old = new_organism.otrub
	end

	--LerpVariables(FrameTime(),organism,new_organism)

	if not organism then return end
	local alive = lply:Alive() or (spect and spect:Alive())

	local health = (lply:Alive() and lply:Health()) or 100

	if not alive or follow then end

	local org = organism
	
	if not org.brain then return end
	
	local adrenaline = org.adrenaline or 0
	local pulse = org.pulse or 70
	local pain = org.pain or 0
	local hurt = org.hurt or 0
	local blood = org.blood or 5000
	local bleed = org.bleed or 0
	local o2 = org.o2 and org.o2[1] or 30
	local brain = org.brain or 0
	local otrub = lply:Alive() and org.otrub or false
	local analgesia = organism.analgesia or 0
	local health = health
	local disorientation = org.disorientation or 0
	local immobilization = org.immobilization or 0
	local incapacitated = org.incapacitated or false
	local critical = org.critical or false
	tinnitusSoundFactor = Lerp(FrameTime()*2.5,tinnitusSoundFactor or 0, math.min(math.max( lply.tinnitus and (lply.tinnitus - CurTime()) or 0, 0)*7.5,120))
	local tinnitusSoundFactor2 = tinnitusSoundFactor + (hook.Run("ModifyTinnitusFactor", tinnitusSoundFactor) or 0)

	--print(lply.tinnitus)
	local adrenK = math.min(math.max(1 + adrenaline, 1), 1.2)

	if org.otrub then
		//DrawMotionBlur(0.1, 1., 0.1)
		//lply:ScreenFade( SCREENFADE.IN, clr_black2, 2, 0.5 )
	end
	
	--maybe 56, 30?
	local normaldsp = hg_gopro:GetBool() and 55 or 0
	lply:SetDSP(normaldsp)

	if otrub or ((fakeTimer and fakeTimer - 2 > CurTime()) and GetConVar("hg_deathfadeout"):GetBool()) then
		--if otrub or (fakeTimer and fakeTimer - 2 > CurTime()) then
		clr_black1.a = math.Clamp(pain / 50 * 255, 250, 255)
		//lply:ScreenFade( SCREENFADE.IN, clr_black2, 2, 0.5 )
		--lply:ScreenFade( SCREENFADE.IN, Color(0,0,0,255), 2, 0.5 )
		
		if isnumber(zb.ROUND_STATE) and (zb.ROUND_STATE ~= 1) then
			lply:SetDSP(normaldsp)
			plyCommand(lply,"soundfade "..tinnitusSoundFactor2.." 25")
		elseif lply:Alive() then
			lply:SetDSP(17)
			plyCommand(lply,"soundfade 100 25")
		end
	else
		plyCommand(lply,"soundfade "..tinnitusSoundFactor2.." 25")

		if ((disorientation and disorientation > 3) or (brain and brain > 0.2) or lply.PlayerClassName == "headcrabzombie" or lply:GetNetVar("headcrab")) and lply:Alive() then
			lply:SetDSP(130)
		else
			lply:SetDSP((lply.suiciding and lply:Alive()) and 130 or normaldsp)
		end
	end

	if not alive then
		return false
	end
	
	k1 = Lerp(FrameTime() * 15, k1 or 0, math.min(math.min(adrenaline / 1, 2),1.5))
	-- при хедкрабе исключаем consciousness из затемнения (хедкраб сам ставит низкий consciousness)
	local consciousnessForK2 = hasHeadcrabEffect and 1 or (consciousnessLerp or 1)
	k2 = (30 - (o2 or 30)) / 30 + (1 - consciousnessForK2) * 1-- + brain * 2
	k3 = ((5000 / math.max(blood, 1000)) - 1) * 1.5

	DrawSharpen(k1 * 2, k1 * 1)
	local lowpulse = math.max((70 - pulse) / 70, 0) + math.max(3000 * ((math.cos(CurTime()/2) + 1) / 2 * 0.1 + 1) - (blood * adrenK - 300),0) / 400

	if (lply.PlayerClassName == "headcrabzombie" or lply:GetNetVar("headcrab")) and lply:Alive() then
		disorientation = disorientation + 100
	end

	disorientation = disorientation + amtflashed * 5

	local amount = 1 - math.Clamp(lowpulse + disorientation / 4 + k2 * 2,0,1)

	disorientationLerp = LerpFT(disorientation > disorientationLerp and 1 or 0.01, disorientationLerp, math.max(lply.suiciding and 1.5 or 0, disorientation))

	if (disorientationLerp > 1) and lply:Alive() or brain > 0 then
		local add2 = disorientationLerp - 1
		if not brain_motionblur and lply.PlayerClassName ~= "headcrabzombie" then DrawMotionBlur(0.15 - math.Clamp(add2 / 1, 0, 0.1), add2 * 2, 0.001) end
		if disorientationLerp > 2 then
			local add = (disorientationLerp - 2) * 2
			local time = CurTime() * 3
			local mul = math.Clamp(add / 16, 0, 0.2)

			ang1[1] = math.cos(time) + math.sin(time * 0.5) + math.sin((time - 5) * 1.1)
			ang1[2] = math.sin(time) + math.cos(time * 0.5) + math.sin((time + 1) * 1.1)
			ViewPunch(ang1 * mul * 0.125)
			//ViewPunch2(ang1 * mul * 1 * 0.25)

			//local ang = lply:EyeAngles()
			//lply:SetEyeAngles(ang - ang1 * 0.01)

			ang2[3] = math.Rand(-15,15) * mul
			//SetViewPunchAngles(ang2)
			//ViewPunch(ang1 * mul * 1)
		end
	end


	//pain = math.abs(math.cos(CurTime())) * 40
	if (pain > 0) or (hurt > 0) or (immobilization > 0) or (brain > 0) then
		local k = ((hurt + immobilization / 15) / 2)
		--DrawToyTown(1, k * ScrH())
		local newpain = pain - 10
		if newpain > 0 then
			//surface.SetDrawColor(0, 0, 0, (newpain / 20) * 255 - math.ease.InOutCirc(math.abs(math.cos(CurTime()))) * 50)
			//surface.SetMaterial(pain_mat)
			//surface.DrawTexturedRect(-1, -1, ScrW()+1, ScrH()+1)
			local blur = math.max((newpain / 30 + brain * 10),0) / 30
			if blur > 0 then
				DrawMaterialOverlay( "sprites/mat_jack_hmcd_scope_aberration", blur )
			end
		end
	end
	hg_potatopc = hg_potatopc or hg.ConVars.potatopc
	local potato = hg_potatopc:GetBool()
	local hasHeadcrabEffect = lply:GetNetVar("headcrab") and lply.PlayerClassName ~= "headcrabzombie" and lply:Alive()
	local brainForEffect = hasHeadcrabEffect and 0 or brain

	if (k1 > 0) or (k2 > 0) or (k3 > 0) or brainForEffect > 0 then
		if !potato then
			DrawToyTown(2, (k3 * 3 + k2 * 1 + brainForEffect * 10) * ScrH() / 2)
			-- Розовый оверлей поверх пикселизации при sadsalat
			if (lply._saladPinkTint or 0) > 0.01 and ((k2 > 0.1) or (brainForEffect > 0.05)) then
				local pt = lply._saladPinkTint
				local intensity = math.Clamp((k2 + brainForEffect) * pt, 0, 1)
				surface.SetDrawColor(255, 80, 200, math.floor(intensity * 60))
				surface.DrawRect(0, 0, ScrW(), ScrH())
			end
		end
	end

	-- Эффект хедкраба: аберрация как при боли + красный тинт, нарастает 30 сек
	do
		local hasHeadcrab = hasHeadcrabEffect

		if hasHeadcrab and not lply._hcStartTime then
			lply._hcStartTime = CurTime()
		elseif not hasHeadcrab then
			lply._hcStartTime = nil
		end

		if lply._hcStartTime and hasHeadcrab then
			local elapsed = CurTime() - lply._hcStartTime
			local eatProgress = math.Clamp(elapsed / 30, 0, 1)

			if eatProgress > 0 and hg.DrawHeadcrabGrain then
				hg.DrawHeadcrabGrain(eatProgress)

				-- сильное волнистое искажение zb_heat: максимум 57 сек, потом за 3 сек исчезает
				local heatM = Material("effects/shaders/zb_heat")
				local t = CurTime()
				
				-- Вычисляем интенсивность: 1.0 до 57 сек, потом плавно до 0 за последние 3 секунды
				local grainIntensity = 1.0
				if elapsed >= 57 then
					-- За последние 3 секунды (57-60) уменьшаем с 1 до 0
					grainIntensity = math.Clamp(1 - (elapsed - 57) / 3, 0, 1)
				end
				
				render.UpdateScreenEffectTexture()
				heatM:SetFloat("$c0_x", -t * 0.3)
				heatM:SetFloat("$c0_y", grainIntensity * 0.5)
				heatM:SetFloat("$c2_x", (math.sin(t * 0.7) - 2) * grainIntensity * 5)
				render.SetMaterial(heatM)
				render.DrawScreenQuad()
			end
		end
	end

	--DrawMaterialOverlay( "homigrad/vgui/bloodblur.png", 0)
	local view = render.GetViewSetup()
	--RenderSuperDoF(view.origin,view.angles,0)
	if analgesia > 1 then
		DrawMaterialOverlay( "particle/warp4_warp_noz", -(analgesia - 0.5) * math.sin(CurTime()) * 5 / 150 )
	end

	/*

	local amt = (math.cos(addtime) + math.sin(addtime * 3) + math.sin(addtime * 2)) / 90
	local amt2 = (math.sin(addtime) + math.cos(addtime * 5) + math.sin(addtime * 6)) / 90
	surface.SetDrawColor(255,255,255,math.abs(amt * 255 * 30))
	surface.SetMaterial(blindoverlay)

	local mat = Matrix({
		{1 - amt, amt, 0, -amt2 / 2},
		{amt2, 1 - amt2, 0, -amt / 2},
		{0, 0, 1, 0},
		{0, 0, 0, 1},
	})
	blindoverlay:SetMatrix("$basetexturetransform", mat)
	surface.DrawTexturedRect(0, 0, ScrW(), ScrH())

	*/

	tabblood["$pp_colour_colour"] = Lerp(FrameTime() * 30, tabblood["$pp_colour_colour"], (blood / 5000) * (potato and (blood / 5000) or 1) + (math.max(org.analgesia - 1, 0) * math.sin(CurTime()) * 5))
	tabblood["$pp_colour_brightness"] = Lerp(FrameTime() * 30, tabblood["$pp_colour_brightness"], (potato and (blood / 5000 - 1) / 2 or 0) )
	tabblood["$pp_colour_addb"] = !org.otrub and ((potato and k2 / 5 or 0)) or 0
	-- при горении убираем синюю виньетку
	local fireEnt2 = IsValid(lply.FakeRagdoll) and lply.FakeRagdoll or lply
	if IsValid(fireEnt2) and fireEnt2:IsOnFire() then
		tabblood["$pp_colour_addb"] = 0
	end

	-- Считаем розовый тинт для пикселей
	local hasSaladWep = false
	for _, wep in ipairs(lply:GetWeapons()) do
		if IsValid(wep) and wep:GetClass() == "weapon_sadsalat" then
			hasSaladWep = true
			break
		end
	end
	lply._saladPinkTint = LerpFT(0.05, lply._saladPinkTint or 0, hasSaladWep and 1 or 0)

	DrawColorModify(tabblood)

	local ent = IsValid(lply.FakeRagdoll) and lply.FakeRagdoll or lply

	if otrub then
		--[[render.PushFilterMag( TEXFILTER.ANISOTROPIC )
		render.PushFilterMin( TEXFILTER.ANISOTROPIC )

		local textOtrub = "You are unconscious. "
		local textOtrub2 =  
			( critical and "You can't be saved." ) or 
			( incapacitated and "You will not get up without someone's help." ) or 
			( 
				"You will probably wake up in "
				..( 	
					( pain < 50 and "about a minute." ) or 
					( pain < 100 and "about two minutes." ) or 
					"a few minutes."
				) 
			)

		local parsed = markup.Parse( 
			"<font=HomigradFontMedium>"..
			( critical and "You're criticaly injured." or textOtrub )..
			"\n<colour=255,"..( critical and 25 or 255 )..","..( critical and 25 or 255 ) ..",255>"..
			( textOtrub2 ).."</colour></font>" 
		)
		--((critical and "You can not be saved.") or 
		--(incapacitated and "You will not get up without someone's help.") or 
		--( "You will probably wake up in " .. (pain < 50 and "about a minute.") ) or 
		--((pain < 100 and "about two minutes.") or "a few minutes.")) -- WTF???
		
		--surface.SetTextColor(255,255,255,255)
		--surface.SetFont("HomigradFontMedium")
		--local txtSizeX, txtSizeY = surface.GetTextSize(textOtrub)
		--surface.SetTextPos(ScrW()/2 - (txtSizeX/2),ScrH()/1.1 - (txtSizeY/2))
		--surface.DrawText(textOtrub)

		parsed:Draw( ScrW()/2, ScrH()/1.1, TEXT_ALIGN_CENTER, nil, nil, TEXT_ALIGN_CENTER )
		
		render.PopFilterMag()
		render.PopFilterMin()--]]
	end
	
	if IsValid(ent) and ent.Blinking and lply:Alive() then
		surface.SetDrawColor(0,0,0,255)
		if amtflashed and amtflashed > 0.1 and amtflashed < 0.8 and ent.Blinking > 0.1 then
			surface.DrawRect(-1, -1,ScrW() + 1,ScrH() + 1)
			//surface.DrawRect(-1,-1,ScrW()+1,ent.Blinking * ScrH())
			//surface.DrawRect(-1,ScrH() + 1,ScrW()+1,-ent.Blinking * ScrH())
		end
	end
end)

hook.Add("OnNetVarSet","wounds_netvar",function(index, key, var)
	if key == "wounds" then
		local ent = Entity(index)
		--local ent = hg.RagdollOwner(ent) or ent
		
		if IsValid(ent) then
			if ent.wounds then
				for i = 1, #ent.wounds do
					if !var or !var[i] then continue end
					var[i][5] = ent.wounds[i][5]
				end
			end

			ent.wounds = var
			--PrintTable(ent.wounds)
			local rag = IsValid(ent:GetNWEntity("FakeRagdoll")) and ent:GetNWEntity("FakeRagdoll")-- or IsValid(ent:GetNWEntity("RagdollDeath")) and ent:GetNWEntity("RagdollDeath")
			if IsValid(rag) then
				rag.wounds = rag:GetNetVar("wounds") or var
			end
		end
	end
end)

hook.Add("OnNetVarSet","wounds_netvar2",function(index, key, var)
	if key == "arterialwounds" then
		local ent = Entity(index)
		--local ent = hg.RagdollOwner(ent) or ent
		
		if IsValid(ent) then
			if ent.arterialwounds then
				for i = 1, #ent.arterialwounds do
					if not var[i] then continue end
					var[i][5] = ent.arterialwounds[i][5]
				end
			end

			ent.arterialwounds = var
			local rag = IsValid(ent:GetNWEntity("FakeRagdoll")) and ent:GetNWEntity("FakeRagdoll")-- or IsValid(ent:GetNWEntity("RagdollDeath")) and ent:GetNWEntity("RagdollDeath")
			
			if IsValid(rag) then
				rag.arterialwounds = rag:GetNetVar("arterialwounds") or var
			end
		end
	end
end)

hook.Add("Player Spawn", "removewounds", function(ply)
	if OverrideSpawn then return end

	ply.wounds = {}
	ply.arterialwounds = {}
end)

hook.Add("Fake", "huyhuyhuy235", function(ply,ragdoll)
	if not IsValid(ragdoll) then return end

	ragdoll.wounds = ply.wounds
	ragdoll.arterialwounds = ply.arterialwounds
end)

function hg.applyFountain(pos, ang, mul, mul2, forward, ent)
	if bit.band(util.PointContents(pos), CONTENTS_WATER) == CONTENTS_WATER then
		if math.random(2) == 1 then return end
		hg.addBloodPart2(pos, ang:Forward() * forward * 0.5 + VectorRand(-25,25) * mul2, nil, nil, nil, nil, true, nil, ent)
		hg.addBloodPart2(pos + VectorRand(-1,1), ang:Forward() * forward * 0.25 + VectorRand(-10,10) * mul2, nil, nil, nil, nil, true, nil, ent)
		//hg.addBloodPart2(pos + VectorRand(-1,1), ang:Forward() * forward * 0.25 + VectorRand(-10,10) * mul2, nil, nil, nil, nil, true, nil, ent)
	else
		hg.addBloodPart(pos, ang:Forward() * forward * 2 * math.abs(math.sin(CurTime() * 3) + math.cos(CurTime() * 5) + math.sin(CurTime() * 2) + 4) * 0.1 + ang:Right() * 15 * (math.sin(CurTime()) * 1) + ang:Right() * math.sin(CurTime() * 2) * 15 + VectorRand(-3, 3),nil,nil,nil,true)
		hg.addBloodPart(pos + VectorRand(-1,1), ang:Forward() * 55 + VectorRand(-25,25) * mul2,nil,nil,nil,nil, nil, ent)
		//hg.addBloodPart(pos + VectorRand(-1,1), ang:Forward() * 55 + VectorRand(-25,25) * mul2,nil,nil,nil,nil, nil, ent)
	end
end

local hg_old_blood = ConVarExists("hg_old_blood") and GetConVar("hg_old_blood") or CreateClientConVar("hg_old_blood", 0, true, false, "new decals, or old", 0, 1)
local vecTorso = Vector(1, 1, 1)
local checkpulsebones = {
	["ValveBiped.Bip01_Head1"] = true,
	["ValveBiped.Bip01_R_Hand"] = true,
	["ValveBiped.Bip01_L_Hand"] = true,
}
local hg_blood_fps = ConVarExists("hg_blood_fps") and GetConVar("hg_blood_fps") or CreateClientConVar("hg_blood_fps", 24, true, nil, "fps to draw blood", 12, 165)

local pitchAddClasses = {
	["furry"] = 20,
	["headcrabzombie"] = -60
}
local muffedClasses = {
	["headcrabzombie"] = true
}

local hg_heartbeat_volume = ConVarExists("hg_heartbeat_volume") and GetConVar("hg_heartbeat_volume") or CreateClientConVar("hg_heartbeat_volume", 1, true, nil, "heartbeat loudness", 0, 4)

hook.Add("Player-Ragdoll think", "organism-think-client-blood", function(ply, ent, time)
	--local ent = IsValid(ply.FakeRagdoll) and ply.FakeRagdoll or ply
	--print(ply,ent,ply.organism.owner,ply.new_organism.owner)
	local organism = ply.organism
	local new_organism = ply.new_organism
	
	local seen = ent.shouldTransmit-- and not ent.NotSeen
	local wounds = ply.wounds
	local arterialwounds = ply.arterialwounds

	local org = ent.organism

	if !org then return end

	if org and org.pulse and org.o2 and org.o2[1] then
		local pulse = org.heartbeat
		org.pulsethink = org.pulsethink or 0
		local speed = math.Clamp(org.heartbeat / 60, 1, 3.3) * 0.5 * (org.o2[1] < 8 and 0 or 1)
		org.pulsethink = org.pulsethink + (org.heartbeat > 1 and 1 or 0) * (org.holdingbreath and 0 or 1) * FrameTime() * 5.6 * (speed) * (org.lungsfunction and 1 or 0) * ((org.alive and !ent.headexploded) and 1 or 0)
		
		local torso = ent:LookupBone("ValveBiped.Bip01_Spine2")
		--local chest = ent:LookupBone("ValveBiped.Bip01_Spine1")
		
		if torso then
			if ent:GetPos():DistToSqr(lply:GetPos()) > 450 * 450 then return end
			local sin = (math.sin(org.pulsethink) + 1) * 0.5
			local amt = 0.05 * sin * math.max(org.pulse / 70, 0.5)
			
			local size = 1 + amt
			vecTorso[1] = size
			vecTorso[2] = size
			vecTorso[3] = size
			
			ent:ManipulateBoneScale(torso, vecTorso)
			//ent:ManipulateBoneAngles(torso, Angle(0, amt, 0))

			vecTorso[1] = 0
			vecTorso[2] = amt * 2
			vecTorso[3] = 0
			
			if sin < 0.1 and org.analgesia <= 1.5 and not org.breathed then
				org.lastbreathed = CurTime()
				org.breathed = true
				local heartbeat = org.heartbeat or 0
				local muffed
				local pitch = math.Clamp(heartbeat / 200 * 100, 100, 100) * math.Clamp((org.stamina and org.stamina[1] and (1 + (1 - org.stamina[1] / org.stamina.max) * 0.2) or 1), 1, 1.2)
				local vol = math.Remap(heartbeat, 70, 300, 0, 0.25) + (org.stamina and org.stamina[1] and 1 - org.stamina[1] / org.stamina.max or 0)

				if ent.armors then
					muffed = ent.armors["face"] == "mask2" or ent.PlayerClassName == "Combine"
				end

				if ply.PlayerClassName and muffedClasses[ply.PlayerClassName] then
					muffed = muffedClasses[ply.PlayerClassName]
				end

				local pitchadd = 0
				if ply.PlayerClassName and pitchAddClasses[ply.PlayerClassName] then
					pitchadd = pitchAddClasses[ply.PlayerClassName]
				end

				if vol > 1.5 and ply == lply then
					local amta = (vol - 1.5)
					local ang1 = Angle(amta * -0.5, 0, 0)
					local ang2 = Angle(amta * 5, 0, 0)

					--[[ViewPunch4(ang1)
					--ViewPunch(ang1)

					timer.Simple(speed, function()
						ViewPunch4(-ang1)
						--ViewPunch(-ang2)
					end)--]]

				end

				ply:EmitSound("snds_jack_hmcd_breathing/" .. (ThatPlyIsFemale(ent) and "f" or "m") .. math.random(4) .. ".wav", min(heartbeat * 1.0 / ( muffed and 2.5 or 4), 45), pitch + pitchadd + math.Rand(-2, 2), vol, CHAN_AUTO, 0, muffed and 16 or 0)
			elseif org.breathed and sin >= 0.1 then
				org.breathed = false
			end

			--ent:ManipulateBonePosition(torso, vecTorso)

			--local size = 1 - 0.02 * math.sin(org.pulsethink)
			--vecTorso[1] = size
			--vecTorso[2] = size
			--vecTorso[3] = size

			--ent:ManipulateBoneScale(chest, vecTorso)
		end
	end

	ply.pulse_breathe = ply.pulse_breathe or {}
	ent.pulse_breathe = ply.pulse_breathe
	
	hg.LerpVariables(FrameTime() * 10, organism, new_organism)
	
	local org = ent.organism or {}
	local owner = ent
	
	local beatsPerSecond = math.max(min(30 / math.max(org.pulse or 70,2), 4), 0.1) * (!hg_old_blood:GetBool() and 0.3 or 1)
	
	if org.pulse and org.heartbeat > 30 and (org.lastpulse or 0) + (1 / math.Clamp(org.heartbeat, 1, 600)) * 60 < CurTime() then
		org.lastpulse = CurTime()
		local pulse = org.heartbeat or 0
		local pain = org.pain or 0
		
		local dist = owner:GetPos():DistToSqr(lply:GetPos())
		local carryent = lply:GetNetVar("carryent")
		local carrybone = lply:GetNetVar("carrybone")
		local cantcheck = org.CantCheckPulse
		local checkingplayer = (IsValid(carryent) and carryent.organism == ply.organism and !cantcheck and checkpulsebones[carryent:GetBoneName(carryent:TranslateBoneToPhysBone(carrybone))])
		
		if dist < 64 * 64 and ((ply == lply and !checkingplayer) or checkingplayer) then
			local vol = checkingplayer and 2 or ((pain > 60 and ply == lply) and 1 or (pulse > 200 and ((200 - 95) / 50 + 0.12 - (pulse - 200) / 1000) or pulse > 95 and (pulse - 95) / 50 + 0.12 or 0.12))
			if not checkingplayer then
				vol = math.Clamp(vol, 0, 0.7) * hg_heartbeat_volume:GetFloat()
			end

			--ply:EmitSound("heartbeat/heartbeat_single.wav", 55, 60, vol)
			if ent:GetVelocity():LengthSqr() < 10 then
				sound.Play("heartbeat/heartbeat_single.wav", ply:EyePos(), 55, 60, vol * 1.5)
			else
				EmitSound("heartbeat/heartbeat_single.wav", ply:EyePos(), ply:EntIndex(), CHAN_AUTO, vol, 55, nil, 60)
			end
		end
	end

	--why? because
	if org.pulse and (ent.pulse_breathe.lastbreathe or 0) < CurTime() and org.lastbreathed and org.lastbreathed + 5 < CurTime() then
		local heartbeat = org.heartbeat or 0
		ent.pulse_breathe.lastbreathe = CurTime() + (1 / math.Clamp(org.heartbeat + (org.o2[1] - 30) * 1, 1, 120)) * 90 + ( org.o2[1] < 20 and 5 or 0)
		
		if org.analgesia <= 1.5 and org.heartbeat > 1 then
			if (ent:WaterLevel() < 3) then
				local muffed

				if ent.armors then
					muffed = ent.armors["face"] == "mask2" or ent.PlayerClassName == "Combine"
				end
				
				if org.timeValue and org.o2.curregen <= org.timeValue * 0.5 and org.o2[1] < 20 then
					ply:EmitSound("zcitysnd/real_sonar/"..(ThatPlyIsFemale(ent) and "fe" or "").."male_wheeze"..math.random(5)..".mp3", 40, nil, nil, nil, nil, 1)
				end
			else
				if org.o2[1] < 15 then
					ply:EmitSound("zcitysnd/real_sonar/"..(ThatPlyIsFemale(ent) and "fe" or "").."male_drown"..math.random(5)..".mp3", 60)
				end
			end
		end
	end

	local fountains = GetNetVar("fountains")
	if fountains and fountains[ent] then
		local tbl = fountains[ent]
		if (tbl.time or 0) < CurTime() and org.pulse then
			local mul = 1 / math.max(org.pulse / 40 * 25, 2) * 0.75
			local mul2 = math.max(org.pulse, 1) / 15
			local forward = mul2 * 150
			tbl.time = CurTime() + mul * 0.5
			
			if seen then
				local mat = ent:GetBoneMatrix(tbl.bone)

				if mat then
					local pos, ang = LocalToWorld(tbl.lpos, tbl.lang, mat:GetTranslation(), mat:GetAngles())
					
					hg.applyFountain(pos, ang, mul, mul2, forward, ent)
				end
			else
				local pos, ang = ent:GetPos(), angle_zero
				hg.applyFountain(pos, ang, mul, mul2, forward, ent)
			end
		end
	end
	
	if org and org.blood and org.blood > 10 and wounds and #wounds > 0 then
		if (owner:IsPlayer() and owner:Alive()) or not owner:IsPlayer() then
			for i, wound in pairs(wounds) do
				local size = math.random(0, 1) * math.max(math.min(wound[1], 1), 0.5)
				
				if wound[5] + beatsPerSecond < time then
					if seen and ent:LookupBone(wound[4]) then
						local bone = wound[4]
						local should = !(hg.amputatedlimbs2[bone] and org[hg.amputatedlimbs2[bone].."amputated"])

						if !should then continue end

						local mat = ent:GetBoneMatrix(ent:LookupBone(bone))
						if not mat then return end
						local bonePos, boneAng = mat:GetTranslation(), mat:GetAngles()
						if not wound[2] or not wound[3] or not bonePos or not boneAng then return end
						local pos, ang = LocalToWorld(wound[2], wound[3], bonePos, boneAng)

						local water = bit.band(util.PointContents(pos), CONTENTS_WATER) == CONTENTS_WATER
						if water then
							if wound[5] + 1 < time then
								hg.addBloodPart2(pos, VectorRand(-5, 5), nil, nil, nil, nil, true, nil, ent)
							end
						else
							hg.addBloodPart(pos, VectorRand(-15, 15), nil, size, size, false, nil, ent)
						end

						wound[5] = time + (water and 2 or (math.Rand(0, 1) * (!hg_old_blood:GetBool() and 0.5 or 1) / wound[1] * 15))
					else
						local pos = ent:GetPos()

						local water = bit.band(util.PointContents(pos), CONTENTS_WATER) == CONTENTS_WATER
						if water then
							hg.addBloodPart2(pos, VectorRand(-5, 5), nil, nil, nil, nil, true, nil, ent)
						else
							hg.addBloodPart(pos, VectorRand(-15, 15), nil, size, size, false, nil, ent)
						end

						wound[5] = time + (water and 2 or (math.Rand(0, 1) * (!hg_old_blood:GetBool() and 0.5 or 1) / wound[1] * 15))
					end
				end
			end
		end
	end
	
	if org and org.blood and org.blood > 10 and arterialwounds and #arterialwounds > 0 then
		for i, wound in pairs(arterialwounds) do
			local addtime = seen and 1 / math.Clamp(org.pulse or 70, 1,15) * 0.25 or 0.06
			if wound[5] + addtime < time and ent:LookupBone(wound[4]) then
				local pos, ang = ent:GetBonePosition(ent:LookupBone(wound[4]))
				if (owner:IsPlayer() and owner:Alive()) or not owner:IsPlayer() then
					local size = math.random(1, 2) * math.max(math.min(wound[1], 1), 0.5)
					if seen and ent:LookupBone(wound[4]) then
						local bone = wound[4]

						local should = !(hg.amputatedlimbs2[bone] and org[hg.amputatedlimbs2[bone].."amputated"])

						if !should then continue end
						
						local mat = ent:GetBoneMatrix(ent:LookupBone(bone))
						if not mat then return end
						local bonePos, boneAng = mat:GetTranslation(), mat:GetAngles()
						if not wound[2] or not wound[3] or not bonePos or not boneAng then return end
						local pos = LocalToWorld(wound[2], wound[3], bonePos, boneAng)

						local dir = wound[6]
						local len = dir:Length() * (org.pulse or 70) / 70
						local _, dir = LocalToWorld(vector_origin, dir:Angle(), vector_origin, ang)
						
						dir = -dir:Forward() * len

						local water = bit.band(util.PointContents(pos), CONTENTS_WATER) == CONTENTS_WATER
						if water then
							hg.addBloodPart2(pos, VectorRand(-5, 5), nil, nil, nil, nil, true, nil, ent)
						else
							hg.addBloodPart(pos, VectorRand(-1, 1) * (org.pulse or 70) / 70 + dir * 5 * (math.abs(math.sin(CurTime() * 2) + math.cos(CurTime() * (5 + i * 2)) + math.sin(CurTime() * (1 + i))) * 0.6 + math.sin(CurTime() * 2) + 4) * 0.1 + dir:Angle():Right() * 25 * math.sin(CurTime() * 2) * math.cos(CurTime() * 4) + ang:Up() * 25 * math.sin(CurTime() * 3) * math.cos(CurTime() * 1) + VectorRand(-1, 1) * (org.pulse or 70) / 70, nil, size, size, true, nil, ent)
						end

						wound[5] = time + (water and 2 or (0.5 * 1 / hg_blood_fps:GetInt()))
					else
						local pos = ent:GetPos()
						
						local water = bit.band(util.PointContents(pos), CONTENTS_WATER) == CONTENTS_WATER
						if water then
							hg.addBloodPart2(pos, VectorRand(-5, 5), nil, nil, nil, nil, true, nil, ent)
						else
							hg.addBloodPart(pos, VectorRand(-15, 15), nil, size, size, true, nil, ent)
						end

						wound[5] = time + (water and 2 or 0)
					end
				end
			end
		end
	end
end)

local grub = Model("models/grub_nugget_small.mdl")
local vecalmostzero = Vector(0.01, 0.01, 0.01)

local modelPlacements = {
	[1] = {
		["ValveBiped.Bip01_L_Calf"] = {Vector(15.5, 0, 0), Angle(0, 90, 0)},
		["ValveBiped.Bip01_R_Calf"] = {Vector(15.5, 0, 0), Angle(0, 90, 0)},
		["ValveBiped.Bip01_R_Forearm"] = {Vector(11, 0.5, 0.5), Angle(0, 90, 0)},
		["ValveBiped.Bip01_L_Forearm"] = {Vector(11, 0.5, -0.5), Angle(0, 90, 0)},
	},
	[0] = {
		["ValveBiped.Bip01_L_Calf"] = {Vector(17.5, 0, 0), Angle(0, 90, 0)},
		["ValveBiped.Bip01_R_Calf"] = {Vector(17.5, 0, 0), Angle(0, 90, 0)},
		["ValveBiped.Bip01_R_Forearm"] = {Vector(11, 0.5, 0.5), Angle(0, 90, 0)},
		["ValveBiped.Bip01_L_Forearm"] = {Vector(11, 0, -1), Angle(0, 90, 0)},
	}
}

local limbs = {
	["lleg"] = "ValveBiped.Bip01_L_Calf",
	["rleg"] = "ValveBiped.Bip01_R_Calf",
	["larm"] = "ValveBiped.Bip01_L_Forearm",
	["rarm"] = "ValveBiped.Bip01_R_Forearm",
	["head"] = "ValveBiped.Bip01_Head1"
}

function hg.amputatedbone(ent, bone)
	if ent.organism and hg.amputatedlimbs2[bone] then
		if ent.organism[hg.amputatedlimbs2[bone].."amputated"] then
			return true
		end
	end
end

hg.amputatedlimbs = limbs

hg.amputatedlimbs2 = {}
for k, v in pairs(limbs) do
	hg.amputatedlimbs2[v] = k
end

local vecFull = Vector(1, 1, 1)

function hg.GoreCalc(ent, ply)
	local org = ent.new_organism or ent.organism
	if !org then return end

	for bone, nam in pairs(limbs) do
		if !org[bone.."amputated"] then
			local bon = ent:LookupBone(nam)

			if !ent:GetManipulateBoneScale(bon):IsEqualTol(vecFull, 0.01) then
				ent:ManipulateBoneScale(bon, vecFull)
			end

			continue
		end
		
		local bon = ent:LookupBone(nam)
		local mat = ent:GetBoneMatrix(bon)
		local mat2 = ent:GetBoneMatrix(bon - 1)
		mat:SetScale(vecalmostzero)
		
		hg.bone_apply_matrix(ent, bon, mat)
		
		if IsValid(ply.OldFakeRagdoll) then
			hg.bone_apply_matrix(ply, bon, mat)
		end

		local fem = ThatPlyIsFemale(ent) and 1 or 0
		
		if !modelPlacements[fem][nam] then continue end

		local pos, ang = LocalToWorld(modelPlacements[fem][nam][1], modelPlacements[fem][nam][2], mat2:GetTranslation(), mat2:GetAngles())
		
		if !IsValid(headboom_mdl) then
			headboom_mdl = ClientsideModel(grub)
			headboom_mdl:SetNoDraw(true)
			headboom_mdl:SetSubMaterial(0, "models/flesh")
			headboom_mdl:SetModelScale(0.8)
		end
		
		headboom_mdl:SetRenderOrigin(pos)
		headboom_mdl:SetRenderAngles(ang)
		headboom_mdl:SetupBones()
		headboom_mdl:DrawModel()
	end
end

local prank = {}
local time_troll = 100

local DontCallMe = false
hook.Add("HG.InputMouseApply","zzzzzzzzzzzzbrain_death",function(tbl)
	 

	if lply:Alive() and lply.organism and (lply.organism.brain or 0) > 0.1 then
		if #prank < time_troll then table.insert(prank,1,{tbl.x,tbl.y}) end
		if #prank >= time_troll then table.remove(prank,#prank) end
		
		local amt = lply.organism.brain / 0.3

		local xa = Lerp(1 * amt,tbl.x,prank[#prank][1])// + math.sin(CurTime() / 5) * amt * 10
		local ya = Lerp(1 * amt,tbl.y,prank[#prank][2])// + math.cos(CurTime() / 5) * math.sin(CurTime() / 2) * amt * 10

		tbl.angle.pitch = math.Clamp(tbl.angle.pitch + tbl.y / 100 + ya / 100, -89, 89)
		tbl.angle.yaw = tbl.angle.yaw - tbl.x / 100 - xa / 100
		tbl.override_angle = true
	end

	--[[local actwep = LocalPlayer():GetActiveWeapon()
	if not actwep or not actwep.GetTrace then return end
	local hitpos,pos,ang = actwep:GetTrace()

	local ply = hg.GetCurrentCharacter(Entity(2))
	local dist = ply:EyePos():Distance(LocalPlayer():EyePos())
	ply:SetupBones()
	scr = ply:GetBoneMatrix(ply:LookupBone("ValveBiped.Bip01_Head1")):GetTranslation():ToScreen()

	angle.pitch = math.Clamp(angle.pitch + (scr.y - (pos+ang:Forward() * dist):ToScreen().y) / 50, -89, 89)
	angle.yaw = angle.yaw - (scr.x - (pos+ang:Forward() * dist):ToScreen().x) / 50
	cmd:SetViewAngles(angle)

	return true--]]
end)

local function OpenOrganismMenu()
	if not LocalPlayer():IsAdmin() then return end
	
	local frame = vgui.Create("DFrame")
	frame:SetSize(420, 750)
	frame:SetTitle("Organism Control")
	frame:Center()
	frame:MakePopup()
	
	local scroll = vgui.Create("DScrollPanel", frame)
	scroll:SetPos(5, 30)
	scroll:SetSize(410, 715)
	
	local y = 10
	
	for i, target in pairs(player.GetAll()) do
		if not IsValid(target) or not target:IsPlayer() then continue end
		
		local bg = vgui.Create("DPanel", scroll)
		bg:SetPos(5, y)
		bg:SetSize(400, 275)
		
		local name = vgui.Create("DLabel", bg)
		name:SetText(target:GetName())
		name:SetFont("DermaDefaultBold")
		name:SetTextColor(Color(255, 255, 255))
		name:SetPos(10, 8)
		name:SizeToContents()
		
local lblo2 = vgui.Create("DLabel", bg)
		lblo2:SetText("O2:")
		lblo2:SetPos(10, 30)
		lblo2:SizeToContents()
		
		local btn_o2_30 = vgui.Create("DButton", bg)
		btn_o2_30:SetText("30")
		btn_o2_30:SetPos(45, 28)
		btn_o2_30:SetSize(35, 18)
		btn_o2_30.DoClick = function() RunConsoleCommand("hg_org_menu_cmd", target:UserID(), "o2", 30) end
		
		local btn_o2_25 = vgui.Create("DButton", bg)
		btn_o2_25:SetText("25")
		btn_o2_25:SetPos(85, 28)
		btn_o2_25:SetSize(35, 18)
		btn_o2_25.DoClick = function() RunConsoleCommand("hg_org_menu_cmd", target:UserID(), "o2", 25) end
		
		local btn_o2_20 = vgui.Create("DButton", bg)
		btn_o2_20:SetText("20")
		btn_o2_20:SetPos(125, 28)
		btn_o2_20:SetSize(35, 18)
		btn_o2_20.DoClick = function() RunConsoleCommand("hg_org_menu_cmd", target:UserID(), "o2", 20) end
		
		local btn_o2_15 = vgui.Create("DButton", bg)
		btn_o2_15:SetText("15")
		btn_o2_15:SetPos(165, 28)
		btn_o2_15:SetSize(35, 18)
		btn_o2_15.DoClick = function() RunConsoleCommand("hg_org_menu_cmd", target:UserID(), "o2", 15) end
		
		local btn_o2_10 = vgui.Create("DButton", bg)
		btn_o2_10:SetText("10")
		btn_o2_10:SetPos(205, 28)
		btn_o2_10:SetSize(35, 18)
		btn_o2_10.DoClick = function() RunConsoleCommand("hg_org_menu_cmd", target:UserID(), "o2", 10) end
		
		local btn_o2_5 = vgui.Create("DButton", bg)
		btn_o2_5:SetText("5")
		btn_o2_5:SetPos(245, 28)
		btn_o2_5:SetSize(30, 18)
		btn_o2_5.DoClick = function() RunConsoleCommand("hg_org_menu_cmd", target:UserID(), "o2", 5) end
		
		local btn_o2_0 = vgui.Create("DButton", bg)
		btn_o2_0:SetText("0")
		btn_o2_0:SetPos(280, 28)
		btn_o2_0:SetSize(30, 18)
		btn_o2_0.DoClick = function() RunConsoleCommand("hg_org_menu_cmd", target:UserID(), "o2", 0) end
		
		local lblpain = vgui.Create("DLabel", bg)
		lblpain:SetText("Pain:")
		lblpain:SetPos(10, 55)
		lblpain:SizeToContents()
		
		local btn_pain_0 = vgui.Create("DButton", bg)
		btn_pain_0:SetText("0")
		btn_pain_0:SetPos(50, 53)
		btn_pain_0:SetSize(35, 18)
		btn_pain_0.DoClick = function() RunConsoleCommand("hg_org_menu_cmd", target:UserID(), "pain", 0) end
		
		local btn_pain_30 = vgui.Create("DButton", bg)
		btn_pain_30:SetText("30")
		btn_pain_30:SetPos(90, 53)
		btn_pain_30:SetSize(35, 18)
		btn_pain_30.DoClick = function() RunConsoleCommand("hg_org_menu_cmd", target:UserID(), "pain", 30) end
		
		local btn_pain_60 = vgui.Create("DButton", bg)
		btn_pain_60:SetText("60")
		btn_pain_60:SetPos(130, 53)
		btn_pain_60:SetSize(35, 18)
		btn_pain_60.DoClick = function() RunConsoleCommand("hg_org_menu_cmd", target:UserID(), "pain", 60) end
		
		local btn_pain_80 = vgui.Create("DButton", bg)
		btn_pain_80:SetText("80")
		btn_pain_80:SetPos(170, 53)
		btn_pain_80:SetSize(35, 18)
		btn_pain_80.DoClick = function() RunConsoleCommand("hg_org_menu_cmd", target:UserID(), "pain", 80) end
		
		local btn_pain_100 = vgui.Create("DButton", bg)
		btn_pain_100:SetText("100")
		btn_pain_100:SetPos(210, 53)
		btn_pain_100:SetSize(40, 18)
		btn_pain_100.DoClick = function() RunConsoleCommand("hg_org_menu_cmd", target:UserID(), "pain", 100) end
		
		local btn_pain_unlock = vgui.Create("DButton", bg)
		btn_pain_unlock:SetText("Unlock")
		btn_pain_unlock:SetPos(255, 53)
		btn_pain_unlock:SetSize(55, 18)
		btn_pain_unlock.DoClick = function() RunConsoleCommand("hg_org_menu_cmd", target:UserID(), "painunlock", 1) end
		
		local btn_ko = vgui.Create("DButton", bg)
		btn_ko:SetText("KO")
		btn_ko:SetPos(10, 80)
		btn_ko:SetSize(80, 25)
		btn_ko.DoClick = function() RunConsoleCommand("hg_org_menu_cmd", target:UserID(), "otrub", 1) end
		
		local btn_wake = vgui.Create("DButton", bg)
		btn_wake:SetText("Wake")
		btn_wake:SetPos(100, 80)
		btn_wake:SetSize(80, 25)
		btn_wake.DoClick = function() RunConsoleCommand("hg_org_menu_cmd", target:UserID(), "otrub", 0) end
		
		local btn_freeze = vgui.Create("DButton", bg)
		btn_freeze:SetText("Freeze O2")
		btn_freeze:SetPos(190, 80)
		btn_freeze:SetSize(80, 25)
		btn_freeze.DoClick = function() RunConsoleCommand("hg_org_menu_cmd", target:UserID(), "o2freeze", 1) end
		
		local btn_unfreeze = vgui.Create("DButton", bg)
		btn_unfreeze:SetText("Unfreeze")
		btn_unfreeze:SetPos(280, 80)
		btn_unfreeze:SetSize(40, 25)
		btn_unfreeze.DoClick = function() RunConsoleCommand("hg_org_menu_cmd", target:UserID(), "o2freeze", 0) end
		
		local lbldis = vgui.Create("DLabel", bg)
		lbldis:SetText("Disorient:")
		lbldis:SetPos(10, 110)
		lbldis:SizeToContents()
		
		local btn_dis_30 = vgui.Create("DButton", bg)
		btn_dis_30:SetText("30")
		btn_dis_30:SetPos(75, 108)
		btn_dis_30:SetSize(30, 18)
		btn_dis_30.DoClick = function() RunConsoleCommand("hg_org_menu_cmd", target:UserID(), "disorient", 30) end
		
		local btn_dis_25 = vgui.Create("DButton", bg)
		btn_dis_25:SetText("25")
		btn_dis_25:SetPos(110, 108)
		btn_dis_25:SetSize(30, 18)
		btn_dis_25.DoClick = function() RunConsoleCommand("hg_org_menu_cmd", target:UserID(), "disorient", 25) end
		
		local btn_dis_20 = vgui.Create("DButton", bg)
		btn_dis_20:SetText("20")
		btn_dis_20:SetPos(145, 108)
		btn_dis_20:SetSize(30, 18)
		btn_dis_20.DoClick = function() RunConsoleCommand("hg_org_menu_cmd", target:UserID(), "disorient", 20) end
		
		local btn_dis_15 = vgui.Create("DButton", bg)
		btn_dis_15:SetText("15")
		btn_dis_15:SetPos(180, 108)
		btn_dis_15:SetSize(30, 18)
		btn_dis_15.DoClick = function() RunConsoleCommand("hg_org_menu_cmd", target:UserID(), "disorient", 15) end
		
		local btn_dis_10 = vgui.Create("DButton", bg)
		btn_dis_10:SetText("10")
		btn_dis_10:SetPos(215, 108)
		btn_dis_10:SetSize(30, 18)
		btn_dis_10.DoClick = function() RunConsoleCommand("hg_org_menu_cmd", target:UserID(), "disorient", 10) end
		
		local btn_dis_5 = vgui.Create("DButton", bg)
		btn_dis_5:SetText("5")
		btn_dis_5:SetPos(250, 108)
		btn_dis_5:SetSize(30, 18)
		btn_dis_5.DoClick = function() RunConsoleCommand("hg_org_menu_cmd", target:UserID(), "disorient", 5) end
		
		local btn_dis_0 = vgui.Create("DButton", bg)
		btn_dis_0:SetText("0")
		btn_dis_0:SetPos(285, 108)
		btn_dis_0:SetSize(30, 18)
		btn_dis_0.DoClick = function() RunConsoleCommand("hg_org_menu_cmd", target:UserID(), "disorient", 0) end
		
		local lblshock = vgui.Create("DLabel", bg)
		lblshock:SetText("Shock:")
		lblshock:SetPos(10, 130)
		lblshock:SizeToContents()
		
		local btn_shock_30 = vgui.Create("DButton", bg)
		btn_shock_30:SetText("30")
		btn_shock_30:SetPos(60, 128)
		btn_shock_30:SetSize(30, 18)
		btn_shock_30.DoClick = function() RunConsoleCommand("hg_org_menu_cmd", target:UserID(), "shock", 30) end
		
		local btn_shock_25 = vgui.Create("DButton", bg)
		btn_shock_25:SetText("25")
		btn_shock_25:SetPos(95, 128)
		btn_shock_25:SetSize(30, 18)
		btn_shock_25.DoClick = function() RunConsoleCommand("hg_org_menu_cmd", target:UserID(), "shock", 25) end
		
		local btn_shock_20 = vgui.Create("DButton", bg)
		btn_shock_20:SetText("20")
		btn_shock_20:SetPos(130, 128)
		btn_shock_20:SetSize(30, 18)
		btn_shock_20.DoClick = function() RunConsoleCommand("hg_org_menu_cmd", target:UserID(), "shock", 20) end
		
		local btn_shock_15 = vgui.Create("DButton", bg)
		btn_shock_15:SetText("15")
		btn_shock_15:SetPos(165, 128)
		btn_shock_15:SetSize(30, 18)
		btn_shock_15.DoClick = function() RunConsoleCommand("hg_org_menu_cmd", target:UserID(), "shock", 15) end
		
		local btn_shock_10 = vgui.Create("DButton", bg)
		btn_shock_10:SetText("10")
		btn_shock_10:SetPos(200, 128)
		btn_shock_10:SetSize(30, 18)
		btn_shock_10.DoClick = function() RunConsoleCommand("hg_org_menu_cmd", target:UserID(), "shock", 10) end
		
		local btn_shock_5 = vgui.Create("DButton", bg)
		btn_shock_5:SetText("5")
		btn_shock_5:SetPos(235, 128)
		btn_shock_5:SetSize(30, 18)
		btn_shock_5.DoClick = function() RunConsoleCommand("hg_org_menu_cmd", target:UserID(), "shock", 5) end
		
		local btn_shock_0 = vgui.Create("DButton", bg)
		btn_shock_0:SetText("0")
		btn_shock_0:SetPos(270, 128)
		btn_shock_0:SetSize(30, 18)
		btn_shock_0.DoClick = function() RunConsoleCommand("hg_org_menu_cmd", target:UserID(), "shock", 0) end
		
		local lblpulse = vgui.Create("DLabel", bg)
		lblpulse:SetText("Pulse:")
		lblpulse:SetPos(10, 150)
		lblpulse:SizeToContents()
		
		local btn_pulse_30 = vgui.Create("DButton", bg)
		btn_pulse_30:SetText("30")
		btn_pulse_30:SetPos(60, 148)
		btn_pulse_30:SetSize(30, 18)
		btn_pulse_30.DoClick = function() RunConsoleCommand("hg_org_menu_cmd", target:UserID(), "pulse", 30) end
		
		local btn_pulse_25 = vgui.Create("DButton", bg)
		btn_pulse_25:SetText("25")
		btn_pulse_25:SetPos(95, 148)
		btn_pulse_25:SetSize(30, 18)
		btn_pulse_25.DoClick = function() RunConsoleCommand("hg_org_menu_cmd", target:UserID(), "pulse", 25) end
		
		local btn_pulse_20 = vgui.Create("DButton", bg)
		btn_pulse_20:SetText("20")
		btn_pulse_20:SetPos(130, 148)
		btn_pulse_20:SetSize(30, 18)
		btn_pulse_20.DoClick = function() RunConsoleCommand("hg_org_menu_cmd", target:UserID(), "pulse", 20) end
		
		local btn_pulse_15 = vgui.Create("DButton", bg)
		btn_pulse_15:SetText("15")
		btn_pulse_15:SetPos(165, 148)
		btn_pulse_15:SetSize(30, 18)
		btn_pulse_15.DoClick = function() RunConsoleCommand("hg_org_menu_cmd", target:UserID(), "pulse", 15) end
		
		local btn_pulse_10 = vgui.Create("DButton", bg)
		btn_pulse_10:SetText("10")
		btn_pulse_10:SetPos(200, 148)
		btn_pulse_10:SetSize(30, 18)
		btn_pulse_10.DoClick = function() RunConsoleCommand("hg_org_menu_cmd", target:UserID(), "pulse", 10) end
		
		local btn_pulse_5 = vgui.Create("DButton", bg)
		btn_pulse_5:SetText("5")
		btn_pulse_5:SetPos(235, 148)
		btn_pulse_5:SetSize(30, 18)
		btn_pulse_5.DoClick = function() RunConsoleCommand("hg_org_menu_cmd", target:UserID(), "pulse", 5) end
		
		local btn_pulse_0 = vgui.Create("DButton", bg)
		btn_pulse_0:SetText("0")
		btn_pulse_0:SetPos(270, 148)
		btn_pulse_0:SetSize(30, 18)
		btn_pulse_0.DoClick = function() RunConsoleCommand("hg_org_menu_cmd", target:UserID(), "pulse", 0) end
		
		local btn_pulse_freeze = vgui.Create("DButton", bg)
		btn_pulse_freeze:SetText("Freeze")
		btn_pulse_freeze:SetPos(305, 148)
		btn_pulse_freeze:SetSize(50, 18)
		btn_pulse_freeze.DoClick = function() RunConsoleCommand("hg_org_menu_cmd", target:UserID(), "pulsefreeze", 1) end
		
		local btn_pulse_unfreeze = vgui.Create("DButton", bg)
		btn_pulse_unfreeze:SetText("Unfrz")
		btn_pulse_unfreeze:SetPos(360, 148)
		btn_pulse_unfreeze:SetSize(35, 18)
		btn_pulse_unfreeze.DoClick = function() RunConsoleCommand("hg_org_menu_cmd", target:UserID(), "pulsefreeze", 0) end
		
local lbladren = vgui.Create("DLabel", bg)
		lbladren:SetText("Adrenaline:")
		lbladren:SetPos(10, 170)
		lbladren:SizeToContents()
		
		local btn_adren_30 = vgui.Create("DButton", bg)
		btn_adren_30:SetText("30")
		btn_adren_30:SetPos(85, 168)
		btn_adren_30:SetSize(35, 18)
		btn_adren_30.DoClick = function() RunConsoleCommand("hg_org_menu_cmd", target:UserID(), "adrenaline", 30) end
		
		local btn_adren_25 = vgui.Create("DButton", bg)
		btn_adren_25:SetText("25")
		btn_adren_25:SetPos(125, 168)
		btn_adren_25:SetSize(35, 18)
		btn_adren_25.DoClick = function() RunConsoleCommand("hg_org_menu_cmd", target:UserID(), "adrenaline", 25) end
		
		local btn_adren_20 = vgui.Create("DButton", bg)
		btn_adren_20:SetText("20")
		btn_adren_20:SetPos(165, 168)
		btn_adren_20:SetSize(35, 18)
		btn_adren_20.DoClick = function() RunConsoleCommand("hg_org_menu_cmd", target:UserID(), "adrenaline", 20) end
		
		local btn_adren_15 = vgui.Create("DButton", bg)
		btn_adren_15:SetText("15")
		btn_adren_15:SetPos(205, 168)
		btn_adren_15:SetSize(35, 18)
		btn_adren_15.DoClick = function() RunConsoleCommand("hg_org_menu_cmd", target:UserID(), "adrenaline", 15) end
		
		local btn_adren_10 = vgui.Create("DButton", bg)
		btn_adren_10:SetText("10")
		btn_adren_10:SetPos(245, 168)
		btn_adren_10:SetSize(35, 18)
		btn_adren_10.DoClick = function() RunConsoleCommand("hg_org_menu_cmd", target:UserID(), "adrenaline", 10) end
		
		local btn_adren_5 = vgui.Create("DButton", bg)
		btn_adren_5:SetText("5")
		btn_adren_5:SetPos(285, 168)
		btn_adren_5:SetSize(35, 18)
		btn_adren_5.DoClick = function() RunConsoleCommand("hg_org_menu_cmd", target:UserID(), "adrenaline", 5) end
		
		local btn_adren_0 = vgui.Create("DButton", bg)
		btn_adren_0:SetText("0")
		btn_adren_0:SetPos(325, 168)
		btn_adren_0:SetSize(35, 18)
		btn_adren_0.DoClick = function() RunConsoleCommand("hg_org_menu_cmd", target:UserID(), "adrenaline", 0) end
		
		local btn_adren_freeze = vgui.Create("DButton", bg)
		btn_adren_freeze:SetText("Freeze")
		btn_adren_freeze:SetPos(365, 168)
		btn_adren_freeze:SetSize(40, 18)
		btn_adren_freeze.DoClick = function() RunConsoleCommand("hg_org_menu_cmd", target:UserID(), "adrenalinefreeze", 1) end
		
		local btn_adren_unfreeze = vgui.Create("DButton", bg)
		btn_adren_unfreeze:SetText("Unfrz")
		btn_adren_unfreeze:SetPos(365, 190)
		btn_adren_unfreeze:SetSize(40, 18)
		btn_adren_unfreeze.DoClick = function() RunConsoleCommand("hg_org_menu_cmd", target:UserID(), "adrenalinefreeze", 0) end
		
		local lblbleed = vgui.Create("DLabel", bg)
		lblbleed:SetText("Bleeding:")
		lblbleed:SetPos(10, 215)
		lblbleed:SizeToContents()
		
		local slider_bleed = vgui.Create("DNumSlider", bg)
		slider_bleed:SetPos(70, 210)
		slider_bleed:SetSize(250, 20)
		slider_bleed:SetMin(0)
		slider_bleed:SetMax(100)
		slider_bleed:SetDecimals(0)
		slider_bleed:SetValue(0)
		
		local btn_apply_bleed = vgui.Create("DButton", bg)
		btn_apply_bleed:SetText("Apply")
		btn_apply_bleed:SetPos(330, 213)
		btn_apply_bleed:SetSize(60, 18)
		btn_apply_bleed.DoClick = function()
			local bleedValue = slider_bleed:GetValue()
			RunConsoleCommand("hg_org_menu_cmd", target:UserID(), "bleed", bleedValue)
		end
		
		local btn_cut_artery = vgui.Create("DButton", bg)
		btn_cut_artery:SetText("Cut Carotid Artery")
		btn_cut_artery:SetPos(10, 240)
		btn_cut_artery:SetSize(150, 25)
		btn_cut_artery.DoClick = function()
			RunConsoleCommand("hg_org_menu_cmd", target:UserID(), "cutartery", 1)
		end
		
		y = y + 280
	end
end

concommand.Add("hg_organism_menu", function()
	OpenOrganismMenu()
end)

local afk_lastMove = CurTime()
local afk_lastAng  = Angle(0,0,0)
local afk_lastPos  = Vector(0,0,0)
local afk_alpha    = 0
local AFK_TIME     = 300 -- секунд до АФК

local afk_dots     = 0
local afk_dotTimer = 0

hook.Add("Think", "hg_afk_tracker", function()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	local pos = ply:GetPos()
	local ang = ply:EyeAngles()

	-- если двинулся или повернул камеру — сбрасываем таймер
	if pos:DistToSqr(afk_lastPos) > 4 or math.abs(ang.y - afk_lastAng.y) > 1 or math.abs(ang.p - afk_lastAng.p) > 1 then
		afk_lastMove = CurTime()
		afk_lastPos  = pos
		afk_lastAng  = ang
	end
end)

hook.Add("PlayerButtonDown", "hg_afk_keypress", function(ply, btn)
	if ply ~= LocalPlayer() then return end
	afk_lastMove = CurTime()
end)

hook.Add("HUDPaint", "hg_afk_screen", function()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	local isAfk = (CurTime() - afk_lastMove) >= AFK_TIME

	afk_alpha = Lerp(FrameTime() * 2, afk_alpha, isAfk and 1 or 0)

	if afk_alpha < 0.01 then return end

	local sw, sh = ScrW(), ScrH()
	local a = afk_alpha

	-- затемнение
	surface.SetDrawColor(0, 0, 0, 180 * a)
	surface.DrawRect(0, 0, sw, sh)

	-- градиент снизу
	surface.SetDrawColor(80, 0, 0, 180 * a)
	surface.SetMaterial(Material("vgui/gradient-d"))
	surface.DrawTexturedRect(0, sh / 2, sw, sh / 2)

	-- градиент сверху
	surface.SetDrawColor(80, 0, 0, 120 * a)
	surface.SetMaterial(Material("vgui/gradient-u"))
	surface.DrawTexturedRect(0, 0, sw, sh / 2)

	-- анимация точек
	afk_dotTimer = afk_dotTimer + FrameTime()
	if afk_dotTimer >= 0.5 then
		afk_dotTimer = 0
		afk_dots = (afk_dots + 1) % 4
	end
	local dots = string.rep(".", afk_dots)

	-- текст
	local cx, cy = sw / 2, sh / 2

	surface.SetFont("HomigradFontBig")
	local tw, th = surface.GetTextSize("AFK")
	surface.SetTextColor(255, 255, 255, 255 * a)
	surface.SetTextPos(cx - tw / 2, cy - th - 10)
	surface.DrawText("AFK")

	surface.SetFont("HomigradFontMedium")
	local msg = "Тип пошел хавать" .. dots
	local mw, mh = surface.GetTextSize(msg)
	surface.SetTextColor(180, 180, 180, 220 * a)
	surface.SetTextPos(cx - mw / 2, cy + 10)
	surface.DrawText(msg)

	-- время афк
	local elapsed = math.floor(CurTime() - afk_lastMove)
	local mins = math.floor(elapsed / 60)
	local secs = elapsed % 60
	local timeStr = string.format("%d:%02d", mins, secs)
	surface.SetFont("HomigradFontSmall")
	local tw2, th2 = surface.GetTextSize(timeStr)
	surface.SetTextColor(120, 120, 120, 180 * a)
	surface.SetTextPos(cx - tw2 / 2, cy + mh + 20)
	surface.DrawText(timeStr)

	-- подсказка снизу слева — чередуется каждые 3 сек с анимацией
	local afk_hints = {
		"ау, ты тут? давай играй!",
		"сервер скучает без тебя...",
		"эй, не спи за клавой",
		"ты там живой вообще?",
		"может хватит афкшить?",
		"твой персонаж замёрз стоять",
		"нажми хоть что-нибудь...",
		"сколько можно стоять столбом",
	}
	local period   = 3  -- секунд на фразу
	local t        = CurTime()
	local hintIdx  = math.floor(t / period) % #afk_hints + 1
	local phase    = (t % period) / period  -- 0..1 внутри периода

	-- fade in 20%, показ 60%, fade out 20%
	local hintAlpha
	if phase < 0.2 then
		hintAlpha = math.ease.OutQuart(phase / 0.2)
	elseif phase < 0.8 then
		hintAlpha = 1
	else
		hintAlpha = math.ease.InQuart(1 - (phase - 0.8) / 0.2)
	end

	-- выезд снизу: при fade in едет вверх, при fade out уходит вниз
	local slideOffset
	if phase < 0.2 then
		slideOffset = (1 - math.ease.OutQuart(phase / 0.2)) * 22
	elseif phase < 0.8 then
		slideOffset = 0
	else
		slideOffset = math.ease.InQuart((phase - 0.8) / 0.2) * 22
	end

	surface.SetFont("HomigradFontSmall")
	local hint = afk_hints[hintIdx]
	surface.SetTextColor(255, 255, 255, 200 * a * hintAlpha)
	surface.SetTextPos(20, sh - 40 + slideOffset)
	surface.DrawText(hint)
end)

-- Сообщение при лоботомии >= 30% — чередующиеся фразы
do
	surface.CreateFont("HG_LobotomyMsg", {
		font      = "Bender",
		size      = ScreenScale(14),
		weight    = 700,
		antialias = true,
	})

	-- спокойные фразы (brain 0.3 - 0.6)
	local MESSAGES_CALM = {
		"You tried to survive, but failed.",
		"Your mind is slipping away...",
		"The damage is too great to recover.",
		"You can feel yourself fading.",
		"It's getting harder to think clearly.",
		"Your brain can't take much more of this.",
		"Everything is becoming a blur.",
		"You should have been more careful.",
		"The end is closer than you think.",
		"Hold on... just a little longer.",
		"Is anyone out there?",
		"I can't remember who I am anymore.",
		"The pain is fading... that's not good.",
		"My thoughts are scattered.",
		"I just need to rest for a moment.",
		"Why can't I focus?",
		"Something is very wrong with my head.",
		"I can hear my heartbeat slowing.",
		"Was it worth it?",
		"I should have run when I had the chance.",
	}

	-- агрессивные фразы (brain > 0.6) — капсом, злые
	local MESSAGES_RAGE = {
		"YOU COULD HAVE SURVIVED BUT YOU'RE TOO STUPID FOR THAT.",
		"WHAT WERE YOU THINKING? YOU DESERVED THIS.",
		"YOU HAD EVERY CHANCE. YOU WASTED THEM ALL.",
		"TOO DUMB TO LIVE. TOO SLOW TO RUN.",
		"DID YOU REALLY THINK YOU COULD MAKE IT?",
		"YOU FAILED. AGAIN. AS ALWAYS.",
		"YOUR BRAIN IS GONE. JUST LIKE YOUR CHANCES.",
		"PATHETIC. ABSOLUTELY PATHETIC.",
		"YOU CALL THAT SURVIVING? I CALL IT DYING SLOWLY.",
		"NOBODY IS COMING TO SAVE YOU.",
		"YOU BROUGHT THIS ON YOURSELF.",
		"STOP PRETENDING YOU KNOW WHAT YOU'RE DOING.",
		"THIS IS WHAT HAPPENS WHEN YOU DON'T THINK.",
		"YOU NEVER HAD A CHANCE. ADMIT IT.",
		"GAME OVER. YOU LOSE. AGAIN.",
	}

	-- издевательские фразы (brain > 0.7)
	local MESSAGES_MOCK = {
		"WHILE YOU'RE BEING STUPID, YOUR BRAIN IS ROTTING.",
		"KEEP STANDING THERE. THAT'S REALLY HELPING.",
		"WOW. JUST... WOW. HOW ARE YOU EVEN ALIVE THIS LONG?",
		"YOUR TEAMMATES ARE WATCHING YOU DIE. SLOWLY.",
		"CONGRATULATIONS. YOU FOUND A NEW WAY TO FAIL.",
		"IS THIS YOUR STRATEGY? BECAUSE IT'S WORKING GREAT.",
		"MAYBE NEXT TIME TRY USING YOUR HEAD. OH WAIT.",
		"YOU'RE DOING AMAZING. KEEP IT UP. (YOU'RE NOT.)",
		"I'VE SEEN ROCKS MAKE BETTER DECISIONS.",
		"AT LEAST YOU'RE CONSISTENT. CONSISTENTLY TERRIBLE.",
		"YOUR BRAIN CALLED. IT WANTS OUT.",
		"EVEN THE HEADCRAB IS EMBARRASSED FOR YOU.",
		"THIS IS FINE. EVERYTHING IS FINE. (IT'S NOT FINE.)",
		"YOU COULD HAVE JUST... NOT DONE THAT.",
		"SKILL ISSUE. MASSIVE SKILL ISSUE.",
	}

	local MSG_INTERVAL = 4.0

	local msgAlpha   = 0
	local msgShown   = false
	local msgIndex   = 1
	local msgTimer   = 0
	local msgFadeOut = false
	local msgRage    = false  -- текущий пул

	-- глитч: случайные символы для замены
	local GLITCH_CHARS = "!@#$%^&*<>?/\\|[]{}~`"
	local glitchTimer  = 0
	local glitchStr    = ""

	local function MakeGlitch(str, intensity)
		local result = {}
		for i = 1, #str do
			if math.random() < intensity * 0.4 then
				local idx = math.random(#GLITCH_CHARS)
				result[i] = string.sub(GLITCH_CHARS, idx, idx)
			else
				result[i] = string.sub(str, i, i)
			end
		end
		return table.concat(result)
	end

	hook.Add("Player Spawn", "HG_LobotomyMsgReset", function(ply)
		if ply ~= LocalPlayer() then return end
		msgShown   = false
		msgAlpha   = 0
		msgIndex   = 1
		msgTimer   = 0
		msgFadeOut = false
		msgRage    = false
		glitchStr  = ""
	end)

	hook.Add("HUDPaint", "HG_LobotomyMsg", function()
		local lp = LocalPlayer()
		if not IsValid(lp) or not lp:Alive() then return end
		local org = lp.organism
		if not org then return end

		local brain = org.brain or 0

		if msgShown and brain < 0.1 then
			msgShown   = false
			msgAlpha   = 0
			msgIndex   = 1
			msgTimer   = 0
			msgFadeOut = false
			msgRage    = false
			glitchStr  = ""
			return
		end

		if brain >= 0.3 and not msgShown then
			msgShown   = true
			msgRage    = brain > 0.6
			local pool = msgRage and (brain > 0.7 and MESSAGES_MOCK or MESSAGES_RAGE) or MESSAGES_CALM
			msgIndex   = math.random(#pool)
			msgTimer   = CurTime() + MSG_INTERVAL
			msgFadeOut = false
		end

		if not msgShown then return end

		local ft = FrameTime()
		local t  = CurTime()

		-- при нарастании brain переключаем пул
		local shouldRage = brain > 0.6
		if shouldRage ~= msgRage and not msgFadeOut then
			msgFadeOut = true
		end

		if msgFadeOut then
			msgAlpha = math.max(msgAlpha - ft * 150, 0)
			if msgAlpha <= 0 then
				msgRage = shouldRage
				local pool = msgRage and (brain > 0.7 and MESSAGES_MOCK or MESSAGES_RAGE) or MESSAGES_CALM
				local newIdx = msgIndex
				while newIdx == msgIndex and #pool > 1 do
					newIdx = math.random(#pool)
				end
				msgIndex   = newIdx
				msgFadeOut = false
				msgTimer   = CurTime() + MSG_INTERVAL
			end
		else
			msgAlpha = math.min(msgAlpha + ft * 80, 255)
			if CurTime() > msgTimer then
				msgFadeOut = true
			end
		end

		if msgAlpha <= 0 then return end

		local pool  = msgRage and (brain > 0.7 and MESSAGES_MOCK or MESSAGES_RAGE) or MESSAGES_CALM
		local msg   = pool[msgIndex] or ""

		-- глитч нарастает с brain
		local glitchIntensity = math.Clamp((brain - 0.3) / 0.7, 0, 1)

		-- обновляем глитч строку раз в 0.05 сек
		glitchTimer = glitchTimer + ft
		if glitchTimer > 0.05 then
			glitchTimer = 0
			if glitchIntensity > 0.05 then
				glitchStr = MakeGlitch(msg, glitchIntensity)
			else
				glitchStr = msg
			end
		end
		if glitchStr == "" then glitchStr = msg end

		-- дрожание нарастает с brain
		local shakeAmt = glitchIntensity * 8
		local shakeX   = math.sin(t * 60) * shakeAmt
		local shakeY   = math.cos(t * 55) * shakeAmt

		local sw, sh = ScrW(), ScrH()
		local alpha  = math.floor(msgAlpha)
		local baseX  = sw / 2
		local baseY  = sh * 0.62

		surface.SetFont("HG_LobotomyMsg")
		local tw, _ = surface.GetTextSize(glitchStr)

		-- при rage — красный цвет, при calm — белый
		local r = msgRage and 220 or 200
		local g = msgRage and 20  or 200
		local b = msgRage and 20  or 200

		-- тень
		surface.SetTextColor(0, 0, 0, alpha)
		surface.SetTextPos(baseX - tw / 2 + shakeX + 2, baseY + shakeY + 2)
		surface.DrawText(glitchStr)

		-- основной текст
		surface.SetTextColor(r, g, b, alpha)
		surface.SetTextPos(baseX - tw / 2 + shakeX, baseY + shakeY)
		surface.DrawText(glitchStr)

		-- при сильном глитче — чёрная аберрация (смещённые тёмные копии)
		if glitchIntensity > 0.4 then
			local aberr = glitchIntensity * 4
			-- тёмно-красный слой справа
			surface.SetTextColor(80, 0, 0, math.floor(alpha * 0.5))
			surface.SetTextPos(baseX - tw / 2 + shakeX + aberr, baseY + shakeY)
			surface.DrawText(glitchStr)
			-- чёрный слой слева
			surface.SetTextColor(0, 0, 0, math.floor(alpha * 0.6))
			surface.SetTextPos(baseX - tw / 2 + shakeX - aberr, baseY + shakeY)
			surface.DrawText(glitchStr)
		end
	end)
end
