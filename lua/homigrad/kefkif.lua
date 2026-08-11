-- kefkif.lua
-- Меню и анимации, перенесены из client (1).lua
-- Требует наличия таблицы Kefir, runtimeApi, localCache и нативного бриджа nativeApi

if CLIENT then

-- ============================================================
-- ВСПОМОГАТЕЛЬНЫЕ PAINT-ФУНКЦИИ
-- ============================================================

function Kefir.paint.IsHovered(selfRef, x, y, w, h)
	local mx, my = gui.MousePos()
	return x <= mx and mx <= x + w and y <= my and my <= y + h
end

function Kefir.paint.IBlur(selfRef, amount, passes, ox, oy)
	amount = amount or 2.5
	passes = passes or 3
	local sw = ScrW()
	local sh = ScrH()
	local blurMat = Kefir.material.blur
	surface.SetDrawColor(color_white)
	surface.SetMaterial(blurMat)
	for i = 1, passes do
		blurMat:SetFloat("$blur", i / passes * amount)
		blurMat:Recompute()
		render.UpdateScreenEffectTexture()
		surface.DrawTexturedRect(-(ox or 0), -(oy or 0), sw, sh)
	end
end

function Kefir.paint.SBlur(selfRef, x, y, w, h, amount, passes, pad)
	amount = amount or 2.5
	passes = passes or 3
	pad = pad or 0
	render.SetScissorRect(x - pad, y, x + w + pad, y + h, true)
	selfRef:IBlur(amount, passes, 0, 0)
	render.SetScissorRect(0, 0, 0, 0, false)
end

end -- CLIENT

if CLIENT then

-- ============================================================
-- РЕГИСТРАЦИЯ UI-КОМПОНЕНТОВ
-- ============================================================

-- Вкладка (кнопка переключения таба)
Kefir.paint:Register("tabbutton", "DButton", {
	Init = function(p)
		p:SetText("")
	end,
	Paint = function(p, w, h)
		local ea, eb = p:LocalToScreen(0, 0)
		render.SetScissorRect(ea, eb, ea + w, eb + h, true)

		local tabKey  = p.Tab[1]
		local tabIcon = p.Tab[2]
		local isSelected = Kefir.tabs.current == tabKey
		local clr = p:IsHovered() and not isSelected and Kefir.color.groupbox
		           or isSelected and Kefir.color.kefir_red
		           or Kefir.color.white
		local langRU = Kefir:GetLanguage() == "RU" and 11 or 10

		Kefir.paint:Box(1, 8, w - 2, h - 16, true, Kefir.color.kefir_black, Kefir.color.groupbox)
		local iw, ih = Kefir.paint:Text(tabIcon, 26, 16, (h - 26) / 2, clr, TEXT_ALIGN_CENTER, "icons")
		Kefir.paint:EOText(Kefir:GetLangText(tabKey), 13, iw + 10, (h - 6) / 2, Kefir.paint:HColorAlpha(clr, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, "visuals", 255)
		Kefir.paint:EOText(string.lower(Kefir:GetLangText(tabKey)), langRU, iw + 7, (h + 16) / 2, Kefir.paint:HColorAlpha(clr, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, "flag", 255)

		render.SetScissorRect(0, 0, 0, 0, false)
	end,
	DoClick = function(p)
		Kefir.tabs.current = p.Tab[1]
		Kefir.paint:TABUpdate()
	end
})

end -- CLIENT

if CLIENT then

-- Обычная кнопка
Kefir.paint:Register("button", "DButton", {
	Init = function(p)
		p:SetText("")
		p.__textsize = 6
		p.__text = "?"
		p.__textfont = "ofont"
		p.__buttonrounded = false
		p.__buttonroundedcolor = Kefir.color.kefir_red
		p.__std__brc = nil
		p.__tocolor = nil
		p.__htab = -30
	end,
	SRoundedColor = function(p, c) p.__buttonroundedcolor = c or Kefir.color.kefir_red; if not p.__std__brc then p.__std__brc = p.__buttonroundedcolor end end,
	GTextSize   = function(p) return p.__textsize or 6 end,
	GText       = function(p) return p.__text or "?" end,
	GTextFont   = function(p) return p.__textfont or "ofont" end,
	GRounded    = function(p) return p.__buttonrounded or false end,
	GRoundedColor = function(p) return p.__buttonroundedcolor or Kefir.color.kefir_red end,
	SText     = function(p, t) p.__text = t or "?" end,
	STextFont = function(p, f) p.__textfont = f or "ofont" end,
	STextSize = function(p, s) p.__textsize = s end,
	SRounded  = function(p, b) p.__buttonrounded = b end,
	Paint = function(p, w, h)
		p.__tocolor = p.__std__brc
		if p.__texttabtext and p:IsHovered() then p.__tocolor = Kefir.color.groupname end

		local ea, eb = p:LocalToScreen(0, 0)
		render.SetScissorRect(ea, eb, ea + w, eb + h, true)

		local lerpClr = Kefir:LerpColor(FrameTime() * 4, p:GRoundedColor() or p.__std__brc, p.__tocolor)
		p:SRoundedColor(lerpClr)
		Kefir.paint:Box(0, 0, w, h, p:GRounded(), Kefir.color.kefir_black, p:GRoundedColor(), 2, true)

		if p.__texttabtext then
			Kefir.paint:Text(Kefir:GetLangText(p:GText()) or "", p:GTextSize(), w / 2, (h - p:GTextSize()) / 2, Kefir.color.white, TEXT_ALIGN_CENTER, p:GTextFont() .. ".blur")
		end
		Kefir.paint:Text(Kefir:GetLangText(p:GText()) or "", p:GTextSize(), w / 2, (h - p:GTextSize()) / 2, Kefir.color.white, TEXT_ALIGN_CENTER, p:GTextFont())

		if p.__texttabtext then
			p.__htab = Kefir:Lerp(FrameTime() * 4.5, p.__htab or -30, p:IsHovered() and h or -30)
			-- градиент анимации при наведении
			Kefir.paint:Gradient(0, 0, w, p.__htab + 4, Kefir.color.tabbox, Kefir.color.kefir_red, true)
			Kefir.paint:Text(Kefir:GetLangText(p.__texttabtext), 20, w / 2, (p.__htab - 20) / 2, Kefir.color.white, TEXT_ALIGN_CENTER, "ofont")
		end

		render.SetScissorRect(0, 0, 0, 0, false)
	end
})

end -- CLIENT

if CLIENT then

-- Дефолтная кнопка (простая)
Kefir.paint:Register("default_button", "DButton", {
	Paint = function(p, w, h)
		local ts = p._textsize
		Kefir.paint:Box(0, 0, w, h, p._rounded or false, Kefir.color.kefir_red or Kefir.color.kefir_black, p._roundedcolor or Kefir.color.kefir_red, 1, true)
		Kefir.paint:Text(Kefir:GetLangText(p._text) or "", ts, w / 2, (h - ts) / 2, Kefir.color.white, TEXT_ALIGN_CENTER, "ofont")
	end
})

-- Чекбокс с анимацией clickanim
Kefir.paint:Register("checkbox", "DCheckBox", {
	DoClick = function(p)
		if not p.adata.lang333 then
			if p.__var ~= "toggle" then
				if isbool(runtimeApi.var[p.__tab][p.__group][p.__var][1]) then
					runtimeApi.var[p.__tab][p.__group][p.__var][1] = not runtimeApi.var[p.__tab][p.__group][p.__var][1]
				end
			elseif isbool(runtimeApi.var[p.__tab][p.__var][1]) then
				runtimeApi.var[p.__tab][p.__var][1] = not runtimeApi.var[p.__tab][p.__var][1]
			end
		else
			runtimeApi.var.USER_CONFIG.SHARE = not runtimeApi.var.USER_CONFIG.SHARE
		end
	end,
	AnimationThink = function(p)
		if p._glow then
			p._glow = Kefir:Lerp(FrameTime() * 4, p._glow or 0, p:IsHovered() and 90 or 0)
		end
	end,
	Paint = function(p, w, h)
		p.adata = p.adata or {}
		local widget = p.__widget or { 0, Kefir.color.white }
		local offset = widget[1] or 0
		local textClr = widget[2] or Kefir.color.white
		local boxW = w - (w - 15)
		local textX = boxW + 22
		local fontSize = 20
		local val

		if not p.adata.lang333 then
			val = runtimeApi.var[p.__tab] and runtimeApi.var[p.__tab][p.__group] and runtimeApi.var[p.__tab][p.__group][p.__var] and runtimeApi.var[p.__tab][p.__group][p.__var][1]
		else
			val = runtimeApi.var.USER_CONFIG.SHARE
		end

		-- glow при наведении
		Kefir.paint:Box(0 + offset, 0, w, h, false, Kefir.paint:HColorAlpha(Kefir.color.kefir_red, p._glow or 0))
		-- рамка чекбокса
		Kefir.paint:Box(0 + offset, 0, boxW, h, true, Kefir.color.kefir_black, Kefir.color.kefir_red, 1, true)
		-- текст
		Kefir.paint:Text(Kefir:GetLangText(p.__cachetext), fontSize, textX / 2 + offset, h - (fontSize - 2), textClr, TEXT_ALIGN_LEFT, "ofont")

		-- анимация заполнения (clickanim)
		local pad = 2
		p.clickanim = Kefir:Lerp(12 * FrameTime(), p.clickanim or 0, val and 1.1 or 0)
		Kefir.paint:Gradient(pad + offset, pad, (boxW - pad * 2) * p.clickanim - 1, h - pad * 2, Kefir.color.kefir_red, Kefir.color.groupname, true, nil, Kefir.material.gui_up)
	end
})

end -- CLIENT

if CLIENT then

-- Слайдер с анимацией заполнения
Kefir.paint:Register("slider", "DNumSlider", {
	Init = function(p)
		p.Label:SetColor(Color(200, 200, 200))
		p.TextArea:SetVisible(false)
		function p.Paint() end
		function p.Slider.Knob.Paint() end
		p.initialize = false
		p.stackvar = {}
	end,
	PushVar = function(p, v) table.insert(p.stackvar, v) end,
	GetStack = function(p) return p.stackvar or {} end,
	OnValueChanged = function(p, val)
		if p.initialize then
			local st = p:GetStack()
			local rounded = p.wdata[3] == 0 and math.floor(val) or math.Round(val, 1)
			runtimeApi.var[Kefir.tabs.current][st[1]][st[2]][1] = rounded
		end
	end
})

-- Текстовый лейбл
Kefir.paint:Register("text", "DLabel", {
	Init = function(p)
		p.__data = { "?", 16, Kefir.color.white, "ofont" }
		p:SetText("")
	end,
	Paint = function(p)
		local d = p.__data
		Kefir.paint:Text(Kefir:GetLangText(d[1]), d[2], 0, 0, d[3], TEXT_ALIGN_LEFT, d[4])
	end
})

-- Панель-контейнер группы
Kefir.paint:Register("panelcontent", "DPanel", {
	Paint = function(p, w, h)
		Kefir.paint:Box(0, 0, w, h, true, Kefir.color.kefir_black, Kefir.color.groupbox, 1, true)
	end,
	PaintOver = function(p, w)
		surface.SetFont(Kefir:GetName() .. "kefir.ofont.16")
		local name = Kefir:GetLangText(p.__groupname)
		local tw, th = surface.GetTextSize(name)
		local bw = tw + 25.5
		local ny = -5.5
		Kefir.paint:Box((w - (bw + 2)) / 2, ny + 5, bw + 2, th, true, Kefir.color.groupname, Kefir.color.groupname, 0, true)
		Kefir.paint:Box((w - bw) / 2, ny + 5, bw, th - 1, true, Kefir.color.kefir_black, Kefir.color.groupname, 0, true)
		Kefir.paint:Text(name, 16, w / 2, ny + 4, Kefir.color.white, TEXT_ALIGN_CENTER, "ofont")
	end
})

end -- CLIENT

if CLIENT then

-- Главное окно меню (menuframe) с анимациями
Kefir.paint:Register("menuframe", "DFrame", {
	Init = function(p)
		if IsValid(Kefir.menu) then
			Kefir.paint:Delete(Kefir)
			return
		end
	end,
	OnRemove = function()
		Kefir.paint:fDelete(Kefir.previewesp)
		Kefir.paint:fDelete(Kefir.filteresp)
		Kefir.paint:fDelete(Kefir.hitboxaim)
		Kefir.paint:fDelete(Kefir.tab_frame)
	end,
	OnKeyCodePressed = function(p, key)
		local hkc = Kefir.hotkey_choosing
		if key == KEY_MINUS and not p.ForceClose then
			p:Remove()
			p = nil
			Kefir.paint:fDelete(Kefir.previewesp)
			Kefir.paint:fDelete(Kefir.filteresp)
			Kefir.paint:fDelete(Kefir.hitboxaim)
			Kefir.paint:fDelete(Kefir.tab_frame)
		end
		if hkc[1][1] ~= "none" then
			if key ~= KEY_ESCAPE then
				runtimeApi.var[hkc[1][2]][hkc[1][3]][hkc[1][1]][1] = key
			end
			hkc[1][1] = "none"
		end
	end,
	Paint = function(p, w, h)
		Kefir.paint:rectBox(w, h, 0, 0, color_black)
		Kefir.paint:rectBox(w - 2, h - 2, 1, 1, Kefir.color.groupname)
		Kefir.paint:rectBox(w - 4, h - 4, 2, 2, Kefir.color.kefir_black)

		local logoText   = "https://t.me/mayrcheat"
		local footerText = Kefir:GetLangText("mayrr.zip") .. " | build"
		local cx = w / 2
		local ny = 2

		Kefir.paint:Text(logoText, 32, cx, ny, Kefir.paint:HColorAlpha(Kefir.color.kefir_red, 155), TEXT_ALIGN_CENTER, "blur")
		local _, lh = Kefir.paint:Text(logoText, 31, cx, ny, Kefir.color.white, TEXT_ALIGN_CENTER, "ofont")
		Kefir.paint:GlowText(footerText, 18, cx, ny + lh, Kefir.color.white, TEXT_ALIGN_CENTER)

		-- FAQ анимация (size_text_update)
		if runtimeApi.var.MISC and runtimeApi.var.MISC[1] then
			local faqAnim = runtimeApi.var.MISC[1].faqz_animation
			if faqAnim and faqAnim[1] then
				p.size_text_update = math.floor(Kefir:Lerp(8 * FrameTime(), p.size_text_update or 0, 0))
			else
				p.size_text_update = 0
			end
		end

		local footerClr = Kefir.qfaq ~= "" and Kefir.color.white or Kefir.color.footeri
		local footerMsg = Kefir.qfaq ~= "" and Kefir.qfaq or Kefir:GetLangText(Kefir.qfaq_text)
		local xPad = w * 0.025

		Kefir.paint:Text(footerMsg, 12 + (p.size_text_update or 0), xPad + 14, h - 23, footerClr, TEXT_ALIGN_LEFT, "chat2")

		surface.SetDrawColor(Kefir.color.line)
		surface.DrawLine(20, 75, w - 20, 75)
	end,
	Think = function(p)
		local hkc = Kefir.hotkey_choosing
		p.wh = { p:GetWide(), p:GetTall() }
		for k = 107, 112 do
			if input.IsButtonDown(k) and hkc[1][1] ~= "none" then
				runtimeApi.var[hkc[1][2]][hkc[1][3]][hkc[1][1]][1] = k
				hkc[1][1] = "none"
			end
		end
		if p.ForceClose and p:GetAlpha() < 1 then
			Kefir.paint:Delete(Kefir)
		end
	end
})

end -- CLIENT

if CLIENT then

-- jframe (вспомогательное окно с анимацией появления)
Kefir.paint:Register("jframe", "DFrame", {
	Init = function(p)
		p:SetTitle("")
		p:SetZPos(-9999)
		p:ShowCloseButton(false)
		p:SetDraggable(false)
		p:SetAlpha(0)
		p:AlphaTo(255, 0.1, 0, nil)
		p:SetPaintedManually(not nativeApi.standalone_vgui)
	end,
	Paint = function(p, w, h)
		local a = p:GetAlpha()
		Kefir.paint:rectBox(w, h, 0, 0, Kefir.paint:HColorAlpha(color_black, a))
		Kefir.paint:rectBox(w - 2, h - 2, 1, 1, Kefir.paint:HColorAlpha(Kefir.color.groupname, a))
		Kefir.paint:rectBox(w - 4, h - 4, 2, 2, Kefir.paint:HColorAlpha(Kefir.color.kefir_black, a))
	end
})

-- color_picker
Kefir.paint:Register("color_picker", "DFrame", {
	Init = function(p)
		p:ShowCloseButton(false)
		p:SetTitle("")
	end,
	Paint = function(p, w, h)
		Kefir.paint:Box(0, 0, w, h, true, Kefir.color.kefir_black, Kefir.color.kefir_red, 2, true)
	end
})

-- color_selector (выбор цвета с анимацией hover)
Kefir.paint:Register("color_selector", "DButton", {
	Init = function(p)
		p.__var = Kefir.color.white
		p.stackvar = {}
		p:SetText("")
	end,
	SetVar  = function(p, v) p.__var = v end,
	PushVar = function(p, v) table.insert(p.stackvar, v) end,
	GetStack = function(p) return p.stackvar or {} end,
	GetVar  = function(p) return p.__var end,
	Paint = function(p, w, h)
		Kefir.paint:Box(0, 0, w, h, true, p:GetVar(), Kefir.color.picker_clr, 1, true)
	end,
	DoClick = function(p)
		local var   = p:GetVar()
		local stack = p:GetStack()
		Kefir.cpick_act = true
		local mx, my = gui.MousePos()
		Kefir.cpickl = Kefir.paint:CreateObject("color_picker")
		Kefir.cpickl:SetPos(mx + 25, my)
		Kefir.cpickl:SetSize(200, 0)
		Kefir.cpickl:MakePopup()
		Kefir.cpickl:SetPaintedManually(not nativeApi.standalone_vgui)
		timer.Simple(0.01, function()
			if IsValid(Kefir.cpickl) then
				function Kefir.cpickl.Think(self)
					if not self:HasFocus() or not IsValid(Kefir.menu) then
						self:Remove()
						Kefir.cpick_act = false
					end
				end
				Kefir.cpickl:SizeTo(200, 200, 0.09, 0, 0.9, nil)
			end
		end)
		function Kefir.cpickl.OnRemove() Kefir.cpick_act = false end

		local mixer = vgui.Create("DColorMixer", Kefir.cpickl)
		mixer:SetPos(5, 5)
		mixer:SetSize(190, 190)
		mixer:SetPalette(false)
		mixer:SetAlphaBar(true)
		mixer:SetWangs(false)
		mixer:SetColor(runtimeApi.var[Kefir.tabs.current][stack[1]][stack[2]][6][stack[3]])
		function mixer.ValueChanged(self, clr)
			runtimeApi.var[Kefir.tabs.current][stack[1]][stack[2]][6][stack[3]] = clr
			if IsValid(p) then p:SetVar(clr) end
		end
		function mixer.OnRemove() Kefir.cpick_act = false end
	end
})

end -- CLIENT

if CLIENT then

-- ============================================================
-- ФУНКЦИЯ TABs — создание плавающей панели вкладок
-- ============================================================
function Kefir.paint.TABs(selfRef)
	if IsValid(Kefir.tab_frame) then
		Kefir.tab_frame:Remove()
		Kefir.tab_frame = nil
		return
	end

	local tabH = 60
	Kefir.tab_frame = selfRef:CreateObject("jframe")
	Kefir.tab_frame:SetPos(0, 0)
	Kefir.tab_frame:SetSize(0, tabH)
	Kefir.tab_frame.XD      = 0
	Kefir.tab_frame.OFFSET_Y = 305
	Kefir.tab_frame.ALPHA    = 0
	Kefir.tab_frame:SetAlpha(0)

	function Kefir.tab_frame.Think(p)
		if not IsValid(Kefir.menu) then return end
		-- анимация выдвижения панели вкладок
		p.OFFSET_Y = Kefir:Lerp(FrameTime() * 8, p.OFFSET_Y or 305, Kefir.menu:GetAlpha() >= 220 and 505 or 405)
		p.ALPHA    = Kefir:Lerp(FrameTime() * 8, p.ALPHA    or 0,   Kefir.menu:GetAlpha() >= 254 and 255 or 0)
		p:SetAlpha(Kefir.menu:GetAlpha() <= 254 and 0 or math.Clamp(p.ALPHA, 0, 255))
		Kefir:TrackMenu(p, p.XD / 3.5, p.OFFSET_Y)
	end

	local btnW  = 100
	local xOff  = 3
	for _, tabEntry in pairs(Kefir.tabs.list) do
		local btn = selfRef:CreateObject("tabbutton", Kefir.tab_frame)
		btn:SetSize(btnW + 3, tabH + 9)
		btn:SetPos(xOff, -4)
		btn.Tab = { tabEntry[1], tabEntry[2] }
		xOff = xOff + (btnW + 5)
	end

	Kefir.tab_frame:SetSize(xOff, tabH)
	Kefir.tab_frame.XD = xOff
end

end -- CLIENT

if CLIENT then

-- ============================================================
-- ФУНКЦИЯ TABUpdate — перестройка содержимого активной вкладки
-- с анимацией появления групп (scissor + ease-out)
-- ============================================================
function Kefir.paint.TABUpdate(selfRef)
	-- удаляем старые группы
	if not table.IsEmpty(Kefir.menu_groups) then
		for i, grp in ipairs(Kefir.menu_groups) do
			grp:Remove()
			Kefir.menu_groups[i] = nil
		end
		Kefir.menu_groups = {}
	end

	if Kefir.menu_scroll then
		Kefir.menu_scroll:Remove()
		Kefir.menu_scroll = nil
	end

	-- вызов специфичного обновления вкладки
	local tabUpd = Kefir.tab_update and Kefir.tab_update[Kefir.tabs.current]
	if isfunction(tabUpd) then
		tabUpd()
	else
		selfRef:fDelete(Kefir.previewesp)
		selfRef:fDelete(Kefir.filteresp)
		selfRef:fDelete(Kefir.hitboxaim)
	end

	-- вкладки с кастомным drawfunction (PLAYERS, HOME, ATTACHMENTS …)
	if runtimeApi.var[Kefir.tabs.current] and runtimeApi.var[Kefir.tabs.current].undraw then
		local name = Kefir.tabs.current
		local titled = name:sub(1,1):upper() .. name:sub(2):lower()

		Kefir.menu_scroll = Kefir.paint:CreateObject("panelcontent", Kefir.menu)
		Kefir.menu_scroll:SetPos(20, 80)
		Kefir.menu_scroll:SetSize(760, 390)
		Kefir.menu_scroll.__groupname = titled

		local df = runtimeApi.var[Kefir.tabs.current].drawfunction
		if isfunction(df) then df(Kefir.menu_scroll) end
		return
	end

	-- обычные вкладки — 3 колонки с анимацией
	local startX = 20
	local startY = 80
	local colW   = 247
	local spawnTime = CurTime()

	for col = 1, 3 do
		local colH = col == 1 and 365 or 390

		Kefir.menu_groups[col] = Kefir.paint:CreateObject("panelcontent", Kefir.menu)
		Kefir.menu_groups[col]:SetPos(startX, col == 1 and startY + (390 - colH) or startY)
		Kefir.menu_groups[col]:SetSize(colW, colH)
		Kefir.menu_groups[col].__groupname =
			runtimeApi.var[Kefir.tabs.current]
			and runtimeApi.var[Kefir.tabs.current][col]
			and runtimeApi.var[Kefir.tabs.current][col].name
			or "?"
		startX = startX + colW + 10

		Kefir.menu_groups[col]:SetZPos(30999)
		Kefir.menu_groups[col]:NoClipping(true)

		-- анимация появления (scissor ease-out)
		local origPaint = Kefir.menu_groups[col].Paint
		Kefir.menu_groups[col].Paint = function(p, w, h)
			local elapsed  = CurTime() - spawnTime
			local progress = math.min(elapsed / 0.35, 1)
			local eased    = 1 - (1 - progress) * (1 - progress)
			local clipH    = math.floor(h * eased)
			local sx, sy   = p:LocalToScreen(0, 0)

			render.SetScissorRect(sx, sy, sx + w, sy + clipH, true)
			if origPaint then origPaint(p, w, h) end
			render.SetScissorRect(0, 0, 0, 0, false)

			-- светящаяся кромка пока анимация не завершена
			if eased < 1 then
				Kefir.paint:Gradient(0, clipH - 2, w, math.Clamp(h - clipH + 2, 0, 250),
					selfRef:HColorAlpha(Kefir.color.kefir_red,   155 * (1 - eased)),
					selfRef:HColorAlpha(Kefir.color.kefir_black, 255), true)
			end
		end

		-- скролл-панель внутри колонки
		local scroll = vgui.Create("DScrollPanel", Kefir.menu_groups[col])
		scroll:Dock(FILL)
		scroll:SetZPos(30999)
		scroll:NoClipping(true)

		local vbar = scroll:GetVBar()
		vbar:SetSize(12, 15)
		vbar.tPos = 0
		vbar.nPos = 0

		function vbar.Paint(self, w, h)
			selfRef:rectBox(w, h, 0, 0, color_black)
			selfRef:rectBox(w - 2, h - 2, 1, 1, Kefir.color.groupname)
			selfRef:rectBox(w - 4, h - 4, 2, 2, Kefir.color.kefir_black)
		end
		function vbar.btnGrip.Paint(self, w, h)
			local clr = self:IsHovered() and Kefir.color.kefir_red or Kefir.color.groupbox
			selfRef:rectBox(w - 8, h, 4, 0, clr)
			selfRef:rectBox(w - 10, h - 2, 5, 1, color_black)
		end
		function vbar.btnUp.Paint() end
		function vbar.btnDown.Paint() end

		Kefir.menu_scroll = scroll

		-- наполнение элементами
		if runtimeApi.var[Kefir.tabs.current] and runtimeApi.var[Kefir.tabs.current][col] then
			local cur    = Kefir.tabs.current
			local group  = runtimeApi.var[cur][col]
			local yOff   = 11
			local items  = {}

			for k, v in pairs(group) do
				if k ~= "name" then table.insert(items, { k, v }) end
			end
			table.sort(items, function(a, b) return (a[2][4] or 0) < (b[2][4] or 0) end)

			for _, item in ipairs(items) do
				local key, data = item[1], item[2]
				local meta = {
					data_var  = data,
					index     = key,
					object_x  = 5,
					object_y  = yOff,
					current_  = cur,
					group     = col
				}
				if isnumber(data[4]) and data[4] > 0 and isfunction(Kefir.drawlist[data[3]]) then
					yOff = yOff + Kefir.drawlist[data[3]](Kefir, meta)
				end
			end
		end
	end
end

end -- CLIENT

if CLIENT then

-- ============================================================
-- ФУНКЦИЯ ToggleMenu — открыть/закрыть меню
-- ============================================================
function Kefir.paint.ToggleMenu(selfRef)
	local owner = selfRef.__owner

	Kefir:_Initialize()

	if owner.menu == nil or not IsValid(owner.menu) or type(owner.menu) ~= "Panel" then
		owner.menu = Kefir.paint:CreateObject("menuframe")

		local sw = ScrW()
		local sh = ScrH()
		local mw, mh = 800, 500
		local pos = Kefir:PosBySize(sw, sh, mw, mh)

		timer.Simple(0.01, function()
			if not IsValid(owner.menu) then return end
			owner.menu:SetSize(mw, mh)
			owner.menu:SetPos(pos[1], pos[2])
			owner.menu:SetAlpha(0)
			owner.menu:SetTitle("")
			owner.menu:ShowCloseButton(false)
			-- анимация появления меню
			owner.menu:AlphaTo(255, 0.05, 0)
			owner.menu.ForceClose = false
		end)

		owner.menu:SetPaintedManually(not nativeApi.standalone_vgui)

		-- восстанавливаем позицию из сохранения
		local drag = Kefir.variables.DRAGMENU
		if drag and drag[1] and drag[2] then
			owner.menu:SetPos(drag[1], drag[2])
		end

		owner.menu:MakePopup()
		nativeApi.util_setMenuPanel(owner.menu)

		-- Master Switch чекбокс
		local ms = Kefir.paint:CreateObject("checkbox", owner.menu)
		ms:SetPos(25, 82)
		ms:SetSize(240, 15)
		ms:SetZPos(31000)
		ms.bgl          = true
		ms.__var        = "toggle"
		ms.__tab        = owner.tabs.current
		ms.__cachetext  = "Master Switch"
		ms.FAQ_INDEX    = "master_switch"
		ms.originalthink = ms.Think

		function ms.Think(self)
			if runtimeApi.var[owner.tabs.current] and runtimeApi.var[owner.tabs.current].undraw then
				self:SetPos(-10000, -10000)
			else
				self:SetPos(25, 82)
			end
			self.__tab = owner.tabs.current
			self.originalthink(self)
		end

		selfRef:TABs()
		selfRef:TABUpdate()
	else
		-- закрытие с сохранением позиции
		local mx, my = owner.menu:GetPos()
		Kefir.variables.DRAGMENU = { mx, my }

		selfRef:fDelete(owner.menu)
		selfRef:fDelete(Kefir.previewesp)
		selfRef:fDelete(Kefir.filteresp)
		selfRef:fDelete(Kefir.hitboxaim)
		selfRef:fDelete(Kefir.tab_frame)

		owner.menu.ForceClose = true
	end
end

end -- CLIENT

if CLIENT then

-- ============================================================
-- ВСПОМОГАТЕЛЬНЫЕ АНИМАЦИОННЫЕ PAINT-ФУНКЦИИ
-- ============================================================

-- Bloom (свечение вокруг прямоугольника)
function Kefir.paint.Bloom(selfRef, x, y, w, h, clr, passes, size, alpha)
	passes = passes or 6
	size   = size   or 10
	alpha  = alpha  or 55
	for i = passes, 1, -1 do
		local frac = i / passes
		local pad  = size * frac
		surface.SetDrawColor(clr.r, clr.g, clr.b, math.floor(alpha * (1 - frac)))
		surface.DrawRect(x - pad, y - pad, w + pad * 2, h + pad * 2)
	end
end

-- Shadow
function Kefir.paint.Shadow(selfRef, x, y, w, h, depth, alpha)
	for i = 1, depth do
		surface.DrawRect(x - i, y - i, w + i * 2, h + i * 2)
		-- цвет задаётся снаружи, здесь только геометрия
	end
end

-- GlowText — текст с размытым дублем для эффекта свечения
function Kefir.paint.GlowText(selfRef, text, size, x, y, clr, xalign, yalign, fontType)
	fontType = fontType or "ofont"
	selfRef:Text(text, size, x, y, clr, xalign, yalign, fontType)
	selfRef:Text(text, size, x, y, clr, xalign, yalign, "glow")
end

-- Gradient (обёртка)
function Kefir.paint.Gradient(selfRef, x, y, w, h, clr1, clr2, invert, matOverride, matOverride2)
	surface.SetDrawColor(clr1.r, clr1.g, clr1.b, clr1.a or 255)
	surface.DrawRect(x, y, w, h)

	local mat = matOverride2 and matOverride2
	           or invert     and (matOverride or Kefir.material.vgui_bottom)
	           or               (matOverride or Kefir.material.vgui_up)

	surface.SetDrawColor(clr2.r, clr2.g, clr2.b, clr2.a or 255)
	surface.SetMaterial(mat)
	surface.DrawTexturedRect(x, y, w, h)
end

-- Corner (дуга)
function Kefir.paint.Corner(selfRef, cx, cy, r, startA, endA, clr, thickness, quality)
	local px, py
	for i = 0, quality do
		local ang = math.rad(startA + (endA - startA) * (i / quality))
		local nx  = cx + math.cos(ang) * r
		local ny  = cy + math.sin(ang) * r
		if px then Kefir.paint:Line(px, py, nx, ny, clr, thickness) end
		px, py = nx, ny
	end
end

-- CornerOutline (скруглённый прямоугольник через линии)
function Kefir.paint.CornerOutline(selfRef, x, y, w, h, r, clr, thickness, quality, cornersOnly)
	quality = quality or 4
	if r <= 0 and not cornersOnly then
		surface.SetDrawColor(clr)
		surface.DrawOutlinedRect(x, y, w, h, thickness)
		return
	end
	if not cornersOnly then
		selfRef:Line(x + r, y,     x + w - r, y,     clr, thickness)
		selfRef:Line(x + r, y + h, x + w - r, y + h, clr, thickness)
		selfRef:Line(x,     y + r, x,     y + h - r, clr, thickness)
		selfRef:Line(x + w, y + r, x + w, y + h - r, clr, thickness)
	end
	selfRef:Corner(x + r,     y + r,     r, 180, 270, clr, thickness, quality)
	selfRef:Corner(x + w - r, y + r,     r, 270, 360, clr, thickness, quality)
	selfRef:Corner(x + w - r, y + h - r, r, 0,   90,  clr, thickness, quality)
	selfRef:Corner(x + r,     y + h - r, r, 90,  180, clr, thickness, quality)
end

end -- CLIENT

if CLIENT then

-- ============================================================
-- DRAWLIST — РЕНДЕР UI-ЭЛЕМЕНТОВ В КОЛОНКАХ МЕНЮ
-- ============================================================

-- space (отступ)
Kefir.drawlist.space = function(owner, meta)
	if not Kefir:AllowedFeature(meta.index) then return 0 end
	return meta.data_var[5]
end

-- text (статичный лейбл)
Kefir.drawlist.text = function(owner, meta, parent)
	if not Kefir:AllowedFeature(meta.index) then return 0 end
	local d  = meta.data_var[5]
	local lbl = Kefir.paint:CreateObject("text", parent or owner.menu_scroll)
	lbl:SetPos(meta.object_x, meta.object_y)
	lbl:SetSize(240, 15 + (d[5] or 0))
	lbl.__data = { d[1], d[2], d[3], d[4] }
	return d[2] + 2
end

-- button
Kefir.drawlist.button = function(owner, meta, parent)
	if not Kefir:AllowedFeature(meta.index) then return 0 end
	local d    = meta.data_var[5]
	local text = d[1]; local fs   = d[2]; local rounded = d[3]
	local sz   = d[4]; local clr  = d[5]; local fn  = d[7]; local args = d[10] or {}
	local isOffset = d[9] or false
	local offXY    = d[10] or { 0, 0 }
	local offAbs   = isOffset and offXY or { 0, 0 }

	local btn = Kefir.paint:CreateObject("default_button", parent or owner.menu_scroll)
	btn:SetPos(meta.object_x + offAbs[1], meta.object_y - offAbs[2])
	btn:SetSize(sz[1], sz[2])
	btn:SetText("")
	btn._text         = text
	btn._textsize     = fs
	btn._rounded      = rounded
	btn._maincolor    = clr
	btn._roundedcolor = clr
	btn._sizebtn      = sz

	function btn.DoClick()
		if fn then fn(table.unpack(args)) end
	end

	return isOffset and 0 or sz[2] + 5
end

-- input
Kefir.drawlist.input = function(owner, meta, parent)
	local d      = meta.data_var[5]
	local entry  = vgui.Create("DTextEntry", parent or owner.menu_scroll)
	local ftype  = d[4] or "ofont"
	local maxlen = d[5] or 14

	entry:SetPos(meta.object_x + (d[6] or 0), meta.object_y)
	entry:SetSize(d[1], d[2])
	entry:SetValue(meta.data_var[1])
	entry:SetText(meta.data_var[1])
	entry:SetPlaceholderText(d[3])

	entry.font2    = ftype
	entry.blink    = 0
	entry.blink_change = true
	entry.caretx   = 0
	entry.iMaxLen  = maxlen

	function entry.Paint(self, w, h)
		local caret = self:GetCaretPos()
		local val   = self:GetValue()
		local sub   = string.sub(val, 1, caret)

		-- анимация курсора (blink)
		if self.blink_change then
			if self.blink >= 0.99 then self.blink_change = false end
		elseif self.blink <= 0.01 then
			self.blink_change = true
		end
		self.blink = Lerp(FrameTime() * 9, self.blink, self.blink_change and 1 or 0)

		Kefir.paint:Box(0, 0, w, h, true, Kefir.color.kefir_black, Kefir.color.kefir_red, 1, true)
		Kefir.paint:Text(#val <= 0 and d[3] or val, 14, w / 2, 0,
			Kefir.paint:HColorAlpha(Kefir.color.white, #val <= 0 and 55 or 255), TEXT_ALIGN_CENTER, ftype)

		if self:HasFocus() then
			surface.SetFont(Kefir:GetName() .. "kefir." .. ftype .. ".14")
			local tw, th = surface.GetTextSize(val)
			local sw      = surface.GetTextSize(sub)
			local cx      = w / 2 - tw / 2 + sw
			local cy      = (h - th) / 2
			self.caretx   = Lerp(FrameTime() * 7.7, self.caretx or 0, cx)
			surface.SetDrawColor(Kefir.paint:HColorAlpha(Kefir.color.white, self.blink * 255))
			surface.DrawRect(self.caretx, cy, 2, th)
		end
	end

	function entry.OnTextChanged(self)
		local v  = self:GetValue()
		local ml = self.iMaxLen
		if ml < #v then
			self:SetText(string.sub(v, 1, ml))
			self:SetCaretPos(ml)
		end
		meta.data_var[1] = string.sub(v, 1, ml)
	end

	local customEnv = meta.custom_env
	if isfunction(customEnv) then customEnv(entry) end

	return d[2] + 2
end

end -- CLIENT

if CLIENT then

-- combobox (одиночный выбор)
Kefir.drawlist.combobox = function(owner, meta, parent)
	if not Kefir:AllowedFeature(meta.index) then return 0, nil end
	local d      = meta.data_var
	local opts   = d[5]
	local offset = d[6] or 0
	local noSave = d[7] or false
	if not d[1] then return 0, nil end

	local cb = vgui.Create("DComboBox", parent or owner.menu_scroll)
	cb:SetPos(meta.object_x + offset, meta.object_y)
	cb:SetSize(100, 20)
	cb:SetValue(d[1])
	cb.itemsList = opts
	cb.FAQ_INDEX = meta.index

	function cb.PaintOver(self, w, h)
		Kefir.paint:Box(0, 0, w, h, true, Kefir.color.kefir_black, Kefir.color.kefir_red, 1, true)
		Kefir.paint:Text(Kefir:GetLangText(self:GetValue()), 20, w / 2, 0, Kefir.color.white, TEXT_ALIGN_CENTER, "ofont")
	end
	function cb.OnSelect(self, _, val)
		if not noSave then
			runtimeApi.var[Kefir.tabs.current][meta.group][meta.index][1] = val
		end
		if self.addfn then self:addfn(val) end
	end
	function cb.DoClick(self)
		Kefir.drawlist.derma(self, nil, nil, meta.index)
	end

	-- лейбл справа
	local lbl = Kefir.paint:CreateObject("text", parent or owner.menu_scroll)
	lbl:SetPos(meta.object_x + 105 + offset, meta.object_y)
	lbl:SetSize(240, 20)
	lbl.__data = { d[2], 20, Kefir.color.white, "ofont" }
	cb._istext = lbl
	function cb.OnRemove(self) if IsValid(self._istext) then self._istext:Remove() end end

	return 22, cb
end

-- mcombobox (множественный выбор)
Kefir.drawlist.mcombobox = function(owner, meta, parent)
	if not Kefir:AllowedFeature(meta.index) then return 0, nil end
	local d      = meta.data_var
	local opts   = d[5]
	local offset = d[6] or 0
	if not d[1] then return 0, nil end

	local cb = vgui.Create("DComboBox", parent or owner.menu_scroll)
	cb:SetPos(meta.object_x + offset, meta.object_y)
	cb:SetSize(100, 20)
	cb:SetValue(d[2])
	cb.itemsList = opts
	cb.FAQ_INDEX = meta.index

	function cb.PaintOver(self, w, h)
		local sel    = runtimeApi.var[Kefir.tabs.current][meta.group][meta.index][1]
		local keys   = {}
		for k in pairs(sel) do table.insert(keys, k) end
		local label  = table.concat(keys, ", ")
		surface.SetFont(Kefir:GetName() .. "kefir.ofont.20")
		label = Kefir:trim(label, w)
		Kefir.paint:Box(0, 0, w, h, true, Kefir.color.kefir_black, Kefir.color.kefir_red, 1, true)
		Kefir.paint:Text(label, 18, w / 2, 0, Kefir.color.white, TEXT_ALIGN_CENTER, "ofont")
	end
	function cb.DoClick(self)
		Kefir.drawlist.derma(self, function(choice)
			local tbl = runtimeApi.var[Kefir.tabs.current][meta.group][meta.index][1]
			tbl[choice] = not tbl[choice] or nil
		end, function(choice)
			return runtimeApi.var[Kefir.tabs.current][meta.group][meta.index][1][choice] ~= nil
		end, meta.index)
	end

	local lbl = Kefir.paint:CreateObject("text", parent or owner.menu_scroll)
	lbl:SetPos(meta.object_x + 105 + offset, meta.object_y)
	lbl:SetSize(240, 20)
	lbl.__data = { d[2], 20, Kefir.color.white, "ofont" }
	cb._istext = lbl
	function cb.OnRemove(self) if IsValid(self._istext) then self._istext:Remove() end end

	return 22, cb
end

end -- CLIENT

if CLIENT then

-- slider (полоса с анимацией заполнения)
Kefir.drawlist.slider = function(owner, meta, parent)
	if not Kefir:AllowedFeature(meta.index) then return 0 end
	local d       = meta.data_var[5]
	local offset  = meta.data_var[6] or 0
	local scroll  = parent or owner.menu_scroll
	local extraW  = parent and 90 or 0
	local extraH  = parent and 10 or 0
	local extraLX = parent and 4  or 0

	local sld = Kefir.paint:CreateObject("slider", scroll)
	sld.wdata    = d
	sld.adata    = meta
	sld:SetSize(100 + extraW, 20 + extraH)
	sld:PushVar(meta.group)
	sld:PushVar(meta.index)
	sld:SetPos(meta.object_x - 41.5 + offset, meta.object_y)
	sld:SetMin(d[1])
	sld:SetMax(d[2])
	sld:SetDecimals(d[3])
	sld:SetText("")
	sld:SetValue(runtimeApi.var[meta.current_][meta.group][meta.index][1])
	sld.FAQ_INDEX = meta.index
	sld.col_text  = d[4] or Kefir.color.white
	sld.sub2      = d[5] or ""
	sld.initialize = true
	sld.a3 = 0

	sld.Slider.__owner = sld

	-- анимация полосы заполнения
	function sld.Slider.Paint(self, w, h)
		local val     = runtimeApi.var[meta.current_][self.__owner.adata.index] and
		                runtimeApi.var[meta.current_][self.__owner.adata.group][self.__owner.adata.index][1] or 0
		local rounded = self.__owner.wdata[3] == 0 and math.floor(val) or math.Round(val, 1)
		local frac    = (val - self.__owner.wdata[1]) / (self.__owner.wdata[2] - self.__owner.wdata[1])
		local editing = self:IsEditing()

		self.a3 = Kefir:Lerp(FrameTime() * 4.5, self.a3 or 0, frac)

		Kefir.paint:Box(0, 0, w, h, true, Kefir.color.kefir_black, Kefir.color.kefir_red, 1, true)
		Kefir.paint:Box(3, editing and 4 or 2, (w - 6) * self.a3, h - (editing and 8 or 4), false,
			editing and Kefir.color.groupbox or Kefir.color.kefir_red)

		local label = tostring(rounded)
		if self.__owner.sub2 ~= "" then label = label .. Kefir:GetLangText(self.__owner.sub2); w = w + 4 end
		Kefir.paint:Text(label, 18, w / 2, (h - 18) / 2, Kefir.color.white, TEXT_ALIGN_CENTER, "ofont")
	end

	-- лейбл
	local lbl = Kefir.paint:CreateObject("text", scroll)
	lbl:SetPos(meta.object_x + 65 + offset + extraW, meta.object_y + extraLX)
	lbl:SetSize(240, 15)
	lbl.__data = { meta.data_var[2], 16, d[4] or Kefir.color.white, "ofont" }

	return 25
end

-- keybind
Kefir.drawlist.keybind = function(owner, meta, parent)
	if not Kefir:AllowedFeature(meta.index) then return 0 end
	local d      = meta.data_var
	local btnSz  = { 60, 20 }
	local offset = d[5] or 0
	local dep    = d[6] or {}
	local noShift = d[7]

	local btn = Kefir.paint:CreateObject("default_button", parent or owner.menu_scroll)
	btn:SetPos(meta.object_x + offset * 6.15, meta.object_y - (not noShift and offset or 0))
	btn:SetSize(btnSz[1], btnSz[2])
	btn:SetText("")

	btn.apollon  = { meta.object_x + offset * 6.15, meta.object_y - (not noShift and offset or 0) }
	btn.dep      = dep
	btn._text    = string.upper(input.GetKeyName(d[1]))
	btn._stdtext = btn._text
	btn._textsize     = 16
	btn._rounded      = true
	btn._maincolor    = Kefir.color.kefir_black
	btn._roundedcolor = Kefir.color.kefir_red
	btn._sizebtn      = btnSz
	btn._hotkeyvar    = d[2]
	btn._group        = meta.group
	btn._indx         = meta.index

	function btn.DoClick(self)
		Kefir.hotkey_choosing[1][1] = self._indx
		Kefir.hotkey_choosing[1][2] = owner.tabs.current
		Kefir.hotkey_choosing[1][3] = self._group
	end
	function btn.Think(self)
		local keyName = input.GetKeyName(runtimeApi.var[owner.tabs.current][meta.group][self._indx][1])
		if Kefir.hotkey_choosing[1][1] == self._indx then
			keyName = "PRESS"
			self:SetSize(40, self._sizebtn[2])
		else
			self:SetSize(self._sizebtn[1], self._sizebtn[2])
		end
		self._text = string.upper(keyName)
		if dep and not table.IsEmpty(dep) then
			if runtimeApi.var[dep[1]] and runtimeApi.var[dep[1]][dep[2]] and runtimeApi.var[dep[1]][dep[2]][dep[3]] and runtimeApi.var[dep[1]][dep[2]][dep[3]][1] == dep[4] then
				self:SetPos(table.unpack(self.apollon))
			else
				self:SetPos(131313, 0)
			end
		end
	end

	-- лейбл
	local lbl = Kefir.paint:CreateObject("text", parent or owner.menu_scroll)
	lbl:SetPos(meta.object_x + offset * 6.15 + btnSz[1] + 3, meta.object_y - (not noShift and offset or 0))
	lbl:SetSize(240, 20)
	lbl.dep   = dep
	lbl.indx  = meta.index
	lbl.apollon = { meta.object_x + offset * 6.15 + btnSz[1] + 3, meta.object_y - (not noShift and offset or 0) }
	function lbl.Think(self)
		self.__data = { d[2], 20, Kefir.color.white, "ofont" }
		if dep and not table.IsEmpty(dep) then
			if runtimeApi.var[dep[1]] and runtimeApi.var[dep[1]][dep[2]] and runtimeApi.var[dep[1]][dep[2]][dep[3]] and runtimeApi.var[dep[1]][dep[2]][dep[3]][1] == dep[4] then
				self:SetPos(table.unpack(self.apollon))
			else
				self:SetPos(131313, 0)
			end
		end
	end

	return btnSz[2] + 5
end

end -- CLIENT

if CLIENT then

-- checkbox внутри drawlist (обёртка над RegisterTable)
Kefir.drawlist.checkbox = function(owner, meta, parent)
	if not Kefir:AllowedFeature(meta.index) then return 0 end
	local d      = meta.data_var
	local scroll = parent or owner.menu_scroll
	local widget = istable(d[5]) and d[5] or {}

	surface.SetFont(Kefir:GetName() .. "kefir.ofont.20")
	local tw = surface.GetTextSize(Kefir:GetLangText(d[2]))
	local hotkeyVar = d[7]

	local cb = Kefir.paint:CreateObject("checkbox", scroll)
	cb:SetPos(meta.object_x, meta.object_y)
	cb:SetSize(hotkeyVar ~= nil and 190 or 235, 15)
	cb._glow        = 0
	cb.adata        = meta
	cb.__var        = meta.index
	cb.__tab        = meta.current_
	cb.__group      = meta.group
	cb.__cachetext  = d[2]
	cb.__widget     = widget
	cb.__hoveredtext = widget[3] or ""
	cb.FAQ_INDEX    = meta.index
	function cb.DoRightClick() end

	-- цветовые пикеры
	local colors = d[6]
	if colors and istable(colors) and not table.IsEmpty(colors) then
		local cx = meta.object_x + (widget[1] or 0) + tw + 26
		for i, clr in ipairs(colors) do
			local sel = Kefir.paint:CreateObject("color_selector", scroll)
			sel:SetPos(cx, meta.object_y)
			sel:SetSize(15, 15)
			sel:PushVar(meta.group)
			sel:PushVar(meta.index)
			sel:PushVar(i)
			sel:SetVar(clr)
			cx = cx + 19
		end
	end

	-- кнопка кейбинда
	if hotkeyVar and hotkeyVar ~= "" then
		local kbtn = vgui.Create("DButton", scroll)
		kbtn:SetPos(meta.object_x + 192, meta.object_y)
		kbtn:SetSize(50, 15)
		kbtn:SetText("")
		kbtn:SetCursor("arrow")
		kbtn.FAQ_INDEX = "X_keybind_button_X"
		kbtn.var1 = { hotkeyVar, meta.group }
		kbtn.itemsList = { "Always On", "Toggle", "Hold", "Unhold", "On Shot" }

		function kbtn.Paint(self)
			local s  = runtimeApi.var[Kefir.tabs.current][self.var1[2]][self.var1[1]]
			local km = s and string.upper(input.GetKeyName(s[1])) or "?"
			local mode = s and s[8] or ""
			if mode == "On Shot" then km = Kefir:GetLangText("OS") end
			Kefir.paint:EOText(string.format("[%s]",
				Kefir.hotkey_choosing[1][1] == self.var1[1] and "..." or km),
				10, 0, 6,
				self:IsHovered() and Kefir.color.keybindhov or Kefir.color.keybind,
				TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, "visuals")
		end
		function kbtn.DoClick(self)
			Kefir.hotkey_choosing[1][1] = self.var1[1]
			Kefir.hotkey_choosing[1][2] = Kefir.tabs.current
			Kefir.hotkey_choosing[1][3] = self.var1[2]
		end
		function kbtn.DoRightClick(self)
			Kefir.drawlist.derma(self, function(choice)
				runtimeApi.var[Kefir.tabs.current][self.var1[2]][self.var1[1]][8] = choice
			end, function(choice)
				return choice == runtimeApi.var[Kefir.tabs.current][self.var1[2]][self.var1[1]][8]
			end, "")
		end
	end

	return 20
end

end -- CLIENT

if CLIENT then

-- ============================================================
-- DERMA-МЕНЮ (контекстный список вариантов с анимацией)
-- ============================================================
Kefir.drawlist.derma = function(panelRef, onSelect, checkFn, faqIndex)
	if Kefir.drawlist.derma_opened then
		CloseDermaMenus()
		return
	end

	local menu  = DermaMenu(false, panelRef)
	local items = panelRef.itemsList

	menu:SetDrawBorder(false)
	menu:SetDrawOnTop(false)
	menu.Paint     = nil
	menu.PaintOver = nil

	for _, choice in ipairs(items) do
		local opt = menu:AddOption(_, function()
			if IsValid(panelRef) then
				if isfunction(onSelect) then onSelect(choice)
				else panelRef:ChooseOption(choice) end
			end
		end)
		opt:SetText("")
		opt._choice    = choice
		opt.FAQ_INDEX  = (faqIndex or "") .. "_" .. choice

		function opt.PaintOver(self, w, h)
			Kefir.paint:Box(2, 2, w - 3, h - 3, false, Kefir.color.kefir_black)

			self._alpha  = Kefir:Lerp(FrameTime() * 6,  self._alpha  or 0,   self:IsHovered() and 255 or 0)
			self._alpha1 = Kefir:Lerp(FrameTime() * 20, self._alpha1 or 0,   255)

			local a  = self._alpha
			local bk = Kefir.paint:HColorAlpha(Kefir.color.kefir_black, a)
			local rd = Kefir.paint:HColorAlpha(Kefir.color.kefir_red,   a)

			Kefir.paint:Box(0, 0, w, h, true, bk, rd, 1, true)

			local label = Kefir:GetLangText(self._choice)
			local font  = Kefir:RussianSymbols(label) and "chat" or "ofont"
			Kefir.paint:Text(label, 16, w / 2, 4, Kefir.paint:HColorAlpha(Kefir.color.white, self._alpha1), TEXT_ALIGN_CENTER, font)

			if isfunction(checkFn) and checkFn(self._choice) then
				Kefir.paint:Text("✓", 12, 4, (h - 12) / 2, Kefir.paint:HColorAlpha(Kefir.color.white, self._alpha1), TEXT_ALIGN_LEFT, "icons")
			end
		end
	end

	local ox, oy = panelRef:LocalToScreen(0, panelRef:GetTall())
	menu:Open(ox, oy, false, panelRef)

	function menu.OnRemove()
		Kefir.drawlist.derma_opened = false
	end
	function menu.Paint(self, w, h)
		Kefir.paint:Box(0, 0, w, h, true, Kefir.color.kefir_black, Kefir.color.kefir_red, 1, true)
	end

	Kefir.drawlist.derma_opened  = true
	Kefir.drawlist.dermacurrent  = menu
	menu:SetPaintedManually(not nativeApi.standalone_vgui)

	return menu
end

-- list (список конфигов)
Kefir.drawlist.list = function(owner, meta, parent)
	local items   = meta.data_var[5][3]
	local colName = Kefir:GetLangText("Config Name")
	Kefir.configlist = vgui.Create("DListView", parent or owner.menu_scroll)
	Kefir.configlist:SetSize(238, 200)
	Kefir.configlist:SetPos(meta.object_x, meta.object_y)
	Kefir.configlist:SetMultiSelect(false)
	Kefir.configlist:AddColumn(colName)

	-- кастомный рендер строк
	Kefir.configlist.origAddLine = Kefir.configlist.AddLine
	function Kefir.configlist.AddLine(self, ...)
		local line   = self:origAddLine(...)
		local name   = ({ ... })[1]
		local clean  = string.gsub(name, "%.cvip$", "")
		line.Columns[1]:SetText("")
		line.txt2 = clean
		function line.Paint() end
		function line.PaintOver(self2, w, h)
			local selClr = self2:IsSelected() and Kefir.color.groupname  or Kefir.color.kefir_red
			local bkClr  = self2:IsSelected() and Kefir.color.picker_clr or Kefir.color.kefir_black
			local txtClr = self2:IsSelected() and Kefir.color.selectedline or Kefir.color.white
			Kefir.paint:Box(0, 0, w, h, true, bkClr, selClr, 1, true)
			Kefir.paint:EOText(clean, 18, w / 2, 10, txtClr, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, "ofont", 255)
		end
		return line
	end
	function Kefir.configlist.Paint(self, w, h)
		Kefir.paint:Box(0, 0, w, h, true, Kefir.color.kefir_black, Kefir.color.kefir_red, 1, true)
	end
	function Kefir.configlist.Think(self)
		local sel  = self:GetSelectedLine()
		local line = sel and self:GetLine(sel)
		meta.data_var[1] = line and line.txt2 or nil
	end

	for _, v in ipairs(items) do Kefir.configlist:AddLine(v) end

	-- стиль скроллбара
	local vb = Kefir.configlist.VBar
	vb:SetSize(12, 15)
	function vb.Paint(self, w, h)
		Kefir.paint:rectBox(w, h, 0, 0, color_black)
		Kefir.paint:rectBox(w - 2, h - 2, 1, 1, Kefir.color.groupname)
		Kefir.paint:rectBox(w - 4, h - 4, 2, 2, Kefir.color.kefir_black)
	end
	function vb.btnGrip.Paint(self, w, h)
		local c = self:IsHovered() and Kefir.color.kefir_red or Kefir.color.groupbox
		Kefir.paint:rectBox(w - 8, h, 4, 0, c)
		Kefir.paint:rectBox(w - 10, h - 2, 5, 1, color_black)
	end
	function vb.btnUp.Paint()   end
	function vb.btnDown.Paint() end

	return 205
end

end -- CLIENT

if CLIENT then

-- ============================================================
-- РЕНДЕР МЕНЮ (RenderMenu) — ручная отрисовка панелей
-- ============================================================
function Kefir.RenderMenu(selfRef)
	if nativeApi.standalone_vgui then
		selfRef:DrawHovered()
		return
	end

	if IsValid(selfRef.tab_frame) then
		selfRef.tab_frame:PaintManual()
	end

	if IsValid(selfRef.menu) then
		local mx, my = selfRef.menu:GetPos()
		local mw, mh = selfRef.menu:GetSize()
		local bx, by, bw, bh = mx - 1, my - 2, mw + 2, mh + 4

		surface.SetDrawColor(Kefir.paint:HColorAlpha(Kefir.color.groupname, 50))
		surface.DrawRect(bx, by, bw, bh)
		Kefir.paint:SBlur(bx, by, bw, bh, 3, 6, 5)
		selfRef.menu:PaintManual()
	end

	if IsValid(selfRef.hitboxaim)  then selfRef.hitboxaim:PaintManual()  end
	if IsValid(selfRef.filteresp)  then selfRef.filteresp:PaintManual()  end
	if IsValid(selfRef.previewesp) then selfRef.previewesp:PaintManual() end

	if IsValid(selfRef.drawlist and selfRef.drawlist.dermacurrent) then
		selfRef.drawlist.dermacurrent:PaintManual()
	end
	if IsValid(selfRef.cpickl) then selfRef.cpickl:PaintManual() end

	selfRef:DrawHovered()
end

-- ============================================================
-- ОТКРЫТИЕ/ЗАКРЫТИЕ МЕНЮ ПО КНОПКЕ (Menu)
-- ============================================================
local menuDrag   = false
local menuOffset = Vector(0, 0, 0)

function Kefir.Menu(selfRef)
	-- хоткей открытия меню
	if input.IsButtonDown(runtimeApi.var.MISC and runtimeApi.var.MISC[1] and runtimeApi.var.MISC[1].menu_hotkey and runtimeApi.var.MISC[1].menu_hotkey[1] or KEY_PAGEUP) and Kefir.imenu then
		selfRef.paint:ToggleMenu()
		Kefir.imenu = false
		timer.Simple(0.2, function() Kefir.imenu = true end)
	end

	-- перетаскивание меню мышью за шапку
	if IsValid(selfRef.menu) and selfRef.menu:IsVisible() and not menuDrag and not (Kefir.drag_states and Kefir.drag_states.keybinds and Kefir.drag_states.keybinds.dragging) then
		local mx, my   = gui.MousePos()
		local px, py   = selfRef.menu:GetPos()

		if input.IsMouseDown(MOUSE_LEFT) then
			if not menuDrag then
				if Kefir.paint:IsHovered(px, py, 800, 80) and selfRef.menu:HasFocus() then
					menuDrag = true
					menuOffset = Vector(mx - px, my - py, 0)
				end
			else
				selfRef.menu:SetPos(mx - menuOffset.x, my - menuOffset.y)
			end
		else
			menuDrag = false
		end
	elseif not input.IsMouseDown(MOUSE_LEFT) then
		menuDrag = false
	end
end

end -- CLIENT

if CLIENT then

-- ============================================================
-- DrawHovered — подсказка FAQ при наведении на элемент
-- ============================================================
function Kefir.DrawHovered(selfRef)
	local hov = vgui.GetHoveredPanel()
	if not hov or not hov.__hoveredtext then return end

	local text = selfRef:GetLangText(hov.__hoveredtext)
	if text == "" then return end

	surface.SetFont(Kefir:GetName() .. "kefir.visuals.16")
	local tw, th = surface.GetTextSize(text)
	local bw = tw + 14
	local bh = th + 4
	local mx, my = gui.MousePos()
	local by = my - 32

	Kefir.paint:rectBox(bw, bh, mx, by,           Kefir.color.kefir_black)
	Kefir.paint:rectBox(bw - 2, bh - 2, mx + 1, by + 1, Kefir.color.groupname)
	Kefir.paint:rectBox(bw - 4, bh - 4, mx + 2, by + 2, Kefir.color.kefir_black)
	Kefir.paint:EOText(text, 16, mx + 6, th * 0.5 + by, Kefir.color.white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, "visuals")
end

-- ============================================================
-- DrawServerMismatch — уведомление об обрыве соединения
-- ============================================================
local notifyY   = -100
local notifyW   = 200

function Kefir.DrawServerMismatch(selfRef)
	if notifyY <= -97 and (not rawget(Kefir, "problem_server") or Kefir.problem_server <= 0) then return end

	local bx = (ScrW() - notifyW) / 2
	local shake = math.Round(math.sin(CurTime() * 5) * 1.5)

	local bx2, by2 = bx - 1 - shake, notifyY - 2 - shake
	local bw2, bh2 = notifyW + 2 + shake * 2, 29 + shake * 2

	surface.SetDrawColor(Kefir.paint:HColorAlpha(Kefir.color.groupname, 255))
	surface.DrawRect(bx2, by2, bw2, bh2)
	Kefir.paint:SBlur(bx2, by2, bw2, bh2, 3, 5, 7)

	-- анимация выезда
	notifyY = Kefir:Lerp(FrameTime() * 3, notifyY or 0,
		(Kefir.problem_server or 0) <= 0 and -100 or 5)

	Kefir.paint:rectBox(notifyW, 25, bx, notifyY, Kefir.color.kefir_black)
	Kefir.paint:rectBox(notifyW - 2, 25 - 2, bx + 1, notifyY + 1, Kefir.color.groupname)
	Kefir.paint:rectBox(notifyW - 4, 25 - 4, bx + 2, notifyY + 2, Kefir.color.kefir_black)

	notifyW = Kefir.paint:EOText(
		string.format(selfRef:GetLangText("Connection to the mayrr.zip server was lost, after connection attempts expire the cheat will be unloaded! (%d/10)"),
			Kefir.problem_server or 0),
		16, bx + 6, notifyY + 10, Kefir.color.white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, "visuals") + 12
end

-- ============================================================
-- DrawLogs — плавно исчезающие уведомления
-- ============================================================
function Kefir.DrawLogs(selfRef)
	if not Kefir.logs or table.IsEmpty(Kefir.logs) then return end

	local yOff = 2
	local now  = CurTime()

	for i = #Kefir.logs, 1, -1 do
		local entry = Kefir.logs[i]
		if not entry or not entry[1] then break end

		local text, clr, expTime, lifetime, alpha, logX, logW, logH =
			entry[1], entry[2], entry[3], entry[4], entry[5], entry[6], entry[7], entry[8]

		-- анимация исчезновения
		if expTime ~= nil then
			if now - expTime > 0 then
				entry[6] = Kefir:Lerp(FrameTime() * 3, logX, -logW)
				entry[5] = Kefir:Lerp(FrameTime() * 2, alpha, 0)
				if logX < -(logW - 1) then table.remove(Kefir.logs, i) end
			end
		else
			entry[6] = Kefir:Lerp(FrameTime() * 5, logX, 0)
			if logX > -1 then entry[3] = now + lifetime end
		end

		local bw = logW + 14
		local bh = logH + 4
		local bx = logX + 4
		local ay = logH + 4

		local cA  = Kefir.paint:HColorAlpha(clr, alpha)
		local cBk = Kefir.paint:HColorAlpha(color_black, alpha)
		local cGn = Kefir.paint:HColorAlpha(Kefir.color.groupname, alpha)
		local cKb = Kefir.paint:HColorAlpha(Kefir.color.kefir_black, alpha)

		Kefir.paint:rectBox(bw, ay, bx, yOff, cBk)
		Kefir.paint:rectBox(bw - 2, ay - 2, bx + 1, yOff + 1, cGn)
		Kefir.paint:rectBox(bw - 4, ay - 4, bx + 2, yOff + 2, cKb)
		Kefir.paint:EOText(text, 16, bx + 6, logH * 0.5 + yOff, cA, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, "visuals", alpha)

		yOff = yOff + (ay + 4)
	end
end

end -- CLIENT

if CLIENT then

-- ============================================================
-- Watermark с анимацией
-- ============================================================
function Kefir.DrawWatermark(selfRef)
	if not runtimeApi.var.MISC then return end
	local s = runtimeApi.var.MISC[1]
	if not s or not s.watermark or not s.watermark[1] then return end

	local fps     = Kefir.realfps or 0
	local label   = string.format(Kefir:GetLangText("mayrr | %d commit | %d fps | %d ms. |"),
		Kefir.BUILD_NUMBER or 0, fps, IsValid(localPlayer) and localPlayer:Ping() or 0)
	local bw      = 200
	local bx      = (ScrW() - bw) / 2
	local by      = ScrH() * 0.002

	surface.SetFont(Kefir:GetName() .. "kefir.font.18")
	local tw, th = surface.GetTextSize(label)
	local boxW   = tw + 20
	local boxH   = th + 5

	Kefir.paint:rectBox(boxW, boxH, bx, by, color_black)
	Kefir.paint:rectBox(boxW - 2, boxH - 2, bx + 1, by + 1, Kefir.color.groupname)
	Kefir.paint:rectBox(boxW - 4, boxH - 4, bx + 2, by + 2, Kefir.color.kefir_black)
	Kefir.paint:EOText(label, 18, bx + 8, by + boxH / 2, Kefir.color.white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 0.1, "font")
end

-- ============================================================
-- Keybinds-оверлей с анимацией активных биндов
-- ============================================================
function Kefir.DrawKeybinds(selfRef)
	if not runtimeApi.var.MISC then return end
	local s = runtimeApi.var.MISC[1]
	if not s or not s.keybinds or not s.keybinds[1] then return end

	local pos   = Kefir.keybindpos
	local x, y  = pos.x, pos.y
	local title = Kefir:GetLangText("Keybinds")

	surface.SetFont(Kefir:GetName() .. "kefir.ofont.20")
	local tw = surface.GetTextSize(title)
	local maxW = tw + 40
	local rows  = {}

	surface.SetFont(Kefir:GetName() .. "kefir.ofont.16")

	for name, st in pairs(Kefir.keystates) do
		if CurTime() - st.time < 0.1 and st.active then
			local rw = surface.GetTextSize(name)
			if maxW < rw + 20 then maxW = rw + 20 end
			table.insert(rows, { name = name, h = select(2, surface.GetTextSize(name)) })
		end
	end

	-- Fakelag строка
	if Kefir.fl_ticks and Kefir.fl_ticks > 0 then
		local lbl = Kefir:GetLangText("Fakelag ") .. tostring(Kefir.fl_ticks)
		local rw, rh = surface.GetTextSize(lbl)
		if maxW < rw + 20 then maxW = rw + 20 end
		table.insert(rows, { name = lbl, h = rh })
	end

	local headerH = 25
	local totalH  = headerH + (#rows > 0 and #rows * 19 or 0)

	local bx2, by2 = x - 1, y - 2
	local bw2, bh2 = maxW + 2, totalH + 4
	surface.SetDrawColor(Kefir.paint:HColorAlpha(Kefir.color.groupname, 245))
	surface.DrawRect(bx2, by2, bw2, bh2)
	Kefir.paint:SBlur(bx2, by2, bw2, bh2, 3, 5, 7)

	Kefir.paint:rectBox(maxW, totalH, x, y, color_black)
	Kefir.paint:rectBox(maxW - 2, totalH - 2, x + 1, y + 1, Kefir.color.groupname)
	Kefir.paint:rectBox(maxW - 4, totalH - 4, x + 2, y + 2, Kefir.color.kefir_black)
	Kefir.paint:EOText(title, 20, x + maxW / 2, y + headerH / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 0.1, "ofont")

	local rowY = y + headerH + 2
	for _, row in ipairs(rows) do
		Kefir.paint:EOText(row.name, 16, x + 8, rowY + 6.5, row.color or color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 0.01, "ofont")
		rowY = rowY + 19
	end

	-- перетаскивание
	Kefir:SystemDragging(Kefir.keybindpos, "keybinds", maxW, totalH)
end

end -- CLIENT

if CLIENT then

-- ============================================================
-- HColorAlpha — кэшированное создание Color с заданной альфой
-- ============================================================
local _borFn    = bit.bor
local _lshiftFn = bit.lshift
local _floorFn  = math.floor

Kefir.paint.cache_alpha = Kefir.paint.cache_alpha or {}

function Kefir.paint.HColorAlpha(selfRef, clr, alpha)
	local r, g, b = clr.r, clr.g, clr.b
	alpha = alpha or 255
	if alpha ~= alpha or alpha < 0 then alpha = 0
	elseif alpha > 255 then alpha = 255 end
	alpha = _floorFn(alpha)

	local key = _borFn(_lshiftFn(r, 24), _lshiftFn(g, 16), _lshiftFn(b, 8), alpha)
	local cached = selfRef.cache_alpha[key]
	if cached then return cached end

	local c = Color(r, g, b, alpha)
	selfRef.cache_alpha[key] = c
	return c
end

-- ============================================================
-- Box — прямоугольник с опциональной обводкой
-- ============================================================
function Kefir.paint.Box(selfRef, x, y, w, h, outlined, fillClr, outlineClr, thickness, invert)
	thickness = thickness or 1
	if not invert then
		if outlined then
			surface.SetDrawColor(outlineClr or color_black)
			surface.DrawRect(x - thickness, y - thickness, w + thickness * 2, h + thickness * 2)
		end
		surface.SetDrawColor(fillClr or color_white)
		surface.DrawRect(x, y, w, h)
	else
		if outlined then
			surface.SetDrawColor(outlineClr or color_black)
			surface.DrawRect(x, y, w, h)
		end
		surface.SetDrawColor(fillClr or color_white)
		surface.DrawRect(x + thickness, y + thickness, w - thickness * 2, h - thickness * 2)
	end
end

-- rectBox — упрощённый прямоугольник (размер, позиция, цвет)
function Kefir.paint.rectBox(selfRef, w, h, x, y, clr)
	clr = clr or color_white
	x   = x or 0
	y   = y or 0
	surface.SetDrawColor(clr)
	surface.DrawRect(x, y, w, h)
end

-- Line
function Kefir.paint.Line(selfRef, x1, y1, x2, y2, clr, thickness)
	surface.SetDrawColor(clr or color_white)
	surface.DrawLine(x1, y1, x2, y2)
end

-- LineOutlined — линия с тёмной обводкой
function Kefir.paint.LineOutlined(selfRef, x1, y1, x2, y2, clr, thickness, outlineClr)
	local pad = thickness or 1
	outlineClr = outlineClr or Kefir.color.kefir_black
	surface.SetDrawColor(outlineClr)
	surface.DrawLine(x1 - pad, y1,      x2 - pad, y2)
	surface.DrawLine(x1 + pad, y1,      x2 + pad, y2)
	surface.DrawLine(x1,       y1 - pad, x2,      y2 - pad)
	surface.DrawLine(x1,       y1 + pad, x2,      y2 + pad)
	surface.SetDrawColor(clr or color_white)
	surface.DrawLine(x1, y1, x2, y2)
end

-- OutlinedRect
function Kefir.paint.OutlinedRect(selfRef, x, y, w, h, clr, thickness)
	surface.SetDrawColor(clr)
	surface.DrawOutlinedRect(x, y, w, h, thickness or 1)
end

-- Circle (filled)
function Kefir.paint.Circle(selfRef, cx, cy, r, segments, clr)
	local poly = {}
	for i = 0, segments do
		local ang = math.rad(i / segments * -360)
		poly[#poly + 1] = {
			x = cx + math.sin(ang) * r,
			y = cy + math.cos(ang) * r
		}
	end
	surface.SetDrawColor(clr or color_white)
	draw.NoTexture()
	surface.DrawPoly(poly)
end

-- vCircle (surface.DrawCircle wrapper)
function Kefir.paint.vCircle(selfRef, cx, cy, r, clr)
	surface.SetDrawColor(clr or color_white)
	surface.DrawCircle(cx, cy, r, clr or color_white)
end

end -- CLIENT
