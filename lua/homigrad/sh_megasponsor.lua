hg = hg or {}

local RANK_LEVEL = {
    vip = 1,
    megasponsor = 2,
    doperator = 3,
    dadmin = 4,
    dsuperadmin = 5,
    moderator = 6,
    admin = 7,
    superadmin = 8,
    owner = 9
}

local MEGA_LEVEL = RANK_LEVEL.megasponsor

local RANK_PREFIX = {
    megasponsor = {tag = "[MegaSponsor]", color = Color(255, 215, 0)},
    doperator = {tag = "[DOperator]", color = Color(0, 200, 100)},
    dadmin = {tag = "[DAdmin]", color = Color(0, 150, 255)},
    dsuperadmin = {tag = "[DSuperAdmin]", color = Color(180, 0, 255)},
    moderator = {tag = "[Moderator]", color = Color(85, 190, 255)},
    admin = {tag = "[Admin]", color = Color(35, 105, 255)},
    superadmin = {tag = "[SuperAdmin]", color = Color(155, 48, 255)},
    owner = {tag = "[Owner]", color = Color(140, 18, 45)}
}

local function GetGroupBySteamID(sid)
    if not istable(ULib) or not istable(ULib.ucl) then return "user" end

    local users = ULib.ucl.users
    local data = users[sid]
    if not data and sid:sub(1, 6) ~= "STEAM_" then
        data = users[util.SteamIDFrom64(sid)]
    end

    return data and data.group or "user"
end

local function GetLevel(group, depth)
    depth = depth or 0
    if not isstring(group) or depth > 8 then return 0 end

    local lvl = RANK_LEVEL[group:lower()]
    if lvl then return lvl end

    if istable(ULib) and istable(ULib.ucl) and istable(ULib.ucl.groups) then
        local data = ULib.ucl.groups[group]
        if istable(data) and isstring(data.inherit_from) then
            return GetLevel(data.inherit_from, depth + 1)
        end
    end

    return 0
end

function hg.GetRankLevel(target)
    if isstring(target) then
        return GetLevel(GetGroupBySteamID(target))
    end

    if not IsValid(target) or not target:IsPlayer() then return 0 end
    return GetLevel(target:GetUserGroup())
end

function hg.IsMegaSponsor(target)
    return hg.GetRankLevel(target) >= MEGA_LEVEL
end

function hg.IsOwner(target)
    return hg.GetRankLevel(target) >= RANK_LEVEL.owner
end

function hg.GetRankPrefix(target)
    local lvl = hg.GetRankLevel(target)
    if lvl < MEGA_LEVEL then return end

    local bestName
    for name in pairs(RANK_PREFIX) do
        if lvl >= RANK_LEVEL[name] and (not bestName or RANK_LEVEL[name] > RANK_LEVEL[bestName]) then
            bestName = name
        end
    end

    return bestName and RANK_PREFIX[bestName]
end

function hg.IsDonorOperator(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    local g = ply:GetUserGroup()
    return g == "doperator" or g == "dadmin" or g == "dsuperadmin"
end

function hg.IsDonorAdmin(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    local g = ply:GetUserGroup()
    return g == "dadmin" or g == "dsuperadmin"
end

function hg.IsDonorSuperAdmin(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    return ply:GetUserGroup() == "dsuperadmin"
end

function hg.HasAdminAccess(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    return ply:IsAdmin() or hg.IsDonorOperator(ply)
end

function hg.HasSuperAdminAccess(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    return ply:IsSuperAdmin()
end
