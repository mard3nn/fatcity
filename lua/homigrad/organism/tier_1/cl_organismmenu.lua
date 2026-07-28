if SERVER then return end

local function OpenOrganismMenu()
    if not LocalPlayer():IsSuperAdmin() then return end

    local frame = vgui.Create("ZFrame")
    frame:SetSize(500, 700)
    frame:SetTitle("Управление Организмом")
    frame:Center()
    frame:MakePopup()

    local topPanel = vgui.Create("DPanel", frame)
    topPanel:Dock(TOP)
    topPanel:SetHeight(40)
    topPanel:DockMargin(10, 10, 10, 5)
    topPanel.Paint = nil

    local playerSelect = vgui.Create("DComboBox", topPanel)
    playerSelect:Dock(FILL)
    playerSelect:SetSortItems(true)
    playerSelect:SetValue("Выберите цель (по умолчанию: Вы)")

    local function RefreshPlayers()
        playerSelect:Clear()
        playerSelect:AddChoice("Сам себе", LocalPlayer())
        for _, ply in ipairs(player.GetAll()) do
            if ply == LocalPlayer() then continue end
            playerSelect:AddChoice(ply:Nick() .. " (" .. ply:SteamID() .. ")", ply)
        end
    end
    RefreshPlayers()

    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:Dock(FILL)
    scroll:DockMargin(10, 5, 10, 10)

    local function AddParameterControl(label, cmdKey, min, max, default)
        local pnl = vgui.Create("DPanel", scroll)
        pnl:Dock(TOP)
        pnl:SetHeight(60)
        pnl:DockMargin(0, 0, 0, 10)
        pnl.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30, 200))
        end

        local slider = vgui.Create("DNumSlider", pnl)
        slider:Dock(FILL)
        slider:DockMargin(10, 0, 10, 0)
        slider:SetText(label)
        slider:SetMin(min)
        slider:SetMax(max)
        slider:SetValue(default)
        slider:SetDecimals(2)

        local applyBtn = vgui.Create("DButton", pnl)
        applyBtn:SetSize(60, 20)
        applyBtn:SetPos(410, 20)
        applyBtn:SetText("ОК")
        applyBtn.DoClick = function()
            local _, target = playerSelect:GetSelected()
            local targetName = IsValid(target) and target:Name() or LocalPlayer():Name()
            RunConsoleCommand("hg_organism_setvalue", cmdKey, tostring(slider:GetValue()), targetName)
        end
    end

    -- Основные параметры
    AddParameterControl("Кровь (Blood)", "blood", 0, 5000, 5000)
    AddParameterControl("Боль (Pain)", "pain", 0, 150, 0)
    AddParameterControl("Кислород (O2)", "o2", 0, 30, 30)
    AddParameterControl("Пульс (Pulse)", "pulse", 0, 200, 70)
    AddParameterControl("Шок (Shock)", "shock", 0, 100, 0)
    AddParameterControl("Адреналин", "adrenaline", 0, 5, 0)
    AddParameterControl("Температура", "temperature", 25, 42, 36.6)

    -- Кнопки состояний
    local statusPnl = vgui.Create("DPanel", scroll)
    statusPnl:Dock(TOP)
    statusPnl:SetHeight(180)
    statusPnl.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(50, 20, 20, 150))
    end

    local actions = {
        { "Упасть (KO)", "otrub", "1" },
        { "Встать (Wake)", "otrub", "0" },
        { "Остановка сердца", "heartstop", "1" },
        { "Запуск сердца", "heartstop", "0" },
        { "Внутр. кровотечение", "internalBleed", "20" },
        { "Остановить кровь", "bleed", "0" },
        { "ПОЛНАЯ ОЧИСТКА", "clear", "" }
    }

    local x, y = 10, 10
    for i, act in ipairs(actions) do
        local btn = vgui.Create("DButton", statusPnl)
        btn:SetSize(150, 30)
        btn:SetPos(x, y)
        btn:SetText(act[1])
        
        if act[2] == "clear" then 
            btn:SetTextColor(Color(255, 100, 100))
        end

        btn.DoClick = function()
            local _, target = playerSelect:GetSelected()
            local targetName = IsValid(target) and target:Name() or LocalPlayer():Name()
            
            if act[2] == "clear" then
                RunConsoleCommand("hg_organism_clear", targetName)
            else
                RunConsoleCommand("hg_organism_setvalue", act[2], act[3], targetName)
            end
        end

        y = y + 40
        if y > 140 then
            y = 10
            x = x + 160
        end
    end

    -- Кнопка обновления списка игроков
    local refreshBtn = vgui.Create("DButton", frame)
    refreshBtn:Dock(BOTTOM)
    refreshBtn:SetHeight(30)
    refreshBtn:DockMargin(10, 0, 10, 10)
    refreshBtn:SetText("Обновить список игроков")
    refreshBtn.DoClick = RefreshPlayers
end

concommand.Add("hg_organism_control", OpenOrganismMenu)