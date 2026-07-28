MODE.name = "slovopacana"
local MODE = MODE

local MusicVolume = GetConVar("snd_musicvolume")
local roundMusic = nil

local teams = {
    [0] = {
        name = "Чайники",
        color = Color(210, 120, 40),
        objective = "Уничтожьте Братву"
    },
    [1] = {
        name = "Братва",
        color = Color(40, 130, 220),
        objective = "Уничтожьте Чайников"
    }
}

local policeTimerSlideStart = 0
local posaddPolice = 0
local wasPoliceTimerActive = false

local policeArrivedActive = false
local policeArrivedTime = 0
local posaddPoliceArrived = 0

local CreateEndMenu

net.Receive("slovopacana_roundend", function()
    if IsValid(roundMusic) then
        roundMusic:Stop()
        roundMusic = nil
    end
    policeArrivedActive = false
    posaddPolice = 0
    posaddPoliceArrived = 0
    wasPoliceTimerActive = false
    CreateEndMenu()
end)

net.Receive("slovopacana_PoliceArrived", function()
    policeArrivedActive = true
    policeArrivedTime = CurTime()
    wasPoliceTimerActive = false
end)

function MODE:RenderScreenspaceEffects()
    if zb.ROUND_START + 7 < CurTime() then return end
    local fade = math.Clamp(zb.ROUND_START + 7 - CurTime(), 0, 1)
    surface.SetDrawColor(0, 0, 0, 255 * fade)
    surface.DrawRect(-1, -1, ScrW() + 1, ScrH() + 1)
end

local function DrawFriendlyMarkers()
    if not IsValid(lply) then return end
    local myTeam = lply:Team()
    if myTeam == TEAM_SPECTATOR then return end

    for _, ply in player.Iterator() do
        if ply == lply then continue end
        if not ply:Alive() then continue end
        if ply:Team() ~= myTeam then continue end

        local dist = lply:GetPos():Distance(ply:GetPos())
        if dist > 2600 then continue end

        local screenPos = (ply:GetPos() + Vector(0, 0, 82)):ToScreen()
        if not screenPos.visible then continue end

        local alpha = math.Clamp(255 - dist * 0.07, 80, 255)
        local text = "СВОЙ"

        surface.SetFont("ZB_InterfaceMedium")
        local tw, th = surface.GetTextSize(text)
        local bw, bh = tw + 16, th + 8
        local bx, by = screenPos.x - bw * 0.5, screenPos.y - 42

        draw.RoundedBox(6, bx, by, bw, bh, Color(25, 120, 25, alpha))
        surface.SetDrawColor(80, 255, 80, alpha)
        surface.DrawOutlinedRect(bx, by, bw, bh, 2)

        draw.SimpleText(text, "ZB_InterfaceMedium", screenPos.x, by + bh * 0.5, Color(210, 255, 210, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        local y = by + bh
        surface.DrawLine(screenPos.x, y, screenPos.x - 6, y + 9)
        surface.DrawLine(screenPos.x, y, screenPos.x + 6, y + 9)
        surface.DrawLine(screenPos.x - 6, y + 9, screenPos.x + 6, y + 9)
    end
end

function MODE:HUDPaint()
    if not IsValid(lply) then lply = LocalPlayer() end
    if not IsValid(lply) or not lply:Alive() then return end

    DrawFriendlyMarkers()

    local curTime = CurTime()
    local roundStart = zb.ROUND_START

    if policeArrivedActive then
        local timeSinceArrived = curTime - policeArrivedTime
        local target

        if timeSinceArrived < 10 then
            target = 0
        else
            target = -ScrW() * 0.4
        end

        posaddPoliceArrived = Lerp(FrameTime() * 5, posaddPoliceArrived, target)

        if timeSinceArrived > 11 and posaddPoliceArrived < -ScrW() * 0.39 then
            policeArrivedActive = false
            return
        end

        local color = Color(255 * -math.sin(curTime * 3), 25, 255 * math.sin(curTime * 3))
        draw.SimpleText("Полиция прибыла на место!", "ZB_HomicideMedium",
            ScrW() * 0.02 + posaddPoliceArrived, ScrH() * 0.95,
            Color(0, 0, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("Полиция прибыла на место!", "ZB_HomicideMedium",
            (ScrW() * 0.02) - 1 + posaddPoliceArrived, (ScrH() * 0.95) - 2,
            color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        return
    end

    local timerActive = (roundStart + 30 < curTime) and (roundStart + 150 > curTime)

    if timerActive and not wasPoliceTimerActive then
        policeTimerSlideStart = curTime
    end
    wasPoliceTimerActive = timerActive

    if timerActive then
        local remaining = math.max(0, roundStart + 150 - curTime)
        local slideElapsed = curTime - policeTimerSlideStart
        local target = slideElapsed > 1 and 0 or -ScrW() * 0.4
        posaddPolice = Lerp(FrameTime() * 5, posaddPolice or 0, target)

        local color = Color(255 * -math.sin(curTime * 3), 25, 255 * math.sin(curTime * 3))
        local timeText = string.FormattedTime(remaining, "%02i:%02i")
        draw.SimpleText("Полиция прибудет через: " .. timeText, "ZB_HomicideMedium",
            ScrW() * 0.02 + posaddPolice, ScrH() * 0.95,
            Color(0, 0, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("Полиция прибудет через: " .. timeText, "ZB_HomicideMedium",
            (ScrW() * 0.02) - 1 + posaddPolice, (ScrH() * 0.95) - 2,
            color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    if roundStart + 8 < curTime then return end

    local fade = math.Clamp(roundStart + 8 - curTime, 0, 1)
    local w, h = ScrW(), ScrH()
    local teamData = teams[lply:Team()] or teams[0]

    draw.SimpleText("GOMICITY | СЛОВО ПАЦАНА", "ZB_HomicideMediumLarge", w * 0.5, h * 0.1, Color(0, 162, 255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText("Ваша команда: " .. teamData.name, "ZB_HomicideMediumLarge", w * 0.5, h * 0.5, Color(teamData.color.r, teamData.color.g, teamData.color.b, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText(teamData.objective, "ZB_HomicideMedium", w * 0.5, h * 0.9, Color(255, 255, 255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

local spEndMenu

local function CloseEndMenu()
    if IsValid(spEndMenu) then
        spEndMenu:Close()
        spEndMenu = nil
    end
end

CreateEndMenu = function()
    CloseEndMenu()

    surface.PlaySound("ambient/alarms/warningbell1.wav")

    spEndMenu = vgui.Create("ZFrame")
    local frame = spEndMenu

    local sizeX, sizeY = ScrW() / 2.5, ScrH() / 1.2
    local posX, posY = ScrW() / 1.3 - sizeX / 2, ScrH() / 2 - sizeY / 2

    frame:SetPos(posX, posY)
    frame:SetSize(sizeX, sizeY)
    frame:MakePopup()
    frame:SetKeyboardInputEnabled(false)
    frame:ShowCloseButton(false)

    local closebutton = vgui.Create("DButton", frame)
    closebutton:SetPos(5, 5)
    closebutton:SetSize(ScrW() / 20, ScrH() / 30)
    closebutton:SetText("")
    closebutton.DoClick = function()
        CloseEndMenu()
    end
    closebutton.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, Color(28, 28, 28, 235))
        surface.SetDrawColor(180, 40, 40, 180)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText("Закрыть", "ZB_InterfaceMedium", w * 0.5, h * 0.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    frame.Paint = function(self, w, h)
        hg.DrawBlur(self)
        draw.RoundedBox(12, 0, 0, w, h, Color(255, 0, 0, 65))
        draw.RoundedBox(10, 2, 2, w - 4, h - 4, Color(0, 0, 0, 185))

        draw.SimpleText("Слово пацана", "ZB_InterfaceMediumLarge", w * 0.5, 18, color_white, TEXT_ALIGN_CENTER)
        draw.SimpleText("Игроки:", "ZB_InterfaceMediumLarge", w * 0.5, 44, color_white, TEXT_ALIGN_CENTER)
    end

    local list = vgui.Create("DScrollPanel", frame)
    list:SetPos(10, 80)
    list:SetSize(sizeX - 20, sizeY - 90)
    list.Paint = function(self, w, h)
        hg.DrawBlur(self)
        draw.RoundedBox(10, 0, 0, w, h, Color(255, 0, 0, 55))
        draw.RoundedBox(8, 2, 2, w - 4, h - 4, Color(0, 0, 0, 120))
    end

    for _, ply in player.Iterator() do
        if ply:Team() == TEAM_SPECTATOR then continue end

        local item = vgui.Create("DButton", list)
        item:SetSize(100, 50)
        item:Dock(TOP)
        item:DockMargin(8, 6, 8, 4)
        item:SetText("")

        item.Paint = function(self, w, h)
            if not IsValid(ply) then return end
            local t = teams[ply:Team()] or teams[0]
            local base = ply:Alive() and Color(t.color.r, t.color.g, t.color.b, 220) or Color(85, 85, 85, 255)
            local lower = ply:Alive() and Color(math.max(t.color.r - 20, 0), math.max(t.color.g - 20, 0), math.max(t.color.b - 20, 0), 255) or Color(70, 70, 70, 255)

            draw.RoundedBox(8, 0, 0, w, h, base)
            draw.RoundedBoxEx(8, 0, h * 0.5, w, h * 0.5, lower, false, false, true, true)
            surface.SetDrawColor(0, 0, 0, 120)
            surface.DrawOutlinedRect(0, 0, w, h, 1)

            local name = ply:IsValid() and ply:Name() or "Отключился"
            if not ply:Alive() then
                name = name .. " - мертв"
            end

            surface.SetFont("ZB_InterfaceMediumLarge")
            surface.SetTextColor(255, 255, 255, 255)
            local nw, nh = surface.GetTextSize(name)
            surface.SetTextPos(15, h * 0.5 - nh * 0.5)
            surface.DrawText(name)

            local frags = tostring(ply:Frags() or 0)
            local fw, fh = surface.GetTextSize(frags)
            surface.SetTextPos(w - fw - 15, h * 0.5 - fh * 0.5)
            surface.DrawText(frags)
        end

        item.DoClick = function()
            if ply:IsBot() then return end
            gui.OpenURL("https://steamcommunity.com/profiles/" .. ply:SteamID64())
        end

        list:AddItem(item)
    end
end

function MODE:RoundStart()
    CloseEndMenu()
    policeArrivedActive = false
    posaddPolice = 0
    posaddPoliceArrived = 0
    wasPoliceTimerActive = false

    sound.PlayFile("sound/resimi_ot_rubi/clovo_pacana.mp3", "noblock", function(station)
        if IsValid(station) then
            roundMusic = station
            station:SetVolume(1 * MusicVolume:GetFloat())
            station:EnableLooping(true)
            station:Play()
        end
    end)
end