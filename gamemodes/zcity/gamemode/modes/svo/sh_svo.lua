local MODE = MODE

zb = zb or {}

local mapName = game.GetMap()

if mapName == "gm_fork" then
    MODE.ZoneTimeToShrink = 600
    MODE.ZoneEnabled = true
else
    MODE.ZoneTimeToShrink = 300
    MODE.ZoneEnabled = true
end

function MODE.GetZoneRadius()
    if MODE.ZoneEnabled == false then
        return 0xFFFFFFFF
    end

    if not zonedistance or not isnumber(zonedistance) then
        return 0xFFFFFFFF
    end
    local dist = zonedistance + 2048
    return dist * math.max(((zb.ROUND_START + MODE.ZoneTimeToShrink) - CurTime()) / MODE.ZoneTimeToShrink, 0.025)
end