modifier_info = class({
	IsHidden = function(self) return true end,
	IsPurgable = function(self) return false end,
	OnCreated = function(self, kv) self.info = kv.info end,
})