local MODE = MODE

MODE.name = "protocol01"
MODE.PrintName = "TЦК"

MODE.ROUND_TIME = 600
MODE.Chance = 0.0

MODE.OverideSpawnPos = true
MODE.LootSpawn = true
MODE.GuiltDisabled = false

local AmmoID_45Rubber = game.GetAmmoID(".45 Rubber")
local GetAllPlayers = player.GetAll
local IteratorPlayers = player.Iterator
local GetPlayersTeam = team.GetPlayers

util.AddNetworkString("protocol01_start")
util.AddNetworkString("protocol01_roundend")

local smalltownPoints = {
    { tckSpawn = Vector(1488, 1264, 36),   carSpawn = Vector(1248, 1152, 68),  radius = 320 },
    { tckSpawn = Vector(1472, 640, 36),    carSpawn = Vector(1189, 570, 36),   radius = 320 },
    { tckSpawn = Vector(-288, 2016, 36),   carSpawn = Vector(-287, 1695, 36),  radius = 320 },
    { tckSpawn = Vector(320, -2000, 36),   carSpawn = Vector(320, -1764, 36),  radius = 320 },
    { tckSpawn = Vector(1472, -864, 36),   carSpawn = Vector(1248, -916, 36),  radius = 320 },
    { tckSpawn = Vector(-1408, -856, 36),  carSpawn = Vector(-1219, -819, 36), radius = 320 },
}

local MAP_SPAWN_DATA = {
    ["mu_smallotown_v2_13"]       = smalltownPoints,
    ["mu_smallotown_v2_13_night"] = smalltownPoints,
    ["mu_smallotown_v2_hl2"] = smalltownPoints,
    ["mu_smallotown_waste_v2_13"] = smalltownPoints
}

local function DissolvePlayer(ply)
    if not IsValid(ply) or not ply:Alive() then return end
    ply:SetNetVar("handcuffed", nil)
    ply:KillSilent()
    timer.Simple(0, function()
        if not IsValid(ply) then return end
        local rag = ply:GetRagdollEntity()
        if IsValid(rag) then
            local dissolver = ents.Create("env_entity_dissolver")
            if IsValid(dissolver) then
                dissolver.Target = "dissolve" .. rag:EntIndex()
                dissolver:SetKeyValue("dissolvetype", 0)
                dissolver:SetKeyValue("magnitude", 0)
                dissolver:SetPos(rag:GetPos())
                dissolver:Spawn()
                rag:SetName(dissolver.Target)
                dissolver:Fire("Dissolve", dissolver.Target, 0)
                dissolver:Fire("Kill", "", 0.1)
            end
        else
            timer.Simple(1, function()
                if IsValid(ply) then ply:Remove() end
            end)
        end
    end)
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

    local numTCK = 1
    if count >= 32 then numTCK = 6
    elseif count >= 26 then numTCK = 5
    elseif count >= 16 then numTCK = 4
    elseif count >= 8 then numTCK = 3
    elseif count >= 4 then numTCK = 2
    end

    for i, ply in ipairs(players) do
        if i <= numTCK then
            ply:SetTeam(1)
        else
            ply:SetTeam(0)
        end
    end
end

function MODE:Intermission()
    game.CleanUpMap()
    self:AssignTeams()

    self.TCKSpawnPoint = nil
    self.ActiveCircles = nil
    self.CarSpawnPoint = nil

    local mapName = game.GetMap()
    local spawnData = MAP_SPAWN_DATA[mapName]

    if spawnData and #spawnData > 0 then
        local chosenPoint = spawnData[math.random(#spawnData)]
        self.TCKSpawnPoint = chosenPoint.tckSpawn
        self.CarSpawnPoint = chosenPoint.carSpawn
        self.ActiveCircles = { { center = chosenPoint.tckSpawn, radius = chosenPoint.radius } }
    end

    for _, ply in IteratorPlayers() do
        if ply:Team() == TEAM_SPECTATOR then continue end
        ply:SetupTeam(ply:Team())
    end

    if self.TCKSpawnPoint then
        for _, ply in ipairs(GetPlayersTeam(1)) do
            ply:SetPos(self.TCKSpawnPoint)
        end
    end

    if self.CarSpawnPoint then
        timer.Simple(0.1, function()
            local car = ents.Create("gtav_speedo")
            if IsValid(car) then
                car:SetPos(self.CarSpawnPoint + Vector(0, 0, 10))
                car:Spawn()
            end
        end)
    end

    for _, ply in IteratorPlayers() do
        if ply:Team() == TEAM_SPECTATOR then continue end
        net.Start("protocol01_start")
        net.WriteUInt(ply:Team(), 2)
        local circles = self.ActiveCircles or {}
        net.WriteUInt(#circles, 4)
        for _, c in ipairs(circles) do
            net.WriteVector(c.center)
            net.WriteFloat(c.radius)
        end
        net.Send(ply)
    end
end

function MODE:CheckAlivePlayers()
    local tckAlive = {}
    local civAlive = {}
    for _, ply in ipairs(GetPlayersTeam(1)) do
        if ply:Alive() and not ply:GetNetVar("handcuffed", false) then
            table.insert(tckAlive, ply)
        end
    end
    for _, ply in ipairs(GetPlayersTeam(0)) do
        if ply:Alive() and not ply:GetNetVar("handcuffed", false) then
            table.insert(civAlive, ply)
        end
    end
    return {tckAlive, civAlive}
end

function MODE:ShouldRoundEnd()
    local teamsAlive = self:CheckAlivePlayers()
    return (#teamsAlive[1] == 0) or (#teamsAlive[2] == 0)
end

function MODE:BoringRoundFunction() end
function MODE:RoundStart() end

function MODE:GetPlySpawn(ply)
    if self.TCKSpawnPoint and ply:Team() == 1 then
        return self.TCKSpawnPoint
    end
    return zb:GetRandomSpawn()
end

function MODE:GiveEquipment()
    timer.Simple(0.1, function()
        for _, ply in IteratorPlayers() do
            if not ply:Alive() then continue end
            ply:SetSuppressPickupNotices(true)
            ply.noSound = true

            if ply:Team() == 1 then
                ply:SetPlayerClass("tck")
                zb.GiveRole(ply, "Оперативник ТЦК", Color(0, 100, 0))

                local pistol = ply:Give("weapon_mp-80")
                if IsValid(pistol) and pistol.GetMaxClip1 then
                    ply:GiveAmmo(pistol:GetMaxClip1() * 1, AmmoID_45Rubber, true)
                end
                ply:Give("weapon_medkit_sh")
                ply:Give("weapon_hg_tonfa")
                ply:Give("weapon_handcuffs")
                ply:Give("weapon_handcuffs_key")
                ply:Give("weapon_walkie_talkie")

                hg.AddArmor(ply, "ent_armor_vest1")
                hg.AddArmor(ply, "ent_armor_helmet1")
            else
 
                ply:SetPlayerClass("civilian_protocol")
                zb.GiveRole(ply, "Гражданский", Color(0, 120, 0))
            end

 
            ply:Give("weapon_hands_sh")
            ply:SelectWeapon("weapon_hands_sh")

            timer.Simple(0.1, function() ply.noSound = false end)
            ply:SetSuppressPickupNotices(false)
        end
    end)
end

MODE.LootTable = {
    {25, {
        {10, "weapon_hatchet"},
        {10, "weapon_table_leg"},
        {10, "weapon_hg_spear"},
        {10, "weapon_hg_razor"},
        {10, "weapon_kitchenknife"},
        {10, "weapon_hg_cinderblock"},
        {10, "weapon_hg_cleaver"},
        {10, "weapon_bat"},
        {10, "weapon_hg_bottlebroken"},
        {10, "weapon_hammer"},
    }},
    {60, {
        {20, "weapon_smallconsumable"},
        {20, "weapon_bigconsumable"},
        {15, "weapon_matches"},
        {15, "weapon_painkillers"},
        {15, "weapon_bloodbag"},
        {15, "weapon_ducttape"},
    }},
    {15, {
        {30, "weapon_bandage_sh"},
        {30, "weapon_bigbandage_sh"},
        {20, "weapon_medkit_sh"},
        {10, "weapon_hg_fiberwire"},
        {5, "weapon_hg_spear_pro"},
        {5, "weapon_taser"},
    }}
}

local circleCooldown = 0
hook.Add("Think", "Protocol01_CircleThink", function()
    local rnd = CurrentRound()
    if not rnd or rnd.name ~= "protocol01" then return end
    if (zb.ROUND_START or CurTime()) + 20 > CurTime() then return end
    if circleCooldown > CurTime() then return end
    circleCooldown = CurTime() + 0.5

    local circles = MODE.ActiveCircles
    if not circles then return end

    for _, ply in ipairs(GetPlayersTeam(0)) do
        if not ply:Alive() or ply:GetNetVar("handcuffed", false) then continue end
        local pos = ply:GetPos()
        for _, c in ipairs(circles) do
            if pos:Distance(c.center) <= c.radius then
                DissolvePlayer(ply)
                break
            end
        end
    end
end)

function MODE:RoundThink() end

function MODE:GetTeamSpawn()
    return {zb:GetRandomSpawn()}, {zb:GetRandomSpawn()}
end

function MODE:CanSpawn() end

function MODE:EndRound()
    timer.Simple(2, function()
        net.Start("protocol01_roundend")
        local teamsAlive = self:CheckAlivePlayers()
        local tckWin = #teamsAlive[1] > 0
        net.WriteBool(tckWin)
        net.Broadcast()
    end)

    local teamsAlive = self:CheckAlivePlayers()
    local tckWin = #teamsAlive[1] > 0
    for _, ply in IteratorPlayers() do
        if ply:Team() == TEAM_SPECTATOR then continue end
        if (ply:Team() == 1 and tckWin) or (ply:Team() == 0 and not tckWin) then
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