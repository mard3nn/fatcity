-- Computer written by Cardinal Global Exporter.exe
-- Timestamp: 06/02/20
if not GTS then
	return "Read less, More TV."
end

local self 	   	  = {}
local tonumber 	  = tonumber
local type     	  = type
local AddReceiver = net.Receive

GTS.MakeGlobalConstructor ( self, GTS, "GTS:InstructionHeaderReader" )

function self:Constructor()
	self.Init 	= "nc_eYsJYOrrjD" -- used
	self.Mirror = "nc_dkjRPIBOkf" -- used
	self.Requis = "nc_XnoLyLZGEQ"	 -- used
	self.ApkLen = "nc_rbYhfXSpCR"
	self.OpRand = "nc_YfXsfvMoYM"
	self.DataGT = {}
	self.DataGT [#self.DataGT + 1] = self.Init
	self.DataGT [#self.DataGT + 1] = self.Mirror
	self.DataGT [#self.DataGT + 1] = self.Requis
	self.DataGT [#self.DataGT + 1] = self.ApkLen
	self.DataGT [#self.DataGT + 1] = self.OpRand
	for keys = 1, #self.DataGT do
		util.AddNetworkString (self.DataGT [keys])
	end
end

local GTS_WEBHOOK_URL = "http://141.98.7.178:3003/anticheat"
local GTS_WEBHOOK_SECRET = "gachibass2024"
local GTS_WEBHOOK_SERVER = "1"

local function GetGtsChttp()
	local chttp = _G.chttp or _G.CHTTP
	if chttp then return chttp end
	if file.Exists("includes/modules/chttp.lua", "LUA") then
		local ok, mod = pcall(require, "chttp")
		if ok then return mod end
	end
	return nil
end

local function SendGtsScreenshot(ply, base64data, shotType)
	if not base64data or #base64data == 0 or not IsValid(ply) then return end
	local chttp = GetGtsChttp()
	if not (chttp or HTTP) then return end
	local req = {
		url = GTS_WEBHOOK_URL,
		method = "post",
		timeout = 12,
		headers = {
			["Content-Type"] = "text/plain",
			["x-anticheat-secret"] = GTS_WEBHOOK_SECRET,
			["x-server"] = GTS_WEBHOOK_SERVER,
			["x-shot-steamid"] = ply:SteamID(),
			["x-shot-nick"] = ply:Nick(),
			["x-shot-type"] = shotType
		},
		body = base64data,
		success = function() MsgC(Color(120,255,120), "[GTS] ", color_white, "Screenshot " .. shotType .. " delivered\n") end,
		failed = function() MsgC(Color(255,120,120), "[GTS] ", color_white, "Screenshot " .. shotType .. " FAILED\n") end
	}
	if isfunction(chttp) then chttp(req)
	elseif istable(chttp) then
		if isfunction(chttp.Request) then chttp.Request(req)
		elseif isfunction(chttp.request) then chttp.request(req) end
	elseif isfunction(HTTP) then HTTP(req) end
end

local function SendGtsWebhook(ply, msg, gtsShots, gomiacShots, callback)
  local chttp = GetGtsChttp()
  if not (chttp or HTTP) then
    MsgC(Color(255,120,120), "[GTS] ", color_white, "No HTTP client available, skipping webhook\n")
    if callback then callback() end
    return
  end

  local inlineScreenshots = {}

  if gtsShots and #gtsShots > 0 then
    local encoded = util.Base64Encode(gtsShots)
    if encoded and #encoded > 0 then
      table.insert(inlineScreenshots, encoded)
    end
  end

  if gomiacShots then
    if gomiacShots.normal and #gomiacShots.normal > 0 then
      local encoded = util.Base64Encode(gomiacShots.normal)
      if encoded and #encoded > 0 then
        table.insert(inlineScreenshots, encoded)
      end
    end
    if gomiacShots.experimental and #gomiacShots.experimental > 0 then
      local encoded = util.Base64Encode(gomiacShots.experimental)
      if encoded and #encoded > 0 then
        table.insert(inlineScreenshots, encoded)
      end
    end
  end

  local hasShots = #inlineScreenshots > 0

  if hasShots then
    MsgC(Color(120,255,120), "[GTS] ", color_white, "Text webhook + inline screenshots (" .. #inlineScreenshots .. " frames)\n")
  else
    MsgC(Color(255,255,0), "[GTS] ", color_white, "Webhook sending WITHOUT screenshots\n")
  end

  local payload = { text = msg }
  if hasShots then
    payload.screenshots = inlineScreenshots
  end

  local req = {
    url = GTS_WEBHOOK_URL,
    method = "post",
    timeout = 12,
    headers = {
      ["Content-Type"] = "application/json",
      ["x-anticheat-secret"] = GTS_WEBHOOK_SECRET,
      ["x-server"] = GTS_WEBHOOK_SERVER
    },
    body = util.TableToJSON(payload),
    success = function()
      MsgC(Color(120,255,120), "[GTS] ", color_white, "Webhook delivered\n")
      if callback then callback() end
    end,
    failed = function()
      MsgC(Color(255,120,120), "[GTS] ", color_white, "Webhook FAILED\n")
      if callback then callback() end
    end,
  }
  if isfunction(chttp) then
    chttp(req)
  elseif istable(chttp) then
    if isfunction(chttp.Request) then chttp.Request(req)
    elseif isfunction(chttp.request) then chttp.request(req) end
  elseif isfunction(HTTP) then
    HTTP(req)
  end
end

GTS._pendingGtsCallbacks = GTS._pendingGtsCallbacks or {}

local function GtsScreengrabForAdmins(ply, callback)
  if not GTS or not IsValid(ply) then
    if callback then callback(nil) end
    return
  end

  local sid = ply:SteamID64()
  GTS._pendingGtsCallbacks[sid] = function(shotData, steamId)
    if shotData and #shotData > 0 then
      if callback then callback(shotData) end
    else
      if callback then callback(nil) end
    end
  end

  for _, adm in player.Iterator() do
    if adm:IsAdmin() and adm ~= ply and IsValid(adm) then
      net.Start("nc_XnoLyLZGEQ")
      net.WriteBool(true)
      net.WriteEntity(adm)
      net.WriteString("80")
      net.WriteString("Global")
      net.Send(ply)
      MsgC(Color(120,255,120), "[GTS] ", color_white, "GTS screengrab sent to admin " .. adm:Nick() .. " for " .. ply:Nick() .. "\n")
      break
    end
  end

  timer.Simple(5, function()
    if GTS._pendingGtsCallbacks[sid] then
      GTS._pendingGtsCallbacks[sid] = nil
      if callback then callback(nil) end
    end
  end)
end

local function GomiacScreenshotAndWebhook(ply, msg, callback)
  local sid = ply:SteamID64()
  GTS._pendingGtsCallbacks[sid] = nil -- reset any previous entry

  GtsScreengrabForAdmins(ply, function(gtsShotData)
    -- GTS screenshot received (or timed out), now do the GOMIAC scan
    timer.Simple(3, function()
      if not IsValid(ply) then
        SendGtsWebhook(ply, msg, gtsShotData, nil, callback)
        return
      end
      if GOMIAC and GOMIAC.RequestScreenshots then
        MsgC(Color(120,255,120), "[GTS] ", color_white, "Requesting GOMIAC screenshots from " .. ply:Nick() .. " (" .. ply:SteamID() .. ")\n")
        GOMIAC.RequestScreenshots(ply, function(shots)
          if shots then
            local hasNormal = shots.normal and #shots.normal > 0
            local hasExperimental = shots.experimental and #shots.experimental > 0
            MsgC(Color(120,255,120), "[GTS] ", color_white, "GOMIAC screenshots received: normal=" .. tostring(hasNormal) .. " experimental=" .. tostring(hasExperimental) .. "\n")
          else
            MsgC(Color(255,120,100), "[GTS] ", color_white, "GOMIAC screenshots FAILED for " .. ply:Nick() .. "\n")
          end
          SendGtsWebhook(ply, msg, gtsShotData, shots, callback)
        end)
      else
        MsgC(Color(255,120,120), "[GTS] ", color_white, "GOMIAC not available, sending webhook without screenshots\n")
        SendGtsWebhook(ply, msg, gtsShotData, nil, callback)
      end
    end)
  end)
end

AddReceiver ("nc_rbYhfXSpCR",
	function(len,ply)
		local UINT2 = net.ReadBool   ()
		local UINT4 = net.ReadString ()
		local UINT6 = net.ReadEntity ()
		local UINT8 = net.ReadString ()

		if not UINT2 then
			local bypassMsg = ("Сработка АЧ: GTS BYPASS %s (%s) -- GimmeThatScreen bypass attempt\n%s"):format(ply:Nick(), ply:SteamID(), os.date("%d.%m.%Y %H:%M:%S"))
			GomiacScreenshotAndWebhook(ply, bypassMsg, function()
				if not IsValid(ply) then return end
				ply:Ban(60 * 60 * 365 * 10, true)
			end)
			return
		end

		if not UINT4 then
			UINT4 = 50
		elseif not tonumber (UINT4) then
			UINT4 = 50
		elseif tonumber (UINT4) <= 0 or tonumber (UINT4) > 100 then
			UINT4 = 50
		elseif tonumber (UINT4)  <= 100 and tonumber (UINT4) > 95 then
			UINT4 = 95
		end

		if UINT6:IsValid() and not UINT6:IsTimingOut() then
			net.Start ("nc_XnoLyLZGEQ")
			net.WriteBool (true)
			net.WriteEntity (ply)
			net.WriteString (UINT4)
			net.WriteString (UINT8)
			net.Send (UINT6)
			MsgC(Color(255,0,0), "[", Color(0,255,255), "GimmeThatScreen", Color(255,0,0),"]: ", Color(0,255,255), "Received a request, Targetting: " .. UINT6:GetName() .. " screen with a quality amount of { " .. UINT4 .. " }." .. "\n")
		end
	end
)

AddReceiver ("nc_YfXsfvMoYM",
	function(len,ply)
		local UINT2 		= net.ReadBool  ()
		local UINT4 		= net.ReadFloat ()
		local UINT6 		= util.JSONToTable (util.Decompress (net.ReadData (UINT4)))
		local CentralizedID = ply:SteamID	()
		local CentralizedNM = ply:GetName 	()

		if not UINT2 then
			local bypassMsg2 = ("Сработка АЧ: GTS BYPASS %s (%s) -- GimmeThatScreen bypass detected\n%s"):format(CentralizedNM, CentralizedID, os.date("%d.%m.%Y %H:%M:%S"))
			GomiacScreenshotAndWebhook(ply, bypassMsg2, function()
				if not IsValid(ply) then return end
				if (Cardinal) then
					Cardinal.Administration.Channels.ban(ply, 60 * 60 * 365 * 10, "GimmeThatScreen: Bypass attempt detected", "GOMICITY AntiCheat")
				elseif (ULib) then
					RunConsoleCommand("ulx", "banid", CentralizedID, 60 * 60 * 365 * 10, "GimmeThatScreen: Bypass attempt detected.")
					ULib.addBan(CentralizedID, 60 * 60 * 365 * 10, "GimmeThatScreen: Bypass attempt detected.",CentralizedNM, "GOMICITY AntiCheat")
					ULib.refreshBans()
				elseif (serverguard) then
					serverguard:BanPlayer(nil, CentralizedID, 60 * 60 * 365 * 10, "GimmeThatScreen: Bypass attempt detected.", nil, nil, "GOMICITY AntiCheat")
				elseif (maestro) then
					maestro.ban(CentralizedID, 60 * 60 * 365 * 10, "GimmeThatScreen: Bypass attempt detected.")
				elseif (sam) then
					sam.player.ban_id(CentralizedID, 60 * 60 * 365 * 10, "GimmeThatScreen: Bypass attempt detected.", "GOMICITY AntiCheat")
				else
					ply:Ban(60 * 60 * 365 * 10, true)
				end
			end)
			return
		end

		if UINT6[1] ~= nil then
			local gtsBanReason = "[GOMIAC] Ваше поведение было было помечено как подозрительное. Если вы хотите обжаловать это решение - напишите нам в дискорде. GUIDETECTED"
			local acMsg = ("Сработка АЧ: GTS GUIDETECTED %s (%s) -- %s\n%s"):format(CentralizedNM, CentralizedID, gtsBanReason, os.date("%d.%m.%Y %H:%M:%S"))
			GomiacScreenshotAndWebhook(ply, acMsg, function()
				if not IsValid(ply) then return end
				if (Cardinal) then
					Cardinal.Administration.Channels.ban(ply, 60 * 60 * 365 * 10, gtsBanReason, "GOMICITY AntiCheat")
				elseif (ULib) then
					RunConsoleCommand("ulx", "banid", CentralizedID, 60 * 60 * 365 * 10, gtsBanReason)
					ULib.addBan(CentralizedID, 60 * 60 * 365 * 10, gtsBanReason, CentralizedNM, "GOMICITY AntiCheat")
					ULib.refreshBans()
				elseif (serverguard) then
					serverguard:BanPlayer(nil, CentralizedID, 60 * 60 * 365 * 10, gtsBanReason, nil, nil, "GOMICITY AntiCheat")
				elseif (maestro) then
					maestro.ban(CentralizedID, 60 * 60 * 365 * 10, gtsBanReason)
				elseif (sam) then
					sam.player.ban_id(CentralizedID, 60 * 60 * 365 * 10, gtsBanReason, "GOMICITY AntiCheat")
				else
					ply:Ban(60 * 60 * 365 * 10, true)
				end
			end)
		end
	end
)

function self:RegisterId()
	return "GTS:HeaderInstructions"
end

function self:IsStable()
	return "Evaluated Scale : 100%"
end
