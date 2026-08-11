--
hg = hg or {}
hg.WeaponSelector = hg.WeaponSelector or {}
local WS = hg.WeaponSelector

function WS.GetPrintName( self )
	local class = self:GetClass()
	local phrase = language.GetPhrase(class)
	return phrase ~= class and phrase or self:GetPrintName()
end

WS.Show = 0
WS.Transparent = 0
WS.Appear = 0
WS.LastSelectedSlot = 0
WS.LastSelectedSlotPos = 0

WS.SelectedSlot = 0
WS.SelectedSlotPos = 0

local function EaseSoft(t)
    return math.ease.InOutCubic(math.Clamp(t, 0, 1))
end

function WS.DrawText(text, font, posX, posY, color, textAlign, alphaMul)
    local a = (alphaMul or WS.Transparent) * 255
    draw.DrawText( text, font, posX + 2, posY + 2, ColorAlpha(color_black, a) ,textAlign )
    draw.DrawText( text, font, posX, posY, ColorAlpha(color, a) ,textAlign )
end

function WS.GetSelectedWeapon()
    if not IsValid( LocalPlayer() ) or not LocalPlayer():Alive() then return end
    local Weapons = WS.GetWeaponTable( LocalPlayer() )
    if not Weapons then return end
    local sel = Weapons[WS.SelectedSlot] and Weapons[WS.SelectedSlot][WS.SelectedSlotPos]
    if sel then return sel end
    local last = Weapons[WS.LastSelectedSlot] and Weapons[WS.LastSelectedSlot][WS.LastSelectedSlotPos]
    if last then return last end
    return Weapons[0] and Weapons[0][0]
end

function WS.GetWeaponTable( ply )
    if not IsValid( ply ) or not ply:Alive() then return end
    local WeaponsGet = ply:GetWeapons()
    local FormatedTable = {
        [0] = {}, [1] = {}, [2] = {}, [3] = {}, [4] = {}, [5] = {},
    }

    table.sort(WeaponsGet, function(a, b) return (a.SlotPos or 0) > (b.SlotPos or 0) end)

    for k,wep in ipairs(WeaponsGet) do
        local tTbl = FormatedTable[wep.Slot or 0]
        local iMinPos = math.min( (wep.SlotPos and wep.SlotPos) or 1, ((#tTbl or 0) + 1)) - 1
        local iPos = tTbl[ iMinPos ] and #tTbl + 1 or iMinPos
        tTbl[ iPos ] = wep
    end
    return FormatedTable
end

local gradient_u = Material("vgui/gradient-d")

local COLLAPSED_H = 0.025
local GAP_H = 0.004
local ROW_STAGGER = 0.32
local ROW_SLIDE = 0.018

local function RowAppear(appear, rowIndex, totalRows)
    if totalRows <= 1 then return EaseSoft(appear) end
    local rowNorm = rowIndex / (totalRows - 1)
    local t = math.Clamp((appear - rowNorm * ROW_STAGGER) / math.max(1 - ROW_STAGGER, 0.01), 0, 1)
    return EaseSoft(t)
end

local function SelHeight(s)
    return math.ease.OutCubic(math.Clamp(s, 0, 1))
end

local function SelGlow(s)
    return math.ease.InOutSine(math.Clamp(s, 0, 1))
end

local function SelIcon(s)
    local t = math.Clamp((s - 0.1) / 0.9, 0, 1)
    return math.ease.OutQuad(t)
end

function WS.WeaponSelectorDraw( ply )
    if not IsValid( ply ) or not ply:Alive() or GetGlobalBool("RadialInventory", false) then
        WS.Appear = 0
        WS.Transparent = 0
        return
    end

    local open = WS.Show > CurTime()

    WS.Appear = LerpFT(open and 0.12 or 0.09, WS.Appear or 0, open and 1 or 0)
    if WS.Appear < 0.005 then
        WS.Appear = 0
        WS.Transparent = 0
        WS.SelectedSlot = WS.LastSelectedSlot
        WS.SelectedSlotPos = -1
        return
    end

    local Weapons = WS.GetWeaponTable( ply )
    local SelectedWep = WS.GetSelectedWeapon()
    if open and not IsValid(SelectedWep) then return end

    local appear = EaseSoft(WS.Appear)
    WS.Transparent = appear

    local scrW, scrH = ScrW(), ScrH()
    local collapsedH = scrH * COLLAPSED_H
    local gap = scrH * GAP_H
    local rowSlidePx = scrH * ROW_SLIDE

    local SuperAmmout = 0
    local AmmoutSlots = 0
    for i = 0, #Weapons do
        local slotTbl = Weapons[i]
        if table.Count(slotTbl) < 1 then continue end
        AmmoutSlots = AmmoutSlots + 1
    end

    for i = 0, #Weapons do
        local slotTbl = Weapons[i]
        if table.Count(slotTbl) < 1 then continue end

        local sizeX = scrW * 0.1
        local position = scrW / 2 + ((SuperAmmout - (AmmoutSlots / 2)) * sizeX)

        local wepCount = 0
        local slotHasSelected = false
        for Id = 0, #slotTbl do
            local w = slotTbl[Id]
            if not w then continue end
            wepCount = wepCount + 1
            if IsValid(SelectedWep) and SelectedWep == w then
                slotHasSelected = true
            end
        end
        local totalRows = wepCount + 1

        local headerT = RowAppear(WS.Appear, 0, totalRows)
        local headerGlow = slotHasSelected and 1 or 0.55
        WS.DrawText(
            i + 1,
            "HomigradFontMedium",
            position + sizeX / 2,
            scrH * 0.02 + (1 - headerT) * (-rowSlidePx),
            color_white,
            TEXT_ALIGN_CENTER,
            headerT * headerGlow
        )

        local yCursor = scrH * 0.05
        local rowIndex = 1
        for Id = 0, #slotTbl do
            local wep = slotTbl[Id]
            if not wep then continue end

            local rowT = RowAppear(WS.Appear, rowIndex, totalRows)
            local selected = IsValid(SelectedWep) and SelectedWep == wep

            wep.SelectorScale = LerpFT(selected and 0.2 or 0.17, wep.SelectorScale or 0, selected and 1 or 0)
            local s = wep.SelectorScale
            local sH = SelHeight(s)
            local sG = SelGlow(s)
            local sI = SelIcon(s)

            local expandedH = sizeX * 0.7
            local sizeH = Lerp(sH, collapsedH, expandedH)

            local boxW = Lerp(sH, sizeX * 0.97, sizeX)
            local boxX = position + (sizeX - boxW) * 0.5
            local boxH = sizeH
            local yBase = yCursor + (1 - rowT) * (-rowSlidePx)

            local idleAlpha = slotHasSelected and 0.62 or 0.82
            local itemAlpha = rowT * Lerp(sG, idleAlpha, 1)
            local bgAlpha = itemAlpha * Lerp(sG, 180, 220)

            if rowT > 0.005 then
                draw.RoundedBox(0, boxX, yBase, boxW, boxH, ColorAlpha(color_black, bgAlpha))

                draw.RoundedBox(
                    0,
                    boxX,
                    yBase + boxH - 2,
                    boxW,
                    2,
                    ColorAlpha(color_black, itemAlpha * Lerp(sG, 160, 230))
                )

                if sG > 0.005 then
                    surface.SetDrawColor(0, 28, 155, itemAlpha * 210 * sG)
                    surface.SetMaterial(gradient_u)
                    surface.DrawTexturedRect(boxX, yBase, boxW, boxH)

                    local outlineA = itemAlpha * 170 * sG
                    surface.SetDrawColor(47, 64, 121, outlineA)
                    surface.DrawOutlinedRect(boxX, yBase, boxW, boxH, math.max(1, math.floor(1 + sG)))
                end

                local titleY = yBase + Lerp(sH, 2.5, 5)
                WS.DrawText(
                    WS.GetPrintName(wep),
                    "HomigradFontSmall",
                    boxX + boxW / 2,
                    titleY,
                    color_white,
                    TEXT_ALIGN_CENTER,
                    itemAlpha
                )

                if sI > 0.01 and wep.DrawWeaponSelection then
                    local iconPad = 5
                    local iconY = yBase + boxH * Lerp(sI, 0.35, 0.2)
                    local iconH = (boxH - 10) * Lerp(sI, 0.55, 1)
                    local iconW = (boxW - iconPad * 2) * Lerp(sI, 0.85, 1)
                    local iconX = boxX + (boxW - iconW) * 0.5
                    wep:DrawWeaponSelection(iconX, iconY, iconW, iconH, itemAlpha * sI * 255)
                end
            end

            yCursor = yCursor + sizeH + gap
            rowIndex = rowIndex + 1
        end

        SuperAmmout = SuperAmmout + 1
    end
end

-- Changer
local tAcceptKeys = {
    ["slot1"] = 1,
    ["slot2"] = 2,
    ["slot3"] = 3,
    ["slot4"] = 4,
    ["slot5"] = 5,
    ["slot6"] = 6,
}

--[[
    Table:
        [1]	=	Weapon [52][weapon_hands_sh]
        [2]	=	Weapon [117][weapon_bigconsumable]
        [3]	=	Weapon [121][weapon_handcuffs_key]
        [4]	=	Weapon [122][weapon_handcuffs]
        [5]	=	Weapon [123][weapon_traitor_poison1]
        [6]	=	Weapon [124][weapon_traitor_suit]
        [7]	=	Weapon [125][weapon_matches]

    TableFormated:
    [0]:
		[0]	=	Weapon [126][weapon_physgun]
		[1]	=	Weapon [52][weapon_hands_sh]
    [1]:
    [2]:
    [3]:
		[1]	=	Weapon [117][weapon_bigconsumable]
		[2]	=	Weapon [121][weapon_handcuffs_key]
		[3]	=	Weapon [122][weapon_handcuffs]
		[4]	=	Weapon [123][weapon_traitor_poison1]
		[5]	=	Weapon [125][weapon_matches]
    [4]:
    [5]:
		[1]	=	Weapon [124][weapon_traitor_suit]
--]]

local function GetUpper(Weapons)
    if #LocalPlayer():GetWeapons() < 1 then return end
    WS.SelectedSlot = WS.SelectedSlot < 0 and #Weapons or WS.SelectedSlot - 1
    WS.SelectedSlotPos = Weapons[WS.SelectedSlot] and #Weapons[WS.SelectedSlot] or 0

    local Guard = 0
    while (Weapons[WS.SelectedSlot] == nil or Weapons[WS.SelectedSlot][WS.SelectedSlotPos] == nil) and Guard < #Weapons + 1 do
        WS.SelectedSlot = WS.SelectedSlot < 0 and #Weapons or WS.SelectedSlot - 1
        WS.SelectedSlotPos = Weapons[WS.SelectedSlot] and #Weapons[WS.SelectedSlot] or 0
        Guard = Guard + 1
    end
end

local function GetDown(Weapons)
    if #LocalPlayer():GetWeapons() < 1 then return end
    WS.SelectedSlot = WS.SelectedSlot > #Weapons and 0 or WS.SelectedSlot + 1
    WS.SelectedSlotPos = 0

    local Guard = 0
    while (Weapons[WS.SelectedSlot] == nil or Weapons[WS.SelectedSlot][WS.SelectedSlotPos] == nil) and Guard < #Weapons + 1 do
        WS.SelectedSlot = WS.SelectedSlot > #Weapons and 0 or WS.SelectedSlot + 1
        WS.SelectedSlotPos = 0
        Guard = Guard + 1
    end
end

local LastSelected = 0

local function get_active_tool(ply, tool)
    local activeWep = ply:GetActiveWeapon()
    if not IsValid(activeWep) or activeWep:GetClass() ~= "gmod_tool" or activeWep.Mode ~= tool then return end
    return activeWep:GetToolObject(tool)
end

local function canUseSelector(ply)
    local wep = ply:GetActiveWeapon()
    local tool = get_active_tool(ply, "submaterial")
    if tool and IsValid(ply:GetEyeTraceNoCursor().Entity) then
        return true
    end

    return IsAiming(ply) or (IsValid(wep) and wep:GetClass() == "weapon_physgun" and ply:KeyDown(IN_ATTACK)) or (lply.organism and lply.organism.pain and lply.organism.pain > 100) or GetGlobalBool("RadialInventory", false)
end

function WS.ChangeSelectionWep( ply, key )
    if not IsValid( ply ) or not ply:Alive() or GetGlobalBool("RadialInventory", false) then return end
    if ply.organism and ply.organism.otrub then return end
    if canUseSelector( ply ) then return end
    --print(canUseSelector( ply ))
    --print("Table")
    --PrintTable( WS.GetWeaponTable( ply ) )
    local iPos = tAcceptKeys[ key ]
    if iPos or key == "invnext" or key == "invprev" or key == "lastinv" then

        local Weapons = WS.GetWeaponTable( ply )

        WS.Show = CurTime() + 4
        --print(key)
        surface.PlaySound("arc9_eft_shared/weapon_generic_rifle_spin"..math.random(10)..".ogg")
        if iPos then
            iPos = iPos - 1
            if LastSelected ~= iPos then 
                WS.SelectedSlotPos = -1
            end
            WS.SelectedSlotPos = (Weapons[iPos] and LastSelected == iPos and WS.SelectedSlotPos + 1 > #Weapons[iPos] and 0 or math.min( WS.SelectedSlotPos + 1, #Weapons[iPos] )) or 0
            WS.SelectedSlot = iPos
            LastSelected = iPos
            --print(WS.SelectedSlotPos)
            --print(iPos)
            --print( Weapons[WS.SelectedSlot][WS.SelectedSlotPos] )
        elseif key == "invprev" then
            WS.SelectedSlotPos = WS.SelectedSlotPos - 1
            --print(WS.SelectedSlotPos)
            if Weapons[WS.SelectedSlot] and WS.SelectedSlotPos < 0  then
                GetUpper(Weapons)
            end
            --WS.SelectedSlot = Weapons[WS.SelectedSlot] and #Weapons[WS.SelectedSlot] > (WS.SelectedSlotPos + 1) and WS.SelectedSlot + 1 or WS.SelectedSlot + 1 > #Weapons - 1 and 0 or 0
        elseif key == "invnext" then
            WS.SelectedSlotPos = WS.SelectedSlotPos + 1
            --print(WS.SelectedSlotPos)
            if Weapons[WS.SelectedSlot] and WS.SelectedSlotPos > #Weapons[WS.SelectedSlot] then
                GetDown(Weapons)
            end
        elseif key == "lastinv" and IsValid(WS.LastInv) then
            WS.Show = 0
            WS.LastInv = WS.LastInv or "weapon_hands_sh"
            local oldwep = ply:GetActiveWeapon()
            input.SelectWeapon( WS.LastInv )
            WS.LastInv = oldwep
        end

    end
end

function WS.SetActuallyWeapon( ply, cmd )
    if not IsValid( ply ) or not ply:Alive() or GetGlobalBool("RadialInventory", false) then return end
    if (cmd:KeyDown( IN_ATTACK ) or cmd:KeyDown( IN_ATTACK2 )) and WS.Show > CurTime() then

        if WS.Selected and WS.Selected > CurTime() then 
            cmd:RemoveKey(IN_ATTACK) 
            cmd:RemoveKey(IN_ATTACK2) 
        else
            cmd:RemoveKey(IN_ATTACK)
            cmd:RemoveKey(IN_ATTACK2) 
            --print(WS.GetSelectedWeapon())
            
            if IsValid(WS.GetSelectedWeapon()) then
                WS.LastInv = WS.LastInv ~= ply:GetActiveWeapon() and WS.LastInv or ply:GetActiveWeapon()
                input.SelectWeapon( WS.GetSelectedWeapon() )
            end
            cmd:RemoveKey(IN_ATTACK)
            cmd:RemoveKey(IN_ATTACK2) 

            WS.LastSelectedSlot = WS.SelectedSlot
            WS.LastSelectedSlotPos = WS.SelectedSlotPos
            WS.Selected = CurTime() + 0.2
            WS.Show = CurTime() + 0.2
            surface.PlaySound("arc9_eft_shared/weapon_generic_spin"..math.random(1,10)..".ogg")
        end
    end
end

hook.Add( "PlayerBindPress", "WeaponSelector_PlayerBindPress", WS.ChangeSelectionWep )

hook.Add( "HUDPaint", "WeaponSelector_Draw", function()
    WS.WeaponSelectorDraw( LocalPlayer() )
end)

hook.Add( "StartCommand", "WeaponSelector_StartCommand", WS.SetActuallyWeapon )

local tHideElements = {
    ["CHudWeaponSelection"] = true
}

hook.Add("HUDShouldDraw", "WeaponSelector_HUDShouldDraw", function(sElementName)
    if tHideElements[sElementName] then return false end
end)

-- Я ТАК ЗАДОЛБАЛСЯ ПРОСТО УБЕЙТЕ МЕНЯ ХАХАХАХАХАХАХАХАХАХААХАХАХАХАХАХА
-- ПОЛЧАСА Я ПЫТАЛСЯ СДЕЛАТЬ НОРМЛАЬНОЕ ПЕРЕКЛЮЧЕНИЕ ГОВНА!!!
-- ЗАТО ПОЛУЧИЛОСЬ!!!!
-- УЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭ
--[[
    /\_/\
    |_ _|
    |   |__
   /_|_____\ -- IT'S SO OVER
--]]
