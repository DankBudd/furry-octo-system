modifier_custom_aura = class({

	OnCreated = function(self, kv)
		if IsServer() then
			self.radius = kv.radius or 1100
			self.type   = kv.type 	or DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC
			self.team   = kv.team 	or DOTA_UNIT_TARGET_TEAM_ENEMY
			self.flags  = kv.flags  or DOTA_UNIT_TARGET_FLAG_NONE

			self.purgable = kv.purgable or false
			self.hidden   = kv.hidden 	or true

			self.activeOnDeath = kv.activeOnDeath or false
			self.removeOnDeath = kv.removeOnDeath or true
			self.auraModifier  = kv.auraModifier  or "modifier_truesight"
		
			self.texture = kv.texture or nil

			if not self.texture and self:GetAbility() then
				self.texture = self:GetAbility():GetTexture()
			end
		end
	end,

	IsAura = function(self) return true end,
	IsHidden = function(self) return self.hidden end,
	GetTexture = function(self) return self.texture end,
	IsPurgable = function(self) return self.purgable end,
	GetAuraRadius = function(self) return self.radius end,
	RemoveOnDeath = function(self) return self.removeOnDeath end,
	GetAttributes = function(self) return MODIFIER_ATTRIBUTE_MULTIPLE end,
	GetModifierAura = function(self) return self.auraModifier end,
	GetAuraSearchTeam = function(self) return self.team end,
	GetAuraSearchType = function(self) return self.type end,
	GetAuraSearchFlags = function(self) return self.flags end,
	IsAuraActiveOnDeath = function(self) return self.activeOnDeath end,
})