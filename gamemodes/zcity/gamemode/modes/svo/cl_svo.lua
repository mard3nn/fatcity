MODE.name = "svo"
local MODE = MODE

local SVO_LoopStation = nil
local MusicVolume = GetConVar("snd_musicvolume")

local isLocalDrone = false

net.Receive("svo_start", function()
    zb.RemoveFade()
    local myTeam = net.ReadUInt(2)
    isLocalDrone = net.ReadBool()

    sound.PlayFile("sound/resimi_ot_rubi/music1.wav", "noblock", function(station)
        if IsValid(station) then
            SVO_LoopStation = station
            station:SetVolume(1 * MusicVolume:GetFloat())
            station:EnableLooping(false)
        end
    end)
end)

local teams = {
    ["rus"] = { objective = "Уничтожить всех бойцов ВСУ", name = "Российский солдат", color1 = Color(190,0,0), color2 = Color(190,0,0) },
    ["ukr"] = { objective = "Уничтожить всех российских солдат", name = "Украинский солдат", color1 = Color(0,120,255), color2 = Color(0,120,255) },
    ["rus_drone"] = { objective = "Уничтожить всех бойцов ВСУ", name = "Оператор БПЛА РФ", color1 = Color(190,0,0), color2 = Color(190,0,0) },
    ["ukr_drone"] = { objective = "Уничтожить всех российских солдат", name = "Оператор БПЛА ВСУ", color1 = Color(0,120,255), color2 = Color(0,120,255) },
}

net.Receive("svo_zone_init", function()
    ZonePos = net.ReadVector()
    zonedistance = net.ReadFloat()

    sound.PlayFile("sound/ambient/energy/force_field_loop1.wav", "noblock", function(station)
        if IsValid(station) then
            zb.SoundStation = station
            station:Play()
            station:EnableLooping(true)
            station:SetVolume(0)
        end
    end)
end)

hook.Add("Think", "SVO_ZoneSoundThink", function()
    if CurrentRound() and CurrentRound().name ~= "svo" then return end
    local station = zb.SoundStation
    if not IsValid(station) then return end
    local radius = MODE.GetZoneRadius()
    if not radius then return end
    local dist = LocalPlayer():GetPos():Distance(ZonePos)
    local volume = math.Clamp((dist - radius) + 200, 0, 200) / 200
    station:SetVolume(volume)
end)

local mat = Material("hmcd_dmzone")

function MODE:PostDrawTranslucentRenderables(bDepth, bSkybox, isDraw3DSkybox)
    if bSkybox or isDraw3DSkybox then return end
    if not ZonePos or not zonedistance then return end
    local radius = MODE.GetZoneRadius()
    if not radius then return end
    render.SetMaterial(mat)
    render.DrawSphere(ZonePos, -radius, 60, 60, color_white)
end

function MODE:RenderScreenspaceEffects()
    if zb.ROUND_START + 5 < CurTime() then return end
    local fade = math.Clamp(zb.ROUND_START + 3 - CurTime(), 0, 1)
    surface.SetDrawColor(0, 0, 0, 255 * fade)
    surface.DrawRect(-1, -1, ScrW() + 1, ScrH() + 1)
end

function MODE:HUDPaint()
    if zb.ROUND_START + 6 < CurTime() then return end
    if not LocalPlayer():Alive() then return end
    zb.RemoveFade()
    local fade = math.Clamp(zb.ROUND_START + 6 - CurTime(), 0, 1)
    local ply = LocalPlayer()
    local team = ply:Team()
    if team ~= 0 and team ~= 1 then return end

    local roleKey
    if isLocalDrone then
        roleKey = (team == 0) and "rus_drone" or "ukr_drone"
    else
        roleKey = (team == 0) and "rus" or "ukr"
    end
    local teamInfo = teams[roleKey]
    if not teamInfo then return end

    draw.SimpleText("Война в Украине", "ZB_HomicideMediumLarge", ScrW() * 0.5, ScrH() * 0.1, Color(0, 162, 255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    local ColorRole = teamInfo.color1
    ColorRole.a = 255 * fade
    draw.SimpleText("Вы " .. teamInfo.name, "ZB_HomicideMediumLarge", ScrW() * 0.5, ScrH() * 0.5, ColorRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    local ColorObj = teamInfo.color2
    ColorObj.a = 255 * fade
    draw.SimpleText(teamInfo.objective, "ZB_HomicideMedium", ScrW() * 0.5, ScrH() * 0.9, ColorObj, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

local CreateEndMenu
net.Receive("svo_roundend", function()
    if IsValid(SVO_LoopStation) then SVO_LoopStation:Stop() end
    CreateEndMenu()
end)

local colGray = Color(85, 85, 85, 255)
local colRed = Color(130, 10, 10)
local colRedUp = Color(160, 30, 30)
local colBlue = Color(0, 120, 255)
local colBlueUp = Color(40, 120, 255)
local col = Color(255, 255, 255, 255)
local colSpect1 = Color(75, 75, 75, 255)
local colSpect2 = Color(255, 255, 255)

BlurBackground = BlurBackground or hg.DrawBlur

if IsValid(hmcdEndMenu) then
    hmcdEndMenu:Remove()
    hmcdEndMenu = nil
end

CreateEndMenu = function()
    if IsValid(hmcdEndMenu) then
        hmcdEndMenu:Remove()
        hmcdEndMenu = nil
    end

    hmcdEndMenu = vgui.Create("ZFrame")
    surface.PlaySound("ambient/alarms/warningbell1.wav")
    local sizeX, sizeY = ScrW() / 2.5, ScrH() / 1.2
    local posX, posY = ScrW() / 1.3 - sizeX / 2, ScrH() / 2 - sizeY / 2
    hmcdEndMenu:SetPos(posX, posY)
    hmcdEndMenu:SetSize(sizeX, sizeY)
    hmcdEndMenu:MakePopup()
    hmcdEndMenu:SetKeyboardInputEnabled(false)
    hmcdEndMenu:ShowCloseButton(false)

    local closebutton = vgui.Create("DButton", hmcdEndMenu)
    closebutton:SetPos(5, 5)
    closebutton:SetSize(ScrW() / 20, ScrH() / 30)
    closebutton:SetText("")
    closebutton.DoClick = function()
        if IsValid(hmcdEndMenu) then
            hmcdEndMenu:Close()
            hmcdEndMenu = nil
        end
    end
    closebutton.Paint = function(self, w, h)
        surface.SetDrawColor(122, 122, 122, 255)
        surface.DrawOutlinedRect(0, 0, w, h, 2.5)
        surface.SetFont("ZB_InterfaceMedium")
        surface.SetTextColor(col.r, col.g, col.b, col.a)
        local lenX, lenY = surface.GetTextSize("Close")
        surface.SetTextPos(lenX - lenX / 1.1, 4)
        surface.DrawText("Close")
    end

    hmcdEndMenu.Paint = function(self, w, h)
        BlurBackground(self)
        surface.SetFont("ZB_InterfaceMediumLarge")
        surface.SetTextColor(col.r, col.g, col.b, col.a)
        local lenX, lenY = surface.GetTextSize("Players:")
        surface.SetTextPos(w / 2 - lenX / 2, 20)
        surface.DrawText("Players:")
        surface.SetDrawColor(255, 0, 0, 128)
        surface.DrawOutlinedRect(0, 0, w, h, 2.5)
    end

    local DScrollPanel = vgui.Create("DScrollPanel", hmcdEndMenu)
    DScrollPanel:SetPos(10, 80)
    DScrollPanel:SetSize(sizeX - 20, sizeY - 90)
    function DScrollPanel:Paint(w, h)
        BlurBackground(self)
        surface.SetDrawColor(255, 0, 0, 128)
        surface.DrawOutlinedRect(0, 0, w, h, 2.5)
    end

    for _, ply in ipairs(player.GetAll()) do
        if ply:Team() == TEAM_SPECTATOR then continue end
        local but = vgui.Create("DButton", DScrollPanel)
        but:SetSize(100, 50)
        but:Dock(TOP)
        but:DockMargin(8, 6, 8, -1)
        but:SetText("")
        but.Paint = function(self, w, h)
            if not IsValid(ply) then return end
            local col1, col2
            if ply:Alive() then
                if ply:Team() == 0 then
                    col1, col2 = colRed, colRedUp
                else
                    col1, col2 = colBlue, colBlueUp
                end
            else
                col1, col2 = colGray, colSpect1
            end
            surface.SetDrawColor(col1.r, col1.g, col1.b, col1.a)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(col2.r, col2.g, col2.b, col2.a)
            surface.DrawRect(0, h / 2, w, h / 2)
            local pcol = ply:GetPlayerColor():ToColor()
            surface.SetFont("ZB_InterfaceMediumLarge")
            local name = ply:GetPlayerName() or "He quit..."
            local nameW, nameH = surface.GetTextSize(name)
            surface.SetTextColor(0, 0, 0, 255)
            surface.SetTextPos(w / 2 + 1, h / 2 - nameH / 2 + 1)
            surface.DrawText(name)
            surface.SetTextColor(pcol.r, pcol.g, pcol.b, pcol.a)
            surface.SetTextPos(w / 2, h / 2 - nameH / 2)
            surface.DrawText(name)
            surface.SetFont("ZB_InterfaceMediumLarge")
            surface.SetTextColor(colSpect2.r, colSpect2.g, colSpect2.b, colSpect2.a)
            local info = ply:Name() .. (not ply:Alive() and " - died" or "")
            surface.SetTextPos(15, h / 2 - nameH / 2)
            surface.DrawText(info)
            local frags = ply:Frags() or 0
            local fragW, fragH = surface.GetTextSize(tostring(frags))
            surface.SetTextPos(w - fragW - 15, h / 2 - fragH / 2)
            surface.DrawText(frags)
        end
        but.DoClick = function()
            if not IsValid(ply) then return end
            if ply:IsBot() then
                chat.AddText(Color(255, 0, 0), "no, you can't")
                return
            end
            gui.OpenURL("https://steamcommunity.com/profiles/" .. ply:SteamID64())
        end
        DScrollPanel:AddItem(but)
    end
    return true
end

function MODE:RoundStart()
    if IsValid(hmcdEndMenu) then
        hmcdEndMenu:Remove()
        hmcdEndMenu = nil
    end
end