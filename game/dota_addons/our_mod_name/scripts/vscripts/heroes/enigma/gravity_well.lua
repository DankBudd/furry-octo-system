LinkLuaModifier( "modifier_gravity_well_aura", "heroes/enigma/modifier_gravity_well_aura.lua", LUA_MODIFIER_MOTION_NONE )

function CreateGravityWellThinkerSlow( keys )
	local caster = keys.caster
	local ability = keys.ability

	CreateModifierThinker(caster, ability, "modifier_gravity_well_aura", {}, keys.target_points[1], caster:GetTeamNumber(), false)
end

function DamageTargets( keys )
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target

	local damage = ability:GetSpecialValueFor("damage")
	local talentDamage = "special_bonus_unique_enigma_3"

	-- if talent exists then increase damage based on debuff stacks and talent %value
	if caster:HasTalent( talentDamage ) and target:HasModifier( "modifier_gravity_well_aura" ) then
		damage = damage + (damage * (target:GetModifierStackCount("modifier_gravity_well_aura", caster) * caster:FindTalentValue( talentDamage ) * 0.01))
	end
	ApplyDamage({victim = target, attacker = caster, ability = ability, damage = damage, damage_type = ability:GetAbilityDamageType()})
end
