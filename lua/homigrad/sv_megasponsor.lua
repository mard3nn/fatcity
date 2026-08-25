local SPONSOR_GROUPS = {
    megasponsor = true,
    admin = true,
    superadmin = true
}

local function GetGroupBySteamID(sid)
    if not istable(ulx) or not istable(ULib) or not istable(ULib.ucl) then return "user" end

    local users = ULib.ucl.users
    local data = users[sid]
    if not data and sid:sub(1, 6) ~= "STEAM_" then
        data = users[util.SteamIDFrom64(sid)]
    end

    return data and data.group or "user"
end

function hg.IsMegaSponsor(target)
    if istable(target) and target.IsPlayer then
        if not IsValid(target) or not target:IsPlayer() then return false end
        return SPONSOR_GROUPS[target:GetUserGroup()] or false
    end

    return SPONSOR_GROUPS[GetGroupBySteamID(tostring(target))] or false
end

hook.Add("PlayerInitialSpawn", "MegaSponsorFlag", function(ply)
    ply.hg_IsMegaSponsor = hg.IsMegaSponsor(ply)

    if ply:GetUserGroup() ~= "megasponsor" then return end

    timer.Simple(5, function()
        if not IsValid(ply) then return end
        zChatPrint(Color(255, 215, 0), "[MegaSponsor] ", color_white, ply:Nick() .. " заходит в игру!")
    end)
end)

hook.Add("Player Spawn", "MegaSponsorFlagRefresh", function(ply)
    ply.hg_IsMegaSponsor = hg.IsMegaSponsor(ply)
end)

hook.Add("CheckPassword", "MegaSponsorReservedSlot", function(steamID64)
    local visibleCvar = GetConVar("sv_visiblemaxplayers")
    local visible = visibleCvar and visibleCvar:GetInt() or -1
    local maxplayers = game.MaxPlayers()
    local cap = visible > 0 and math.min(visible, maxplayers) or maxplayers

    local all = player.GetAll()

    if #all < cap then return end

    if hg.IsMegaSponsor(steamID64) then
        if #all < maxplayers then return end

        local victim
        for _, ply in ipairs(all) do
            if ply:GetUserGroup() == "user" and (not IsValid(victim) or ply:TimeConnected() < victim:TimeConnected()) then
                victim = ply
            end
        end

        if IsValid(victim) then
            victim:Kick("тебя лоха кикнули потому что мегаспонсор зашол")
            return
        end
    end

    return false, "Сервер полон! Если вы хотите заходить без очереди - купите роль Megasponsor."
end)
