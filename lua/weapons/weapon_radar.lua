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

SWEP.NextScanTime = 0
SWEP.ScanState = "idle"
SWEP.ScanStartTime = 0
SWEP.ScanDuration = 0
SWEP.LockedPlayer = nil
SWEP.NextPingTime = 0
SWEP.LastDist = 0
SWEP.PulseAlpha = 0

function SWEP:Think()
    if not CLIENT or not IsValid(self:GetOwner()) or self:GetOwner() ~= LocalPlayer() then return end
    local curTime = CurTime()

    if self.ScanState == "idle" and curTime >= self.NextScanTime then
        self.ScanState = "scanning"
        self.ScanStartTime = curTime
        self.ScanDuration = 3 + math.Rand(0, 2)
        self.LockedPlayer = nil
    elseif self.ScanState == "scanning" then
        if curTime - self.ScanStartTime >= self.ScanDuration then
            local nearest, nearestDist = nil, math.huge
            local myPos = LocalPlayer():GetPos()
            for _, ply in ipairs(player.GetAll()) do
                if ply ~= LocalPlayer() and ply:Alive() and ply:Health() > 0 and ply:Team() ~= LocalPlayer():Team() then
                    local dist = myPos:Distance(ply:GetPos()) / 52.5
                    if dist < nearestDist then
                        nearestDist = dist; nearest = ply
                    end
                end
            end
            if nearest then
                self.ScanState = "locked"
                self.LockedPlayer = nearest
                self.LastDist = math.Round(nearestDist)
                self.NextPingTime = curTime + 3
                self.PulseAlpha = 255
                surface.PlaySound("buttons/button14.wav")
            else
                self.ScanState = "idle"
                self.NextScanTime = curTime + 2
            end
        end
    elseif self.ScanState == "locked" then
        if not IsValid(self.LockedPlayer) or not self.LockedPlayer:Alive() or self.LockedPlayer:Health() <= 0 or self.LockedPlayer:Team() == LocalPlayer():Team() then
            self.ScanState = "idle"
            self.NextScanTime = curTime + 1
            self.LockedPlayer = nil
        elseif curTime >= self.NextPingTime then
            local dist = LocalPlayer():GetPos():Distance(self.LockedPlayer:GetPos()) / 52.5
            self.LastDist = math.Round(dist)
            self.NextPingTime = curTime + 3
            self.PulseAlpha = 255
            surface.PlaySound("buttons/button14.wav")
        end
    end

    self.PulseAlpha = math.max(0, self.PulseAlpha - FrameTime() * 300)
end

function SWEP:AddDrawModel(ent)
    if not IsValid(self:GetOwner()) or not self:GetOwner() == LocalPlayer() then return end
    local pos, ang = ent:GetRenderOrigin(), ent:GetRenderAngles()
    pos = pos + ang:Up() * 0.7 + ang:Forward() * -3.4 + ang:Right() * -2.2
    local scale = 0.013
    vgui.Start3D2D(pos, ang, scale)
    local w, h = 570, 320
    local t = RealTime()

    draw.RoundedBox(0, 0, 0, w, h, Color(10, 12, 20, 255))
    surface.SetDrawColor(30, 40, 60, 255)
    surface.DrawOutlinedRect(0, 0, w, h)

    local cx, cy = w/2, h/2

    if self.ScanState == "idle" then
        draw.SimpleText("ПОИСК ЦЕЛИ...", "GOMI_SettingsCat", w/2, cy, Color(100, 100, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    elseif self.ScanState == "scanning" then
        local progress = (CurTime() - self.ScanStartTime) / self.ScanDuration
        local dots = math.floor(progress * 6) % 3 + 1
        local loading = string.rep(".", dots)
        draw.SimpleText("Ищем" .. loading, "GOMI_SettingsCat", w/2, cy - 10, Color(60, 130, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(math.Round(progress * 100) .. "%", "GOMI_SettingsHelp", w/2, cy + 30, Color(100, 140, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    elseif self.ScanState == "locked" and IsValid(self.LockedPlayer) then
        local distText = self.LastDist .. " m"
        local textCol = self.LastDist < 20 and Color(255, 80, 80) or self.LastDist < 50 and Color(255, 200, 60) or Color(60, 255, 80)
        draw.SimpleText(distText, "GOMI_Title", w/2, cy - 16, textCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(self.LockedPlayer:Nick(), "GOMI_SettingsHelp", w/2, cy + 60, Color(180, 180, 180), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) // пенисолюбабба богдан канарейка

        local nextPing = math.max(0, math.Round(self.NextPingTime - CurTime()))
        draw.SimpleText("Возможный сигнал: " .. nextPing .. "с", "GOMI_SettingsHelp", w/2, h - 15, Color(100, 140, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    vgui.End3D2D()
end
