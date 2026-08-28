--[[local PANEL = {}

local clr_text = Color(225, 225, 225)
local clr_text_sub = Color(105, 105, 105)
local clr_bg_main = Color(10, 10, 19, 235)

local function GetTextChars(text)
    local chars = {}
    if utf8 then
        for _, code in utf8.codes(text) do
            chars[#chars + 1] = utf8.char(code)
        end
    else
        for i = 1, #text do chars[#chars + 1] = text:sub(i, i) end
    end
    return chars
end

local AuthorData = {
    {
        name = "marden",
        desc = "Главный разработчик GOMICITY.\nОтвечает за код."
    },
    {
        name = "Mardenenko",
        desc = "Создатель основатель сервера."
    }
}

local WBR_WHITE = Color(255, 255, 255, 255)
local WBR_COLORS = {
    Color(255, 255, 255, 255), -- W
    Color(60, 130, 255, 255),  -- B
    Color(230, 45, 45, 255)    -- R
}

local function LerpColor(t, c1, c2)
    return Color(Lerp(t, c1.r, c2.r), Lerp(t, c1.g, c2.g), Lerp(t, c1.b, c2.b), Lerp(t, c1.a, c2.a))
end

local function GetWBRColor(idx)
    return WBR_COLORS[(idx - 1) % 3 + 1]
end

function PANEL:Init()
    self:SetSize(ScrW(), ScrH())
    self:Center()
    self:MakePopup()
    self:SetAlpha(0)
    self:AlphaTo(255, 0.2)
    self.OpenedAt = RealTime()

    self.AuthorPanels = {}

    local container = vgui.Create("DPanel", self)
    container:SetWide(ScreenScale(250))
    container:SetTall(ScrH() * 0.5)
    container:SetPos(ScrW() / 2 - container:GetWide() / 2, ScrH() * 0.45)
    container.Paint = nil

    for i, data in ipairs(AuthorData) do
        local p = vgui.Create("EditablePanel", container)
        p:Dock(TOP)
        p:DockMargin(0, 0, 0, ScreenScale(10))
        p:SetTall(ScreenScale(30))
        p.Expanded = false
        p.ExpandLerp = 0
        
        local btn = vgui.Create("DButton", p)
        btn:Dock(TOP)
        btn:SetTall(ScreenScale(25))
        btn:SetText(data.name)
        btn:SetFont("ZC_MM_Title")
        btn.HoverLerp = 0

        btn.Paint = function(s, w, h)
            s.HoverLerp = LerpFT(0.15, s.HoverLerp, s:IsHovered() and 1 or 0)
            local v = s.HoverLerp
            local chars = GetTextChars(data.name)
            local totalW = surface.GetTextSize(data.name)
            local startX = w / 2 - totalW / 2
            local t = RealTime() * 7

            for j, char in ipairs(chars) do
                local offset = surface.GetTextSize(table.concat(chars, "", 1, j - 1))
                local shimmer = (math.sin(t - j * 0.4) + 1) * 0.5
                local s2 = shimmer * 3
                local p2 = math.floor(s2)
                local f2 = s2 - p2
                local cr, cg, cb
                if p2 == 0 then
                    cr = 255; cg = Lerp(f2, 255, 50); cb = Lerp(f2, 255, 50)
                elseif p2 == 1 then
                    cr = Lerp(f2, 255, 50); cg = Lerp(f2, 50, 100); cb = Lerp(f2, 50, 255)
                else
                    cr = Lerp(f2, 50, 255); cg = Lerp(f2, 100, 255); cb = Lerp(f2, 255, 255)
                end
                local col_shimmer = Color(40, 40, 40):Lerp(Color(cr, cg, cb), shimmer)
                local col = clr_text:Lerp(col_shimmer, v)
                
                draw.SimpleText(char, "ZC_MM_Title", startX + offset + 1, h / 2 + 1, Color(0, 0, 0, 200), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText(char, "ZC_MM_Title", startX + offset, h / 2, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
            return true
        end

        local desc = vgui.Create("DLabel", p)
        desc:SetText(data.desc)
        desc:SetFont("ZCity_Tiny")
        desc:SetTextColor(Color(180, 180, 180))
        desc:SetContentAlignment(5)
        desc:Dock(FILL)
        desc:SetAlpha(0)
        desc:SetWrap(true)

        btn.DoClick = function()
            p.Expanded = !p.Expanded
            surface.PlaySound("shitty/tap-resonant.wav")
        end

        p.Think = function(s)
            s.ExpandLerp = LerpFT(0.1, s.ExpandLerp, s.Expanded and 1 or 0)
            s:SetTall(ScreenScale(30) + s.ExpandLerp * ScreenScale(35))
            desc:SetAlpha(s.ExpandLerp * 255)
        end

        self.AuthorPanels[i] = p
    end

    self.Container = container

    local close = vgui.Create("DButton", self)
    close:SetSize(ScreenScale(80), ScreenScale(25))
    close:SetText("RETURN")
    close:SetFont("ZCity_Small")
    close:SetTextColor(clr_text)
    close.HoverLerp = 0

    close.Think = function(s)
        s.HoverLerp = LerpFT(0.15, s.HoverLerp or 0, s:IsHovered() and 1 or 0)
    end

    close.Paint = function(s, w, h)
        local txt = s:GetText()
        local v = s.HoverLerp
        surface.SetFont(s:GetFont())
        local chars = GetTextChars(txt)
        local totalW = surface.GetTextSize(txt)
        local startX = w / 2 - totalW / 2
        local t = RealTime() * 7

        for i, char in ipairs(chars) do
            local offset = surface.GetTextSize(table.concat(chars, "", 1, i - 1))
            local shimmer = (math.sin(t - i * 0.4) + 1) * 0.5
            local s2 = shimmer * 3
            local p2 = math.floor(s2)
            local f2 = s2 - p2
            local cr, cg, cb
            if p2 == 0 then
                cr = 255; cg = Lerp(f2, 255, 50); cb = Lerp(f2, 255, 50)
            elseif p2 == 1 then
                cr = Lerp(f2, 255, 50); cg = Lerp(f2, 50, 100); cb = Lerp(f2, 50, 255)
            else
                cr = Lerp(f2, 50, 255); cg = Lerp(f2, 100, 255); cb = Lerp(f2, 255, 255)
            end
            local col_shimmer = Color(40, 40, 40):Lerp(Color(cr, cg, cb), shimmer)
            local col = clr_text:Lerp(col_shimmer, v)
            
            draw.SimpleText(char, s:GetFont(), startX + offset + 1, h / 2 + 1, Color(0, 0, 0, 200 * v), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(char, s:GetFont(), startX + offset, h / 2, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        return true
    end

    close.DoClick = function()
        self:AlphaTo(0, 0.2, 0, function() self:Remove() end)
    end
    self.CloseBtn = close
end

local gradient_d = surface.GetTextureID("vgui/gradient-d")
local gradient_l = surface.GetTextureID("vgui/gradient-l")

function PANEL:Paint(w, h)
    draw.RoundedBox(0, 0, 0, w, h, clr_bg_main)
    hg.DrawBlur(self, 5)

    -- Анимированная сетка (дизайн из Main Menu)
    local gridSize = ScreenScale(25)
    local gridSpeed = 12
    local gridTime = RealTime() * gridSpeed
    local gridAlpha = 12
    local offset = gridTime % gridSize

    surface.SetDrawColor(200, 30, 30, gridAlpha)
    for i = -1, math.ceil(w / gridSize) + 1 do
        local x = i * gridSize - offset
        surface.DrawRect(x, 0, 1, h)
    end
    for i = -1, math.ceil(h / gridSize) + 1 do
        local y = i * gridSize + offset
        surface.DrawRect(0, y, w, 1)
    end
    
    -- Градиенты фона
    surface.SetDrawColor(clr_bg_main)
    surface.SetTexture(gradient_l)
    surface.DrawTexturedRect(0, 0, w, h)
    
    surface.SetDrawColor(60, 60, 60, 30)
    surface.SetTexture(gradient_d)
    surface.DrawTexturedRect(0, 0, w, h)

    local title = "GOMICITY"
    local x, y = w / 2, h * 0.25
    local sweepPos = (RealTime() - self.OpenedAt) * 12.0
    local soft = 1.4

    surface.SetFont("ZC_MM_Title")
    draw.SimpleText(title, "ZC_MM_Title", x + 1, y + 1, Color(0, 0, 0, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    local chars = GetTextChars(title)
    local totalW, _ = surface.GetTextSize(title)
    local startX = x - totalW / 2
    local ax = 0
    for i, char in ipairs(chars) do
        local progress = math.Clamp((sweepPos - (i - 1)) / soft, 0, 1)
        progress = progress * progress * (3 - 2 * progress)
        local target = GetWBRColor(i)
        local col = LerpColor(progress, WBR_WHITE, target)
        draw.SimpleText(char, "ZC_MM_Title", startX + ax, y, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        ax = ax + surface.GetTextSize(char)
    end

    draw.SimpleText("PROJECT AUTHORS", "ZCity_Tiny", w / 2, y + ScreenScale(26), clr_text_sub, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    if IsValid(self.CloseBtn) then
        self.CloseBtn:SetPos(w / 2 - self.CloseBtn:GetWide() / 2, h - ScreenScale(50))
    end
end

function PANEL:OnKeyCodePressed(keyCode)
    if keyCode == KEY_ESCAPE then
        self:AlphaTo(0, 0.2, 0, function()
            self:Remove()
        end)
    end
end

vgui.Register("ZAuthorPanel", PANEL, "EditablePanel")

-- Команда для теста
concommand.Add("hg_authors", function() vgui.Create("ZAuthorPanel") end)]]
