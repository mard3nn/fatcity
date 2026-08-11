-- Admin organism control menu (client)

local MENU
local REFRESH_INTERVAL = 0.5
local nextRefresh = 0
local selectedEnt
local snapshot = {}
local controls = {}
local updatingUI = false
local interactingUntil = 0
local pendingSets = {}
local pendingSetTimer = "hg_orgmenu_flushsets"
local activeCategory = 1

local COL_BG = Color(25, 25, 35, 220)
local COL_BR = Color(70, 140, 220, 240)
local COL_TEXT = Color(220, 230, 245)
local COL_DIM = Color(140, 160, 190)
local COL_ACCENT = Color(80, 160, 255)
local COL_ROW = Color(20, 28, 45, 160)
local COL_TRACK = Color(40, 50, 70, 200)
local COL_FILL = Color(50, 120, 210, 220)
local COL_GRAD_SIDE = Color(25, 25, 35, 180)
local COL_GRAD_BLUE = Color(0, 50, 140, 50)

local gradient_d = surface.GetTextureID("vgui/gradient-d")
local gradient_l = surface.GetTextureID("vgui/gradient-l")

surface.CreateFont("HGOrgMenuSub", {
	font = "Bahnschrift",
	size = 14,
	weight = 500,
	extended = true,
	antialias = true,
})

surface.CreateFont("HGOrgMenuSmall", {
	font = "Bahnschrift",
	size = 12,
	weight = 500,
	extended = true,
	antialias = true,
})

local function flushPendingSets()
	if not IsValid(selectedEnt) then
		pendingSets = {}
		return
	end

	for path, data in pairs(pendingSets) do
		net.Start("hg_orgmenu_set")
			net.WriteEntity(selectedEnt)
			net.WriteString(path)
			net.WriteString(data.valueType or "")
			net.WriteType(data.value)
		net.SendToServer()
	end

	pendingSets = {}
end

local function queueSet(path, valueType, value)
	if not IsValid(selectedEnt) or updatingUI then return end

	interactingUntil = CurTime() + 0.8
	pendingSets[path] = {valueType = valueType, value = value}
	snapshot[path] = value

	timer.Create(pendingSetTimer, 0.12, 1, flushPendingSets)
end

local CATEGORIES = {
	{
		name = "Vital",
		fields = {
			{key = "alive", type = "bool", label = "Alive"},
			{key = "otrub", type = "bool", label = "Unconscious"},
			{key = "canmove", type = "bool", label = "Can move"},
			{key = "godmode", type = "bool", label = "Godmode"},
			{key = "superfighter", type = "bool", label = "Superfighter"},
			{key = "health", type = "num", min = 0, max = 200, label = "Health"},
			{key = "temperature", type = "num", min = 20, max = 45, decimals = 1, label = "Temperature"},
			{key = "consciousness", type = "num", min = 0, max = 1, decimals = 2, label = "Consciousness"},
			{key = "disorientation", type = "num", min = 0, max = 20, decimals = 2, label = "Disorientation"},
			{key = "fear", type = "num", min = 0, max = 20, decimals = 2, label = "Fear"},
			{key = "fearadd", type = "num", min = 0, max = 20, decimals = 2, label = "Fear add"},
		}
	},
	{
		name = "Blood",
		fields = {
			{key = "blood", type = "num", min = 0, max = 5000, label = "Blood"},
			{key = "bleed", type = "num", min = 0, max = 100, decimals = 2, label = "Bleed"},
			{key = "internalBleed", type = "num", min = 0, max = 50, decimals = 2, label = "Internal bleed"},
			{key = "bloodtype", type = "choice", choices = {"o-", "o+", "a-", "a+", "b-", "b+", "ab-", "ab+", "c-"}, label = "Blood type"},
			{key = "bleedingmul", type = "num", min = 0, max = 5, decimals = 2, label = "Bleed mul"},
			{key = "arteria", type = "num", min = 0, max = 1, decimals = 2, label = "Neck artery"},
			{key = "rarmartery", type = "num", min = 0, max = 1, decimals = 2, label = "R arm artery"},
			{key = "larmartery", type = "num", min = 0, max = 1, decimals = 2, label = "L arm artery"},
			{key = "rlegartery", type = "num", min = 0, max = 1, decimals = 2, label = "R leg artery"},
			{key = "llegartery", type = "num", min = 0, max = 1, decimals = 2, label = "L leg artery"},
			{key = "spineartery", type = "num", min = 0, max = 1, decimals = 2, label = "Spine artery"},
			{key = "wantToVomit", type = "num", min = 0, max = 10, decimals = 2, label = "Want to vomit"},
		}
	},
	{
		name = "Pain",
		fields = {
			{key = "pain", type = "num", min = 0, max = 150, decimals = 1, label = "Pain"},
			{key = "avgpain", type = "num", min = 0, max = 150, decimals = 1, label = "Avg pain"},
			{key = "painadd", type = "num", min = 0, max = 150, decimals = 1, label = "Pain add"},
			{key = "shock", type = "num", min = 0, max = 100, decimals = 1, label = "Shock"},
			{key = "hurt", type = "num", min = 0, max = 10, decimals = 2, label = "Hurt"},
			{key = "hurtadd", type = "num", min = 0, max = 10, decimals = 2, label = "Hurt add"},
			{key = "immobilization", type = "num", min = 0, max = 100, decimals = 1, label = "Immobilization"},
			{key = "painkiller", type = "num", min = 0, max = 5, decimals = 2, label = "Painkiller"},
			{key = "analgesia", type = "num", min = 0, max = 5, decimals = 2, label = "Analgesia"},
			{key = "naloxone", type = "num", min = 0, max = 5, decimals = 2, label = "Naloxone"},
			{key = "tranquilizer", type = "num", min = 0, max = 10, decimals = 2, label = "Tranquilizer"},
			{key = "adrenaline", type = "num", min = 0, max = 10, decimals = 2, label = "Adrenaline"},
			{key = "adrenalineAdd", type = "num", min = 0, max = 10, decimals = 2, label = "Adrenaline add"},
			{key = "adrenalineStorage", type = "num", min = 0, max = 10, decimals = 2, label = "Adrenaline storage"},
		}
	},
	{
		name = "Heart",
		fields = {
			{key = "pulse", type = "num", min = 0, max = 250, label = "Pulse"},
			{key = "heartbeat", type = "num", min = 0, max = 300, label = "Heartbeat"},
			{key = "bloodPressure", type = "num", min = 0, max = 200, label = "Blood pressure"},
			{key = "systolic", type = "num", min = 0, max = 250, label = "Systolic"},
			{key = "diastolic", type = "num", min = 0, max = 150, label = "Diastolic"},
			{key = "cardiacOutput", type = "num", min = 0, max = 2, decimals = 2, label = "Cardiac output"},
			{key = "heart", type = "num", min = 0, max = 1, decimals = 2, label = "Heart damage"},
			{key = "heartstop", type = "bool", label = "Heart stopped"},
			{key = "fibrillation", type = "bool", label = "Fibrillation"},
			{key = "arrhythmia", type = "num", min = 0, max = 1, decimals = 2, label = "Arrhythmia"},
			{key = "myocardialOxygen", type = "num", min = 0, max = 1, decimals = 2, label = "Myocardial O2"},
			{key = "heartStrain", type = "num", min = 0, max = 1, decimals = 2, label = "Heart strain"},
			{key = "hypertension", type = "num", min = 0, max = 1, decimals = 2, label = "Hypertension"},
			{key = "hypotension", type = "num", min = 0, max = 1, decimals = 2, label = "Hypotension"},
		}
	},
	{
		name = "Brain",
		fields = {
			{key = "brain", type = "num", min = 0, max = 1, decimals = 3, label = "Brain"},
			{key = "brainFrontal", type = "num", min = 0, max = 1, decimals = 3, label = "Frontal"},
			{key = "brainParietal", type = "num", min = 0, max = 1, decimals = 3, label = "Parietal"},
			{key = "brainTemporal", type = "num", min = 0, max = 1, decimals = 3, label = "Temporal"},
			{key = "brainOccipital", type = "num", min = 0, max = 1, decimals = 3, label = "Occipital"},
			{key = "brainHemorrhage", type = "num", min = 0, max = 1, decimals = 3, label = "Hemorrhage"},
			{key = "brainBleedRate", type = "num", min = 0, max = 0.05, decimals = 4, label = "Brain bleed rate"},
			{key = "skull", type = "num", min = 0, max = 1, decimals = 2, label = "Skull"},
			{key = "jaw", type = "num", min = 0, max = 1, decimals = 2, label = "Jaw"},
			{key = "eyeL", type = "num", min = 0, max = 1, decimals = 2, label = "Left eye"},
			{key = "eyeR", type = "num", min = 0, max = 1, decimals = 2, label = "Right eye"},
			{key = "jawdislocation", type = "bool", label = "Jaw dislocation"},
		}
	},
	{
		name = "Organs",
		fields = {
			{key = "spine1", type = "num", min = 0, max = 1, decimals = 2, label = "Spine 1"},
			{key = "spine2", type = "num", min = 0, max = 1, decimals = 2, label = "Spine 2"},
			{key = "spine3", type = "num", min = 0, max = 1, decimals = 2, label = "Spine 3"},
			{key = "chest", type = "num", min = 0, max = 1, decimals = 2, label = "Chest"},
			{key = "pelvis", type = "num", min = 0, max = 1, decimals = 2, label = "Pelvis"},
			{key = "stomach", type = "num", min = 0, max = 1, decimals = 2, label = "Stomach"},
			{key = "liver", type = "num", min = 0, max = 1, decimals = 2, label = "Liver"},
			{key = "intestines", type = "num", min = 0, max = 1, decimals = 2, label = "Intestines"},
			{key = "thiamine", type = "num", min = 0, max = 5, decimals = 2, label = "Thiamine"},
			{key = "trachea", type = "num", min = 0, max = 1, decimals = 2, label = "Trachea"},
			{key = "pneumothorax", type = "num", min = 0, max = 1, decimals = 2, label = "Pneumothorax"},
			{key = "needle", type = "num", min = 0, max = 1, decimals = 2, label = "Needle"},
			{key = "lungsfunction", type = "bool", label = "Lungs function"},
			{key = "holdingbreath", type = "bool", label = "Holding breath"},
			{key = "CO", type = "num", min = 0, max = 100, decimals = 2, label = "CO"},
			{key = "lungsL.1", type = "num", min = 0, max = 1, decimals = 2, label = "L lung dmg"},
			{key = "lungsL.2", type = "num", min = 0, max = 1, decimals = 2, label = "L lung hole"},
			{key = "lungsR.1", type = "num", min = 0, max = 1, decimals = 2, label = "R lung dmg"},
			{key = "lungsR.2", type = "num", min = 0, max = 1, decimals = 2, label = "R lung hole"},
			{key = "o2.1", type = "num", min = 0, max = 40, decimals = 2, label = "O2"},
			{key = "o2.regen", type = "num", min = 0, max = 5, decimals = 2, label = "O2 regen"},
			{key = "o2.curregen", type = "num", min = 0, max = 5, decimals = 2, label = "O2 cur regen"},
		}
	},
	{
		name = "Limbs",
		fields = {
			{key = "lleg", type = "num", min = 0, max = 1, decimals = 2, label = "L leg"},
			{key = "rleg", type = "num", min = 0, max = 1, decimals = 2, label = "R leg"},
			{key = "larm", type = "num", min = 0, max = 1, decimals = 2, label = "L arm"},
			{key = "rarm", type = "num", min = 0, max = 1, decimals = 2, label = "R arm"},
			{key = "llegdislocation", type = "bool", label = "L leg dislocation"},
			{key = "rlegdislocation", type = "bool", label = "R leg dislocation"},
			{key = "larmdislocation", type = "bool", label = "L arm dislocation"},
			{key = "rarmdislocation", type = "bool", label = "R arm dislocation"},
			{key = "llegamputated", type = "bool", label = "L leg amputated"},
			{key = "rlegamputated", type = "bool", label = "R leg amputated"},
			{key = "larmamputated", type = "bool", label = "L arm amputated"},
			{key = "rarmamputated", type = "bool", label = "R arm amputated"},
			{key = "headamputated", type = "bool", label = "Head amputated"},
			{key = "recoilmul", type = "num", min = 0, max = 5, decimals = 2, label = "Recoil mul"},
			{key = "meleespeed", type = "num", min = 0, max = 5, decimals = 2, label = "Melee speed"},
			{key = "legstrength", type = "num", min = 0, max = 5, decimals = 2, label = "Leg strength"},
		}
	},
	{
		name = "Effects",
		fields = {
			{key = "stamina.1", type = "num", min = 0, max = 200, decimals = 1, label = "Stamina"},
			{key = "stamina.max", type = "num", min = 1, max = 200, decimals = 1, label = "Stamina max"},
			{key = "stamina.regen", type = "num", min = 0, max = 5, decimals = 2, label = "Stamina regen"},
			{key = "stamina.sub", type = "num", min = 0, max = 5, decimals = 2, label = "Stamina sub"},
			{key = "hungry", type = "num", min = 0, max = 100, decimals = 1, label = "Hungry"},
			{key = "satiety", type = "num", min = 0, max = 100, decimals = 1, label = "Satiety"},
			{key = "berserk", type = "num", min = 0, max = 10, decimals = 2, label = "Berserk"},
			{key = "noradrenaline", type = "num", min = 0, max = 10, decimals = 2, label = "Noradrenaline"},
			{key = "assimilated", type = "num", min = 0, max = 1, decimals = 2, label = "Assimilated"},
			{key = "furryinfected", type = "bool", label = "Furry infected"},
			{key = "panicattack", type = "num", min = 0, max = 1, decimals = 2, label = "Panic attack"},
			{key = "panicattackadd", type = "num", min = 0, max = 1, decimals = 2, label = "Panic add"},
			{key = "seizure", type = "num", min = 0, max = 1, decimals = 2, label = "Seizure"},
			{key = "seizureActive", type = "bool", label = "Seizure active"},
			{key = "stun", type = "num", min = 0, max = 999999, decimals = 0, label = "Stun until"},
			{key = "lightstun", type = "num", min = 0, max = 999999, decimals = 0, label = "Light stun until"},
		}
	},
}

local ACTIONS = {
	{id = "fullheal", label = "Full Heal"},
	{id = "clear", label = "Reset"},
	{id = "wake", label = "Wake Up"},
	{id = "otrub", label = "Knock Out"},
	{id = "heartstart", label = "Restart Heart"},
	{id = "heartstop", label = "Stop Heart"},
	{id = "fibrillation", label = "Fibrillation"},
	{id = "seizure_start", label = "Start Seizure"},
	{id = "seizure_stop", label = "Stop Seizure"},
	{id = "panic", label = "Panic"},
	{id = "berserk", label = "Berserk"},
	{id = "noradrenaline", label = "Noradrenaline"},
	{id = "bleedout", label = "Bleedout"},
	{id = "killbrain", label = "Destroy Brain"},
	{id = "fake", label = "Force Ragdoll"},
	{id = "god_on", label = "Godmode ON"},
	{id = "god_off", label = "Godmode OFF"},
	{id = "amputate_larm", label = "Amp. L Arm"},
	{id = "amputate_rarm", label = "Amp. R Arm"},
	{id = "amputate_lleg", label = "Amp. L Leg"},
	{id = "amputate_rleg", label = "Amp. R Leg"},
	{id = "explode_head", label = "Explode Head"},
}

local function requestSnapshot()
	if not IsValid(selectedEnt) then return end
	net.Start("hg_orgmenu_request")
		net.WriteEntity(selectedEnt)
	net.SendToServer()
end

local function sendAction(action)
	if not IsValid(selectedEnt) then return end
	flushPendingSets()
	interactingUntil = CurTime() + 0.4
	net.Start("hg_orgmenu_action")
		net.WriteEntity(selectedEnt)
		net.WriteString(action)
	net.SendToServer()
end

local function formatValue(value, decimals)
	if value == nil then return "-" end
	if type(value) == "boolean" then return value and "ON" or "OFF" end
	local num = tonumber(value)
	if not num then return tostring(value) end
	return string.format("%." .. (decimals or 0) .. "f", num)
end

local function applySnapshotToControls()
	if not IsValid(MENU) then return end
	if CurTime() < interactingUntil then return end

	updatingUI = true
	for path, ctrl in pairs(controls) do
		if not IsValid(ctrl) then continue end
		if pendingSets[path] then continue end
		local value = snapshot[path]
		if value == nil then continue end
		if ctrl.SetOrgValue then
			ctrl:SetOrgValue(value)
		elseif ctrl.ClassName == "DComboBox" then
			ctrl:SetValue(tostring(value))
		end
	end
	updatingUI = false
end

local function createToggle(parent, field)
	local path = field.key
	local row = vgui.Create("DPanel", parent)
	row:Dock(TOP)
	row:DockMargin(6, 2, 6, 2)
	row:SetTall(28)
	row.checked = false

	row.Paint = function(self, w, h)
		draw.RoundedBox(0, 0, 0, w, h, COL_ROW)
		draw.SimpleText(field.label or path, "HGOrgMenuSub", 8, h / 2, COL_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		draw.SimpleText(self.checked and "ON" or "OFF", "HGOrgMenuSmall", w - 8, h / 2, self.checked and COL_ACCENT or COL_DIM, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
	end

	row.OnMousePressed = function(self)
		self.checked = not self.checked
		queueSet(path, "bool", self.checked)
	end

	row.SetOrgValue = function(self, value)
		self.checked = tobool(value)
	end

	controls[path] = row
end

local function createChoice(parent, field)
	local path = field.key
	local row = vgui.Create("DPanel", parent)
	row:Dock(TOP)
	row:DockMargin(6, 2, 6, 2)
	row:SetTall(28)
	row.Paint = function(_, w, h)
		draw.RoundedBox(0, 0, 0, w, h, COL_ROW)
		draw.SimpleText(field.label or path, "HGOrgMenuSub", 8, h / 2, COL_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end

	local combo = vgui.Create("DComboBox", row)
	combo:Dock(RIGHT)
	combo:SetWide(120)
	combo:DockMargin(4, 2, 4, 2)
	combo:SetTextColor(COL_TEXT)
	for i = 1, #(field.choices or {}) do
		combo:AddChoice(field.choices[i])
	end
	combo.OnSelect = function(_, _, value)
		queueSet(path, "string", value)
	end

	controls[path] = combo
end

local function createSlider(parent, field)
	local path = field.key
	local minv = field.min or 0
	local maxv = field.max or 1
	local decimals = field.decimals or 0

	local row = vgui.Create("DPanel", parent)
	row:Dock(TOP)
	row:DockMargin(6, 2, 6, 2)
	row:SetTall(40)
	row.value = minv
	row.dragging = false

	row.Paint = function(self, w, h)
		draw.RoundedBox(0, 0, 0, w, h, COL_ROW)
		draw.SimpleText(field.label or path, "HGOrgMenuSub", 8, 10, COL_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		draw.SimpleText(formatValue(self.value, decimals), "HGOrgMenuSmall", w - 8, 10, COL_ACCENT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

		local trackX, trackY, trackW, trackH = 8, 24, w - 16, 8
		local frac = maxv ~= minv and math.Clamp((self.value - minv) / (maxv - minv), 0, 1) or 0
		draw.RoundedBox(0, trackX, trackY, trackW, trackH, COL_TRACK)
		draw.RoundedBox(0, trackX, trackY, trackW * frac, trackH, COL_FILL)
		draw.RoundedBox(0, trackX + trackW * frac - 4, trackY - 2, 8, 12, COL_ACCENT)
	end

	local function setFromCursor(self)
		local w = self:GetWide()
		local trackX, trackW = 8, w - 16
		local mx = self:CursorPos()
		local frac = math.Clamp((mx - trackX) / trackW, 0, 1)
		local value = minv + (maxv - minv) * frac
		value = decimals <= 0 and math.Round(value) or math.Round(value, decimals)
		self.value = value
		queueSet(path, "num", value)
	end

	row.OnMousePressed = function(self, code)
		if code ~= MOUSE_LEFT then return end
		self.dragging = true
		self:MouseCapture(true)
		setFromCursor(self)
	end

	row.OnMouseReleased = function(self, code)
		if code ~= MOUSE_LEFT then return end
		self.dragging = false
		self:MouseCapture(false)
	end

	row.OnCursorMoved = function(self)
		if self.dragging then setFromCursor(self) end
	end

	row.SetOrgValue = function(self, value)
		self.value = tonumber(value) or minv
	end

	controls[path] = row
end

local function addFieldRow(parent, field)
	if field.type == "bool" then
		createToggle(parent, field)
	elseif field.type == "choice" then
		createChoice(parent, field)
	else
		createSlider(parent, field)
	end
end

local function rebuildPlayerList(combo)
	if not IsValid(combo) then return end
	combo:Clear()
	local keep

	for _, ply in ipairs(player.GetAll()) do
		combo:AddChoice(ply:Nick(), ply)
		if IsValid(selectedEnt) and selectedEnt == ply then keep = ply end
	end

	local eyed = LocalPlayer():GetEyeTrace().Entity
	if IsValid(eyed) then
		local orgOwner = eyed.organism and eyed.organism.owner or eyed
		if IsValid(orgOwner) and orgOwner ~= LocalPlayer() then
			local label = orgOwner:IsPlayer() and orgOwner:Nick() or ("ENT #" .. orgOwner:EntIndex())
			combo:AddChoice("[LOOK] " .. label, orgOwner)
		end
	end

	if IsValid(keep) then
		combo:SetValue(keep:IsPlayer() and keep:Nick() or tostring(keep))
		selectedEnt = keep
	elseif IsValid(LocalPlayer()) then
		combo:SetValue(LocalPlayer():Nick())
		selectedEnt = LocalPlayer()
	end
end

local function openMenu()
	if not LocalPlayer():IsAdmin() then return end

	if IsValid(MENU) then
		MENU:Remove()
		MENU = nil
	end

	controls = {}
	snapshot = {}
	activeCategory = 1

	local frame = vgui.Create("ZFrame")
	MENU = frame
	frame:SetSize(math.min(ScrW() - 40, 980), math.min(ScrH() - 40, 680))
	frame:Center()
	frame:SetTitle("Organism")
	frame:SetDraggable(true)
	frame:SetSizable(true)
	frame:SetDeleteOnClose(true)
	frame:MakePopup()
	frame:SetColorBG(COL_BG)
	frame:SetColorBR(COL_BR)
	frame:SetBlurStrengh(2)

	local oldPaint = frame.Paint
	frame.Paint = function(self, w, h)
		oldPaint(self, w, h)

		surface.SetDrawColor(COL_GRAD_SIDE)
		surface.SetTexture(gradient_l)
		surface.DrawTexturedRect(0, 0, w, h)

		surface.SetDrawColor(COL_GRAD_BLUE)
		surface.SetTexture(gradient_d)
		surface.DrawTexturedRect(0, 0, w, h)
	end

	frame.OnClose = function()
		timer.Remove(pendingSetTimer)
		flushPendingSets()
		MENU = nil
	end

	local top = vgui.Create("DPanel", frame)
	top:Dock(TOP)
	top:SetTall(36)
	top:DockMargin(8, 28, 8, 4)
	top.Paint = nil

	local combo = vgui.Create("DComboBox", top)
	combo:Dock(LEFT)
	combo:SetWide(220)
	combo:DockMargin(0, 4, 4, 4)
	combo:SetTextColor(COL_TEXT)
	combo.OnSelect = function(_, _, _, data)
		selectedEnt = data
		requestSnapshot()
	end

	local function makeTopBtn(text, wide, click)
		local btn = vgui.Create("DButton", top)
		btn:Dock(LEFT)
		btn:SetWide(wide)
		btn:DockMargin(0, 4, 4, 4)
		btn:SetText(text)
		btn.DoClick = click
	end

	makeTopBtn("Refresh", 70, function()
		rebuildPlayerList(combo)
		requestSnapshot()
	end)

	makeTopBtn("Myself", 70, function()
		selectedEnt = LocalPlayer()
		combo:SetValue(LocalPlayer():Nick())
		requestSnapshot()
	end)

	makeTopBtn("Look", 60, function()
		local ent = LocalPlayer():GetEyeTrace().Entity
		if not IsValid(ent) then return end
		local owner = ent.organism and ent.organism.owner or ent
		if not IsValid(owner) or not owner.organism then return end
		selectedEnt = owner
		combo:SetValue(owner:IsPlayer() and owner:Nick() or ("ENT #" .. owner:EntIndex()))
		requestSnapshot()
	end)

	local actions = vgui.Create("DScrollPanel", frame)
	actions:Dock(RIGHT)
	actions:SetWide(150)
	actions:DockMargin(0, 4, 8, 8)

	for i = 1, #ACTIONS do
		local act = ACTIONS[i]
		local btn = vgui.Create("DButton", actions)
		btn:Dock(TOP)
		btn:DockMargin(0, 0, 0, 3)
		btn:SetTall(24)
		btn:SetText(act.label)
		btn.DoClick = function() sendAction(act.id) end
	end

	local body = vgui.Create("DPanel", frame)
	body:Dock(FILL)
	body:DockMargin(8, 4, 4, 8)
	body.Paint = nil

	local tabs = vgui.Create("DPanel", body)
	tabs:Dock(LEFT)
	tabs:SetWide(110)
	tabs:DockMargin(0, 0, 4, 0)
	tabs.Paint = nil

	local content = vgui.Create("DPanel", body)
	content:Dock(FILL)
	content.Paint = nil

	local pages = {}

	local function showCategory(index)
		activeCategory = index
		for i, page in pairs(pages) do
			if IsValid(page) then page:SetVisible(i == index) end
		end
	end

	for i = 1, #CATEGORIES do
		local cat = CATEGORIES[i]

		local tabBtn = vgui.Create("DButton", tabs)
		tabBtn:Dock(TOP)
		tabBtn:SetTall(26)
		tabBtn:DockMargin(0, 0, 0, 2)
		tabBtn:SetText(cat.name)
		tabBtn.DoClick = function()
			showCategory(i)
		end
		tabBtn.Paint = function(self, w, h)
			local active = activeCategory == i
			draw.RoundedBox(0, 0, 0, w, h, active and Color(30, 70, 130, 200) or Color(20, 28, 45, 140))
			draw.SimpleText(self:GetText(), "HGOrgMenuSmall", w / 2, h / 2, COL_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			return true
		end

		local scroll = vgui.Create("DScrollPanel", content)
		scroll:Dock(FILL)
		scroll:SetVisible(i == 1)
		pages[i] = scroll

		for j = 1, #cat.fields do
			addFieldRow(scroll, cat.fields[j])
		end
	end

	rebuildPlayerList(combo)
	requestSnapshot()

	frame.Think = function()
		if not IsValid(frame) then return end
		if CurTime() < nextRefresh then return end
		if CurTime() < interactingUntil then return end
		nextRefresh = CurTime() + REFRESH_INTERVAL
		if IsValid(selectedEnt) then requestSnapshot() end
	end
end

net.Receive("hg_orgmenu_open", function()
	openMenu()
end)

net.Receive("hg_orgmenu_snapshot", function()
	local ent = net.ReadEntity()
	local data = net.ReadTable() or {}
	if IsValid(selectedEnt) and IsValid(ent) and selectedEnt ~= ent then return end
	selectedEnt = ent
	snapshot = data
	applySnapshotToControls()
end)

concommand.Add("hg_organism_menu_cl", function()
	openMenu()
end)

list.Set("DesktopWindows", "HGOrganismMenu", {
	title = "Organism",
	icon = "icon16/heart.png",
	init = function()
		RunConsoleCommand("hg_organism_menu")
	end
})
