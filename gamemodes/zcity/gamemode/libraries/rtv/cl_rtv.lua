if CLIENT then
    local RTVPanel = nil
    local CachedMaps, CachedEndTime, CachedVotes = nil, 0, {}
    local RTV_CloseTimer = nil
    local RTV_Music = nil

    surface.CreateFont('RTV.TitleFont', { font = 'Roboto', size = ScreenScale(18), weight = 1000 })
    surface.CreateFont('RTV.TimeFont',  { font = 'Roboto', size = ScreenScale(8), weight = 1, italic = true })
    surface.CreateFont('RTV.StayFont', { font = 'Roboto', size = ScreenScale(10), weight = 1000 })

    -- peremeshivaet massiv (Fisher-Yates), ispolzuetsya chtobi poryadok kart bil raznii kajdii RTV
    local function PeremeshatMassiv(tbl, seedValue)
        local seed = 0
        seedValue = tostring(seedValue or '')
        for i = 1, #seedValue do
            seed = (seed * 31 + string.byte(seedValue, i)) % 2147483647
        end
        if seed == 0 then seed = 1 end
        local n = #tbl
        for i = n, 2, -1 do
            seed = (seed * 16807) % 2147483647
            local j = (seed % i) + 1
            tbl[i], tbl[j] = tbl[j], tbl[i]
        end
        return tbl
    end

    -- --KartaKartochkaKartaKartochkaKartaKartochkaKartaKartochka eto kvadratic v korotom naxoditca karta
    local KartaKartochka = {}
    function KartaKartochka:Init()
        self.ImyaKarti = ''
        self.Avatarki = {}
        self.Pobeditel = false
        self.Vybrannaya = false
        self.Mat = nil
        self.MoveGlow = 0
    end

    function KartaKartochka:Setup(name, parent)
        self.ImyaKarti = name
        self.Roditel = parent
        if name == 'random' then
            self.Mat = Material('icon64/random.png', 'smooth')
            if self.Mat:IsError() then self.Mat = Material('icon64/tool.png') end
        else
            self.Mat = Material('maps/thumb/' .. name .. '.png', 'smooth')
            if self.Mat:IsError() then self.Mat = Material('maps/thumb/noimage.vmt') end
        end
    end

    function KartaKartochka:Paint(w, h)
        if self.Mat then
            surface.SetDrawColor(255, 255, 255, 255)
            surface.SetMaterial(self.Mat)
            surface.DrawTexturedRect(0, 0, w, h)
        else
            draw.RoundedBox(4, 0, 0, w, h, Color(50,50,50,255))
        end

        draw.RoundedBox(0, 0, 0, w, 20, Color(0,0,0,180))
        draw.SimpleText(self.ImyaKarti:gsub('_', ' '), 'DermaDefault', w/2, 4, Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

        if self.Vybrannaya then
            surface.SetDrawColor(255,200,0,240)
            surface.DrawOutlinedRect(0,0,w,h,2)
        end
        if self.Pobeditel then
            local alpha = math.abs(math.sin(RealTime() * 10)) * 255
            surface.SetDrawColor(255,255,0,alpha)
            surface.DrawOutlinedRect(0,0,w,h,3)
        end

        if self.MoveGlow and self.MoveGlow > 0 then
            surface.SetDrawColor(80,190,255,self.MoveGlow)
            surface.DrawOutlinedRect(0,0,w,h,3)
        end
    end

    function KartaKartochka:Think()
        if self.MoveGlow and self.MoveGlow > 0 then
            self.MoveGlow = math.max(0, self.MoveGlow - FrameTime() * 450)
        end
    end

    function KartaKartochka:DoClick()
        if self.Roditel.VoteCooldown > CurTime() then return end
        self.Roditel:LocalVote(self.ImyaKarti)
        net.Start('ZB_RockTheVote_vote')
            net.WriteString(self.ImyaKarti)
        net.SendToServer()
        self.Roditel.VoteCooldown = CurTime() + 1
    end

    function KartaKartochka:OnMousePressed(code)
        if code == MOUSE_LEFT then self:DoClick() end
    end

    function KartaKartochka:UpdateAvatars(voters)
        for _, av in ipairs(self.Avatarki) do if av:IsValid() then av:Remove() end end
        self.Avatarki = {}
        if not voters then return end
        for _, sid64 in ipairs(voters) do
            local ply = player.GetBySteamID64(sid64)
            if IsValid(ply) then
                local av = vgui.Create('AvatarImage', self)
                av:SetPlayer(ply, 32)
                av:SetPaintedManually(false)
                table.insert(self.Avatarki, av)
            end
        end
        self:InvalidateLayout()
    end

    function KartaKartochka:PerformLayout(w, h)
        local avatarSize = 32
        local padding = 1
        local x, y = padding, h - avatarSize - padding
        local maxX = w - padding
        for _, av in ipairs(self.Avatarki) do
            if av:IsValid() then
                if x + avatarSize > maxX then x = padding; y = y - avatarSize - padding end
                av:SetPos(x, y)
                av:SetSize(avatarSize, avatarSize)
                x = x + avatarSize + padding
            end
        end
    end
    vgui.Register('RTVMapCard', KartaKartochka, 'DPanel')

    -- menushka golosovaniya!!!
    local PanelGolosovaniya = {}
    function PanelGolosovaniya:Init()
        self:SetSize(ScrW(), ScrH())
        self:SetPos(0,0)
        self:SetAlpha(0)
        self:AlphaTo(255, 0.5, 0)
        self:MakePopup()
        self:SetKeyboardInputEnabled(false)
        self:SetMouseInputEnabled(true)

        self.VoteMaps = {}
        self.VoteEndTime = 0
        self.TotalDuration = 30
        self.Votes = {}
        self.WinnerMap = nil
        self.Kartochki = {}
        self.KartochkiOrder = {}
        self.VoteCooldown = 0
        self.MoySteamID64 = LocalPlayer():SteamID64()
        self.MoyGolos = nil

        self.Fon = function(_, w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(20, 20, 20, 220))
            local speed = 40
            local spacing = 50
            local offsetX = (CurTime() * speed) % spacing
            local offsetY = (CurTime() * 0.7 * speed) % spacing
            surface.SetDrawColor(200, 30, 30, 15)
            for x = offsetX, w, spacing do surface.DrawLine(x, 0, x, h) end
            for y = offsetY, h, spacing do surface.DrawLine(0, y, w, y) end
        end

        self.TopBar = vgui.Create('DPanel', self)
        self.TopBar:Dock(TOP)
        self.TopBar:SetTall(ScrH()*0.12)
        self.TopBar:DockMargin(ScrW()*0.05, ScrH()*0.03, ScrW()*0.05, 0)
        self.TopBar.Paint = function(_, w, h)
            local timeLeft = math.max(0, self.VoteEndTime - CurTime())
            local frac = math.Clamp(timeLeft / self.TotalDuration, 0, 1)
            local timeFormatted = string.FormattedTime(math.ceil(timeLeft), '%02i:%02i')
            local barY = h * 0.55
            local barH = h * 0.28
            local titleX = 10
            local titleY = barY - 50

            draw.SimpleTextOutlined('ГОЛОСОВАНИЕ ЗА СМЕНУ КАРТЫ', 'RTV.TitleFont', titleX, titleY, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 2, Color(0,0,0,15))
            draw.SimpleTextOutlined('ГОЛОСОВАНИЕ ЗА СМЕНУ КАРТЫ', 'RTV.TitleFont', titleX, titleY, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1, Color(0,0,0,30))
            local titleW = draw.SimpleText('ГОЛОСОВАНИЕ ЗА СМЕНУ КАРТЫ', 'RTV.TitleFont', titleX, titleY, Color(0,0,0,0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP) or 120
            draw.SimpleTextOutlined(timeFormatted, 'RTV.TimeFont', titleX + titleW + 15, titleY + 3, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 2, Color(0,0,0,15))
            draw.SimpleTextOutlined(timeFormatted, 'RTV.TimeFont', titleX + titleW + 15, titleY + 3, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1, Color(0,0,0,30))

            local barW = w * 0.65
            local barX = titleX
            draw.RoundedBox(4, barX-2, barY-2, barW+4, barH+4, Color(0,0,0,30))
            draw.RoundedBox(4, barX-1, barY-1, barW+2, barH+2, Color(0,0,0,60))
            draw.RoundedBox(4, barX, barY, barW, barH, Color(60,60,60,200))
            if frac > 0 then
                local fillW = barW * frac
                draw.RoundedBox(4, barX, barY, fillW, barH, Color(255,255,255,240))
                draw.RoundedBox(2, barX+2, barY+2, fillW-4, barH*0.4, Color(255,255,255,80))
            end
            surface.SetDrawColor(255,255,255,200)
            surface.DrawOutlinedRect(barX, barY, barW, barH, 2)
        end

        self.KnopkaOst = vgui.Create('DPanel', self.TopBar)
        self.KnopkaOst:SetWidth(ScrW() * 0.15)
        self.KnopkaOst.AvatarkiOst = {}
        self.KnopkaOst.Vybrannaya = false
        self.KnopkaOst.Pobeditel = false
        self.KnopkaOst.Paint = function(pnl, w, h)
            draw.RoundedBox(6, 0, 0, w, h, Color(0,0,0,180))
            local bg = pnl:IsHovered() and Color(100,100,100,240) or Color(70,70,70,230)
            draw.RoundedBox(6, 0, 0, w, h, bg)
            surface.SetDrawColor(255,255,255,40)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            if pnl.Vybrannaya then
                surface.SetDrawColor(255,200,0,240)
                surface.DrawOutlinedRect(0, 0, w, h, 2)
            end
            draw.SimpleText('ОСТАТЬСЯ', 'RTV.StayFont', w/2, h/2, Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        self.KnopkaOst.OnMousePressed = function(pnl, code)
            if code == MOUSE_LEFT then
                if self.VoteCooldown > CurTime() then return end
                self:LocalVote('stay')
                net.Start('ZB_RockTheVote_vote')
                    net.WriteString('stay')
                net.SendToServer()
                self.VoteCooldown = CurTime() + 1
            end
        end
        self.KnopkaOst.PerformLayout = function(pnl, w, h)
            local avatarSize = 20
            local padding = 2
            local x, y = padding + 3, h - avatarSize - padding - 2
            local maxX = w - padding - 3
            for _, av in ipairs(pnl.AvatarkiOst) do
                if av:IsValid() then
                    if x + avatarSize > maxX then x = padding + 3; y = y - avatarSize - padding end
                    av:SetPos(x, y)
                    av:SetSize(avatarSize, avatarSize)
                    x = x + avatarSize + padding
                end
            end
        end

        self.TopBar.PerformLayout = function(pnl, w, h)
            if IsValid(self.KnopkaOst) then
                local barY = h * 0.55
                local barH = h * 0.28
                local barW = w * 0.65
                local titleX = 10
                local barX = titleX
                local stayX = barX + barW + 20
                local stayW = w * 0.20
                self.KnopkaOst:SetPos(stayX, barY)
                self.KnopkaOst:SetSize(stayW, barH)
            end
        end

        self.MapsContainer = vgui.Create('DPanel', self)
        self.MapsContainer:Dock(FILL)
        self.MapsContainer:DockMargin(ScrW()*0.05, ScrH()*0.01, ScrW()*0.05, ScrH()*0.04)
        self.MapsContainer.Paint = nil

        self.Scroll = vgui.Create('DScrollPanel', self.MapsContainer) --https://gmodwiki.com/DScrollPanel
        self.Scroll:Dock(FILL)

        self.MapsInner = vgui.Create('DPanel')
        self.MapsInner.Paint = nil
        self.Scroll:AddItem(self.MapsInner)
    end

    function PanelGolosovaniya:LocalVote(mapName)
        if not mapName then return end
        local mySid = self.MoySteamID64
        if self.MoyGolos and self.Votes[self.MoyGolos] then
            for i, sid in ipairs(self.Votes[self.MoyGolos]) do
                if sid == mySid then table.remove(self.Votes[self.MoyGolos], i) break end
            end
            if #self.Votes[self.MoyGolos] == 0 then self.Votes[self.MoyGolos] = nil end
        end
        self.Votes[mapName] = self.Votes[mapName] or {}
        table.insert(self.Votes[mapName], mySid)
        self.MoyGolos = mapName
        for m, card in pairs(self.Kartochki) do
            if card:IsValid() then
                card.Vybrannaya = (m == mapName)
                card:UpdateAvatars(self.Votes[m] or {})
            end
        end

        self:SinhronizirovatPoryadok(mapName)
        self:PereRisovka()
        if self.KnopkaOst then
            self.KnopkaOst.Vybrannaya = (mapName == 'stay')
            for _, av in ipairs(self.KnopkaOst.AvatarkiOst) do if av:IsValid() then av:Remove() end end
            self.KnopkaOst.AvatarkiOst = {}
            for _, sid64 in ipairs(self.Votes['stay'] or {}) do
                local ply = player.GetBySteamID64(sid64)
                if IsValid(ply) then
                    local av = vgui.Create('AvatarImage', self.KnopkaOst)
                    av:SetPlayer(ply, 32)
                    av:SetPaintedManually(false)
                    table.insert(self.KnopkaOst.AvatarkiOst, av)
                end
            end
            self.KnopkaOst:InvalidateLayout()
        end
    end

    function PanelGolosovaniya:ZapolnitKartami(maps)
        self.MapsInner:Clear()
        self.Kartochki = {}
        self.KartochkiOrder = {}

        local spisokKart = {}
        for _, m in ipairs(maps) do
            if m ~= 'stay' then table.insert(spisokKart, m) end
        end
        PeremeshatMassiv(spisokKart, self.DeckSeed)
        self.BazoviyPoryadok = table.Copy(spisokKart)

        for _, m in ipairs(spisokKart) do
            local card = vgui.Create('RTVMapCard', self.MapsInner)
            card:Setup(m, self)
            card:SetAlpha(255)
            self.Kartochki[m] = card
            table.insert(self.KartochkiOrder, m)
        end
        self:SinhronizirovatPoryadok()
        timer.Simple(0, function() if IsValid(self) then self:PereRisovka(true) end end)
    end

    function PanelGolosovaniya:SinhronizirovatPoryadok(mapName)
        if not self.BazoviyPoryadok then return end

        if mapName and mapName ~= 'stay' and self.Kartochki[mapName] then
            table.RemoveByValue(self.KartochkiOrder, mapName)
            table.insert(self.KartochkiOrder, 1, mapName)
        end

        local noviyPoryadok = {}
        local dobavleno = {}
        for _, currentMap in ipairs(self.KartochkiOrder) do
            if #(self.Votes[currentMap] or {}) > 0 then
                table.insert(noviyPoryadok, currentMap)
                dobavleno[currentMap] = true
            end
        end
        for _, currentMap in ipairs(self.BazoviyPoryadok) do
            if not dobavleno[currentMap] then
                table.insert(noviyPoryadok, currentMap)
            end
        end
        self.KartochkiOrder = noviyPoryadok
    end

    function PanelGolosovaniya:PereRisovka(animatePoyavlenie) --scolko vsego mi mosem razmestit kartochek y igroka na ekrane
        local cardCount = #self.KartochkiOrder
        if cardCount == 0 then return end
        local parentW = self.MapsContainer:GetWide()
        if parentW <= 0 then return end
        local cols = math.max(4, math.min(6, math.floor(parentW / 130)))
        local spacing = 8
        local totalSpacing = spacing * (cols + 1)
        local cardW = (parentW - totalSpacing) / cols
        local cardH = cardW

        for i, m in ipairs(self.KartochkiOrder) do
            local card = self.Kartochki[m]
            if card and card:IsValid() then
                local col = (i - 1) % cols
                local row = math.floor((i - 1) / cols)
                local x = spacing + col * (cardW + spacing)
                local y = spacing + row * (cardH + spacing)

                card:SetSize(cardW, cardH)

                if animatePoyavlenie then
                    card:SetAlpha(255)
                    card:SetPos(x, y)
                else
                    -- plavnaya animaciya pri perestanovke kartochek mestami
                    card:AlphaTo(255, 0.15, 0)
                    card:MoveTo(x, y, 0.3, 0, 0.3)
                end
            end
        end
        local totalRows = math.ceil(cardCount / cols)
        self.MapsInner:SetSize(parentW, totalRows * (cardH + spacing) + spacing)
    end

    function PanelGolosovaniya:PerformLayout(w, h)
        self:PereRisovka()
        if self.KnopkaOst then self.KnopkaOst:SetPos(w * 0.62, ScrH() * 0.065) end
    end

    function PanelGolosovaniya:Paint(w, h)
        self.Fon(self, w, h)
    end
    vgui.Register('ModernRTVPanel', PanelGolosovaniya, 'DPanel')

    --Esli xot ktoto skazet chto eto jbt to ya naxyi zastrlus
    function CloseRTV()
        if RTV_CloseTimer then
            timer.Remove("RTV_Close")
            RTV_CloseTimer = nil
        end
        if RTV_Music then
            RTV_Music:Stop()
            RTV_Music = nil
        end
        if IsValid(RTVPanel) then
            RTVPanel:Remove()
            RTVPanel = nil
        end
    end

    function OpenRTVPanel(maps, endTime, votes)
        CloseRTV()  -- убьёт старую панель, таймер и музыку
        if not maps or #maps == 0 then return end
        RTVPanel = vgui.Create('ModernRTVPanel')
        RTVPanel.VoteMaps = maps
        RTVPanel.VoteEndTime = endTime
        RTVPanel.TotalDuration = endTime - CurTime()
        RTVPanel.Votes = votes or {}
        RTVPanel.DeckSeed = endTime
        RTVPanel.MoyGolos = nil
        for mapName, voters in pairs(RTVPanel.Votes) do
            for _, sid64 in ipairs(voters) do
                if sid64 == RTVPanel.MoySteamID64 then
                    RTVPanel.MoyGolos = mapName
                    break
                end
            end
            if RTVPanel.MoyGolos then break end
        end
        RTVPanel:ZapolnitKartami(maps)

        RTV_Music = CreateSound(LocalPlayer(), "rtv/rtv_musica.wav")
        RTV_Music:Play()
    end

    net.Receive('ZB_RockTheVote_start', function()
        local maps = net.ReadTable()
        local endTime = net.ReadFloat()
        CachedMaps, CachedEndTime, CachedVotes = maps, endTime, {}
        OpenRTVPanel(maps, endTime, {})
    end)

    net.Receive('ZB_RockTheVote_voteCLreg', function()
        local votes = net.ReadTable()
        CachedVotes = votes
        if IsValid(RTVPanel) then
            local izmenennayaKarta = nil
            for mapName, voters in pairs(votes) do
                if mapName ~= 'stay' and #voters > #(RTVPanel.Votes[mapName] or {}) then
                    izmenennayaKarta = mapName
                    break
                end
            end
            RTVPanel.Votes = votes
            RTVPanel.MoyGolos = nil
            for mapName, voters in pairs(votes) do
                for _, sid64 in ipairs(voters) do
                    if sid64 == RTVPanel.MoySteamID64 then
                        RTVPanel.MoyGolos = mapName
                        break
                    end
                end
                if RTVPanel.MoyGolos then break end
            end
            for map, card in pairs(RTVPanel.Kartochki) do
                if card:IsValid() then
                    card:UpdateAvatars(votes[map] or {})
                    card.Vybrannaya = (map == RTVPanel.MoyGolos)
                end
            end
            RTVPanel:SinhronizirovatPoryadok(izmenennayaKarta)
            RTVPanel:PereRisovka()
            if RTVPanel.KnopkaOst then
                RTVPanel.KnopkaOst.Vybrannaya = (RTVPanel.MoyGolos == 'stay')
                for _, av in ipairs(RTVPanel.KnopkaOst.AvatarkiOst) do av:Remove() end
                RTVPanel.KnopkaOst.AvatarkiOst = {}
                for _, sid64 in ipairs(votes['stay'] or {}) do
                    local ply = player.GetBySteamID64(sid64)
                    if IsValid(ply) then
                        local av = vgui.Create('AvatarImage', RTVPanel.KnopkaOst)
                        av:SetPlayer(ply, 32)
                        av:SetPaintedManually(false)
                        table.insert(RTVPanel.KnopkaOst.AvatarkiOst, av)
                    end
                end
                RTVPanel.KnopkaOst:InvalidateLayout()
            end
        end
    end)

    net.Receive('ZB_RockTheVote_end', function()
        local winner = net.ReadString()
        CachedMaps = nil
        if IsValid(RTVPanel) then
            RTVPanel.WinnerMap = winner
            if winner ~= 'stay' and RTVPanel.Kartochki[winner] then
                RTVPanel.Kartochki[winner].Pobeditel = true
            elseif winner == 'stay' and RTVPanel.KnopkaOst then
                RTVPanel.KnopkaOst.Pobeditel = true
                local oldPaint = RTVPanel.KnopkaOst.Paint
                RTVPanel.KnopkaOst.Paint = function(pnl, w, h)
                    oldPaint(pnl, w, h)
                    if pnl.Pobeditel then
                        local alpha = math.abs(math.sin(RealTime() * 10)) * 255
                        surface.SetDrawColor(255,255,0,alpha)
                        surface.DrawOutlinedRect(0,0,w,h,3)
                    end
                end
            end
            RTVPanel.VoteCooldown = math.huge
            surface.PlaySound('buttons/combine_button_locked.wav')
            if RTV_CloseTimer then timer.Remove("RTV_Close") end
            RTV_CloseTimer = "RTV_Close"
            timer.Create("RTV_Close", 5, 1, function() CloseRTV() end)
        end
    end)

    net.Receive('RTVMenu', function()
        if IsValid(RTVPanel) then RTVPanel:MoveToFront() return end
        if CachedMaps and CachedEndTime > CurTime() then
            OpenRTVPanel(CachedMaps, CachedEndTime, CachedVotes)
        end
    end)
end