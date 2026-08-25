hook.Add("PlayerInitialSpawn", "MegaSponsorFlag", function(ply)
    ply.hg_IsMegaSponsor = hg.IsMegaSponsor(ply)

    if not hg.IsMegaSponsor(ply) then return end

    timer.Simple(5, function()
        if not IsValid(ply) then return end

        local prefix = hg.GetRankPrefix(ply)

        zChatPrint(
            prefix and prefix.color or Color(255, 215, 0),
            prefix and prefix.tag .. " " or "[MegaSponsor] ",
            color_white,
            ply:Nick() .. " заходит в игру!"
        )
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
            if hg.GetRankLevel(ply) < 1 and (not IsValid(victim) or ply:TimeConnected() < victim:TimeConnected()) then
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
