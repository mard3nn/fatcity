MODE.name = "protocol01"
local MODE = MODE

local MusicVolume = GetConVar("snd_musicvolume")
local circles = {}

surface.CreateFont("TCK_TimesNewRoman", {
    font = "Times New Roman",
    size = 32,
    weight = 500,
    antialias = true,
    bold = true,
})

net.Receive("protocol01_start", function()
    zb.RemoveFade()
    local myTeam = net.ReadUInt(2)

    circles = {}
    local count = net.ReadUInt(4)
    for i = 1, count do
        table.insert(circles, {
            center = net.ReadVector(),
            radius = net.ReadFloat()
        })
    end

    sound.PlayFile("sound/resimi_ot_rubi/music2.wav", "noblock", function(station)
        if IsValid(station) then
            station:SetVolume(1 * MusicVolume:GetFloat())
            station:EnableLooping(false)
            station:Play()
        end
    end)
end)

local teams = {
    [0] = { objective = "Выживите и не попадитесь ТЦК!", name = "Гражданский", color1 = Color(0,200,0), color2 = Color(0,200,0) },
    [1] = { objective = "Задержите всех гражданских!", name = "Оперативник ТЦК", color1 = Color(0,100,0), color2 = Color(0,100,0) },
}

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
    local team_ = LocalPlayer():Team()
    if team_ ~= 0 and team_ ~= 1 then return end

    draw.SimpleText("GOMICITY | ПРОТОКОЛ 01 — ЗАДЕРЖАНИЕ", "ZB_HomicideMediumLarge", ScrW() * 0.5, ScrH() * 0.1, Color(0, 162, 255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    local rolename = teams[team_].name
    local colorRole = teams[team_].color1
    colorRole.a = 255 * fade
    draw.SimpleText("Вы " .. rolename, "ZB_HomicideMediumLarge", ScrW() * 0.5, ScrH() * 0.5, colorRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    local objective = teams[team_].objective
    local colorObj = teams[team_].color2
    colorObj.a = 255 * fade
    draw.SimpleText(objective, "ZB_HomicideMedium", ScrW() * 0.5, ScrH() * 0.9, colorObj, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

local mat = Material("hmcd_dmzone")
function MODE:PostDrawTranslucentRenderables(bDepth, bSkybox, isDraw3DSkybox)
    if bSkybox or isDraw3DSkybox then return end
    for _, c in ipairs(circles) do
        render.SetMaterial(mat)
        render.DrawSphere(c.center, c.radius, 60, 60, Color(255, 50, 50, 100))

        local totalCiv = 0
        local detainedCiv = 0
        for _, ply in ipairs(player.GetAll()) do
            if ply:Team() == 1 or ply:Team() == TEAM_SPECTATOR then continue end
            totalCiv = totalCiv + 1
            if not ply:Alive() or ply:GetNetVar("handcuffed", false) then
                detainedCiv = detainedCiv + 1
            end
        end
        if totalCiv > 0 then
            local txt = "ГРАЖДАНСКИХ: " .. detainedCiv .. "/" .. totalCiv
            local pos = c.center + Vector(0, 0, 120)
            local ang = (pos - LocalPlayer():GetPos()):Angle()
            local textAngle = Angle(0, ang.y - 90, 90)

            cam.Start3D2D(pos, textAngle, 1)
                surface.SetFont("TCK_TimesNewRoman")
                surface.SetTextColor(255, 255, 255, 255)
                local tw, th = surface.GetTextSize(txt)
                surface.SetTextPos(-tw / 2, -th / 2)
                surface.DrawText(txt)
            cam.End3D2D()
        end
    end
end

local CreateEndMenu
net.Receive("protocol01_roundend", function()
    CreateEndMenu(net.ReadBool())
end)

local colGray = Color(85,85,85,255)
local colRed = Color(130,10,10)
local colRedUp = Color(160,30,30)
local colGreen = Color(0,100,0)
local colGreenUp = Color(0,130,0)
local col = Color(255,255,255,255)
local colSpect1 = Color(75,75,75,255)
local colSpect2 = Color(255,255,255)

BlurBackground = BlurBackground or hg.DrawBlur

if IsValid(hmcdEndMenu) then hmcdEndMenu:Remove() hmcdEndMenu = nil end

CreateEndMenu = function(tckWin)
    if IsValid(hmcdEndMenu) then hmcdEndMenu:Remove() hmcdEndMenu = nil end
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
    closebutton:SetPos(5,5)
    closebutton:SetSize(ScrW() / 20, ScrH() / 30)
    closebutton:SetText("")
    closebutton.DoClick = function() if IsValid(hmcdEndMenu) then hmcdEndMenu:Close() hmcdEndMenu = nil end end
    closebutton.Paint = function(self, w, h)
        surface.SetDrawColor(122,122,122,255)
        surface.DrawOutlinedRect(0,0,w,h,2.5)
        surface.SetFont("ZB_InterfaceMedium")
        surface.SetTextColor(col.r,col.g,col.b,col.a)
        local lenX,_ = surface.GetTextSize("Close")
        surface.SetTextPos(lenX - lenX/1.1, 4)
        surface.DrawText("Close")
    end

    hmcdEndMenu.Paint = function(self, w, h)
        BlurBackground(self)
        surface.SetFont("ZB_InterfaceMediumLarge")
        surface.SetTextColor(col.r,col.g,col.b,col.a)
        local winnerText = tckWin and "ТЦК задержали всех!" or "Гражданские победили!"
        local lenX,_ = surface.GetTextSize(winnerText)
        surface.SetTextPos(w/2 - lenX/2, 20)
        surface.DrawText(winnerText)
        surface.SetDrawColor(255, 0, 0, 128)
        surface.DrawOutlinedRect(0, 0, w, h, 2.5)
    end

    local DScrollPanel = vgui.Create("DScrollPanel", hmcdEndMenu)
    DScrollPanel:SetPos(10, 80)
    DScrollPanel:SetSize(sizeX - 20, sizeY - 90)
    DScrollPanel.Paint = function(self, w, h)
        BlurBackground(self)
        surface.SetDrawColor(255,0,0,128)
        surface.DrawOutlinedRect(0,0,w,h,2.5)
    end

    for _, ply in ipairs(player.GetAll()) do
        if ply:Team() == TEAM_SPECTATOR then continue end
        local but = vgui.Create("DButton", DScrollPanel)
        but:SetSize(100,50)
        but:Dock(TOP)
        but:DockMargin(8,6,8,-1)
        but:SetText("")
        but.Paint = function(self, w, h)
            local col1, col2
            if ply:Alive() then
                if ply:Team() == 1 then
                    col1, col2 = colGreen, colGreenUp
                else
                    col1, col2 = colRed, colRedUp
                end
            else
                col1, col2 = colGray, colSpect1
            end
            surface.SetDrawColor(col1.r, col1.g, col1.b, col1.a)
            surface.DrawRect(0,0,w,h)
            surface.SetDrawColor(col2.r, col2.g, col2.b, col2.a)
            surface.DrawRect(0,h/2,w,h/2)
            local pcol = ply:GetPlayerColor():ToColor()
            surface.SetFont("ZB_InterfaceMediumLarge")
            local name = ply:GetPlayerName() or "He quit..."
            local nameW, nameH = surface.GetTextSize(name)
            surface.SetTextColor(0,0,0,255)
            surface.SetTextPos(w/2 + 1, h/2 - nameH/2 + 1)
            surface.DrawText(name)
            surface.SetTextColor(pcol.r, pcol.g, pcol.b, pcol.a)
            surface.SetTextPos(w/2, h/2 - nameH/2)
            surface.DrawText(name)
            surface.SetFont("ZB_InterfaceMediumLarge")
            surface.SetTextColor(colSpect2.r, colSpect2.g, colSpect2.b, colSpect2.a)
            local info = ply:Name() .. (not ply:Alive() and " - died" or "")
            surface.SetTextPos(15, h/2 - nameH/2)
            surface.DrawText(info)
            local frags = ply:Frags() or 0
            local fragW, fragH = surface.GetTextSize(tostring(frags))
            surface.SetTextPos(w - fragW - 15, h/2 - fragH/2)
            surface.DrawText(frags)
        end
        but.DoClick = function()
            if ply:IsBot() then chat.AddText(Color(255,0,0), "no, you can't") return end
            gui.OpenURL("https://steamcommunity.com/profiles/" .. ply:SteamID64())
        end
        DScrollPanel:AddItem(but)
    end
    return true
end

function MODE:RoundStart()
    if IsValid(hmcdEndMenu) then hmcdEndMenu:Remove() hmcdEndMenu = nil end
end