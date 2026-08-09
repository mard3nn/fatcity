local blurMat = Material("pp/blurscreen")

surface.CreateFont("GOMI_Title", {
    font = "Bahnschrift",
    size = ScreenScale(40),
    weight = 800,
    antialias = true
})
surface.CreateFont("GOMI_Btn", {
    font = "Bahnschrift",
    size = ScreenScale(13),
    weight = 500,
    antialias = true,
    extended = true
})
surface.CreateFont("GOMI_Small", {
    font = "Bahnschrift",
    size = ScreenScale(9),
    weight = 400,
    antialias = true
})
surface.CreateFont("GOMI_RulesCat", {
    font = "Bahnschrift",
    size = ScreenScale(16),
    weight = 700,
    antialias = true
})
surface.CreateFont("GOMI_RulesNum", {
    font = "Bahnschrift",
    size = ScreenScale(12),
    weight = 600,
    antialias = true
})
surface.CreateFont("GOMI_RulesDesc", {
    font = "Bahnschrift",
    size = ScreenScale(10),
    weight = 400,
    antialias = true
})
surface.CreateFont("GOMI_SettingsHelp", {
    font = "Bahnschrift",
    size = ScreenScale(10),
    weight = 400,
    antialias = true
})

local TITLE_WHITE = Color(255, 255, 255, 255)
local TITLE_COLORS = {
    [1] = Color(255, 255, 255, 255), -- П
    [2] = Color(255, 255, 255, 255), -- Р
    [3] = Color(255, 255, 255, 255), -- А
    [4] = Color(60, 130, 255, 255),  -- В
    [5] = Color(60, 130, 255, 255),  -- И
    [6] = Color(230, 45, 45, 255),   -- Л
    [7] = Color(230, 45, 45, 255)    -- А
}
local TITLE_SWEEP_SPEED = 12.0
local TITLE_SWEEP_SOFT  = 1.4

local function LerpColor(t, c1, c2)
    return Color(
        Lerp(t, c1.r, c2.r),
        Lerp(t, c1.g, c2.g),
        Lerp(t, c1.b, c2.b),
        Lerp(t, c1.a, c2.a)
    )
end

local function drawBlur(panel, amount)
    local x, y = panel:LocalToScreen(0, 0)
    local frac = panel:GetAlpha() / 255
    surface.SetDrawColor(255, 255, 255, 255 * frac)
    surface.SetMaterial(blurMat)
    for i = 1, 3 do
        blurMat:SetFloat("$blur", (i / 3) * (amount or 8) * frac)
        blurMat:Recompute()
        render.UpdateScreenEffectTexture()
        surface.DrawTexturedRect(-x, -y, ScrW(), ScrH())
    end
end

function hg.DrawRules(parent)
    parent:SetAlpha(0)
    parent.anim = 0

    parent.Paint = function(self, w, h)
        self.anim = Lerp(FrameTime() * 8, self.anim, 1)
        drawBlur(self, 8)
        surface.SetDrawColor(10, 10, 15, 220 * self.anim)
        surface.DrawRect(0, 0, w, h)

        local gridSize = ScreenScale(25)
        local offset = (RealTime() * 12) % gridSize
        surface.SetDrawColor(200, 30, 30, 15 * self.anim)
        for i = -1, math.ceil(w / gridSize) + 1 do
            surface.DrawRect(i * gridSize - offset, 0, 1, h)
        end
        for i = -1, math.ceil(h / gridSize) + 1 do
            surface.DrawRect(0, i * gridSize + offset, w, 1)
        end
    end
    parent:AlphaTo(255, 0.15, 0)
    parent.openTime = RealTime()

    local titleLabel = vgui.Create("DLabel", parent)
    titleLabel:SetPos(ScreenScale(20), ScreenScale(20))
    titleLabel:SetFont("GOMI_Title")
    titleLabel:SetText("ПРАВИЛА")
    titleLabel:SizeToContents()
    titleLabel:SetTextColor(Color(255, 255, 255, 0))
    titleLabel.alpha = 0
    titleLabel.Paint = function(self, w, h)
        self.alpha = Lerp(FrameTime() * 10, self.alpha, 1)
        local a = self.alpha * 255
        local parentPnl = self:GetParent()
        local openTime = IsValid(parentPnl) and (parentPnl.openTime or RealTime()) or RealTime()
        local sweepPos = (RealTime() - openTime) * TITLE_SWEEP_SPEED
        local title = "ПРАВИЛА"
        surface.SetFont("GOMI_Title")
        local chars = {}
        if utf8 then
            for _, c in utf8.codes(title) do chars[#chars+1] = utf8.char(c) end
        else
            for i = 1, #title do chars[i] = title:sub(i, i) end
        end
        local cx = 0
        for i, ch in ipairs(chars) do
            local cw = surface.GetTextSize(ch)
            local target = TITLE_COLORS[i] or TITLE_WHITE

            local progress = math.Clamp((sweepPos - (i - 1)) / TITLE_SWEEP_SOFT, 0, 1)
            progress = progress * progress * (3 - 2 * progress)
            local col = LerpColor(progress, TITLE_WHITE, target)
            local glow = math.Clamp(1 - math.abs(sweepPos - (i - 1)) / TITLE_SWEEP_SOFT, 0, 1)
            col = LerpColor(glow * 0.55, col, TITLE_WHITE)

            draw.SimpleText(ch, "GOMI_Title", cx + 2, 2, Color(0, 0, 0, 150 * (a/255)))
            draw.SimpleText(ch, "GOMI_Title", cx, 0, Color(col.r, col.g, col.b, a))
            cx = cx + cw
        end
    end

    local closeBtn = vgui.Create("DButton", parent)
    closeBtn:SetText("")
    closeBtn:SetSize(ScreenScale(28), ScreenScale(28))
    closeBtn:SetPos(parent:GetWide() - ScreenScale(48), ScreenScale(16))
    closeBtn:SetCursor("hand")
    closeBtn.hover = 0
    closeBtn.Paint = function(self, w, h)
        self.hover = Lerp(FrameTime() * 10, self.hover, self:IsHovered() and 1 or 0)
        if self.hover > 0.01 then
            draw.RoundedBox(4, 0, 0, w, h, Color(200, 40, 40, 180 * self.hover))
        end
        draw.SimpleText("X", "GOMI_Btn", w/2, h/2, Color(255 - 80 * self.hover, 180 + 60 * self.hover, 180 + 60 * self.hover, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    closeBtn.DoClick = function()
        parent:Remove()
        timer.Simple(0, function()
            if IsValid(ZCity_MainMenu_Instance) then ZCity_MainMenu_Instance:Remove() end
            ZCity_MainMenu_Instance = vgui.Create("ZMainMenu")
        end)
    end

    local browser = vgui.Create("HTML", parent)
    browser:SetPos(ScreenScale(20), ScreenScale(70))
    browser:SetSize(parent:GetWide() - ScreenScale(40), parent:GetTall() - ScreenScale(120))
    browser:OpenURL("https://docs.google.com/document/d/1IJoHzd_4nKEprPnmOTvpvD1sqrTvLMRIXJvLbI2rhaM/edit?tab=t.0")

    local loadingPanel = vgui.Create("DPanel", parent)
    loadingPanel:SetPos(browser:GetPos())
    loadingPanel:SetSize(browser:GetSize())
    loadingPanel:SetMouseInputEnabled(true)
    loadingPanel.startTime = RealTime()
    loadingPanel.hidden = false
    loadingPanel.Paint = function(self, w, h)
        local frac = self:GetAlpha() / 255
        if frac <= 0 then return end

        surface.SetDrawColor(10, 10, 15, 235 * frac)
        surface.DrawRect(0, 0, w, h)

        local elapsed = RealTime() - self.startTime
        local cx, cy = w / 2, h / 2 - ScreenScale(16)
        local radius = ScreenScale(16)
        local dots = 10

        for i = 1, dots do
            local ang = (i / dots) * math.pi * 2 + RealTime() * 4
            local x = cx + math.cos(ang) * radius
            local y = cy + math.sin(ang) * radius
            local fade = ((i / dots) + RealTime() * 0.9) % 1
            local col = LerpColor(fade, Color(230, 45, 45), Color(255, 255, 255))
            local dotSize = ScreenScale(3)
            draw.RoundedBox(dotSize, x - dotSize, y - dotSize, dotSize * 2, dotSize * 2, Color(col.r, col.g, col.b, (50 + 205 * fade) * frac))
        end

        draw.SimpleText("Загрузка страницы...", "GOMI_RulesDesc", cx, cy + radius + ScreenScale(18), Color(200, 200, 200, 255 * frac), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

        if elapsed > 5 then
            draw.SimpleText("Похоже, возникли проблемы с соединением", "GOMI_RulesDesc", cx, cy + radius + ScreenScale(36), Color(230, 90, 90, 255 * frac), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
            draw.SimpleText("Нажмите \"нажмите сюда\" ниже, чтобы открыть правила в браузере", "GOMI_RulesDesc", cx, cy + radius + ScreenScale(50), Color(180, 180, 180, 255 * frac), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        end
    end

    local function HideLoadingPanel()
        if not IsValid(loadingPanel) or loadingPanel.hidden then return end
        loadingPanel.hidden = true
        loadingPanel:AlphaTo(0, 0.3, 0, function()
            if IsValid(loadingPanel) then loadingPanel:Remove() end
        end)
    end

    browser.OnFinishLoading = function()
        HideLoadingPanel()
    end
    browser.OnDocumentReady = function()
        HideLoadingPanel()
    end

    local footer = vgui.Create("DPanel", parent)
    footer:SetPos(ScreenScale(20), parent:GetTall() - ScreenScale(40))
    footer:SetSize(parent:GetWide() - ScreenScale(40), ScreenScale(15))
    footer.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(20, 20, 25, 200))
        surface.SetDrawColor(60, 60, 70, 150)
        surface.DrawRect(0, 0, w, 1)
    end

    local footerText = vgui.Create("DLabel", footer)
    footerText:SetFont("GOMI_SettingsHelp")
    footerText:SetText("Правила находятся только в формате сайта, если хотите прочитать подробнее ")
    footerText:SetTextColor(Color(140, 140, 140))
    footerText:SizeToContents()
    footerText:SetPos(ScreenScale(10), footer:GetTall()/2 - footerText:GetTall()/2)

    local linkBtn = vgui.Create("DButton", footer)
    linkBtn:SetText("")
    linkBtn:SetCursor("hand")
    linkBtn.hover = 0
    surface.SetFont("GOMI_SettingsHelp")
    local linkW = surface.GetTextSize("нажмите сюда")
    linkBtn:SetSize(linkW, footer:GetTall())
    linkBtn:SetPos(footerText:GetPos() + footerText:GetWide(), 0)
    linkBtn.Paint = function(self, w, h)
        self.hover = Lerp(FrameTime() * 10, self.hover, self:IsHovered() and 1 or 0)
        draw.SimpleText("нажмите сюда", "GOMI_SettingsHelp", w/2, h/2, Color(80 + 100 * self.hover, 130 + 80 * self.hover, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        if self:IsHovered() then
            surface.SetDrawColor(80, 130, 255, 80)
            surface.DrawLine(2, h - 3, w - 2, h - 3)
        end
    end
    linkBtn.DoClick = function()
        gui.OpenURL("https://docs.google.com/document/d/1IJoHzd_4nKEprPnmOTvpvD1sqrTvLMRIXJvLbI2rhaM/edit?tab=t.0")
    end
end
