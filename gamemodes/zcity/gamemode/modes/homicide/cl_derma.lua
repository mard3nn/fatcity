local MODE = MODE
local vgui_color_main = Color(155, 0, 0, 255) // Claude Popusk 4.8
local vgui_color_bg = Color(50, 50, 50, 255)
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

local function set_role(role, mode)
	if mode == "soe" then
		RunConsoleCommand(MODE.ConVarName_SubRole_Traitor_SOE, role)
	else
		RunConsoleCommand(MODE.ConVarName_SubRole_Traitor, role)
	end
end

local function screen_scale_2(num)
	return ScreenScale(num) / (ScrW() / ScrH())
end

--\\SubRole View Panel
local PANEL = {}

function PANEL:Construct()
	self:SetSkin(hg.GetMainSkin())
	
	self.Title = self.Title or "No title"
	self.hover = 0
	local width, height = self:GetSize()
	local dock_bottom = 5
	
	self.Paint = function(sel, w, h)
		sel.hover = Lerp(FrameTime() * 10, sel.hover, sel:IsHovered() and 1 or 0)
		local isSelected = (self.Mode == "soe" and MODE.ConVar_SubRole_Traitor_SOE:GetString() == self.Role) or (self.Mode != "soe" and MODE.ConVar_SubRole_Traitor:GetString() == self.Role)
		
		draw.RoundedBox(6, 0, 0, w, h, sel.hover > 0.01 and cardBgHover or cardBg)
		if(isSelected)then
			surface.SetDrawColor(cardBorder)
			surface.DrawOutlinedRect(0, 0, w, h, 2)
		end
	end
	
	local label_name = vgui.Create("DLabel", self)
	label_name.ZRolePanel = self
	local label_name_height = 50--height / 5
	height = height - label_name_height - dock_bottom
	label_name:SetText("")
	label_name:SetSkin(hg.GetMainSkin())
	label_name:DockMargin(0, 0, 0, dock_bottom)
	label_name:Dock(TOP)
	label_name:SetHeight(label_name_height)
	label_name:SetMouseInputEnabled(true)
	label_name.Paint = function(sel, w, h)
		if((self.Mode == "soe" and MODE.ConVar_SubRole_Traitor_SOE:GetString() == self.Role) or (self.Mode != "soe" and MODE.ConVar_SubRole_Traitor:GetString() == self.Role))then
			surface.SetDrawColor(cardBorder)
			surface.DrawOutlinedRect(1, 1, w - 2, h - 2, 2)
		end
		
		surface.SetFont("GOMI_RoleCardTitle")

		local tw, th = surface.GetTextSize(self.Title)
		
		surface.SetTextColor(textBright)
		surface.SetTextPos(w / 2 - tw / 2, h / 2 - th / 2)
		surface.DrawText(self.Title)
	end
	
	label_name.DoClick = function(sel)
		set_role(self.Role, self.Mode or "soe")
	end
	
	local text_description = vgui.Create("RichText", self)
	text_description.ZRolePanel = self
	text_description:SetText(self.Description)
	text_description:SetSkin(hg.GetMainSkin())
	text_description:Dock(FILL)
	text_description:DockMargin(8, 0, 8, 8)
	text_description.PerformLayout = function(sel)
		if(sel:GetFont() != "GOMI_RoleCardDesc")then
			sel:SetFontInternal("GOMI_RoleCardDesc")
		end
		
		sel:SetFGColor(textDim)
	end
	text_description.Paint = function(sel, w, h)
		
	end
end

function PANEL:PaintOver(w, h)

end

local tex_gradient = surface.GetTextureID("vgui/gradient-d")
local mata = Material("vgui/traitor_icons/traitor_icon.png")

local rolesmaterials = {
	["traitor_default_soe"] = Material("vgui/traitor_icons/traitor_icon.png"),
}

local glow = Material("homigrad/vgui/models/circle.png")

function PANEL:PostPaintPanel(w, h)
	/*if((self.Mode == "soe" and MODE.ConVar_SubRole_Traitor_SOE:GetString() == self.Role) or (self.Mode != "soe" and MODE.ConVar_SubRole_Traitor:GetString() == self.Role))then
		local y_start = 0
		
		surface.SetDrawColor(vgui_color_main)
		//surface.SetTexture(tex_gradient)
		surface.SetMaterial(mata)
		surface.DrawTexturedRect(0, -100, w, h + 200)
	end*/
	if rolesmaterials[self.Role] then
		//surface.SetDrawColor(vgui_color_main)
		//surface.SetMaterial(rolesmaterials[self.Role])
		//surface.DrawTexturedRect(0, -100, w, h + 200)

		--[[ --whatever
        render.SetStencilWriteMask(0xFF)
        render.SetStencilTestMask(0xFF)
        render.SetStencilReferenceValue(0)
        render.SetStencilCompareFunction(STENCIL_NEVER)
        render.SetStencilPassOperation(STENCIL_KEEP)
        render.SetStencilFailOperation(STENCIL_KEEP)
        render.SetStencilZFailOperation(STENCIL_KEEP)
        render.ClearStencil()
        
        render.SetStencilEnable(true)
        render.SetStencilReferenceValue(1)
        render.SetStencilFailOperation(STENCIL_REPLACE)

		surface.SetDrawColor(Color(255, 255, 255, 255))
		surface.SetMaterial(glow)
		local x, y = self:ScreenToLocal(gui.MouseX() - 0, gui.MouseY() - 0)
		draw.Circle( x, y, 200, 16 )

        render.SetStencilFailOperation(STENCIL_KEEP)
        render.SetStencilCompareFunction(STENCIL_EQUAL)

		surface.SetDrawColor(Color(255, 0, 0, 50))
		surface.SetMaterial(rolesmaterials[self.Role])
		surface.DrawTexturedRect(0, -100, w, h + 200)

		render.SetStencilEnable( false )--]]
	end
end

derma.DefineControl("HMCD_RolePanel", "", PANEL, "DPanel")
--||Sub role carousel
local PANEL = {}

function PANEL:BuildRoleScroller()
	if(IsValid(self.RoleScroller))then
		self.RoleScroller:Remove()
	end

	local mode_info = MODE.RoleChooseRoundTypes[self.Mode]
	local roles = mode_info and mode_info[self.RoleType]
	if not roles then return end

	self.RolesIDsList = roles

	local width, height = self:GetSize()
	local hscroll = vgui.Create("ZHorizontalScroller", self)
	hscroll:SetPos(self.ContentMargin, self.ContentY)
	hscroll:SetSize(width - self.ContentMargin * 2, height - self.ContentY - self.FooterHeight - ScreenScale(12))
	hscroll:SetSkin(hg.GetMainSkin())
	hscroll:SetOverlap(-10)
	self.RoleScroller = hscroll

	for role_id, _ in pairs(roles) do
		local role_info = MODE.SubRoles[role_id]
		if not role_info then continue end

		local role_panel = vgui.Create("HMCD_RolePanel", hscroll)
		role_panel.Title = role_info.Name
		role_panel.Description = role_info.Description
		role_panel.Role = role_id
		role_panel.Mode = self.Mode
		role_panel:SetWidth(ScreenScale(190))
		role_panel:Construct()

		hscroll:AddPanel(role_panel)
	end
end

function PANEL:SwitchRoleMode(mode)
	local mode_info = MODE.RoleChooseRoundTypes[mode]
	if not mode_info or not mode_info[self.RoleType] then return end
	if self.Mode == mode and IsValid(self.RoleScroller) then return end

	self.Mode = mode
	self:BuildRoleScroller()
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
	
	self.OnRemove = function(sel)
		gui.EnableScreenClicker(false)
	end
	
	self.OnKeyCodePressed = function(sel, key)
		if(key == KEY_ESCAPE)then
			sel:Remove()
		end
	end
	
	self.Paint = function(sel, w, h)
		sel.bgAlpha = Lerp(FrameTime() * 8, sel.bgAlpha, 1)
		drawBlur(sel, 8)
		surface.SetDrawColor(bgOverlay.r, bgOverlay.g, bgOverlay.b, bgOverlay.a * sel.bgAlpha)
		surface.DrawRect(0, 0, w, h)
		
		local grid = ScreenScale(25)
		local off = (RealTime() * 12) % grid
		surface.SetDrawColor(200, 30, 30, 15 * sel.bgAlpha)
		for i = -1, math.ceil(w / grid) + 1 do surface.DrawRect(i * grid - off, 0, 1, h) end
		for i = -1, math.ceil(h / grid) + 1 do surface.DrawRect(0, i * grid + off, w, 1) end
	end
	
	local title = vgui.Create("DLabel", self)
	title:SetPos(ScreenScale(20), ScreenScale(20))
	title:SetFont("GOMI_RoleTitle")
	title:SetText("РОЛЬ ПРЕДАТЕЛЯ")
	title:SetTextColor(Color(0, 0, 0, 0))
	title.anim = 0
	title.Paint = function(sel, w, h)
		sel.anim = Lerp(FrameTime() * 10, sel.anim, 1)
		local a = sel.anim * 255
		local root = sel:GetParent()
		local openTime = IsValid(root) and (root.openTime or RealTime()) or RealTime()
		local sweepPos = (RealTime() - openTime) * 12.0
		local soft = 1.4
		local s = "РОЛЬ ПРЕДАТЕЛЯ"
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
			draw.RoundedBox(4, 0, 0, w, h, Color(200, 40, 40, 180 * sel.hover))
		end
		draw.SimpleText("X", "GOMI_RoleBtn", w / 2, h / 2, Color(255 - 80 * sel.hover, 180 + 60 * sel.hover, 180 + 60 * sel.hover, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	closeBtn.DoClick = function()
		if(IsValid(VGUI_HMCD_RolePanelList))then
			VGUI_HMCD_RolePanelList:Remove()
		else
			self:Remove()
		end
	end
	
	local width, height = self:GetSize()
	self.RoleType = self.RoleType or "Traitor"
	self.Mode = MODE.RoleChooseRoundTypes[self.Mode] and self.Mode or "standard"
	self.ContentMargin = ScreenScale(20)
	self.ContentY = ScreenScale(105)
	self.FooterHeight = ScreenScale(44)

	local mode_switch = vgui.Create("DPanel", self)
	local switch_width = ScreenScale(190)
	local switch_height = ScreenScale(24)
	mode_switch:SetSize(switch_width, switch_height)
	mode_switch:SetPos((width - switch_width) / 2, ScreenScale(68))
	mode_switch.Paint = function(sel, w, h)
		draw.RoundedBox(6, 0, 0, w, h, Color(20, 20, 24, 220))
	end

	local mode_options = {
		{ id = "standard", label = "СТАНДАРТ" },
		{ id = "soe", label = "SOE" },
	}

	for index, option in ipairs(mode_options) do
		local mode_id = option.id
		local mode_label = option.label
		local mode_button = vgui.Create("DButton", mode_switch)
		mode_button:SetText("")
		mode_button:SetSize(switch_width / #mode_options, switch_height)
		mode_button:SetPos((index - 1) * switch_width / #mode_options, 0)
		mode_button:SetCursor("hand")
		mode_button.hover = 0
		mode_button.Paint = function(sel, w, h)
			sel.hover = Lerp(FrameTime() * 10, sel.hover, sel:IsHovered() and 1 or 0)
			local active = self.Mode == mode_id
			local bg = active and Color(110, 20, 25, 235) or Color(32 + 12 * sel.hover, 32 + 12 * sel.hover, 38 + 12 * sel.hover, 220)
			draw.RoundedBox(5, 1, 1, w - 2, h - 2, bg)
			if active then
				surface.SetDrawColor(cardBorder)
				surface.DrawOutlinedRect(1, 1, w - 2, h - 2, 1)
			end
			draw.SimpleText(mode_label, "GOMI_RoleBtn", w / 2, h / 2, active and textBright or textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		mode_button.DoClick = function()
			self:SwitchRoleMode(mode_id)
		end
	end

	self:BuildRoleScroller()
	
	local button_ready = vgui.Create("DButton", self)
	button_ready:SetPos((width - ScreenScale(180)) / 2, height - self.FooterHeight)
	button_ready:SetSize(ScreenScale(180), ScreenScale(36))
	button_ready:SetSkin(hg.GetMainSkin())
	button_ready:SetText("")
	button_ready.hover = 0
	button_ready.DoClick = function(sel)
		//if(sel.Clicked)then
			if(IsValid(VGUI_HMCD_RolePanelList))then
				VGUI_HMCD_RolePanelList:Remove()
			end
		//end
		
		//sel.Clicked = true
		
		//net.Start("HMCD(StartPlayersRoleSelection)")
		//net.SendToServer()
	end
	button_ready.Paint = function(sel, w, h)
		sel.hover = Lerp(FrameTime() * 10, sel.hover, sel:IsHovered() and 1 or 0)
		draw.RoundedBox(6, 0, 0, w, h, sel.hover > 0.01 and Color(45, 45, 50, 230) or Color(30, 30, 34, 220))
		surface.SetDrawColor(cardBorder.r, cardBorder.g, cardBorder.b, 200)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
		draw.SimpleText("ГОТОВО", "GOMI_RoleBtn", w / 2, h / 2, textBright, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end

derma.DefineControl("HMCD_RolePanelList", "", PANEL, "DPanel")
--//

--\\Manual Click detection
local delta = 0
hook.Add("CreateMove", "HMCD_RolePanelClick", function(cmd)
	local dlta = (input.WasMousePressed(MOUSE_WHEEL_DOWN) and -1) or (input.WasMousePressed(MOUSE_WHEEL_UP) and 1) or 0

	delta = LerpFT(0.05, delta, dlta)
	local delta = delta * 2

	if(math.abs(delta) > 0.01)then
		local hovered_panel = vgui.GetHoveredPanel()

		local parent_panel = IsValid(hovered_panel) and hovered_panel:GetParent()
		local parent_panel2 = IsValid(parent_panel) and parent_panel:GetParent()
		local parent_panel3 = IsValid(parent_panel2) and parent_panel2:GetParent()
		local parent_panel4 = IsValid(parent_panel3) and parent_panel3:GetParent()
		local parent_panel5 = IsValid(parent_panel4) and parent_panel4:GetParent()

		if IsValid(hovered_panel) and hovered_panel.OnMouseWheeled then
			hovered_panel:OnMouseWheeled(delta)
		end

		if IsValid(parent_panel) and parent_panel.OnMouseWheeled then
			parent_panel:OnMouseWheeled(delta)
		end

		if IsValid(parent_panel2) and parent_panel2.OnMouseWheeled then
			parent_panel2:OnMouseWheeled(delta)
		end

		if IsValid(parent_panel3) and parent_panel3.OnMouseWheeled then
			parent_panel3:OnMouseWheeled(delta)
		end

		if IsValid(parent_panel4) and parent_panel4.OnMouseWheeled then
			parent_panel4:OnMouseWheeled(delta)
		end

		if IsValid(parent_panel5) and parent_panel5.OnMouseWheeled then
			parent_panel5:OnMouseWheeled(delta)
		end
	end

	if(input.WasMousePressed(MOUSE_LEFT))then
			-- print("Left mouse button was pressed")
		local hovered_panel = vgui.GetHoveredPanel()
		
		if(IsValid(hovered_panel) and IsValid(hovered_panel.ZRolePanel))then
			set_role(hovered_panel.ZRolePanel.Role, hovered_panel.ZRolePanel.Mode)
		end
	end
end)
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