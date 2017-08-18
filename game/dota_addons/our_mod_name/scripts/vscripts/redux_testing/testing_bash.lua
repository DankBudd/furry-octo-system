LinkLuaModifier("modifier_testing_bash", "redux_testing/testing_bash.lua", LUA_MODIFIER_MOTION_NONE)

testing_bash = class({})

function testing_bash:GetIntrinsicModifierName()
	return "modifier_testing_bash"
end

modifier_testing_bash = class({
	IsHidden = function(self) return self:GetParent() == self:GetCaster() end,
	IsPurgable = function(self) return self:GetParent() ~= self:GetCaster() end,
	IsDebuff = function(self) return self:GetParent() ~= self:GetCaster() end,
	IsStunDebuff = function(self) return self:GetParent() ~= self:GetCaster() end,
	DeclareFunctions = function(self) return {MODIFIER_EVENT_ON_ATTACK_LANDED, MODIFIER_PROPERTY_OVERRIDE_ANIMATION} end,
	GetAttributes = function(self) return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end,

	CheckState = function(self)
		if self:GetParent() == self:GetCaster() then return end
		return {[MODIFIER_STATE_STUNNED] = true,}
	end,

	OnCreated = function(self, kv)
		if not IsServer() then return end
		self.damage = self:GetAbility():GetAbilityDamage()
		self.dType = self:GetAbility():GetAbilityDamageType()
		self.duration = self:GetAbility():GetSpecialValueFor("duration") or 1.0
		self.chance = self:GetAbility():GetSpecialValueFor("chance") or 25
	end,

	GetOverrideAnimation = function(self)
		if self:GetParent() == self:GetCaster() then return end
		return ACT_DOTA_DISABLED
	end,

	OnAttackLanded = function(self, keys)
		if not IsServer() or keys.attacker ~= self:GetParent() then return end
		if self:GetParent() ~= self:GetCaster() then return end
		if not RollPercentage(self.chance) then return end
		ApplyDamage({victim = keys.target, attacker = keys.attacker, ability = self:GetAbility(), damage = self.damage, damage_type = self.dType})
		keys.target:AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_testing_bash", {duration = self.duration})
		EmitSoundOn("DOTA_Item.SkullBasher", keys.target)
	end,
})
