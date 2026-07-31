local CLASS = player.RegClass("ebanutiy")

local col1 = Color(150, 40, 40)

function CLASS.On(self)
	self.JumpPowerMul = 1.15

	if CLIENT then return end

	self.StaminaExhaustMul = 0

	if self.organism then
		self.organism.superfighter = 1
	end

	self.oldmaxhealth = self:GetMaxHealth()
	self:SetMaxHealth(300)
	self:SetHealth(300)

	self:StripWeapon("weapon_hands_sh")
	local fists = self:Give("weapon_hg_powerfists")
	if IsValid(fists) then
		self:SelectWeapon(fists)
	end

	if zb and zb.GiveRole then zb.GiveRole(self, "Ebanutiy", col1) end
end

function CLASS.Off(self)
	self.JumpPowerMul = nil

	if CLIENT then return end

	self.StaminaExhaustMul = nil

	if self.organism then
		self.organism.superfighter = false
	end

	if self.oldmaxhealth then
		self:SetMaxHealth(self.oldmaxhealth)
		self:SetHealth(math.min(self:Health(), self.oldmaxhealth))
		self.oldmaxhealth = nil
	end

	self:StripWeapon("weapon_hg_powerfists")

	if not self:HasWeapon("weapon_hands_sh") then
		self:Give("weapon_hands_sh")
	end
end

function CLASS.Think(self)
	if CLIENT then return end

	if self:HasWeapon("weapon_hands_sh") then
		self:StripWeapon("weapon_hands_sh")
	end

	if not self:HasWeapon("weapon_hg_powerfists") then
		self:Give("weapon_hg_powerfists")
	end

	local org = self.organism
	if org then
		if org.superfighter ~= 1 then
			org.superfighter = 1
		end

		if org.stamina then
			org.stamina.sub = 0
			org.stamina.subadd = 0
			org.stamina[1] = org.stamina.max
		end
	end
end

hook.Add("FinishMove", "EbanutiyStamina", function(ply, move)
	if ply.PlayerClassName ~= "ebanutiy" then return end

	local org = ply.organism
	if org and org.stamina then
		org.stamina[1] = org.stamina.max
	end
end)

hook.Add("HG_MovementCalc_2", "EbanutiySpeed", function(mul, ply, cmd, mv)
	if IsValid(ply) and ply.PlayerClassName == "ebanutiy" then
		mul[1] = ply:IsSprinting() and 1.6 or 1.3
	end
end)

if SERVER then
	hook.Add("EntityTakeDamage", "EbanutiyVulnerable", function(ent, dmgInfo)
		if ent:IsPlayer() and ent.PlayerClassName == "ebanutiy" then
			dmgInfo:ScaleDamage(1.25)
		end
	end)
end

local IDLE_ANIM = ACT_HL2MP_IDLE_CROUCH_ZOMBIE or ACT_HL2MP_IDLE_ZOMBIE

hook.Add("CalcMainActivity", "EbanutiyAnims", function(ply, vel)
	if ply.PlayerClassName ~= "ebanutiy" then return end

	local anim = ACT_HL2MP_RUN_ZOMBIE_FAST
	if vel:LengthSqr() <= 0 then
		anim = IDLE_ANIM
	end
	if ply:IsFlagSet(FL_ANIMDUCKING) then
		anim = ACT_HL2MP_WALK_CROUCH_ZOMBIE_01
	end
	if not ply:IsOnGround() and ply:GetMoveType() ~= MOVETYPE_NOCLIP then
		anim = ACT_HL2MP_JUMP_SLAM
	end

	return anim, -1
end)

hook.Add("UpdateAnimation", "EbanutiyAnimRate", function(ply, vel, maxSeqGroundSpeed)
	if not IsValid(ply) or not ply:Alive() or ply.PlayerClassName ~= "ebanutiy" then return end

	ply:SetPlaybackRate(ply:OnGround() and 1.8 or 1.1)
	return ply, vel, maxSeqGroundSpeed
end)

if SERVER then
	hook.Add("HG_PlayerFootstep", "EbanutiySteps", function(ply)
		if not ply:Alive() or ply.PlayerClassName ~= "ebanutiy" then return end

		local chr = hg.GetCurrentCharacter(ply)
		chr:EmitSound("npc/fast_zombie/foot" .. math.random(4) .. ".wav", 65, math.random(95, 105))
		return true
	end)
end
