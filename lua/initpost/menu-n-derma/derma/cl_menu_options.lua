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
surface.CreateFont("GOMI_SettingsCat", {
    font = "Bahnschrift",
    size = ScreenScale(15),
    weight = 700,
    antialias = true
})
surface.CreateFont("GOMI_SettingsLabel", {
    font = "Bahnschrift",
    size = ScreenScale(12),
    weight = 500,
    antialias = true
})
surface.CreateFont("GOMI_SettingsHelp", {
    font = "Bahnschrift",
    size = ScreenScale(8),
    weight = 400,
    antialias = true
})

local bgOverlay = Color(10, 10, 15, 220)
local textBright = Color(220, 220, 220)
local textDim = Color(140, 140, 140)
local accent = Color(180, 180, 180)
local panelHoverBg = Color(255, 255, 255, 8)
local sliderTrack = Color(60, 60, 65, 200)
local sliderKnob = Color(180, 180, 180)
local toggleOff = Color(50, 50, 55, 200)
local toggleOn = Color(180, 180, 180, 255)

local WBR_WHITE = Color(255, 255, 255, 255)
local WBR_COLORS = {
    Color(255, 255, 255, 255), -- W
    Color(60, 130, 255, 255),  -- B
    Color(230, 45, 45, 255)    -- R
}
local function GetWBRColor(idx)
    return WBR_COLORS[(idx - 1) % 3 + 1]
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

hg.settings = hg.settings or {}
hg.settings.tbl = {}

function hg.settings:AddOpt(category, convarName, title, decimals, isString, convarType)
    self.tbl[category] = self.tbl[category] or {}
    self.tbl[category][convarName] = {
        convar  = convarName,
        title   = title,
        decimals = decimals or false,
        isString = isString or false,
        convarType = convarType
    }
end

local hg_firstperson_death   = CreateClientConVar("hg_firstperson_death",   "0", true, false, "Переключение вида камеры смерти от первого лица", 0, 1)
local hg_font                = CreateClientConVar("hg_font",                "Bahnschrift", true, false, "Изменить шрифт текста")
local hg_attachment_draw_distance = CreateClientConVar("hg_attachment_draw_distance", 0, true, nil, "Расстояние прорисовки обвесов", 0, 4096)

hg.settings:AddOpt("Геймплей", "hg_old_notificate", "Старые уведомления")
hg.settings:AddOpt("Геймплей", "hg_cheats", "Включить читы")
hg.settings:AddOpt("Геймплей", "hg_showthoughts", "Показывать свои мысли")
hg.settings:AddOpt("Геймплей", "hg_hints", "Показывать подсказки")
hg.settings:AddOpt("Геймплей", "hg_gary", "HG GARY")
hg.settings:AddOpt("Геймплей", "hg_deathfadeout", "Затухание при смерти")

if not game.IsDedicated() then
    hg.settings:AddOpt("Сервер", "hg_toughnpcs", "Сильные NPC")
    hg.settings:AddOpt("Сервер", "hg_thirdperson", "Третье лицо (WIP)")
    hg.settings:AddOpt("Сервер", "hg_legacycam", "Старая камера")
    hg.settings:AddOpt("Сервер", "hg_ragdollcombat", "Боевой режим ragdoll")
    hg.settings:AddOpt("Сервер", "hg_movement_stamina_debuff", "Снижение выносливости")
    hg.settings:AddOpt("Сервер", "hg_furcity", "Фурсити")
    hg.settings:AddOpt("Сервер", "hg_appearance_access_for_all", "Полный доступ к внешности", nil, nil, "bool")
    hg.settings:AddOpt("Сервер", "hg_healanims", "Анимации лечения и еды")
    hg.settings:AddOpt("Сервер", "hg_aimtoshoot", "Стрельба в стиле DarkRP (не работает)")
    hg.settings:AddOpt("Сервер", "hg_slings", "Sling system")
end

hg.settings:AddOpt("Отладка", "hg_show_hitposmuzzle", "Показывать хитпосы")
hg.settings:AddOpt("Отладка", "hg_setzoompos", "Настройка зума оружия (консоль)")
hg.settings:AddOpt("Отладка", "hg_show_hitbox", "Показывать хитбоксы")

hg.settings:AddOpt("Оптимизация", "hg_potatopc", "Режим слабого ПК")
hg.settings:AddOpt("Оптимизация", "hg_anims_draw_distance", "Дистанция анимаций", true, nil, "int")
hg.settings:AddOpt("Оптимизация", "hg_anim_fps", "FPS анимаций", nil, nil, "int")
hg.settings:AddOpt("Оптимизация", "hg_attachment_draw_distance", "Дистанция обвесов", true, nil, "int")
hg.settings:AddOpt("Оптимизация", "hg_maxsmoketrails", "Макс. дымовых следов", nil, nil, "int")
hg.settings:AddOpt("Оптимизация", "hg_tpik_distance", "Дистанция рендера TPIK", true, nil, "int")

hg.settings:AddOpt("Кровь", "hg_blood_draw_distance", "Дистанция крови")
hg.settings:AddOpt("Кровь", "hg_blood_fps", "FPS крови")
hg.settings:AddOpt("Кровь", "hg_blood_sprites", "Спрайты крови (отключены)")
hg.settings:AddOpt("Кровь", "hg_old_blood", "Старая кровь")

hg.settings:AddOpt("Интерфейс", "hg_font", "Пользовательский шрифт", false, true)

hg.settings:AddOpt("Оружие", "hg_weaponshotblur_enable", "Размытие при стрельбе")
hg.settings:AddOpt("Оружие", "hg_dynamic_mags", "Динамическая проверка магазинов")
hg.settings:AddOpt("Оружие", "hg_zoomsensitivity", "Чувствительность прицела")
hg.settings:AddOpt("Оружие", "hg_highpitchgunfire", "Высокие частоты выстрелов")

hg.settings:AddOpt("Вид", "hg_firstperson_death", "Смерть от первого лица")
hg.settings:AddOpt("Вид", "hg_fov", "Поле зрения")
hg.settings:AddOpt("Вид", "hg_newspectate", "Плавная камера наблюдателя")
hg.settings:AddOpt("Вид", "hg_cshs_fake", "C'sHS Ragdoll камера")
hg.settings:AddOpt("Вид", "hg_gun_cam", "Оружейная камера (админы)")
hg.settings:AddOpt("Вид", "hg_nofovzoom", "Отключить FOV Zoom")
hg.settings:AddOpt("Вид", "hg_realismcam", "Realism camera")
hg.settings:AddOpt("Вид", "hg_gopro", "GoPro камера (не работает)")
hg.settings:AddOpt("Вид", "hg_newfakecam", "New fake camera")
hg.settings:AddOpt("Вид", "hg_leancam_mul", "Множ. наклона камеры", true, nil, "int")

hg.settings:AddOpt("Звук", "hg_dmusic", "Музыка в меню")
hg.settings:AddOpt("Звук", "hg_quietshots", "Тихие выстрелы")

local function getConvarType(cvar)
    local s = cvar:GetString()
    if s == "0" or s == "1" then return "bool" end
    if tonumber(s) then return "int" end
    return "string"
end

local function makeCategoryRow(parent, y, text)
    local pnl = vgui.Create("DPanel", parent)
    pnl:SetSize(parent:GetWide(), ScreenScale(26))
    pnl:SetPos(0, y)
    pnl:SetMouseInputEnabled(false)
    pnl.anim = 0
    pnl.Paint = function(self, w, h)
        self.anim = Lerp(FrameTime() * 8, self.anim, 1)
        local alpha = self.anim * 255
        local root = self:GetParent():GetParent()
        local openTime = IsValid(root) and (root.openTime or RealTime()) or RealTime()
        local sweepPos = (RealTime() - openTime) * 12.0
        local soft = 1.4
        local chars = {}
        if utf8 then
            for _, c in utf8.codes(text) do chars[#chars+1] = utf8.char(c) end
        else
            for i = 1, #text do chars[i] = text:sub(i, i) end
        end
    surface.SetFont("GOMI_Btn")
        local cx = ScreenScale(16)
        for i, ch in ipairs(chars) do
            local cw = surface.GetTextSize(ch)
            local progress = math.Clamp((sweepPos - (i - 1)) / soft, 0, 1)
            progress = progress * progress * (3 - 2 * progress)
            local target = GetWBRColor(i)
            local col = Color(Lerp(progress, 255, target.r), Lerp(progress, 255, target.g), Lerp(progress, 255, target.b), alpha)
            draw.SimpleText(ch, "GOMI_SettingsCat", cx + 1, h/2 + 1, Color(0,0,0,120))
            draw.SimpleText(ch, "GOMI_SettingsCat", cx, h/2, col)
            cx = cx + cw
        end
    end
    return pnl
end

local function makeSettingRow(parent, y, data)
    local convarName = data.convar
    local title = data.title
    if not convarName then
        convarName = data[2]
        title = data[3]
    end
    if not convarName then return end
    local cvar = GetConVar(convarName)
    if not cvar then return end

    local ctype = data.convarType or getConvarType(cvar)
    local w = parent:GetWide()
    local pad = ScreenScale(16)
    local ctrlW = ScreenScale(180)
    local rowH = ScreenScale(28)
    local hasHelp = cvar:GetHelpText() and cvar:GetHelpText() ~= ""
    if hasHelp then rowH = ScreenScale(40) end

    local pnl = vgui.Create("DPanel", parent)
    pnl:SetSize(w, rowH)
    pnl:SetPos(0, y)
    pnl:SetMouseInputEnabled(true)
    pnl.hover = 0
    pnl.Paint = function(self, w, h)
        self.hover = Lerp(FrameTime() * 10, self.hover, self:IsHovered() and 1 or 0)
        if self.hover > 0.01 then
            surface.SetDrawColor(panelHoverBg.r, panelHoverBg.g, panelHoverBg.b, panelHoverBg.a * self.hover)
            surface.DrawRect(pad, 0, w - pad*2, h)
        end
    end

    local titleLbl = vgui.Create("DLabel", pnl)
    titleLbl:SetPos(pad, rowH * 0.3)
    titleLbl:SetFont("GOMI_SettingsLabel")
    titleLbl:SetText(title)
    titleLbl:SetTextColor(textBright)
    titleLbl:SizeToContents()

    if hasHelp then
        local helpLbl = vgui.Create("DLabel", pnl)
        helpLbl:SetPos(pad, rowH * 0.7)
        helpLbl:SetFont("GOMI_SettingsHelp")
        helpLbl:SetText(cvar:GetHelpText())
        helpLbl:SetTextColor(textDim)
        helpLbl:SizeToContents()
    end

    local ctrlX = w - ctrlW - pad
    if ctype == "bool" then
        local tw, th = ScreenScale(36), ScreenScale(16)
        local tog = vgui.Create("DPanel", pnl)
        tog:SetSize(tw, th)
        tog:SetPos(ctrlX, rowH/2 - th/2)
        local val = cvar:GetBool() and 1 or 0
        local target = val
        tog.Paint = function(self, w, h)
            target = cvar:GetBool() and 1 or 0
            val = Lerp(FrameTime() * 12, val, target)
            draw.RoundedBox(4, 0, 0, w, h, val > 0.5 and toggleOn or toggleOff)
            local kx = Lerp(val, 2, w - h + 2)
            draw.RoundedBox(4, kx, 2, h-4, h-4, val > 0.5 and Color(30,30,30) or textBright)
        end
        tog.OnMousePressed = function()
            RunConsoleCommand(convarName, cvar:GetBool() and "0" or "1")
        end
    elseif ctype == "int" then
        local valW = ScreenScale(40)
        local slider = vgui.Create("DNumSlider", pnl)
        slider:SetSize(ctrlW - valW - ScreenScale(8), ScreenScale(16))
        slider:SetPos(ctrlX + valW + ScreenScale(4), rowH/2 - ScreenScale(8))
        slider:SetText("")
        local decimals = data.decimals or false
        slider:SetDecimals(decimals and 2 or 0)
        slider:SetMin(cvar:GetMin() or 0)
        slider:SetMax(cvar:GetMax() or 100)
        slider:SetValue(decimals and cvar:GetFloat() or cvar:GetInt())
        slider.Label:SetVisible(false)
        if slider.TextArea then slider.TextArea:SetVisible(false) end
        slider.Slider.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, h/2-2, w, 4, sliderTrack)
        end
        slider.Slider.Knob.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, sliderKnob)
        end

        local valLbl = vgui.Create("DLabel", pnl)
        valLbl:SetPos(ctrlX, rowH/2 - ScreenScale(8))
        valLbl:SetSize(valW, ScreenScale(16))
        valLbl:SetFont("GOMI_Small")
        valLbl:SetTextColor(textBright)
        valLbl:SetContentAlignment(6)

        slider.OnValueChanged = function(self, val)
            if decimals then
                RunConsoleCommand(convarName, string.format("%.2f", val))
            else
                RunConsoleCommand(convarName, tostring(math.Round(val)))
            end
            valLbl:SetText(decimals and string.format("%.2f", cvar:GetFloat()) or tostring(cvar:GetInt()))
        end
        timer.Simple(0, function()
            if IsValid(valLbl) then
                valLbl:SetText(decimals and string.format("%.2f", cvar:GetFloat()) or tostring(cvar:GetInt()))
            end
        end)
    elseif ctype == "string" then
        local entry = vgui.Create("DTextEntry", pnl)
        entry:SetSize(ctrlW, ScreenScale(18))
        entry:SetPos(ctrlX, rowH/2 - ScreenScale(9))
        entry:SetFont("GOMI_Small")
        entry:SetText(cvar:GetString())
        entry:SetUpdateOnType(true)
        entry.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(40,40,45,200))
            surface.SetDrawColor(100,100,100,180)
            surface.DrawOutlinedRect(0,0,w,h,1)
            self:DrawTextEntryText(textBright, accent, textBright)
        end
        entry.OnChange = function()
            RunConsoleCommand(convarName, entry:GetValue())
        end
    end

    return pnl
end

function hg.DrawSettings(parent)
    parent:SetAlpha(0)
    parent.bgAlpha = 0
    parent.Paint = function(self, w, h)
        self.bgAlpha = Lerp(FrameTime() * 8, self.bgAlpha, 1)
        drawBlur(self, 8)
        surface.SetDrawColor(bgOverlay.r, bgOverlay.g, bgOverlay.b, bgOverlay.a * self.bgAlpha)
        surface.DrawRect(0, 0, w, h)

        local grid = ScreenScale(25)
        local off = (RealTime() * 12) % grid
        surface.SetDrawColor(200, 200, 200, 15 * self.bgAlpha)
        for i = -1, math.ceil(w/grid)+1 do surface.DrawRect(i*grid - off, 0, 1, h) end
        for i = -1, math.ceil(h/grid)+1 do surface.DrawRect(0, i*grid + off, w, 1) end
    end
    parent:AlphaTo(255, 0.15, 0)
    parent.openTime = RealTime()

    local title = vgui.Create("DLabel", parent)
    title:SetPos(ScreenScale(20), ScreenScale(20))
    title:SetFont("GOMI_Title")
    title:SetText("Настройки")
    title:SetTextColor(Color(0,0,0,0))
    title.anim = 0
    title.Paint = function(self, w, h)
        self.anim = Lerp(FrameTime() * 10, self.anim, 1)
        local a = self.anim * 255
        local parentPnl = self:GetParent()
        local openTime = IsValid(parentPnl) and (parentPnl.openTime or RealTime()) or RealTime()
        local sweepPos = (RealTime() - openTime) * 12.0
        local soft = 1.4
        local s = "Настройки"
        surface.SetFont("GOMI_Title")
        local chars = {}
        if utf8 then
            for _, c in utf8.codes(s) do chars[#chars+1] = utf8.char(c) end
        else
            for i = 1, #s do chars[i] = s:sub(i,i) end
        end
        local cx = 0
        for i, ch in ipairs(chars) do
            local cw = surface.GetTextSize(ch)
            local progress = math.Clamp((sweepPos - (i - 1)) / soft, 0, 1)
            progress = progress * progress * (3 - 2 * progress)
            local target = GetWBRColor(i)
            local col = Color(Lerp(progress, 255, target.r), Lerp(progress, 255, target.g), Lerp(progress, 255, target.b), a)
            draw.SimpleText(ch, "GOMI_Title", cx+2, 2, Color(0,0,0,150*(a/255)))
            draw.SimpleText(ch, "GOMI_Title", cx, 0, col)
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

    local catNames = {}
    for name, catTable in pairs(hg.settings.tbl) do
        local hasValid = false
        for _, optData in pairs(catTable) do
            local cn = optData.convar or optData[2]
            if cn and GetConVar(cn) then hasValid = true; break end
        end
        if hasValid then catNames[#catNames+1] = name end
    end
    if #catNames == 0 then return end
    table.sort(catNames)

    local activeCat = catNames[1]
    local catBtns = {}
    local scroller

    local function rebuildContent()
        if not IsValid(scroller) then return end
        scroller:Clear()
        local catData = hg.settings.tbl[activeCat]
        if not catData then return end

        local optKeys = {}
        for k, _ in pairs(catData) do optKeys[#optKeys+1] = k end
        table.sort(optKeys)

        local y = 0
        local catPnl = makeCategoryRow(scroller, y, activeCat)
        y = y + catPnl:GetTall() + ScreenScale(12)

        for _, k in ipairs(optKeys) do
            local row = makeSettingRow(scroller, y, catData[k])
            if row then y = y + row:GetTall() + ScreenScale(6) end
        end
    end

    local btnArea = vgui.Create("DPanel", parent)
    btnArea:SetPos(ScreenScale(20), ScreenScale(70))
    btnArea:SetSize(parent:GetWide() - ScreenScale(40), ScreenScale(26))
    btnArea:SetMouseInputEnabled(true)
    btnArea.Paint = function() end

    surface.SetFont("GOMI_SettingsCat")
    local btnGap = ScreenScale(3)
    local padX = ScreenScale(6)
    local btnH = ScreenScale(14)
    local btnX = 0

    for i, name in ipairs(catNames) do
        local tw = surface.GetTextSize(name)
        local btnW = tw + padX * 2

        local btn = vgui.Create("DButton", btnArea)
        btn:SetText("")
        btn:SetSize(btnW, btnH)
        btn:SetPos(btnX, btnArea:GetTall()/2 - btnH/2)
        btn:SetCursor("hand")

        btn.catName = name
        btn.isActive = (name == activeCat)
        btn.hover = 0
        btn.glow = btn.isActive and 1 or 0

        btn.Paint = function(self, w, h)
            self.hover = Lerp(FrameTime() * 12, self.hover, self:IsHovered() and 1 or 0)
            self.glow = Lerp(FrameTime() * 8, self.glow, self.isActive and 1 or 0)

            local g = self.glow
            if g > 0.01 then
                draw.RoundedBox(6, -3, -3, w+6, h+6, Color(180, 180, 220, 40 * g))
            end

            local bg
            if self.isActive then
                local b = 60 + 120 * g
                bg = Color(b, b, b + 20, 220)
            elseif self.hover > 0.01 then
                bg = Color(45, 45, 55, 220)
            else
                bg = Color(25, 25, 30, 200)
            end
            draw.RoundedBox(4, 0, 0, w, h, bg)

            local txtCol = self.isActive and Color(230, 230, 240) or Color(170, 170, 170)
            draw.SimpleText(self.catName, "GOMI_Btn", w/2, h/2, txtCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        btn.DoClick = function(self)
            activeCat = self.catName
            for _, b in ipairs(catBtns) do
                b.isActive = (b.catName == activeCat)
            end
            rebuildContent()
        end

        catBtns[i] = btn
        btnX = btnX + btnW + btnGap
    end

    local scroll = vgui.Create("DScrollPanel", parent)
    scroll:SetSize(parent:GetWide() - ScreenScale(40), parent:GetTall() - ScreenScale(130))
    scroll:SetPos(ScreenScale(20), ScreenScale(110))
    scroll.Paint = function() end

    local vbar = scroll:GetVBar()
    vbar:SetSize(ScreenScale(8), 0)
    vbar.Paint = function(s,w,h) draw.RoundedBox(4,0,0,w,h,Color(30,30,40,200)) end
    vbar.btnUp.Paint = function() end
    vbar.btnDown.Paint = function() end
    vbar.btnGrip.Paint = function(s,w,h)
        draw.RoundedBox(4,2,2,w-4,h-4,s:IsHovered() and Color(100,100,130) or Color(70,70,90))
    end

    scroller = scroll
    rebuildContent()
end