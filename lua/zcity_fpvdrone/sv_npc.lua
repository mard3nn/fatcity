ZCFpv = ZCFpv or {}

local NPC_RANGE = 2800
local FEAR_RANGE = 420
local THINK_RATE = 0.55

local function ensureBullseye(drone)
	if not IsValid(drone) or drone.Dead then return end
	if IsValid(drone.ZCFpvBullseye) then
		drone.ZCFpvBullseye:SetPos(drone:WorldSpaceCenter())
		return drone.ZCFpvBullseye
	end

	local eye = ents.Create("npc_bullseye")
	if not IsValid(eye) then return end

	eye:SetPos(drone:WorldSpaceCenter())
	eye:SetAngles(angle_zero)
	eye:SetParent(drone)
	eye:Spawn()
	eye:Activate()
	eye:SetHealth(999999)
	eye:SetSolid(SOLID_BBOX)
	eye:SetCollisionGroup(COLLISION_GROUP_NPC)
	eye:SetNotSolid(false)
	eye:AddEFlags(EFL_DONTBLOCKLOS)
	eye.ZCFpvBullseye = true
	eye.ZCFpvDroneOwner = drone
	drone.ZCFpvBullseye = eye
	return eye
end

local function clearBullseye(drone)
	if not IsValid(drone) then return end
	if IsValid(drone.ZCFpvBullseye) then
		drone.ZCFpvBullseye:Remove()
	end
	drone.ZCFpvBullseye = nil
end

local function scareNPC(npc, drone, eye)
	if not IsValid(npc) or not npc:IsNPC() then return end
	if not IsValid(drone) or not drone:GetPowered() or drone.Dead then return end

	local target = IsValid(eye) and eye or drone
	if not npc:Visible(target) and not npc:Visible(drone) then return end

	local dist = npc:GetPos():DistToSqr(drone:GetPos())
	if dist > NPC_RANGE * NPC_RANGE then return end

	if dist <= FEAR_RANGE * FEAR_RANGE then
		npc:AddEntityRelationship(drone, D_FR, 99)
		if IsValid(eye) then npc:AddEntityRelationship(eye, D_FR, 99) end
		npc:UpdateEnemyMemory(target, target:GetPos())
		npc:SetEnemy(target)
		if not npc:IsMoving() then
			npc:SetSchedule(SCHED_RUN_FROM_ENEMY)
		end
		return
	end

	npc:AddEntityRelationship(drone, D_HT, 80)
	if IsValid(eye) then
		npc:AddEntityRelationship(eye, D_HT, 99)
		npc:UpdateEnemyMemory(eye, eye:GetPos())
		npc:SetEnemy(eye)
	else
		npc:UpdateEnemyMemory(drone, drone:GetPos())
		npc:SetEnemy(drone)
	end
end

hook.Add("Think", "ZCFpv_NPCThreat", function()
	if (ZCFpv._npcNext or 0) > CurTime() then return end
	ZCFpv._npcNext = CurTime() + THINK_RATE

	for _, drone in ipairs(ents.FindByClass("ent_zc_fpv_*")) do
		if not drone.ZCFpvDrone then continue end
		if drone.Dead or not drone:GetPowered() then
			clearBullseye(drone)
			continue
		end

		local eye = ensureBullseye(drone)
		for _, npc in ipairs(ents.FindInSphere(drone:GetPos(), NPC_RANGE)) do
			scareNPC(npc, drone, eye)
		end
	end
end)

hook.Add("EntityRemoved", "ZCFpv_NPCBullseye", function(ent)
	if not IsValid(ent) or not ent.ZCFpvDrone then return end
	clearBullseye(ent)
end)

hook.Add("EntityTakeDamage", "ZCFpv_NPCMiss", function(ent, dmg)
	local drone = ent
	if IsValid(ent) and ent.ZCFpvBullseye then
		drone = ent.ZCFpvDroneOwner or ent:GetParent()
		if not ZCFpv.IsDrone(drone) then return true end
		local atk = dmg:GetAttacker()
		if IsValid(atk) and (atk:IsNPC() or atk:IsNextBot()) and math.Rand(0, 1) > 0.6 then
			return true
		end
		if drone.TakeDroneDamage then
			drone:TakeDroneDamage(dmg:GetDamage())
		end
		return true
	end

	if not IsValid(drone) or not drone.ZCFpvDrone then return end
	local atk = dmg:GetAttacker()
	if not IsValid(atk) then return end
	if not (atk:IsNPC() or atk:IsNextBot()) then return end
	if math.Rand(0, 1) > 0.6 then
		return true
	end
end)
