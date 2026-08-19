ZCFpv = ZCFpv or {}

CreateClientConVar("zc_fpv_vhs", "1", true, false)
CreateClientConVar("zc_fpv_vhs_comets", "1", true, false)
CreateClientConVar("zc_fpv_vhs_chroma", "1", true, false)
CreateClientConVar("zc_fpv_vhs_desat", "1", true, false)
CreateClientConVar("crocus_vhs_shake", "1", true, false)

local M_NOISE = Material("effects/fpv_noise")
local BAT_0 = Material("osd/bat_0.png", "mips smooth")
local BAT_1 = Material("osd/bat_1.png", "mips smooth")
local BAT_2 = Material("osd/bat_2.png", "mips smooth")
local BAT_3 = Material("osd/bat_3.png", "mips smooth")
local BAT_4 = Material("osd/bat_4.png", "mips smooth")
local BAT_5 = Material("osd/bat_5.png", "mips smooth")
local BAT_6 = Material("osd/bat_6.png", "mips smooth")
local FLYMN = Material("osd/flymn.png", "mips smooth")
local BAT_LOW = Material("osd/bat_low.png", "mips noclamp")
local M_CH = Material("osd/crosshair.png", "mips smooth")
local M_WIFI = Material("osd/wifi.png", "mips smooth")
local M_AIR = Material("osd/airspd.png", "mips smooth")
local M_GND = Material("osd/gndspd.png", "mips smooth")
local M_KMH = Material("osd/kmh.png", "mips smooth")
local M_MM = Material("osd/mm.png", "mips smooth")
local M_P0 = Material("osd/0p.png", "mips smooth")
local M_P1 = Material("osd/1p.png", "mips smooth")
local M_P2 = Material("osd/2p.png", "mips smooth")
local M_P3 = Material("osd/3p.png", "mips smooth")
local M_P4 = Material("osd/4p.png", "mips smooth")

local clr = Color(180, 180, 180, 255)
local COMPASS = {[0] = "N", [45] = "NE", [90] = "E", [135] = "SE", [180] = "S", [225] = "SW", [270] = "W", [315] = "NW", [360] = "N"}
local ring = {{2, 4}, {4, 2}, {4, -2}, {2, -4}, {-2, -4}, {-4, -2}, {-4, 2}, {-2, 4}}
local _pts = {{}, {}, {}, {}, {}}

surface.CreateFont("ZCFpv_Beta", {
	font = "VCR OSD Mono Cyr",
	size = 24,
	weight = 400,
	outline = true,
	antialias = false,
	scanlines = 1,
	extended = true,
})

surface.CreateFont("ZCFpv_OSD", {
	font = "Arial",
	size = 28,
	weight = 600,
	antialias = false,
	scanlines = 1,
	extended = true,
})

surface.CreateFont("ZCFpv_OSD_Sm", {
	font = "Arial",
	size = 18,
	weight = 500,
	antialias = false,
	scanlines = 1,
	extended = true,
})

local vhsOn = false
local desatNext, desatEnd, desatVal = 0, 0, 1
local smoothNoise = 0
local takeOffPos
local flightStart
local cachedAlt = 0
local nextAltTrace = 0
ZCFpv.MavicNVG = false

hook.Remove("PostDrawOpaqueRenderables", "ZCFpv_ThermalHot")
hook.Remove("PostDrawEffects", "ZCFpv_ThermalHot")
hook.Remove("PreDrawHalos", "ZCFpv_ThermalHalo")
hook.Remove("RenderScreenspaceEffects", "ZCFpv_zMavicNVG")
hook.Remove("HUDPaint", "ZCFpv_ThermalHUD")
hook.Remove("Think", "ZCFpv_ThermalKey")
hook.Remove("PlayerButtonDown", "ZCFpv_MavicNVG")

local matThermal = CreateMaterial("zc_fpv_thermal_hot", "UnlitGeneric", {
	["$basetexture"] = "vgui/white",
	["$model"] = "1",
	["$vertexcolor"] = "1",
	["$vertexalpha"] = "0",
	["$nofog"] = "1",
	["$ignorez"] = "0",
})
local thermalHot = {}

local thermalMod = {
	["$pp_colour_addr"] = 0,
	["$pp_colour_addg"] = 0,
	["$pp_colour_addb"] = 0,
	["$pp_colour_brightness"] = -0.28,
	["$pp_colour_contrast"] = 1.05,
	["$pp_colour_colour"] = 0,
	["$pp_colour_mulr"] = 0,
	["$pp_colour_mulg"] = 0,
	["$pp_colour_mulb"] = 0,
}

local function droneHasThermal(drone)
	if not IsValid(drone) then return false end
	local cls = drone:GetClass()
	if cls == "ent_zc_fpv_mavic" then return true end
	if cls:find("crocus", 1, true) then return true end
	return false
end

local function getThermalDrone()
	local ply = LocalPlayer()
	local drone = ZCFpv.GetLinkedDrone(ply)
	if IsValid(drone) then return drone end
	if IsValid(ZCFpv.ClientLinked) then return ZCFpv.ClientLinked end
end

local function thermalActive()
	if not ZCFpv.MavicNVG then return false end
	local drone = getThermalDrone()
	if not droneHasThermal(drone) then
		ZCFpv.MavicNVG = false
		return false
	end
	return true, drone
end

local thermalKeyDown = false
local thermalToggleAt = 0

local function toggleThermal()
	local now = CurTime()
	if now < thermalToggleAt + 0.2 then return end
	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	if gui.IsGameUIVisible() or ply:IsTyping() then return end
	if vgui.GetKeyboardFocus() then return end
	local drone = getThermalDrone()
	if not droneHasThermal(drone) then return end
	thermalToggleAt = now
	ZCFpv.MavicNVG = not ZCFpv.MavicNVG
	surface.PlaySound(ZCFpv.MavicNVG and "buttons/button14.wav" or "buttons/button19.wav")
end

local function collectThermalHot()
	thermalHot = {}
	for _, ply in ipairs(player.GetAll()) do
		if IsValid(ply) and ply:Alive() and not ply:GetNoDraw() then
			thermalHot[#thermalHot + 1] = ply
		end
	end
	for _, ent in ipairs(ents.FindByClass("npc_*")) do
		if IsValid(ent) and ent:Health() > 0 and not ent:GetNoDraw() then
			thermalHot[#thermalHot + 1] = ent
		end
	end
	for _, ent in ipairs(ents.FindByClass("prop_ragdoll")) do
		if IsValid(ent) and not ent:GetNoDraw() then
			thermalHot[#thermalHot + 1] = ent
		end
	end
end

local function paintHotEnt(ent)
	if not IsValid(ent) then return end
	render.MaterialOverride(matThermal)
	render.SuppressEngineLighting(true)
	render.SetColorModulation(1, 1, 1)
	render.SetBlend(1)
	ent:DrawModel()
	if ent:IsPlayer() then
		local wep = ent:GetActiveWeapon()
		if IsValid(wep) then wep:DrawModel() end
	end
	render.SuppressEngineLighting(false)
	render.MaterialOverride(nil)
end


local batUpperT = {0.05, 0.15, 0.30, 0.55, 0.80, 0.95}
local batUpperM = {BAT_6, BAT_5, BAT_4, BAT_3, BAT_2, BAT_1, BAT_0}
local batLowerT = {0.15, 0.30, 0.55, 0.80, 0.95}
local batLowerM = {BAT_5, BAT_4, BAT_3, BAT_2, BAT_1, BAT_0}

local function upperBat(pct)
	for i, t in ipairs(batUpperT) do
		if pct <= t then return batUpperM[i] end
	end
	return BAT_0
end

local function lowerBat(pct)
	for i, t in ipairs(batLowerT) do
		if pct <= t then return batLowerM[i] end
	end
	return BAT_0
end

local function DrawBox(x, y, w, h)
	x, y, w, h = math.floor(x), math.floor(y), math.floor(w), math.floor(h)
	surface.SetDrawColor(0, 0, 0, 255)
	surface.DrawRect(x - 1, y - 1, w + 2, h + 2)
	surface.SetDrawColor(180, 180, 180, 255)
	surface.DrawRect(x, y, w, h)
end

local function DrawOutlinedLine(x1, y1, x2, y2)
	x1, y1, x2, y2 = math.floor(x1), math.floor(y1), math.floor(x2), math.floor(y2)
	surface.SetDrawColor(0, 0, 0, 255)
	surface.DrawLine(x1 - 1, y1, x2 - 1, y2)
	surface.DrawLine(x1 + 1, y1, x2 + 1, y2)
	surface.DrawLine(x1, y1 - 1, x2, y2 - 1)
	surface.DrawLine(x1, y1 + 1, x2, y2 + 1)
	surface.SetDrawColor(180, 180, 180, 255)
	surface.DrawLine(x1, y1, x2, y2)
end

local function DrawHollowPointer(x, y, side, text)
	local w = 70
	if side == "left" then
		_pts[1].x, _pts[1].y = x, y
		_pts[2].x, _pts[2].y = x + 15, y - 18
		_pts[3].x, _pts[3].y = x + w, y - 18
		_pts[4].x, _pts[4].y = x + w, y + 18
		_pts[5].x, _pts[5].y = x + 15, y + 18
	else
		_pts[1].x, _pts[1].y = x, y
		_pts[2].x, _pts[2].y = x - 15, y - 18
		_pts[3].x, _pts[3].y = x - w, y - 18
		_pts[4].x, _pts[4].y = x - w, y + 18
		_pts[5].x, _pts[5].y = x - 15, y + 18
	end
	surface.SetDrawColor(0, 0, 0, 255)
	for i = 1, 5 do
		local np = _pts[i + 1] or _pts[1]
		surface.DrawLine(_pts[i].x - 1, _pts[i].y, np.x - 1, np.y)
		surface.DrawLine(_pts[i].x + 1, _pts[i].y, np.x + 1, np.y)
		surface.DrawLine(_pts[i].x, _pts[i].y - 1, np.x, np.y - 1)
		surface.DrawLine(_pts[i].x, _pts[i].y + 1, np.x, np.y + 1)
	end
	surface.SetDrawColor(180, 180, 180, 255)
	for i = 1, 5 do
		local np = _pts[i + 1] or _pts[1]
		surface.DrawLine(_pts[i].x, _pts[i].y, np.x, np.y)
	end
	local tx = (side == "left") and (x + 42) or (x - 42)
	draw.SimpleText(text, "ZCFpv_Beta", math.floor(tx), math.floor(y), clr, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

local function DrawVerticalTape(val, x_pos, side, bottom_text, sh)
	local cy = sh * 0.5
	local pxd = 6
	local range = 25
	render.SetScissorRect(x_pos - 100, cy - 150, x_pos + 100, cy + 150, true)
	for i = math.floor(val - range), math.ceil(val + range) do
		local y = cy + (val - i) * pxd
		if i >= 0 then
			if i % 10 == 0 then
				local tx = (side == "left") and (x_pos + 12) or (x_pos - 12)
				DrawOutlinedLine(x_pos, y, tx, y)
				local txt_x = (side == "left") and (x_pos - 5) or (x_pos + 5)
				draw.SimpleText(string.format("%03d", i), "ZCFpv_Beta", txt_x, y, clr, side == "left" and 1 or 0, 1)
			elseif i % 2 == 0 then
				local tx = (side == "left") and (x_pos + 7) or (x_pos - 7)
				DrawOutlinedLine(x_pos, y, tx, y)
			end
		end
	end
	render.SetScissorRect(0, 0, 0, 0, false)
	DrawHollowPointer(side == "left" and x_pos + 12 or x_pos - 12, cy, side, string.format(side == "right" and "%04d" or "%03d", math.Round(val)))
	if bottom_text then
		draw.SimpleText(bottom_text, "ZCFpv_Beta", x_pos, cy + 170, clr, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end

local function DrawCompass(heading, cx)
	local strip_y, strip_w, pxd = 70, 420, 5
	local hw = strip_w / 2
	render.SetScissorRect(cx - hw, 0, cx + hw, strip_y + 60, true)
	surface.SetDrawColor(0, 0, 0, 255)
	surface.DrawRect(cx - hw, strip_y - 1, strip_w, 3)
	surface.SetDrawColor(180, 180, 180, 255)
	surface.DrawRect(cx - hw, strip_y, strip_w, 1)
	for i = math.floor(heading - hw / pxd), math.ceil(heading + hw / pxd) do
		local x = math.floor(cx + (i - heading) * pxd)
		local nd = i % 360
		if nd < 0 then nd = nd + 360 end
		local th = (i % 15 == 0) and 12 or ((i % 5 == 0) and 7 or 4)
		surface.SetDrawColor(0, 0, 0, 255)
		surface.DrawRect(x - 1, strip_y - th - 1, 3, th + 2)
		surface.SetDrawColor(180, 180, 180, 255)
		surface.DrawRect(x, strip_y - th, 1, th)
		if COMPASS[nd] and i % 45 == 0 then
			draw.SimpleText(COMPASS[nd], "ZCFpv_Beta", x, strip_y - 14, clr, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
		end
	end
	render.SetScissorRect(0, 0, 0, 0, false)
	draw.SimpleText(string.format("%03d", math.Round(heading)), "ZCFpv_Beta", cx, strip_y + 5, clr, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
end

local function updateAltitude(pos, drone)
	local ct = CurTime()
	if ct >= nextAltTrace then
		nextAltTrace = ct + 0.1
		local tr = util.TraceLine({start = pos, endpos = pos - Vector(0, 0, 50000), filter = drone})
		cachedAlt = (pos.z - tr.HitPos.z) / 39.37
	end
	return cachedAlt
end

local function updateNoise(sig, jam)
	local lose = 1 - sig
	local target = (lose * lose) * 220 + lose * 80 + (jam or 0) ^ 2 * 180
	if sig < 0.12 then target = math.max(target, 200 + (0.12 - sig) * 900) end
	if sig < 0.06 then target = math.min(255, 240 + math.sin(CurTime() * 18) * 15) end
	smoothNoise = Lerp(FrameTime() * 3, smoothNoise, math.Clamp(target, 0, 255))
	return smoothNoise
end

local function DrawBetaflight(drone, sw, sh, cx, cy, sig)
	local pos = drone:GetPos()
	local ang = drone:GetAngles()
	local ct = CurTime()
	if not takeOffPos then takeOffPos = pos end
	if not flightStart then flightStart = ct end

	local altitude = updateAltitude(pos, drone)
	local speed = drone:GetVelocity():Length() * 0.09144
	local fTime = ct - flightStart

	-- horizon dashes
	local roll = math.Clamp(ang.r, -60, 60)
	for side = -1, 1, 2 do
		for d = 1, 5 do
			local pX = cx + (side * (100 + (d - 1) * 28))
			if side == -1 then pX = pX - 8 end
			local pY = math.Clamp(cy + (side * ((d / 5) * (roll * 4))), 150, sh - 150)
			DrawBox(pX, pY, 8, 2)
		end
	end

	DrawVerticalTape(speed, cx - 350, "left", "KM/H", sh)
	DrawVerticalTape(altitude, cx + 350, "right", "M", sh)
	DrawCompass((-ang.y + 90) % 360, cx)

	-- crosshair dots
	DrawBox(cx - 1, cy - 1, 2, 2)
	for _, p in ipairs(ring) do
		DrawBox(cx + p[1] - 1, cy + p[2] - 1, 2, 2)
	end
	for i = 1, 2 do
		local gap = 14 + (i - 1) * 10
		DrawBox(cx + gap, cy - 1, 5, 2)
		DrawBox(cx - gap - 5, cy - 1, 5, 2)
		DrawBox(cx - 1, cy + gap, 2, 5)
		DrawBox(cx - 1, cy - gap - 5, 2, 5)
	end

	local distHome = math.Round(pos:Distance(takeOffPos) / 39.37)
	draw.SimpleText(string.format("%03dM", distHome), "ZCFpv_Beta", 50, 50, clr, 0)

	local acroY = sh - 110
	local fps = math.Round(1 / math.max(RealFrameTime(), 0.001))
	draw.SimpleText("ACRO", "ZCFpv_Beta", cx - 45, acroY, clr, TEXT_ALIGN_CENTER)
	draw.SimpleText("FPS " .. fps, "ZCFpv_Beta", cx - 45, acroY + 25, clr, TEXT_ALIGN_CENTER)

	local bars = (sig > 0.7 and 3) or (sig > 0.35 and 2) or 1
	for i = 1, 3 do
		local h = 16 - (i - 1) * 5
		local sx = cx + 8 + i * 9
		local by = acroY + 24 - h
		surface.SetDrawColor(0, 0, 0, 255)
		surface.DrawRect(sx - 1, by - 1, 5, h + 2)
		local v = (i <= bars) and 180 or 30
		surface.SetDrawColor(v, v, v, 255)
		surface.DrawRect(sx, by, 3, h)
	end

	local pct = math.Clamp(drone:GetBattery(), 0, 1)
	local thrFrac = drone:GetThrottleFrac()
	local throttle = math.Clamp(thrFrac, 0, 1)
	local fuelPlane = drone.FixedWing
	local bx, by = 60, sh - 280

	if fuelPlane then
		draw.SimpleText("FUEL", "ZCFpv_Beta", bx, by + 18, clr)
		draw.SimpleText(string.format("%.0f%%", pct * 100), "ZCFpv_Beta", bx + 55, by + 18, clr)
		surface.SetDrawColor(0, 0, 0, 200)
		surface.DrawRect(bx - 1, by + 48, 102, 14)
		surface.SetDrawColor(pct > 0.25 and Color(180, 180, 180) or Color(180, 60, 40))
		surface.DrawRect(bx, by + 49, 100 * pct, 12)
		if pct < 0.33 and math.sin(ct * 10) > 0 then
			draw.SimpleText("LOW FUEL", "ZCFpv_Beta", cx, cy + 85, clr, TEXT_ALIGN_CENTER)
		end
	else
		local volts = math.max(0, (14.8 * pct) - throttle * 0.8)
		surface.SetDrawColor(255, 255, 255, 255)
		surface.SetMaterial(upperBat(pct))
		surface.DrawTexturedRect(bx, by, 40, 70)
		draw.SimpleText(string.format("%.2fV", volts / 4), "ZCFpv_Beta", bx + 55, by + 18, clr)

		surface.SetMaterial(lowerBat(pct))
		surface.DrawTexturedRect(bx, by + 90, 40, 70)
		draw.SimpleText(string.format("%.1fV", volts), "ZCFpv_Beta", bx + 55, by + 108, clr)
		draw.SimpleText(string.format("%.0f MAH", 200 + pct * 1300), "ZCFpv_Beta", bx, by + 175, clr)

		if pct < 0.33 and math.sin(ct * 10) > 0 then
			surface.SetMaterial(BAT_LOW)
			surface.SetDrawColor(180, 180, 180, 255)
			local th = 32
			local tw = (BAT_LOW:Width() / math.max(BAT_LOW:Height(), 1)) * th
			surface.DrawTexturedRect(math.floor(cx - tw * 0.5), math.floor(cy + 85), tw, th)
		end
	end

	local trX = sw - 50
	draw.SimpleText(string.format("%+d P", math.Round(ang.p)), "ZCFpv_Beta", trX, 50, clr, 2)
	draw.SimpleText(string.format("%+d R", math.Round(ang.r)), "ZCFpv_Beta", trX, 80, clr, 2)

	local brX, brY = sw - 50, sh - 150
	draw.SimpleText(string.format("%+d M/S", math.Round(drone:GetVelocity().z / 39.37)), "ZCFpv_Beta", brX, brY, clr, 2)
	if fuelPlane then
		draw.SimpleText(string.format("FUEL %.0f%%", pct * 100), "ZCFpv_Beta", brX, brY + 35, clr, 2)
	else
		local volts = math.max(0, (14.8 * pct) - throttle * 0.8)
		draw.SimpleText(string.format("U %.1fV", volts), "ZCFpv_Beta", brX, brY + 35, clr, 2)
	end
	draw.SimpleText(string.format("%d:%02d", math.floor(fTime / 60), math.floor(fTime % 60)), "ZCFpv_Beta", brX, brY + 70, clr, 2)

	surface.SetMaterial(FLYMN)
	surface.SetDrawColor(180, 180, 180, 255)
	surface.DrawTexturedRect(brX - 65, brY + 68, 26, 26)

	draw.SimpleText("HEALTH " .. math.max(0, math.Round(drone:Health())), "ZCFpv_Beta", 50, sh - 40, clr, 0)
	draw.SimpleText(string.format("km/h %d", math.Round(speed)), "ZCFpv_Beta", sw - 50, sh - 40, clr, 2)

	if droneHasThermal(drone) then
		local col = ZCFpv.MavicNVG and Color(240, 240, 240) or Color(140, 140, 140)
		--draw.SimpleText(ZCFpv.MavicNVG and "THERMAL ON  [N]" or "THERMAL  [N]", "ZCFpv_Beta", cx, sh - 72, col, TEXT_ALIGN_CENTER)
	end
end

local function DrawDigital(drone, sw, sh, cx, cy, sig)
	local vel = drone:GetVelocity()
	local air = math.Round(vel:Length() * 0.09144)
	local gnd = math.Round(Vector(vel.x, vel.y, 0):Length() * 0.09144)
	if not takeOffPos then takeOffPos = drone:GetPos() end
	local alt = math.max(0, math.Round((drone:GetPos().z - takeOffPos.z) / 39.37, 1))

	surface.SetDrawColor(255, 255, 255, 255)
	surface.SetMaterial(M_CH)
	surface.DrawTexturedRect(cx - 32, cy - 32, 64, 64)

	local spdX, spdY = 50, sh - 175
	surface.SetMaterial(M_AIR)
	surface.DrawTexturedRect(spdX, spdY, 40, 26)
	draw.SimpleText(tostring(air), "ZCFpv_OSD", spdX + 120, spdY + 13, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
	surface.SetMaterial(M_KMH)
	surface.DrawTexturedRect(spdX + 125, spdY - 2, 30, 30)
	surface.SetMaterial(M_GND)
	surface.DrawTexturedRect(spdX, spdY + 38, 40, 26)
	draw.SimpleText(tostring(gnd), "ZCFpv_OSD", spdX + 120, spdY + 51, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
	surface.SetMaterial(M_KMH)
	surface.DrawTexturedRect(spdX + 125, spdY + 36, 30, 30)

	local rx = sw - 160
	surface.SetMaterial(M_MM)
	surface.DrawTexturedRect(rx + 10, spdY - 15, 30, 30)
	draw.SimpleText(string.format("%.1f", alt), "ZCFpv_OSD", rx - 10, spdY, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

	local wifiX, wifiY = sw - 120, 40
	surface.SetMaterial(M_WIFI)
	surface.DrawTexturedRect(wifiX, wifiY, 36, 36)
	local bars = sig > 0.85 and M_P4 or sig > 0.65 and M_P3 or sig > 0.4 and M_P2 or sig > 0.2 and M_P1 or M_P0
	surface.SetMaterial(bars)
	surface.DrawTexturedRect(wifiX - 50, wifiY + 4, 44, 28)
	draw.SimpleText(math.floor(sig * 100) .. "%", "ZCFpv_OSD_Sm", wifiX + 18, wifiY + 40, sig < 0.35 and Color(255, 80, 80) or color_white, TEXT_ALIGN_CENTER)

	if droneHasThermal(drone) then
		local col = ZCFpv.MavicNVG and Color(240, 240, 240) or Color(140, 140, 140)
		--draw.SimpleText(ZCFpv.MavicNVG and "THERMAL ON  [N]" or "THERMAL  [N]", "ZCFpv_OSD_Sm", cx, sh - 48, col, TEXT_ALIGN_CENTER)
	end
end

local function enableVHS()
	if not REALISTICVHSEFFECT2_CFG or vhsOn then return end
	vhsOn = true
	RunConsoleCommand("realisticvhseffect2_enabled", "1")
	REALISTICVHSEFFECT2_CFG.channelssettings.chroma_noise_enabled = false
	REALISTICVHSEFFECT2_CFG.channelssettings.luma_noise_enabled = false
	REALISTICVHSEFFECT2_CFG.channelssettings.general_blur = 0.35
	REALISTICVHSEFFECT2_CFG.channelssettings.chroma_blur = 0.8
	REALISTICVHSEFFECT2_CFG.wave.enabled = false
	REALISTICVHSEFFECT2_CFG.lines.enabled = false
	REALISTICVHSEFFECT2_CFG.tubedelay.enabled = false
	REALISTICVHSEFFECT2_CFG.presize = true
	REALISTICVHSEFFECT2_CFG.viewtype = 0
	REALISTICVHSEFFECT2_CFG.sharpen.enabled = false
	REALISTICVHSEFFECT2_CFG.interlaced.enabled = false
	REALISTICVHSEFFECT2_CFG.osd.dateenabled = false
	REALISTICVHSEFFECT2_CFG.osd.vcr_text_enabled = false
	REALISTICVHSEFFECT2_CFG.osd.middletext = nil
	REALISTICVHSEFFECT2_CFG.comets.enabled = false
	if REALISTICVHSEFFECT2_CFG.currenthookclass ~= "RenderScreenspaceEffects" then
		RunConsoleCommand("realisticvhseffect2_changehook", "RenderScreenspaceEffects")
	end
end

local function disableVHS()
	local enabled = GetConVar("realisticvhseffect2_enabled")
	if not vhsOn and (not enabled or not enabled:GetBool()) then return end
	vhsOn = false
	RunConsoleCommand("realisticvhseffect2_enabled", "0")
	if REALISTICVHSEFFECT2_CFG then
		REALISTICVHSEFFECT2_CFG.comets.enabled = false
		REALISTICVHSEFFECT2_CFG.wave.enabled = false
		REALISTICVHSEFFECT2_CFG.lines.enabled = false
		REALISTICVHSEFFECT2_CFG.cameraclrdist.r = 0
		REALISTICVHSEFFECT2_CFG.cameraclrdist.g = 0
		REALISTICVHSEFFECT2_CFG.cameraclrdist.b = 0
		REALISTICVHSEFFECT2_CFG.postclrmod["pp_colour_colour"] = 1
	end
	desatVal = 1
end

local function updateVHS()
	if not REALISTICVHSEFFECT2_CFG or not vhsOn then return end
	REALISTICVHSEFFECT2_CFG.comets.enabled = false
	REALISTICVHSEFFECT2_CFG.interlaced.enabled = false
	REALISTICVHSEFFECT2_CFG.sharpen.enabled = false
	REALISTICVHSEFFECT2_CFG.cameraclrdist.r = 0
	REALISTICVHSEFFECT2_CFG.cameraclrdist.g = 0
	REALISTICVHSEFFECT2_CFG.cameraclrdist.b = 0
	REALISTICVHSEFFECT2_CFG.channelssettings.general_blur = 0.35
	REALISTICVHSEFFECT2_CFG.channelssettings.chroma_blur = 0.8
	REALISTICVHSEFFECT2_CFG.presize = true
	REALISTICVHSEFFECT2_CFG.viewtype = 0
	REALISTICVHSEFFECT2_CFG.wave.enabled = false
	REALISTICVHSEFFECT2_CFG.lines.enabled = false
	if ZCFpv.MavicNVG then
		REALISTICVHSEFFECT2_CFG.postclrmod["pp_colour_colour"] = 0
		return
	end
	if GetConVar("zc_fpv_vhs_desat"):GetBool() then
		local ct = CurTime()
		if ct > desatNext then
			desatEnd = ct + math.Rand(0.5, 1)
			desatNext = ct + math.Rand(8, 25)
		end
		desatVal = Lerp(FrameTime() * 3, desatVal, ct < desatEnd and 0 or 1)
		REALISTICVHSEFFECT2_CFG.postclrmod["pp_colour_colour"] = desatVal
	else
		REALISTICVHSEFFECT2_CFG.postclrmod["pp_colour_colour"] = 1
	end
end

hook.Add("Think", "ZCFpv_ThermalKey", function()
	local down = input.IsKeyDown(KEY_N)
	if down and not thermalKeyDown then
		toggleThermal()
	end
	thermalKeyDown = down
end)

hook.Add("PlayerButtonDown", "ZCFpv_MavicNVG", function(ply, btn)
	if ply ~= LocalPlayer() or btn ~= KEY_N then return end
	toggleThermal()
end)

hook.Add("RenderScreenspaceEffects", "ZCFpv_zMavicNVG", function()
	if not thermalActive() then return end
	DrawColorModify(thermalMod)

	local sw, sh = ScrW(), ScrH()
	surface.SetDrawColor(0, 0, 0, 110)
	surface.DrawRect(0, 0, sw, sh)

	local ns = 16
	local sx, sy = (CurTime() * ns) % 1, (CurTime() * ns * 1.3) % 1
	surface.SetMaterial(M_NOISE)
	surface.SetDrawColor(255, 255, 255, 30)
	surface.DrawTexturedRectUV(0, 0, sw, sh, sx, sy, sx + 1.1, sy + 1.1)
end)

hook.Add("PostDrawEffects", "ZCFpv_ThermalHot", function()
	if not thermalActive() then return end
	collectThermalHot()
	if #thermalHot == 0 then return end

	cam.Start3D(EyePos(), EyeAngles())
		for _, ent in ipairs(thermalHot) do
			paintHotEnt(ent)
		end
	cam.End3D()

	DrawBloom(0.55, 2.4, 10, 10, 2, 1, 1, 1, 1)
end)

hook.Add("PreDrawHalos", "ZCFpv_ThermalHalo", function()
	if not thermalActive() then return end
	if #thermalHot == 0 then collectThermalHot() end
	if #thermalHot == 0 then return end
	halo.Add(thermalHot, Color(255, 255, 255, 220), 3, 3, 2, true, false)
end)

hook.Add("HUDPaint", "ZCFpv_ThermalHUD", function()
	if not thermalActive() then return end
	draw.SimpleText("Thermal vision", "ZCFpv_OSD_Sm", 28, 24, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	draw.SimpleText("FLIR", "ZCFpv_OSD", ScrW() - 28, 22, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
end)

hook.Add("RenderScreenspaceEffects", "ZCFpv_WorldNoise", function()
	local drone = ZCFpv.GetLinkedDrone(LocalPlayer())
	if not IsValid(drone) then return end

	local sig = drone:GetSignal() or 1
	local jam = drone:GetNWFloat("ZCFpvJam", 0)
	updateNoise(sig, jam)
	drone.SmoothNoise = smoothNoise
	if smoothNoise <= 1 then return end

	local sw, sh = ScrW(), ScrH()
	local ns = 25 + (sig < 0.12 and 35 or 0)
	local sx, sy = (CurTime() * ns) % 1, (CurTime() * ns * 1.2) % 1
	surface.SetMaterial(M_NOISE)
	surface.SetDrawColor(255, 255, 255, math.min(smoothNoise, 220))
	surface.DrawTexturedRectUV(0, 0, sw, sh, sx, sy, sx + 1, sy + 1)

	if sig < 0.1 then
		local sx2, sy2 = (CurTime() * -ns * 0.7) % 1, (CurTime() * ns * 2.1) % 1
		surface.SetDrawColor(255, 255, 255, math.min(smoothNoise * 0.55, 160))
		surface.DrawTexturedRectUV(0, 0, sw, sh, sx2, sy2, sx2 + 1.4, sy2 + 1.4)
		for i = 1, 5 do
			surface.SetDrawColor(255, 255, 255, math.random(25, 80))
			surface.DrawRect(0, math.random(0, sh), sw, math.random(1, 3))
		end
	end
end)

function ZCFpv.DrawFPVEffects(drone)
	if not IsValid(drone) then return end

	local sw, sh = ScrW(), ScrH()
	local cx, cy = sw * 0.5, sh * 0.5
	local sig = drone:GetSignal() or 1

	updateNoise(sig, drone:GetNWFloat("ZCFpvJam", 0))
	drone.SmoothNoise = smoothNoise

	if drone.Strike or drone:GetClass() == "ent_zc_fpv_crocus" then
		DrawBetaflight(drone, sw, sh, cx, cy, sig)
	else
		DrawDigital(drone, sw, sh, cx, cy, sig)
	end

	if GetConVar("zc_fpv_vhs"):GetBool() then
		surface.SetDrawColor(0, 0, 0, 255)
		surface.DrawRect(0, 0, 10, sh)
		surface.DrawRect(sw - 10, 0, 10, sh)
		surface.DrawRect(0, 0, sw, 10)
		surface.DrawRect(0, sh - 10, sw, 10)
	end
end

hook.Add("Think", "ZCFpv_VHS", function()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	local drone = ZCFpv.GetLinkedDrone(ply)
	if IsValid(drone) and GetConVar("zc_fpv_vhs"):GetBool() and not ZCFpv.MavicNVG then
		enableVHS()
		updateVHS()
	else
		if not IsValid(drone) then
			takeOffPos = nil
			flightStart = nil
		end
		disableVHS()
	end
end)

hook.Add("HUDPaint", "ZCFpv_OSD", function()
	local drone = ZCFpv.GetLinkedDrone(LocalPlayer())
	if not IsValid(drone) then return end
	ZCFpv.DrawFPVEffects(drone)
end)
