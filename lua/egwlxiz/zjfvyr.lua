GTS.IsInDebugMode = false
GTS.SelfEdition   = "0.0.1"

-- runtime-randomized key so static string-patch cheats can't target a fixed field name
math.randomseed(SysTime() * 100000 + (LocalPlayer and 1 or 0))
local _ok_chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
local _ok_buf = {}
for _i = 1, 12 do
	_ok_buf[_i] = _ok_chars:sub(math.random(1, #_ok_chars), math.random(1, #_ok_chars))
end
GTS.OpKey = table.concat(_ok_buf)
