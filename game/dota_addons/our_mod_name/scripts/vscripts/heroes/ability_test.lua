LinkLuaModifier("modifier_test", "heroes/ability_test.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_test_reduction", "heroes/ability_test.lua", LUA_MODIFIER_MOTION_NONE)

ability_test = class({})

function ability_test:GetIntrinsicModifierName()
	return "modifier_test"
end

function ability_test:OnUpgrade()
	local mod =	self:GetCaster():FindModifierByNameAndCaster(self:GetIntrinsicModifierName(), self:GetCaster())
	mod:ForceRefresh()
end

modifier_test = class({})

function modifier_test:IsHidden()
	return false
end

function modifier_test:IsPurgable()
	return false
end

function modifier_test:IsPermanent()
	return true
end

function modifier_test:DestroyOnExpire()
	return false
end

function modifier_test:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_ABILITY_FULLY_CAST,
	}
	return funcs
end

function modifier_test:OnCreated( kv )
	self:ForceRefresh()
end

function modifier_test:OnRefresh( kv )
	self.duration = self:GetAbility():GetSpecialValueFor("stack_duration")
end

function modifier_test:OnAbilityFullyCast( keys )
	if IsServer() and keys.unit == self:GetParent() then
		self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_test_reduction", {duration = self.duration})
		self:GetParent():SetModifierStackCount("modifier_test", self:GetCaster(), self:GetStackCount()+1)
		self:SetDuration(self.duration, true)
	end
end


modifier_test_reduction = class({})

function modifier_test_reduction:IsPurgable()
	return false
end

function modifier_test_reduction:IsHidden()
	return true
end

function modifier_test_reduction:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_test_reduction:OnCreated( kv )
	self.reduction = self:GetAbility():GetSpecialValueFor("reduction")

	if IsServer() then
		self.mod = self:GetParent():FindModifierByNameAndCaster("modifier_test", self:GetCaster())
	end
end

function modifier_test_reduction:OnDestroy()
	if IsServer() then
		if self.mod then
			self.mod:DecrementStackCount()
		end
	end
end

function modifier_test_reduction:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE_STACKING,
	}
	return funcs
end

function modifier_test_reduction:GetModifierPercentageCooldownStacking()
	return self.reduction
end


-----------------------------------------------------------------------------------
