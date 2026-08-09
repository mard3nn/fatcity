local MODE = MODE
local vgui_color_main = Color(155, 0, 0, 255) // Claude Popusk 4.8
local vgui_color_bg = Color(50, 50, 50, 255) // ChatJABADE 5.6-Sol'
local vgui_color_ready = Color(0, 150, 50, 255)
local vgui_color_notready = Color(0, 50, 0, 255)

-- surface.CreateFont("RoleSelection_Main", {
	-- font = "Roboto",
	-- extended = false,
	-- size = ScreenScale(10),
	-- weight = 500,
	-- blursize = 0,
	-- scanlines = 0,
	-- antialias = true,
	-- underline = false,
	-- italic = false,
	-- strikeout = false,
	-- symbol = false,
	-- rotary = false,
	-- shadow = false,
	-- additive = false,
	-- outline = false,
-- })

local blurMat = Material("pp/blurscreen")
local gradient_u = Material("vgui/gradient-u")
local gradient_d = Material("vgui/gradient-d")
local gradient_l = Material("vgui/gradient-l")
local gradient_r = Material("vgui/gradient-r")
local blueGrad = Color(60, 120, 235, 255)
local blueBlackGrad = Color(12, 22, 55, 255)

surface.CreateFont("GOMI_RoleTitle", {
	font = "Bahnschrift",
	size = ScreenScale(40),
	weight = 800,
	antialias = true
})
surface.CreateFont("GOMI_RoleBtn", {
	font = "Bahnschrift",
	size = ScreenScale(13),
	weight = 500,
	antialias = true,
	extended = true
})
surface.CreateFont("GOMI_RoleCardTitle", {
	font = "Bahnschrift",
	size = ScreenScale(13),
	weight = 600,
	antialias = true
})
surface.CreateFont("GOMI_RoleCardDesc", {
	font = "Bahnschrift",
	size = ScreenScale(10),
	weight = 400,
	antialias = true
})
surface.CreateFont("GOMI_RoleShopDesc", {
	font = "Bahnschrift",
	size = ScreenScale(12),
	weight = 500,
	antialias = true,
	extended = true
})

local bgOverlay = Color(10, 10, 15, 220)
local textBright = Color(220, 220, 220)
local textDim = Color(140, 140, 140)
local cardBg = Color(25, 25, 30, 210)
local cardBgHover = Color(35, 35, 42, 230)
local cardBorder = vgui_color_main

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

--\\Traitor Class + Shop (PluvCoin)
local ClassOrder = {
	"traitor_default",
	"traitor_infiltrator",
	"traitor_assasin",
	"traitor_chemist",
}

local ShopOrder = {
	"weapon_p22",
	"weapon_pl15",
	"weapon_sogknife",
	"weapon_buck200knife",
	"weapon_hg_f1_tpik",
	"weapon_hg_grenade_tpik",
	"weapon_hg_rgd_tpik",
	"weapon_traitor_ied",
	"weapon_traitor_poison1",
	"weapon_traitor_poison3",
	"weapon_traitor_poison4",
	"weapon_traitor_poison_consumable",
	"weapon_hg_shuriken",
	"weapon_traitor_suit",
	"weapon_hg_jam",
}

local pluvGold = Color(255, 200, 60, 255)
local pluvGreen = Color(80, 200, 90, 255)
local pluvRed = Color(230, 60, 60, 255)

local function ClassCoins(class)
	local info = MODE.SubRoles[class]
	return (info and info.PluvCoins) or 0
end

local function IsValidClass(class)
	local info = MODE.SubRoles[class]
	return info and info.PluvCoins ~= nil
end

local function CurrentClassConVarValue()
	if(MODE.Type == "soe")then
		return MODE.ConVar_SubRole_Traitor_SOE:GetString()
	end
	return MODE.ConVar_SubRole_Traitor:GetString()
end

local PANEL = {}

function PANEL:GetBudget()
	return ClassCoins(self.SelectedClass)
end

function PANEL:GetSpent()
	local spent = 0
	for class, _ in pairs(self.Selected) do
		local info = MODE.TraitorShop[class]
		if info then spent = spent + info.Price end
	end
	return spent
end

function PANEL:ClampSelectionToBudget()
	local budget = self:GetBudget()
	local spent = self:GetSpent()
	if spent <= budget then return end

	local arr = {}
	for class, _ in pairs(self.Selected) do arr[#arr + 1] = class end
	table.sort(arr, function(a, b)
		return (MODE.TraitorShop[a].Price or 0) > (MODE.TraitorShop[b].Price or 0)
	end)

	for _, class in ipairs(arr) do
		if spent <= budget then break end
		self.Selected[class] = nil
		spent = spent - (MODE.TraitorShop[class].Price or 0)
	end
end

function PANEL:SelectClass(class)
	if not IsValidClass(class) then return end
	if(self.SelectedClass == class)then return end
	self.SelectedClass = class
	self:ClampSelectionToBudget()
	surface.PlaySound("shitty/tap_depress.wav")
end

function PANEL:ToggleWeapon(class)
	local info = MODE.TraitorShop[class]
	if not info then return end

	if(self.Selected[class])then
		self.Selected[class] = nil
		surface.PlaySound("shitty/tap_release.wav")
		return
	end

	if(self:GetBudget() - self:GetSpent() >= info.Price)then
		self.Selected[class] = true
		surface.PlaySound("shitty/tap_release.wav")
		return
	end

	surface.PlaySound("buttons/button11.wav")
end

function PANEL:SaveSelection()
	local class = self.SelectedClass
	if class and IsValidClass(class) then
		if(MODE.Type == "soe")then
			RunConsoleCommand(MODE.ConVarName_SubRole_Traitor_SOE, class)
		else
			RunConsoleCommand(MODE.ConVarName_SubRole_Traitor, class)
		end
	end

	local list = {}
	for class2, _ in pairs(self.Selected) do
		list[#list + 1] = class2
	end
	table.sort(list)
	RunConsoleCommand(MODE.ConVarName_Loadout, table.concat(list, ","))

	net.Start("HMCD(StartPlayersRoleSelection)")
	net.SendToServer()
end

function PANEL:Think()
	if(IsValid(self.BudgetLabel))then
		self.BudgetLabel:SetText("Плювкоины: " .. self:GetBudget())
		self.BudgetLabel:SizeToContents()
	end
	if(IsValid(self.SpentLabel))then
		self.SpentLabel:SetText("Потрачено: " .. self:GetSpent() .. "  |  Осталось: " .. (self:GetBudget() - self:GetSpent()))
		self.SpentLabel:SizeToContents()
	end
end

function PANEL:Construct()
	self:SetSkin(hg.GetMainSkin())
	self:SetSize(ScrW(), ScrH())
	self:SetPos(0, 0)
	self:SetMouseInputEnabled(true)
	self:SetKeyboardInputEnabled(true)
	self:MakePopup()
	gui.EnableScreenClicker(true)
	self:SetAlpha(0)
	self:AlphaTo(255, 0.15, 0)
	self.openTime = RealTime()
	self.bgAlpha = 0

	self.Selected = {}
	local current_loadout = MODE.ConVar_Loadout:GetString()
	for _, class in ipairs(string.Explode(",", current_loadout)) do
		class = string.Trim(class)
		if class != "" and MODE.TraitorShop[class] then
			self.Selected[class] = true
		end
	end

	local cur_class = CurrentClassConVarValue()
	if not IsValidClass(cur_class) then
		cur_class = ClassOrder[1]
	end
	self.SelectedClass = cur_class
	self:ClampSelectionToBudget()

	self.OnRemove = function(sel)
		gui.EnableScreenClicker(false)
	end

	self.OnKeyCodePressed = function(sel, key)
		if(key == KEY_ESCAPE)then
			sel:SaveSelection()
			sel:Remove()
		end
	end

	self.Paint = function(sel, w, h)
		sel.bgAlpha = Lerp(FrameTime() * 8, sel.bgAlpha, 1)
		drawBlur(sel, 8)
		surface.SetDrawColor(bgOverlay.r, bgOverlay.g, bgOverlay.b, bgOverlay.a * sel.bgAlpha)
		surface.DrawRect(0, 0, w, h)

		local grad = 70 * sel.bgAlpha
		surface.SetDrawColor(blueGrad.r, blueGrad.g, blueGrad.b, grad * 0.5)
		surface.SetMaterial(gradient_d)
		surface.DrawTexturedRect(0, 0, w, h)
		surface.SetDrawColor(blueGrad.r, blueGrad.g, blueGrad.b, grad * 0.35)
		surface.SetMaterial(gradient_r)
		surface.DrawTexturedRect(0, 0, w, h)
		surface.SetDrawColor(blueBlackGrad.r, blueBlackGrad.g, blueBlackGrad.b, 175 * sel.bgAlpha)
		surface.SetMaterial(gradient_u)
		surface.DrawTexturedRect(0, 0, w, h)

		local grid = ScreenScale(25)
		local off = (RealTime() * 12) % grid
		surface.SetDrawColor(199, 2, 2, 15 * sel.bgAlpha)
		for i = -1, math.ceil(w / grid) + 1 do surface.DrawRect(i * grid - off, 0, 1, h) end
		for i = -1, math.ceil(h / grid) + 1 do surface.DrawRect(0, i * grid + off, w, 1) end
	end

	local title = vgui.Create("DLabel", self)
	title:SetPos(ScreenScale(20), ScreenScale(20))
	title:SetFont("GOMI_RoleTitle")
	title:SetText("ВЫБОР ПРЕДАТЕЛЯ")
	title:SetTextColor(Color(0, 0, 0, 0))
	title.anim = 0
	title.Paint = function(sel, w, h)
		sel.anim = Lerp(FrameTime() * 10, sel.anim, 1)
		local a = sel.anim * 255
		local root = sel:GetParent()
		local openTime = IsValid(root) and (root.openTime or RealTime()) or RealTime()
		local sweepPos = (RealTime() - openTime) * 12.0
		local soft = 1.4
		local s = "ВЫБОР ПРЕДАТЕЛЯ"
		surface.SetFont("GOMI_RoleTitle")
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
			draw.SimpleText(ch, "GOMI_RoleTitle", cx + 2, 2, Color(0, 0, 0, 150 * (a / 255)))
			draw.SimpleText(ch, "GOMI_RoleTitle", cx, 0, col)
			cx = cx + cw
		end
	end

	local closeBtn = vgui.Create("DButton", self)
	closeBtn:SetText("")
	closeBtn:SetSize(ScreenScale(28), ScreenScale(28))
	closeBtn:SetPos(self:GetWide() - ScreenScale(48), ScreenScale(16))
	closeBtn:SetCursor("hand")
	closeBtn.hover = 0
	closeBtn.Paint = function(sel, w, h)
		sel.hover = Lerp(FrameTime() * 10, sel.hover, sel:IsHovered() and 1 or 0)
		if(sel.hover > 0.01)then
			draw.RoundedBox(4, 0, 0, w, h, Color(199, 2, 2, 180 * sel.hover))
		end
		draw.SimpleText("X", "GOMI_RoleBtn", w / 2, h / 2, Color(255 - 80 * sel.hover, 180 + 60 * sel.hover, 180 + 60 * sel.hover, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	closeBtn.DoClick = function()
		self:SaveSelection()
		self:Remove()
	end

	local margin = ScreenScale(20)
	local cardY = ScreenScale(88)
	local cardH = ScreenScale(90)
	local gap = ScreenScale(12)
	local cardsW = self:GetWide() - margin * 2
	local cardW = (cardsW - gap * 3) / 4

	local classHint = vgui.Create("DLabel", self)
	classHint:SetPos(margin, cardY - ScreenScale(22))
	classHint:SetFont("GOMI_RoleBtn")
	classHint:SetText("1. КЛАСС ПРЕДАТЕЛЯ")
	classHint:SetTextColor(textDim)
	classHint:SizeToContents()

	for i, class in ipairs(ClassOrder) do
		local info = MODE.SubRoles[class]
		if not info or not info.PluvCoins then continue end

		local btn = vgui.Create("DButton", self)
		btn:SetText("")
		btn:SetPos(margin + (i - 1) * (cardW + gap), cardY)
		btn:SetSize(cardW, cardH)
		btn:SetCursor("hand")
		btn.class = class
		btn.hover = 0
		btn.Paint = function(sel, w, h)
			sel.hover = Lerp(FrameTime() * 10, sel.hover, sel:IsHovered() and 1 or 0)
			local selected = self.SelectedClass == sel.class
			local bg = Color(25, 25, 30, 230)
			if selected then
				bg = Color(45, 25, 28, 240)
			elseif sel.hover > 0.01 then
				bg = Color(35, 35, 42, 235)
			end
			draw.RoundedBox(6, 0, 0, w, h, bg)
			if selected then
				surface.SetDrawColor(cardBorder)
				surface.DrawOutlinedRect(0, 0, w, h, 2)
			elseif sel.hover > 0.01 then
				surface.SetDrawColor(blueGrad.r, blueGrad.g, blueGrad.b, 160 * sel.hover)
				surface.DrawOutlinedRect(0, 0, w, h, 1)
			end

			local first_line = string.Explode("\n", info.Description or "")[1] or ""
			draw.SimpleText(info.Name, "GOMI_RoleCardTitle", w / 2, ScreenScale(8), textBright, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
			draw.SimpleText(first_line, "GOMI_RoleCardDesc", w / 2, ScreenScale(34), textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
			draw.SimpleText("+" .. info.PluvCoins .. " PluvCoin", "GOMI_RoleBtn", w / 2, h - ScreenScale(10), pluvGold, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
		end
		btn.DoClick = function(sel)
			self:SelectClass(sel.class)
		end
	end

	local shopHintY = cardY + cardH + ScreenScale(6)
	local shopHint = vgui.Create("DLabel", self)
	shopHint:SetPos(margin, shopHintY)
	shopHint:SetFont("GOMI_RoleBtn")
	shopHint:SetText("2. СНАРЯЖЕНИЕ (PluvCoin)")
	shopHint:SetTextColor(textDim)
	shopHint:SizeToContents()

	local footerH = ScreenScale(54)
	local shopY = shopHintY + ScreenScale(16)
	local shopH = self:GetTall() - shopY - footerH - ScreenScale(20)

	local scroll = vgui.Create("DScrollPanel", self)
	scroll:SetPos(margin, shopY)
	scroll:SetSize(self:GetWide() - margin * 2, shopH)
	scroll:SetSkin(hg.GetMainSkin())
	scroll.Paint = function(sel, w, h)
		surface.SetDrawColor(12, 18, 38, 150)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(blueGrad.r, blueGrad.g, blueGrad.b, 90)
		surface.SetMaterial(gradient_u)
		surface.DrawTexturedRect(0, 0, w, h)
	end

	for i, class in ipairs(ShopOrder) do
		local info = MODE.TraitorShop[class]
		if not info then continue end

		local row = vgui.Create("DButton", scroll)
		row:SetText("")
		row:SetTall(ScreenScale(58))
		row:DockMargin(0, 0, 0, ScreenScale(4))
		row:Dock(TOP)
		row:SetCursor("hand")
		row.class = class
		row.hover = 0
		row.checkAnim = 0
		row.buyPulse = 0
		row.Paint = function(sel, w, h)
			sel.hover = Lerp(FrameTime() * 10, sel.hover, sel:IsHovered() and 1 or 0)
			local selected = self.Selected[sel.class] ~= nil
			sel.checkAnim = Lerp(FrameTime() * 18, sel.checkAnim, selected and 1 or 0)
			sel.buyPulse = math.max(0, sel.buyPulse - FrameTime() * 2.2)
			local bg = Color(20, 20, 25, 220)
			if selected then
				bg = Color(40, 22, 24, 235)
			elseif sel.hover > 0.01 then
				bg = Color(30, 30, 36, 230)
			end
			draw.RoundedBox(5, 0, 0, w, h, bg)
			if selected then
				surface.SetDrawColor(199, 2, 2, 220)
				surface.DrawOutlinedRect(0, 0, w, h, 1)
			end

			if sel.hover > 0.01 then
				surface.SetDrawColor(blueGrad.r, blueGrad.g, blueGrad.b, 190 * sel.hover)
				surface.DrawRect(0, 0, 3, h)
			end

			if sel.buyPulse > 0 then
				surface.SetDrawColor(pluvGreen.r, pluvGreen.g, pluvGreen.b, 55 * sel.buyPulse)
				surface.DrawRect(0, 0, w, h)
				local p = 1 - sel.buyPulse
				local size = math.Lerp(p, h * 0.3, w * 0.9)
				surface.SetDrawColor(pluvGreen.r, pluvGreen.g, pluvGreen.b, 230 * sel.buyPulse)
				surface.DrawOutlinedRect(w / 2 - size / 2, h / 2 - size / 2, size, size, 3)
			end

			local x = ScreenScale(12)
			local cb = ScreenScale(18)
			local cbx, cby = x, h / 2 - cb / 2
			surface.SetDrawColor(selected and pluvGreen or Color(70, 70, 80, 255))
			surface.DrawOutlinedRect(cbx, cby, cb, cb, 1)
			if sel.checkAnim > 0 then
				local half = cb * 0.25 * sel.checkAnim
				surface.SetDrawColor(pluvGreen)
				surface.DrawRect(cbx + cb / 2 - half, cby + cb / 2 - half, half * 2, half * 2)
			end

			local buyCol = selected and pluvGreen or (sel.hover > 0.01 and Color(200, 200, 210, 255) or textDim)
			draw.SimpleText(selected and "КУПЛЕНО" or "КУПИТЬ", "GOMI_RoleBtn", x + cb + ScreenScale(6), h / 2, buyCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

			local tx = x + ScreenScale(120)
			draw.SimpleText(info.Name, "GOMI_RoleCardTitle", tx, h / 2 - ScreenScale(7), textBright, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText(info.Desc, "GOMI_RoleShopDesc", tx, h / 2 + ScreenScale(12), textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

			local remaining = self:GetBudget() - self:GetSpent()
			local canBuy = selected or remaining >= info.Price
			local priceCol = canBuy and pluvGold or pluvRed
			draw.SimpleText(tostring(info.Price) .. " PluvCoin", "GOMI_RoleBtn", w - ScreenScale(12), h / 2, priceCol, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
		end
		row.DoClick = function(sel)
			self:ToggleWeapon(sel.class)
			if self.Selected[sel.class] then
				sel.buyPulse = 1
			end
		end

		scroll:AddItem(row)
	end

	local footer = vgui.Create("DPanel", self)
	footer:SetPos(0, self:GetTall() - footerH)
	footer:SetSize(self:GetWide(), footerH)
	footer.Paint = function(sel, w, h)
		draw.RoundedBox(0, 0, 0, w, h, Color(10, 10, 19, 235))
		surface.SetDrawColor(0, 19, 102, 150)
		surface.DrawRect(0, 0, w, 1)
	end

	self.BudgetLabel = vgui.Create("DLabel", footer)
	self.BudgetLabel:SetFont("GOMI_RoleBtn")
	self.BudgetLabel:SetPos(ScreenScale(20), ScreenScale(8))
	self.BudgetLabel:SetTextColor(pluvGold)
	self.BudgetLabel:SizeToContents()

	self.SpentLabel = vgui.Create("DLabel", footer)
	self.SpentLabel:SetFont("GOMI_RoleCardDesc")
	self.SpentLabel:SetPos(ScreenScale(20), ScreenScale(30))
	self.SpentLabel:SetTextColor(textDim)
	self.SpentLabel:SizeToContents()

	local readyBtn = vgui.Create("DButton", footer)
	readyBtn:SetText("")
	readyBtn:SetSize(ScreenScale(200), ScreenScale(40))
	readyBtn:SetPos(self:GetWide() - ScreenScale(20) - ScreenScale(200), (footerH - ScreenScale(40)) / 2)
	readyBtn:SetCursor("hand")
	readyBtn.hover = 0
	readyBtn.Paint = function(sel, w, h)
		sel.hover = Lerp(FrameTime() * 10, sel.hover, sel:IsHovered() and 1 or 0)
		draw.RoundedBox(6, 0, 0, w, h, sel.hover > 0.01 and Color(60, 20, 24, 240) or Color(35, 16, 20, 235))
		surface.SetDrawColor(cardBorder.r, cardBorder.g, cardBorder.b, 200)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
		draw.SimpleText("ГОТОВО", "GOMI_RoleBtn", w / 2, h / 2, textBright, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	readyBtn.DoClick = function()
		self:SaveSelection()
		self:Remove()
	end
end

derma.DefineControl("HMCD_RolePanelList", "", PANEL, "DPanel")
--//
--\\https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/vgui/dhorizontalscroller.lua
local PANEL = {}

AccessorFunc( PANEL, "m_iOverlap",			"Overlap" )
AccessorFunc( PANEL, "m_bShowDropTargets",	"ShowDropTargets", FORCE_BOOL )

function PANEL:Init()

	self.Panels = {}
	self.OffsetX = 0
	self.FrameTime = 0

	self.pnlCanvas = vgui.Create( "DDragBase", self )
	self.pnlCanvas:SetDropPos( "6" )
	self.pnlCanvas:SetUseLiveDrag( false )
	self.pnlCanvas.OnModified = function() self:OnDragModified() end

	self.pnlCanvas.UpdateDropTarget = function( Canvas, drop, pnl )
		if ( !self:GetShowDropTargets() ) then return end
		DDragBase.UpdateDropTarget( Canvas, drop, pnl )
	end

	self.pnlCanvas.OnChildAdded = function( Canvas, child )

		local dn = Canvas:GetDnD()
		if ( dn ) then

			child:Droppable( dn )
			child.OnDrop = function()

				local x, y = Canvas:LocalCursorPos()
				local closest, id = self.pnlCanvas:GetClosestChild( x, Canvas:GetTall() / 2 ), 0

				for k, v in pairs( self.Panels ) do
					if ( v == closest ) then id = k break end
				end

				table.RemoveByValue( self.Panels, child )
				table.insert( self.Panels, id, child )

				self:InvalidateLayout()

				return child

			end
		end

	end

	self:SetOverlap( 0 )

	self.btnLeft = vgui.Create( "DButton", self )
	self.btnLeft:SetText( "" )
	self.btnLeft.Paint = function( panel, w, h ) derma.SkinHook( "Paint", "ButtonLeft", panel, w, h ) end

	self.btnRight = vgui.Create( "DButton", self )
	self.btnRight:SetText( "" )
	self.btnRight.Paint = function( panel, w, h ) derma.SkinHook( "Paint", "ButtonRight", panel, w, h ) end

end

function PANEL:GetCanvas()
	return self.pnlCanvas
end

function PANEL:ScrollToChild( panel )

	-- make sure our size is all good
	self:InvalidateLayout( true )

	local x, y = self.pnlCanvas:GetChildPosition( panel )
	local w, h = panel:GetSize()

	x = x + w * 0.5
	x = x - self:GetWide() * 0.5

	self:SetScroll( x )

end

function PANEL:SetScroll( x )

	self.OffsetX = x
	self:InvalidateLayout( true )

end

function PANEL:SetUseLiveDrag( bool )
	self.pnlCanvas:SetUseLiveDrag( bool )
end

function PANEL:MakeDroppable( name, allowCopy )
	self.pnlCanvas:MakeDroppable( name, allowCopy )
end

function PANEL:AddPanel( pnl )

	table.insert( self.Panels, pnl )

	pnl:SetParent( self.pnlCanvas )
	self:InvalidateLayout( true )

end

function PANEL:Clear()
	self.pnlCanvas:Clear()
	self.Panels = {}
end

function PANEL:OnMouseWheeled( dlta )

	self.OffsetX = self.OffsetX + dlta * -30
	self:InvalidateLayout( true )

	return true

end

function PANEL:Think()

	-- Hmm.. This needs to really just be done in one place
	-- and made available to everyone.
	local FrameRate = VGUIFrameTime() - self.FrameTime
	self.FrameTime = VGUIFrameTime()

	if ( self.btnRight:IsDown() ) then
		self.OffsetX = self.OffsetX + ( 500 * FrameRate )
		self:InvalidateLayout( true )
	end

	if ( self.btnLeft:IsDown() ) then
		self.OffsetX = self.OffsetX - ( 500 * FrameRate )
		self:InvalidateLayout( true )
	end

	if ( dragndrop.IsDragging() ) then

		local x, y = self:LocalCursorPos()

		if ( x < 30 ) then
			self.OffsetX = self.OffsetX - ( 350 * FrameRate )
		elseif ( x > self:GetWide() - 30 ) then
			self.OffsetX = self.OffsetX + ( 350 * FrameRate )
		end

		self:InvalidateLayout( true )

	end

end

function PANEL:PerformLayout()

	local w, h = self:GetSize()

	self.pnlCanvas:SetTall( h )

	local x = 0

	for k, v in pairs( self.Panels ) do
		if ( !IsValid( v ) ) then continue end
		if ( !v:IsVisible() ) then continue end

		v:SetPos( x, 0 )
		v:SetTall( h )
		if ( v.ApplySchemeSettings ) then v:ApplySchemeSettings() end

		x = x + v:GetWide() - self.m_iOverlap

	end

	self.pnlCanvas:SetWide( x + self.m_iOverlap )

	if ( w < self.pnlCanvas:GetWide() ) then
		self.OffsetX = math.Clamp( self.OffsetX, 0, self.pnlCanvas:GetWide() - self:GetWide() )
	else
		self.OffsetX = 0
	end

	self.pnlCanvas.x = self.OffsetX * -1

	self.btnLeft:SetSize( 15, 15 )
	self.btnLeft:AlignLeft( 4 )
	self.btnLeft:AlignBottom( 5 )

	self.btnRight:SetSize( 15, 15 )
	self.btnRight:AlignRight( 4 )
	self.btnRight:AlignBottom( 5 )

	self.btnLeft:SetVisible( self.pnlCanvas.x < 0 )
	self.btnRight:SetVisible( self.pnlCanvas.x + self.pnlCanvas:GetWide() > self:GetWide() )

end

function PANEL:OnDragModified()
	-- Override me
end

derma.DefineControl( "ZHorizontalScroller", "", PANEL, "Panel" )
--//
