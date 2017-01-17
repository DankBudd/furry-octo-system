--[[///////////////
/// Void Curse ///
/////////////////]]

function VoidCurse( keys )
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target
	local duration = ability:GetSpecialValueFor("duration") + 0.01 -- this allows for the last tick to actually occur, since it ticks the same frame that the modifier expires without this.
	local talent = "special_bonus_unique_gravity_lord_1"

	-- check for talent and increase duration if it exists
	if caster:HasTalent(talent) then
		duration = duration + caster:FindTalentValue(talent)[2]
	end
	if caster:FindAbilityByName("galaxy"):GetLevel() > 0 and not caster:PassivesDisabled() then
		ability:ApplyDataDrivenModifier(caster, target, "modifier_void_curse_galaxy_debuff", {})
	end

	-- apply modifier_void_curse_tick to target
	ability:ApplyDataDrivenModifier(caster, target, keys.modifier, {duration = duration})
end

function VoidCurseTick( keys )
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target
	local damage = ability:GetSpecialValueFor("damage")
	local talent = "special_bonus_unique_gravity_lord_1"
	local talentValues = caster:FindTalentValue(talent)
	local damageType = ability:GetAbilityDamageType()

	-- add a stack of armor/resist reduction to target
	if not target:HasModifier("modifier_void_curse_debuff") then
		ability:ApplyDataDrivenModifier(caster, target, keys.modifier, {})
		target:SetModifierStackCount(keys.modifier, caster, 1)
	else
		target:SetModifierStackCount(keys.modifier, caster, target:GetModifierStackCount(keys.modifier, caster)+1)
	end
	-- check for talent and increase damage if its skilled
	if caster:HasTalent(talent) then
		damage = damage + talentValues[1]
		if talentValues[3] == 1 then
			damageType = DAMAGE_TYPE_PHYSICAL
		elseif talentValues[3] == 2 then
			damageType = DAMAGE_TYPE_MAGICAL
		elseif talentValues[3] == 4 then
			damageType = DAMAGE_TYPE_PURE
		end
	end

	if caster:HasTalent("special_bonus_unique_gravity_lord_6") and caster:FindAbilityByName("gravity_lord"):GetLevel() > 0 then
		VoidFissure(caster, target)
	end
	-- check if target is effected by black_star and increase damage if it is
	if target:HasModifier("modifier_black_star_vc_bonus_damage") then
		damage = damage * caster:FindAbilityByName("black_star"):GetSpecialValueFor("vc_bonus_damage") * 0.01
	end
	ApplyDamage({victim = target, attacker = caster, ability = ability, damage = damage, damage_type = damageType, damage_flags = DOTA_DAMAGE_FLAG_NONE})
end

function HealLastHitter( keys )
	local caster = keys.caster
	local lastHitter = keys.attacker
	local target = keys.target
	local heal = caster:FindAbilityByName("galaxy"):GetSpecialValueFor("vc_heal") * 0.01
	local talent = "special_bonus_unique_gravity_lord_4"

	if caster:HasTalent(talent) then
		heal = heal + (caster:FindTalentValue(talent)[3] * 0.01)
	end

	if target and target:IsAlive() or lastHitter == caster or caster:PassivesDisabled() then return end
	lastHitter:Heal(lastHitter:GetMaxHealth() * heal, caster)
	lastHitter:GiveMana(lastHitter:GetMaxMana() * heal)
end

--[[/////////////////
/// Gravity Well ///
///////////////////]]

-- probably not refresher compatible
function GravityWellThinker( keys )
	local caster = keys.caster
	local ability = keys.ability
	local galaxy = caster:FindAbilityByName("galaxy")
	local duration = ability:GetSpecialValueFor("duration") + 0.01
	local interval = ability:GetSpecialValueFor("think_interval")
	local radius = ability:GetSpecialValueFor("radius")
	local talent2 = "special_bonus_unique_gravity_lord_2"
	local talent4 = "special_bonus_unique_gravity_lord_4"

	if galaxy:GetLevel() > 0 and not caster:PassivesDisabled() then
		if caster:HasTalent(talent4) then
			radius = radius + caster:FindTalentValue(talent4)[5]
		end
		radius = radius + galaxy:GetSpecialValueFor("gw_radius")
	end

	local talentValues = caster:FindTalentValue(talent2)
	if caster:HasTalent(talent2) then
		duration = talentValues[2]
		interval = talentValues[3]
	end
	ability:ApplyDataDrivenThinker(caster, keys.target_points[1], "modifier_gravity_well_particle", {duration = duration})

	Timers:CreateTimer(function()
		-- initialize duration tracker
		if not ability.endTime then
			ability.endTime = 0.0 
		end
		ability.endTime = ability.endTime + interval

		-- kill timer if gravity_well has reached the end of its duration
		if ability.endTime >= duration then
			ability.endTime = 0.0
			return nil
		end

		-- find targets
		local targets = FindUnitsInRadius(caster:GetTeamNumber(), keys.target_points[1], nil, radius,
						ability:GetAbilityTargetTeam(), ability:GetAbilityTargetType(), ability:GetAbilityTargetFlags(), FIND_ANY_ORDER, false)
		-- iterate through targets and damage/slow them
		for _,target in pairs(targets) do
			SlowTarget(ability, target, keys.modifier, duration)
			DamageTarget(ability, target, keys.modifier, talent2)
			if caster:HasTalent("special_bonus_unique_gravity_lord_6") and caster:FindAbilityByName("gravity_lord"):GetLevel() > 0 then
				VoidFissure(caster, target)
			end
		end

		if galaxy:GetLevel() > 0 and not caster:PassivesDisabled() then
			local allies = FindUnitsInRadius(caster:GetTeamNumber(), keys.target_points[1], nil, radius,
			 				DOTA_UNIT_TARGET_TEAM_FRIENDLY, ability:GetAbilityTargetType(), ability:GetAbilityTargetFlags(), FIND_ANY_ORDER, false)
			for _,ally in pairs(allies) do
				ManaRestore(caster, ally, galaxy)
			end
		end

		-- repeat timer
		return interval
	end)
end

function SlowTarget( ability, target, modifier, duration )
	local caster = ability:GetCaster()
	local debuff_duration = duration + ability:GetSpecialValueFor("debuff_duration")
	local stackCount = target:GetModifierStackCount(modifier, caster)

	-- increment stack count, or apply modifier if target does not have it
	if target:HasModifier(modifier) then
		target:SetModifierStackCount(modifier, caster, stackCount+1)
	else
		ability:ApplyDataDrivenModifier(caster, target, modifier, {duration = debuff_duration})
		target:SetModifierStackCount(modifier, caster, 1)
	end
end

function DamageTarget( ability, target, modifier, talent )
	local caster = ability:GetCaster()
	local damage = ability:GetSpecialValueFor("damage")
	local talentValues = caster:FindTalentValue(talent)
	local galaxy = caster:FindAbilityByName("galaxy")

	-- if talent exists then increase damage based on debuff stacks and talent %value
	if caster:HasTalent(talent) and target:HasModifier(modifier) then
		damage = damage + (damage * target:GetModifierStackCount(modifier, caster) * talentValues[1] * 0.01)
	end
	if galaxy:GetLevel() > 0 and not caster:PassivesDisabled() then
		damage = damage + (caster:GetIntellect() * galaxy:GetSpecialValueFor("gw_int_to_damage") * 0.01)
	end
	ApplyDamage({victim = target, attacker = caster, ability = ability, damage = damage, damage_type = ability:GetAbilityDamageType(), damage_flags = DOTA_DAMAGE_FLAG_NONE})
end

function ManaRestore( caster, ally, galaxy )
	if ally:GetManaPercent() == 100 or ally == caster or caster:PassivesDisabled() then return end
	ally:GiveMana(ally:GetMaxMana() * galaxy:GetSpecialValueFor("gw_ally_mana_restore") * 0.01)
end

--[[/////////////////
/// Gravity Bolt ///
///////////////////]]

-- on projectile hit unit damage unit and heal caster
function GravityBoltHitUnit( keys )
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target
	local talent = "special_bonus_unique_gravity_lord_3"
	local talentValues = caster:FindTalentValue(talent)

	local casterInt = caster:GetIntellect()
	local intDamage = ability:GetSpecialValueFor("int_to_damage") * 0.01
	local amtToHeal = ability:GetSpecialValueFor("self_heal") * 0.01

	if caster:HasTalent(talent) then
		intDamage = intDamage + (talentValues[1] * 0.01)
	end

	if caster:HasTalent("special_bonus_unique_gravity_lord_6") and caster:FindAbilityByName("gravity_lord"):GetLevel() > 0 then
		VoidFissure(caster, target)
	end

	local damage = ability:GetAbilityDamage() + (intDamage * casterInt)
	local heal = damage * amtToHeal
	ApplyDamage({victim = target, attacker = caster, ability = ability, damage = damage, damage_type = ability:GetAbilityDamageType(), damage_flags = DOTA_DAMAGE_FLAG_NONE})
	caster:Heal(heal, caster)
end

-- if talent then reduce cooldown
function GravityBoltCooldown( keys )
	local caster = keys.caster
	local ability = keys.ability

	if caster:HasTalent("special_bonus_unique_gravity_lord_3") then
		ability:EndCooldown()
		ability:StartCooldown(ability:GetCooldown(ability:GetLevel()-1) - caster:FindTalentValue("special_bonus_unique_gravity_lord_3")[4])
	end
end

-- if talent then apply int bonus modifier to caster
function GravityBoltModifier( keys )
	local caster = keys.caster
	local ability = keys.ability

	if caster:HasTalent("special_bonus_unique_gravity_lord_3") then
		if caster:HasModifier(keys.modifier) then 
			caster:SetModifierStackCount(keys.modifier, caster, caster:GetModifierStackCount(keys.modifier, caster) + 1)
		else
			ability:ApplyDataDrivenModifier(caster, caster, keys.modifier, {})
		end
	end
end

function GravityBoltManaCost( keys )
	local caster = keys.caster
	local manaCostPct = caster:FindTalentValue("special_bonus_unique_gravity_lord_3")[3] * 0.01

	if caster:HasTalent("special_bonus_unique_gravity_lord_3") then
		caster:SetMana(caster:GetMana() * manaCostPct)
	end
end

--[[///////////
/// Galaxy ///
/////////////]]

function GalaxyManaCostReduction( keys )
	local caster = keys.caster
	local galaxy = caster:FindAbilityByName("galaxy")
	local talent = "special_bonus_unique_gravity_lord_4"
	local manaCostReduction

	if galaxy:GetLevel() > 0 and not caster:PassivesDisabled() then
		manaCostReduction = galaxy:GetSpecialValueFor("mana_cost_reduction")
		if caster:HasTalent(talent) then
			manaCostReduction = manaCostReduction + caster:FindTalentValue(talent)[2]
		end
		caster:SetMana(caster:GetMana() + manaCostReduction)
	end
end

function DisableGalaxyPassive( keys )
	local caster = keys.caster
	local ability = keys.ability
	local modifierToRemove = keys.modifier
	local modifierToApply = keys.temp_modifier

	local stackCount = caster:GetModifierStackCount(modifierToApply, caster)
	local galaxyCount = ability:GetSpecialValueFor("cd_reduction")
	if caster:HasTalent(talent) then
		local talentCount = galaxyCount + caster:FindTalentValue(talent)[1]
	end

	if caster:PassivesDisabled() or (caster:HasTalent(talent) and not stackCount == talentCount) then
		caster:ApplyDataDrivenModifier(caster, caster, modifierToApply, {})
		caster:RemoveModifierByNameAndCaster(modifierToRemove, caster)
	end
end

function EnableGalaxyPassive( keys )
	local caster = keys.caster
	local ability = keys.ability
	local modifierToRemove = keys.temp_modifier
	local modifierToApply = keys.modifier
	local talent = "special_bonus_unique_gravity_lord_4"

	local stackCount = ability:GetSpecialValueFor("cd_reduction")
	if caster:HasTalent(talent) then
		stackCount = stackCount + caster:FindTalentValue(talent)[1]
	end

	if not caster:PassivesDisabled() then
		caster:ApplyDataDrivenModifier(caster, target, modifierToApply, {})
		caster:SetModifierStackCount(modifierToApply, caster, stackCount)
		caster:RemoveModifierByNameAndCaster(modifierToRemove, caster)
	end
end

--[[///////////////
/// Black Star ///
/////////////////]]

function BlackStar( keys )
	local caster = keys.caster
	local ability = keys.ability
	local radius = ability:GetSpecialValueFor("radius")
	local stunDuration = ability:GetSpecialValueFor("stun_duration")
	local intDamage = ability:GetSpecialValueFor("int_to_damage")
	local damage = ability:GetAbilityDamage()
	local talent = "special_bonus_unique_gravity_lord_5"

	local hasTalent = caster:HasTalent(talent)
	if hasTalent then
		intDamage = intDamage + caster:FindTalentValue(talent)[4]
		damage = damage + caster:FindTalentValue(talent)[3]
		stunDuration = stunDuration + caster:GetIntellect() * 0.01
	end
	damage = damage + (damage * intDamage * 0.01)

	local targets = FindUnitsInRadius(caster:GetTeamNumber(), keys.target_points[1], nil, radius,
					ability:GetAbilityTargetTeam(), ability:GetAbilityTargetType(), ability:GetAbilityTargetFlags(), FIND_ANY_ORDER, false)
	for _,target in pairs(targets) do
		if target ~= nil then
			target:AddNewModifier(caster, ability, "modifier_stunned", {duration = stunDuration})
			ApplyDamage({victim = target, attacker = caster, ability = ability, damage = damage, damage_type = ability:GetAbilityDamageType(), damage_flags = DOTA_DAMAGE_FLAG_NONE})
			if hasTalent then
				BlackStarVoidCurse(caster, caster:FindAbilityByName("void_curse"), target)
			end
			if caster:HasTalent("special_bonus_unique_gravity_lord_6") and caster:FindAbilityByName("gravity_lord"):GetLevel() > 0 then
				VoidFissure(caster, target)
			end
		end
	end

	local dummy = CreateUnitByName("npc_dummy_unit", keys.target_points[1], false, nil, nil, caster:GetTeamNumber())
	EmitSoundOn("Hero_Phoenix.SuperNova.Explode", dummy)

	local pfxName = "particles/units/heroes/hero_phoenix/phoenix_supernova_reborn.vpcf"
	local pfx = ParticleManager:CreateParticle( pfxName, PATTACH_ABSORIGIN, dummy )
--	ParticleManager:SetParticleControlEnt( pfx, 0, dummy, PATTACH_POINT_FOLLOW, "follow_origin", dummy:GetAbsOrigin(), true )
--	ParticleManager:SetParticleControlEnt( pfx, 1, dummy, PATTACH_POINT_FOLLOW, "attach_hitloc", dummy:GetAbsOrigin(), true )

	if hasTalent then
		Timers:CreateTimer({0.4, function()
			EmitSoundOn("Hero_Silencer.LastWord.Cast", dummy)
		end})
	end
end

function BlackStarVoidCurse( caster, ability, target )
	local duration = caster:FindAbilityByName("void_curse"):GetSpecialValueFor("duration") + 0.01 -- this allows for the last tick to actually occur, since it ticks the same frame that the modifier expires without this.
	local talent = "special_bonus_unique_gravity_lord_1"

	-- check for talent and increase duration if it exists
	if caster:HasTalent(talent) then
		duration = duration + caster:FindTalentValue(talent)[2]
	end
	if caster:FindAbilityByName("galaxy"):GetLevel() > 0 and not caster:PassivesDisabled() then
		ability:ApplyDataDrivenModifier(caster, target, "modifier_void_curse_galaxy_debuff", {})
	end

	-- apply modifier_void_curse_tick to target
	ability:ApplyDataDrivenModifier(caster, target, "modifier_void_curse_tick", {duration = duration})
end

function BlackStarCooldown( keys )
	local caster = keys.caster
	local ability = keys.ability
	local talent = "special_bonus_unique_gravity_lord_5"

	if caster:HasTalent(talent) then
		ability:EndCooldown()
		ability:StartCooldown(ability:GetCooldown(ability:GetLevel()-1) - caster:FindTalentValue(talent)[2])
	end
end

--[[/////////////////
/// Gravity Lord ///
///////////////////]]

function DoubleGravityLordBonuses( keys )
	local caster = keys.caster
	local ability = keys.ability
	-- double gravity lord bonuses if caster has talent and bonuses have not already been doubled.
	if caster:HasTalent("special_bonus_unique_gravity_lord_6") and not caster.hasDoubled then
		ability:ApplyDataDrivenModifier(caster, target, keys.modifier, {})
		ability.hasDoubled = true
	end
end

function LevelHiddenAbilityCastRange( keys )
	local abilityToLevel = keys.caster:FindAbilityByName("gravity_lord_cast_range_bonus")
	local ability = keys.ability
	if abilityToLevel:GetLevel() == ability:GetLevel() then return end
	abilityToLevel:SetLevel(ability:GetLevel())
end

-- Author: SwordBacon
function SetCastRange(keys)
	local caster = keys.caster
	local ability = keys.ability
	if ability:GetLevel() <= 0 then return end
    -- FIXME: Remove this hack once the proper property is released.
	-- Remove old cast range
	caster:RemoveModifierByName("modifier_item_aether_lens")
	-- Replace cast range
	caster:AddNewModifier(caster, ability, "modifier_item_aether_lens", {}) 
end

function GravityLordManaBonus( keys )
	local caster = keys.caster
	local ability = keys.ability
	local manaBonus = ability:GetSpecialValueFor("mana_bonus_tooltip") * 0.01
	local stackCount = caster:CalculateBaseMana(true, true) * manaBonus
	local talent = "special_bonus_unique_gravity_lord_6"

	if caster:HasTalent(talent) then
		stackCount = stackCount * caster:FindTalentValue(talent)[1]
	end

	caster:SetModifierStackCount(keys.modifier, caster, stackCount)
	caster:CalculateStatBonus()
end

function VoidFissure( caster, target )
	local gravityLord = caster:FindAbilityByName("gravity_lord")
	local talent = "special_bonus_unique_gravity_lord_6"
	local modifier = "modifier_gravity_lord_void_fissure"

	if caster:HasTalent(talent) and gravityLord:GetLevel() > 0 then
		if target ~= nil then
			if not target:HasModifier(modifier) then
				gravityLord:ApplyDataDrivenModifier(caster, target, modifier, {})
			else
				target:SetModifierStackCount(modifier, caster, target:GetModifierStackCount(modifier, caster)+1)
			end
		end
	end
end