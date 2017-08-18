LinkLuaModifier("modifier_gl_malefice", "scripts/vscripts/heroes/enigma/gl_malefice", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_gl_malefice_lesser", "scripts/vscripts/heroes/enigma/gl_malefice", LUA_MODIFIER_MOTION_NONE)

require('scripts/vscripts/heroes/enigma/gl')

gl_malefice = class({})

function gl_malefice:GetBehavior()
	local behav = DOTA_ABILITY_BEHAVIOR_UNIT_TARGET 
	return behav
end

function gl_malefice:GetCastRange( vLocation, hTarget )
	return self.BaseClass.GetCastRange(self, vLocation, hTarget)
end

function gl_malefice:GetManaCost()
	local manaCost = self.BaseClass.GetManaCost(self, self:GetLevel())
--	local galaxy = self:GetCaster():FindAbilityByName("gl_galaxy")
	if galaxy then
		if galaxy:GetLevel() > 0 and not self:GetCaster():PassivesDisabled() then
			local reduction = galaxy:GetSpecialValueFor("mana_cost_reduction")
			if caster:HasTalent("special_bonus_unique_gravity_lord_4") then
				reduction = reduction + caster:FindTalentValues("special_bonus_unique_gravity_lord_4")[2]
			end
			manaCost = manaCost - reduction
		end
	end
	return manaCost
end

function gl_malefice:CastFilterResultTarget( target )
	if IsServer() then
		local result = UnitFilter(target, self:GetAbilityTargetTeam(), self:GetAbilityTargetType(), DOTA_UNIT_TARGET_FLAG_NONE, self:GetCaster():GetTeamNumber())
		return result
	end
	return UF_SUCCESS
end

function gl_malefice:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	if not target or target:TriggerSpellAbsorb(self) then return end

	local duration = self:GetSpecialValueFor("duration")

	EmitSoundOn("Hero_Silencer.LastWord.Cast", target)

	-- talent check
	if caster:HasTalent("special_bonus_unique_gravity_lord_1") then
		duration = duration+caster:FindTalentValues("special_bonus_unique_gravity_lord_1")["duration"]
	end
	-- galaxy check
	local galaxy = caster:FindAbilityByName("galaxy")
	if galaxy then
		if galaxy:GetLevel() > 0 and not caster:PassivesDisabled() then
	--		target:AddNewModifier(caster, self, "", {})
		end
	end

	target:AddNewModifier(caster, self, "modifier_gl_malefice", {duration = duration})
end

------------------------------------------------------

modifier_gl_malefice = class({})

function modifier_gl_malefice:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
	}
	return funcs
end

function modifier_gl_malefice:GetEffectName()
	return "particles/units/heroes/hero_silencer/silencer_last_word_status.vpcf"
end

function modifier_gl_malefice:GetEffectAttachType()
	return "follow_origin"
end

function modifier_gl_malefice:IsDebuff()
	return true
end

function modifier_gl_malefice:IsAura()
	if self:GetCaster():HasTalent("special_bonus_unique_gravity_lord_1") then
		return true
	end
	return false
end

function modifier_gl_malefice:GetModifierAura()
	return "modifier_gl_malefice_lesser"
end

function modifier_gl_malefice:GetAuraRadius()
	if self:GetCaster():HasTalent("special_bonus_unique_gravity_lord_1") then
		return self:GetCaster():FindTalentValues("special_bonus_unique_gravity_lord_1")["aura_radius"]
	end
	return 0
end

function modifier_gl_malefice:GetAuraSearchTeam()
	return self:GetAbility():GetAbilityTargetTeam()
end

function modifier_gl_malefice:GetAuraSearchType()
	return self:GetAbility():GetAbilityTargetType()
end

function modifier_gl_malefice:GetAuraSearchFlags()
	return self:GetAbility():GetAbilityTargetFlags()
end

function modifier_gl_malefice:OnCreated( kv )
	self.armorLoss = self:GetAbility():GetSpecialValueFor("armor_loss")
	self.resistLoss = self:GetAbility():GetSpecialValueFor("resist_loss")

	local damage = self:GetAbility():GetSpecialValueFor("damage")
	if self:GetCaster():HasTalent("special_bonus_unique_gravity_lord_1") then
--		damage = damage + self:GetCaster():FindTalentValues("special_bonus_unique_gravity_lord_1")["bonus_damage"]
	end
	self.damage = damage

	self:StartIntervalThink(self:GetAbility():GetSpecialValueFor("tick_rate"))
end

function modifier_gl_malefice:OnRefresh( kv )
	self.armorLoss = self:GetSpecialValueFor("armor_loss")
	self.resistLoss = self:GetSpecialValueFor("resist_loss")

	local damage = self:GetSpecialValueFor("damage")
	if self:GetCaster():HasTalent("special_bonus_unique_gravity_lord_1") then
--		damage = damage + self:GetCaster():FindTalentValues("special_bonus_unique_gravity_lord_1")["bonus_damage"]
	end
	self.damage = damage

	StartIntervalThink(self:GetSpecialValueFor("tick_rate"))
end

function modifier_gl_malefice:OnIntervalThink()
	local damage = self.damage

	--bonus damage from ult
	if self:GetParent():HasModifier("modifier_gl_black_hole_malefice") then
--		damage = damage * self:GetCaster():FindAbilityByName("gl_black_hole"):GetSpecialValueFor("bonus_damage") * 0.01
	end

	ApplyVoidFissure(self:GetCaster(), self:GetParent())

	ApplyDamage({victim = self:GetParent(), attacker = self:GetCaster(), ability = self:GetAbility(), damage = damage, damage_type = self:GetAbility():GetAbilityDamageType(), damage_flags = DOTA_DAMAGE_FLAG_NONE})

	self:IncrementStackCount()

	local units = FindUnitsInRadius(self:GetCaster():GetTeamNumber(), self:GetParent():GetAbsOrigin(), nil, self:GetCaster():FindTalentValues("special_bonus_unique_gravity_lord_1")["aura_radius"], self:GetAbility():GetAbilityTargetTeam(), self:GetAbility():GetAbilityTargetType(), self:GetAbility():GetAbilityTargetFlags(), FIND_ANY_ORDER, false)
	for _,unit in pairs(units) do
		if unit:HasModifier("modifier_gl_malefice_lesser") then
			local mod = unit:FindModifierByNameAndCaster("modifier_gl_malefice_lesser", self:GetCaster())
			mod:IncrementStackCount()
			mod.auraMod = self
		end
	end
end

function modifier_gl_malefice:GetModifierPhysicalArmorBonus()
	return self.armorLoss * self:GetStackCount()
end

function modifier_gl_malefice:GetModifierMagicalResistanceBonus()
	return self.resistLoss * self:GetStackCount()
end

------------------------------------------------------------------

modifier_gl_malefice_lesser = class({})

function modifier_gl_malefice_lesser:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
	}
	return funcs
end

function modifier_gl_malefice_lesser:IsDebuff()
	return true
end

function modifier_gl_malefice_lesser:OnCreated( kv )
	if not self.auraMod then
	 	self.damage = 0
		self.armorLoss = 0
		self.resistLoss = 0
		return
	end
	local tVal = self:GetCaster():FindTalentValues("special_bonus_unique_gravity_lord_1")
	self.damage = self.auraMod.damage * tVal["splash_damage_pct"] * 0.01
	self.armorLoss = self.auraMod.armorLoss * tVal["reduced_reductions"] * 0.01
	self.resistLoss = self.auraMod.resistLoss * tVal["reduced_reductions"] * 0.01
end

function modifier_gl_malefice_lesser:OnRefresh( kv )
	if not self.auraMod then
	 	self.damage = 0
		self.armorLoss = 0
		self.resistLoss = 0
		return
	end
	local tVal = self:GetCaster():FindTalentValues("special_bonus_unique_gravity_lord_1")
	self.damage = self.auraMod.damage * tVal["splash_damage_pct"] * 0.01
	self.armorLoss = self.auraMod.armorLoss * tVal["reduced_reductions"] * 0.01
	self.resistLoss = self.auraMod.resistLoss * tVal["reduced_reductions"] * 0.01
end

function modifier_gl_malefice_lesser:OnStackCountChanged( prevStack )
	ApplyDamage({victim = self:GetParent(), attacker = self:GetCaster(), ability = self:GetAbility(), damage = self.damage, damage_type = self:GetAbility():GetAbilityDamageType()})
	--pull unit towards aura parent
	local direction = (self:GetParent():GetAbsOrigin() - self.auraMod:GetParent():GetAbsOrigin()):Normalized()
	local distance = (self:GetParent():GetAbsOrigin() - self.auraMod:GetParent():GetAbsOrigin()):Length2D() / 2
	local speed = distance * 1/30
	local verticle = nil
	local shouldStun = false
	self:GetParent():KnockbackUnit(distance, direction, speed, vertical, shouldStun)
end

function modifier_gl_malefice_lesser:GetModifierPhysicalArmorBonus()
	return self.armorLoss * self:GetStackCount()
end

function modifier_gl_malefice_lesser:GetModifierMagicalResistanceBonus()
	return self.resistLoss * self:GetStackCount()
end



