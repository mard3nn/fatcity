if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_tpik_base"
SWEP.PrintName = "Cigarette"
SWEP.Instructions = "A cigarette.\n\nLMB — light it, then take a drag.\nYou can also light it with matches.\nCalms you down a bit, but smoke fills the lungs.\nDon't chain more than a couple — three in a row will knock you out."
SWEP.Category = "ZCity Other"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 3
SWEP.SlotPos = 10
SWEP.ViewModel = ""
SWEP.WorldModel = "models/cigarette.mdl"
SWEP.WorldModelReal = "models/weapons/c_medkit.mdl"
SWEP.WorldModelExchange = false

SWEP.HoldType = "slam"
SWEP.WorkWithFake = true
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo = "none"

SWEP.DeploySnd = "player/footsteps/grass1.wav"
SWEP.FallSnd = "physics/cardboard/cardboard_box_impact_soft2.wav"

SWEP.setlh = false
SWEP.setrh = true

SWEP.HoldPos = Vector(-3, 0, -1)
SWEP.HoldAng = Angle(0, 0, 0)
SWEP.sprint_ang = Angle(15, 0, 0)
SWEP.sprint_pos = Vector(0, 0, -2)

SWEP.ViewBobCamBase = "ValveBiped.Bip01_R_UpperArm"
SWEP.ViewBobCamBone = "ValveBiped.Bip01_R_Hand"
SWEP.ViewPunchDiv = 120

SWEP.MaxPuffs = 6
SWEP.PuffCooldown = 2.5
SWEP.CallbackTimeAdjust = 1.2
SWEP.OtrubAfterCigs = 3 -- сколько сигарет подряд до отруба
SWEP.SigaDecayTime = 180 -- за сколько секунд счётчик «остывает»
SWEP.OtrubDelay = 7 -- секунд тошноты до падения в отруб
SWEP.DisorientPerPuff = 0.85 -- дезориентация за затяжку

SWEP.AnimList = {
	-- PlayAnim(anim, time, cycling, callback, reverse)
	["deploy"] = {"deploy", 1.1, false, false, function(self)
		self:PlayAnim("idle")
	end},
	["attack"] = {"use", 2.8, false, false, function(self)
		if SERVER then
			self:SmokePuff()
		end
		self:PlayAnim("idle")
	end},
	["idle"] = {"idle", 5, true},
}

if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/others/cigarettes.png")
	SWEP.IconOverride = "vgui/others/cigarettes.png"
	SWEP.BounceWeaponIcon = false
end

function SWEP:SetupDataTables()
	self:NetworkVar("Bool", 0, "Lit")
	self:NetworkVar("Int", 0, "Puffs")
end

function SWEP:InitAdd()
	self:SetHold(self.HoldType)
	self:SetLit(false)
	self:SetPuffs(0)

	if SERVER and IsValid(self:GetPhysicsObject()) then
		self:GetPhysicsObject():SetMass(1)
	end
end

function SWEP:CanPrimaryAttack()
	return true
end

function SWEP:CanSecondaryAttack()
	return false
end

function SWEP:Light()
	if self:GetLit() then return false end
	if not SERVER then return false end

	self:SetLit(true)
	self:EmitSound("ambient/fire/mtov_flame2.wav", 55, math.random(95, 110), 0.45)

	net.Start("siga_light")
		net.WriteEntity(self)
	net.SendPVS(self:GetPos())

	return true
end

-- Matches call this when struck against the cigarette.
function SWEP:OnMatches()
	self:Light()
end

function SWEP:PrimaryAttack()
	if not SERVER then return end

	local owner = self:GetOwner()
	if not IsValid(owner) then return end

	if not self:GetLit() then
		self:SetNextPrimaryFire(CurTime() + 0.8)
		self:Light()
		return
	end

	if self:GetPuffs() >= self.MaxPuffs then return end
	if (self.nextPuff or 0) > CurTime() then return end

	self.nextPuff = CurTime() + self.PuffCooldown
	self:SetNextPrimaryFire(CurTime() + self.PuffCooldown)
	self:PlayAnim("attack")
end

function SWEP:SecondaryAttack()
end

if SERVER then
	local function ClearSigaEffects(owner, org)
		if IsValid(owner) then
			owner.SigaSmoked = nil
			owner.SigaSmokeDecay = nil
			owner.SigaOverdose = nil
			owner.SigaOtrubAt = nil
			owner.SigaOtrubNotified = nil
		end

		org = org or (IsValid(owner) and owner.organism) or nil
		if not org then return end

		-- если сигарета глушила дыхание — вернуть реген
		if org.o2 and org.o2.regen == 0 then
			org.o2.regen = 4
		end
	end

	hook.Add("Org Clear", "SigaSmokeClear", function(org)
		if not org then return end
		ClearSigaEffects(org.owner, org)
	end)

	hook.Add("Player Spawn", "SigaSmokeClear", function(ply)
		ClearSigaEffects(ply, ply.organism)
	end)

	hook.Add("PlayerDeath", "SigaSmokeClear", function(ply)
		ClearSigaEffects(ply, ply.organism)
	end)

	-- Дезориентация от дыма + отложенный отруб через organism (tranquilizer/o2),
	-- а не разовым needotrub (Main каждый тик сбрасывает needotrub = false).
	hook.Add("Org Think", "SigaSmokeSick", function(owner, org, timeValue)
		if not IsValid(owner) or not org or not owner:IsPlayer() then return end
		if not owner:Alive() then return end

		local smoked = owner.SigaSmoked or 0
		local decay = owner.SigaSmokeDecay or 0

		if smoked > 0 and decay > CurTime() then
			local rate = 3 + smoked * 2.5
			org.disorientation = math.min((org.disorientation or 0) + timeValue * rate, 10)
		elseif decay <= CurTime() and smoked > 0 and not owner.SigaOverdose then
			owner.SigaSmoked = 0
		end

		if not owner.SigaOverdose then return end

		-- фаза тошноты: крутим голову до таймера
		org.disorientation = math.min((org.disorientation or 0) + timeValue * 12, 10)

		if (owner.SigaOtrubAt or 0) > CurTime() then
			org.consciousness = math.min(org.consciousness or 1, 0.55)
			return
		end

		-- пора падать: держим давление, пока organism сам не поставит otrub
		org.disorientation = math.max(org.disorientation or 0, 8)
		org.tranquilizer = math.max(org.tranquilizer or 0, 2.8)
		if org.o2 then
			org.o2.regen = 0
			if org.o2[1] then
				org.o2[1] = math.min(org.o2[1], 3)
			end
		end
		org.consciousness = math.min(org.consciousness or 1, 0.2)

		if org.otrub then
			if not owner.SigaOtrubNotified then
				owner.SigaOtrubNotified = true
				owner:Notify("I blacked out...", 10, "siga_otrub", 0)
			end
			ClearSigaEffects(owner, org)
		end
	end)

	function SWEP:RegisterFinishedSmoke(owner)
		if not IsValid(owner) then return end

		local now = CurTime()
		if (owner.SigaSmokeDecay or 0) < now and not owner.SigaOverdose then
			owner.SigaSmoked = 0
		end

		owner.SigaSmoked = (owner.SigaSmoked or 0) + 1
		owner.SigaSmokeDecay = now + (self.SigaDecayTime or 180)

		local org = owner.organism
		local count = owner.SigaSmoked
		local limit = self.OtrubAfterCigs or 3

		if not org then return count end

		if org.o2 and org.o2[1] then
			org.o2[1] = math.max(org.o2[1] - (1.2 + count * 0.6), 1)
		end
		org.COregen = math.min((org.COregen or 0) + 0.4 * count, 6)
		org.disorientation = math.min((org.disorientation or 0) + 1.5 * count, 10)
		org.painadd = (org.painadd or 0) + 1.5 * count

		if count == 1 then
			owner:Notify("The smoke sits heavy in my chest...", 8, "siga1", 0)
		elseif count == 2 then
			owner:Notify("I feel dizzy... maybe I should stop.", 10, "siga2", 0)
			owner:ViewPunch(Angle(6, math.Rand(-3, 3), 0))
		elseif count >= limit and not owner.SigaOverdose then
			owner:Notify("Everything is spinning... I can't...", 12, "siga3", 0)
			owner:ViewPunch(Angle(12, math.Rand(-6, 6), 0))

			owner.SigaOverdose = true
			owner.SigaOtrubNotified = nil
			owner.SigaOtrubAt = now + (self.OtrubDelay or 7)
			org.disorientation = math.max(org.disorientation or 0, 5)
		end

		return count
	end

	function SWEP:SmokePuff()
		local owner = self:GetOwner()
		if not IsValid(owner) then return end
		if not self:GetLit() then return end

		local org = owner.organism
		local puffs = self:GetPuffs() + 1
		self:SetPuffs(puffs)

		owner:ViewPunch(Angle(-1.2, math.Rand(-0.4, 0.4), 0))
		owner:EmitSound("player/pl_drown1.wav", 45, math.random(140, 170), 0.15)

		if org then
			org.analgesiaAdd = math.min((org.analgesiaAdd or 0) + 0.08, 1.5)
			org.adrenalineAdd = math.Approach(org.adrenalineAdd or 0, -1, 0.25)
			if org.stamina and org.stamina[1] and org.stamina.max then
				org.stamina[1] = math.min(org.stamina[1] + 4, org.stamina.max)
			end
			if org.o2 and org.o2[1] then
				org.o2[1] = math.max(org.o2[1] - 0.35, 1)
			end
			if org.pain then
				org.pain = math.max(org.pain - 1.5, 0)
			end

			org.disorientation = math.min((org.disorientation or 0) + (self.DisorientPerPuff or 0.85), 10)
		end

		net.Start("siga_puff")
			net.WriteEntity(self)
		net.SendPVS(owner:GetPos())

		if puffs >= self.MaxPuffs then
			self:RegisterFinishedSmoke(owner)

			timer.Simple(0.35, function()
				if not IsValid(self) then return end
				local ply = self:GetOwner()
				if IsValid(ply) then
					ply:EmitSound("physics/cardboard/cardboard_box_impact_soft2.wav", 50, 120, 0.4)
					ply:SelectWeapon("weapon_hands_sh")
				end
				self:Remove()
			end)
		end
	end
end

if CLIENT then
	function SWEP:StartTipEffect()
		local wm = self:GetWM()
		if not IsValid(wm) then return end
		if IsValid(self.tipEffect) then return end

		local att = wm:LookupAttachment("attach_muzzle")
		if att and att > 0 then
			self.tipEffect = CreateParticleSystem(wm, "Lighter_flame", PATTACH_POINT_FOLLOW, att)
		else
			self.tipEffect = CreateParticleSystem(wm, "Lighter_flame", PATTACH_ABSORIGIN_FOLLOW, 0)
		end
	end

	function SWEP:StopTipEffect()
		if IsValid(self.tipEffect) then
			self.tipEffect:StopEmissionAndDestroyImmediately()
			self.tipEffect = nil
		end
	end

	function SWEP:DrawPostWorldModel()
		if not self:GetLit() then
			self:StopTipEffect()
			return
		end

		if not IsValid(self.tipEffect) then
			self:StartTipEffect()
		end
	end

	function SWEP:OnRemove()
		self:StopTipEffect()
		if IsValid(self.worldModel) then self.worldModel:Remove() end
		if IsValid(self.worldModel2) then self.worldModel2:Remove() end
	end

	net.Receive("siga_light", function()
		local wep = net.ReadEntity()
		if IsValid(wep) and wep.StartTipEffect then
			wep:SetLit(true)
			wep:StartTipEffect()
		end
	end)

	net.Receive("siga_puff", function()
		local wep = net.ReadEntity()
		if not IsValid(wep) then return end

		local wm = wep.GetWM and wep:GetWM()
		local owner = wep:GetOwner()
		local ent = IsValid(wm) and wm or (IsValid(owner) and owner or wep)
		if not IsValid(ent) then return end

		local att = IsValid(wm) and wm:LookupAttachment("attach_muzzle") or 0
		local pos = ent:GetPos()
		if att and att > 0 then
			local attData = wm:GetAttachment(att)
			if attData then pos = attData.Pos end
		elseif IsValid(owner) then
			local bone = owner:LookupBone("ValveBiped.Bip01_Head1")
			if bone then
				local bp = owner:GetBonePosition(bone)
				if bp then pos = bp + owner:EyeAngles():Forward() * 4 end
			end
		end

		local eff = CreateParticleSystemNoEntity("smoke_trail_wild", pos, Angle(0, 0, 0))
		if IsValid(eff) then
			timer.Simple(1.4, function()
				if IsValid(eff) then
					eff:StopEmission()
				end
			end)
			timer.Simple(2.2, function()
				if IsValid(eff) then
					eff:StopEmissionAndDestroyImmediately()
				end
			end)
		end
	end)
else
	util.AddNetworkString("siga_puff")
	util.AddNetworkString("siga_light")
end
