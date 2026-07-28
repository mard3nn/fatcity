if SERVER then
    util.AddNetworkString("OpenDonateMenu")
    util.AddNetworkString("DonateLogAdmin")

    hook.Add("ShowSpare1", "DonateMenuF3", function(ply)
        net.Start("OpenDonateMenu")
        net.Send(ply)
    end)
end

if CLIENT then
    local donateItems = {
        { name = "VIP Статус", price = "349", desc = "Расширенный доступ к функционалу системы." },
        { name = "Модератор", price = "700", desc = "Привилегии модерации. Лимит: 0/3 варнов." },
        { name = "Администратор", price = "1200", desc = "Привилегии администрирования. Лимит: 0/5 варнов." },
        { name = "Супер админ", price = "3500", desc = "Полный доступ к системе. Лимит: 0/7 варнов." },
        { name = "Друг создателя", price = "4500", desc = "Эксклюзивный статус. Лимит: 0/12 варнов." },
        { name = "Снятие Варна", price = "350", desc = "Аннулирование одного дисциплинарного взыскания." },
        { name = "Снятие бана/мута", price = "300", desc = "Досрочное восстановление доступа." },
        { name = "Снятие бана (Читы)", price = "1000", desc = "Полная амнистия профиля." }
    }

    local function LerpColor(t, c1, c2)
        return Color(
            Lerp(t, c1.r, c2.r),
            Lerp(t, c1.g, c2.g),
            Lerp(t, c1.b, c2.b),
            Lerp(t, c1.a, c2.a)
        )
    end

    function OpenDonateMenu()
        if IsValid(DonateFrame) then DonateFrame:Remove() end

        local startTime = CurTime()
        local frame = vgui.Create("DFrame")
        frame:SetSize(900, 650)
        frame:SetTitle("")
        frame:Center()
        frame:MakePopup()
        frame:SetSkin("ZCity")
        DonateFrame = frame

        frame.Paint = function(self, w, h)
            local anim = math.Clamp((CurTime() - startTime) * 3, 0, 1)
            
            if hg and hg.DrawBlur then hg.DrawBlur(self, 8 * anim) end
            
            surface.SetDrawColor(10, 10, 10, 245 * anim)
            surface.DrawRect(0, 0, w, h)

            surface.SetDrawColor(255, 255, 255, 2 * anim)
            for i = 0, w, 30 do surface.DrawRect(i, 0, 1, h) end
            for i = 0, h, 30 do surface.DrawRect(0, i, w, 1) end

            local scan = (CurTime() * 150) % (h + 100) - 50
            surface.SetDrawColor(hg.VGUI.MainColor.r, hg.VGUI.MainColor.g, hg.VGUI.MainColor.b, 15 * anim)
            surface.DrawRect(0, scan, w, 2)
            
            surface.SetDrawColor(hg.VGUI.MainColor.r, hg.VGUI.MainColor.g, hg.VGUI.MainColor.b, 200 * anim)
            surface.DrawOutlinedRect(0, 0, w, h, 1)

            local cs = 20
            surface.SetDrawColor(hg.VGUI.MainColor)
            surface.DrawRect(0, 0, cs, 3) surface.DrawRect(0, 0, 3, cs)
            surface.DrawRect(w-cs, 0, cs, 3) surface.DrawRect(w-3, 0, 3, cs)
            surface.DrawRect(0, h-3, cs, 3) surface.DrawRect(0, h-cs, 3, cs)
            surface.DrawRect(w-cs, h-3, cs, 3) surface.DrawRect(w-3, h-cs, 3, cs)

            surface.SetDrawColor(0, 0, 0, 180 * anim)
            surface.DrawRect(0, 0, w, 45)
            surface.SetDrawColor(hg.VGUI.MainColor.r, hg.VGUI.MainColor.g, hg.VGUI.MainColor.b, 255 * anim)
            surface.DrawRect(0, 44, w, 1)

            draw.SimpleText("ДОНАТЫ", "ZCity_Fixed_Tiny", w/2, 22, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        local scroll = vgui.Create("DScrollPanel", frame)
        scroll:Dock(FILL)
        scroll:DockMargin(20, 60, 20, 20)

        local layout = vgui.Create("DIconLayout", scroll)
        layout:Dock(FILL)
        layout:SetSpaceX(20)
        layout:SetSpaceY(15)

        for i, item in ipairs(donateItems) do
            local panel = layout:Add("DPanel")
            panel:SetSize(270, 170)
            panel.hoverAnim = 0
            panel.entryTime = startTime + (i * 0.1)

            panel.Paint = function(self, w, h)
                local f = math.Clamp((CurTime() - self.entryTime) * 2, 0, 1)
                if f <= 0 then return end
                
                self:SetAlpha(f * 255)
                
                local target = self:IsHovered() and 1 or 0
                self.hoverAnim = Lerp(FrameTime() * 10, self.hoverAnim, target)

                surface.SetDrawColor(15, 15, 15, 220 * f)
                surface.DrawRect(0, 0, w, h)
                
                local borderColor = LerpColor(self.hoverAnim, Color(100, 100, 100, 50), hg.VGUI.MainColor)
                borderColor.a = borderColor.a * f
                surface.SetDrawColor(borderColor)
                surface.DrawOutlinedRect(0, 0, w, h, 1)
                
                DisableClipping(true)
                render.SetScissorRect(0, 0, ScrW(), ScrH(), true) 
                DisableClipping(false)
            end

            panel.OnCursorEntered = function(self)
                surface.PlaySound("arccw_uc/common/cloth_1.ogg")
            end

            local name = vgui.Create("DLabel", panel)
            name:SetText(item.name)
            name:SetFont("ZCity_Fixed_Tiny")
            name:Dock(TOP)
            name:SetContentAlignment(5)
            name:DockMargin(0, 10, 0, 0)
            name:SetTextColor(hg.VGUI.MainColor)

            local desc = vgui.Create("DLabel", panel)
            desc:SetText(item.desc)
            desc:SetFont("ZCity_Tiny")
            desc:Dock(FILL)
            desc:SetContentAlignment(5)
            desc:DockMargin(10, 0, 10, 0)
            desc:SetWrap(true)
            desc:SetTextColor(Color(180, 180, 180))

            local buy = vgui.Create("DButton", panel)
            buy:SetText("КУПИТЬ ЗА " .. item.price .. "₽")
            buy:SetTall(35)
            buy:Dock(BOTTOM)
            buy:DockMargin(10, 5, 10, 10)
            buy:SetFont("ZCity_Fixed_Tiny")
            buy:SetSkin("ZCity")
            buy:SetTextColor(color_white)

            buy.OnCursorEntered = function(self)
                surface.PlaySound("arccw_uc/common/cloth_1.ogg")
            end

            buy.DoClick = function()
                local card = "2200 7012 1206 3041"
                Derma_Query(
                    "ЭЛЕКТРОННЫЙ ЧЕК\n\nУслуга: " .. item.name .. "\nЦена: " .. item.price .. "₽\n\nКарта для перевода:\n" .. card .. "\n\nНомер карты будет скопирован автоматически.",
                    "ПОДТВЕРЖДЕНИЕ ПЛАТЕЖА",
                    "ОПЛАТИТЬ", function()
                        SetClipboardText(card:gsub("%s+", ""))
                        chat.AddText(hg.VGUI.MainColor, "[СИСТЕМА] ", color_white, "Реквизиты скопированы в буфер.")
                        gui.OpenURL("https://www.tinkoff.ru/rm/r_eFvLWfkaQk.RGmwAZkrar/AnthO35191?money=" .. item.price)
                        
                        net.Start("DonateLogAdmin")
                        net.WriteString(item.name)
                        net.WriteString(item.price)
                        net.SendToServer()
                        
                        frame:Close()
                    end,
                    "ЗАКРЫТЬ"
                )
            end
        end
    end

    net.Receive("OpenDonateMenu", OpenDonateMenu)

    local function CreateEscButton()
        if IsValid(DonateEscBtn) then DonateEscBtn:Remove() end
        
        DonateEscBtn = vgui.Create("DButton")
        DonateEscBtn:SetSize(160, 45)
        DonateEscBtn:SetPos(30, ScrH() - 70)
        DonateEscBtn:SetText("DONATE")
        DonateEscBtn:SetFont("ZCity_Small")
        DonateEscBtn:SetTextColor(color_white)
        DonateEscBtn:SetSkin("ZCity")
        DonateEscBtn.lerpAnim = 0

        DonateEscBtn.Paint = function(self, w, h)
            local target = self:IsHovered() and 1 or 0
            self.lerpAnim = Lerp(FrameTime() * 8, self.lerpAnim, target)

            surface.SetDrawColor(LerpColor(self.lerpAnim, Color(0, 0, 0, 200), hg.VGUI.MainColor))
            surface.DrawRect(0, 0, w, h)
            
            surface.SetDrawColor(hg.VGUI.MainColor)
            surface.DrawOutlinedRect(0, 0, w, h, 2)
            
            if self:IsHovered() then
                surface.SetDrawColor(255, 255, 255, 30)
                surface.DrawRect(0, 0, w, h)
            end
        end

        DonateEscBtn.DoClick = function()
            OpenDonateMenu()
        end
    end

    hook.Add("Think", "DonateMenuEscCheck", function()
        if gui and gui.IsGameMenuVisible and gui.IsGameMenuVisible() then
            if not IsValid(DonateEscBtn) then CreateEscButton() end
            DonateEscBtn:SetVisible(true)
        else
            if IsValid(DonateEscBtn) then DonateEscBtn:SetVisible(false) end
        end
    end)
end

if SERVER then
    net.Receive("DonateLogAdmin", function(len, ply)
        local itemName = net.ReadString()
        local itemPrice = net.ReadString()
        
        print("[DONATE] " .. ply:Nick() .. " (" .. ply:SteamID() .. ") хочет: " .. itemName .. " за " .. itemPrice .. " руб.")
        
        for _, admin in ipairs(player.GetAll()) do
            if admin:IsAdmin() then
                admin:ChatPrint("[ДОНАТ] " .. ply:Nick() .. " перешел к оплате " .. itemName .. " (" .. itemPrice .. " руб.). Проверьте банк!")
            end
        end
    end)
end