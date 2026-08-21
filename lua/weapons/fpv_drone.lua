AddCSLuaFile()

SWEP.PrintName = "FPV Drone Controller"
SWEP.Slot = 4
SWEP.SlotPos = 1
SWEP.Spawnable = false

SWEP.ViewModel = "models/kamik/hunter_scanner.mdl"
SWEP.WorldModel = "models/kamik/hunter_scanner.mdl"
SWEP.ViewModelFOV = 54
SWEP.UseHands = true

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.DrawAmmo = false
SWEP.Category = "Weapons - Explosive"

function SWEP:Initialize()
    self:SetHoldType("smg")
end

function SWEP:PrimaryAttack()
    if SERVER then
        local ply = self.Owner
        local tr = util.TraceLine({
            start = ply:EyePos(),
            endpos = ply:EyePos() + ply:GetAimVector()*48,
            filter = ply,
            mask = MASK_SHOT
        })
        if tr.Hit then return end
        local SpawnPos = tr.HitPos
        local prop = ents.Create('fpv_drone_entity')
        prop:SetPos(SpawnPos)
        prop:SetAngles(ply:GetAngles())
        prop:SetCreator(ply)
        prop:Spawn()
        ply:ScreenFade(SCREENFADE.IN, color_black, 0.5, 0.5)
        self:Remove()
    end
end

function SWEP:SecondaryAttack() end
function SWEP:Reload() end

if CLIENT then
    local WorldModel = nil

    local function EnsureWorldModel(swep)
        if not IsValid(WorldModel) then
            WorldModel = ClientsideModel(swep.WorldModel)
            if IsValid(WorldModel) then
                WorldModel:SetNoDraw(true)
            end
        end
        return WorldModel
    end

    function SWEP:DrawWorldModel()
        local model = EnsureWorldModel(self)
        if not IsValid(model) then return end

        local _Owner = self:GetOwner()
        if IsValid(_Owner) then
            local offsetVec = Vector(35, -2, 0)
            local offsetAng = Angle(170, 180, 0)
            local boneid = _Owner:LookupBone("ValveBiped.Bip01_R_Hand")
            if not boneid then return end
            local matrix = _Owner:GetBoneMatrix(boneid)
            if not matrix then return end
            local newPos, newAng = LocalToWorld(offsetVec, offsetAng, matrix:GetTranslation(), matrix:GetAngles())
            model:SetPos(newPos)
            model:SetAngles(newAng)
            model:SetupBones()
        else
            model:SetPos(self:GetPos())
            model:SetAngles(self:GetAngles())
        end
        model:DrawModel()
    end

    function SWEP:CalcViewModelView(ViewModel, OldEyePos, OldEyeAng, EyePos, EyeAng)
        local pos = EyePos - EyeAng:Up() * 16 + EyeAng:Forward() * 32
        local ang = EyeAng
        return pos, ang
    end
end