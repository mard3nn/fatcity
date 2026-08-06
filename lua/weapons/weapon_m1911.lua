SWEP.Base = "homigrad_base"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.PrintName = "Colt M1911 rework"
SWEP.Author = "Colt"
SWEP.Instructions = "Pistol chambered in .45 ACP"
SWEP.Category = "Weapons - Pistols"
SWEP.Slot = 2
SWEP.SlotPos = 10
SWEP.ViewModel = ""
SWEP.WorldModel = "models/weapons/w_pist_elite_single.mdl"
SWEP.WorldModelFake = "models/weapons/arc9/darsu_eft/c_m1911.mdl" // ну корочк контент арц9 ефт от дарсу
-- SWEP.GetDebug = false

SWEP.WepSelectIcon2 = Material("entities/arc9_eft_m1911.png")
SWEP.IconOverride = "entities/arc9_eft_m1911.png"
SWEP.WepSelectIcon2box = true
SWEP.FakeBodyGroups = "01111100111"

SWEP.FakeAttachment = "1"
SWEP.FakePos = Vector(-22, 2.2, 9)
SWEP.FakeAng = Angle(0, 0, 3)
SWEP.AttachmentPos = Vector(-0.6,1.2,0.6)
SWEP.AttachmentAng = Angle(0,0,0)
SWEP.MagIndex = nil

SWEP.ModularParts = {
	magazine = {
		model = "models/weapons/arc9/darsu_eft/mods/mag_1911_11.mdl",
		bonemerge = false,
		bone = "mod_magazine",
		pos = Vector(0, 0, 0),
		ang = Angle(0, -90, 0),
	},
}

SWEP.FakeEjectBrassATT = "2"

SWEP.AnimList = {
	["idle"] = "idle",
	["reload"] = "reload1",
	["reload_empty"] = "reload_empty0_1",
	["inspect"] = "inspect",
}

SWEP.CustomShell = "45acp"
SWEP.EjectAng = Angle(0,0,0)

SWEP.weight = 1
SWEP.punchmul = 1.5
SWEP.punchspeed = 3
SWEP.ScrappersSlot = "Secondary"

SWEP.LocalMuzzlePos = Vector(-3.5,0,6.5)
SWEP.LocalMuzzleAng = Angle(0,0,0)
SWEP.WeaponEyeAngles = Angle(0,0,0)

SWEP.weaponInvCategory = 2
SWEP.ShellEject = "EjectBrass_9mm"
SWEP.Primary.ClipSize = 7
SWEP.Primary.DefaultClip = 7
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = ".45 ACP"
SWEP.Primary.Cone = 0
SWEP.Primary.Damage = 25
SWEP.Primary.Sound = {"weapons/newakm/akmm_fp.wav", 75, 90, 100}
SWEP.SupressedSound = {"m9/m9_suppressed_fp.wav", 65, 90, 100}
SWEP.Primary.SoundEmpty = {"zcitysnd/sound/weapons/m1911/handling/m1911_empty.wav", 75, 100, 105, CHAN_WEAPON, 2}
SWEP.Primary.Force = 25
SWEP.Primary.Wait = PISTOLS_WAIT
SWEP.ReloadTime = 3.5
SWEP.FakeReloadSounds = {
	[0.3] = "weapons/universal/uni_pistol_draw_01.wav",
	[0.45] = "weapons/tfa_ins2/usp_tactical/magout.wav",
	[0.55] = "weapons/universal/uni_crawl_l_03.wav",
	[0.6] = "zcitysnd/sound/weapons/m9/handling/m9_magin.wav",
	[0.7] = "zcitysnd/sound/weapons/m9/handling/m9_maghit.wav",
}

SWEP.FakeEmptyReloadSounds = {
	[0.33] = "weapons/tfa_ins2/usp_tactical/magout.wav",
	[0.5] = "weapons/universal/uni_pistol_draw_01.wav",
	[0.65] = "zcitysnd/sound/weapons/m9/handling/m9_magin.wav",
	[0.75] = "zcitysnd/sound/weapons/m9/handling/m9_maghit.wav",
	[0.85] = "weapons/m45/m45_boltrelease.wav",
}

local vecfull = Vector(1,1,1)




SWEP.AnimsEvents = {
	["reload_empty"] = {
		[0.2] = function(self)
			local ent = hg.CreateMag( self, Vector(0,-45,-12), self:GetRandomBodygroups() or "0", true)
			if not IsValid(ent) then return end
			for i = 0, ent:GetBoneCount() - 1 do
				ent:ManipulateBoneScale(i, vector_origin)
			end

			ent:ManipulateBoneScale(54, Vector(1,1,1))
			ent:ManipulateBoneScale(55, Vector(1,1,1))

			local phys = ent:GetPhysicsObject()

			if IsValid(phys) then
				phys:AddAngleVelocity(Vector(-250,0,0))
			end
		end,
		[0.4] = function(self)
		end
	},
	["reload"] = {
		[-1] = function(self)
		end,

		[0.2] = function(self)
		end,

		[0.7] = function(self)
		end
	}
}

SWEP.DeploySnd = {"homigrad/weapons/draw_pistol.mp3", 55, 100, 110}
SWEP.HolsterSnd = {"homigrad/weapons/holster_pistol.mp3", 55, 100, 110}
SWEP.UseCustomWorldModel = true
SWEP.WorldPos = Vector(3, -0.8, 2.6)
SWEP.WorldAng = Angle(0, 0, -1)
SWEP.HoldType = "revolver"
SWEP.ZoomPos = Vector(0, -1.9728, 7.0416)
SWEP.RHandPos = Vector(-13.5, 0, 3)
SWEP.LHandPos = false
SWEP.attPos = Vector(0, -2, -0.5)
SWEP.attAng = Angle(0, 0, 0)
SWEP.SprayRand = {Angle(-0.03, -0.03, 0), Angle(-0.05, 0.03, 0)}
SWEP.Ergonomics = 1.2
SWEP.Penetration = 7
SWEP.lengthSub = 25
SWEP.DistSound = "m9/m9_dist.wav"
SWEP.holsteredBone = "ValveBiped.Bip01_R_Thigh"
SWEP.holsteredPos = Vector(0, 1, -7)
SWEP.holsteredAng = Angle(0, 20, 30)
SWEP.shouldntDrawHolstered = true

SWEP.availableAttachments = {
	barrel = {
		[1] = {"supressor2", Vector(0,0,0), {}},
        ["mount"] = Vector(0.5,0.73,0),
    }
}

--local to head
SWEP.RHPos = Vector(12,-4.5,3)
SWEP.RHAng = Angle(0,-5,90)
--local to rh
SWEP.LHPos = Vector(-1.2,-1.4,-2.8)
SWEP.LHAng = Angle(5,9,-100)

SWEP.ShootAnimMul = 3
SWEP.SightSlideOffset = 0.8

SWEP.FakeViewBobBone = "ValveBiped.Bip01_R_Hand"
SWEP.FakeViewBobBaseBone = "ValveBiped.Bip01_R_Forearm"
SWEP.ViewPunchDiv = 1
SWEP.FakeMagDropBone = "mod_magazine"
SWEP.MagModel = "models/weapons/arccw/c_ur_m1911.mdl"

SWEP.lmagpos = Vector(0,0,0)
SWEP.lmagang = Angle(0,0,0)
SWEP.lmagpos2 = Vector(-12.7,0,-2.4)
SWEP.lmagang2 = Angle(90,0,-110)

function SWEP:PostSetupDataTables()
	self:NetworkVar("String",0,"RandomBodygroups")
	if ( CLIENT ) then
		self:NetworkVarNotify( "RandomBodygroups", self.OnVarChanged )
	end
end

function SWEP:OnVarChanged( name, old, new )
	if !IsValid(self:GetWM()) then return end

	self:GetWM():SetBodyGroups(new)
end


function SWEP:GetModularPartModel(partName, fallback, role)
	if partName == "magazine" then
		return self:GetActiveMagazineModel(fallback, role)
	end
	return fallback
end

function SWEP:DrawModularParts()
	local wm = self:GetWM()
	if not IsValid(wm) then return end

	local parts = self.ModularParts
	if not istable(parts) then return end

	self.ModularHeldPartModels = self.ModularHeldPartModels or {}
	self.ModularHeldPartPaths  = self.ModularHeldPartPaths  or {}
	local positioned = {}

	local function positionPart(partName)
		if positioned[partName] then return positioned[partName] end
		local partData = parts[partName]
		if not istable(partData) then return end

		local modelPath = self:GetModularPartModel(partName, partData.model, "held")
		local model = self.ModularHeldPartModels[partName]
		if not isstring(modelPath) or modelPath == "" then
			if IsValid(model) then model:Remove() end
			self.ModularHeldPartModels[partName] = nil
			self.ModularHeldPartPaths[partName]  = nil
			return
		end
		if IsValid(model) and self.ModularHeldPartPaths[partName] ~= modelPath then
			model:Remove()
			model = nil
		end
		if not IsValid(model) then
			model = ClientsideModel(modelPath, RENDERGROUP_BOTH)
			if not IsValid(model) then return end
			model:SetNoDraw(true)
			self.ModularHeldPartModels[partName] = model
			self.ModularHeldPartPaths[partName]  = modelPath
		end

		local basePos, baseAng
		if partData.parent then
			local parent = positionPart(partData.parent)
			if not IsValid(parent) then return end
			basePos, baseAng = parent:GetPos(), parent:GetAngles()
		else
			local boneID = wm:LookupBone(partData.bone or "")
			local matrix = boneID and wm:GetBoneMatrix(boneID)
			if not matrix then return end
			basePos, baseAng = matrix:GetTranslation(), matrix:GetAngles()
		end

		local partPos = partData.pos or vector_origin
		local partAng = partData.ang or angle_zero
		local pos, ang = LocalToWorld(partPos, partAng, basePos, baseAng)
		pos, ang = self:ApplyManagedStockPartOffset(partName, pos, ang)
		model:SetRenderOrigin(pos)
		model:SetRenderAngles(ang)
		model:SetPos(pos)
		model:SetAngles(ang)
		if partData.skin ~= nil then model:SetSkin(partData.skin) end
		if isstring(partData.bodygroups) then model:SetBodyGroups(partData.bodygroups) end
		model:SetupBones()
		positioned[partName] = model
		return model
	end

	for partName in pairs(parts) do positionPart(partName) end
	for partName in pairs(parts) do
		local model = positioned[partName]
		if IsValid(model) then model:DrawModel() end
	end

	self.HeldMagCSModel = positioned.magazine
end

function SWEP:DrawPost()
	local wep = self:GetWeaponEntity()
	if CLIENT and IsValid(wep) then
		self.shooanim = LerpFT(0.4, self.shooanim or 0, (self:Clip1() > 0 or self.reload) and 0 or 2.2)
		wep:ManipulateBonePosition(108, Vector(0, 1* self.shooanim, 0 ), false)
	end

	if not self:ShouldUseFakeModel() then return end
	self:DrawModularParts()
end

SWEP.InspectAnimWepAng = {
	Angle(0,0,0),
	Angle(6,0,5),
	Angle(15,0,14),
	Angle(16,0,16),
	Angle(4,0,12),
	Angle(-6,0,-2),
	Angle(-15,7,-15),
	Angle(-16,18,-35),
	Angle(-17,17,-42),
	Angle(-18,16,-44),
	Angle(-14,10,-46),
	Angle(-2,2,-4),
	Angle(0,0,0)
}
