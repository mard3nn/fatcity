surface.CreateFont("ZC_MM_Title", {
    font = "Bahnschrift",
    size = ScreenScale(40),
    weight = 800,
    antialias = true
})

surface.CreateFont("ZCity_Small", {
    font = "Bahnschrift",
    size = ScreenScale(13),
    weight = 500,
    antialias = true,
    extended = true
})

surface.CreateFont("ZCity_Tiny", {
    font = "Bahnschrift",
    size = ScreenScale(9),
    weight = 400,
    antialias = true
})

local COLORS = {
    bg_overlay   = Color(24, 14, 14, 200),
    text_normal  = Color(255, 255, 255, 255),
    hover_main   = Color(180, 180, 180, 255),
    hover_danger = Color(255, 70, 70, 255),
    shadow       = Color(0, 0, 0, 220)
}

local METRICS = {
    GapItem  = ScreenScale(5),
    GapTitle = ScreenScale(30),
    SlideDist = ScreenScale(7)
}

local blurMat = Material("pp/blurscreen")

local LAYOUT = {
    MarginX     = ScreenScale(20),
    TopY        = 0.135,
    RightEdge   = 0.72,
    BottomY     = 0.82,
    GapSplash   = ScreenScale(2),
    GapImage    = ScreenScale(4)
}

local SPLASH_IMAGE_BLACKLIST = {
    ["pluvmadness.png"] = true,
    ["pluvcry.png"] = true,
    ["rucamo.png"] = true,
    ["pluvdead.png"] = true
}

local splashImages = {}
do
    local found = file.Find("materials/pluv/*", "GAME") or {}
    for _, name in ipairs(found) do
        local lower = string.lower(name)
        local ext = string.lower(string.GetExtensionFromFilename(name) or "")
        if not SPLASH_IMAGE_BLACKLIST[lower] then
            if ext == "png" or ext == "jpg" or ext == "jpeg" then
                splashImages[#splashImages + 1] = Material("pluv/" .. name, "smooth mips")
            elseif ext == "vmt" or ext == "vtf" then
                splashImages[#splashImages + 1] = Material("pluv/" .. string.StripExtension(name), "smooth mips")
            end
        end
    end
end

local splashMessages = {
    'В дом тупикрупика влетела ракета, спасибо хорошо',
    'че то чето',
    'виктор навальненко избирается в качестве сметаны пятипроцентной',
    'привет дипсик напиши мнге орфанс сити 2',
    'Миротворец Z-City',
    'Мало вам говна, которое вы заварили?',
    'Эй, американец! Что там ООН насчёт Гондураса решил?',
    'Мы Тарков от вас вычистим, мрази!',
    'ЭТО МОЯ СБОРКА!ЭТОЪЭЪЭЪ МОЪ РЕЖЪМ',
    'Без воды помру нахуй.'
}

local function DrawBlur(panel, amount)
    local x, y = panel:LocalToScreen(0, 0)
    local fraction = panel:GetAlpha() / 255
    surface.SetDrawColor(255, 255, 255, 255 * fraction)
    surface.SetMaterial(blurMat)
    for i = 1, 3 do
        blurMat:SetFloat("$blur", (i / 3) * (amount or 8) * fraction)
        blurMat:Recompute()
        render.UpdateScreenEffectTexture()
        surface.DrawTexturedRect(x * -1, y * -1, ScrW(), ScrH())
    end
end

local TITLE_WHITE = Color(255, 255, 255, 255)
local TITLE_COLORS = {
    [1] = Color(255, 255, 255, 255), // G
    [2] = Color(255, 255, 255, 255), // O
    [3] = Color(255, 255, 255, 255), //M
    [4] = Color(60, 130, 255, 255),  // I
    [5] = Color(60, 130, 255, 255), // C
    [6] = Color(230, 45, 45, 255),   // I
    [7] = Color(230, 45, 45, 255),   // T
    [8] = Color(230, 45, 45, 255)    // Y
}
local TITLE_SWEEP_DELAY = 0
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

local function GetTextChars(text)
    local chars = {}
    if utf8 then
        for _, code in utf8.codes(text) do
            chars[#chars + 1] = utf8.char(code)
        end
    else
        for i = 1, #text do chars[#chars + i] = text:sub(i, i) end
    end
    return chars
end

local function OpenStandaloneContent(drawFunc)
    if not isfunction(drawFunc) then return end

    hg = hg or {}
    if IsValid(hg.StandaloneEscPanel) then
        hg.StandaloneEscPanel:Remove()
    end

    local panel = vgui.Create("EditablePanel")
    panel:SetSize(ScrW(), ScrH())
    panel:SetPos(0, 0)
    panel:SetMouseInputEnabled(true)
    panel:SetKeyboardInputEnabled(true)
    panel:MakePopup()

    function panel:OnKeyCodePressed(keyCode)
        if keyCode == KEY_ESCAPE then
            self:Remove()
        end
    end

    function panel:OnRemove()
        if hg then hg.StandaloneEscPanel = nil end
        gui.EnableScreenClicker(false)
    end

    hg.StandaloneEscPanel = panel
    gui.EnableScreenClicker(true)
    drawFunc(panel)
end

local Selects = {
    { Title = "Продолжить", Func = function(menu) menu:Close() end },
    {
        Title = "Правила",
        Func = function(menu)
            menu:Close(function()
                timer.Simple(0, function()
                    if hg and hg.DrawRules then
                        OpenStandaloneContent(hg.DrawRules)
                    end
                end)
            end)
        end
    },
    {
        Title = "Внешний вид",
        Func = function(menu)
            menu:Close(function()
                timer.Simple(0, function()
                    if hg and hg.CreateApperanceMenu then
                        hg.CreateApperanceMenu()
                    end
                end)
            end)
        end
    },
    {
        Title = "Настройки",
        Func = function(menu)
            menu:Close(function()
                timer.Simple(0, function()
                    if hg and hg.DrawSettings then
                        OpenStandaloneContent(hg.DrawSettings)
                    end
                end)
            end)
        end
    },
    {
        Title = "Донат",
        Func = function(menu)
            menu:Close(function()
                OpenDonateMenu()
            end)
        end
    },
    {
        Title = "Роль предателя",
        Func = function(menu)
            menu:Close(function()
                if hg and hg.SelectPlayerRole then
                    hg.SelectPlayerRole()
                end
            end)
        end
    },
    {
        Title = "Главное меню",
        Func = function(menu)
            menu:Close(function() gui.ActivateGameUI() end)
        end
    },
    {
        Title = "Дискорд",
        Func = function(menu)
            menu:Close(function()
                gui.OpenURL("https://discord.gg/2X9pgvVZ8")
            end)
        end
    },
    { Title = "Переподключиться", Func = function() RunConsoleCommand("retry") end },
    { Title = "Отключиться", Func = function() RunConsoleCommand("disconnect") end },
}

local musicShouldPlay = false
local activeStation = nil
local lastStationID = 0

hook.Add("Think", "ZMainMenu_MusicFailsafe", function()
    if not musicShouldPlay and IsValid(activeStation) then
        activeStation:SetVolume(0)
        activeStation:Stop()
        activeStation = nil
    end
end)

local PANEL = {}

function PANEL:Init()
    self:SetSize(ScrW(), ScrH())
    self:Center()
    self:MakePopup()
    self:SetAlpha(0)
    self:AlphaTo(255, 0.4, 0)
    self:SetCursor("blank")
    timer.Simple(0.5, function()
        if IsValid(self) then self:SetCursor("arrow") end
    end)

    self.MainTitle = "GOMICITY"
    local mapname = game.GetMap():match("_(.+)$") or game.GetMap()
    self.SubTitle = splashMessages[math.random(#splashMessages)] .. " | " .. string.NiceName(mapname)
    self.SplashImage = (#splashImages > 0) and splashImages[math.random(#splashImages)] or nil

    self:BuildUI()
    timer.Simple(0, function()
        if self.First then self:First() end
    end)

    self.OpenedAt = RealTime()
end

function PANEL:OnKeyCodePressed(key)
    if key == KEY_ESCAPE then
        self:Close()
    end
end

function PANEL:Paint(w, h)
    DrawBlur(self, 8)
    local fraction = self:GetAlpha() / 255

    surface.SetDrawColor(COLORS.bg_overlay.r, COLORS.bg_overlay.g, COLORS.bg_overlay.b, COLORS.bg_overlay.a * fraction)
    surface.DrawRect(0, 0, w, h)

    local gridSize = ScreenScale(25)
    local gridSpeed = 12
    local gridAlpha = 10
    local offset = RealTime() * gridSpeed % gridSize
    surface.SetDrawColor(180, 30, 30, gridAlpha)
    for i = -1, math.ceil(w / gridSize) + 1 do
        surface.DrawRect(i * gridSize - offset, 0, 1, h)
    end
    for i = -1, math.ceil(h / gridSize) + 1 do
        surface.DrawRect(0, i * gridSize + offset, w, 1)
    end

    if not IsValid(self.BtnContainer) or not self.BtnContainer:IsVisible() then return end

    local openedAt = self.OpenedAt or RealTime()
    local shouldAppear = RealTime() >= openedAt + (self.TitleAppearDelay or 0)
    self.TitleAppearLerp = Lerp(FrameTime() * 15, self.TitleAppearLerp or 0, shouldAppear and 1 or 0)
    local v = self.TitleAppearLerp
    local title = self.MainTitle
    local appearOffset = (1 - v) * (self.TitleAppearOffset or 0)
    local sweepPos = (RealTime() - (openedAt + (self.TitleAppearDelay or 0) + TITLE_SWEEP_DELAY)) * TITLE_SWEEP_SPEED

    local startX = LAYOUT.MarginX

    surface.SetFont("ZCity_Tiny")
    local _, splashHeight = surface.GetTextSize("A")
    local splashY = h * LAYOUT.TopY + appearOffset
    draw.SimpleText(self.SubTitle, "ZCity_Tiny", startX, splashY, Color(105, 105, 105, 255 * v), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    surface.SetFont("ZC_MM_Title")
    local tw, titleHeight = surface.GetTextSize(title)
    local y = splashY + splashHeight + LAYOUT.GapSplash

    local chars = GetTextChars(title)
    local acc = 0
    for i, char in ipairs(chars) do
        local cw = surface.GetTextSize(char)
        local target = TITLE_COLORS[i] or TITLE_WHITE

        local progress = math.Clamp((sweepPos - (i - 1)) / TITLE_SWEEP_SOFT, 0, 1)
        progress = progress * progress * (3 - 2 * progress)
        local col = LerpColor(progress, TITLE_WHITE, target)
        local glow = math.Clamp(1 - math.abs(sweepPos - (i - 1)) / TITLE_SWEEP_SOFT, 0, 1)
        col = LerpColor(glow * 0.55, col, TITLE_WHITE)

        draw.SimpleText(char, "ZC_MM_Title", startX + acc + 2, y + 2, Color(0, 0, 0, 150 * v), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(char, "ZC_MM_Title", startX + acc, y, Color(col.r, col.g, col.b, 255 * v), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        acc = acc + cw
    end

    local mat = self.SplashImage

    if mat and not mat:IsError() then
        local boxX = startX
        local boxY = y + titleHeight + LAYOUT.GapImage
        local boxW = w * LAYOUT.RightEdge - boxX
        local boxH = h * LAYOUT.BottomY - boxY

        if boxW > 0 and boxH > 0 then
            local mw, mh = math.max(mat:Width(), 1), math.max(mat:Height(), 1)
            local drawW = boxW
            local drawH = math.min(drawW * (mh / mw), boxH)

            surface.SetDrawColor(0, 0, 0, 140 * v)
            surface.DrawRect(boxX, boxY, drawW, drawH)

            surface.SetDrawColor(255, 255, 255, 255 * v)
            surface.SetMaterial(mat)
            surface.DrawTexturedRect(boxX, boxY, drawW, drawH)
        end
    end
end

function PANEL:BuildUI()
    local w, h = self:GetWide(), self:GetTall()

    self.BtnContainer = vgui.Create("DPanel", self)
    self.BtnContainer:SetSize(w, h)
    self.BtnContainer.Paint = function() end

    surface.SetFont("ZC_MM_Title")
    local _, titleHeight = surface.GetTextSize("A")
    local btnHeight = ScreenScale(14)
    local totalBlockHeight = titleHeight + METRICS.GapTitle + (#Selects * btnHeight) + ((#Selects - 1) * METRICS.GapItem)
    self.TitleY = (h * 0.48) - (totalBlockHeight / 2)

    local yPos = self.TitleY + titleHeight + METRICS.GapTitle
    local btnWidth = math.max(w * 0.22, ScreenScale(100))
    local btnMargin = ScreenScale(24)
    local btnX = w - btnWidth - btnMargin
    local textPad = ScreenScale(5)

    for i, v in ipairs(Selects) do
        local btn = vgui.Create("DButton", self.BtnContainer)
        btn:SetSize(btnWidth, btnHeight)
        btn:SetText("")
        btn:SetAlpha(0)
        btn:SetPos(btnX, yPos + ScreenScale(15))
        btn:MoveTo(btnX, yPos, 0.5, (i * 0.04), 0.5)
        btn:AlphaTo(255, 0.5, (i * 0.04))

        btn.Hov = 0
        btn.wasHovered = false

        btn.Think = function(s)
            local isHover = s:IsHovered()
            if isHover and not s.wasHovered then
                surface.PlaySound("garrysmod/ui_hover.wav")
                s.wasHovered = true
            elseif not isHover then
                s.wasHovered = false
            end
            s.Hov = Lerp(FrameTime() * 8, s.Hov, isHover and 1 or 0)
        end

		btn.Paint = function(s, pw, ph)
            local hoverAmount = s.Hov
            local alpha = s:GetAlpha() / 255
            local txt = v.Title
            local xOffset = Lerp(hoverAmount, 0, METRICS.SlideDist)
            local targetCol = (v.Title == "Отключиться") and COLORS.hover_danger or COLORS.hover_main
            local col = LerpColor(hoverAmount, COLORS.text_normal, targetCol)

            surface.SetFont("ZCity_Small")

            draw.SimpleText(txt, "ZCity_Small", textPad + xOffset + 2, ph / 2 + 2, Color(0, 0, 0, 220 * alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(txt, "ZCity_Small", textPad + xOffset, ph / 2, Color(col.r, col.g, col.b, col.a * alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end

        btn.DoClick = function(s)
            surface.PlaySound("garrysmod/ui_click.wav")
            v.Func(self)
        end

        yPos = yPos + btnHeight + METRICS.GapItem
    end

    local bottomDock = vgui.Create("DPanel", self)
    local footerLineH = ScreenScaleH(14)
    bottomDock:SetSize(math.min(ScrW() * 0.45, math.max(420, ScreenScaleH(420))), footerLineH * 4 + 4)
    bottomDock.BaseX = ScreenScale(6)
    bottomDock.AppearOffset = ScreenScaleH(18)
    bottomDock.AppearDelay = 0.18
    bottomDock.AppearLerp = 0
    bottomDock:SetAlpha(0)
    bottomDock:SetPos(bottomDock.BaseX, ScrH() - bottomDock:GetTall() - ScreenScale(6) + bottomDock.AppearOffset)

    bottomDock.Paint = function() end
    bottomDock.Think = function(s)
        local parent = s:GetParent()
        local openedAt = IsValid(parent) and (parent.OpenedAt or RealTime()) or RealTime()
        local show = RealTime() >= openedAt + s.AppearDelay
        s.AppearLerp = Lerp(FrameTime() * 12, s.AppearLerp or 0, show and 1 or 0)
        s:SetAlpha(255 * s.AppearLerp)
        s:SetPos(s.BaseX, ScrH() - s:GetTall() - ScreenScale(6) + (1 - s.AppearLerp) * s.AppearOffset)
        for _, child in ipairs(s:GetChildren()) do
            if IsValid(child) then child:SetAlpha(s:GetAlpha()) end
        end
    end

    local infoColor = Color(178, 178, 178, 220)
    local labelsData = {
        { text = "Authors: uzelezz, Sadsalat,", index = 0 },
        { text = "Mr.Point, Zac70, Deka, Mannytko, ok1ro", index = 1 },
        { text = "GOMICITY is a fork of KIROCITY, licensed under AGPLv3", index = 2 },
        { text = "GitHub: github.com/uzelezz123/Z-City | github.com/ok1ro/KIROCITY-OFF", index = 3 }
    }

    for _, data in ipairs(labelsData) do
        local lbl = vgui.Create("DLabel", bottomDock)
        lbl:SetPos(0, 2 + footerLineH * data.index)
        lbl:SetSize(bottomDock:GetWide(), footerLineH)
        lbl:SetFont("ZCity_Tiny")
        lbl:SetTextColor(data.index == 3 and Color(105, 105, 105, 220) or infoColor)
        lbl:SetText(data.text)
        lbl:SetContentAlignment(4)
        if data.index == 3 then
            lbl:SetMouseInputEnabled(true)
            function lbl:DoClick()
                gui.OpenURL("https://github.com/uzelezz123/Z-City")
            end
        end
    end

    local rightAuthors = vgui.Create("DLabel", self)
    rightAuthors:SetFont("ZCity_Tiny")
    rightAuthors:SetTextColor(infoColor)
    rightAuthors:SetText("GOMICITY Authors: Полковник Мардененко, aboba017\nа вы знали что дворовые собаки умнее чем\nнекоторые люди?")
    rightAuthors:SetContentAlignment(3)
    rightAuthors:SizeToContents()

    rightAuthors.AppearOffset = ScreenScaleH(18)
    rightAuthors.AppearDelay = 0.2
    rightAuthors.AppearLerp = 0
    rightAuthors:SetAlpha(0)
    rightAuthors:SetPos(ScrW() - rightAuthors:GetWide() - 5, ScrH() - rightAuthors:GetTall() - 16 + rightAuthors.AppearOffset)

    rightAuthors.Think = function(s)
        local parent = s:GetParent()
        if not IsValid(parent) then return end
        local openedAt = parent.OpenedAt or RealTime()
        local show = RealTime() >= openedAt + s.AppearDelay
        s.AppearLerp = Lerp(FrameTime() * 12, s.AppearLerp or 0, show and 1 or 0)
        s:SetAlpha(255 * s.AppearLerp)
        s:SetPos(ScrW() - s:GetWide() - 5, ScrH() - s:GetTall() - 16 + (1 - s.AppearLerp) * s.AppearOffset)
    end
end

function PANEL:First()
    self.TitleAppearDelay = 0.03
    self.TitleAppearOffset = ScreenScaleH(22)
    self.TitleAppearLerp = 0

    local hg_dmusic = GetConVar("hg_dmusic")
    if hg_dmusic and not hg_dmusic:GetBool() then return end

    musicShouldPlay = true
    lastStationID = lastStationID + 1
    local currentID = lastStationID

    if IsValid(activeStation) then
        activeStation:SetVolume(0)
        activeStation:Stop()
        activeStation = nil
    end

    sound.PlayFile("sound/esc/rube_cool_music_for_esc.wav", "noplay mono", function(station, err, errStr)
        if IsValid(station) then
            if musicShouldPlay and currentID == lastStationID and IsValid(self) and not self.IsClosing then
                if IsValid(activeStation) then activeStation:Stop() end
                activeStation = station
                activeStation:SetVolume(0.5)
                activeStation:Play()
            else
                station:SetVolume(0)
                station:Stop()
            end
        end
    end)
end

function PANEL:Close(callback)
    self.IsClosing = true
    musicShouldPlay = false

    if IsValid(activeStation) then
        activeStation:SetVolume(0)
        activeStation:Stop()
        activeStation = nil
    end

    self:SetKeyboardInputEnabled(false)
    self:SetMouseInputEnabled(false)

    self:AlphaTo(0, 0.35, 0, function()
        if IsValid(self) then self:Remove() end
        if callback then callback() end
    end)
end

vgui.Register("ZMainMenu", PANEL, "EditablePanel")

if IsValid(ZCity_MainMenu_Instance) then
    ZCity_MainMenu_Instance:Remove()
end
ZCity_MainMenu_Instance = nil

hook.Add("OnPauseMenuShow", "ZCity_OpenMainMenu", function()
    local run = hook.Run("OnShowZCityPause")
    if run ~= nil then return run end

    if hg and IsValid(hg.StandaloneEscPanel) then
        hg.StandaloneEscPanel:Remove()
        return false
    end

    if IsValid(ZCity_MainMenu_Instance) then
        ZCity_MainMenu_Instance:Close()
        ZCity_MainMenu_Instance = nil
        return false
    end

    gui.HideGameUI()
    ZCity_MainMenu_Instance = vgui.Create("ZMainMenu")
    return false
end)