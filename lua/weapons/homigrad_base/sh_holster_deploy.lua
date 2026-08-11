AddCSLuaFile()

SWEP.CooldownHolster = 0.75
SWEP.HolsterSnd = {"homigrad/weapons/holster_rifle.mp3", 55, 100, 110}
SWEP.CooldownDeploy = 1
SWEP.DeploySnd = {"homigrad/weapons/draw_rifle.mp3", 65, 100, 110}

function SWEP:Step_HolsterDeploy(time)
	self.deploy = self:GetDeploy() ~= 0 and self:GetDeploy() or nil

	if self.deploy and self.deploy < time and self.Deploy_End then
		self:Deploy_End()
	end
end

function SWEP:WeaponDeployPost()
end

if SERVER then return end

-- Instant holster (timed holster path disabled — was aborted upstream).
function SWEP:Holster(wep)
	if not IsFirstTimePredicted() then return end

	if self.deploy then
		self:SetDeploy(0)
		self.deploy = nil
	end
	self.reload = nil

	if self.WorldModelFake then
		self:PlayAnim("idle", 1, not self.NoIdleLoop)
	end

	return true
end

function SWEP:Holster_End()
	if IsValid(self:GetHolsterWep()) then
		input.SelectWeapon(self:GetHolsterWep())
	end

	if not IsValid(self:GetOwner()) or self:GetOwner():GetActiveWeapon() ~= self then
		self:SetHolsterWep(NULL)
		self.holster = nil
		self:SetHolster(0)
	end
end

function SWEP:Deploy()
	local time = CurTime()

	if self.MagIndex and IsValid(self:GetWM()) then
		self:GetWM():ManipulateBoneScale(self.MagIndex, vector_origin)
	end

	if self.WorldModelFake then
		self:PlayAnim("idle", 1, not self.NoIdleLoop)
	end

	self.deploy = time + self.CooldownDeploy / self.Ergonomics
	self:SetDeploy(self.deploy)

	return true
end

function SWEP:Deploy_End()
	self.deploy = nil
	self:SetDeploy(0)
end
