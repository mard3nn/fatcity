-- TPIK: third-person inverse kinematics (client)

local math, Vector, Angle, util, IsValid, CurTime, game, FrameTime, LerpAngle, LerpVector =
	math, Vector, Angle, util, IsValid, CurTime, game, FrameTime, LerpAngle, LerpVector
local math_Clamp, math_Approach, math_NormalizeAngle = math.Clamp, math.Approach, math.NormalizeAngle
local LocalToWorld, WorldToLocal = LocalToWorld, WorldToLocal
local vecUpX, vecUpY, vecUpZ = Vector(1, 0, 0), Vector(0, 1, 0), Vector(0, 0, 1)
local vecZero, angZero = Vector(0, 0, 0), Angle(0, 0, 0)
local HAND_REACH = 38

----------------------------------------------------------------
-- Bone tables
----------------------------------------------------------------

local FINGER_SUFFIX = {"", "1", "2"}

local function makeFingerBones(side)
	local list = {"ValveBiped.Bip01_" .. side .. "_Hand"}
	for i = 4, 0, -1 do
		for _, suf in ipairs(FINGER_SUFFIX) do
			list[#list + 1] = ("ValveBiped.Bip01_%s_Finger%d%s"):format(side, i, suf)
		end
	end
	return list
end

local function addFingerAliases(dict, side, targetSide, translate)
	targetSide = targetSide or side
	local map = function(src, dst)
		dict[src] = dst
	end

	local valve = function(s, name) return "ValveBiped.Bip01_" .. s .. "_" .. name end
	local short = function(s, name) return s .. " " .. name end
	local bip = function(s, name) return "Bip01 " .. s .. " " .. name end

	local srcSide, dstSide = side, targetSide
	map(valve(srcSide, "Hand"), valve(dstSide, "Hand"))
	map(short(srcSide, "Hand"), valve(dstSide, "Hand"))
	map(bip(srcSide, "Hand"), valve(dstSide, "Hand"))

	for i = 0, 4 do
		for _, suf in ipairs(FINGER_SUFFIX) do
			local name = ("Finger%d%s"):format(i, suf)
			map(valve(srcSide, name), valve(dstSide, name))
			map(short(srcSide, name), valve(dstSide, name))
			map(bip(srcSide, name), valve(dstSide, name))
		end
	end
end

local TPIKBonesRH = makeFingerBones("R")
local TPIKBonesLH = makeFingerBones("L")

local TPIKBones = {
	"ValveBiped.Bip01_L_Wrist", "ValveBiped.Bip01_L_Ulna",
}
for _, b in ipairs(TPIKBonesLH) do TPIKBones[#TPIKBones + 1] = b end
TPIKBones[#TPIKBones + 1] = "ValveBiped.Bip01_R_Wrist"
TPIKBones[#TPIKBones + 1] = "ValveBiped.Bip01_R_Ulna"
for _, b in ipairs(TPIKBonesRH) do TPIKBones[#TPIKBones + 1] = b end

local TPIKBonesTranslate = {}
for _, b in ipairs(TPIKBonesLH) do TPIKBonesTranslate[b] = b end
for _, b in ipairs(TPIKBonesRH) do TPIKBonesTranslate[b] = b end

local TPIKBonesRHDict, TPIKBonesLHDict, TPIKBonesRHDictTranslate = {}, {}, {}
addFingerAliases(TPIKBonesRHDict, "R", "R")
addFingerAliases(TPIKBonesLHDict, "L", "L")
addFingerAliases(TPIKBonesRHDictTranslate, "R", "L")

hg.TPIKBones = TPIKBones
hg.TPIKBonesTranslate = TPIKBonesTranslate
hg.TPIKBonesRH = TPIKBonesRH
hg.TPIKBonesLH = TPIKBonesLH
hg.TPIKBonesRHDict = TPIKBonesRHDict
hg.TPIKBonesLHDict = TPIKBonesLHDict
hg.TPIKBonesRHDictTranslate = TPIKBonesRHDictTranslate
hg.TPIKBonesOther = {
	"ValveBiped.Bip01_R_Clavicle",
	"ValveBiped.Bip01_R_UpperArm",
	"ValveBiped.Bip01_R_Forearm",
	"ValveBiped.Bip01_L_Clavicle",
	"ValveBiped.Bip01_L_UpperArm",
	"ValveBiped.Bip01_L_Forearm",
}

----------------------------------------------------------------
-- Shared helpers
----------------------------------------------------------------

local function clampHandPos(pos, oldpos, reach)
	reach = reach or HAND_REACH
	pos.x = math_Clamp(pos.x, oldpos.x - reach, oldpos.x + reach)
	pos.y = math_Clamp(pos.y, oldpos.y - reach, oldpos.y + reach)
	pos.z = math_Clamp(pos.z, oldpos.z - reach, oldpos.z + reach)
	return pos
end

local function dragHand(ply, self, boneName, ikFlag, pos, basisAng, localAng, oldKey)
	if not IsValid(ply) or not pos then return end

	local spine = ply:LookupBone("ValveBiped.Bip01_Spine4")
	if not spine then return end

	local bone = ply:LookupBone(boneName)
	local mat = bone and ply:GetBoneMatrix(bone)
	if not mat then return end

	self[ikFlag] = true

	local oldpos = mat:GetTranslation()
	clampHandPos(pos, oldpos)

	if basisAng then
		local p, a = LocalToWorld(vecZero, localAng or angZero, pos, basisAng)
		mat:SetTranslation(p)
		mat:SetAngles(a)
	else
		mat:SetTranslation(pos)
	end

	hg.bone_apply_matrix(ply, bone, mat)
	ply[oldKey] = pos - oldpos
end

----------------------------------------------------------------
-- FABRIK
----------------------------------------------------------------

local function fabriqBackward(final, segments)
	local inverse = {}
	for i = #final, 1, -1 do
		if i == #final then
			inverse[i] = segments[i]
		else
			local nextpos = inverse[i + 1].Pos
			inverse[i] = {
				Pos = nextpos + (final[i].Pos - nextpos):GetNormalized() * final[i].Len,
				Len = segments[i].Len,
			}
		end
	end
	return inverse
end

local function fabriqForward(inverse, segments)
	local fwd = {}
	for i = 1, #inverse do
		if i == 1 then
			fwd[i] = segments[i]
		else
			local prev = fwd[i - 1].Pos
			fwd[i] = {
				Pos = prev + (inverse[i].Pos - prev):GetNormalized() * segments[i - 1].Len,
				Len = segments[i].Len,
			}
		end
	end
	return fwd
end

local function solve(segments, iter)
	local final = {}
	for i = 1, #segments do
		final[i] = segments[i]
	end

	for _ = 1, iter do
		final = fabriqBackward(final, segments)
		final = fabriqForward(final, segments)
	end

	if segments[1].Pos:DistToSqr(segments[#segments].Pos) < 225 then
		final = fabriqBackward(final, segments)
	end

	return final
end

hg.IKSolve = solve

local function quatFromDiff(diff, twist)
	local angrr = diff:Angle()
	local q = Quaternion()
	q = q * Quaternion():SetAngleAxis(angrr.y, vecUpZ)
	q = q * Quaternion():SetAngleAxis(angrr.p, vecUpY)
	q = q * Quaternion():SetAngleAxis(twist, vecUpX)
	return q:Angle(), angrr
end

----------------------------------------------------------------
-- Arm IK configs (L / R)
----------------------------------------------------------------

local ARM_R = {
	upper = "ValveBiped.Bip01_R_UpperArm",
	forearm = "ValveBiped.Bip01_R_Forearm",
	hand = "ValveBiped.Bip01_R_Hand",
	ulna = "ValveBiped.Bip01_R_Ulna",
	wrist = "ValveBiped.Bip01_R_Wrist",
	segments = "segmentsr",
	lerp = "lerp_rh",
	last = "last_rh",
	hold = "rhold",
	hitLerp = "lerpedsegmenthit",
	hitNormal = "oldhitnormal",
	poleHook = "IKPoleRightArm",
	poleRight = 25,
	poleUp = -20,
	poleFwd = -20,
	upperTwist = function(angrr, eyeang)
		return -120 + angrr.y - eyeang.y + eyeang.r
	end,
	forearmTwist = function(angrr, eyeang)
		return -120 - angrr.r + eyeang.r - math_NormalizeAngle(eyeang.y - angrr.y) * math_NormalizeAngle(angrr.p) / 90
	end,
	wristRotate = function(eyeang, handAng)
		return math_NormalizeAngle(-eyeang.r + handAng.r + math_NormalizeAngle(eyeang.y - handAng.y) * math_NormalizeAngle(handAng.p) / 90 - 90)
	end,
	ulnaAdd = -30,
	wristAdd = -30,
}

local ARM_L = {
	upper = "ValveBiped.Bip01_L_UpperArm",
	forearm = "ValveBiped.Bip01_L_Forearm",
	hand = "ValveBiped.Bip01_L_Hand",
	ulna = "ValveBiped.Bip01_L_Ulna",
	wrist = "ValveBiped.Bip01_L_Wrist",
	segments = "segmentsl",
	lerp = "lerp_lh",
	last = "last_lh",
	hold = "lhold",
	hitLerp = "lerpedsegmenthit2",
	hitNormal = "oldhitnormal2",
	poleHook = "IKPoleLeftArm",
	poleRight = -25,
	poleUp = -20,
	poleFwd = 0,
	upperTwist = function(angrr, eyeang)
		return -30 + angrr.y - eyeang.y + eyeang.r
	end,
	forearmTwist = function(angrr, eyeang)
		return -60 - angrr.r + eyeang.r - math_NormalizeAngle(eyeang.y - angrr.y) * math_NormalizeAngle(angrr.p) / 90
	end,
	wristRotate = function(eyeang, handAng)
		return math_NormalizeAngle(-eyeang.r + handAng.r + math_NormalizeAngle(eyeang.y - handAng.y) * math_NormalizeAngle(handAng.p) / 90 - 45)
	end,
	ulnaAdd = 0,
	wristAdd = 0,
	brokenArm = true,
}

local function ensureSegments(ply, key)
	local segs = ply[key]
	if not segs then
		segs = {
			{Pos = Vector(), Len = 0},
			{Pos = Vector(), Len = 0},
		}
		ply[key] = segs
	end
	return segs
end

local function rebuildArmSegments(ply, ent, cfg, upperMat, handMat, handMatOld, spinepos, eyeang, limblength, lerp, wep)
	local segments = ensureSegments(ply, cfg.segments)
	local eye = -(-eyeang)
	eye.p = math_NormalizeAngle(eye.p) * 0.5

	segments[1].Pos = upperMat:GetTranslation()
	segments[1].Len = limblength
	segments[2].Pos = spinepos + eye:Right() * cfg.poleRight + eye:Up() * cfg.poleUp - eye:Forward() * cfg.poleFwd
	segments[2].Len = limblength

	local tr = util.TraceLine({
		start = segments[1].Pos,
		endpos = segments[2].Pos,
		filter = {ent, ply},
		mask = MASK_SOLID_BRUSHONLY,
	})

	ply[cfg.hitLerp] = LerpFT(0.08, ply[cfg.hitLerp] or 0, 1 - tr.Fraction)
	ply[cfg.hitNormal] = LerpAngleFT(0.08, ply[cfg.hitNormal] or tr.HitNormal:Angle(), tr.Hit and tr.HitNormal:Angle() or ply[cfg.hitNormal] or Angle())

	local hitAmt = ply[cfg.hitLerp] or 0
	if hitAmt > 0.01 and ply[cfg.hitNormal] then
		local hitnormal = ply[cfg.hitNormal]:Forward()
		local angleFactor = math.sin(math.acos(math_Clamp(hitnormal:Dot(tr.Normal), -1, 1)))
		segments[2].Pos = segments[2].Pos + hitnormal * 20 * hitAmt * angleFactor
	end

	local newpos = hook.Run(cfg.poleHook, ply, ent, segments[2].Pos, segments)
	if newpos then
		segments[2].Pos = newpos
	end

	local hand = handMat:GetTranslation()
	local lastMat = ply[cfg.last]
	local holdMat = handMatOld

	if cfg.brokenArm and ply.organism and ply.organism.larm and ply.organism.larm > 0.99 and ishgweapon(wep) and not wep.reload then
		segments[3] = segments[3] or {Pos = hand, Len = limblength}
		local drift = (-vector_up * 0.6 + eye:Forward() * 0.4 + ((not wep:IsPistolHoldType()) and eye:Right() * 0.7 or vector_origin) + ent:GetVelocity() / 400) * 0.5
		local rate = (not wep:IsPistolHoldType()) and 0.05 or 0.01
		segments[3].Pos = LerpVector(rate, segments[3].Pos + drift, hand)
	else
		local fallback = (segments[3] and segments[3].Pos) or hand
		local fromLast = lastMat and lastMat:GetTranslation() or fallback
		local fromHold = holdMat and holdMat:GetTranslation() or hand
		segments[3] = {
			Pos = Lerp(1 - lerp, fromLast, fromHold),
			Len = 12,
		}
	end

	if IsValid(lply) and lply:IsSuperAdmin() then
		for i = 2, #segments do
			debugoverlay.Line(segments[i - 1].Pos, segments[i].Pos, 0, color_white, true)
		end
	end

	ply[cfg.segments] = solve(segments, 4)
	return ply[cfg.segments]
end

local function applyWristBones(ent, ang, angrotate, ulnaBone, wristBone, ulnaAdd, wristAdd)
	if ulnaBone then
		local wmat = ent:GetBoneMatrix(ulnaBone)
		if wmat then
			local a = Angle(ang)
			a:RotateAroundAxis(a:Forward(), angrotate * 0.5 + ulnaAdd)
			wmat:SetAngles(a)
			ent:SetBoneMatrix(ulnaBone, wmat)
			ang = a
		end
	end

	if wristBone then
		local wmat = ent:GetBoneMatrix(wristBone)
		if wmat then
			ang:RotateAroundAxis(ang:Forward(), angrotate * 0.5 + wristAdd)
			wmat:SetAngles(ang)
			ent:SetBoneMatrix(wristBone, wmat)
		end
	end
end

local function solveArm(ply, ent, cfg, eyeang, spinepos, limblength, lerp, shouldrebuild, wep)
	if lerp == 0 then return end

	local upperIdx = ent:LookupBone(cfg.upper)
	local forearmIdx = ent:LookupBone(cfg.forearm)
	local handIdx = ent:LookupBone(cfg.hand)
	if not upperIdx or not forearmIdx or not handIdx then return end

	local upperMat = ent:GetBoneMatrix(upperIdx)
	local forearmMat = ent:GetBoneMatrix(forearmIdx)
	local handMat = ent:GetBoneMatrix(handIdx)
	local handMatOld = ply[cfg.hold]
	if not upperMat or not forearmMat or not handMat then return end

	local ulnaIdx = ent:LookupBone(cfg.ulna)
	local wristIdx = ent:LookupBone(cfg.wrist)

	local segments = ply[cfg.segments]
	if shouldrebuild or not segments or not segments[3] then
		segments = rebuildArmSegments(ply, ent, cfg, upperMat, handMat, handMatOld, spinepos, eyeang, limblength, lerp, wep)
	end
	if not segments or not segments[3] then return end

	local handPos = -(-segments[3].Pos)

	upperMat:SetTranslation(segments[1].Pos)
	forearmMat:SetTranslation(segments[2].Pos)
	handMat:SetTranslation(handPos)

	local diffUpper = (segments[2].Pos - segments[1].Pos):GetNormalized()
	local upperAng = quatFromDiff(diffUpper, cfg.upperTwist(diffUpper:Angle(), eyeang))
	upperMat:SetAngles(upperAng)

	local diffFore = (segments[3].Pos - segments[2].Pos):GetNormalized()
	local forearmAng = quatFromDiff(diffFore, cfg.forearmTwist(diffFore:Angle(), eyeang))
	forearmMat:SetAngles(forearmAng)

	if cfg.brokenArm and ply.organism and ply.organism.larm and ply.organism.larm > 0.99 and ishgweapon(wep) and not wep.reload then
		local ang = Angle(forearmAng)
		ang:RotateAroundAxis(ang:Forward(), 95)
		handMat:SetAngles(LerpAngle(0.5, handMat:GetAngles(), ang))
	end

	hg.bone_apply_matrix(ent, upperIdx, upperMat, forearmIdx)
	hg.bone_apply_matrix(ent, forearmIdx, forearmMat, handIdx)
	hg.bone_apply_matrix(ent, handIdx, handMat)

	if IsValid(ply.OldRagdoll) then
		hg.bone_apply_matrix(ply, upperIdx, upperMat, forearmIdx)
		hg.bone_apply_matrix(ply, forearmIdx, forearmMat, handIdx)
		hg.bone_apply_matrix(ply, handIdx, handMat)
	end

	local angrotate = cfg.wristRotate(eyeang, handMat:GetAngles())
	applyWristBones(ent, Angle(forearmAng), angrotate, ulnaIdx, wristIdx, cfg.ulnaAdd, cfg.wristAdd)
end

----------------------------------------------------------------
-- Main DoTPIK
----------------------------------------------------------------

function hg.DoTPIK(ply, ent)
	local headIdx = ent:LookupBone("ValveBiped.Bip01_Head1")
	if not headIdx then return end

	local headMat = ent:GetBoneMatrix(headIdx)
	if not headMat then return end

	local upperL = ent:LookupBone("ValveBiped.Bip01_L_UpperArm")
	local upperR = ent:LookupBone("ValveBiped.Bip01_R_UpperArm")
	local forearmL = ent:LookupBone("ValveBiped.Bip01_L_Forearm")
	local forearmR = ent:LookupBone("ValveBiped.Bip01_R_Forearm")
	local handL = ent:LookupBone("ValveBiped.Bip01_L_Hand")
	local handR = ent:LookupBone("ValveBiped.Bip01_R_Hand")
	if not (upperL and upperR and forearmL and forearmR and handL and handR) then return end

	local handLMat = ent:GetBoneMatrix(handL)
	local handRMat = ent:GetBoneMatrix(handR)
	if not handLMat or not handRMat then return end

	local _, eyeang = LocalToWorld(
		vector_origin,
		ply:InVehicle() and LerpAngle(0.5, ply:EyeAngles(), angle_zero) or ply:EyeAngles(),
		vector_origin,
		(IsValid(ply:GetVehicle()) and hg.IsLocal(ply) and ply:GetVehicle():GetAngles()) or angle_zero
	)

	local wep = ply:GetActiveWeapon()
	local lhikWant = ((IsValid(wep) and wep.lhandik) or ply:InVehicle()) and hg.CanUseLeftHand(ply)
	local rhikWant = ((IsValid(wep) and wep.rhandik) or ply:InVehicle()) and hg.CanUseRightHand(ply)

	if rhikWant then ply.last_rh = handRMat end
	if lhikWant then ply.last_lh = handLMat end

	local rate = FrameTime() * 2.5 * game.GetTimeScale()
	ply.lerp_lh = math_Approach(ply.lerp_lh or 0, lhikWant and 1 or 0, rate)
	ply.lerp_rh = math_Approach(ply.lerp_rh or 0, rhikWant and 1 or 0, rate)

	local lerp_lh = math.ease.InOutSine(ply.lerp_lh)
	local lerp_rh = math.ease.InOutSine(ply.lerp_rh)

	ply.lhold = nil
	ply.rhold = nil

	if lerp_lh == 0 and lerp_rh == 0 then
		if IsValid(wep) then
			wep.lhandik = false
			wep.rhandik = false
		end
		return
	end

	local limblength = ply:BoneLength(forearmL)
	if not limblength or limblength == 0 then limblength = 12 end

	local spinepos = headMat:GetTranslation()
	local shouldrebuild = (ply.nextrebuild or 0) < CurTime()
	if shouldrebuild then
		ply.nextrebuild = CurTime()
	end

	if lerp_rh ~= 0 then
		solveArm(ply, ent, ARM_R, eyeang, spinepos, limblength, lerp_rh, shouldrebuild, wep)
	end

	if lerp_lh ~= 0 then
		solveArm(ply, ent, ARM_L, eyeang, spinepos, limblength, lerp_lh, shouldrebuild, wep)
	end

	if IsValid(wep) then
		wep.lhandik = false
		wep.rhandik = false
	end
end

-- Compatibility stubs
function hg._DeprecatedDoTPIK(ply, ent)
	return hg.DoTPIK(ply, ent)
end

function hg.Solve2PartIK(start_p, end_p, length0, length1, mat0, mat1, sign, torsomat, angs, ang)
	-- Legacy 2-bone solver kept for API compatibility; prefer FABRIK via hg.DoTPIK.
	local length2 = (start_p - end_p):Length()
	local prev_ang0 = Quaternion():SetMatrix(mat0)
	local prev_ang1 = Quaternion():SetMatrix(mat1)

	local cosAngle0 = math_Clamp(((length2 * length2) + (length0 * length0) - (length1 * length1)) / (2 * length2 * length0), -1, 1)
	local angle0 = -math.deg(math.acos(cosAngle0))
	local cosAngle1 = math_Clamp(((length1 * length1) + (length0 * length0) - (length2 * length2)) / (2 * length1 * length0), -1, 1)
	local angle1 = -math.deg(math.acos(cosAngle1))

	local diff = (end_p - start_p)
	diff:Normalize()
	local angle2 = math.deg(math.atan2(-math.sqrt(diff.x * diff.x + diff.y * diff.y), diff.z)) - 90
	local angle3 = math_NormalizeAngle(-math.deg(math.atan2(diff.x, diff.y)) - 90)

	local torsoright = angs.y - angs.r + 120 * sign
	local diffa2 = 90 + (sign > 0 and -30 or 30)

	local Joint0 = Angle(angle0 + angle2, angle3, 0)
	Joint0:RotateAroundAxis(Joint0:Forward(), diffa2 + 15)
	Joint0:RotateAroundAxis(diff, angle3 - torsoright)
	prev_ang0:SetAngle(Joint0)

	local Joint1 = Angle(angle0 + angle2 + 180 + angle1, angle3, 0)
	Joint1:RotateAroundAxis(Joint1:Forward(), diffa2 + 30)
	Joint1:RotateAroundAxis(diff, angle3 - torsoright)
	prev_ang1:SetAngle(Joint1)

	local j0 = start_p + prev_ang0:Angle():Forward() * length0
	local j1 = j0 + prev_ang1:Angle():Forward() * length1
	return j0, j1, prev_ang0:Angle(), prev_ang1:Angle()
end

----------------------------------------------------------------
-- Main entry
----------------------------------------------------------------

local ang_head1, ang_head2 = Angle(-90, 0, 220), Angle(-90, 0, -30)

function hg.MainTPIKFunction(ent, ply, wpn)
	if not IsValid(ply) or not ply:IsPlayer() or not ply.InVehicle then return end

	if hg.ShouldTPIK(ply) then
		if IsValid(wpn) and wpn.SetHandPos then
			wpn:SetHandPos()
		end

		if ply:InVehicle() then
			local Car = ply.IsDrivingSimfphys and ply.GetSimfphys and ply:IsDrivingSimfphys() and IsValid(ply:GetSimfphys()) and ply:GetSimfphys()
				or (ply.GlideGetVehicle and IsValid(ply:GlideGetVehicle()) and ply:GlideGetSeatIndex() == 1 and ply:GlideGetVehicle())
				or ply:GetVehicle()

			if IsValid(Car) and IsValid(wpn) and not wpn.reload then
				Car:SetupBones()
				local bone, adjust = hg.GetCarSteering(Car)
				if bone and Car:GetBoneMatrix(bone) then
					local pos, ang = Car:GetBoneMatrix(bone):GetTranslation(), Car:GetBoneMatrix(bone):GetAngles()
					pos, ang = LocalToWorld(adjust[1], adjust[2], pos, ang)
					wpn.lhandik = true
					hg.DragLeftHand_Ex(ent, wpn, pos, ang)

					if adjust[3] then
						pos, ang = Car:GetBoneMatrix(bone):GetTranslation(), Car:GetBoneMatrix(bone):GetAngles()
						pos, ang = LocalToWorld(adjust[3], adjust[4], pos, ang)
						ply.lerp_rh = 1
						wpn.rhandik = true
						hg.DragRightHand_Ex(ent, wpn, pos, ang)
					end
				end
			end
		end

		hg.FlashlightPos(ply)

		if IsValid(wpn) and wpn:GetClass() ~= "weapon_hands_sh" and IsValid(ply:GetNetVar("carryent2")) then
			hg.DragHands(ply, wpn)
		end

		if IsValid(wpn) and wpn:GetClass() == "weapon_hands_sh" and ply:GetNetVar("headcrab") then
			local headBone = ply:LookupBone("ValveBiped.Bip01_Head1")
			local bone_matrix = headBone and ent:GetBoneMatrix(headBone)
			if bone_matrix then
				local pos, ang = bone_matrix:GetTranslation(), bone_matrix:GetAngles()
				hg.DragHandsToPos(ply, ply:GetActiveWeapon(), pos + ang:Right() * 7 - ang:Forward() * 5, true, 5.5, ang:Right(), ang_head1, ang_head2)
			end
		end

		hg.DoZManip(ent, ply)
		hg.DoTPIK(ply, ent)
	end

	-- Stamina hand shake on ragdoll character
	if ent ~= ply and ent.organism and ent.organism.stamina and ent.organism.stamina[1] then
		local stammul = math_Clamp(1 - ent.organism.stamina[1] / 90, 0, 1)
		local fingerR = ent:LookupBone("ValveBiped.Bip01_R_Finger11")
		local fingerL = ent:LookupBone("ValveBiped.Bip01_L_Finger11")

		if fingerR and ent:GetManipulateBoneAngles(fingerR)[2] < 0 then
			local rh = ent:LookupBone("ValveBiped.Bip01_R_Hand")
			local rhmat = rh and ent:GetBoneMatrix(rh)
			if rhmat then
				rhmat:SetTranslation(rhmat:GetTranslation() + VectorRand(-0.2, 0.2) * stammul)
				hg.bone_apply_matrix(ent, rh, rhmat)
			end
		end

		if fingerL and ent:GetManipulateBoneAngles(fingerL)[2] < 0 then
			local lh = ent:LookupBone("ValveBiped.Bip01_L_Hand")
			local lhmat = lh and ent:GetBoneMatrix(lh)
			if lhmat then
				lhmat:SetTranslation(lhmat:GetTranslation() + VectorRand(-0.2, 0.2) * stammul)
				hg.bone_apply_matrix(ent, lh, lhmat)
			end
		end
	end
end

----------------------------------------------------------------
-- Flashlight
----------------------------------------------------------------

function hg.FlashlightPos(ply)
	if not ply:GetNetVar("flashlight", false) then
		if IsValid(ply.flashlight) then ply.flashlight:Remove() end
		return
	end

	local inv = ply:GetNetVar("Inventory")
	if not inv or not inv["Weapons"] or not inv["Weapons"]["hg_flashlight"] or (ply.organism and ply.organism.larmamputated) then
		if IsValid(ply.flashlight) then ply.flashlight:Remove() end
		if IsValid(ply.flmodel) then ply.flmodel:SetNoDraw(true) end
		return
	end

	local wep = ply:GetActiveWeapon()
	if IsValid(wep) then
		local laser = wep.attachments and wep.attachments.underbarrel
		local attachmentData
		if (laser and not table.IsEmpty(laser)) or wep.laser then
			attachmentData = (laser and not table.IsEmpty(laser)) and hg.attachments.underbarrel[laser[1]] or wep.laserData
		end
		if attachmentData and attachmentData.supportFlashlight then
			if IsValid(ply.flashlight) then ply.flashlight:Remove() end
			return
		end
	end

	if IsValid(ply.FakeRagdoll) then return end
	if not ishgweapon(wep) or wep.reload then return end
	if ply.organism and ply.organism.larmamputated then return end

	local rh = ply:LookupBone("ValveBiped.Bip01_R_Hand")
	local lh = ply:LookupBone("ValveBiped.Bip01_L_Hand")
	local rhmat = rh and ply:GetBoneMatrix(rh)
	local lhmat = lh and ply:GetBoneMatrix(lh)
	if not rhmat or not lhmat then return end

	local veclh, lang
	if ply == lply and ply == GetViewEntity() then
		veclh, lang = hg.FlashlightTransform(ply)
	else
		veclh, lang = hg.FlashlightTransform(ply, false)
	end

	if veclh and lang then
		lhmat:SetTranslation(veclh)
		lhmat:SetAngles(lang)
	end
end

----------------------------------------------------------------
-- Drag helpers
----------------------------------------------------------------

local vec1 = Vector(0, 2, 0)
local vec2 = Vector(0, -2, 0)

function hg.DragHands(ply, self)
	if not IsValid(ply) then return end

	local ply_spine_index = ply:LookupBone("ValveBiped.Bip01_Spine4")
	if not ply_spine_index then return end
	local ply_spine_matrix = ply:GetBoneMatrix(ply_spine_index)
	if not ply_spine_matrix then return end

	local eyetr = hg.eyeTrace(ply)
	local ent = IsValid(ply:GetNetVar("carryent")) and ply:GetNetVar("carryent") or IsValid(ply:GetNetVar("carryent2")) and ply:GetNetVar("carryent2")
	local bon = ply:GetNetVar("carrybone", 0) ~= 0 and ply:GetNetVar("carrybone", 0) or ply:GetNetVar("carrybone2", 0)
	local lpos = IsValid(ent) and ply:GetNetVar("carrypos", nil) or ply:GetNetVar("carrypos2", nil)
	local wep = IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon()
	local twohands = ply:GetNetVar("carrymass", 0) > 15 or (not hg.CanUseLeftHand(ply) and wep and wep:GetClass() == "weapon_hands_sh")

	local pos, norm, TraceResult

	if IsValid(ent) then
		local bone = ent:TranslatePhysBoneToBone(bon)
		local wanted_pos = bone and ent:GetBoneMatrix(bone) or ent:GetPos()

		if lpos then
			if not ent:IsRagdoll() then
				wanted_pos = ent:LocalToWorld(lpos)
			elseif ismatrix(wanted_pos) then
				wanted_pos = LocalToWorld(lpos, angle_zero, wanted_pos:GetTranslation(), wanted_pos:GetAngles())
			end
		elseif ismatrix(wanted_pos) then
			wanted_pos = wanted_pos:GetTranslation()
		end

		local start = ply_spine_matrix:GetTranslation()
		local len = math.min((wanted_pos - start):Length(), 40)
		TraceResult = util.TraceLine({
			start = start,
			endpos = start + (wanted_pos - start):GetNormalized() * len,
			filter = ply,
		})
		pos = TraceResult.HitPos - TraceResult.Normal * 4
		norm = wanted_pos - ply:EyePos()
	end

	local rh, lh = ply:LookupBone("ValveBiped.Bip01_R_Hand"), ply:LookupBone("ValveBiped.Bip01_L_Hand")
	local rhmat, lhmat = rh and ply:GetBoneMatrix(rh), lh and ply:GetBoneMatrix(lh)
	if not pos or not rhmat or not lhmat then return end

	local dot = (pos - ply_spine_matrix:GetTranslation()):GetNormalized():Dot(eyetr.Normal:Angle():Right())

	if wep and not ishgweapon(wep) then
		hg.bone.Set(ply, "spine", vector_origin, Angle(0, 0, -dot * 20), "holding")
		hg.bone.Set(ply, "spine2", vector_origin, Angle(0, 0, -dot * 25), "holding2")
		hg.bone.Set(ply, "head", vector_origin, -Angle(0, 0, -dot * 30), "holding3")
	end

	local amputee = ply.organism and ply.organism.larmamputated
	local posDot = (pos - ply_spine_matrix:GetTranslation()):GetNormalized():Dot(ply_spine_matrix:GetAngles():Forward()) * -50
	local posMul = math_Clamp(-(-posDot / 20), 0.1, 1.5)
	local posMul2 = math_Clamp(-posDot / 20, -1, 1)
	local posMul3 = math_Clamp((-posDot + 30) / 20, 1, 2)
	local ang1 = Angle(-30 * posMul, 5, 70 * -posMul2)
	local ang2 = Angle(-30 * posMul, -5, -120 * -posMul3)

	if twohands or amputee then
		local oldpos = rhmat:GetTranslation()
		clampHandPos(pos, oldpos)

		if norm then
			local p, newang = LocalToWorld(vec2, ang2, pos, norm:Angle())
			rhmat:SetTranslation(p)
			rhmat:SetAngles(newang)
		else
			rhmat:SetTranslation(pos)
		end

		hg.bone_apply_matrix(ply, rh, rhmat)
		ply.oldposrh = pos - oldpos
		self.rhandik = true
	end

	if amputee then return end

	local oldpos = lhmat:GetTranslation()
	clampHandPos(pos, oldpos)

	if norm then
		local p, newang = LocalToWorld(twohands and vec1 or vector_origin, ang1, pos, norm:Angle())
		lhmat:SetTranslation(p)
		lhmat:SetAngles(newang)
	end

	if hg.CanUseLeftHand(ply) then
		hg.bone_apply_matrix(ply, lh, lhmat)
	end
	ply.oldposlh = pos - oldpos
	self.lhandik = true
end

function hg.DragRightHand(ply, self, pos, norm, anglh)
	dragHand(ply, self, "ValveBiped.Bip01_R_Hand", "rhandik", pos, norm and norm:Angle() or nil, anglh, "oldposrh")
end

function hg.DragLeftHand(ply, self, pos, norm, anglh)
	dragHand(ply, self, "ValveBiped.Bip01_L_Hand", "lhandik", pos, norm and norm:Angle() or nil, anglh, "oldposlh")
end

function hg.DragLeftHand_Ex(ply, self, pos, ang, anglh)
	dragHand(ply, self, "ValveBiped.Bip01_L_Hand", "lhandik", pos, ang, anglh, "oldposlh")
end

function hg.DragRightHand_Ex(ply, self, pos, ang, angrh)
	dragHand(ply, self, "ValveBiped.Bip01_R_Hand", "rhandik", pos, ang, angrh, "oldposrh")
end

function hg.DragHandsToPos(ply, self, pos, twohanded, twohanddist, norm, angrh, anglh)
	if not IsValid(ply) or not pos then return end

	local rh, lh = ply:LookupBone("ValveBiped.Bip01_R_Hand"), ply:LookupBone("ValveBiped.Bip01_L_Hand")
	local rhmat, lhmat = rh and ply:GetBoneMatrix(rh), lh and ply:GetBoneMatrix(lh)
	if not rhmat or not lhmat then return end

	self.lhandik = true
	local basis = norm and norm:Angle() or nil

	if twohanded then
		self.rhandik = true
		local oldpos = rhmat:GetTranslation()
		clampHandPos(pos, oldpos)

		if basis then
			local p, newang = LocalToWorld(Vector(0, -(twohanddist or 5), 0), angrh or Angle(0, 0, 180), pos, basis)
			rhmat:SetTranslation(p)
			rhmat:SetAngles(newang)
		else
			rhmat:SetTranslation(pos)
		end

		hg.bone_apply_matrix(ply, rh, rhmat)
		ply.oldposrh = pos - oldpos
	end

	local oldpos = lhmat:GetTranslation()
	clampHandPos(pos, oldpos)

	if basis then
		local p, newang = LocalToWorld(Vector(0, twohanded and (twohanddist or 5) or 0, 0), anglh or angZero, pos, basis)
		lhmat:SetTranslation(p)
		lhmat:SetAngles(newang)
	end

	hg.bone_apply_matrix(ply, lh, lhmat)
	ply.oldposlh = pos - oldpos
end

----------------------------------------------------------------
-- PullLHTowards (compat stub — animation path disabled upstream)
----------------------------------------------------------------

local meta = FindMetaTable("Entity")
function meta:PullLHTowards(towards, timetopull, mdl, offsets, callback)
	local ply = hg.RagdollOwner(self) or self

	if towards == nil then
		ply.pullingTowards = nil
		ply.pullingTowardsStart = nil
		ply.pullingTowardsTime = nil
		ply.pullingTowardsWeapon = nil
		if IsValid(ply.pullingTowardsModel) then
			ply.pullingTowardsModel:Remove()
		end
		ply.pullingTowardsModel = nil
		ply.pullingTowardsOffsets = nil
		return
	end

	if callback then
		timer.Simple(timetopull or 0, function()
			if not IsValid(ply) then return end
			local wep = ply:GetActiveWeapon()
			if IsValid(wep) then
				callback(wep)
			end
		end)
	end
end
