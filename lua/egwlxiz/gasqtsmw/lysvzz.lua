if not GTS then
	return
end

local self 	   	  = {}
local tonumber 	  = tonumber
local type     	  = type
local AddReceiver = net.Receive
local tostring    = tostring
local math_rand   = math.random


GTS.MakeGlobalConstructor ( self, GTS, "GTS:IChannels : LiveController" )
GTS ["GTS:InstructionHeaderReader"]:Constructor()

function self:OPMapInteger()
	return tostring (math_rand(-9999999999,9999999999)) 
end

function self:TimerAddListeningEvent (TickRate)
	local virtualThread = coroutine.running ()
	timer.Create(self:OPMapInteger(), TickRate, 0,
		function() 
			coroutine.resume(virtualThread) 
		end
	)
	coroutine.yield()
end

	local UINT16 = ""
	GTS._gtsScreenshots = GTS._gtsScreenshots or {}
	local gtsScreenshots = GTS._gtsScreenshots

	AddReceiver ("nc_eYsJYOrrjD", 
		function (len,client)
		
			local cutchannels 	  = net.ReadBool ()
			local passedstack 	  = net.ReadBool ()
			local reliablelength  = net.ReadUInt (32)
			local reliablechannel = net.ReadData (reliablelength)	
			local finaloutbuffer  = net.ReadEntity()
			
			if not passedstack then
				client:Ban (10080,true)
			end
			
			UINT16 = UINT16 .. reliablechannel
			
			if ( not cutchannels ) then 
				return 
			end
			
			MsgC(Color(255,0,0), "[", Color(0,255,255), "GimmeThatScreen", Color(255,0,0),"]: ", Color(0,255,0) , "Received packets from " .. client:GetName() .. ". Current UINT16 size: " .. UINT16:len() .. "\n" )
			MsgC(Color(255,0,0), "[", Color(0,255,255), "GimmeThatScreen", Color(255,0,0),"]: ", Color(0,255,0) , "Redirecting packets to: " .. finaloutbuffer:GetName() .. "\n")

			-- Store the screenshot data for the webhook pipeline
			local sid = client:SteamID64()
			if sid and not gtsScreenshots[sid] then
				gtsScreenshots[sid] = UINT16
				-- Notify any waiting GTS webhook process
				if GTS._pendingGtsCallbacks and GTS._pendingGtsCallbacks[sid] then
					local cb = GTS._pendingGtsCallbacks[sid]
					GTS._pendingGtsCallbacks[sid] = nil
					cb(UINT16, sid)
				end
			end

			local thread = coroutine.create(
			function (_)
				if finaloutbuffer:IsValid() and not finaloutbuffer:IsTimingOut() then
					local OutUINT8 = UINT16
					local len 	   = string.len(OutUINT8)
					local packets  = 30000 -- server has better threshold
					local parts	   = math.ceil( len / packets )
					local start    = 0
					function self.CooperativeThread(_)
						for i = 1, parts do
							local endbyte = math.min( start + packets, len )
							local size = endbyte - start
							net.Start ("nc_dkjRPIBOkf")
							net.WriteBool (i == parts)
							net.WriteBool (true)
							net.WriteUInt (size, 32)
							net.WriteData (OutUINT8:sub (start + 1, endbyte + 1), size)
							net.Send (finaloutbuffer)
							start = endbyte
							self:TimerAddListeningEvent (0.35)
						end
					end
					coroutine.wrap (self.CooperativeThread)(0)
				end
			end
		)
		coroutine.resume (thread)
		UINT16 = ""
	end
)