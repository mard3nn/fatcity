--made by mrrp :3

local maxLength = GetConVar("zchat_maxmessagelength")

local NoDrop = CreateClientConVar("zchat_dropcharacters", 1, true, false, "Play the character dropping animation when erasing text", 0, 1)
local ShowTextBoxInactive = CreateClientConVar("zchat_showtextboxinactive", 1, true, false, "Showing your text in textbox while chat is turned off", 0, 1)

local function CallbackBind(self, callback)
	return function(_, ...)
		return callback(self, ...)
	end
end

local function PaintMarkupOverride(text, font, x, y, color, alignX, alignY, alpha)
	alpha = alpha or 255

	// задник
	surface.SetTextPos(x + 1, y + 1)
	surface.SetTextColor(0, 0, 0, alpha)
	surface.SetFont(font)
	surface.DrawText(text)

	surface.SetTextPos(x, y)
	surface.SetTextColor(color.r, color.g, color.b, alpha)
	surface.SetFont(font)
	surface.DrawText(text)
end

local MATRIX_CHARS = "#$%*+=?!;:^~/[]{}|01"

local function MatrixRandomChar()
	local i = math.random(#MATRIX_CHARS)
	return MATRIX_CHARS:sub(i, i)
end

local function DecodeEntities(s)
	return s:gsub("&lt;", "<"):gsub("&gt;", ">"):gsub("&amp;", "&")
end

local function SplitSegments(buffer)
	local segs = {}
	local col = Color(255, 255, 255)
	local buf = {}

	local function Flush()
		if #buf > 0 then
			segs[#segs + 1] = {color = col, text = table.concat(buf)}
			buf = {}
		end
	end

	local pos = 1
	while pos <= #buffer do
		local s, e = buffer:find("<[^>]*>", pos)
		local chunkEnd = (s or #buffer + 1) - 1
		if chunkEnd >= pos then buf[#buf + 1] = buffer:sub(pos, chunkEnd) end
		if not s then break end

		Flush()

		local rr, gg, bb = buffer:sub(s, e):match("^<color=(%d+),(%d+),(%d+)>$")
		if rr then col = Color(tonumber(rr), tonumber(gg), tonumber(bb)) end
		pos = e + 1
	end
	Flush()

	for _, seg in ipairs(segs) do
		seg.text = DecodeEntities(seg.text)
		seg.chars = {}

		if utf8 then
			for _, cp in utf8.codes(seg.text) do
				seg.chars[#seg.chars + 1] = cp
			end
		else
			for i = 1, #seg.text do
				seg.chars[#seg.chars + 1] = seg.text:byte(i)
			end
		end
	end

	return segs
end

local PANEL = {}

function PANEL:Init()
	self.text = ""
	self.alpha = 0
	self.fadeDelay = 15
	self.fadeDuration = 5
	self.yAnimDuration = 1

	self.yAnim = 5
end

function PANEL:SetupMatrix(segs)
	self.matrix = {
		segs = segs,
		total = 0,
		born = CurTime()
	}

	if self.matrixPrefixText then
		for _, seg in ipairs(segs) do
			if seg.text == self.matrixPrefixText then
				seg.gated = true
				break
			end
		end
	end

	for _, seg in ipairs(segs) do
		self.matrix.total = self.matrix.total + #seg.chars
	end

	surface.SetFont("zChatFont")
	local _, th = surface.GetTextSize("Ag")
	self:SetTall(math.max(th, 10))

	self:CreateAnimation(self.yAnimDuration, {
		index = 4,
		target = {yAnim = 0},
		easing = "outQuint"
	})

	self:CreateAnimation(0.5, {
		index = 3,
		target = {alpha = 255},
	})

	timer.Simple(self.fadeDelay, function()
		if (!IsValid(self)) then
			return
		end

		self:CreateAnimation(self.fadeDuration, {
			index = 3,
			target = {alpha = 0}
		})
	end)
end

local MATRIX_DECODE_TIME = 1.2
local MATRIX_GONE_TIME = 0.5

function PANEL:GetMatrixFraction()
	local now = CurTime()

	if now < self.fadeDelay then
		return math.Clamp((now - self.matrix.born) / MATRIX_DECODE_TIME, 0, 1)
	end

	return 1 - math.Clamp((now - self.fadeDelay) / MATRIX_GONE_TIME, 0, 1)
end

function PANEL:MatrixPaint()
	local newAlpha

	if (hg.chat:GetActive()) then
		newAlpha = math.max(hg.chat.alpha, self.alpha)
	else
		newAlpha = self.alpha - (255 - hg.chat.realAlpha)
	end

	surface.SetAlphaMultiplier(math.Clamp(newAlpha, 0, 255) / 255)

	local frac = self:GetMatrixFraction()

	DisableClipping(true)
		local chatboxX, chatboxY = hg.chat:GetPos()
		local wide, tall = hg.chat:GetSize()

		render.SetScissorRect(chatboxX, chatboxY, chatboxX + wide, chatboxY + tall, true)
			surface.SetFont("zChatFont")
			local x, y = 0, self.yAnim

			for _, seg in ipairs(self.matrix.segs) do
				local gate = seg.gated and math.floor(#seg.chars * frac + 0.5) or #seg.chars + 1000
				local localIdx = 0

				for _, cp in ipairs(seg.chars) do
					localIdx = localIdx + 1

					local origCh = utf8.char(cp)
					local tw = surface.GetTextSize(origCh)

					local ch
					local r, g, b

					if cp == 32 then
						ch = " "
					elseif localIdx <= gate then
						ch = origCh
						r, g, b = seg.color.r, seg.color.g, seg.color.b
					else
						ch = MatrixRandomChar()
						r, g, b = math.random(40, 120), math.random(160, 255), math.random(40, 120)
					end

					if ch ~= " " then
						surface.SetTextPos(x + 1, y + 1)
						surface.SetTextColor(0, 0, 0, 255)
						surface.DrawText(ch)

						surface.SetTextPos(x, y)
						surface.SetTextColor(r, g, b, 255)
						surface.DrawText(ch)
					end

					x = x + tw
				end
			end
		render.SetScissorRect(0, 0, 0, 0, false)
	DisableClipping(false)

	surface.SetAlphaMultiplier(1)
end

function PANEL:SetMarkup(text)
	self.text = text

	if self.isMatrix then
		self:SetupMatrix(SplitSegments(text))
		return
	end

	self.markup = hg.markup.Parse(self.text, self:GetWide())
	self.markup.onDrawText = PaintMarkupOverride

	self:SetTall(self.markup:GetHeight())

	timer.Simple(self.fadeDelay, function()
		if (!IsValid(self)) then
			return
		end

		self:CreateAnimation(self.fadeDuration, {
			index = 3,
			target = {alpha = 0}
		})
	end)

	self:CreateAnimation(self.yAnimDuration, {
		index = 4,
		target = {yAnim = 0},
		easing = "outQuint"
	})

	self:CreateAnimation(0.5, {
		index = 3,
		target = {alpha = 255},
	})
end

function PANEL:PerformLayout(width, height)
	if self.matrix then
		surface.SetFont("zChatFont")
		self:SetTall(select(2, surface.GetTextSize("Ag")))
		return
	end

	self.markup = hg.markup.Parse(self.text, width)
	self.markup.onDrawText = PaintMarkupOverride

	self:SetTall(self.markup:GetHeight())
end

function PANEL:Paint(width, height)
	if self.matrix then
		self:MatrixPaint()
		return
	end

	local newAlpha

	if (hg.chat:GetActive()) then
		newAlpha = math.max(hg.chat.alpha, self.alpha)
	else
		newAlpha = self.alpha - (255 - hg.chat.realAlpha)
	end

	DisableClipping(true)
		local chatboxX, chatboxY = hg.chat:GetPos()
		local wide, tall = hg.chat:GetSize()

		render.SetScissorRect(chatboxX, chatboxY, chatboxX + wide, chatboxY + tall, true)
			self.markup:draw(0, self.yAnim, nil, nil, newAlpha)
		render.SetScissorRect(0, 0, 0, 0, false)
	DisableClipping(false)
end

vgui.Register("zChatMessage", PANEL, "Panel")

PANEL = {}

DEFINE_BASECLASS("DTextEntry")

function PANEL:Init()
	self:SetFont("zChatFont")
	self:SetUpdateOnType(true)
	self:SetHistoryEnabled(true)

	self.History = hg.chat.messageHistory
	self.droppedCharacters = {}

	self.prevText = ""

	self:SetTextColor(color_white)

	self:SetPaintBackground(false)

	self.m_bLoseFocusOnClickAway = false
end

function PANEL:AllowInput(newCharacter)
	local text = self:GetText()
	local maxLen = maxLength:GetInt()

	// Мы не можем проверить корректность длины при использовании UTF-8, так как метод AllowInput вызывается для отдельных байтов, а не для полных символов.
	if (string.len(text .. newCharacter) > maxLen) then
		surface.PlaySound("common/talk.wav")
		return true
	end
end

function PANEL:Think()
	local text = self:GetText()
	local maxLen = maxLength:GetInt()

	if (text:utf8len() > maxLen) then
		local newText = text:utf8sub(0, maxLen)

		self:SetText(newText)
		self:SetCaretPos(newText:utf8len())
	end
end

local gradient_l = Material("vgui/gradient-l")

function PANEL:Paint(w, h)
	surface.SetDrawColor(40, 40, 40, 180) // color for gui chata
	surface.DrawRect(0, 0, w, h)

	for k, v in ipairs(self.droppedCharacters) do
		local text = v.text

		v.velocityY = v.velocityY + (5 * FrameTime())
		v.y = v.y + v.velocityY

		v.x = v.x + v.velocityX

		v.alpha = v.alpha - FrameTime() * 750

		DisableClipping(true)
			surface.SetTextColor(150, 150, 150, v.alpha)
			surface.SetTextPos(v.x, v.y)
			surface.SetFont("zChatFont")
			surface.DrawText(text)
		DisableClipping(false)

		if v.alpha <= 0 then
			table.remove(self.droppedCharacters, k)
		end
	end

	if ShowTextBoxInactive:GetBool() and !hg.chat:GetActive() and self.prevText != "" then
		DisableClipping(true)
		surface.SetAlphaMultiplier(1)
			surface.SetTextColor(150, 150, 150, 55)
			surface.SetTextPos(0, 0)
			surface.SetFont("zChatFont")
			surface.DrawText(self.prevText)
		surface.SetAlphaMultiplier(0)
		DisableClipping(false)
	end

	BaseClass.Paint(self, w, h)
end

function PANEL:OnValueChange(text)
	local prevText = self.prevText

	if NoDrop:GetBool() then
		local len1, len2 = string.utf8len(prevText), string.utf8len(text)

		if len1 > len2 then
			local droppedText = string.utf8sub(prevText, self:GetCaretPos() + 1, self:GetCaretPos() + (len1 - len2))

			local droppedChars = string.Explode(utf8.charpattern, droppedText)
			for k, v in ipairs(droppedChars) do
				local data = {}
				data.text = v

				surface.SetFont("zChatFont")
				local tw2 = surface.GetTextSize(v)

				data.x = tw2 * (self:GetCaretPos())

				data.y = 8

				data.velocityX = math.Rand(-0.1, 0.1)
				data.velocityY = -1

				data.alpha = 255

				table.insert(self.droppedCharacters, data)
			end
		end
	end

	self.prevText = text
end

vgui.Register("zChatboxEntry", PANEL, "DTextEntry")

PANEL = {}

AccessorFunc(PANEL, "bActive", "Active", FORCE_BOOL)
AccessorFunc(PANEL, "realAlpha", "RealAlpha", FORCE_BOOL)

function PANEL:Init()
	hg.chat = self

	self.entries = {}
	self.messageHistory = {}

	self.alpha = 255
	self.realAlpha = 255

	self:SetSize(ScrW() * 0.3, ScrH() * 0.2)
	self:SetPos(ScrW() * 0.02, ScrH() * 0.67)

	local entryPanel = self:Add("Panel")
	entryPanel:SetZPos(1)
	entryPanel:Dock(BOTTOM)
	entryPanel:DockMargin(4, 0, 4, 4)

	self.entry = entryPanel:Add("zChatboxEntry")
	self.entry:Dock(FILL)
	self.entry.OnEnter = CallbackBind(self, self.OnMessageSent)

	self.history = self:Add("DScrollPanel")
	self.history:Dock(FILL)
	self.history:DockMargin(4, 2, 4, 4)

	self:SetActive(false)
end

local gradient_d = Material("vgui/gradient-d")
local gray = Color(255, 255, 255, 100)
local black = Color(0, 0, 0, 200)

function PANEL:Paint(w, h)
	surface.SetDrawColor(140, 140, 140, 60 + math.sin(CurTime()) * 20) -- Пульсирующий серый градиент для поля ввода
	surface.SetMaterial(gradient_d)
	surface.DrawTexturedRect(0, h * 0.5, w, h * 0.5)

	surface.SetDrawColor(0, 0, 0, 200)
	surface.SetDrawColor(40, 40, 40, 200)
	surface.DrawRect(0, 0, w, h)

	surface.SetAlphaMultiplier(1)
		self.history:PaintManual()
		local bar = self.history:GetVBar()
		bar:SetAlpha(self:GetAlpha())
	surface.SetAlphaMultiplier(self:GetAlpha() / 255)

	DisableClipping(true)
		draw.SimpleText("Держите левый альт и нажмите энтер что бы отправить личное сообщение", "zChatFontSmall", 5, h * 1.01 + 1, black)
		draw.SimpleText("Держите левый альт и нажмите энтер что бы отправить личное сообщение", "zChatFontSmall", 4, h * 1.01, gray)

		if LocalPlayer().organism and LocalPlayer().organism.otrub  then
			draw.SimpleText("Your messages are currently not visible to anyone.", "zChatFontSmall", ScrW() * 0.3 + 1, h * 1.01 + 1, black, TEXT_ALIGN_RIGHT)
			draw.SimpleText("Your messages are currently not visible to anyone.", "zChatFontSmall", ScrW() * 0.3, h * 1.01, gray, TEXT_ALIGN_RIGHT)
		end
	DisableClipping(false)

	if self.bActive then
		self:SetAlpha(self.alpha - (255 - self.realAlpha))
	end
end

function PANEL:SetActive(bActive, bRemovePrev)
	if (bActive) then
		self:SetAlpha(255)
		self:MakePopup()
		self.entry:RequestFocus()

		input.SetCursorPos(self:LocalToScreen(10, self:GetTall() + 10))

		hook.Run("StartChat")
	else
		self:SetAlpha(0)
		self:SetMouseInputEnabled(false)
		self:SetKeyboardInputEnabled(false)

		if bRemovePrev then
			self.entry:SetText("")
			self.entry.prevText = ""
		end

		gui.EnableScreenClicker(false)

		hook.Run("FinishChat")
	end

	self.bActive = bActive

	local bar = self.history:GetVBar()
	bar:SetScroll(bar.CanvasSize)
end

function PANEL:AnimateAlpha(newAlpha)
	self:CreateAnimation(1, {
		index = 1,
		target = {alpha = newAlpha},
	})
end

function PANEL:AnimateRealAlpha(newAlpha)
	self:CreateAnimation(1, {
		index = 2,
		target = {realAlpha = newAlpha},
	})
end

function PANEL:SetRealAlpha(alpha)
	self.realAlpha = alpha
end

function PANEL:OnMessageSent()
	local text = self.entry:GetText()

	if (text:find("%S")) then
		local lastEntry = hg.chat.messageHistory[#hg.chat.messageHistory]

		if (lastEntry != text) then
			if (#hg.chat.messageHistory >= 20) then
				table.remove(hg.chat.messageHistory, 1)
			end

			hg.chat.messageHistory[#hg.chat.messageHistory + 1] = text
		end

		net.Start("zChatMessage")
			net.WriteString(text)
		net.SendToServer()
	end

	self:SetActive(false, true)
end

function PANEL:AddLine(elements)
	local buffer = {
		"<font=zChatFont>"
	}

	buffer = hook.Run("ModifyMessageBuffer", buffer, CHAT_SPEAKER) or buffer

	for _, v in ipairs(elements) do
		if (type(v) == "IMaterial") then
			local texture = v:GetName()

			if (texture) then
				buffer[#buffer + 1] = string.format("<img=%s,%dx%d> ", texture, v:Width(), v:Height())
			end
		elseif (istable(v) and v.r and v.g and v.b) then
			buffer[#buffer + 1] = string.format("<color=%d,%d,%d>", v.r, v.g, v.b)
		elseif (type(v) == "Player") then
			local color = team.GetColor(v:Team())

			buffer[#buffer + 1] = string.format("<color=%d,%d,%d>%s", color.r, color.g, color.b,
				v:GetName():gsub("<", "&lt;"):gsub(">", "&gt;"))
		else
			buffer[#buffer + 1] = tostring(v):gsub("<", "&lt;"):gsub(">", "&gt;")
		end
	end

	local speaker = CHAT_SPEAKER
	local rankPrefix = IsValid(speaker) and speaker:IsPlayer() and hg.GetRankPrefix and hg.GetRankPrefix(speaker)

	local panel = self.history:Add("zChatMessage")
	panel.isMatrix = rankPrefix and hg.IsOwner and hg.IsOwner(speaker) or false
	panel.matrixPrefixText = panel.isMatrix and rankPrefix.tag .. " " or nil
	panel:Dock(TOP)
	panel:InvalidateParent(true)
	panel:SetMarkup(table.concat(buffer))

	if (#self.entries >= 100) then
		local oldPanel = table.remove(self.entries, 1)

		if (IsValid(oldPanel)) then
			oldPanel:Remove()
		end
	end

	local bar = self.history:GetVBar()
	local bScroll = !self:GetActive() or bar.Scroll == bar.CanvasSize

	if bScroll then
		bar:SetScroll(bar.CanvasSize)
	end

	self.entries[#self.entries + 1] = panel
	return panel
end

function PANEL:AddMessage(...)
	self:AddLine({...})

	chat.PlaySound()
end

vgui.Register("zChatbox", PANEL, "EditablePanel")
