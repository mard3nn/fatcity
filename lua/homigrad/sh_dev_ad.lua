local NET_MESSAGE = "zc_dev_ad_sync"
local DATA_FILE = "zcity_datacontent/dev_ad.txt"
local POSITION_FILE = "zcity_datacontent/dev_ad_position.txt"
local DEFAULT_TEXT = "LOCAL BUILD"

if SERVER then
	util.AddNetworkString(NET_MESSAGE)
	resource.AddFile("resource/fonts/disket-mono-bold.ttf")
	resource.AddFile("resource/fonts/disket-mono-regular.ttf")

	-- У локального SRCDS может быть публичный IP, поэтому сохранённая настройка
	-- devad служит явным маркером тестовой установки.
	local enabled = not game.IsDedicated() or file.Exists(DATA_FILE, "DATA")
	local savedText = string.Replace(file.Read(DATA_FILE, "DATA") or DEFAULT_TEXT, "\\n", "\n")
	local text = string.Trim(string.Split(savedText, "\n")[1] or DEFAULT_TEXT)
	local position = math.Clamp(math.floor(tonumber(file.Read(POSITION_FILE, "DATA")) or 1), 1, 6)
	if text == "" then text = DEFAULT_TEXT end

	local function SendState(ply)
		net.Start(NET_MESSAGE)
			net.WriteBool(enabled)
			net.WriteString(text)
			net.WriteUInt(position, 3)
		if IsValid(ply) then net.Send(ply) else net.Broadcast() end
	end

	hook.Add("PlayerInitialSpawn", "ZCityDevAdSync", function(ply)
		SendState(ply)
	end)

	concommand.Add("devad", function(ply, _, _, argsText)
		if IsValid(ply) and not ply:IsAdmin() then
			ply:ChatPrint("[devad] Команда доступна только администраторам.")
			return
		end

		local newText = string.Trim(argsText or "")
		if newText == "" then
			local message = "Использование: devad <текст>"
			if IsValid(ply) then ply:ChatPrint(message) else print("[devad] " .. message) end
			return
		end

		newText = string.Replace(newText, "\\n", " ")
		newText = string.Replace(newText, "\n", " ")
		newText = string.Replace(newText, "\r", " ")
		newText = string.Replace(newText, "\t", " ")
		text = string.sub(string.Trim(newText), 1, 80)

		if not file.IsDir("zcity_datacontent", "DATA") then
			file.CreateDir("zcity_datacontent")
		end
		file.Write(DATA_FILE, text)
		enabled = true
		SendState()

		local message = "Текст локальной плашки обновлён: " .. text
		if IsValid(ply) then ply:ChatPrint("[devad] " .. message) else print("[devad] " .. message) end
	end)

	local positionNames = {
		"1 - левый нижний",
		"2 - посередине снизу",
		"3 - справа нижний",
		"4 - справа верхний",
		"5 - посередине сверху",
		"6 - левый верхний"
	}

	local function PrintPositions(ply)
		local lines = {"[devad_ch] Позиции плашки:"}
		table.Add(lines, positionNames)
		table.insert(lines, "Текущая позиция: " .. position)

		for _, line in ipairs(lines) do
			if IsValid(ply) then ply:ChatPrint(line) else print(line) end
		end
	end

	concommand.Add("devad_ch", function(ply, _, args)
		if IsValid(ply) and not ply:IsAdmin() then
			ply:ChatPrint("[devad_ch] Команда доступна только администраторам.")
			return
		end

		local newPosition = tonumber(args[1])
		if not newPosition then
			PrintPositions(ply)
			return
		end

		newPosition = math.floor(newPosition)
		if newPosition < 1 or newPosition > 6 then
			PrintPositions(ply)
			return
		end

		position = newPosition
		if not file.IsDir("zcity_datacontent", "DATA") then file.CreateDir("zcity_datacontent") end
		file.Write(POSITION_FILE, tostring(position))
		SendState()

		local message = "[devad_ch] " .. positionNames[position]
		if IsValid(ply) then ply:ChatPrint(message) else print(message) end
	end)

	return
end

local isEnabled = false
local adText = DEFAULT_TEXT
local adPosition = 1
local logoUrl = "https://i.ibb.co/7dmdmtV2/gomi-city.png"
local logoPath = "zcity_dev_ad/gomi_city_stacked.png"
local logo

local function LoadLogo()
	if file.Exists(logoPath, "DATA") then
		logo = Material("../data/" .. logoPath, "smooth")
		if not logo:IsError() then return end
	end

	http.Fetch(logoUrl, function(body)
		if not body or body == "" then return end
		if not file.IsDir("zcity_dev_ad", "DATA") then file.CreateDir("zcity_dev_ad") end
		file.Write(logoPath, body)
		logo = Material("../data/" .. logoPath, "smooth")
	end)
end

LoadLogo()

local function IsLocalConnection()
	local address = string.lower(game.GetIPAddress() or "")
	return address == "loopback"
		or string.StartWith(address, "localhost")
		or string.StartWith(address, "127.")
		or string.StartWith(address, "[::1]")
		or address == "::1"
end

surface.CreateFont("ZCityDevAdText", {
	font = "Disket Mono",
	size = 13,
	weight = 700,
	extended = true
})

surface.CreateFont("ZCityDevAdWip", {
	font = "Disket Mono",
	size = 12,
	weight = 400,
	extended = true
})

net.Receive(NET_MESSAGE, function()
	isEnabled = net.ReadBool()
	adText = net.ReadString()
	adPosition = net.ReadUInt(3)
end)

-- Удаляем прежнюю HUDPaint-версию при Lua hot reload, иначе обе плашки
-- продолжают рисоваться до переподключения клиента.
hook.Remove("HUDPaint", "ZCityDevAd")
hook.Remove("PostRenderVGUI", "ZCityDevAd")

hook.Add("PostRenderVGUI", "ZCityDevAd", function()
	if not isEnabled and not IsLocalConnection() then return end

	local scale = math.Clamp(ScrH() / 1080, 0.75, 1.5)
	local margin = 34 * scale
	local logoWidth, logoHeight = 94 * scale, 59 * scale
	local gap = 8 * scale

	surface.SetFont("ZCityDevAdText")
	local titleWidth = surface.GetTextSize(string.upper(adText))
	surface.SetFont("ZCityDevAdWip")
	local wipWidth, wipHeight = surface.GetTextSize("WORK IN PROGRESS")
	local textWidth = math.max(titleWidth, wipWidth + 6 * scale)
	local blockWidth = logoWidth + gap + textWidth

	local x = margin
	if adPosition == 2 or adPosition == 5 then
		x = (ScrW() - blockWidth) / 2
	elseif adPosition == 3 or adPosition == 4 then
		x = ScrW() - margin - blockWidth
	end

	local isTop = adPosition >= 4
	local bottom = isTop and (24 * scale + logoHeight) or (ScrH() - 24 * scale)
	local y = bottom - logoHeight

	if logo and not logo:IsError() then
		surface.SetMaterial(logo)
		surface.SetDrawColor(255, 255, 255, 235)
		surface.DrawTexturedRect(x, y, logoWidth, logoHeight)
	end

	local textX = x + logoWidth + gap
	local wipY = bottom - 17 * scale
	draw.SimpleText(string.upper(adText), "ZCityDevAdText", textX, bottom - 36 * scale, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

	draw.RoundedBox(1, textX - 3 * scale, wipY - wipHeight / 2 - 2 * scale, wipWidth + 6 * scale, wipHeight + 4 * scale, Color(0, 0, 0, 210))
	draw.SimpleText("WORK IN PROGRESS", "ZCityDevAdWip", textX, wipY, Color(157, 160, 156, 235), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
end)
