if SERVER then AddCSLuaFile() end

SWEP.PrintName = "TPIK Base"
SWEP.Category = "ZCity Anims items"
SWEP.Instructions = ":3 если вы скриптхукнули знайте вы для нас вонючка."
SWEP.Spawnable = false
SWEP.AdminOnly = true
SWEP.Slot = 1

SWEP.Weight = 0
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo = "none"

SWEP.WorldModel = "models/weapons/zcity/chands_gestures.mdl"
SWEP.WorldModelReal = "models/weapons/zcity/chands_gestures.mdl"
SWEP.WorldModelExchange = false
SWEP.ViewModel = ""
SWEP.HoldType = "slam"

SWEP.supportTPIK = true
SWEP.isTPIKBase = true
SWEP.WorkWithFake = true
SWEP.visualweight = 1.2

SWEP.weaponPos = Vector(0, 0, 0)
SWEP.weaponAng = Angle(0, 0, 0)

SWEP.animtime = 0
SWEP.animspeed = 0
SWEP.cycling = false
SWEP.reverseanim = false
SWEP.AnimList = {}

SWEP.setlh = false
SWEP.setrh = true

SWEP.sprint_ang = Angle(20, 0, 0)
SWEP.sprint_pos = Vector(0, 0, 0)

SWEP.HoldPos = Vector(0, 0, 0)
SWEP.HoldAng = Angle(0, 0, 0)

SWEP.basebone = 1
SWEP.modelscale = 1
SWEP.modelscale2 = 1
SWEP.Initialzed = false
SWEP.tries = 10

if CLIENT then
	SWEP.BounceWeaponIcon = false
end

function SWEP:CanSecondaryAttack()
	return true
end

function SWEP:SetHold(value)
	self:SetWeaponHoldType(value)
	self:SetHoldType(value)
	self.holdtype = value
end

----------------------------------------------------------------
-- Client worldmodel
----------------------------------------------------------------

if CLIENT then
	local vecNearZero = Vector(0.0001, 0.0001, 0.0001)
	local HAND_REACH = 38

	local function ensureWorldModel(self, modelPath, skin)
		if IsValid(self.worldModel) then return self.worldModel end

		local mdl = ClientsideModel(modelPath)
		mdl:SetNoDraw(true)
		mdl:SetSkin(skin or 0)
		self.worldModel = mdl

		self:CallOnRemove("remove_worldmodel1", function()
			if IsValid(mdl) then mdl:Remove() end
		end)

		return mdl
	end

	function SWEP:_applyHandBones(ent, wm, bones, wmpos)
		for _, bone in ipairs(bones) do
			local wmIdx = wm:LookupBone(bone)
			local plyIdx = ent:LookupBone(bone)
			if not wmIdx or not plyIdx then continue end

			local wmMat = wm:GetBoneMatrix(wmIdx)
			local plyMat = ent:GetBoneMatrix(plyIdx)
			if not wmMat or not plyMat then continue end

			local bonepos = wmMat:GetTranslation()
			bonepos.x = math.Clamp(bonepos.x, wmpos.x - HAND_REACH, wmpos.x + HAND_REACH)
			bonepos.y = math.Clamp(bonepos.y, wmpos.y - HAND_REACH, wmpos.y + HAND_REACH)
			bonepos.z = math.Clamp(bonepos.z, wmpos.z - HAND_REACH, wmpos.z + HAND_REACH)

			plyMat:SetTranslation(bonepos)
			plyMat:SetAngles(wmMat:GetAngles())
			ent:SetBoneMatrix(plyIdx, plyMat)
		end
	end

	function SWEP:GetWM()
		return ensureWorldModel(self, self.WorldModel, self.WMSkin)
	end

	function SWEP:DrawWorldModel()
		if not IsValid(self:GetOwner()) then
			self:DrawWorldModel2()
		end
	end

	function SWEP:DrawWorldModel2()
		local owner = self:GetOwner()
		local WorldModel = ensureWorldModel(self, self.WorldModel, self.WMSkin)
		WorldModel:SetNoDraw(true)

		if IsValid(owner) and (not owner.shouldTransmit or owner.NotSeen) then return end
		if not IsValid(owner) and (not self.shouldTransmit or self.NotSeen) then return end

		WorldModel:SetModelScale(self.modelscale2)

		local ent = IsValid(owner) and (IsValid(owner.FakeRagdoll) and owner.FakeRagdoll or owner) or nil
		local heldActive = IsValid(owner) and (ent == owner or hg.KeyDown(owner, IN_USE) or (owner:GetNetVar("lastFake", 0) > CurTime()))

		if heldActive then
			local timing
			if not self.cycling then
				timing = 1 - math.Clamp((self.animtime - CurTime()) / self.animspeed, 0, 1)
				timing = self.reverseanim and (1 - timing) or timing
				timing = self.CustomTiming and self:CustomTiming() or timing
				WorldModel:SetCycle(timing)

				if self.callback and timing == ((not self.reverseanim) and 1 or 0) then
					self.callback(self)
					self.callback = nil
				end
			else
				timing = ((CurTime() - (self.animtime - self.animspeed)) % self.animspeed) / self.animspeed
				WorldModel:SetCycle(timing)
			end

			self.sprintanim = qerp(0.02 * FrameTime() / engine.TickInterval(), self.sprintanim or 0, (owner.IsSprinting and owner:IsSprinting()) and 1 or 0)

			local tr = hg.eyeTrace(owner, 60)
			if not tr then return end

			if WorldModel:GetModel() ~= self.WorldModelReal then
				WorldModel:SetModel(self.WorldModelReal)
			end

			local ang = owner:EyeAngles()
			local pos = tr.StartPos
				+ ang:Forward() * (self.HoldPos[1] - 4)
				+ ang:Right() * self.HoldPos[2]
				+ ang:Up() * self.HoldPos[3]

			_, ang = LocalToWorld(vector_origin, self.HoldAng or angle_zero, vector_origin, ang)
			pos, ang = LocalToWorld(self.sprint_pos * self.sprintanim, self.sprint_ang * self.sprintanim, pos, ang)

			if self.HoldClampMax ~= nil and self.HoldClampMin ~= nil then
				local headAng = owner:EyeAngles()
				ang.x = math.max(math.min(headAng.x, self.HoldClampMax), self.HoldClampMin)
			end

			WorldModel:SetRenderOrigin(pos)
			WorldModel:SetRenderAngles(ang)
		else
			if WorldModel:GetModel() ~= self.WorldModel then
				WorldModel:SetModel(self.WorldModel)
			end
			WorldModel:SetRenderOrigin(self:GetPos())
			WorldModel:SetRenderAngles(self:GetAngles())
		end

		if IsValid(owner) and not heldActive then
			local bon = ent:LookupBone("ValveBiped.Bip01_R_Hand")
			local mat = bon and ent:GetBoneMatrix(bon)
			if not mat then return end

			local pos, ang = LocalToWorld(self.lpos or vector_origin, self.lang or angle_zero, mat:GetTranslation(), mat:GetAngles())
			WorldModel:SetRenderOrigin(pos)
			WorldModel:SetRenderAngles(ang)
		end

		WorldModel:SetupBones()

		if IsValid(self.worldModel2) then
			self.worldModel2:SetNoDraw(true)
		end

		if not self.WorldModelExchange or self.HideMeshBones then
			if self.HideMeshBones then
				for _, boneName in ipairs(self.HideMeshBones) do
					local idx = WorldModel:LookupBone(boneName)
					if not idx then continue end

					local matrix = WorldModel:GetBoneMatrix(idx)
					if not matrix then continue end

					if self.HideMeshOnlyScale and self.HideMeshOnlyScale[boneName] then
						matrix:SetScale(vecNearZero)
					else
						matrix:Zero()
					end
					WorldModel:SetBoneMatrix(idx, matrix)
				end
			end
			WorldModel:DrawModel()
		end

		if self.WorldModelExchange then
			if not IsValid(self.worldModel2) then
				local mdl2 = ClientsideModel(self.WorldModelExchange)
				self.worldModel2 = mdl2
				self:CallOnRemove("remove_worldmodel2", function()
					if IsValid(mdl2) then mdl2:Remove() end
				end)
			end

			local useReal = WorldModel:GetModel() == self.WorldModelReal
			local pos, ang = WorldModel:GetPos(), WorldModel:GetAngles()

			if IsValid(owner) or self.DontChangeDropped then
				local baseIdx = self.basebone or 1
				local baseMat = useReal and WorldModel:GetBoneMatrix(baseIdx)
				pos, ang = LocalToWorld(
					self.weaponPos,
					self.weaponAng,
					baseMat and baseMat:GetTranslation() or WorldModel:GetPos(),
					baseMat and baseMat:GetAngles() or WorldModel:GetAngles()
				)
			end

			self.worldModel2:SetModelScale(self.modelscale)
			self.worldModel2:SetRenderOrigin(pos)
			self.worldModel2:SetRenderAngles(ang)
			self.worldModel2:SetupBones()

			if WorldModel:GetManipulateBoneScale(self.basebone or 1) ~= vector_origin then
				self.worldModel2:DrawModel()
			end
		end

		if self:IsLocal() and self.isTPIKBase then
			local camBone = WorldModel:LookupBone(self.ViewBobCamBone or "Camera_animated")
				or WorldModel:LookupBone("ValveBiped.Bip01_R_Hand")
			if camBone then
				local gAngles = WorldModel:GetBoneMatrix(camBone):GetAngles()
				local baseBone = WorldModel:LookupBone(self.ViewBobCamBase or "") or 0
				local baseMat = WorldModel:GetBoneMatrix(baseBone)
				if baseMat then
					_, gAngles = WorldToLocal(vector_origin, gAngles, WorldModel:GetPos(), baseMat:GetAngles())
					self.OldAngPunch = self.OldAngPunch or gAngles
					ViewPunch((self.OldAngPunch - gAngles) / (self.ViewPunchDiv or 100))
					self.OldAngPunch = gAngles
				end
			end
		end

		if self.DrawPostWorldModel then
			self:DrawPostWorldModel()
		end
	end
end

function hg.RenderTPIKBase(ent, ply, wep)
	if wep.DrawWorldModel2 then
		wep:DrawWorldModel2()
	else
		wep:DrawWorldModel()
	end
end

----------------------------------------------------------------
-- Camera / hands
----------------------------------------------------------------

local host_timescale = game.GetTimeScale

function SWEP:Camera(eyePos, eyeAng, view, vellen)
	self:SetHandPos()
	self:DrawWorldModel2()

	local owner = self:GetOwner()
	self.walkinglerp = Lerp(hg.lerpFrameTime2(0.1), self.walkinglerp or 0, ((self.DisableWalkBob or owner:InVehicle()) and 0) or hg.GetCurrentCharacter(owner):GetVelocity():LengthSqr())
	self.huytime = self.huytime or 0

	local walk = math.Clamp(self.walkinglerp / 10000, 0, 1)
	self.huytime = self.huytime + walk * FrameTime() * 8 * host_timescale()

	local huy = self.huytime
	local x, y = math.cos(huy) * math.sin(huy) * walk, math.sin(huy) * walk

	eyePos = eyePos - eyeAng:Up() * walk - eyeAng:Up() * x * 0.5 - eyeAng:Right() * y * 0.5
	view.origin = eyePos - (angle_difference_localvec * 150) - (position_difference * 0.5)

	return view
end

function SWEP:CanPrimaryAttack()
	return self:GetOwner():IsSprinting()
end

function SWEP:SetHandPos(noset)
	local ply = self:GetOwner()

	self.rhandik = false
	self.lhandik = false

	if SERVER then return end
	if not IsValid(ply) then return end
	if not ply.shouldTransmit or ply.NotSeen then return end

	local wm = self:GetWM()
	if not IsValid(wm) then return end

	local ent = hg.GetCurrentCharacter(ply)
	local ply_spine_index = ent:LookupBone("ValveBiped.Bip01_Spine4")
	if not ply_spine_index then return end

	local ply_spine_matrix = ent:GetBoneMatrix(ply_spine_index)
	if not ply_spine_matrix then return end

	self.rhandik = self.setrh
	self.lhandik = self.setlh and ((ply:GetTable().ChatGestureWeight or 0) < 0.1)

	local rh = ent:LookupBone("ValveBiped.Bip01_R_Hand")
	local lh = ent:LookupBone("ValveBiped.Bip01_L_Hand")
	ply.rhold = rh and ent:GetBoneMatrix(rh)
	ply.lhold = lh and ent:GetBoneMatrix(lh)

	local heldActive = (ent == ply or hg.KeyDown(ply, IN_USE) or (ply:GetNetVar("lastFake", 0) > CurTime()))
	local wmpos = ply_spine_matrix:GetTranslation()

	if heldActive and self._applyHandBones then
		if self.lhandik and hg.CanUseLeftHand(ply) then
			self:_applyHandBones(ent, wm, hg.TPIKBonesLH, wmpos)
		end
		if self.rhandik then
			self:_applyHandBones(ent, wm, hg.TPIKBonesRH, wmpos)
		end
	end

	if self.PostSetHandPos then
		self:PostSetHandPos()
	end
end

----------------------------------------------------------------
-- Lifecycle
----------------------------------------------------------------

function SWEP:SetupDataTables()
end

function SWEP:OwnerChanged()
	if IsValid(self:GetOwner()) and self:GetOwner():IsPlayer() then
		self:PlayAnim("deploy")
		self:SetHold(self.HoldType)
		timer.Simple(0, function()
			if IsValid(self) then self.picked = true end
		end)
	else
		timer.Simple(0, function()
			if IsValid(self) then self.picked = nil end
		end)
	end
end

function SWEP:OnRemove()
	if IsValid(self.worldModel) then
		self.worldModel:Remove()
	end
	if IsValid(self.worldModel2) then
		self.worldModel2:Remove()
	end
end

function SWEP:Deploy()
	if SERVER and self.Initialzed and not self:GetOwner().noSound and self.DeploySnd then
		self:GetOwner():EmitSound(self.DeploySnd, 65)
	end
	self.Initialzed = true
	self:PlayAnim("deploy")
	self:SetHold(self.HoldType)
	return true
end

function SWEP:Holster(wep)
	return true
end

function SWEP:IsEntSoft(ent)
	return ent:IsNPC() or ent:IsPlayer() or hg.RagdollOwner(ent) or ent:IsRagdoll()
end

function SWEP:ThinkAdd()
end

function SWEP:Think()
	if not IsFirstTimePredicted() then return end
	self:SetHold(self.HoldType)
	self:ThinkAdd()
end

function SWEP:PrimaryAttackAdd(ent)
end

function SWEP:SecondaryAttackAdd(ent)
end

function SWEP:PrimaryAttack()
end

function SWEP:SecondaryAttack()
end

function SWEP:InitAdd()
end

function SWEP:Initialize()
	if self.modelscale then
		self:SetModelScale(self.modelscale)
		self:Activate()
	end
	self:SetHold(self.HoldType)
	self:InitAdd()
end

function SWEP:IsLocal()
	if SERVER then return end
	return not ((self:GetOwner() ~= LocalPlayer()) or (LocalPlayer() ~= GetViewEntity()))
end

----------------------------------------------------------------
-- Animations
----------------------------------------------------------------

if SERVER then
	util.AddNetworkString("melee_attack2")
elseif CLIENT then
	net.Receive("melee_attack2", function()
		local tbl = net.ReadTable()
		local ent = net.ReadEntity()
		local sendtoclient = net.ReadBool()
		if IsValid(ent) and ent.PlayAnim and (sendtoclient or not ent:IsLocal()) then
			ent:PlayAnim(tbl.anim, tbl.time, tbl.cycling, tbl.callback, tbl.reverse)
		end
	end)
end

function SWEP:PlayAnim(anim, time, cycling, callbackFuncName, reverse, sendtoclient)
	if SERVER then
		net.Start("melee_attack2")
			net.WriteTable({
				anim = anim,
				time = time,
				cycling = cycling,
				callback = callbackFuncName,
				reverse = reverse,
			})
			net.WriteEntity(self)
			net.WriteBool(true)
		net.SendPVS(self:GetPos())

		local tAnim = self.AnimList[anim] or {}
		self.seq = tAnim[1] or anim
		self.anim = anim
		self.animspeed = time or tAnim[2] or 1

		if self[callbackFuncName] or tAnim[5] then
			local timerAnim = self.animspeed - (tAnim[6] or self.CallbackTimeAdjust or 0)
			self.CallbackTime = CurTime() + timerAnim
			self.callback = self[callbackFuncName] or tAnim[5]

			local idx = self:EntIndex()
			hook.Add("Think", "AnimCallback" .. idx, function()
				if IsValid(self) and IsValid(self:GetOwner()) and self.CallbackTime < CurTime() then
					hook.Remove("Think", "AnimCallback" .. idx)
					self.callback(self)
				end
			end)
		end
		return
	end

	if not IsValid(self:GetWM()) or not IsValid(self:GetOwner()) or self:GetOwner():GetActiveWeapon() ~= self then
		self.tries = self.tries - 1
		if self.tries > 0 then
			timer.Simple(0.01, function()
				if IsValid(self) then
					self:PlayAnim(anim, time, cycling, callbackFuncName, reverse)
				end
			end)
		end
		return
	end

	self.tries = 10

	local mdl = self:GetWM()
	if mdl:GetModel() ~= self.WorldModelReal then
		mdl:SetModel(self.WorldModelReal)
	end

	local tAnim = self.AnimList[anim] or {}
	self.seq = tAnim[1] or anim
	self.anim = anim
	mdl:SetSequence(tAnim[1] or anim)
	self.animtime = CurTime() + (time or tAnim[2] or 1)
	self.animspeed = time or tAnim[2] or 1
	self.cycling = cycling or (tAnim[3] ~= nil and tAnim[3])
	self.reverseanim = reverse or (tAnim[4] ~= nil and tAnim[4])

	if self[callbackFuncName] or tAnim[5] then
		self.callback = self[callbackFuncName] or tAnim[5]
	end

	if self.AnimsEvents and self.AnimsEvents[self.seq] then
		local Time = self.animspeed
		self.VM_TimerEvents = self.VM_TimerEvents or {}

		for k, v in pairs(self.AnimsEvents[self.seq]) do
			local TimerName = "VM_Events_ZC-Base" .. self:EntIndex() .. self.seq .. k
			local TimerID = #self.VM_TimerEvents + 1
			local seq = self.seq

			timer.Create(TimerName, Time * k, 1, function()
				if not IsValid(self) then return end
				if seq ~= self.seq then self:VM_RemoveAllEvents() end
				v(self, mdl)
				self.VM_TimerEvents[TimerID] = nil
			end)

			self.VM_TimerEvents[TimerID] = TimerName
		end
	end
end

if CLIENT then
	function SWEP:VM_RemoveAllEvents()
		if not self.VM_TimerEvents then return end
		for _, name in ipairs(self.VM_TimerEvents) do
			timer.Remove(name)
		end
		table.Empty(self.VM_TimerEvents)
	end
end

----------------------------------------------------------------
-- Fake gun (ragdoll)
----------------------------------------------------------------

function SWEP:SetFakeGun(ent)
	self:SetNWEntity("fakeGun", ent)
	self.fakeGun = ent
end

function SWEP:RemoveFake()
	if not IsValid(self.fakeGun) then return end
	self.fakeGun:Remove()
	self:SetFakeGun()
end

local function GetPhysBoneNum(ent, boneName)
	if not IsValid(ent) then return 7 end
	return ent:TranslateBoneToPhysBone(ent:LookupBone(boneName))
end

function SWEP:CreateFake(ragdoll)
	if IsValid(self:GetNWEntity("fakeGun")) or not IsValid(ragdoll) then return end

	local ent = ents.Create("prop_physics")
	ent.notprop = true

	local physbonerh = GetPhysBoneNum(ragdoll, "ValveBiped.Bip01_R_Hand")
	local rh = ragdoll:GetPhysicsObjectNum(physbonerh)

	ent:SetPos(rh:GetPos())
	ent:SetModel(self.WorldModel)
	ent:Spawn()
	ent:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	ent:SetMoveType(MOVETYPE_NONE)
	ent:GetPhysicsObject():SetMass(0)
	ent:SetNoDraw(true)
	ent.dontPickup = true
	ent.fakeOwner = self

	ragdoll:DeleteOnRemove(ent)
	ragdoll.fakeGun = ent

	if IsValid(ragdoll.ConsRH) then
		ragdoll.ConsRH:Remove()
	end

	self:SetFakeGun(ent)
	ent:CallOnRemove("homigrad-swep", self.RemoveFake, self)
end
