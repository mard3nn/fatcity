local CurTime = CurTime

-- Instant holster (timed path disabled — keep deploy cooldown / sling behavior).
function SWEP:Holster(wep)
	if self.deploy then
		self:SetDeploy(0)
		self.deploy = nil
	end

	self.reload = nil
	self.StaminaReloadTime = nil

	return true
end

function SWEP:Holster_End()
	local owner = self:GetOwner()
	local wep = IsValid(self:GetHolsterWep()) and self:GetHolsterWep() or (IsValid(owner) and owner:GetWeapon("weapon_hands_sh"))

	if IsValid(wep) and IsValid(owner) then
		owner:SetActiveWeapon(wep)
		wep:Deploy()
		if wep.holster then
			wep.holster = nil
			wep:SetHolster(0)
		end
		self:SetHolsterWep(NULL)
	end

	if not IsValid(owner) or owner:GetActiveWeapon() ~= self then
		self.holster = nil
		self:SetHolster(0)
	end
end

local gamemod = engine.ActiveGamemode()
local hg_slings = ConVarExists("hg_slings") and GetConVar("hg_slings") or CreateConVar("hg_slings", 0, FCVAR_SERVER_CAN_EXECUTE + FCVAR_ARCHIVE, "Toggle sling system", 0, 1)
hook.Add("PlayerSwitchInFake", "slingDrop", function(ply, oldWeapon, newWeapon)
	if not hg_slings:GetBool() then return end
	if oldWeapon == newWeapon then return end
	if (zb.CROUND and zb.CROUND == "hmcd") or gamemod == "sandbox" then
		local inv = ply:GetNetVar("Inventory")

		if SERVER and IsValid(oldWeapon) and not oldWeapon.bigNoDrop and oldWeapon.weaponInvCategory == 1 and inv and inv["Weapons"] and not inv["Weapons"]["hg_sling"] then
			timer.Simple(0, function()
				if IsValid(oldWeapon) and oldWeapon:GetOwner() == ply then
					hg.drop(ply, oldWeapon, newWeapon)
				end
			end)

			if not IsValid(ply.FakeRagdoll) then return true end
		end
	end
end)

SWEP.Initialzed = false -- typo kept for compatibility with existing weapons/inventory
function SWEP:Deploy()
	local time = CurTime()
	if SERVER and self.Initialzed and not self:GetOwner().noSound then
		timer.Simple(self.CooldownDeploy / self.Ergonomics * 0.4, function()
			if IsValid(self) and IsValid(self:GetOwner()) and istable(self.DeploySnd) then
				self:GetOwner():EmitSound(self.DeploySnd[1], 65)
			end
		end)
	end
	self.Initialzed = true

	self.holster = nil
	self:SetHolster(0)

	self.deploy = time + self.CooldownDeploy / self.Ergonomics
	self:SetDeploy(self.deploy)

	return true
end

function SWEP:Deploy_End()
	self.deploy = nil
	self:SetDeploy(0)
end
