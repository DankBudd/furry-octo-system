if not modifier_enigma_mana_bonus then
	modifier_enigma_mana_bonus = class({})
end


function modifier_enigma_mana_bonus:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MANA_BONUS,
	}
	return funcs
end

--FIX error on line 16? GetSpecialValueFor() is 
function modifier_enigma_mana_bonus:OnCreated( kv )
	local maxMana = self:GetCaster():GetMaxMana()
	local manaBonusPct = self:GetAbility:GetSpecialValueFor("mana_bonus") * 0.01
	self.manaBonus = maxMana * manaBonusPct

--	self:ForceRefresh()
--	self:CalculateStatBonus()
end

--[[
function modifier_enigma_mana_bonus:OnCreated( kv )
	if IsServer() then
		self:StartIntervalThink(0.1)
	end
end

function modifier_enigma_mana_bonus:OnIntervalThink()
	if IsServer() then
		local maxMana = self:GetCaster():GetMaxMana()
		local manaBonusPct = self:GetCaster():FindAbilityByName("enigma_passive"):GetSpecialValueFor("mana_bonus")
		self.manaBonus = maxMana * manaBonusPct

		self:ForceRefresh()
--		self:CalculateStatBonus()
	end
end
]]

function modifier_enigma_mana_bonus:GetModifierManaBonus()
	return self.manaBonus
end

function modifier_enigma_mana_bonus:IsPurgable()
	return false
end

function modifier_enigma_mana_bonus:IsDebuff()
	return false
end

function modifier_enigma_mana_bonus:IsHidden()
	return true
end