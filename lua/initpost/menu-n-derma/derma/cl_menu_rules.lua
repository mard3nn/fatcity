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

local colRed    = Color(255, 100, 100)
local colYellow = Color(255, 255, 100)
local colOrange = Color(255, 180, 100)

local rulesList = {
    { category = "0. Основное", items = {
        { name = "0.1", desc = "Незнание правил не освобождает от ответственности." },
        { name = "0.2", desc = "Для хомиградовских нахуй на пол кто будет ложить тому бан по решению администрации." },
        { name = "0.3", desc = "Решение администрации является окончательным." }
    }},
    { category = "1. Общие правила", items = {
        { name = "1.1 — Дискредитация сервера", desc = "Запрещено оскорблять сервер, рекламировать другие проекты или распространять ложную информацию.", punishment = "бан навсегда", color = colRed },
        { name = "1.2 — Оскорбления и токсичность", desc = "Запрещены (оскорбление родных), травля.", punishment = "мут / гаг — 30 минут; повтор — бан до 1 дня; серьезное нарушение — до 7 дней", color = colYellow },
        { name = "1.3 — Выдача себя за другого", desc = "Запрещено копировать ник или аватар, а также притворяться другим игроком. Срок увеличивается при выдаче себя за админа.", punishment = "бан 16 часов (при выдаче за админа 3 дня)", color = colOrange },
        { name = "1.4 — Обход наказания", desc = "Использование твинков или других способов обхода наказания.", punishment = "бан навсегда", color = colRed },
        { name = "1.5 — Спам", desc = "Флуд, спам звуками (Soundpad), засорение чата. В том числе включение NSFW звуков. Использовать soundpad разрешено в меру.", punishment = "бан — 20 минут; повтор — до 5 часов", color = colYellow },
        { name = "1.6 — Провокации", desc = "Подставы и намеренные попытки заставить другого игрока нарушить правила.", punishment = "бан до 3 недель", color = colOrange },
        { name = "1.7 — Запрещённый контент", desc = "NSFW, шок-контент, экстремистская символика.", punishment = "бан 2 дня", color = colRed },
        { name = "1.8 — Угрозы и слив данных", desc = "Любые угрозы или распространение личной информации.", punishment = "бан навсегда", color = colRed },
        { name = "1.9 — Злоупотребление лазейками", desc = "Использование недоработок правил или механик в свою пользу. В частности — использование багов сервера в личных целях.", punishment = "бан до 5 дней", color = colOrange },
        { name = "1.10 — Давление на администрацию", desc = "Спам жалобами, споры после финального решения, угрозы.", punishment = "бан до 2 дней", color = colYellow },
        { name = "1.11 — Неадекватное поведение", desc = "Крики в микрофон, троллинг, намеренное раздражение игроков.", punishment = "бан до 6 часов", color = colYellow }
    }},
    { category = "2. Игровые правила (GOMICITY)", items = {
        { name = "2.1 — Читы", desc = "Любые сторонние программы, дающие преимущество.", punishment = "бан навсегда + снятие доната", color = colRed },
        { name = "2.2 — Баги и абузы", desc = "Использование багов, дюпов и абуз механик.", punishment = "2 недели; серьезное нарушение — до 3 месяцев", color = colOrange },
        { name = "2.3 — Сговор (тиминг)", desc = "Помощь врагам или игра в сговоре ради преимущества.", punishment = "бан 1 час", color = colYellow },
        { name = "2.4 — Мониторинг", desc = "Передача информации после смерти.", punishment = "бан 2 часа", color = colYellow },
        { name = "2.5 — Помеха игре", desc = "Блокировка проходов, спам объектами, мешание другим игрокам.", punishment = "бан от 1 часа до 1 дня", color = colOrange },
        { name = "2.6 — Лив от наказания", desc = "Выход во время разборки или перед наказанием.", punishment = "бан до 2 дней", color = colOrange },
        { name = "2.7 — Обман администрации", desc = "Ложные жалобы или поддельные доказательства.", punishment = "бан до 1 дня", color = colOrange },
        { name = "2.8 — Руин (порча игры)", desc = "Намеренные действия, портящие игру другим игрокам.", punishment = "бан до 7 дней", color = colRed },
        { name = "2.9 - Массовые убийства", desc = "Человек не является предателем, а иноцентом и начинает без причины убивать людей.", punishment = "бан до 2 часов", color = colRed },
        { name = "2.10 — Массовые нарушения", desc = "Многократные или систематические нарушения.", punishment = "вплоть до перманента", color = colRed },
        { name = "2.11 — Намеренный лаг сервера", desc = "Создание лагов любыми способами.", punishment = "бан вплоть до перманента", color = colRed }
    }}
}

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
        local t = RealTime() * 4
        local title = "ПРАВИЛА"
        surface.SetFont("GOMI_Title")
        local tw = surface.GetTextSize(title)
        local sx = 0
        local chars = {}
        if utf8 then
            for _, c in utf8.codes(title) do chars[#chars+1] = utf8.char(c) end
        else
            for i = 1, #title do chars[i] = title:sub(i, i) end
        end
        local cx = sx
        for i, ch in ipairs(chars) do
            local cw = surface.GetTextSize(ch)
            local shimmer = (math.sin(t - i * 0.4) + 1) / 2
            local gray = 100 + shimmer * 155
            local col = Color(gray, gray, gray, a)
            draw.SimpleText(ch, "GOMI_Title", cx + 2, 2, Color(0, 0, 0, 150 * (a/255)))
            draw.SimpleText(ch, "GOMI_Title", cx, 0, col)
            cx = cx + cw
        end
    end

    local scroll = vgui.Create("DScrollPanel", parent)
    scroll:SetSize(parent:GetWide() - ScreenScale(40), parent:GetTall() - ScreenScale(90))
    scroll:SetPos(ScreenScale(20), ScreenScale(70))
    scroll.Paint = function() end

    local vbar = scroll:GetVBar()
    vbar:SetSize(ScreenScale(8), 0)
    vbar.Paint = function(s, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 40, 200))
    end
    vbar.btnUp.Paint = function() end
    vbar.btnDown.Paint = function() end
    vbar.btnGrip.Paint = function(s, w, h)
        draw.RoundedBox(4, 2, 2, w - 4, h - 4, s:IsHovered() and Color(100, 100, 130) or Color(70, 70, 90))
    end

    local y = 0
    for _, cat in ipairs(rulesList) do
        local catLabel = vgui.Create("DLabel", scroll)
        catLabel:SetPos(ScreenScale(10), y)
        catLabel:SetFont("GOMI_RulesCat")
        catLabel:SetText(cat.category)
        catLabel:SetTextColor(Color(200, 200, 200))
        catLabel:SizeToContents()
        y = y + catLabel:GetTall() + ScreenScale(5)

        for _, item in ipairs(cat.items) do
            local panelHeight = item.punishment and ScreenScale(50) or ScreenScale(35)
            local rulePanel = vgui.Create("DPanel", scroll)
            rulePanel:SetSize(scroll:GetWide() - ScreenScale(15), panelHeight)
            rulePanel:SetPos(ScreenScale(5), y)
            rulePanel.hover = 0

            rulePanel.Paint = function(self, w, h)
                self.hover = Lerp(FrameTime() * 10, self.hover, self:IsHovered() and 1 or 0)
                draw.RoundedBox(4, 0, 0, w, h, Color(40 + self.hover * 15, 40 + self.hover * 15, 40 + self.hover * 15, 180))
                local accent = item.color or Color(180, 180, 180)
                surface.SetDrawColor(accent.r, accent.g, accent.b, 60 + self.hover * 120)
                surface.DrawRect(0, 0, 3, h)
            end

            local nameLabel = vgui.Create("DLabel", rulePanel)
            nameLabel:SetPos(ScreenScale(10), ScreenScale(5))
            nameLabel:SetFont("GOMI_RulesNum")
            nameLabel:SetText(item.name)
            nameLabel:SetTextColor(Color(180, 180, 180))
            nameLabel:SizeToContents()

            local descLabel = vgui.Create("DLabel", rulePanel)
            descLabel:SetPos(ScreenScale(10), ScreenScale(22))
            descLabel:SetFont("GOMI_RulesDesc")
            descLabel:SetText(item.desc)
            descLabel:SetTextColor(Color(150, 150, 150))
            descLabel:SetWide(rulePanel:GetWide() - ScreenScale(20))
            descLabel:SetWrap(true)
            descLabel:SetAutoStretchVertical(true)

            if item.punishment then
                local punLabel = vgui.Create("DLabel", rulePanel)
                punLabel:SetPos(ScreenScale(10), ScreenScale(35))
                punLabel:SetFont("GOMI_RulesDesc")
                punLabel:SetText("Наказание: " .. item.punishment)
                punLabel:SetTextColor(item.color or Color(255, 100, 100))
                punLabel:SizeToContents()
            end

            y = y + panelHeight + ScreenScale(5)
        end
        y = y + ScreenScale(10)
    end
end