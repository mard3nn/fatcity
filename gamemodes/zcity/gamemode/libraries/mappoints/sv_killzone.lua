zb = zb or {}

zb.Killzones = zb.Killzones or {}

function zb.LoadKillzones()
    zb.Killzones = {}

    local points = zb.GetMapPoints("KILLZONE", true)
    if not points or #points == 0 then
        MsgC(Color(255, 200, 0), "[Killzone] ", color_white, "No KILLZONE points found\n")
        return
    end

    for i = 1, #points, 2 do
        local p1 = points[i]
        local p2 = points[i + 1]
        if p1 and p2 and p1.pos and p2.pos then
            local mins = Vector(
                math.min(p1.pos.x, p2.pos.x),
                math.min(p1.pos.y, p2.pos.y),
                math.min(p1.pos.z, p2.pos.z)
            )
            local maxs = Vector(
                math.max(p1.pos.x, p2.pos.x),
                math.max(p1.pos.y, p2.pos.y),
                math.max(p1.pos.z, p2.pos.z)
            )
            table.insert(zb.Killzones, { mins = mins, maxs = maxs })
        end
    end

    MsgC(Color(100, 255, 100), "[Killzone] ", color_white, "Loaded " .. #zb.Killzones .. " killzone(s)\n")
end

function zb.IsInKillzone(pos)
    for _, kz in ipairs(zb.Killzones) do
        if pos.x >= kz.mins.x and pos.x <= kz.maxs.x and
           pos.y >= kz.mins.y and pos.y <= kz.maxs.y and
           pos.z >= kz.mins.z and pos.z <= kz.maxs.z then
            return true
        end
    end
    return false
end

hook.Add("Think", "KillzoneThink", function()
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:GetMoveType() ~= MOVETYPE_NOCLIP then
            if zb.IsInKillzone(ply:GetPos()) then
                if ply:Alive() then
                    local dmg = DamageInfo()
                    dmg:SetDamage(1000)
                    dmg:SetDamageType(DMG_DISSOLVE)
                    dmg:SetAttacker(game.GetWorld())
                    dmg:SetInflictor(game.GetWorld())
                    dmg:SetDamagePosition(ply:GetPos())
                    ply:TakeDamageInfo(dmg)
                elseif ply:Health() > 0 then
                    ply:SetHealth(0)
                end
            end
        end
    end
end)

hook.Add("ZB_AfterAllPoints", "ReloadKillzones", function()
    timer.Simple(0.5, function()
        zb.LoadKillzones()
    end)
end)

hook.Add("InitPostEntity", "LoadKillzones", function()
    timer.Simple(2, function()
        zb.LoadKillzones()
    end)
end)

concommand.Add("zb_reloadkillzones", function(ply)
    if IsValid(ply) and not hg.HasAdminAccess(ply) then return end
    zb.LoadKillzones()
    if IsValid(ply) then
        ply:ChatPrint("Killzones reloaded: " .. #zb.Killzones .. " active")
    end
end)
