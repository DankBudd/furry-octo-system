modifier_custom_aura = class({})

function modifier_custom_aura:OnCreated( kv )
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
	
		self.texture = kv.texture or ""
	end
end

function modifier_custom_aura:GetTexture()
	return self.texture
end

function modifier_custom_aura:IsPurgable()
	return self.purgable
end

function modifier_custom_aura:IsHidden()
	return self.hidden
end

function modifier_custom_aura:RemoveOnDeath()
	return self.removeOnDeath
end

function modifier_custom_aura:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_custom_aura:IsAura()
	return true
end

function modifier_custom_aura:IsAuraActiveOnDeath()
	return self.activeOnDeath
end

function modifier_custom_aura:GetAuraSearchTeam()
	return self.team
end

function modifier_custom_aura:GetAuraSearchType()
	return self.type
end

function modifier_custom_aura:GetAuraSearchFlags()
	return self.flags
end

function modifier_custom_aura:GetAuraRadius()
	return self.radius
end

function modifier_custom_aura:GetModifierAura()
	return self.auraModifier
end
