function ApplyCurse( keys )
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target
	local duration = ability:GetSpecialValueFor("duration") + 0.01 -- this allows for the last tick to actually occur, since it ticks the same frame that the modifier expires without this.
	local talentDuration = "special_bonus_unique_enigma_2"
--	print("----------- ApplyCurse -----------")

	-- check for talent and increase duration if it exists
	if caster:HasTalent( talentDuration ) then
		duration = duration + caster:FindTalentValue( talentDuration )
--		print("caster has talent, increasing duration!")
	end

	-- apply modifier_void_curse_tick to target
	ability:ApplyDataDrivenModifier(caster, target, keys.modifier, {duration = duration})
--	print("applying tick damage modifier!")
--	print("----------- ApplyCurse -----------")
end

function TickDamage( keys )
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target
	local damage = ability:GetSpecialValueFor("damage")

	local talentDamage = "special_bonus_unique_enigma_1"
--	print("----------- TickDamage -----------")

	-- add a stack of armor/resist reduction to target
	if not target:HasModifier("modifier_void_curse_debuff") then
		ability:ApplyDataDrivenModifier(caster, target, keys.modifier, {})
		target:SetModifierStackCount(keys.modifier, caster, 1)
--		print("target does not have armor debuff, applying armor debuff!")
	else
		target:SetModifierStackCount(keys.modifier, caster, target:GetModifierStackCount(keys.modifier, caster) + 1)
--		print("target has armor debuff, incrementing stack count!")
	end

	-- check for talent and increase damage if it exists
	if caster:HasTalent( talentDamage ) then
		damage = damage + caster:FindTalentValue( talentDamage )
		damageType = DAMAGE_TYPE_PURE
--		print("caster has talent, increasing damage and changing damage_type to pure!")
	end
	-- apply damage
	ApplyDamage({victim = target, attacker = caster, ability = ability, damage = damage, damage_type = ability:GetAbilityDamageType()})
--	print("Ow!")
--	print("----------- TickDamage -----------")
end