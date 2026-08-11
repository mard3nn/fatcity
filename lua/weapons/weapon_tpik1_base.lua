-- Manual offset-based TPIK weapon base
if SERVER then AddCSLuaFile() end

SWEP.PrintName = "TPIK Base 1"
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

SWEP.WorldModel = "models/nirrti/tablet/tablet_sfm.mdl"
SWEP.ViewModel = ""
SWEP.HoldType = "normal"

SWEP.setrhik = true
SWEP.setlhik = true

SWEP.LHPos = Vector(0, -6.6, 0)
SWEP.LHAng = Angle(0, 0, 180)

SWEP.visualweight = 1.2

SWEP.RHPosOffset = Vector(0, 0, -7.6)
SWEP.RHAngOffset = Angle(0, 0, -90)

SWEP.LHPosOffset = Vector(0, 0, 0)
SWEP.LHAngOffset = Angle(0, 0, 0)

SWEP.handPos = Vector(0, 0, 0)
SWEP.handAng = Angle(0, 0, 0)

SWEP.UsePistolHold = false

SWEP.offsetVec = Vector(6, -7, 0)
SWEP.offsetAng = Angle(0, 90, 180)

SWEP.HeadPosOffset = Vector(15, 1.7, -5)
SWEP.HeadAngOffset = Angle(-90, 0, -90)

SWEP.BaseBone = "ValveBiped.Bip01_Head1"

SWEP.HoldLH = "pistol_hold2"
SWEP.HoldRH = "pistol_hold2"

SWEP.HoldClampMax = 25
SWEP.HoldClampMin = -25

function SWEP:Think()
	if self:GetHoldType() ~= self.HoldType then
		self:SetHoldType(self.HoldType)
	end
	self:AddThink()
end

function SWEP:AddThink()
end

function SWEP:GetWeaponEntity()
	return IsValid(self.model) and self.model or self
end

function SWEP:SetHandPos(noset)
	self.rhandik = self.setrhik
	self.lhandik = self.setlhik

	local ply = self:GetOwner()
	if not IsValid(ply) or not ply:IsPlayer() then return end
	if not IsValid(self:GetWeaponEntity()) then return end
	if not ply.shouldTransmit or ply.NotSeen then return end

	local ent = IsValid(ply.FakeRagdoll) and ply.FakeRagdoll or ply
	if ent ~= ply and not (ply:KeyDown(IN_USE) or (ply:GetNetVar("lastFake", 0) - CurTime() + 5 > 0)) then
		return
	end

	local rh = ply:LookupBone("ValveBiped.Bip01_R_Hand")
	local lh = ply:LookupBone("ValveBiped.Bip01_L_Hand")
	local base = ply:LookupBone(self.BaseBone)
	if not rh or not lh or not base then return end

	local rhmat = ent:GetBoneMatrix(rh)
	local lhmat = ent:GetBoneMatrix(lh)
	local headmat = ent:GetBoneMatrix(base)
	if not rhmat or not lhmat or not headmat then return end

	local headAng = ply:EyeAngles()
	headAng[1] = math.max(math.min(headAng[1], self.HoldClampMax), self.HoldClampMin)

	local headPos, headAng = LocalToWorld(self.HeadPosOffset, self.HeadAngOffset, headmat:GetTranslation(), headAng)
	self.handPos = headPos
	self.handAng = headAng

	local vec1, ang1 = Vector(headPos), Angle(headAng)
	vec1:Add(ang1:Up() * -1)

	local lhang = Angle(ang1)
	lhang:RotateAroundAxis(ang1:Forward(), -90)

	local vec2, ang2 = LocalToWorld(self.LHPos, self.LHAng, vec1, lhang)
	vec1, ang1 = LocalToWorld(self.RHPosOffset, self.RHAngOffset, vec1, ang1)
	vec2, ang2 = LocalToWorld(self.LHPosOffset, self.LHAngOffset, vec2, ang2)

	rhmat:SetTranslation(vec1)
	rhmat:SetAngles(ang1)
	lhmat:SetTranslation(vec2)
	lhmat:SetAngles(ang2)

	hg.set_hold(ent, self.HoldLH)
	hg.set_holdrh(ent, self.HoldRH)

	hg.bone_apply_matrix(ent, rh, rhmat)
	if self.lhandik and hg.CanUseLeftHand(ply) then
		hg.bone_apply_matrix(ent, lh, lhmat)
	end

	self.rhmat = rhmat
	self.lhmat = lhmat

	return rhmat, lhmat
end

function SWEP:DrawWorldModel()
	self.model = IsValid(self.model) and self.model or ClientsideModel(self.WorldModel)
	local WorldModel = self.model
	if not IsValid(WorldModel) then return end

	WorldModel:SetNoDraw(true)

	local owner = self:GetOwner()

	if not IsValid(owner) or owner.NotSeen or not owner.shouldTransmit then
		WorldModel:SetPos(self:GetPos())
		WorldModel:SetAngles(self:GetAngles())
		WorldModel:SetRenderOrigin(self:GetPos())
		WorldModel:SetRenderAngles(self:GetAngles())
		WorldModel:DrawModel()
		return
	end

	if not WorldModel.Modificators then
		WorldModel:SetSkin(self.Skin or 0)
		WorldModel.Modificators = true
	end

	WorldModel:SetModelScale(self.ModelScale or 1)

	local rhmat, lhmat = self:SetHandPos()
	if not rhmat then return end

	local newPos, newAng = LocalToWorld(self.offsetVec, self.offsetAng, rhmat:GetTranslation(), rhmat:GetAngles())
	WorldModel:SetPos(newPos)
	WorldModel:SetAngles(newAng)
	WorldModel:SetRenderOrigin(newPos)
	WorldModel:SetRenderAngles(newAng)
	WorldModel:SetupBones()
	WorldModel:DrawModel()

	if self.lefthandmodel then
		self.model2 = IsValid(self.model2) and self.model2 or ClientsideModel(self.lefthandmodel)
		local LeftModel = self.model2
		LeftModel:SetNoDraw(true)
		LeftModel:SetModelScale(self.ModelScale2 or 1)

		lhmat = lhmat or self.lhmat
		if lhmat then
			local lPos, lAng = LocalToWorld(self.offsetVec2 or vector_origin, self.offsetAng2 or angle_zero, lhmat:GetTranslation(), lhmat:GetAngles())
			LeftModel:SetPos(lPos)
			LeftModel:SetAngles(lAng)
			LeftModel:SetRenderOrigin(lPos)
			LeftModel:SetRenderAngles(lAng)
			LeftModel:SetupBones()

			if not IsValid(owner.FakeRagdoll) and owner:GetActiveWeapon() == self then
				LeftModel:DrawModel()
			end
		end
	end

	self:AddDrawModel(WorldModel)
end

function SWEP:Camera(eyePos, eyeAng, view, vellen)
	self:SetHandPos()
	self:DrawWorldModel()
	view.origin = eyePos - (angle_difference_localvec * 150) - (position_difference * 0.5)
	return view
end

function SWEP:AddDrawModel(ent)
end
