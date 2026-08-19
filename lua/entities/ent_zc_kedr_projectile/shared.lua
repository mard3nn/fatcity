ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "KEDR Interceptor"
ENT.Spawnable = false

function ENT:SetupDataTables()
	self:NetworkVar("Entity", 0, "Target")
end
