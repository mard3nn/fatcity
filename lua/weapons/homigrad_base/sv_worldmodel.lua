--
util.AddNetworkString("addpredictable")
function SWEP:CreateWorldModel()
	local model = ents.Create("prop_physics")--ents.Create("homigrad_gun")
	model:SetNoDraw(not hg.show_weapons)
	model:SetModel(self.WorldModel)
	model:SetMaterial("models/wireframe")
	model:Spawn()
	timer.Simple(0,function()
		if !IsValid(model) then return end
		model:PhysicsDestroy()
	end)
	model:SetMoveType(MOVETYPE_NONE)
	model:SetNWBool("nophys", true)
	model:SetSolidFlags(FSOLID_NOT_SOLID)
	model:AddEFlags(EFL_NO_DISSOLVE + EFL_NO_DAMAGE_FORCES + EFL_DONTBLOCKLOS)
	self:DeleteOnRemove(model)
	self.worldModel = model
	self:SetLagCompensated(true)
	model.weapon = self
	return model
end

local math_max = math.max
local vecZero = Vector(0, 0, 0)
local angZero = Angle(0, 0, 0)
local hook_Run = hook.Run
function SWEP:WorldModel_Transform(bNoApply, bNoAdditional)
	local model, owner = self.worldModel, self:GetOwner()

	if not IsValid(model) then
		model = self:CreateWorldModel()
	end

	if not IsValid(owner) or owner:IsNPC() then
		if IsValid(model) then
			model:SetPos(self:GetPos())
			model:SetAngles(self:GetAngles())
		end
		return false
	end

	if not IsValid(owner:GetActiveWeapon()) or self ~= owner:GetActiveWeapon() then
		model:SetPos(self:GetPos())
		model:SetAngles(self:GetAngles())
		return
	end

	local ent = IsValid(owner.FakeRagdoll) and owner.FakeRagdoll or owner

	local dtime = SysTime() - (self.last_transform or SysTime())
	self.last_transform = SysTime()

	local RHand = ent:LookupBone("ValveBiped.Bip01_R_Hand")
	if not RHand then return end

	local matrixR = ent:GetBoneMatrix(RHand)
	if not matrixR then return end

	local aimvec = owner:GetAimVector():Angle()
	local matrixRAngRot = matrixR:GetAngles()
	matrixRAngRot:RotateAroundAxis(matrixRAngRot:Forward(), 180)

	local _, ang = WorldToLocal(vecZero, matrixRAngRot, vecZero, aimvec)
	_, ang = LocalToWorld(vecZero, ang, vecZero, aimvec)
	ang[3] = matrixRAngRot[3]

	local desiredAng = (ent ~= owner) and ang or aimvec
	desiredAng[3] = desiredAng[3] + owner:EyeAngles()[3]
	desiredAng:RotateAroundAxis(desiredAng:Forward(), 180)
	local desiredPos = matrixR:GetTranslation()

	local desiredPos1, desiredAng1 = self:PosAngChanges(owner, desiredPos, desiredAng, bNoAdditional, nil, dtime)
	desiredPos = LerpVector(self.lerped_positioning or 0, desiredPos, desiredPos1)
	desiredAng = LerpAngle(self.lerped_angle or 0, desiredAng, desiredAng1)

	local newPos, newAng = LocalToWorld(self.WorldPos, self.WorldAng, desiredPos, desiredAng)
	newAng:RotateAroundAxis(newAng:Forward(), 180)
	self.desiredPos, self.desiredAng = newPos, newAng

	if bNoApply then
		return newPos, newAng, desiredPos, desiredAng
	end

	self.handPos, self.handAng = desiredPos, desiredAng
	model:SetPos(newPos)
	model:SetAngles(newAng)

	return newPos, newAng
end

local weaponsList = hg.weapons
concommand.Add("hg_show_weapons", function(ply, cmd, args)
	if IsValid(ply) and not ply:IsAdmin() then return end
	hg.show_weapons = tonumber(args[1]) > 0
	for i,wep in ipairs(weaponsList) do
		if not IsValid(wep.worldModel) then continue end
		wep.worldModel:SetNoDraw(not hg.show_weapons)
	end
end)

