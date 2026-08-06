if SERVER then
    util.AddNetworkString("OpenDonateMenu")
    util.AddNetworkString("DonateLogAdmin")
end

if CLIENT then
    local DISCORD_INVITE = "https://discord.gg/TFMuxmm3n3"
    local DISCORD_CHANNEL = "#⭐・донат"

    local donateItems = {
        { name = "VIP", price = "299", desc = "Приоритетный вход, префикс и VIP-возможности." },
        { name = "Модератор", price = "649", desc = "Привилегии модерации. Лимит: 0/3 варнов." },
        { name = "Администратор", price = "1199", desc = "Привилегии администрирования. Лимит: 0/5 варнов." },
        { name = "Суперадмин", price = "3499", desc = "Полный доступ к системе. Лимит: 0/7 варнов." },
        { name = "MVP", price = "4500", desc = "Эксклюзивный статус. Лимит: 0/12 варнов." }
    }

    local function LerpColor(t, c1, c2)
        return Color(
            Lerp(t, c1.r, c2.r),
            Lerp(t, c1.g, c2.g),
            Lerp(t, c1.b, c2.b),
            Lerp(t, c1.a, c2.a)
        )
    end

    surface.CreateFont("GOMI_DonateTitle", {
        font = "Bahnschrift",
        size = ScreenScale(40),
        weight = 800,
        antialias = true
    })
    surface.CreateFont("GOMI_DonateBtn", {
        font = "Bahnschrift",
        size = ScreenScale(13),
        weight = 500,
        antialias = true,
        extended = true
    })

    local WBR_COLORS = {
        Color(255, 255, 255, 255), -- W
        Color(60, 130, 255, 255),  -- B
        Color(230, 45, 45, 255)    -- R
    }
    local function GetWBRColor(idx)
        return WBR_COLORS[(idx - 1) % 3 + 1]
    end

    function OpenDonateMenu()
        if IsValid(DonateFrame) then DonateFrame:Remove() end

        local startTime = CurTime()
        local frame = vgui.Create("DFrame")
        frame:SetSize(ScrW(), ScrH())
        frame:SetPos(0, 0)
        frame:SetTitle("")
        frame:SetDraggable(false)
        frame:ShowCloseButton(false)
        frame:MakePopup()
        frame:SetSkin("ZCity")
        DonateFrame = frame

        frame.OnKeyCodePressed = function(self, key)
            if key == KEY_ESCAPE then
                self:Close()
            end
        end

        frame.Paint = function(self, w, h)
            local anim = math.Clamp((CurTime() - startTime) * 3, 0, 1)

            if hg and hg.DrawBlur then hg.DrawBlur(self, 8 * anim) end

            surface.SetDrawColor(10, 10, 15, 220 * anim)
            surface.DrawRect(0, 0, w, h)

            local grid = ScreenScale(25)
            local off = (CurTime() * 12) % grid
            surface.SetDrawColor(hg.VGUI.MainColor.r, hg.VGUI.MainColor.g, hg.VGUI.MainColor.b, 15 * anim)
            for i = -1, math.ceil(w / grid) + 1 do surface.DrawRect(i * grid - off, 0, 1, h) end
            for i = -1, math.ceil(h / grid) + 1 do surface.DrawRect(0, i * grid + off, w, 1) end
        end

        local title = vgui.Create("DLabel", frame)
        title:SetPos(ScreenScale(20), ScreenScale(20))
        title:SetFont("GOMI_DonateTitle")
        title:SetText("ДОНАТЫ")
        title:SetTextColor(Color(0, 0, 0, 0))
        title.Paint = function(sel, w, h)
            local a = math.Clamp((CurTime() - startTime) * 3, 0, 1) * 255
            local sweepPos = (CurTime() - startTime) * 12.0
            local soft = 1.4
            local s = "ДОНАТЫ"
            surface.SetFont("GOMI_DonateTitle")
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
                draw.SimpleText(ch, "GOMI_DonateTitle", cx + 2, 2, Color(0, 0, 0, 150 * (a / 255)))
                draw.SimpleText(ch, "GOMI_DonateTitle", cx, 0, col)
                cx = cx + cw
            end
        end

        local closeBtn = vgui.Create("DButton", frame)
        closeBtn:SetText("")
        closeBtn:SetSize(ScreenScale(28), ScreenScale(28))
        closeBtn:SetPos(frame:GetWide() - ScreenScale(48), ScreenScale(16))
        closeBtn:SetCursor("hand")
        closeBtn.hover = 0
        closeBtn.Paint = function(sel, w, h)
            sel.hover = Lerp(FrameTime() * 10, sel.hover, sel:IsHovered() and 1 or 0)
            if sel.hover > 0.01 then
                draw.RoundedBox(4, 0, 0, w, h, Color(200, 40, 40, 180 * sel.hover))
            end
            draw.SimpleText("X", "GOMI_DonateBtn", w / 2, h / 2, Color(255 - 80 * sel.hover, 180 + 60 * sel.hover, 180 + 60 * sel.hover, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        closeBtn.DoClick = function()
            frame:Close()
        end

        local notice = vgui.Create("DPanel", frame)
        notice:Dock(TOP)
        notice:DockMargin(ScreenScale(20), ScreenScale(90), ScreenScale(20), 0)
        notice:SetTall(ScreenScale(62))
        notice.Paint = function(self, w, h)
            local anim = math.Clamp((CurTime() - startTime) * 3, 0, 1)

            surface.SetDrawColor(15, 15, 15, 220 * anim)
            surface.DrawRect(0, 0, w, h)

            surface.SetDrawColor(hg.VGUI.MainColor.r, hg.VGUI.MainColor.g, hg.VGUI.MainColor.b, 180 * anim)
            surface.DrawOutlinedRect(0, 0, w, h, 1)

            draw.SimpleText("ОПЛАТА ПРОХОДИТ НА НАШЕМ DISCORD СЕРВЕРЕ", "ZCity_Fixed_Tiny", 15, h / 2 - 12, hg.VGUI.MainColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText("Выберите услугу и завершите оплату в канале " .. DISCORD_CHANNEL, "ZCity_Tiny", 15, h / 2 + 11, Color(180, 180, 180, 255 * anim), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end

        local openDiscord = vgui.Create("DButton", notice)
        openDiscord:Dock(RIGHT)
        openDiscord:DockMargin(10, 12, 12, 12)
        openDiscord:SetWide(210)
        openDiscord:SetText("ОТКРЫТЬ DISCORD")
        openDiscord:SetFont("ZCity_Fixed_Tiny")
        openDiscord:SetSkin("ZCity")
        openDiscord:SetTextColor(color_white)

        openDiscord.OnCursorEntered = function(self)
            surface.PlaySound("arccw_uc/common/cloth_1.ogg")
        end

        openDiscord.DoClick = function()
            SetClipboardText(DISCORD_INVITE)
            gui.OpenURL(DISCORD_INVITE)
            chat.AddText(hg.VGUI.MainColor, "[ДОНАТ] ", color_white, "Ссылка на Discord скопирована: " .. DISCORD_INVITE)
        end

        local scroll = vgui.Create("DScrollPanel", frame)
        scroll:Dock(FILL)
        scroll:DockMargin(ScreenScale(20), ScreenScale(15), ScreenScale(20), ScreenScale(20))

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
            buy:SetText("ОФОРМИТЬ ЗА " .. item.price .. "₽")
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
                Derma_Query(
                    "ЗАЯВКА НА ДОНАТ\n\nУслуга: " .. item.name .. "\nЦена: " .. item.price .. "₽\n\nОплата происходит на нашем Discord сервере,\nв канале " .. DISCORD_CHANNEL .. ".\n\nЗавершите оплату там и напишите название услуги.\nСсылка будет скопирована автоматически.",
                    "ОПЛАТА В DISCORD",
                    "ОТКРЫТЬ DISCORD", function()
                        SetClipboardText(DISCORD_INVITE)
                        chat.AddText(hg.VGUI.MainColor, "[ДОНАТ] ", color_white, "Завершите оплату в Discord, канал " .. DISCORD_CHANNEL .. ". Ссылка: " .. DISCORD_INVITE)
                        gui.OpenURL(DISCORD_INVITE)

                        net.Start("DonateLogAdmin")
                        net.WriteString(item.name)
                        net.WriteString(item.price)
                        net.SendToServer()

                        frame:Close()
                    end,
                    "ОТМЕНА"
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
        
        print("[DONATE] " .. ply:Nick() .. " (" .. ply:SteamID() .. ") оформил заявку: " .. itemName .. " за " .. itemPrice .. " руб. (оплата в Discord)")
        
        for _, admin in ipairs(player.GetAll()) do
            if admin:IsAdmin() then
                admin:ChatPrint("[ДОНАТ] " .. ply:Nick() .. " оформил заявку на " .. itemName .. " (" .. itemPrice .. " руб.). Проверьте канал доната в Discord!")
            end
        end
    end)
end
