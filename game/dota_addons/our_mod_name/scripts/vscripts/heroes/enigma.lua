--[[///////////////
/// Void Curse ///
/////////////////]]

function VoidCurse( keys )
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target
	local duration = ability:GetSpecialValueFor("duration") + 0.01
	local talent = "special_bonus_unique_gravity_lord_1"

	-- check for talent and increase duration if it exists
	if caster:HasTalent(talent) then
		duration = duration + caster:FindTalentValues(talent)[2]
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
	local talentValues = caster:FindTalentValues(talent)
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
		damageType = caster:FindAbilityByName("special_bonus_unique_gravity_lord_1"):GetAbilityDamageType()
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
		heal = heal + (caster:FindTalentValues(talent)[3] * 0.01)
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
			radius = radius + caster:FindTalentValues(talent4)[5]
		end
		radius = radius + galaxy:GetSpecialValueFor("gw_radius")
	end

	local talentValues = caster:FindTalentValues(talent2)
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
	local talentValues = caster:FindTalentValues(talent)
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

function GravityBoltHitUnit( keys )
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target
	local talent = "special_bonus_unique_gravity_lord_3"
	local talentValues = caster:FindTalentValues(talent)

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

function GravityBoltCooldown( keys )
	local caster = keys.caster
	local ability = keys.ability

	if caster:HasTalent("special_bonus_unique_gravity_lord_3") then
		ability:EndCooldown()
		ability:StartCooldown(ability:GetCooldown(ability:GetLevel()-1) - caster:FindTalentValues("special_bonus_unique_gravity_lord_3")[4])
	end
end

function GravityBoltModifier( keys )
	local caster = keys.caster
	local ability = keys.ability

	if caster:HasTalent("special_bonus_unique_gravity_lord_3") then
		ability:ApplyDataDrivenModifier(caster, caster, keys.modifier, {})
		caster:CalculateStatBonus()
	end
end

function GravityBoltManaCost( keys )
	local caster = keys.caster
	local manaCostPct = caster:FindTalentValues("special_bonus_unique_gravity_lord_3")[3] * 0.01

	if caster:HasTalent("special_bonus_unique_gravity_lord_3") then
		caster:SetMana(caster:GetMana() - caster:GetMana() * manaCostPct)
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
			manaCostReduction = manaCostReduction + caster:FindTalentValues(talent)[2]
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
		local talentCount = galaxyCount + caster:FindTalentValues(talent)[1]
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
		stackCount = stackCount + caster:FindTalentValues(talent)[1]
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
	local duration = ability:GetSpecialValueFor("duration")
	local damage = ability:GetAbilityDamage()

	local talent = "special_bonus_unique_gravity_lord_5"
	local talent2 = "special_bonus_unique_gravity_lord_6"
	if caster:HasTalent(talent) then
		intDamage = intDamage + caster:FindTalentValues(talent)[4]
		damage = damage + caster:FindTalentValues(talent)[3]
		stunDuration = stunDuration + caster:GetIntellect() * 0.01
	end
	damage = damage + (damage * intDamage * 0.01)

	-- needs work
	local pfx = ParticleManager:CreateParticle("particles/econ/items/enigma/enigma_world_chasm/enigma_blackhole_ti5.vpcf", PATTACH_WORLDORIGIN, caster)
	ParticleManager:SetParticleControl(pfx, 0, Vector(keys.target_points[1].x, keys.target_points[1].y, keys.target_points[1].z + 25))
	ParticleManager:SetParticleControl(pfx, 1, Vector(keys.target_points[1].x, keys.target_points[1].y, keys.target_points[1].z + 25))
	ParticleManager:SetParticleControl(pfx, 2, Vector(keys.target_points[1].x, keys.target_points[1].y, keys.target_points[1].z + 25))
	ParticleManager:SetParticleControl(pfx, 9, Vector(keys.target_points[1].x, keys.target_points[1].y, keys.target_points[1].z + 25))

	-- start blackhole
	local tick = 0
	Timers:CreateTimer(0, function()
		tick = tick + 0.5
		local units = FindUnitsInRadius(caster:GetTeamNumber(), keys.target_points[1], nil, radius, ability:GetAbilityTargetTeam(), ability:GetAbilityTargetType(), DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
		for _,unit in pairs(units) do
			--info for motion controller
			ability.direction = (keys.target_points[1] - unit:GetAbsOrigin()):Normalized()
			ability.speed = 3 --???
			-- start pulling the unit in
			if not unit:HasModifier("modifier_black_star_motion_controller") then
				ability:ApplyDataDrivenModifier(caster, unit, "modifier_black_star_motion_controller", {})
			end
			-- stun if first tick
			if tick == 0.5 then
				unit:AddNewModifier(caster, ability, "modifier_stunned", {duration = stunDuration})
				damage = damage/2
			end
			-- deal damage per tick
			ApplyDamage({victim = unit, attacker = caster, ability = ability, damage = damage, damage_type = ability:GetAbilityDamageType(), damage_flags = DOTA_DAMAGE_FLAG_NONE})
			-- talent stuff
			if caster:HasTalent(talent) then
				BlackStarVoidCurse(caster, caster:FindAbilityByName("void_curse"), unit)
			end
			if caster:HasTalent(talent2) and caster:FindAbilityByName("gravity_lord"):GetLevel() > 0 then
				VoidFissure(caster, unit)
			end
			--stop motion controllers if blackhole is ending
			if tick >= duration then
				if unit then
					if unit:IsAlive() then
						unit:InterruptMotionControllers(true)
						unit:RemoveModifierByNameAndCaster("modifier_black_star_motion_controller", caster)
					end
				end
			end
		end	
		-- end blackhole
		if tick >= duration then
			ParticleManager:DestroyParticle(pfx, false)
			return nil
		end
		-- continue blackhole
		return 0.5
	end)
end

function BlackStarMotion( keys )
	keys.target:SetAbsOrigin(keys.target:GetAbsOrigin() + keys.ability.direction * keys.ability.speed)
end

function BlackStarVoidCurse( caster, ability, target )
	local duration = caster:FindAbilityByName("void_curse"):GetSpecialValueFor("duration") + 0.01
	local talent = "special_bonus_unique_gravity_lord_1"

	-- check for talent and increase duration if it exists
	if caster:HasTalent(talent) then
		duration = duration + caster:FindTalentValues(talent)[2]
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
		ability:StartCooldown(ability:GetCooldown(ability:GetLevel()-1) - caster:FindTalentValues(talent)[2])
	end
end

--[[/////////////////
/// Gravity Lord ///
///////////////////]]

function HandleGravityLordBuffs( keys )
	local caster = keys.caster
	local ability = keys.ability
	local regenCount = ability:GetSpecialValueFor("mana_regen_tooltip")
	local ampCount = ability:GetSpecialValueFor("spell_amp_tooltip")
	local talent = "special_bonus_unique_gravity_lord_6"
	local modifier = keys.modifier

	local stackCount 
	if modifier == keys.check then stackCount = ampCount else stackCount = regenCount end
	local talentCount = stackCount * caster:FindTalentValues(talent)[1]

	if caster:GetModifierStackCount(modifier, caster) < stackCount then
		caster:SetModifierStackCount(modifier, caster, stackCount)
	end

	-- double gravity lord bonuses if caster has talent and bonuses have not already been doubled.
	if caster:HasTalent(talent) and caster:GetModifierStackCount(modifier, caster) < talentCount then
		caster:SetModifierStackCount(modifier, caster, talentCount)
	end
end

function GravityLordManaBonus( keys )
	local caster = keys.caster
	local ability = keys.ability
	local manaBonus = ability:GetSpecialValueFor("mana_bonus_tooltip") * 0.01
	local stackCount = caster:CalculateBaseMana(true, true) * manaBonus
	local talent = "special_bonus_unique_gravity_lord_6"

	if caster:HasTalent(talent) then
		stackCount = stackCount * caster:FindTalentValues(talent)[1]
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
				target:SetModifierStackCount(modifier, caster, 1)
			else
				target:SetModifierStackCount(modifier, caster, target:GetModifierStackCount(modifier, caster)+1)
			end
		end
	end
end