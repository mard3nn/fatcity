local gradient_d = surface.GetTextureID("vgui/gradient-d")
local gradient_l = surface.GetTextureID("vgui/gradient-l")

surface.CreateFont("ZC_SettingsTitle", {
    font = "Bahnschrift",
    size = ScreenScale(22),
    weight = 800,
    antialias = true
})

local clr_verygray = Color(10,10,19,70)
local clr_1 = Color(0,19,102,12)
local red_select = Color(192,0,0)

local textBright = Color(220,220,220)
local textDim = Color(140,140,140)

local toggleOff = Color(40,40,50,200)
local toggleOn = Color(192,0,0,255)
local sliderTrack = Color(60,60,70,180)
local sliderKnob = Color(230,230,230)

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
    pnl:SetSize(parent:GetWide(), ScreenScale(20))
    pnl:SetPos(0, y)
    pnl:SetMouseInputEnabled(false)
    pnl.anim = 0
    pnl.Paint = function(self, w, h)
        self.anim = Lerp(FrameTime() * 8, self.anim, 1)
        local a = self.anim * 255

        surface.SetDrawColor(red_select.r, red_select.g, red_select.b, 160 * self.anim)
        surface.DrawRect(0, ScreenScale(5), ScreenScale(3), ScreenScale(10))

        draw.SimpleText(text, "ZCity_Tiny", ScreenScale(10), h / 2, Color(255,255,255,a), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
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
    local pad = ScreenScale(10)
    local ctrlW = ScreenScale(140)
    local rowH = ScreenScale(20)
    local hasHelp = cvar:GetHelpText() and cvar:GetHelpText() ~= ""
    if hasHelp then rowH = ScreenScale(28) end

    local pnl = vgui.Create("DPanel", parent)
    pnl:SetSize(w, rowH)
    pnl:SetPos(0, y)
    pnl:SetMouseInputEnabled(true)
    pnl.hover = 0
    pnl.Paint = function(self, w, h)
        self.hover = Lerp(FrameTime() * 10, self.hover, self:IsHovered() and 1 or 0)
    end

    local titleLbl = vgui.Create("DLabel", pnl)
    titleLbl:SetPos(pad, rowH * 0.28)
    titleLbl:SetFont("ZCity_Tiny")
    titleLbl:SetText(title)
    titleLbl:SetTextColor(textBright)
    titleLbl:SizeToContents()

    titleLbl.Think = function(self)
        self.HoverLerp = LerpFT(0.2, self.HoverLerp or 0, (pnl:IsHovered() or self:IsHovered()) and 1 or 0)
        self:SetTextColor(textBright:Lerp(red_select, self.HoverLerp))
    end

    if hasHelp then
        local helpLbl = vgui.Create("DLabel", pnl)
        helpLbl:SetPos(pad, rowH * 0.68)
        helpLbl:SetFont("ZCity_VerySuperTiny")
        helpLbl:SetText(cvar:GetHelpText())
        helpLbl:SetTextColor(textDim)
        helpLbl:SizeToContents()
    end

    local ctrlX = w - ctrlW - pad
    if ctype == "bool" then
        local tw, th = ScreenScale(28), ScreenScale(12)
        local tog = vgui.Create("DPanel", pnl)
        tog:SetSize(tw, th)
        tog:SetPos(ctrlX, rowH/2 - th/2)
        local val = cvar:GetBool() and 1 or 0
        local target = val
        tog.Paint = function(self, w, h)
            target = cvar:GetBool() and 1 or 0
            val = Lerp(FrameTime() * 12, val, target)
            draw.RoundedBox(0, 0, 0, w, h, val > 0.5 and toggleOn or toggleOff)
            local kx = Lerp(val, 2, w - h + 2)
            draw.RoundedBox(0, kx, 1, h - 2, h - 2, val > 0.5 and Color(30,30,30) or textBright)
        end
        tog.OnMousePressed = function()
            RunConsoleCommand(convarName, cvar:GetBool() and "0" or "1")
        end
    elseif ctype == "int" then
        local valW = ScreenScale(30)
        local slider = vgui.Create("DNumSlider", pnl)
        slider:SetSize(ctrlW - valW - ScreenScale(6), ScreenScale(12))
        slider:SetPos(ctrlX + valW + ScreenScale(4), rowH/2 - ScreenScale(6))
        slider:SetText("")
        local decimals = data.decimals or false
        slider:SetDecimals(decimals and 2 or 0)
        slider:SetMin(cvar:GetMin() or 0)
        slider:SetMax(cvar:GetMax() or 100)
        slider:SetValue(decimals and cvar:GetFloat() or cvar:GetInt())
        slider.Label:SetVisible(false)
        if slider.TextArea then slider.TextArea:SetVisible(false) end
        slider.Slider.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, h/2 - 2, w, 4, sliderTrack)
        end
        slider.Slider.Knob.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, 0, w, h, sliderKnob)
        end

        local valLbl = vgui.Create("DLabel", pnl)
        valLbl:SetPos(ctrlX, rowH/2 - ScreenScale(6))
        valLbl:SetSize(valW, ScreenScale(12))
        valLbl:SetFont("ZCity_VerySuperTiny")
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
        entry:SetSize(ctrlW, ScreenScale(14))
        entry:SetPos(ctrlX, rowH/2 - ScreenScale(7))
        entry:SetFont("ZCity_Tiny")
        entry:SetText(cvar:GetString())
        entry:SetUpdateOnType(true)
        entry.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(20,20,30,220))
            local border = self:IsEditing() and red_select or Color(120,120,130,180)
            surface.SetDrawColor(border)
            surface.DrawOutlinedRect(0,0,w,h,1)
            self:DrawTextEntryText(textBright, red_select, textBright)
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
        local a = self.bgAlpha

        draw.RoundedBox(0, 0, 0, w, h, Color(clr_verygray.r, clr_verygray.g, clr_verygray.b, clr_verygray.a * a))
        hg.DrawBlur(self, 5)
        surface.SetDrawColor(Color(clr_verygray.r, clr_verygray.g, clr_verygray.b, clr_verygray.a * a))
        surface.SetTexture(gradient_l)
        surface.DrawTexturedRect(0,0,w,h)
        surface.SetDrawColor(Color(clr_1.r, clr_1.g, clr_1.b, clr_1.a * a))
        surface.SetTexture(gradient_d)
        surface.DrawTexturedRect(0,0,w,h)
    end
    parent:AlphaTo(255, 0.15, 0)
    parent.openTime = RealTime()





    local closeBtn = vgui.Create("DButton", parent)
    closeBtn:SetText("")
    closeBtn:SetSize(ScreenScale(22), ScreenScale(22))
    closeBtn:SetPos(parent:GetWide() - ScreenScale(38), ScreenScale(12))
    closeBtn:SetCursor("hand")
    closeBtn.hover = 0
    closeBtn.Paint = function(self, w, h)
        self.hover = Lerp(FrameTime() * 10, self.hover, self:IsHovered() and 1 or 0)
        draw.SimpleText("X", "ZCity_Tiny", w/2, h/2, textBright:Lerp(red_select, self.hover), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
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
        y = y + catPnl:GetTall() + ScreenScale(8)

        for _, k in ipairs(optKeys) do
            local row = makeSettingRow(scroller, y, catData[k])
            if row then y = y + row:GetTall() + ScreenScale(4) end
        end
    end

    local btnArea = vgui.Create("DPanel", parent)
    btnArea:SetPos(ScreenScale(20), ScreenScale(42))
    btnArea:SetSize(parent:GetWide() - ScreenScale(40), ScreenScale(18))
    btnArea:SetMouseInputEnabled(true)
    btnArea.Paint = function() end

    local btnGap = ScreenScale(8)
    local btnH = ScreenScale(12)
    local btnX = 0

    local function addCategoryButton(name)
        surface.SetFont("ZCity_Tiny")
        local btnW = surface.GetTextSize(name) + ScreenScale(4)

        local btn = vgui.Create("DLabel", btnArea)
        btn:SetText(name)
        btn:SetMouseInputEnabled(true)
        btn:SetSize(btnW, btnH)
        btn:SetPos(btnX, btnArea:GetTall()/2 - btnH/2)
        btn:SetFont("ZCity_Tiny")
        btn:SetTextColor(textBright)
        btn.isActive = (name == activeCat)
        btn.HoverLerp = btn.isActive and 1 or 0
        btn.StartX = btnX

        function btn:DoClick()
            if self.isActive then return end
            self.Press = 1
            surface.PlaySound("shitty/tap_depress.wav")
            activeCat = self.catName
            for _, b in ipairs(catBtns) do
                b.isActive = (b.catName == activeCat)
            end
            rebuildContent()
        end

        function btn:Think()
            self.HoverLerp = LerpFT(0.2, self.HoverLerp or 0, (self:IsHovered() or self.isActive) and 1 or 0)
            self.Press = LerpFT(0.15, self.Press or 0, 0)

            local v = self.HoverLerp
            self:SetTextColor(textBright:Lerp(red_select, v))

            local will_text = self.isActive and ("[ " .. name .. " ]") or name
            self:SetText(will_text)
            self:SizeToContents()
            self:SetPos(self.StartX, btnArea:GetTall()/2 - btnH/2 + self.Press * ScreenScale(2))
        end

        catBtns[#catBtns+1] = btn
        btn.catName = name
        btnX = btnX + btnW + btnGap
        return btn
    end

    for i, name in ipairs(catNames) do
        addCategoryButton(name)
    end

    local scroll = vgui.Create("DScrollPanel", parent)
    scroll:SetSize(parent:GetWide() - ScreenScale(30), parent:GetTall() - ScreenScale(90))
    scroll:SetPos(ScreenScale(20), ScreenScale(72))
    scroll.Paint = function() end

    local vbar = scroll:GetVBar()
    vbar:SetSize(ScreenScale(6), 0)
    vbar.Paint = function(s,w,h) draw.RoundedBox(0,0,0,w,h,Color(20,20,30,200)) end
    vbar.btnUp.Paint = function() end
    vbar.btnDown.Paint = function() end
    vbar.btnGrip.Paint = function(s,w,h)
        draw.RoundedBox(0,1,1,w-2,h-2,s:IsHovered() and red_select or Color(90,90,100))
    end

    scroller = scroll
    rebuildContent()
end
