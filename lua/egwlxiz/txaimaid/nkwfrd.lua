-- Timestamp: 05/27/20
GTS  		   	   = GTS or {}
local self 		   = {}
local include 	   = include
local AddCSLuaFile = AddCSLuaFile

function self:InstructionsMounted()
	return function ()
		local Constructor = Constructor or {}
		Constructor ["InternalDispatcher [LiveConstructor]"] = "egwlxiz/wvwzndyn/ynywom.lua"
		Constructor ["InternalDispatcher [Signature]"] 		 = "egwlxiz/zjfvyr.lua"
		Constructor ["InternalDispatcher [ObjectFactory]"]   = "egwlxiz/wvwzndyn/raajqz.lua"
		Constructor ["InternalDispatcher [GlobalDispatch]"]  = "egwlxiz/gasqtsmw/ovugpv.lua"
		Constructor ["InternalDispatcher [ScaledDispatch]"]  = "egwlxiz/gasqtsmw/jejlcd.lua"
		Constructor ["InternalDispatcher [Acceleration]"]    = "egwlxiz/gasqtsmw/lysvzz.lua"
		Constructor ["InternalDispatcher [Deceleration]"]    = "egwlxiz/gasqtsmw/ximktj.lua"
		Constructor ["InternalDispatcher [Interpolator]"]    = "egwlxiz/txaimaid/hmlous.lua"
		Constructor ["InternalDispatcher [BCompanyGroup]"]   = "egwlxiz/txaimaid/ttjkax.lua"
		return Constructor
	end
end

function self:GlobalDispatcher( file )
	if file ~= nil and type(file) == "string" then
		AddCSLuaFile( file )
		include( file )
		return "Dispatched successfully: { " .. file .. " }."
	else
		return "GTS:Dispatcher : Empty allocation provided."
	end
end

self:GlobalDispatcher( self:InstructionsMounted()() ["InternalDispatcher [LiveConstructor]"] )
self:GlobalDispatcher( self:InstructionsMounted()() ["InternalDispatcher [Signature]"] )
self:GlobalDispatcher( self:InstructionsMounted()() ["InternalDispatcher [ObjectFactory]"] )
self:GlobalDispatcher( self:InstructionsMounted()() ["InternalDispatcher [GlobalDispatch]"] )
self:GlobalDispatcher( self:InstructionsMounted()() ["InternalDispatcher [ScaledDispatch]"] )
if ( SERVER ) then
	self:GlobalDispatcher( self:InstructionsMounted()() ["InternalDispatcher [Interpolator]"] )
	self:GlobalDispatcher( self:InstructionsMounted()() ["InternalDispatcher [Acceleration]"] )
end
self:GlobalDispatcher( self:InstructionsMounted()() ["InternalDispatcher [Deceleration]"] )
self:GlobalDispatcher( self:InstructionsMounted()() ["InternalDispatcher [BCompanyGroup]"] )
if GTS.IsInDebugMode then
	MsgC(Color(255,0,0), "[", Color(0,255,255), "GimmeThatScreen", Color(255,0,0),"]: ", Color(0,255,255) , "GTS has loaded successfully!" .. "\n")
end