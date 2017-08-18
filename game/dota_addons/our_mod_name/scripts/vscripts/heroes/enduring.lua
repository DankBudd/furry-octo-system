LinkLuaModifier("modifier_enduring", "scripts/vscripts/heroes/enduring.lua", LUA_MODIFIER_MOTION_NONE)

enduring_regeneration = class({})

function enduring_regeneration:GetBehavior()
	local behav = DOTA_ABILITY_BEHAVIOR_UNIT_TARGET
	return behav
end

function enduring_regeneration:OnUpgrade()
	if self.old then
		local mod = self.old:FindModifierByNameAndCaster("modifier_enduring", self:GetCaster())
		if mod then
			mod:ForceRefresh()
		end
	end
end

function enduring_regeneration:GetAbilityTextureName()
	if self.time then
		return (self.time >= 1 and "granite_golem_bash" or "granite_golem_hp_aura")
	end
	return "granite_golem_hp_aura"
end

function enduring_regeneration:OnSpellStart()
	GameRules:SetTimeOfDay(GameRules:GetTimeOfDay()+200)
	local target = self:GetCursorTarget()
	if target then
		if self.old and not self.old:IsNull() then
			self.old:RemoveModifierByNameAndCaster("modifier_enduring", self:GetCaster())
		end
		self.old = target
		target:AddNewModifier(self:GetCaster(), self, "modifier_enduring", {})
	end
end

----------------------------------------------------------------

modifier_enduring = class({})

function modifier_enduring:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
	}
	return funcs
end

function modifier_enduring:OnIntervalThink()
	if IsServer() then
		print(GameRules:GetTimeOfDay())
		self:GetAbility().time = GameRules:GetTimeOfDay()
	end
end

function modifier_enduring:OnCreated( kv )
	self:ForceRefresh()
	self:StartIntervalThink(1)
end

function modifier_enduring:OnRefresh( kv )
	self.hp = self:GetAbility():GetSpecialValueFor("health_regen")
	self.mp = self:GetAbility():GetSpecialValueFor("mana_regen")
end

function modifier_enduring:GetModifierConstantHealthRegen()
	return (GameRules:IsDaytime() and self.hp) or 0
end

function modifier_enduring:GetModifierConstantManaRegen()
	return (not GameRules:IsDaytime() and self.mp) or 0
end