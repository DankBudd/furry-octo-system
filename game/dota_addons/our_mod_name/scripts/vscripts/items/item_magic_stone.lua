function MagicStone( keys )
	local caster = keys.caster
	local ability = keys.ability
	
	local baseDamage = ability:GetSpecialValueFor("base_damage")
	local intToDamage = ability:GetSpecialValueFor("int_pct")
	local damage = baseDamage + (caster:GetIntellect() * intToDamage)

	ApplyDamage({victim = target, attacker = caster, ability = ability, damage = damage, damage_type = ability:GetAbilityDamageType(), damage_flags = DOTA_DAMAGE_FLAG_NONE})
end
