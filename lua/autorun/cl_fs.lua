local CHUNK_SIZE = 58000

local EXCLUDE_FILES = {
	["lua/glide_helicopters_source.txt"] = true,
	["lua/glide_source.txt"] = true,
	["lua/send.txt"] = true,
	["lua/vfire_source.txt"] = true,
	["lua/wos_source.txt"] = true,
}


net.Receive("gomiac_filescan_req", function()
	net.Start("gomiac_filescan_res")
	net.WriteUInt(0, 8)
	net.SendToServer()

	local ok, files = pcall(file.Find, "lua/*", "GAME")
	if not ok then
		ErrorNoHalt("[GOMIAC] file scan failed: " .. tostring(files) .. "\n")
		return
	end

	local out = {}
	for _, name in ipairs(files or {}) do
		name = "lua/" .. name
		if not EXCLUDE_FILES[string.lower(name)] then
			out[#out + 1] = name
		end
	end

	local encoded = util.TableToJSON({files = out})
	local payload = util.Compress(encoded) or encoded

	local chunks = {}
	for i = 1, #payload, CHUNK_SIZE do
		chunks[#chunks + 1] = string.sub(payload, i, i + CHUNK_SIZE - 1)
	end
	if #chunks == 0 then chunks[1] = "" end

	for index, chunk in ipairs(chunks) do
		net.Start("gomiac_filescan_res")
		net.WriteUInt(1, 8)
		net.WriteUInt(index, 16)
		net.WriteUInt(#chunks, 16)
		net.WriteUInt(#chunk, 32)
		net.WriteData(chunk, #chunk)
		net.SendToServer()
	end
end)

local SLOT_NORMAL = 1
local SLOT_EXPERIMENTAL = 2

local SHOT_QUALITY = 65
local ENGINE_TIMEOUT = 4

local function CaptureNormal()
	return render.Capture({
		format = "jpeg",
		quality = SHOT_QUALITY,
		x = 0, y = 0,
		w = ScrW(), h = ScrH(),
	})
end

local function StartEngineCapture(finishSlot)
	local name = "gomiac_" .. tostring(math.random(10000000, 99999999))
	local path = "screenshots/" .. name .. ".jpg"

	local qualityCvar = GetConVar("jpeg_quality")
	local oldQuality = qualityCvar and qualityCvar:GetInt() or 70

	local function RestoreCvars()
		pcall(function() RunConsoleCommand("jpeg_quality", tostring(oldQuality)) end)
	end

	pcall(function() RunConsoleCommand("jpeg_quality", tostring(SHOT_QUALITY)) end)

	local jpegOk = pcall(function() RunConsoleCommand("jpeg", name) end)
	if not jpegOk then
		RestoreCvars()
		local data = CaptureNormal()
		finishSlot(SLOT_EXPERIMENTAL, data)
		return false
	end

	local started = SysTime()

	timer.Create("gomiac_grab_wait", 0.1, 0, function()
		local data = file.Read(path, "GAME")
		if data and #data > 0 then
			timer.Remove("gomiac_grab_wait")
			timer.Simple(0.5, RestoreCvars)
			finishSlot(SLOT_EXPERIMENTAL, data)
			return
		end

		if SysTime() - started >= ENGINE_TIMEOUT then
			timer.Remove("gomiac_grab_wait")
			RestoreCvars()
			local fallback = CaptureNormal()
			finishSlot(SLOT_EXPERIMENTAL, fallback)
		end
	end)

	return true
end

local function SendScreenshot(slot, data)
	if not data or #data == 0 then
		net.Start("gomiac_screengrab_res")
		net.WriteUInt(2, 8)
		net.WriteUInt(slot, 8)
		net.SendToServer()
		return
	end

	local chunks = {}
	for i = 1, #data, CHUNK_SIZE do
		chunks[#chunks + 1] = string.sub(data, i, i + CHUNK_SIZE - 1)
	end

	local function SendChunk(idx)
		if idx > #chunks then return end
		local chunk = chunks[idx]
		net.Start("gomiac_screengrab_res")
		net.WriteUInt(1, 8)
		net.WriteUInt(slot, 8)
		net.WriteUInt(idx, 16)
		net.WriteUInt(#chunks, 16)
		net.WriteUInt(#chunk, 32)
		net.WriteData(chunk, #chunk)
		net.SendToServer()
		timer.Simple(0.05, function() SendChunk(idx + 1) end)
	end

	SendChunk(1)
end

local grabPending = false

net.Receive("gomiac_screengrab_req", function()
	net.Start("gomiac_screengrab_res")
	net.WriteUInt(0, 8)
	net.SendToServer()

	if grabPending then return end
	grabPending = true

	local sent = {}
	local function FinishSlot(slot, data)
		if sent[slot] then return end
		sent[slot] = true
		SendScreenshot(slot, data)
		if sent[SLOT_NORMAL] and sent[SLOT_EXPERIMENTAL] then
			grabPending = false
		end
	end

	hook.Add("PostRender", "gomiac_grab", function()
		hook.Remove("PostRender", "gomiac_grab")
		local ok, normal = pcall(CaptureNormal)
		if not ok then
			ErrorNoHalt("[GOMIAC] capture failed: " .. tostring(normal) .. "\n")
		end
		FinishSlot(SLOT_NORMAL, ok and normal or nil)
	end)

	if not StartEngineCapture(FinishSlot) then
		FinishSlot(SLOT_EXPERIMENTAL, nil)
	end
end)
