--generic classes

GenericStun = {
	IsPurgable = function(self) return false end,
	CheckState = function(self) return {[MODIFIER_STATE_STUNNED] = true,} end,
	OnCreated = function(self, kv) ParticleManager:CreateParticle("particles/generic_gameplay/generic_stunned.vpcf", PATTACH_OVERHEAD_FOLLOW, self:GetParent()) end,
}

GenericDebuff = {
	IsHidden = function(self) return false end,
	IsDebuff = function(self) return true end,
}