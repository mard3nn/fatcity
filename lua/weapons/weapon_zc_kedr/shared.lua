if SERVER then
	AddCSLuaFile()
end

SWEP.PrintName = "KEDR Anti-Drone Interceptor"
SWEP.Author = "Models: CodeEcho \n addon: informal1337"
SWEP.Category = "ZCity FPV"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Base = "weapon_base"
SWEP.IconOverride = "materials/entities/weapon_yolka_interceptor.png"

SWEP.ViewModel = ""
SWEP.WorldModel = "models/codeecho/yolka_interceptor/kedr_controller.mdl"
SWEP.ControllerModel = "models/codeecho/yolka_interceptor/kedr_controller.mdl"
SWEP.DroneModel = "models/codeecho/yolka_interceptor/kedr_drone.mdl"
SWEP.UseHands = false
SWEP.HoldType = "pistol"
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false

SWEP.offsetVec = Vector(2, -1, 0)
SWEP.offsetAng = Angle(0, 90, 90) -- хуйхухйухйхуйхуйхуйху
SWEP.ModelScale = 0.75
SWEP.DroneScale = 0.92

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.ScanDistance = 90000
SWEP.ScanCone = 28
SWEP.LockTime = 2.5
SWEP.LockBeep = 0.38

function SWEP:SetupDataTables()
	self:NetworkVar("Entity", 0, "LockTarget")
	self:NetworkVar("Float", 0, "LockProgress")
	self:NetworkVar("Bool", 0, "Scanning")
	self:NetworkVar("Bool", 1, "Locked")
	self:NetworkVar("Bool", 2, "Loaded")
end

function SWEP:Initialize()
	self:SetHoldType(self.HoldType)
	if SERVER then self:SetLoaded(true) end
end

function SWEP:IsDrone(ent)
	if not IsValid(ent) or ent:IsPlayer() or ent:IsNPC() then return false end
	return ent.ZCFpvDrone or ent.LVSUAV
end

function SWEP:InCone(ent)
	local ply = self:GetOwner()
	if not IsValid(ply) or not IsValid(ent) then return false end
	local delta = ent:WorldSpaceCenter() - ply:GetShootPos()
	if delta:LengthSqr() < 1 then return true end
	return ply:GetAimVector():Dot(delta:GetNormalized()) >= math.cos(math.rad(self.ScanCone))
end

function SWEP:CollectDrones()
	local list = {}
	for _, ent in ipairs(ents.GetAll()) do
		if self:IsDrone(ent) and not ent.Dead then
			list[#list + 1] = ent
		end
	end
	return list
end

function SWEP:FindTarget()
	local ply = self:GetOwner()
	if not IsValid(ply) then return NULL end

	local start = ply:GetShootPos()
	local aim = ply:GetAimVector()
	local maxDistSqr = self.ScanDistance * self.ScanDistance
	local best, bestDot = NULL, math.cos(math.rad(self.ScanCone))

	for _, ent in ipairs(self:CollectDrones()) do
		local center = ent:WorldSpaceCenter()
		local delta = center - start
		local distSqr = delta:LengthSqr()
		if distSqr > maxDistSqr or distSqr < 1 then continue end

		local dot = aim:Dot(delta:GetNormalized())
		if dot <= bestDot then continue end

		best = ent
		bestDot = dot
	end

	return best
end

function SWEP:ResetLock()
	self:SetLockTarget(NULL)
	self:SetLockProgress(0)
	self:SetLocked(false)
	self:SetScanning(false)
	self.LockStarted = nil
	self.NextLockBeep = nil
	self.Launching = nil
end

function SWEP:LaunchAt(target)
	if self.Launching or not self:GetLoaded() then return end
	local ply = self:GetOwner()
	if not IsValid(ply) or not self:IsDrone(target) or target.Dead then return end

	self.Launching = true
	local ang = ply:EyeAngles()
	local proj = ents.Create("ent_zc_kedr_projectile")
	if not IsValid(proj) then
		self.Launching = nil
		return
	end

	proj:SetPos(ply:GetShootPos() + ang:Forward() * 35 + ang:Right() * -8 + ang:Up() * -5)
	proj:SetAngles(ang)
	proj:SetOwner(ply)
	proj:SetTarget(target)
	proj:Spawn()

	self:SetLoaded(false)
	self:ResetLock()
	timer.Simple(0, function()
		if IsValid(ply) and IsValid(self) then ply:StripWeapon(self:GetClass()) end
	end)
end

function SWEP:Think()
	if CLIENT then return end
	local ply = self:GetOwner()
	if not IsValid(ply) or not self:GetLoaded() or not self:GetScanning() then return end

	local cur = self:GetLockTarget()
	local target = cur
	if not (IsValid(cur) and self:IsDrone(cur) and not cur.Dead and self:InCone(cur)) then
		target = self:FindTarget()
		if IsValid(target) and target ~= cur then
			self:SetLockTarget(target)
			self.LockStarted = CurTime()
			self:SetLockProgress(0)
			self:SetLocked(false)
		end
	end

	if not IsValid(target) then
		self:ResetLock()
		return
	end

	local progress = math.Clamp((CurTime() - (self.LockStarted or CurTime())) / self.LockTime, 0, 1)
	self:SetLockProgress(progress)

	if CurTime() >= (self.NextLockBeep or 0) then
		self.NextLockBeep = CurTime() + self.LockBeep
		local pitch = math.floor(95 + progress * 35)
		self:EmitSound("codeecho/yolka_interceptor/kedr_locking.ogg", 60, pitch, 0.75)
	end

	if progress < 1 then return end
	if not self:GetLocked() then
		self:SetLocked(true)
		self:EmitSound("codeecho/yolka_interceptor/kedr_locked.ogg", 70, 100, 0.85)
	end
	self:LaunchAt(target)
end

function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire(CurTime() + 0.35)
	if CLIENT or not self:GetLoaded() then return end
	if self:GetScanning() or self.Launching then return end

	local target = self:FindTarget()
	if not IsValid(target) then
		self:EmitSound("common/wpn_denyselect.wav", 50, 120, 0.4)
		return
	end

	self:SetScanning(true)
	self:SetLockTarget(target)
	self:SetLockProgress(0)
	self:SetLocked(false)
	self.LockStarted = CurTime()
	self.NextLockBeep = 0
end

function SWEP:SecondaryAttack()
	self:SetNextSecondaryFire(CurTime() + 0.2)
	if CLIENT then return end
	if self:GetScanning() then self:ResetLock() end
end

function SWEP:Reload()
end

if CLIENT then
	local white = Color(235, 245, 235)
	local yellow = Color(255, 190, 40)
	local red = Color(255, 60, 45)

	local function getModel(wep, key, path)
		if IsValid(wep[key]) then return wep[key] end
		local mdl = ClientsideModel(path, RENDERGROUP_OPAQUE)
		if IsValid(mdl) then mdl:SetNoDraw(true) end
		wep[key] = mdl
		return mdl
	end

	local function drawModel(mdl, pos, ang, scale)
		if not IsValid(mdl) then return end
		mdl:SetPos(pos)
		mdl:SetAngles(ang)
		mdl:SetRenderOrigin(pos)
		mdl:SetRenderAngles(ang)
		mdl:SetModelScale(scale or 1, 0)
		mdl:SetupBones()
		mdl:DrawModel()
	end

	function SWEP:RemoveKedrModels()
		if IsValid(self.KedrController) then self.KedrController:Remove() end
		if IsValid(self.KedrDrone) then self.KedrDrone:Remove() end
		self.KedrController = nil
		self.KedrDrone = nil
	end

	function SWEP:GetHandPosAng()
		local ply = self:GetOwner()
		if not IsValid(ply) then
			return self:GetPos(), self:GetAngles()
		end

		local ent = hg and hg.GetCurrentCharacter and hg.GetCurrentCharacter(ply) or ply
		if not IsValid(ent) then ent = ply end

		local bone = ent:LookupBone("ValveBiped.Bip01_R_Hand")
		if not bone then return ply:GetPos(), ply:EyeAngles() end

		ent:SetupBones()
		local mat = ent:GetBoneMatrix(bone)
		if not mat then return ply:GetPos(), ply:EyeAngles() end

		return LocalToWorld(self.offsetVec, self.offsetAng, mat:GetTranslation(), mat:GetAngles())
	end

	function SWEP:DrawKedr()
		local frame = FrameNumber()
		if self._kedrFrame == frame then return end
		self._kedrFrame = frame

		local controller = getModel(self, "KedrController", self.ControllerModel)
		if not IsValid(controller) then return end

		local pos, ang = self:GetHandPosAng()
		drawModel(controller, pos, ang, self.ModelScale)

		if not self:GetLoaded() then return end
		local drone = getModel(self, "KedrDrone", self.DroneModel)
		if not IsValid(drone) then return end

		local id = controller:LookupAttachment("drone_mount")
		local att = id and id > 0 and controller:GetAttachment(id)
		drawModel(drone, att and att.Pos or pos, att and att.Ang or ang, self.DroneScale)
	end

	function SWEP:DrawWorldModel()
		self:DrawKedr()
	end

	function SWEP:DrawWorldModel2()
		self:DrawKedr()
	end

	function SWEP:Holster()
		self:RemoveKedrModels()
		return true
	end

	function SWEP:OnRemove()
		self:RemoveKedrModels()
	end

	function SWEP:DrawHUD()
		local w, h = ScrW(), ScrH()
		local x, y = w * 0.5, h * 0.5
		local target = self:GetLockTarget()
		local col = self:GetLocked() and red or yellow

		surface.SetDrawColor(self:GetScanning() and col or white)
		surface.DrawOutlinedRect(x - 42, y - 42, 84, 84, 2)

		if not self:GetLoaded() then return end

		if not self:GetScanning() then
			draw.SimpleText("лкм - запустить", "DermaDefaultBold", x, y + 58, white, TEXT_ALIGN_CENTER)
			return
		end

		if not IsValid(target) then
			draw.SimpleText("нет цели", "DermaDefaultBold", x, y + 58, yellow, TEXT_ALIGN_CENTER)
			return
		end

		local text = self:GetLocked() and "LAUNCH" or ("LOCK " .. math.floor(self:GetLockProgress() * 100) .. "%")
		draw.SimpleText(text, "DermaDefaultBold", x, y + 58, col, TEXT_ALIGN_CENTER)
		draw.SimpleText(math.floor(LocalPlayer():GetPos():Distance(target:GetPos()) / 52.49) .. " m", "DermaDefault", x, y + 76, white, TEXT_ALIGN_CENTER)
		draw.SimpleText("пкм - отменить", "DermaDefault", x, y + 92, white, TEXT_ALIGN_CENTER)
	end

	hook.Add("PostDrawOpaqueRenderables", "ZCFpv_KedrHand", function(depth, skybox)
		if depth or skybox then return end
		local ply = LocalPlayer()
		if not IsValid(ply) or GetViewEntity() ~= ply then return end
		local wep = ply:GetActiveWeapon()
		if not IsValid(wep) or wep:GetClass() ~= "weapon_zc_kedr" then return end
		wep:DrawKedr()
	end)
end
