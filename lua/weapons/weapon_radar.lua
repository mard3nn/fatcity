if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_tpik1_base"
SWEP.PrintName = "Radar"
SWEP.Instructions = ""
SWEP.Category = "Weapons - Other"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Slot = 1

if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/wep_jack_hmcd_phone")
	SWEP.IconOverride = "vgui/wep_jack_hmcd_phone"
	SWEP.BounceWeaponIcon = false
end

SWEP.Weight = 0
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo = "none"

SWEP.WorldModel = "models/inside/iiphone5.mdl"
SWEP.ViewModel = ""
SWEP.HoldType = "normal"

SWEP.setrhik = true
SWEP.setlhik = false

SWEP.LHPos = Vector(0,-6.6,0)
SWEP.LHAng = Angle(0,0, 80)

SWEP.RHPosOffset = Vector(2,2,-3)
SWEP.RHAngOffset = Angle(0,10,-80)

SWEP.LHPosOffset = Vector(0,0,-0.4)
SWEP.LHAngOffset = Angle(5,0,15)

SWEP.handPos = Vector(0,0,0)
SWEP.handAng = Angle(0,0,0)

SWEP.UsePistolHold = false

SWEP.offsetVec = Vector(4,-6,-1)
SWEP.offsetAng = Angle(10,90,200)

SWEP.HeadPosOffset = Vector(10,1,-4)
SWEP.HeadAngOffset = Angle(-90,0,-90)

SWEP.BaseBone = "ValveBiped.Bip01_Head1"

SWEP.HoldLH = "normal"
SWEP.HoldRH = "normal"

SWEP.HoldClampMax = 35
SWEP.HoldClampMin = 35

SWEP.Skin = 0

function SWEP:PrimaryAttack() end
function SWEP:SecondaryAttack() end

if SERVER then return end

surface.CreateFont("Radar_Big", {font = "Bahnschrift", size = 72, weight = 700, antialias = true})
surface.CreateFont("Radar_Med", {font = "Bahnschrift", size = 36, weight = 600, antialias = true})
surface.CreateFont("Radar_Small", {font = "Bahnschrift", size = 24, weight = 400, antialias = true})

local PING_MIN, PING_MAX = 2, 4
local function NextPingDelay()
	return math.Rand(PING_MIN, PING_MAX)
end

local OFFSET_LIMIT = 6           
local DIST_MIN, DIST_MAX = -2, 10

local BASE_HEAD_POS = Vector(10, 1, -4)



local function DrawFilledCircle(x, y, radius, seg, color)
	local poly = {}
	for i = 0, seg do
		local a = math.rad((i / seg) * 360)
		poly[#poly + 1] = {x = x + math.sin(a) * radius, y = y + math.cos(a) * radius}
	end
	draw.NoTexture()
	surface.SetDrawColor(color)
	surface.DrawPoly(poly)
end

SWEP.NextScanTime = 0
SWEP.ScanState = "idle"
SWEP.ScanStartTime = 0
SWEP.ScanDuration = 0
SWEP.LockedPlayer = nil
SWEP.NextPingTime = 0
SWEP.LastDist = 0
SWEP.PulseAlpha = 0

SWEP.ManualOffsetX = 0
SWEP.ManualOffsetY = 0
SWEP.ManualDist = 0

function SWEP:GetValidTargets()
	local lp = LocalPlayer()
	if not IsValid(lp) then return {} end

	local targets = {}
	local is_hmcd = (zb and zb.CROUND == "hmcd")
	local mode = is_hmcd and zb.modes and zb.modes["hmcd"] or nil
	local traitor_mode = is_hmcd and lp.isTraitor and mode

	for _, ply in ipairs(player.GetAll()) do
		if ply == lp then continue end
		if not IsValid(ply) or not ply:Alive() or ply:Health() <= 0 then continue end

		if traitor_mode then
			local is_teammate = false
			if mode.AllTraitors then
				for _, info in ipairs(mode.AllTraitors) do
					if info[3] == ply:UserID() then
						is_teammate = true
						break
					end
				end
			end
			if is_teammate then continue end
		else
			if ply:Team() == lp:Team() then continue end
		end

		targets[#targets + 1] = ply
	end

	return targets
end

function SWEP:IsTargetValid(ply)
	if not IsValid(ply) or not ply:Alive() or ply:Health() <= 0 then return false end
	for _, valid in ipairs(self:GetValidTargets()) do
		if valid == ply then return true end
	end
	return false
end

function SWEP:CycleTarget()
	if self.ScanState ~= "locked" then return end

	local targets = self:GetValidTargets()
	if #targets == 0 then return end

	local idx = 0
	for i, ply in ipairs(targets) do
		if ply == self.LockedPlayer then
			idx = i
			break
		end
	end

	idx = idx % #targets + 1
	self.LockedPlayer = targets[idx]

	self.ScanState = "switching"
	self.ScanStartTime = CurTime()
	self.ScanDuration = 1.5

	surface.PlaySound("buttons/lightswitch2.wav")
end

function SWEP:SecondaryAttack()
	if not IsFirstTimePredicted() then return end
	self:SetNextSecondaryFire(CurTime() + 0.25)
	self:CycleTarget()
end

function SWEP:Think()
	if not IsValid(self:GetOwner()) or self:GetOwner() ~= LocalPlayer() then return end
	local curTime = CurTime()

	if self.ScanState == "idle" and curTime >= self.NextScanTime then
		self.ScanState = "scanning"
		self.ScanStartTime = curTime
		self.ScanDuration = 2 + math.Rand(0, 1.5)
		self.LockedPlayer = nil
	elseif self.ScanState == "scanning" then
		if curTime - self.ScanStartTime >= self.ScanDuration then
			local nearest, nearestDist = nil, math.huge
			local myPos = LocalPlayer():GetPos()

			for _, ply in ipairs(self:GetValidTargets()) do
				local dist = myPos:Distance(ply:GetPos()) / 52.5
				if dist < nearestDist then
					nearestDist = dist
					nearest = ply
				end
			end

			if nearest then
				self.ScanState = "locked"
				self.LockedPlayer = nearest
				self.LastDist = math.Round(nearestDist)
				self.NextPingTime = curTime + NextPingDelay()
				self.PulseAlpha = 255
				surface.PlaySound("buttons/button14.wav")
			else
				self.ScanState = "idle"
				self.NextScanTime = curTime + NextPingDelay()
			end
		end
	elseif self.ScanState == "switching" then
		if curTime - self.ScanStartTime >= self.ScanDuration then
			if self:IsTargetValid(self.LockedPlayer) then
				self.ScanState = "locked"
				local dist = LocalPlayer():GetPos():Distance(self.LockedPlayer:GetPos()) / 52.5
				self.LastDist = math.Round(dist)
				self.NextPingTime = curTime + NextPingDelay()
				self.PulseAlpha = 255
				surface.PlaySound("buttons/button14.wav")
			else
				self.ScanState = "idle"
				self.NextScanTime = curTime + 1
				self.LockedPlayer = nil
			end
		end
	elseif self.ScanState == "locked" then
		if not self:IsTargetValid(self.LockedPlayer) then
			self.ScanState = "idle"
			self.NextScanTime = curTime + 1
			self.LockedPlayer = nil
		elseif curTime >= self.NextPingTime then
			local dist = LocalPlayer():GetPos():Distance(self.LockedPlayer:GetPos()) / 52.5
			self.LastDist = math.Round(dist)
			self.NextPingTime = curTime + NextPingDelay()
			self.PulseAlpha = 255
			surface.PlaySound("buttons/button14.wav")
		end
	end

	self.PulseAlpha = math.max(0, self.PulseAlpha - FrameTime() * 300)
end

local function DistColor(d)
	if d < 20 then return Color(255, 80, 80) end
	if d < 50 then return Color(255, 200, 60) end
	return Color(60, 255, 120)
end

local function DrawScanning(cx, label, startTime, duration)
	local progress = math.Clamp((CurTime() - startTime) / duration, 0, 1)
	local dots = string.rep(".", math.floor(progress * 6) % 3 + 1)
	draw.SimpleText(label .. dots, "Radar_Med", cx, 130, Color(70, 150, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	local bw, bh = 320, 16
	local bx, by = cx - bw / 2, 180
	draw.RoundedBox(4, bx, by, bw, bh, Color(20, 30, 40, 255))
	draw.RoundedBox(4, bx, by, bw * progress, bh, Color(70, 150, 255, 255))
	draw.SimpleText(math.Round(progress * 100) .. "%", "Radar_Small", cx, by + bh + 22, Color(100, 150, 210), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

function SWEP:DrawScreen()
	local w, h = 570, 320
	local t = RealTime()
	local cx = w / 2
	local busy = (self.ScanState == "scanning" or self.ScanState == "switching")

	draw.RoundedBox(14, 0, 0, w, h, Color(8, 12, 18, 250))
	draw.RoundedBox(14, 4, 4, w - 8, h - 8, Color(14, 20, 28, 255))

	surface.SetDrawColor(40, 90, 70, 255)
	surface.DrawOutlinedRect(4, 4, w - 8, h - 8, 2)

	local dotCol = self.ScanState == "locked" and Color(90, 230, 150) or busy and Color(70, 150, 255) or Color(120, 120, 120)
	local blink = busy and (0.5 + 0.5 * math.sin(t * 8)) or 1
	DrawFilledCircle(cx, 46, 8, 16, Color(dotCol.r, dotCol.g, dotCol.b, 255 * blink))

	if self.ScanState == "idle" then
		draw.SimpleText("ПОИСК ЦЕЛИ", "Radar_Med", cx, h / 2, Color(120, 120, 120), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	elseif self.ScanState == "scanning" then
		DrawScanning(cx, "Ищем", self.ScanStartTime, self.ScanDuration)

	elseif self.ScanState == "switching" then
		DrawScanning(cx, "Ищем другую цель", self.ScanStartTime, self.ScanDuration)

	elseif self.ScanState == "locked" and IsValid(self.LockedPlayer) then
		local col = DistColor(self.LastDist)

		draw.SimpleText(self.LastDist .. " m", "Radar_Big", cx, 130, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText(self.LockedPlayer:Nick(), "Radar_Small", cx, 190, Color(190, 190, 190), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		-- rubi xuilo
		local nextPing = math.max(0, math.Round(self.NextPingTime - CurTime()))
		draw.SimpleText("Сигнал через: " .. nextPing .. "с", "Radar_Small", cx, 222, Color(110, 150, 110), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		surface.SetDrawColor(40, 90, 70, 120)
		surface.DrawLine(16, h - 34, w - 16, h - 34)
		draw.SimpleText("ПКМ — следующая цель", "Radar_Small", cx, h - 18, Color(120, 150, 130), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end

function SWEP:ApplyManualMove(dx, dy)
	self.ManualOffsetX = math.Clamp(self.ManualOffsetX - dx * 0.01, -OFFSET_LIMIT, OFFSET_LIMIT)
	self.ManualOffsetY = math.Clamp(self.ManualOffsetY - dy * 0.01, -OFFSET_LIMIT, OFFSET_LIMIT)
	self:RefreshHeadOffset()
end

function SWEP:RefreshHeadOffset()
	self.HeadPosOffset = Vector(
		BASE_HEAD_POS.x + self.ManualDist,
		BASE_HEAD_POS.y + self.ManualOffsetX,
		BASE_HEAD_POS.z + self.ManualOffsetY
	)
end

function SWEP:AddDrawModel(ent)
	if not IsValid(self:GetOwner()) or self:GetOwner() ~= LocalPlayer() then return end

	self:RefreshHeadOffset()

	local pos, ang = ent:GetRenderOrigin(), ent:GetRenderAngles()
	pos = pos + ang:Up() * 0.7 + ang:Forward() * -3.4 + ang:Right() * -2.2
	local scale = 0.013

	vgui.Start3D2D(pos, ang, scale)
		self:DrawScreen()
	vgui.End3D2D()
end

hook.Add("HG.InputMouseApply", "RadarManualControl", function(tbl)
	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	local wep = ply:GetActiveWeapon()
	if not IsValid(wep) or wep:GetClass() ~= "weapon_radar" then return end
	if not input.IsKeyDown(KEY_R) then return end

	wep:ApplyManualMove(tbl.x, tbl.y)

	tbl.x = 0
	tbl.y = 0
end)

hook.Add("PlayerBindPress", "RadarManualZoom", function(ply, bind, pressed)
	if not IsValid(ply) or ply ~= LocalPlayer() then return end
	if not input.IsKeyDown(KEY_R) then return end

	local wep = ply:GetActiveWeapon()
	if not IsValid(wep) or wep:GetClass() ~= "weapon_radar" then return end

	if bind == "invnext" then
		wep.ManualDist = math.Clamp((wep.ManualDist or 0) - 1, DIST_MIN, DIST_MAX)
		return true
	elseif bind == "invprev" then
		wep.ManualDist = math.Clamp((wep.ManualDist or 0) + 1, DIST_MIN, DIST_MAX)
		return true
	end
end)
