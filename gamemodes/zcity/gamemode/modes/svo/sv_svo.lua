local MODE = MODE

MODE.name = "svo"
MODE.PrintName = "GOMICITY | SVO"

MODE.ROUND_TIME = 720
MODE.Chance = 0.0

MODE.OverideSpawnPos = true
MODE.LootSpawn = false

local AmmoID_545 = game.GetAmmoID("5.45x39mm")
local AmmoID_45ACP = game.GetAmmoID(".45 ACP")
local AmmoID_9mm = game.GetAmmoID("9x19mm")
local GetAllPlayers = player.GetAll
local IteratorPlayers = player.Iterator
local GetPlayersTeam = team.GetPlayers
local GetMapPoints = zb.GetMapPoints
local TranslatePoints = zb.TranslatePointsToVectors
local RandomSpawn = zb.GetRandomSpawn

util.AddNetworkString("svo_start")
util.AddNetworkString("svo_zone_init")
util.AddNetworkString("svo_roundend")

local spawnZones = {
    {
        referencePoint = Vector(-14176, 14944, -10052),
        carPositions = {
            Vector(-14016, 14367, -10067),
            Vector(-14291, 14333, -10067),
        }
    },
    {
        referencePoint = Vector(-15104, 14336, -10052),
        carPositions = {
            Vector(-14784, 14400, -10052),
            Vector(-14784, 14272, -10052),
        }
    },
    {
        referencePoint = Vector(-15232, 7520, -10052),
        carPositions = {
            Vector(-14934, 7693, -10052),
            Vector(-15045, 7804, -10052),
        }
    },
    {
        referencePoint = Vector(-15200, 5184, -10004),
        carPositions = {
            Vector(-15080, 4966, -10004),
            Vector(-15011, 5055, -10004),
        }
    },
    {
        referencePoint = Vector(-14912, -864, -9972),
        carPositions = {
            Vector(-14561, -962, -9972),
            Vector(-14565, -777, -9972),
        }
    },
    {
        referencePoint = Vector(0, -15072, -7644),
        carPositions = {
            Vector(-221, -14950, -7644),
            Vector(-140, -14845, -7644),
        }
    },
    {
        referencePoint = Vector(12080, -5978, -8156),
        carPositions = {
            Vector(11040, -5504, -8220),
            Vector(11392, -5632, -8220),
        }
    },
    {
        referencePoint = Vector(15008, 7776, -7516),
        carPositions = {
            Vector(14336, 8357, -7516),
            Vector(13860, 8329, -7516),
        }
    },
    {
        referencePoint = Vector(10336, 15168, -9092),
        carPositions = {
            Vector(10238, 14905, -9092),
            Vector(10171, 14701, -9052),
        }
    },
}

local function MakeDissolver(ent, position, dissolveType)
    local Dissolver = ents.Create("env_entity_dissolver")
    timer.Simple(5, function() if IsValid(Dissolver) then Dissolver:Remove() end end)
    if not IsValid(Dissolver) then return end
    Dissolver.Target = "dissolve" .. ent:EntIndex()
    Dissolver:SetKeyValue("dissolvetype", dissolveType)
    Dissolver:SetKeyValue("magnitude", 0)
    Dissolver:SetPos(position)
    Dissolver:SetPhysicsAttacker(ent)
    Dissolver:Spawn()
    ent:SetName(Dissolver.Target)
    ent:Fire("Open")
    Dissolver:Fire("Dissolve", Dissolver.Target, 0)
    Dissolver:Fire("Kill", "", 0.1)
    return Dissolver
end

function MODE:CanLaunch()
    return true
end

function MODE.GuiltCheck(Attacker, Victim, add, harm, amt)
    return 1, true
end

function MODE:AssignTeams()
    local players = {}
    for _, ply in ipairs(GetAllPlayers()) do
        if ply:Team() ~= TEAM_SPECTATOR then
            table.insert(players, ply)
        end
    end
    local count = #players
    if count == 0 then return end
    shuffle(players)
    local half = math.floor(count / 2)
    for i, ply in ipairs(players) do
        ply:SetTeam(i <= half and 0 or 1)
    end
    
    local team0Count = 0
    local team1Count = 0
    for _, ply in ipairs(players) do
        if ply:Team() == 0 then team0Count = team0Count + 1
        elseif ply:Team() == 1 then team1Count = team1Count + 1 end
    end
    local minTeamSize = math.min(team0Count, team1Count)

    local numDrone = math.ceil(minTeamSize * 0.35)

    self.DronePlayers = { [0] = {}, [1] = {} }
    if numDrone > 0 then
        for team = 0, 1 do
            local teamPlayers = {}
            for _, ply in ipairs(players) do
                if ply:Team() == team then table.insert(teamPlayers, ply) end
            end
            shuffle(teamPlayers)
            for i = 1, math.min(numDrone, #teamPlayers) do
                self.DronePlayers[team][teamPlayers[i]] = true
            end
        end
    end
end

function MODE:Intermission()
    game.CleanUpMap()
    self:AssignTeams()

    self._rusSpawnVectors = TranslatePoints(GetMapPoints("HMCD_TDM_T"))
    self._ukrSpawnVectors = TranslatePoints(GetMapPoints("HMCD_TDM_CT"))

    for _, ply in IteratorPlayers() do
        if ply:Team() == TEAM_SPECTATOR then continue end
        ply:SetupTeam(ply:Team())
        net.Start("svo_start")
        net.WriteUInt(ply:Team(), 2)
        local isDrone = self.DronePlayers and self.DronePlayers[ply:Team()] and self.DronePlayers[ply:Team()][ply]
        net.WriteBool(isDrone or false)
        net.Send(ply)
    end

    local poses = {}
    for _, ply in IteratorPlayers() do
        if ply:Team() == TEAM_SPECTATOR then continue end
        table.insert(poses, ply:GetPos())
    end
    local centerpoint = Vector(0, 0, 0)
    for _, pos in ipairs(poses) do centerpoint:Add(pos) end
    if #poses > 0 then centerpoint:Div(#poses) end
    local dist = 0
    for _, pos in ipairs(poses) do
        local d = pos:Distance(centerpoint)
        if d > dist then dist = d end
    end
    zonepoint = centerpoint
    zonedistance = dist

    net.Start("svo_zone_init")
    net.WriteVector(zonepoint)
    net.WriteFloat(zonedistance)
    net.Broadcast()
end

function MODE:CheckAlivePlayers()
    return zb:CheckAliveTeams(true)
end

function MODE:ShouldRoundEnd()
    local endround, winner = zb:CheckWinner(self:CheckAlivePlayers())
    return endround
end

function MODE:BoringRoundFunction() end
function MODE:RoundStart() end

local tblweps = {
    [0] = {
        "weapon_m1911", "weapon_melee", "weapon_medkit_sh",
        "weapon_ak74", "weapon_walkie_talkie",
    },
    [1] = {
        "weapon_tokarev", "weapon_melee", "weapon_bigbandage_sh",
        "weapon_painkillers", "weapon_naloxone",
        "weapon_ak200", "weapon_walkie_talkie",
    }
}

local tblarmors = {
    [0] = {"ent_armor_vest1", "ent_armor_helmet7"},
    [1] = {"ent_armor_vest1", "ent_armor_helmet7"}
}

function MODE:GetPlySpawn(ply) end

local function spawnCarsByZones()
    if game.GetMap() ~= "gm_fork" then return end
    for teamID = 0, 1 do
        local basePos
        for _, ply in ipairs(GetPlayersTeam(teamID)) do
            if ply:Alive() then basePos = ply:GetPos() break end
        end
        if not basePos then continue end
        local bestZone, bestDist = nil, 251
        for _, zone in ipairs(spawnZones) do
            local d = basePos:Distance(zone.referencePoint)
            if d <= 250 and d < bestDist then
                bestDist = d
                bestZone = zone
            end
        end
        if bestZone then
            for _, carPos in ipairs(bestZone.carPositions) do
                local car = ents.Create("gtav_speedo")
                if IsValid(car) then
                    car:SetPos(carPos + Vector(0, 0, 10))
                    car:Spawn()
                end
            end
        end
    end
end

function MODE:GiveEquipment()
    timer.Simple(0.1, function()
        local dronePlayers = self.DronePlayers
        for _, ply in IteratorPlayers() do
            if not ply:Alive() then continue end
            ply:SetSuppressPickupNotices(true)
            ply.noSound = true

            local teamID = ply:Team()
            local isDrone = dronePlayers and dronePlayers[teamID] and dronePlayers[teamID][ply]

            if isDrone then
                if teamID == 0 then
                    ply:SetPlayerClass("rus_drone")
                    zb.GiveRole(ply, "Оператор БПЛА РФ", Color(190, 0, 0))
                    local pistol = ply:Give("weapon_m1911")
                    if IsValid(pistol) then
                        ply:GiveAmmo(pistol:GetMaxClip1() * 3, AmmoID_45ACP, true)
                    end
                else
                    ply:SetPlayerClass("ukr_drone")
                    zb.GiveRole(ply, "Оператор БПЛА ВСУ", Color(0, 120, 255))
                    local pistol = ply:Give("weapon_pl15")
                    if IsValid(pistol) then
                        ply:GiveAmmo(pistol:GetMaxClip1() * 3, AmmoID_9mm, true)
                    end
                end
                ply:Give("fpv_drone")
                ply:Give("weapon_claymore")
                ply:Give("weapon_melee")
                hg.AddArmor(ply, "ent_armor_vest1")
                hg.AddArmor(ply, "ent_armor_helmet7")
                ply:Give("weapon_medkit_sh")
                ply:Give("weapon_tourniquet")
            else
                if teamID == 0 then
                    ply:SetPlayerClass("rus")
                    zb.GiveRole(ply, "СОЛДАТ РОССИИ", Color(190, 0, 0))
                else
                    ply:SetPlayerClass("ukr")
                    zb.GiveRole(ply, "СОЛДАТ УКРАИНЫ", Color(0, 120, 255))
                end
                for _, wepName in ipairs(tblweps[teamID]) do
                    local wep = ply:Give(wepName)
                    if IsValid(wep) and wep.GetMaxClip1 then
                        ply:GiveAmmo(wep:GetMaxClip1() * 3, wep:GetPrimaryAmmoType(), true)
                    end
                end
                ply:GiveAmmo(60, AmmoID_545, true)
                for _, arm in ipairs(tblarmors[teamID]) do
                    hg.AddArmor(ply, arm)
                end
            end

            ply:Give("weapon_hands_sh")
            ply:SelectWeapon("weapon_hands_sh")

            timer.Simple(0.1, function() ply.noSound = false end)
            ply:SetSuppressPickupNotices(false)
        end
    end)

    timer.Simple(2, function()
        spawnCarsByZones()
    end)
end

local zoneCooldown = 0
hook.Add("Think", "SVO_ZoneThink", function()
    local rnd = CurrentRound()
    if not rnd or rnd.name ~= "svo" then return end
    if (zb.ROUND_START or CurTime()) + 20 > CurTime() then return end
    if not zonepoint or not zonedistance then return end
    if zoneCooldown > CurTime() then return end
    zoneCooldown = CurTime() + 0.5
    local radius = MODE.GetZoneRadius()
    if not radius or radius >= 0xFFFFFFFF then return end
    local pos = zonepoint
    local radiussqr = radius * radius
    for _, ent in ents.Iterator() do
        if not IsValid(ent) then continue end
        if pos:DistToSqr(ent:GetPos()) <= radiussqr then continue end
        if ent:IsPlayer() then hg.LightStunPlayer(ent) continue end
        if hgIsDoor(ent) and not ent:GetNoDraw() then hgBlastThatDoor(ent) continue end
        if string.find(ent:GetClass(), "prop_") and not hg.expItems[ent:GetModel()] then
            MakeDissolver(ent, ent:GetPos(), 0)
        end
    end
end)

function MODE:RoundThink() end

function MODE:GetTeamSpawn()
    return self._rusSpawnVectors or {}, self._ukrSpawnVectors or {}
end

function MODE:CanSpawn() end

function MODE:EndRound()
    timer.Simple(2, function()
        net.Start("svo_roundend")
        net.Broadcast()
    end)
    local endround, winner = zb:CheckWinner(self:CheckAlivePlayers())
    for _, ply in IteratorPlayers() do
        if ply:Team() == TEAM_SPECTATOR then continue end
        if ply:Team() == winner then
            ply:GiveExp(math.random(15, 30))
            ply:GiveSkill(math.Rand(0.1, 0.15))
        else
            ply:GiveSkill(-math.Rand(0.05, 0.1))
        end
    end
end

function MODE:PlayerDeath(ply) end

function shuffle(tbl)
    local len = #tbl
    for i = len, 2, -1 do
        local j = math.random(i)
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
end