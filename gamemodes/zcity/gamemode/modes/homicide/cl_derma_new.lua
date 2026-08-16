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
	size = ScreenScale(22),
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

-- Truncates text with an ellipsis so it never spills past the given width.
local function fitText(text, font, maxW)
	if not text then return "" end
	surface.SetFont(font)
	local w = surface.GetTextSize(text)
	if w <= maxW then return text end

	local dots = "..."
	local dotsW = surface.GetTextSize(dots)
	local cut = text
	while cut != "" do
		cut = string.sub(cut, 1, string.len(cut) - 1)
		if surface.GetTextSize(cut) + dotsW <= maxW then break end
	end
	return cut .. dots
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
	"weapon_radar",
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
		self.BudgetLabel:SetText("Pluvcoin`s: " .. self:GetBudget())
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
			if gui.IsGameUIVisible() then
				gui.HideGameUI()
			end
		end
	end

	local margin = math.floor(ScreenScale(8))
	local headerH = math.floor(ScreenScale(26))
	local footerH = math.floor(ScreenScale(30))
	local gap = math.floor(ScreenScale(8))
	local bodyY = headerH
	local bodyH = self:GetTall() - bodyY - footerH - margin
	local totalBodyW = self:GetWide() - margin * 2
	local leftW = math.floor(totalBodyW * 0.26)
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

	local title = vgui.Create("DLabel", self)
	title:SetPos(margin, math.floor((headerH - ScreenScale(22)) / 2))
	title:SetFont("GOMI_RoleTitle")
	title:SetText("ВЫБОР ПРЕДАТЕЛЯ")
	title:SetTextColor(Color(0, 0, 0, 0))
	title:SizeToContents()
	title:SetSize(title:GetWide() + 4, title:GetTall() + 4)
	title.anim = 0
	title.Paint = function(sel, w, h)
		sel.anim = Lerp(FrameTime() * 10, sel.anim, 1)
		local alpha = sel.anim * 255
		draw.SimpleText("ВЫБОР ПРЕДАТЕЛЯ", "GOMI_RoleTitle", 2, 2, Color(0, 0, 0, 70 * sel.anim))
		draw.SimpleText("ВЫБОР ПРЕДАТЕЛЯ", "GOMI_RoleTitle", 0, 0, Color(180, 210, 255, alpha))
	end

	local closeBtn = vgui.Create("DButton", self)
	local closeSize = math.floor(headerH * 0.7)
	closeBtn:SetText("")
	closeBtn:SetSize(closeSize, closeSize)
	closeBtn:SetPos(self:GetWide() - margin - closeSize, math.floor((headerH - closeSize) / 2))
	closeBtn:SetCursor("hand")
	closeBtn.hover = 0
	closeBtn.Paint = function(sel, w, h)
		sel.hover = sel:IsHovered() and 1 or 0
		if sel.hover > 0.01 then
			draw.RoundedBox(4, 0, 0, w, h, Color(colAccent.r, colAccent.g, colAccent.b, 140 * sel.hover))
		end
		draw.SimpleText("×", "GOMI_RoleBtn", w / 2, h / 2 - 1, Color(200 + 55 * sel.hover, 210 + 45 * sel.hover, 240, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	closeBtn.DoClick = function()
		self:SaveSelection()
		self:Remove()
	end

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
	classSection:SetPos(math.floor(ScreenScale(10)), math.floor(ScreenScale(8)))
	classSection:SetFont("GOMI_RoleSection")
	classSection:SetText("КЛАСС ПРЕДАТЕЛЯ")
	classSection:SetTextColor(colAccentBright)
	classSection:SizeToContents()

	local sidePad = math.floor(ScreenScale(8))
	local classAreaY = math.floor(ScreenScale(26))
	local classListW = leftW - sidePad * 2
	local classBtnH = math.floor(ScreenScale(22))
	local classGap = math.floor(ScreenScale(4))

	local classList = vgui.Create("DPanel", leftPanel)
	classList:SetPos(sidePad, classAreaY)
	classList:SetSize(classListW, (#ClassOrder * (classBtnH + classGap)))
	classList.Paint = function() end

	local classIdx = 0
	for _, class in ipairs(ClassOrder) do
		local info = MODE.SubRoles[class]
		if not info or not info.PluvCoins then continue end
		classIdx = classIdx + 1

		local btn = vgui.Create("DButton", classList)
		btn:SetText("")
		btn:SetPos(0, (classIdx - 1) * (classBtnH + classGap))
		btn:SetSize(classListW, classBtnH)
		btn:SetCursor("hand")
		btn.class = class
		btn.hover = 0
		btn.Paint = function(sel, w, h)
			sel.hover = sel:IsHovered() and 1 or 0
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
			local priceText = "+" .. info.PluvCoins
			surface.SetFont("GOMI_RolePrice")
			local priceW = surface.GetTextSize(priceText)
			local textPad = math.floor(ScreenScale(6))
			draw.SimpleText(fitText(info.Name, "GOMI_RoleCardTitle", w - textPad * 3 - priceW), "GOMI_RoleCardTitle", textPad, h / 2, nameCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText(priceText, "GOMI_RolePrice", w - textPad, h / 2, pluvGold, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
		end
		btn.DoClick = function(sel)
			self:SelectClass(sel.class)
		end
	end

	local descY = classAreaY + classList:GetTall() + math.floor(ScreenScale(8))
	local descH = bodyH - descY - sidePad

	local descPanel = vgui.Create("DPanel", leftPanel)
	descPanel:SetPos(sidePad, descY)
	descPanel:SetSize(classListW, descH)
	descPanel.Paint = function(sel, w, h)
		draw.RoundedBox(4, 0, 0, w, h, Color(10, 14, 28, 180))
		surface.SetDrawColor(colAccent.r, colAccent.g, colAccent.b, 40)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
	end

	local descScroll = vgui.Create("DScrollPanel", descPanel)
	descScroll:Dock(FILL)
	descScroll:DockMargin(6, 6, 6, 6)

	local descLabel = vgui.Create("DLabel", descScroll)
	descLabel:Dock(TOP)
	descLabel:SetFont("GOMI_RoleCardDesc")
	descLabel:SetTextColor(colTextBright)
	descLabel:SetWrap(true)
	descLabel:SetAutoStretchVertical(true)

	function self:UpdateRoleDescription()
		local info = MODE.SubRoles[self.SelectedClass]
		if info then
			local text = (info.Description or "")
			if info.Objective then
				text = text .. "\n\nЦЕЛЬ: " .. info.Objective
			end
			descLabel:SetText(text)
		else
			descLabel:SetText("")
		end
	end

	self:UpdateRoleDescription()

	local origSelectClass = self.SelectClass
	function self:SelectClass(class)
		origSelectClass(self, class)
		self:UpdateRoleDescription()
	end

	-- Right Panel
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
	shopSection:SetPos(sidePad, math.floor(ScreenScale(8)))
	shopSection:SetFont("GOMI_RoleSection")
	shopSection:SetText("СНАРЯЖЕНИЕ")
	shopSection:SetTextColor(colAccentBright)
	shopSection:SizeToContents()

	local scroll = vgui.Create("DScrollPanel", rightPanel)
	scroll:SetPos(sidePad, classAreaY)
	scroll:SetSize(rightW - sidePad * 2, math.floor(bodyH) - classAreaY - sidePad)
	scroll:SetSkin(hg.GetMainSkin())
	scroll.Paint = function(sel, w, h)
		surface.SetDrawColor(8, 14, 30, 120)
		surface.DrawRect(0, 0, w, h)
	end

	local cardSpace = math.max(2, math.floor(ScreenScale(6)))
	local layout = vgui.Create("DIconLayout", scroll)
	layout:Dock(FILL)
	layout:SetSpaceX(cardSpace)
	layout:SetSpaceY(cardSpace)

	local cols = math.Clamp(math.floor(rightW / ScreenScale(150)), 2, 5)
	local barW = (IsValid(scroll.VBar) and scroll.VBar:GetWide() or 15) + 2
	local innerW = scroll:GetWide() - barW - math.floor(ScreenScale(2))
	local cardW = math.floor((innerW - cardSpace * (cols - 1)) / cols)
	local cardH = math.floor(ScreenScale(50))

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
			sel.hover = sel:IsHovered() and 1 or 0
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

			local pad = math.floor(ScreenScale(6))
			local nameCol = canBuy and colTextBright or colTextMuted
			draw.SimpleText(fitText(info.Name, "GOMI_RoleCardTitle", w - pad * 2), "GOMI_RoleCardTitle", pad, pad, nameCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

			local descYPos = pad + math.floor(ScreenScale(14))
			draw.SimpleText(fitText(info.Desc, "GOMI_RoleShopDesc", w - pad * 2), "GOMI_RoleShopDesc", pad, descYPos, colTextDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

			local priceCol = canBuy and pluvGold or pluvRed
			draw.SimpleText(tostring(info.Price), "GOMI_RolePrice", pad, h - pad, priceCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
			draw.SimpleText("PluvCoin", "GOMI_RoleCardDesc", pad + math.floor(ScreenScale(26)), h - pad, colTextMuted, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)

			if selected then
				draw.SimpleText("ВЗЯТО", "GOMI_RoleSection", w - pad, h - pad, colAccentBright, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
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
	self.BudgetLabel:SetPos(margin, math.floor(footerH * 0.10))
	self.BudgetLabel:SetTextColor(pluvGold)
	self.BudgetLabel:SizeToContents()

	self.SpentLabel = vgui.Create("DLabel", footer)
	self.SpentLabel:SetFont("GOMI_RoleCardDesc")
	self.SpentLabel:SetPos(margin, math.floor(footerH * 0.55))
	self.SpentLabel:SetTextColor(colTextDim)
	self.SpentLabel:SizeToContents()

	local readyW = math.floor(ScreenScale(120))
	local readyH = math.floor(footerH * 0.7)
	local readyBtn = vgui.Create("DButton", footer)
	readyBtn:SetText("")
	readyBtn:SetSize(readyW, readyH)
	readyBtn:SetPos(self:GetWide() - margin - readyW, math.floor((footerH - readyH) / 2))
	readyBtn:SetCursor("hand")
	readyBtn.hover = 0
	readyBtn.Paint = function(sel, w, h)
		sel.hover = sel:IsHovered() and 1 or 0
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

function PANEL:Think()
	if input.IsKeyDown(KEY_ESCAPE) then
		self:SaveSelection()
		self:Remove()
		if gui.IsGameUIVisible() then
			gui.HideGameUI()
		end
		return
	end

	if IsValid(self.BudgetLabel) then
		self.BudgetLabel:SetText("Плювкоины: " .. self:GetBudget())
		self.BudgetLabel:SizeToContents()
	end
	if IsValid(self.SpentLabel) then
		self.SpentLabel:SetText("Потрачено: " .. self:GetSpent() .. "  |  Осталось: " .. (self:GetBudget() - self:GetSpent()))
		self.SpentLabel:SizeToContents()
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
