function DivineRip( keys )
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target
	local stunDuration = ability:GetSpecialValueFor("stun_duration")
	local radius = ability:GetSpecialValueFor("radius")
	local reduction = ability:GetSpecialValueFor("aoe_reduced")

	local baseDamage = ability:GetSpecialValueFor("damage")
	local intToDamage = ability:GetSpecialValueFor("int_pct")
	local intellect = caster:GetIntellect()
	local damage = baseDamage + (intellect * intToDamage)

	-- apply damage and stun to main target
	ApplyDamage({victim = target, attacker = caster, ability = ability, damage = damage, damage_type = ability:GetAbilityDamageType(), damage_flags = DOTA_DAMAGE_FLAG_NONE})
	target:AddNewModifier(caster, ability, "modifier_stunned", {duration = stunDuration})

	-- apply reduced damage and reduced duration stun to surrounding units
	local units = FindUnitsInRadius(caster:GetTeamNumber(), target:GetAbsOrigin(), nil, radius, ability:GetAbilityTargetTeam(), ability:GetAbilityTargetType(), DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER,false)
	if #units <= 1 then return end
	damage = damage * reduction
	stunDuration = stunDuration * reduction
	for _,unit in pairs(units) do
		if not unit == target then
			ApplyDamage({victim = unit, attacker = caster, ability = ability, damage = damage, damage_type = ability:GetAbilityDamageType(), damage_flags = DOTA_DAMAGE_FLAG_NONE})
			unit:AddNewModifier(caster, ability, "modifier_stunned", {duration = stunDuration})
		end
	end
end

function HellRip( keys )
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target
	local disarmDuration = ability:GetSpecialValueFor("disarm_duration")
	ability.disarmDuration = disarmDuration
	local radius = ability:GetSpecialValueFor("radius")
	local reduction = ability:GetSpecialValueFor("aoe_reduced")

	local baseDamage = ability:GetSpecialValueFor("damage")
	local casterDamage = keys.attack_damage
	local casterDamagePct = ability:GetSpecialValueFor("damage_pct")

	local damage = baseDamage + (casterDamage + casterDamagePct)

	-- need to change this probably for whatever we use to recognize bosses
	if target:IsConsideredHero() then
		ability.disarmDuration = ability.disarmDuration/2
	end

	ApplyDamage({victim = target, attacker = caster, ability = ability, damage = damage, damage_type = ability:GetAbilityDamageType(), damage_flags = DOTA_DAMAGE_FLAG_NONE})
	ability:ApplyDataDrivenModifier(caster, target, keys.modifier, {duration = ability.disarmDuration})

	local units = FindUnitsInRadius(caster:GetTeamNumber(), target:GetAbsOrigin(), nil, radius, ability:GetAbilityTargetTeam(), ability:GetAbilityTargetType(), DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER,false)
	if #units <= 1 then return end
	damage = damage * reduction
	disarmDuration = disarmDuration * reduction
	for _,unit in pairs(units) do
		if not unit == target then
			ApplyDamage({victim = unit, attacker = caster, ability = ability, damage = damage, damage_type = ability:GetAbilityDamageType(), damage_flags = DOTA_DAMAGE_FLAG_NONE})
			ability:ApplyDataDrivenModifier(caster, target, keys.modifier, {duration = disarmDuration})
		end
	end
end

function RealmProc( keys )
	local caster = keys.caster
	local ability = keys.ability

	local baseStacks = ability:GetSpecialValueFor("item_damage")
	local damagePct = ability:GetSpecialValueFor("item_damage_pct")
	local stackCount = baseStacks + (caster:GetAttackDamage() * damagePct)

	ability:ApplyDataDrivenModifier(caster, caster, keys.modifier, {})
	caster:SetModifierStackCount(keys.modifier, caster, stackCount)
end
