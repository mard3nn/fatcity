include("shared.lua")

function ENT:Draw()
	self:DrawModel()
	if self:GetPowered() then
		self:GroundWash()
	end
end
