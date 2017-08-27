daisho_blade_master = class({})

function dashio_blade_master:GetIntrinsicModifierName()
	return "modifier_daisho_blade_master"
end


modifier_daisho_blade_master = class({
	IsHidden = function(self) return true end,
	IsPurgable = function(self) return false end,
	IsPermanent = function(self) return true end,
	RemoveOnDeath = function(self) return false end,
	DeclareFunctions = function(self) return {MODIFIER_PROPERTY_STATS_AGILITY_BONUS, MODIFIER_PROPERTY_HEALTH_BONUS, MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS, MODIFIER_PROPERTY_EVASION_CONSTANT,} end,

	GetModifierHealthBonus = function(self) return self.hp end,
	GetModifierEvasion_Constant = function(self) return self.evasion end,
	GetModifierBonusStats_Agility = function(self) return self.agiBonus end,
	GetModifierMagicalResistanceBonus = function(self) return self.resist end,

	OnCreated = function(self)
		self.resist = (-1) * self:GetAbility():GetSpecialValueFor("resist_loss")
		self.agi = self:GetAbility():GetSpecialValueFor("agi_per_item")*0.01
		self.hpPct = self:GetAbility():GetSpecialValueFor("hp_pct")
		self.hpPctMax = self:GetAbility():GetSpecialValueFor("hp_pct_max")
		self.evasion = self:GetAbility():GetSpecialValueFor("evasion")

		self:StartIntervalThink(0.5)
	end,

	OnIntervalThink = function(self)
		local count = 0
		local agi = 0
		for i=0,8 do
			local item = self:GetParent():GetItemInSlot(i)
			if item then
				local bonus = item:GetSpecialValueFor("agility_bonus")
				if bonus then
					agi = agi + (bonus * self.agi)
					count = count+1
				end
			end
		end

		self.agiBonus = bonus
		self.hp = count*self.hpPct
		if self.hp > 20 then
			self.hp = 20
		end
		self.hp = self:GetParent():GetBaseMaxHealth() * self.hp * 0.01
	end,
})