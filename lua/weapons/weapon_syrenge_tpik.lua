if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_hg_medicine_base"
SWEP.PrintName = "Poison Syringe"
SWEP.Instructions = "Шприц, наполненный высококонцентрированным токсином. \n\nLMB: Вколоть себе.\nRMB: Вколоть другому."
SWEP.Category = "ZCity Medicine"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.WorldModel = "models/cof/weapons/syringe/w_syringe.mdl"
SWEP.WorldModelReal = "models/cof/weapons/syringe/v_syringe.mdl"

if CLIENT then
    SWEP.WepSelectIcon = Material("cof/vgui/weapons/syringe/640_syringe_slot")
    SWEP.IconOverride = "cof/vgui/weapons/syringe/640_syringe_slot"
    SWEP.BounceWeaponIcon = false
end

SWEP.setlh = true
SWEP.setrh = true

-- Настройки положения в руках (TPIK)
SWEP.HoldPos = Vector(6, -2, -5)
SWEP.HoldAng = Angle(0, 0, 0)

SWEP.AnimList = {
    ["deploy"] = { "draw", 0.5, false },
    ["heal"] = { "use", 1.5, false, false, function(self)
        self.setlh = true -- Возвращаем левую руку в IK после завершения укола

        if SERVER then
            local buddy = self.healbuddy or self:GetOwner()
            local done = self:Heal(buddy, self.mode)
            
            if done then
                self:PlayAnim("deploy")
            end
        end
    end, 0.2 },
    ["idle"] = {"idle", 5, true}
}

function SWEP:InitializeAdd()
    self.Primary.Automatic = false
    self.Secondary.Automatic = false

    self.modeValues = {
        [1] = 1 -- Один заряд
    }
end

function SWEP:CanHeal(ent)
    return (self.modeValues[1] or 0) > 0
end

function SWEP:PrimaryAttack()
    if self:GetNextPrimaryFire() > CurTime() then return end

    if self:CanHeal(self:GetOwner()) then
        self:SetNextPrimaryFire(CurTime() + 2) -- Задержка, чтобы нельзя было прервать анимацию
        self.setlh = true -- При уколе себе рука должна быть видна (IK работает)
        if SERVER then self:PlayAnim("heal") end
    end
end

function SWEP:SecondaryAttack()
    if self:GetNextSecondaryFire() > CurTime() then return end
    if IsValid(self:GetNWEntity("fakeGun")) then return end
    
    local owner = self:GetOwner()
    local tr = hg.eyeTrace(owner)
    local ent = tr.Entity
    
    if IsValid(ent) and hg.GetCurrentCharacter(ent) ~= hg.GetCurrentCharacter(owner) then
        if self:CanHeal(ent) then
            self:SetNextSecondaryFire(CurTime() + 2) -- Задержка для ПКМ
            self.setlh = false -- Отключаем левую руку только для взаимодействия с другим
            if SERVER then
                self.healbuddy = ent
                self:PlayAnim("heal")
            end
        end
    end
end

if SERVER then
    function SWEP:Heal(ent, mode)
        local org = ent.organism
        if not org then return false end
        
        local owner = self:GetOwner()
        self.healbuddy = nil -- Сбрасываем цель после укола
        local entOwner = IsValid(owner.FakeRagdoll) and owner.FakeRagdoll or owner
        
        -- Звук укола
        entOwner:EmitSound("snd_jack_hmcd_needleprick.wav", 80, math.random(100, 110))
        
        -- Эффект яда на организм
        -- Используем существующие механики из базы organism
        org.poison2 = CurTime() -- Удушье (VX)
        org.poison3 = CurTime() -- Цианид
        
        -- Прямое воздействие на жизненные показатели
        org.pulse = math.max(org.pulse - 40, 0) -- Резкое падение пульса
        if org.pulse < 25 then 
            org.heartstop = true -- Остановка сердца при низком пульсе
        end
        
        org.o2[1] = math.max(org.o2[1] - 10, 0) -- Мгновенная нехватка кислорода
        
        -- Расход шприца
        self.modeValues[1] = 0
        self:SetNetVar("modeValues", self.modeValues)
        
        -- Убираем оружие после использования
        timer.Simple(0.5, function()
            if IsValid(self) and IsValid(owner) then
                owner:SelectWeapon("weapon_hands_sh")
                self:Remove()
            end
        end)

        return true
    end
end