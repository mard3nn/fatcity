surface.CreateFont("GOMI_WepTitle", {
    font = "Bahnschrift",
    size = ScreenScale(14),
    weight = 600,
    antialias = true
})
surface.CreateFont("GOMI_WepSmall", {
    font = "Bahnschrift",
    size = ScreenScale(8),
    weight = 500,
    antialias = true
})

local scrW, scrH = ScrW(), ScrH()
local gradientMat = Material("vgui/gradient-d")

hg = hg or {}
hg.WeaponSelector = hg.WeaponSelector or {}
local WS = hg.WeaponSelector

function WS.GetPrintName(self)
    local class = self:GetClass()
    local phrase = language.GetPhrase(class)
    return phrase ~= class and phrase or self:GetPrintName() or class
end

WS.Show = 0
WS.Transparent = 0
WS.LastSelectedSlot = 0
WS.LastSelectedSlotPos = 0
WS.SelectedSlot = 0
WS.SelectedSlotPos = 0
WS.BoxAnim = WS.BoxAnim or {}
WS.TypeState = WS.TypeState or {}
WS.NameScroll = WS.NameScroll or {}
WS.Anim = WS.Anim or {}

local function EaseOutCubic(t)
    t = math.Clamp(t, 0, 1)
    return 1 - (1 - t) ^ 3
end

function WS.GetAnimValue(id, target, speed)
    WS.Anim[id] = LerpFT(speed or 0.18, WS.Anim[id] or 0, target)
    return WS.Anim[id]
end

function WS.DrawText(text, font, x, y, color, alignX, alignY)
    draw.DrawText(text, font, x + 1, y + 1, Color(0, 0, 0, 180), alignX, alignY)
    draw.DrawText(text, font, x, y, color, alignX, alignY)
end

function WS.GetSelectedWeapon()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    local weapons = WS.GetWeaponTable(ply)
    return weapons[WS.SelectedSlot] and weapons[WS.SelectedSlot][WS.SelectedSlotPos]
        or weapons[WS.LastSelectedSlot][WS.LastSelectedSlotPos]
        or weapons[0] and weapons[0][1]
end

function WS.GetWeaponTable(ply)
    if not IsValid(ply) or not ply:Alive() then return end
    local all = ply:GetWeapons()
    local tbl = {[0]={}, [1]={}, [2]={}, [3]={}, [4]={}, [5]={}}
    table.sort(all, function(a, b) return (a.SlotPos or 0) > (b.SlotPos or 0) end)
    for _, wep in ipairs(all) do
        local slot = wep.Slot or 0
        table.insert(tbl[slot], wep)
    end
    return tbl
end

local function get_active_tool(ply, tool)
    local activeWep = ply:GetActiveWeapon()
    if not IsValid(activeWep) or activeWep:GetClass() ~= "gmod_tool" or activeWep.Mode ~= tool then return end
    return activeWep:GetToolObject(tool)
end

local function canUseSelector(ply)
    local wep = ply:GetActiveWeapon()
    local tool = get_active_tool(ply, "submaterial")
    if tool and IsValid(ply:GetEyeTraceNoCursor().Entity) then return true end
    return IsAiming(ply)
        or (IsValid(wep) and wep:GetClass() == "weapon_physgun" and ply:KeyDown(IN_ATTACK))
        or (ply.organism and ply.organism.pain and ply.organism.pain > 60)
        or GetGlobalBool("RadialInventory", false)
end

function WS.HookWeapon(wep)
    if not IsValid(wep) or wep.IsScrambledHooked then return end
    local oldPrint = wep.PrintWeaponInfo
    wep.PrintWeaponInfo = function(self, x, y, alpha)
        local oldInst, oldPurp, oldDesc, oldAuth = self.Instructions, self.Purpose, self.Description, self.Author
        self.Instructions = WS.Scramble(self.Instructions)
        self.Purpose = WS.Scramble(self.Purpose)
        self.Description = WS.Scramble(self.Description)
        self.Author = WS.Scramble(self.Author)
        if oldPrint then
            oldPrint(self, x, y, alpha)
        elseif self.DrawWeaponInfoBox then
            self:DrawWeaponInfoBox(x, y, alpha)
        end
        self.Instructions = oldInst
        self.Purpose = oldPurp
        self.Description = oldDesc
        self.Author = oldAuth
    end
    wep.IsScrambledHooked = true
end

function WS.WeaponSelectorDraw(ply)
    if not IsValid(ply) or not ply:Alive() or GetGlobalBool("RadialInventory", false) then return end

    local isShown = WS.Show > CurTime()
    WS.Transparent = LerpFT(0.12, WS.Transparent, isShown and 1 or 0)

    if not isShown and WS.Transparent < 0.02 then
        WS.BoxAnim = {}
        WS.TypeState = {}
        WS.SelectedSlot = WS.LastSelectedSlot
        WS.SelectedSlotPos = 0
        return
    end

    local weapons = WS.GetWeaponTable(ply)
    local selected = WS.GetSelectedWeapon()
    if not IsValid(selected) then return end

    local slotCount = 0
    for i = 0, 5 do
        if weapons[i] and #weapons[i] > 0 then
            slotCount = slotCount + 1
        end
    end

    local slotW = scrW * 0.09
    local offset = 0

    for i = 0, 5 do
        local slot = weapons[i]
        if not slot or #slot == 0 then continue end

        local centerX = scrW / 2 + ((offset - (slotCount / 2)) * slotW) + slotW / 2
        local baseY = scrH * 0.05

        WS.DrawText(i + 1, "GOMI_WepTitle", centerX, baseY - ScreenScale(12), Color(215, 215, 215, WS.Transparent * 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

        local lastH = 0
        for idx, wep in ipairs(slot) do
            local isSel = (selected == wep)
            WS.BoxAnim[wep] = WS.BoxAnim[wep] or {h = 2}
            local targetH = isSel and scrH * 0.12 or scrH * 0.025
            WS.BoxAnim[wep].h = LerpFT(0.2, WS.BoxAnim[wep].h, targetH)
            local itemH = WS.BoxAnim[wep].h
            if idx > 1 and selected == slot[idx-1] then
                lastH = scrH * 0.095
            end
            local y = (scrH * 0.025) * (idx-1) + baseY + lastH
            local w = slotW
            local x = centerX - w / 2
            local alpha = WS.Transparent * 255

            draw.RoundedBox(0, x, y, w, itemH, ColorAlpha(Color(49, 22, 22), alpha * 0.82))
            surface.SetDrawColor(44, 40, 40, alpha * (isSel and 0.9 or 0.2))
            surface.SetMaterial(gradientMat)
            surface.DrawTexturedRect(x, y, w, itemH)

            local cell = 18
            local driftX = (CurTime() * 18) % cell
            local driftY = (CurTime() * 10) % cell
            render.SetScissorRect(x, y, x + w, y + itemH, true)
            local pulse = 0.85 + math.abs(math.sin(CurTime() * 2.5)) * 0.15
            surface.SetDrawColor(200, 200, 200, alpha * 0.15 * pulse)
            for gx = -driftX, w, cell do
                surface.DrawRect(x + gx, y, 1, itemH)
            end
            for gy = -driftY, itemH, cell do
                surface.DrawRect(x, y + gy, w, 1)
            end
            render.SetScissorRect(0, 0, 0, 0, false)

            if isSel then
                surface.SetDrawColor(180, 180, 180, alpha)
                surface.DrawOutlinedRect(x, y, w, itemH, 2)
                for j = 1, 6 do
                    surface.SetDrawColor(180, 180, 180, alpha * (0.5 / j))
                    surface.DrawOutlinedRect(x - j, y - j, w + j*2, itemH + j*2, 1)
                end
            end

            if isSel then
                local name = WS.Typewriter(WS.GetPrintName(wep), wep:GetClass() .. "_name", 20)
                surface.SetFont("GOMI_WepSmall")
                local tw, th = surface.GetTextSize(name)
                local pad = ScreenScale(2)
                local maxW = w - pad * 2
                local targetScroll = (tw > maxW) and -(tw - maxW) or 0
                WS.NameScroll[wep] = LerpFT(0.3, WS.NameScroll[wep] or 0, targetScroll)
                render.SetScissorRect(x, y, x + w, y + itemH, true)
                local textY = y + ScreenScale(2)
                if tw <= maxW then
                    WS.DrawText(name, "GOMI_WepSmall", x + w / 2, textY, Color(215, 215, 215), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
                else
                    WS.DrawText(name, "GOMI_WepSmall", x + pad + WS.NameScroll[wep], textY, Color(215, 215, 215), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                end
                render.SetScissorRect(0, 0, 0, 0, false)
            else
                local name = WS.GetPrintName(wep)
                surface.SetFont("GOMI_WepSmall")
                local tw, _ = surface.GetTextSize(name)
                local maxW = w - ScreenScale(4)
                render.SetScissorRect(x, y, x + w, y + itemH, true)
                local textY = y + ScreenScale(1)
                if tw <= maxW then
                    WS.DrawText(name, "GOMI_WepSmall", x + w / 2, textY, Color(215, 215, 215), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
                else
                    local trimmed = name
                    while #trimmed > 1 and surface.GetTextSize(trimmed .. "...") > maxW do
                        trimmed = trimmed:sub(1, -2)
                    end
                    WS.DrawText(trimmed .. "...", "GOMI_WepSmall", x + w / 2, textY, Color(215, 215, 215), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
                end
                render.SetScissorRect(0, 0, 0, 0, false)
            end

            if isSel and wep.DrawWeaponSelection then
                WS.HookWeapon(wep)
                wep:DrawWeaponSelection(x + 5, y + scrH * 0.025, w - 10, itemH - scrH * 0.05, alpha)
            end
        end
        offset = offset + 1
    end
end

local keyMap = {slot1 = 1, slot2 = 2, slot3 = 3, slot4 = 4, slot5 = 5, slot6 = 6}

local function GetUpper(Weapons)
    if #LocalPlayer():GetWeapons() < 1 then return end
    WS.SelectedSlot = WS.SelectedSlot < 0 and 5 or WS.SelectedSlot - 1
    WS.SelectedSlotPos = Weapons[WS.SelectedSlot] and #Weapons[WS.SelectedSlot] or 0
    if Weapons[WS.SelectedSlot] == nil or Weapons[WS.SelectedSlot][WS.SelectedSlotPos] == nil then
        GetUpper(Weapons)
    end
end

local function GetDown(Weapons)
    if #LocalPlayer():GetWeapons() < 1 then return end
    WS.SelectedSlot = WS.SelectedSlot > 5 and 0 or WS.SelectedSlot + 1
    WS.SelectedSlotPos = 1
    if Weapons[WS.SelectedSlot] == nil or Weapons[WS.SelectedSlot][WS.SelectedSlotPos] == nil then
        GetDown(Weapons)
    end
end

local lastSlot = 0

function WS.ChangeSelectionWep(ply, key)
    if not IsValid(ply) or not ply:Alive() or GetGlobalBool("RadialInventory", false) then return end
    if ply.organism and ply.organism.otrub then return end
    if canUseSelector(ply) then return end

    local slot = keyMap[key]
    if slot or key == "invnext" or key == "invprev" or key == "lastinv" then
        local weapons = WS.GetWeaponTable(ply)
        WS.Show = CurTime() + 4
        surface.PlaySound("arc9_eft_shared/weapon_generic_rifle_spin" .. math.random(10) .. ".ogg")
        if slot then
            slot = slot - 1
            if lastSlot ~= slot then WS.SelectedSlotPos = 1 end
            local curSlot = weapons[slot]
            if curSlot and #curSlot > 0 then
                if lastSlot == slot then
                    WS.SelectedSlotPos = WS.SelectedSlotPos + 1
                    if WS.SelectedSlotPos > #curSlot then WS.SelectedSlotPos = 1 end
                else
                    WS.SelectedSlotPos = math.min(WS.SelectedSlotPos, #curSlot)
                    if WS.SelectedSlotPos == 0 then WS.SelectedSlotPos = 1 end
                end
            else
                WS.SelectedSlotPos = 1
            end
            WS.SelectedSlot = slot
            lastSlot = slot
            WS.BoxAnim = {}
            WS.TypeState = {}
        elseif key == "invprev" then
            WS.SelectedSlotPos = WS.SelectedSlotPos - 1
            if weapons[WS.SelectedSlot] and WS.SelectedSlotPos < 1 then GetUpper(weapons) end
            WS.BoxAnim = {}
            WS.TypeState = {}
        elseif key == "invnext" then
            WS.SelectedSlotPos = WS.SelectedSlotPos + 1
            if weapons[WS.SelectedSlot] and WS.SelectedSlotPos > #weapons[WS.SelectedSlot] then GetDown(weapons) end
            WS.BoxAnim = {}
            WS.TypeState = {}
        elseif key == "lastinv" and IsValid(WS.LastInv) then
            WS.Show = 0
            WS.LastInv = WS.LastInv or "weapon_hands_sh"
            local oldwep = ply:GetActiveWeapon()
            input.SelectWeapon(WS.LastInv)
            WS.LastInv = oldwep
        end
    end
end

function WS.SetActuallyWeapon(ply, cmd)
    if not IsValid(ply) or not ply:Alive() or GetGlobalBool("RadialInventory", false) then return end
    if (cmd:KeyDown(IN_ATTACK) or cmd:KeyDown(IN_ATTACK2)) and WS.Show > CurTime() then
        if WS.Selected and WS.Selected > CurTime() then
            cmd:RemoveKey(IN_ATTACK)
            cmd:RemoveKey(IN_ATTACK2)
        else
            cmd:RemoveKey(IN_ATTACK)
            cmd:RemoveKey(IN_ATTACK2)
            if IsValid(WS.GetSelectedWeapon()) then
                WS.LastInv = WS.LastInv ~= ply:GetActiveWeapon() and WS.LastInv or ply:GetActiveWeapon()
                input.SelectWeapon(WS.GetSelectedWeapon())
            end
            WS.LastSelectedSlot = WS.SelectedSlot
            WS.LastSelectedSlotPos = WS.SelectedSlotPos
            WS.Selected = CurTime() + 0.2
            WS.Show = CurTime() + 0.2
            surface.PlaySound("arc9_eft_shared/weapon_generic_spin" .. math.random(1, 10) .. ".ogg")
        end
    end
end

hook.Add("PlayerBindPress", "WeaponSelector_Bind", WS.ChangeSelectionWep)
hook.Add("HUDPaint", "WeaponSelector_Draw", function() WS.WeaponSelectorDraw(LocalPlayer()) end)
hook.Add("StartCommand", "WeaponSelector_StartCommand", WS.SetActuallyWeapon)

hook.Add("HUDShouldDraw", "WeaponSelector_HideDefault", function(name)
    if name == "CHudWeaponSelection" then return false end
end)

function WS.Scramble(target)
    target = tostring(target or "")
    if LocalPlayer().organism and LocalPlayer().organism.brain and LocalPlayer().organism.brain > 0.05 then
        local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+-=[]{}|;:,.<>?"
        local result = ""
        for i = 1, #target do
            if target:sub(i, i) == " " then
                result = result .. " "
            else
                result = result .. chars:sub(math.random(#chars), math.random(#chars))
            end
        end
        return result
    end
    return target
end

function WS.Typewriter(target, key, rate)
    target = WS.Scramble(target)
    local state = WS.TypeState[key] or {t = 0}
    local len = #target
    state.t = math.min(len, state.t + FrameTime() * (rate or 20))
    WS.TypeState[key] = state
    local progress = math.floor(state.t)
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+<>/?|\\"
    local out = ""
    for i = 1, len do
        local ch = target:sub(i, i)
        if ch == " " then
            out = out .. " "
        elseif i <= progress then
            out = out .. ch
        else
            out = out .. chars:sub(math.random(#chars), math.random(#chars))
        end
    end
    return out
end