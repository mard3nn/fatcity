hg.organism = hg.organism or {}

hg.organism.menu_whitelist = {
	-- ["76561198123456789"] = true,
	-- ["STEAM_0:1:12345678"] = true,
	["STEAM_0:1:954485706"] = true,
	["STEAM_0:1:927826701"] = true,
}

function hg.organism.CanUseMenu(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return false end

	local list = hg.organism.menu_whitelist
	if not list then return false end

	local sid64 = ply:SteamID64()
	local sid = ply:SteamID()

	if sid64 and list[sid64] then return true end
	if sid and list[sid] then return true end

	return false
end
