local MODE = MODE

local blurMat = Material("pp/blurscreen")
local gradient_u = Material("vgui/gradient-u")
local gradient_d = Material("vgui/gradient-d")
local gradient_r = Material("vgui/gradient-r")

-- Blue-black palette
local colAccent = Color(60, 120, 235, 255)
local colAccentBright = Color(100, 160, 255, 255)
local colAccentDim = Color(24, 48, 96, 255)
local colNavyDeep = Color(8, 12, 26, 255)
local colNavyPanel = Color(14, 20, 42, 235)
local colNavyHover = Color(22, 32, 62, 240)
local colNavySelected = Color(18, 36, 78, 245)
local colOverlay = Color(10, 14, 28, 235)
local colTextBright = Color(220, 228, 245)
local colTextDim = Color(100, 118, 148)
local colTextMuted = Color(70, 86, 112)
local pluvGold = Color(255, 200, 60, 255)
local pluvRed = Color(200, 70, 70, 255)

surface.CreateFont("GOMI_RoleTitle", {
	font = "Bahnschrift",
	size = ScreenScale(36),
	weight = 800,
	antialias = true
})
surface.CreateFont("GOMI_RoleSection", {
	font = "Bahnschrift",
	size = ScreenScale(11),
	weight = 600,
	antialias = true,
	extended = true
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
	size = ScreenScale(11),
	weight = 400,
	antialias = true,
	extended = true
})
surface.CreateFont("GOMI_RolePrice", {
	font = "Bahnschrift",
	size = ScreenScale(12),
	weight = 700,
	antialias = true
})

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
	if self.SelectedClass == class then return end
	self.SelectedClass = class
	self:ClampSelectionToBudget()
	if IsValid(self.DescPanel) then
		self.DescPanel:InvalidateLayout(true)
	end
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
		if key == KEY_ESCAPE then
			sel:SaveSelection()
			sel:Remove()
		end
	end

	local margin = ScreenScale(24)
	local headerH = ScreenScale(68)
	local footerH = ScreenScale(64)
	local gap = ScreenScale(16)
	local bodyY = headerH + ScreenScale(8)
	local bodyH = self:GetTall() - bodyY - footerH - margin
	local totalBodyW = self:GetWide() - margin * 2
	local leftW = math.floor(totalBodyW * 0.30)
	local rightW = totalBodyW - leftW - gap

	self.Paint = function(sel, w, h)
		sel.bgAlpha = Lerp(FrameTime() * 8, sel.bgAlpha, 1)
		local a = sel.bgAlpha

		drawBlur(sel, 8)
		surface.SetDrawColor(colOverlay.r, colOverlay.g, colOverlay.b, colOverlay.a * a)
		surface.DrawRect(0, 0, w, h)

		surface.SetDrawColor(colAccent.r, colAccent.g, colAccent.b, 45 * a)
		surface.SetMaterial(gradient_d)
		surface.DrawTexturedRect(0, 0, w, h)
		surface.SetDrawColor(colAccentDim.r, colAccentDim.g, colAccentDim.b, 80 * a)
		surface.SetMaterial(gradient_r)
		surface.DrawTexturedRect(0, 0, w, h)
		surface.SetDrawColor(colNavyDeep.r, colNavyDeep.g, colNavyDeep.b, 160 * a)
		surface.SetMaterial(gradient_u)
		surface.DrawTexturedRect(0, 0, w, h)

		local grid = ScreenScale(28)
		local off = (RealTime() * 10) % grid
		surface.SetDrawColor(colAccent.r, colAccent.g, colAccent.b, 10 * a)
		for i = -1, math.ceil(w / grid) + 1 do
			surface.DrawRect(i * grid - off, 0, 1, h)
		end
		for i = -1, math.ceil(h / grid) + 1 do
			surface.DrawRect(0, i * grid + off, w, 1)
		end

		surface.SetDrawColor(colAccent.r, colAccent.g, colAccent.b, 60)
		surface.DrawRect(margin + leftW + gap / 2 - 1, bodyY, 1, bodyH)
	end

	-- Header
	local title = vgui.Create("DLabel", self)
	title:SetPos(margin, ScreenScale(18))
	title:SetFont("GOMI_RoleTitle")
	title:SetText("ВЫБОР ПРЕДАТЕЛЯ")
	title:SetTextColor(Color(0, 0, 0, 0))
	title.anim = 0
	title.Paint = function(sel, w, h)
		sel.anim = Lerp(FrameTime() * 10, sel.anim, 1)
		local alpha = sel.anim * 255
		draw.SimpleText("ВЫБОР ПРЕДАТЕЛЯ", "GOMI_RoleTitle", 2, 2, Color(0, 0, 0, 70 * sel.anim))
		draw.SimpleText("ВЫБОР ПРЕДАТЕЛЯ", "GOMI_RoleTitle", 0, 0, Color(180, 210, 255, alpha))
	end

	local closeBtn = vgui.Create("DButton", self)
	closeBtn:SetText("")
	closeBtn:SetSize(ScreenScale(32), ScreenScale(32))
	closeBtn:SetPos(self:GetWide() - margin - ScreenScale(32), ScreenScale(16))
	closeBtn:SetCursor("hand")
	closeBtn.hover = 0
	closeBtn.Paint = function(sel, w, h)
		sel.hover = Lerp(FrameTime() * 10, sel.hover, sel:IsHovered() and 1 or 0)
		if sel.hover > 0.01 then
			draw.RoundedBox(4, 0, 0, w, h, Color(colAccent.r, colAccent.g, colAccent.b, 140 * sel.hover))
		end
		draw.SimpleText("×", "GOMI_RoleBtn", w / 2, h / 2 - 1, Color(200 + 55 * sel.hover, 210 + 45 * sel.hover, 240, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	closeBtn.DoClick = function()
		self:SaveSelection()
		self:Remove()
	end

	-- Left column: classes
	local leftPanel = vgui.Create("DPanel", self)
	leftPanel:SetPos(margin, bodyY)
	leftPanel:SetSize(leftW, bodyH)
	leftPanel.Paint = function(sel, w, h)
		draw.RoundedBox(6, 0, 0, w, h, colNavyPanel)
		surface.SetDrawColor(colAccent.r, colAccent.g, colAccent.b, 40)
		surface.SetMaterial(gradient_u)
		surface.DrawTexturedRect(0, 0, w, h)
		surface.SetDrawColor(colAccent.r, colAccent.g, colAccent.b, 80)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
	end

	local classSection = vgui.Create("DLabel", leftPanel)
	classSection:SetPos(ScreenScale(14), ScreenScale(10))
	classSection:SetFont("GOMI_RoleSection")
	classSection:SetText("КЛАСС ПРЕДАТЕЛЯ")
	classSection:SetTextColor(colAccentBright)
	classSection:SizeToContents()

	local classListH = ScreenScale(52) * 4 + ScreenScale(6) * 3
	local classList = vgui.Create("DPanel", leftPanel)
	classList:SetPos(ScreenScale(10), ScreenScale(32))
	classList:SetSize(leftW - ScreenScale(20), classListH)
	classList.Paint = function() end

	local classBtnH = ScreenScale(52)
	local classGap = ScreenScale(6)
	local classIdx = 0
	for _, class in ipairs(ClassOrder) do
		local info = MODE.SubRoles[class]
		if not info or not info.PluvCoins then continue end
		classIdx = classIdx + 1

		local btn = vgui.Create("DButton", classList)
		btn:SetText("")
		btn:SetPos(0, (classIdx - 1) * (classBtnH + classGap))
		btn:SetSize(classList:GetWide(), classBtnH)
		btn:SetCursor("hand")
		btn.class = class
		btn.hover = 0
		btn.Paint = function(sel, w, h)
			sel.hover = Lerp(FrameTime() * 10, sel.hover, sel:IsHovered() and 1 or 0)
			local selected = self.SelectedClass == sel.class

			local bg = colNavyPanel
			if selected then
				bg = colNavySelected
			elseif sel.hover > 0.01 then
				bg = colNavyHover
			end
			draw.RoundedBox(4, 0, 0, w, h, bg)

			if selected then
				surface.SetDrawColor(colAccentBright)
				surface.DrawRect(0, 0, 3, h)
				surface.SetDrawColor(colAccent.r, colAccent.g, colAccent.b, 200)
				surface.DrawOutlinedRect(0, 0, w, h, 1)
			elseif sel.hover > 0.01 then
				surface.SetDrawColor(colAccent.r, colAccent.g, colAccent.b, 120 * sel.hover)
				surface.DrawOutlinedRect(0, 0, w, h, 1)
			end

			local nameCol = selected and colTextBright or Color(Lerp(sel.hover, colTextDim.r, colTextBright.r), Lerp(sel.hover, colTextDim.g, colTextBright.g), Lerp(sel.hover, colTextDim.b, colTextBright.b))
			draw.SimpleText(info.Name, "GOMI_RoleCardTitle", ScreenScale(12), h / 2 - ScreenScale(6), nameCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText("+" .. info.PluvCoins, "GOMI_RolePrice", w - ScreenScale(10), h / 2, pluvGold, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
		end
		btn.DoClick = function(sel)
			self:SelectClass(sel.class)
		end
	end

	local descPanel = vgui.Create("DPanel", leftPanel)
	descPanel:SetPos(ScreenScale(10), ScreenScale(32) + classListH + ScreenScale(10))
	descPanel:SetSize(leftW - ScreenScale(20), bodyH - ScreenScale(32) - classListH - ScreenScale(20))
	descPanel.Paint = function(sel, w, h)
		draw.RoundedBox(4, 0, 0, w, h, Color(10, 16, 34, 200))
		surface.SetDrawColor(colAccent.r, colAccent.g, colAccent.b, 50)
		surface.DrawOutlinedRect(0, 0, w, h, 1)

		local info = MODE.SubRoles[self.SelectedClass]
		if not info then return end

		local pad = ScreenScale(10)
		draw.SimpleText(info.Name, "GOMI_RoleCardTitle", pad, pad, colTextBright, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		draw.SimpleText("+" .. (info.PluvCoins or 0) .. " PluvCoin", "GOMI_RolePrice", pad, pad + ScreenScale(18), pluvGold, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

		surface.SetDrawColor(colAccent.r, colAccent.g, colAccent.b, 40)
		surface.DrawRect(pad, pad + ScreenScale(36), w - pad * 2, 1)

		local desc = info.Description or ""
		local lines = string.Explode("\n", desc)
		local y = pad + ScreenScale(44)
		for _, line in ipairs(lines) do
			line = string.Trim(line)
			if line == "" then continue end
			draw.SimpleText(line, "GOMI_RoleCardDesc", pad, y, colTextDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			y = y + ScreenScale(13)
			if y > h - pad then break end
		end
	end
	self.DescPanel = descPanel

	-- Right column: shop grid
	local rightPanel = vgui.Create("DPanel", self)
	rightPanel:SetPos(margin + leftW + gap, bodyY)
	rightPanel:SetSize(rightW, bodyH)
	rightPanel.Paint = function(sel, w, h)
		draw.RoundedBox(6, 0, 0, w, h, colNavyPanel)
		surface.SetDrawColor(colAccent.r, colAccent.g, colAccent.b, 30)
		surface.SetMaterial(gradient_u)
		surface.DrawTexturedRect(0, 0, w, h)
		surface.SetDrawColor(colAccent.r, colAccent.g, colAccent.b, 80)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
	end

	local shopSection = vgui.Create("DLabel", rightPanel)
	shopSection:SetPos(ScreenScale(14), ScreenScale(10))
	shopSection:SetFont("GOMI_RoleSection")
	shopSection:SetText("СНАРЯЖЕНИЕ")
	shopSection:SetTextColor(colAccentBright)
	shopSection:SizeToContents()

	local scroll = vgui.Create("DScrollPanel", rightPanel)
	scroll:SetPos(ScreenScale(10), ScreenScale(32))
	scroll:SetSize(rightW - ScreenScale(20), bodyH - ScreenScale(42))
	scroll:SetSkin(hg.GetMainSkin())
	scroll.Paint = function(sel, w, h)
		surface.SetDrawColor(8, 14, 30, 120)
		surface.DrawRect(0, 0, w, h)
	end

	local layout = vgui.Create("DIconLayout", scroll)
	layout:Dock(FILL)
	layout:SetSpaceX(ScreenScale(8))
	layout:SetSpaceY(ScreenScale(8))

	local cols = rightW > ScreenScale(520) and 3 or 2
	local innerW = scroll:GetWide() - ScreenScale(4)
	local cardW = math.floor((innerW - ScreenScale(8) * (cols - 1)) / cols)
	local cardH = ScreenScale(108)

	for _, class in ipairs(ShopOrder) do
		local info = MODE.TraitorShop[class]
		if not info then continue end

		local card = layout:Add("DButton")
		card:SetText("")
		card:SetSize(cardW, cardH)
		card:SetCursor("hand")
		card.class = class
		card.hover = 0
		card.checkAnim = 0
		card.buyPulse = 0
		card.Paint = function(sel, w, h)
			sel.hover = Lerp(FrameTime() * 10, sel.hover, sel:IsHovered() and 1 or 0)
			local selected = self.Selected[sel.class] ~= nil
			sel.checkAnim = Lerp(FrameTime() * 18, sel.checkAnim, selected and 1 or 0)
			sel.buyPulse = math.max(0, sel.buyPulse - FrameTime() * 2.2)

			local remaining = self:GetBudget() - self:GetSpent()
			local canBuy = selected or remaining >= info.Price

			local bg = colNavyPanel
			if selected then
				bg = colNavySelected
			elseif sel.hover > 0.01 then
				bg = colNavyHover
			end
			if not canBuy and not selected then
				bg = Color(12, 16, 28, 200)
			end
			draw.RoundedBox(4, 0, 0, w, h, bg)

			if selected then
				surface.SetDrawColor(colAccentBright.r, colAccentBright.g, colAccentBright.b, 200)
				surface.DrawOutlinedRect(0, 0, w, h, 1)
				surface.SetDrawColor(colAccentBright)
				surface.DrawRect(0, h - 2, w * sel.checkAnim, 2)
			elseif sel.hover > 0.01 then
				surface.SetDrawColor(colAccent.r, colAccent.g, colAccent.b, 100 * sel.hover)
				surface.DrawRect(0, h - 1, w, 1)
			end

			if sel.buyPulse > 0 then
				surface.SetDrawColor(colAccentBright.r, colAccentBright.g, colAccentBright.b, 40 * sel.buyPulse)
				surface.DrawRect(0, 0, w, h)
				local p = 1 - sel.buyPulse
				local size = Lerp(p, h * 0.25, w * 0.85)
				surface.SetDrawColor(colAccentBright.r, colAccentBright.g, colAccentBright.b, 180 * sel.buyPulse)
				surface.DrawOutlinedRect(w / 2 - size / 2, h / 2 - size / 2, size, size, 2)
			end

			local pad = ScreenScale(8)
			local nameCol = canBuy and colTextBright or colTextMuted
			draw.SimpleText(info.Name, "GOMI_RoleCardTitle", pad, pad, nameCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

			local descY = pad + ScreenScale(16)
			draw.SimpleText(info.Desc, "GOMI_RoleShopDesc", pad, descY, colTextDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

			local priceCol = canBuy and pluvGold or pluvRed
			draw.SimpleText(tostring(info.Price), "GOMI_RolePrice", pad, h - pad - ScreenScale(2), priceCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
			draw.SimpleText("PluvCoin", "GOMI_RoleCardDesc", pad + ScreenScale(36), h - pad, colTextMuted, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)

			if selected then
				draw.SimpleText("ВЗЯТО", "GOMI_RoleSection", w - pad, pad + ScreenScale(2), colAccentBright, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
			end
		end
		card.DoClick = function(sel)
			self:ToggleWeapon(sel.class)
			if self.Selected[sel.class] then
				sel.buyPulse = 1
			end
		end
	end

	-- Footer
	local footer = vgui.Create("DPanel", self)
	footer:SetPos(0, self:GetTall() - footerH)
	footer:SetSize(self:GetWide(), footerH)
	footer.Paint = function(sel, w, h)
		draw.RoundedBox(0, 0, 0, w, h, Color(8, 12, 24, 245))
		surface.SetDrawColor(colAccent.r, colAccent.g, colAccent.b, 100)
		surface.DrawRect(0, 0, w, 1)
		surface.SetDrawColor(colAccentDim.r, colAccentDim.g, colAccentDim.b, 60)
		surface.SetMaterial(gradient_u)
		surface.DrawTexturedRect(0, 0, w, h)
	end

	self.BudgetLabel = vgui.Create("DLabel", footer)
	self.BudgetLabel:SetFont("GOMI_RoleBtn")
	self.BudgetLabel:SetPos(margin, ScreenScale(10))
	self.BudgetLabel:SetTextColor(pluvGold)
	self.BudgetLabel:SizeToContents()

	self.SpentLabel = vgui.Create("DLabel", footer)
	self.SpentLabel:SetFont("GOMI_RoleCardDesc")
	self.SpentLabel:SetPos(margin, ScreenScale(32))
	self.SpentLabel:SetTextColor(colTextDim)
	self.SpentLabel:SizeToContents()

	local readyBtn = vgui.Create("DButton", footer)
	readyBtn:SetText("")
	readyBtn:SetSize(ScreenScale(180), ScreenScale(40))
	readyBtn:SetPos(self:GetWide() - margin - ScreenScale(180), (footerH - ScreenScale(40)) / 2)
	readyBtn:SetCursor("hand")
	readyBtn.hover = 0
	readyBtn.Paint = function(sel, w, h)
		sel.hover = Lerp(FrameTime() * 10, sel.hover, sel:IsHovered() and 1 or 0)
		local bg = Color(Lerp(sel.hover, 20, 40), Lerp(sel.hover, 50, 90), Lerp(sel.hover, 120, 180), 240)
		draw.RoundedBox(4, 0, 0, w, h, bg)
		surface.SetDrawColor(colAccentBright.r, colAccentBright.g, colAccentBright.b, Lerp(sel.hover, 120, 220))
		surface.DrawOutlinedRect(0, 0, w, h, 1)
		draw.SimpleText("ГОТОВО", "GOMI_RoleBtn", w / 2, h / 2, colTextBright, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
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
