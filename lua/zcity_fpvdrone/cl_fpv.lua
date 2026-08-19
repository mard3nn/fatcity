ZCFpv = ZCFpv or {}

local linked
local linkedDrone
local viewStartEye
local mavicPitch = 0
local mavicYaw = 0
local portalsPrev
local attachSent
local attachSentAt = 0
local payloadNotice
local payloadNoticeUntil = 0
local dropMat = Material("models/sw/avia/mavic2/drop")
local colRed = Color(160, 40, 40)

net.Receive("zc_fpv_payload_notice", function()
	payloadNotice = net.ReadString()
	payloadNoticeUntil = CurTime() + 2.5
	attachSent = nil
end)

local function buildView(drone, fov, znear, zfar)
	local mavic = drone:GetClass() == "ent_zc_fpv_mavic"
	local fixedWing = drone.FixedWing
	local angles

	if mavic then
		local pitch = mavicPitch
		local yaw = mavicYaw
		drone:SetPoseParameter("yaw", math.Clamp(yaw, -175, 175))
		drone:SetPoseParameter("pitch", math.Clamp(-pitch, -90, 90))
		drone:InvalidateBoneCache()
		angles = drone:LocalToWorldAngles(Angle(pitch, yaw, 0))
	end

	local id = drone:LookupAttachment("view")
	local att = id and id > 0 and drone:GetAttachment(id)
	local origin

	if att then
		origin = att.Pos
		angles = angles or att.Ang
	else
		origin = mavic and drone:LocalToWorld(Vector(2, 0, -2)) or drone:LocalToWorld(Vector(4, 0, 2))
		angles = angles or drone:GetAngles()
	end

	if fixedWing then
		angles = drone:GetAngles()
		origin = drone:LocalToWorld(Vector(drone:OBBMaxs().x + 1, 0, 2))
	elseif mavic then
		origin = origin - drone:GetUp() * 2 + angles:Forward() * 0.5
	else
		origin = origin - angles:Forward() * 3.5 + angles:Up() * 2
	end

	return {
		origin = origin,
		angles = angles,
		fov = fixedWing and 90 or ZCFpv.FOV or fov or 60,
		znear = fixedWing and 2 or 0.3,
		zfar = zfar,
		drawviewer = true,
	}
end

local function enableOverride()
	zb = zb or {}
	if ZCFpv._overrideSet then return end
	ZCFpv._overrideSet = true
	ZCFpv._prevOverride = zb.OverrideCalcView

	zb.OverrideCalcView = function(ply, origin, angles, fov, znear, zfar)
		local drone = linkedDrone
		if not IsValid(drone) then
			drone = ZCFpv.GetLinkedDrone(ply)
		end
		if IsValid(drone) and ply == LocalPlayer() then
			return buildView(drone, fov, znear, zfar)
		end
		if ZCFpv._prevOverride then
			return ZCFpv._prevOverride(ply, origin, angles, fov, znear, zfar)
		end
	end
end

local function disableOverride()
	if not ZCFpv._overrideSet then return end
	ZCFpv._overrideSet = false
	if zb then
		zb.OverrideCalcView = ZCFpv._prevOverride
	end
	ZCFpv._prevOverride = nil
end

local function clearLink()
	linked = false
	linkedDrone = nil
	ZCFpv.ClientLinked = nil
	viewStartEye = nil
	mavicPitch = 0
	mavicYaw = 0
	ZCFpv.MavicNVG = false
	if portalsPrev ~= nil then
		RunConsoleCommand("r_portalsopenall", tostring(portalsPrev))
		portalsPrev = nil
	end
	disableOverride()
end

net.Receive("zc_fpv_link", function()
	local on = net.ReadBool()
	local ent = net.ReadEntity()

	if on and IsValid(ent) then
		linked = true
		linkedDrone = ent
		ZCFpv.ClientLinked = ent
		viewStartEye = LocalPlayer():EyeAngles()
		mavicPitch = 0
		mavicYaw = 0
		local portals = GetConVar("r_portalsopenall")
		if portals then
			portalsPrev = portals:GetInt()
			RunConsoleCommand("r_portalsopenall", "1")
		end
		enableOverride()
	else
		clearLink()
	end
end)

hook.Add("Think", "ZCFpv_Unstick", function()
	if not linked then return end
	if IsValid(linkedDrone) or IsValid(ZCFpv.GetLinkedDrone(LocalPlayer())) then return end
	clearLink()
end)

hook.Add("CalcView", "ZCFpv_ViewEnt", function(ply, origin, angles, fov, znear, zfar)
	if ply ~= LocalPlayer() then return end
	local drone = linkedDrone or ZCFpv.GetLinkedDrone(ply)
	if not IsValid(drone) then return end
	return buildView(drone, fov, znear, zfar)
end)

hook.Add("PostPostHGCalcView", "ZCFpv_View", function(ply, view)
	if ply ~= LocalPlayer() then return end
	local drone = linkedDrone or ZCFpv.GetLinkedDrone(ply)
	if not IsValid(drone) then return end

	local v = buildView(drone, view.fov, view.znear, view.zfar)
	view.origin = v.origin
	view.angles = v.angles
	view.fov = v.fov
	view.drawviewer = true
	return view
end)

hook.Add("ShouldDrawLocalPlayer", "ZCFpv_DrawSelf", function(ply)
	if ply ~= LocalPlayer() then return end
	if linked or IsValid(linkedDrone) or IsValid(ZCFpv.GetLinkedDrone(ply)) then
		return true
	end
end)

local vecFull = Vector(1, 1, 1)

hook.Add("PrePlayerDraw", "ZCFpv_ShowHead", function(ply)
	local drone = ply:GetNWEntity("ZCFpvDrone")
	if IsValid(drone) then
		ply:SetRenderAngles(ply:GetNWAngle("ZCFpvBodyAng"))
		ply:SetPoseParameter("aim_yaw", 0)
		ply:SetPoseParameter("aim_pitch", 0)
		ply:SetPoseParameter("head_yaw", 0)
		ply:SetPoseParameter("head_pitch", 0)
	end

	if ply ~= LocalPlayer() or not IsValid(drone) then return end
	local bone = ply:LookupBone("ValveBiped.Bip01_Head1")
	if bone then
		ply:ManipulateBoneScale(bone, vecFull)
	end
end)

hook.Add("CreateMove", "ZCFpv_Freeze", function(cmd)
	if not linked and not IsValid(linkedDrone) then return end
	if IsValid(linkedDrone) and linkedDrone:GetClass() == "ent_zc_fpv_mavic" then
		local sens = 0.055
		mavicPitch = math.Clamp(mavicPitch + cmd:GetMouseY() * sens, -45, 95)
		mavicYaw = math.NormalizeAngle(mavicYaw - cmd:GetMouseX() * sens)
	end
	cmd:SetForwardMove(0)
	cmd:SetSideMove(0)
	cmd:SetUpMove(0)
end)

hook.Add("PlayerBindPress", "ZCFpv_Block", function(ply, bind, pressed)
	if not linked and not IsValid(ZCFpv.GetLinkedDrone(ply)) then return end
	if bind == "invnext" or bind == "invprev" or bind == "slot1" or bind == "slot2" or bind == "slot3" or bind == "slot4" or bind == "slot5" or bind == "slot6" then
		return true
	end
end)

hook.Add("HUDPaint", "ZCFpv_Payload", function()
	local ply = LocalPlayer()
	local now = CurTime()

	if payloadNoticeUntil > now then
		if payloadNotice == "BOTTOM PAYLOAD RELEASED" then
			surface.SetMaterial(dropMat)
			surface.SetDrawColor(255, 255, 255, 255)
			surface.DrawTexturedRect(ScrW() * 0.5 - 128, ScrH() * 0.72 - 64, 256, 128)
		else
			draw.SimpleTextOutlined(payloadNotice, "DermaLarge", ScrW() * 0.5, ScrH() * 0.72, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, color_black)
		end
	end

	local hudDrone = IsValid(linkedDrone) and linkedDrone or ZCFpv.GetLinkedDrone(ply)
	if IsValid(hudDrone) then
		local jam = hudDrone:GetNWFloat("ZCFpvJam", 0)
		if jam > 0.05 then
			local col = Color(255, math.floor(180 * (1 - jam)), 35)
			--draw.SimpleTextOutlined("EW JAM " .. math.floor(jam * 100) .. "%", "DermaDefaultBold", ScrW() * 0.5, 32, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, color_black)
		end
	end

	if linked or IsValid(linkedDrone) then return end
	if GetViewEntity() ~= ply or ply:InVehicle() then return end

	local wep = ply:GetActiveWeapon()
	if not ZCFpv.IsPayloadGrenade(wep) then return end
	if wep.SpoonTime then return end

	local tr = hg and hg.eyeTrace and hg.eyeTrace(ply, 320)
	if not tr or not IsValid(tr.Entity) then
		tr = util.TraceLine({
			start = ply:EyePos(),
			endpos = ply:EyePos() + ply:GetAimVector() * 320,
			filter = ply,
			mask = MASK_SHOT,
		})
	end
	if not tr or not IsValid(tr.Entity) then return end

	local drone = tr.Entity
	if drone:GetClass() ~= "ent_zc_fpv_mavic" or IsValid(drone:GetNWEntity("ZCFpvPayload")) then return end

	local toScreen = tr.HitPos:ToScreen()
	local x, y = toScreen.x, toScreen.y
	draw.SimpleText("SHIFT+E - закрепить", "DermaDefaultBold", x + 1, y + 26, color_black, TEXT_ALIGN_CENTER)
	draw.SimpleText("SHIFT+E - закрепить", "DermaDefaultBold", x, y + 25, colRed, TEXT_ALIGN_CENTER)
end)

local function findAttachMavic(ply)
	local tr = hg and hg.eyeTrace and hg.eyeTrace(ply, 320)
	if not tr or not IsValid(tr.Entity) then
		tr = util.TraceLine({
			start = ply:EyePos(),
			endpos = ply:EyePos() + ply:GetAimVector() * 320,
			filter = ply,
			mask = MASK_SHOT,
		})
	end
	if tr and IsValid(tr.Entity) and tr.Entity:GetClass() == "ent_zc_fpv_mavic" then
		return tr.Entity
	end

	local best, bestDot
	for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), 300)) do
		if ent:GetClass() == "ent_zc_fpv_mavic" then
			local dir = ent:WorldSpaceCenter() - ply:EyePos()
			local len = dir:Length()
			if len > 1 then
				local d = ply:GetAimVector():Dot(dir / len)
				if d >= 0.82 and (not bestDot or d > bestDot) then
					best, bestDot = ent, d
				end
			end
		end
	end
	return best
end

local function tryAttachPayload()
	local ply = LocalPlayer()
	if not IsValid(ply) or linked or IsValid(linkedDrone) then return end
	if GetViewEntity() ~= ply or ply:InVehicle() then return end
	if not ply:KeyDown(IN_SPEED) then return end
	if gui.IsGameUIVisible() or ply:IsTyping() then return end

	local wep = ply:GetActiveWeapon()
	if not ZCFpv.IsPayloadGrenade(wep) or wep.SpoonTime then return end

	local drone = findAttachMavic(ply)
	if not IsValid(drone) or IsValid(drone:GetNWEntity("ZCFpvPayload")) then return end

	local now = CurTime()
	if attachSent and now < attachSentAt + 0.45 then return end
	attachSent = true
	attachSentAt = now
	net.Start("zc_fpv_attach_rgd")
		net.WriteEntity(drone)
	net.SendToServer()
end

local wasAttachUse = false
hook.Add("CreateMove", "ZCFpv_AttachPayload", function(cmd)
	local use = cmd:KeyDown(IN_USE)
	local pressed = use and not wasAttachUse
	wasAttachUse = use
	if not pressed or not cmd:KeyDown(IN_SPEED) then return end
	tryAttachPayload()
end)

hook.Add("PlayerButtonDown", "ZCFpv_AttachPayload", function(ply, btn)
	if ply ~= LocalPlayer() or btn ~= KEY_E then return end
	tryAttachPayload()
end)
