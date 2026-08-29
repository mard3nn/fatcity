MODE.name = "tdm"

local MODE = MODE

net.Receive("tdm_start",function()
    surface.PlaySound("csgo_round.wav")
	zb.rtype = net.ReadString()
	hg.DynaMusic:Start( "swat4" )
	zb.RemoveFade()
end)

local teams = {
	[0] = {
		objective = "",
		name = "a Terrorist",
		color1 = Color(190,0,0),
		color2 = Color(190,0,0)
	},
	[1] = {
		objective = "",
		name = "a Counter Terrorist",
		color1 = Color(0,120,190),
		color2 = Color(0,120,190)
	},
}

hook.Add( "StartCommand", "TDM_DisallowMoveOrShoting", function( ply, mv )
	--; BLYAT NY NAXUA PISAT VSE V ODNY LINIY BLYAAA
	if zb.CROUND == "tdm" and (zb.ROUND_START or 0) + 20 > CurTime() then 
		mv:RemoveKey(IN_ATTACK)
		mv:RemoveKey(IN_ATTACK2)
		mv:RemoveKey(IN_FORWARD)
		mv:RemoveKey(IN_BACK)
		mv:RemoveKey(IN_MOVELEFT)
		mv:RemoveKey(IN_MOVERIGHT)
	end
end)

function MODE:RenderScreenspaceEffects()
    local StartTime = zb.ROUND_START or CurTime()
	if StartTime + 7.5 < CurTime() then return end
    local fade = math.Clamp(StartTime + 7.5 - CurTime(),0,1)

    surface.SetDrawColor(0,0,0,255 * fade)
    surface.DrawRect(-1,-1,ScrW() + 1,ScrH() + 1)
end

function MODE:HUDPaint()
    local StartTime = zb.ROUND_START or CurTime()
	self:AddHudPaint()
	if StartTime + 20 > CurTime() then
		draw.SimpleText( string.FormattedTime(StartTime + 20 - CurTime(), "%02i:%02i:%02i"	), "ZB_HomicideMedium", sw * 0.5, sh * 0.95, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText( "Press F3 to open buymenu", "ZB_HomicideMedium", sw * 0.5, sh * 0.9, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	else
		local time = string.FormattedTime( math.max(StartTime + (zb.ROUND_TIME or 400) - CurTime(), 0), "%02i:%02i:%02i" )
		draw.SimpleText( time, "ZB_HomicideMedium", sw * 0.5, sh * 0.95, ColorObj, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

    if StartTime + 20 < CurTime() then return end
	 
	if not lply:Alive() then return end
	zb.RemoveFade()
    local fade = math.Clamp(StartTime + 8 - CurTime(),0,1)
	local team_ = lply:Team()
    draw.SimpleText("ZBattle | "..(self.PrintName or "Team Deathmatch"), "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.1, Color(0,162,255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    local Rolename = teams[team_].name
    local ColorRole = teams[team_].color1
    ColorRole.a = 255 * fade
    draw.SimpleText("You are "..Rolename , "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.5, ColorRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    local Objective = teams[team_].objective
    local ColorObj = teams[team_].color2
    ColorObj.a = 255 * fade
    draw.SimpleText( Objective, "ZB_HomicideMedium", sw * 0.5, sh * 0.9, ColorObj, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	if hg.PluvTown.Active then
		surface.SetMaterial(hg.PluvTown.PluvMadness)
		surface.SetDrawColor(255, 255, 255, math.random(175, 255) * fade / 2)
		surface.DrawTexturedRect(sw * 0.25, sh * 0.44 - ScreenScale(15), sw / 2, ScreenScale(30))

		draw.SimpleText("SOMEWHERE IN PLUVTOWN", "ZB_ScrappersLarge", sw / 2, sh * 0.44 - ScreenScale(2), Color(0, 0, 0, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end

function MODE:AddHudPaint()
end

local CreateEndMenu

net.Receive("tdm_roundend",function()
    CreateEndMenu()
end)



local colGray = Color(85,85,85,255)
local colRed = Color(130,10,10)
local colRedUp = Color(160,30,30)

local colBlue = Color(10,10,160)
local colBlueUp = Color(40,40,160)
local col = Color(255,255,255,255)

local colSpect1 = Color(75,75,75,255)
local colSpect2 = Color(255,255,255)

local colorBG = Color(55,55,55,255)
local colorBGBlacky = Color(40,40,40,255)

local blurMat = Material("pp/blurscreen")
local Dynamic = 0

BlurBackground = BlurBackground or hg.DrawBlur

if IsValid(hmcdEndMenu) then
    hmcdEndMenu:Remove()
    hmcdEndMenu = nil
end

CreateEndMenu = function()
	if IsValid(hmcdEndMenu) then
		hmcdEndMenu:Remove()
		hmcdEndMenu = nil
	end
	Dynamic = 0
	hmcdEndMenu = vgui.Create("ZFrame")

    surface.PlaySound("ambient/alarms/warningbell1.wav")

	local sizeX,sizeY = ScrW() / 2.5 ,ScrH() / 1.2
	local posX,posY = ScrW() / 1.3 - sizeX / 2,ScrH() / 2 - sizeY / 2

	hmcdEndMenu:SetPos(posX,posY)
	hmcdEndMenu:SetSize(sizeX,sizeY)
	--hmcdEndMenu:SetBackgroundColor(colGray)
	hmcdEndMenu:MakePopup()
	hmcdEndMenu:SetKeyboardInputEnabled(false)
	hmcdEndMenu:ShowCloseButton(false)

	local closebutton = vgui.Create("DButton",hmcdEndMenu)
	closebutton:SetPos(5,5)
	closebutton:SetSize(ScrW() / 20,ScrH() / 30)
	closebutton:SetText("")
	
	closebutton.DoClick = function()
		if IsValid(hmcdEndMenu) then
			hmcdEndMenu:Close()
			hmcdEndMenu = nil
		end
	end

	closebutton.Paint = function(self,w,h)
		surface.SetDrawColor( 122, 122, 122, 255)
        surface.DrawOutlinedRect( 0, 0, w, h, 2.5 )
		surface.SetFont( "ZB_InterfaceMedium" )
		surface.SetTextColor(col.r,col.g,col.b,col.a)
		local lengthX, lengthY = surface.GetTextSize("Close")
		surface.SetTextPos( lengthX - lengthX/1.1, 4)
		surface.DrawText("Close")
	end

    hmcdEndMenu.Paint = function(self,w,h)
		BlurBackground(self)

		surface.SetFont( "ZB_InterfaceMediumLarge" )
		surface.SetTextColor(col.r,col.g,col.b,col.a)
		local lengthX, lengthY = surface.GetTextSize("Players:")
		surface.SetTextPos(w / 2 - lengthX/2,20)
		surface.DrawText("Players:")

		surface.SetDrawColor( 255, 0, 0, 128)
        surface.DrawOutlinedRect( 0, 0, w, h, 2.5 )
	end
	-- PLAYERS
	local DScrollPanel = vgui.Create("DScrollPanel", hmcdEndMenu)
	DScrollPanel:SetPos(10, 80)
	DScrollPanel:SetSize(sizeX - 20, sizeY - 90)
	function DScrollPanel:Paint( w, h )
		BlurBackground(self)

		surface.SetDrawColor( 255, 0, 0, 128)
        surface.DrawOutlinedRect( 0, 0, w, h, 2.5 )
	end

	for i, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR then continue end
		local but = vgui.Create("DButton",DScrollPanel)
		but:SetSize(100,50)
		but:Dock(TOP)
		but:DockMargin( 8, 6, 8, -1 )
		but:SetText("")
		but.Paint = function(self,w,h)
            local col1 = (ply:Alive() and colRed) or colGray
            local col2 = (ply:Alive() and colRedUp) or colSpect1
			surface.SetDrawColor(col1.r,col1.g,col1.b,col1.a)
			surface.DrawRect(0,0,w,h)
			surface.SetDrawColor(col2.r,col2.g,col2.b,col2.a)
			surface.DrawRect(0,h/2,w,h/2)

            local col = ply:GetPlayerColor():ToColor()
			surface.SetFont( "ZB_InterfaceMediumLarge" )
			local lengthX, lengthY = surface.GetTextSize( ply:GetPlayerName() or "He quited..." )
			
			surface.SetTextColor(0,0,0,255)
			surface.SetTextPos(w / 2 + 1,h/2 - lengthY/2 + 1)
			surface.DrawText(ply:GetPlayerName() or "He quited...")

			surface.SetTextColor(col.r,col.g,col.b,col.a)
			surface.SetTextPos(w / 2,h/2 - lengthY/2)
			surface.DrawText(ply:GetPlayerName() or "He quited...")

            
			local col = colSpect2
			surface.SetFont( "ZB_InterfaceMediumLarge" )
			surface.SetTextColor(col.r,col.g,col.b,col.a)
			local lengthX, lengthY = surface.GetTextSize( ply:GetPlayerName() or "He quited..." )
			surface.SetTextPos(15,h/2 - lengthY/2)
			surface.DrawText((ply:Name() .. (not ply:Alive() and " - died" or "")) or "He quited...")

			surface.SetFont( "ZB_InterfaceMediumLarge" )
			surface.SetTextColor(col.r,col.g,col.b,col.a)
			local lengthX, lengthY = surface.GetTextSize( ply:Frags() or "He quited..." )
			surface.SetTextPos(w - lengthX -15,h/2 - lengthY/2)
			surface.DrawText(ply:Frags() or "He quited...")
		end

		function but:DoClick()
			if ply:IsBot() then chat.AddText(Color(255,0,0), "no, you can't") return end
			gui.OpenURL("https://steamcommunity.com/profiles/"..ply:SteamID64())
		end

		DScrollPanel:AddItem(but)
	end

	return true
end

function MODE:RoundStart()
    if IsValid(hmcdEndMenu) then
        hmcdEndMenu:Remove()
        hmcdEndMenu = nil
    end
end

surface.CreateFont("ZB_TDM_MENU", {font = "Bahnschrift", size = ScreenScale(13), extended = true, weight = 700, antialias = true})
surface.CreateFont("ZB_TDM_DESC", {font = "Bahnschrift", size = ScreenScale(9), extended = true, weight = 500, antialias = true})
surface.CreateFont("ZB_TDM_CATEGORY", {font = "Bahnschrift", size = ScreenScale(10), extended = true, weight = 700, antialias = true})
surface.CreateFont("ZB_TDM_DESCSMALL", {font = "Bahnschrift", size = ScreenScale(7), extended = true, weight = 500, antialias = true})
surface.CreateFont("ZB_TDM_TITLE", {font = "Bahnschrift", size = ScreenScale(22), extended = true, weight = 800, antialias = true})

local buyAccent = Color(60, 120, 235)
local buyAccentBright = Color(105, 165, 255)
local buyPanel = Color(14, 20, 42, 238)
local buyPanelHover = Color(22, 34, 66, 245)
local buyText = Color(220, 228, 245)
local buyTextDim = Color(105, 122, 150)
local buyGreen = Color(92, 205, 128)
local buyRed = Color(210, 82, 82)
local buyGold = Color(255, 200, 60)
local buyGradientR = Material("vgui/gradient-r")

local function SendBuy(item)
	net.Start("tdm_buyitem")
		net.WriteTable(item)
	net.SendToServer()
end

local function GetBuyIcon(item)
	local weapon = weapons.GetStored(item.ItemClass)
	local ent = scripted_ents.GetStored(item.ItemClass)
	local icon = ent and ent.t and ent.t.IconOverride
	if weapon then
		icon = (weapon.WepSelectIcon2 and weapon.WepSelectIcon2:GetName() .. ".png") or weapon.IconOverride or icon
	end
	return icon, weapon
end

local function OpenBuyMenu()
	if TDM_OpenedBuyMenu then
		TDM_OpenedBuyMenu:Remove()
		TDM_OpenedBuyMenu = nil
	end
	local StartTime = zb.ROUND_START or CurTime()
	if not LocalPlayer():Alive() or StartTime + 40 < CurTime() then return end
	TDM_OpenedBuyMenu = vgui.Create("DPanel")
	local Frame = TDM_OpenedBuyMenu
	Frame:SetSize(ScrW(), ScrH())
	Frame:SetPos(0, 0)
	Frame:MakePopup()
	Frame:SetAlpha(0)
	Frame:AlphaTo(255, 0.15, 0)
	Frame.Paint = function(self, w, h)
		BlurBackground(self)
		surface.SetDrawColor(8, 12, 26, 238)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(buyAccent.r, buyAccent.g, buyAccent.b, 55)
		surface.SetMaterial(buyGradientR)
		surface.DrawTexturedRect(0, 0, w, h)
		local grid = ScreenScale(28)
		local off = (RealTime() * 10) % grid
		surface.SetDrawColor(buyAccent.r, buyAccent.g, buyAccent.b, 10)
		for x = -1, math.ceil(w / grid) do surface.DrawRect(x * grid - off, 0, 1, h) end
		for y = -1, math.ceil(h / grid) do surface.DrawRect(0, y * grid + off, w, 1) end
	end

	local margin, headerH, footerH, gap = ScreenScale(10), ScreenScale(30), ScreenScale(28), ScreenScale(8)
	local leftW = math.floor(ScrW() * 0.19)
	local bodyY, bodyH = headerH, ScrH() - headerH - footerH - margin

	local title = vgui.Create("DLabel", Frame)
	title:SetPos(margin, ScreenScale(3))
	title:SetFont("ZB_TDM_TITLE")
	title:SetText("АРСЕНАЛ")
	title:SetTextColor(Color(180, 210, 255))
	title:SizeToContents()

	local close = vgui.Create("DButton", Frame)
	close:SetText("")
	close:SetSize(ScreenScale(22), ScreenScale(22))
	close:SetPos(ScrW() - margin - close:GetWide(), ScreenScale(4))
	close.Paint = function(self, w, h)
		if self:IsHovered() then draw.RoundedBox(4, 0, 0, w, h, Color(60, 120, 235, 130)) end
		draw.SimpleText("×", "ZB_TDM_MENU", w / 2, h / 2, buyText, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	close.DoClick = function() Frame:Remove() end

	local categories = vgui.Create("DPanel", Frame)
	categories:SetPos(margin, bodyY)
	categories:SetSize(leftW, bodyH)
	categories.Paint = function(self, w, h)
		draw.RoundedBox(6, 0, 0, w, h, buyPanel)
		surface.SetDrawColor(buyAccent.r, buyAccent.g, buyAccent.b, 75)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
	end

	local categoryTitle = vgui.Create("DLabel", categories)
	categoryTitle:Dock(TOP)
	categoryTitle:DockMargin(ScreenScale(8), ScreenScale(8), 0, ScreenScale(5))
	categoryTitle:SetFont("ZB_TDM_CATEGORY")
	categoryTitle:SetText("КАТЕГОРИИ")
	categoryTitle:SetTextColor(buyAccentBright)
	categoryTitle:SetTall(ScreenScale(18))

	local categoryList = vgui.Create("DScrollPanel", categories)
	categoryList:Dock(FILL)
	categoryList:DockMargin(ScreenScale(6), 0, ScreenScale(6), ScreenScale(6))
	local content = vgui.Create("DScrollPanel", Frame)
	content:SetPos(margin + leftW + gap, bodyY)
	content:SetSize(ScrW() - margin * 2 - leftW - gap, bodyH)
	content.Paint = function(self, w, h)
		draw.RoundedBox(6, 0, 0, w, h, buyPanel)
		surface.SetDrawColor(buyAccent.r, buyAccent.g, buyAccent.b, 75)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
	end

	local selectedCategory
	local categoryButtons = {}
	local function ShowCategory(categoryName, category)
		selectedCategory = categoryName
		content:Clear()
		local layout = vgui.Create("DIconLayout", content)
		layout:Dock(TOP)
		layout:DockMargin(ScreenScale(8), ScreenScale(8), ScreenScale(8), ScreenScale(8))
		layout:SetSpaceX(ScreenScale(6))
		layout:SetSpaceY(ScreenScale(6))
		local cols = math.Clamp(math.floor(content:GetWide() / ScreenScale(150)), 2, 5)
		local cardW = math.floor((content:GetWide() - ScreenScale(22) - ScreenScale(6) * (cols - 1)) / cols)
		local cardH = ScreenScale(92)
		local count = 0
		for itemName, item in SortedPairs(category) do
			if itemName == "Priority" then continue end
			count = count + 1
			local icon, weapon = GetBuyIcon(item)
			local actionX = math.floor(cardW * 0.53)
			local attachCols = math.max(1, math.floor((cardW - actionX - ScreenScale(5)) / ScreenScale(16)))
			local attachRows = math.ceil(#(item.Attachments or {}) / attachCols)
			local itemCardH = math.max(cardH, ScreenScale(55 + attachRows * 16))
			local card = layout:Add("DButton")
			card:SetText("")
			card:SetSize(cardW, itemCardH)
			card.Paint = function(self, w, h)
				local affordable = LocalPlayer():GetNWInt("TDM_Money", 0) >= item.Price
				draw.RoundedBox(4, 0, 0, w, h, self:IsHovered() and buyPanelHover or Color(12, 18, 38, 240))
				surface.SetDrawColor(buyAccent.r, buyAccent.g, buyAccent.b, self:IsHovered() and 150 or 55)
				surface.DrawOutlinedRect(0, 0, w, h, 1)
				draw.SimpleText(itemName, "ZB_TDM_MENU", ScreenScale(6), ScreenScale(5), affordable and buyText or buyTextDim)
				draw.SimpleText("$" .. item.Price, "ZB_TDM_DESC", ScreenScale(6), ScreenScale(22), affordable and buyGreen or buyRed)
				draw.SimpleText("КУПИТЬ", "ZB_TDM_DESCSMALL", w - ScreenScale(6), h - ScreenScale(5), self:IsHovered() and buyAccentBright or buyTextDim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
			end
			card.DoClick = function() SendBuy({categoryName, itemName}) end

			if icon then
				local image = vgui.Create("DImage", card)
				image:SetImage(icon)
				image:SetPos(ScreenScale(5), ScreenScale(31))
				image:SetSize(math.min(cardW * 0.48, ScreenScale(58)), ScreenScale(40))
				image:SetMouseInputEnabled(false)
			end

			if weapon then
				local base = weapons.GetStored(weapon.Base or "")
				local ammo = weapon.Primary and weapon.Primary.Ammo or weapon.Ammo or (base and base.Primary and base.Primary.Ammo)
				if ammo and ammo != "none" and hg.ammotypeshuy[ammo] and MODE.BuyItems["Ammo"] then
					local ammoClass = "ent_ammo_" .. hg.ammotypeshuy[ammo].name
					local ammoName
					for name, ammoItem in pairs(MODE.BuyItems["Ammo"]) do
						if istable(ammoItem) and ammoItem.ItemClass == ammoClass then ammoName = name break end
					end
					if ammoName then
						local ammoBtn = vgui.Create("DButton", card)
						ammoBtn:SetText("ПАТРОНЫ")
						ammoBtn:SetFont("ZB_TDM_DESCSMALL")
						ammoBtn:SetTextColor(buyGold)
						ammoBtn:SetPos(actionX, ScreenScale(32))
						ammoBtn:SetSize(cardW - actionX - ScreenScale(5), ScreenScale(15))
						ammoBtn.Paint = function(self, w, h) draw.RoundedBox(3, 0, 0, w, h, Color(30, 42, 72, self:IsHovered() and 255 or 220)) end
						ammoBtn.DoClick = function() SendBuy({"Ammo", ammoName}) end
					end
				end
			end

			for id, attachName in ipairs(item.Attachments or {}) do
				local attach = vgui.Create("DImageButton", card)
				attach:SetImage(hg.attachmentsIcons[attachName] or "icon16/wrench.png")
				attach:SetTooltip((hg.attachmentslaunguage and hg.attachmentslaunguage[attachName]) or attachName)
				attach:SetSize(ScreenScale(14), ScreenScale(14))
				local attachColumn = (id - 1) % attachCols
				local attachRow = math.floor((id - 1) / attachCols)
				attach:SetPos(actionX + attachColumn * ScreenScale(16), ScreenScale(51) + attachRow * ScreenScale(16))
				attach.DoClick = function() SendBuy({categoryName, itemName, attachName}) end
				attach.PaintOver = function(self, w, h)
					surface.SetDrawColor(buyAccent.r, buyAccent.g, buyAccent.b, self:IsHovered() and 210 or 70)
					surface.DrawOutlinedRect(0, 0, w, h, 1)
				end
			end
		end
		layout:SetTall(math.max(cardH, count * (cardH + ScreenScale(6))))
		layout:InvalidateLayout(true)
		timer.Simple(0, function()
			if not IsValid(layout) then return end
			layout:InvalidateLayout(true)
			layout:SizeToChildren(false, true)
		end)
	end

	for categoryName, category in SortedPairsByMemberValue(MODE.BuyItems, "Priority") do
		local btn = vgui.Create("DButton", categoryList)
		btn:Dock(TOP)
		btn:DockMargin(0, 0, 0, ScreenScale(3))
		btn:SetTall(ScreenScale(23))
		btn:SetText("")
		btn.Paint = function(self, w, h)
			local selected = selectedCategory == categoryName
			draw.RoundedBox(4, 0, 0, w, h, selected and Color(18, 36, 78, 245) or (self:IsHovered() and buyPanelHover or Color(10, 15, 31, 210)))
			if selected then surface.SetDrawColor(buyAccentBright) surface.DrawRect(0, 0, 3, h) end
			draw.SimpleText(categoryName, "ZB_TDM_DESC", ScreenScale(7), h / 2, selected and buyText or buyTextDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end
		btn.DoClick = function() ShowCategory(categoryName, category) end
		categoryButtons[#categoryButtons + 1] = {button = btn, name = categoryName, data = category}
	end
	if categoryButtons[1] then ShowCategory(categoryButtons[1].name, categoryButtons[1].data) end

	local status = vgui.Create("DPanel", Frame)
	status:SetPos(0, ScrH() - footerH)
	status:SetSize(ScrW(), footerH)
	status.Paint = function(self, w, h)
		surface.SetDrawColor(8, 12, 24, 248) surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(buyAccent.r, buyAccent.g, buyAccent.b, 100) surface.DrawRect(0, 0, w, 1)
		draw.SimpleText("ДЕНЬГИ  $" .. LocalPlayer():GetNWInt("TDM_Money", 0), "ZB_TDM_CATEGORY", margin, h / 2, buyGreen, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		local left = math.max(0, StartTime + 40 - CurTime())
		draw.SimpleText("ПОКУПКА  " .. string.FormattedTime(left, "%02i:%02i"), "ZB_TDM_CATEGORY", w - margin, h / 2, left <= 5 and buyRed or buyText, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
	end

	Frame.Think = function(self)
		if not LocalPlayer():Alive() or StartTime + 40 < CurTime() then self:Remove() return end
		if input.IsKeyDown(KEY_ESCAPE) then self:Remove() if gui.IsGameUIVisible() then gui.HideGameUI() end end
	end

end

net.Receive("tdm_open_buymenu",function() OpenBuyMenu() end)
TDM_OpenedBuyMenu = TDM_OpenedBuyMenu or nil
