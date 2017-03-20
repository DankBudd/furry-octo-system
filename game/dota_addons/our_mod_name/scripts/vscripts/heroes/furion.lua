--[[//////////////////
/// Natures Wrath ///
////////////////////]]

function NaturesWrath( keys )
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target
	local casterInt = caster:GetIntellect()
	local duration = ability:GetSpecialValueFor("debuff_duration") + 0.1
	local explosionReduction = ability:GetSpecialValueFor("explosion_reduction") * 0.01

	local intToHeal = ability:GetSpecialValueFor("int_to_heal") * 0.01
	local baseHeal = ability:GetSpecialValueFor("base_heal")
	local heal = baseHeal + intToHeal * casterInt
	ability.heal = heal * explosionReduction

	local intToDamage = ability:GetSpecialValueFor("int_to_damage") * 0.01
	local baseDamage = ability:GetSpecialValueFor("base_damage")
	local damage = baseDamage + intToDamage * casterInt
	ability.damage = damage * explosionReduction

	if target:GetTeam() == caster:GetTeam() then
		SendOverheadEventMessage(target, OVERHEAD_ALERT_HEAL, target, heal, nil)
		target:Heal(heal, caster)
		ability:ApplyDataDrivenModifier(caster, target, keys.modifier_buff, {duration = duration})
	else
		ApplyDamage({victim = target, attacker = caster, ability = ability, damage = damage, damage_type = ability:GetAbilityDamageType(), damage_flags = DOTA_DAMAGE_FLAG_NONE})
		ability:ApplyDataDrivenModifier(caster, target, keys.modifier_debuff, {duration = duration})
	end
	ability:ApplyDataDrivenModifier(caster, target, keys.modifier, {duration = duration})
end

function NaturesWrathExplosion( keys )
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target

	if not target then return end

	if target:GetTeam() == caster:GetTeam() then
		local toHeal = FindUnitsInRadius(caster:GetTeamNumber(), target:GetAbsOrigin(), nil, ability:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_FRIENDLY, ability:GetAbilityTargetType(), ability:GetAbilityTargetFlags(), FIND_ANY_ORDER, false)
		if #toHeal > 0 then
			for _,unit in pairs(toHeal) do
				SendOverheadEventMessage(unit, OVERHEAD_ALERT_HEAL, unit, ability.heal, nil)
				unit:Heal(ability.heal, caster)
			end
		end
	else
		local toDamage = FindUnitsInRadius(caster:GetTeamNumber(), target:GetAbsOrigin(), nil, ability:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, ability:GetAbilityTargetType(), ability:GetAbilityTargetFlags(), FIND_ANY_ORDER, false)
		if #toDamage > 0 then
			for _,target in pairs(toDamage) do
				ApplyDamage({victim = target, attacker = caster, ability = ability, damage = ability.damage, damage_type = ability:GetAbilityDamageType(), damage_flags = DOTA_DAMAGE_FLAG_NONE})
			end
		end
	end

	--temp particle and sound so they the explosion is noticable
	EmitSoundOn("Hero_Phoenix.SuperNova.Explode", target)
	local pfxName = "particles/units/heroes/hero_phoenix/phoenix_supernova_reborn.vpcf"
	local pfx = ParticleManager:CreateParticle(pfxName, PATTACH_ABSORIGIN, target)
end

--[[/////////////////
/// Treant Guard ///
///////////////////]]

function SummonTreants( keys )
	local caster = keys.caster
	local ability = keys.ability
	local casterInt = caster:GetIntellect()
	local targetPoint = caster:GetCursorPosition()
	local abilityLevel = ability:GetLevel()
	local maxTreants = ability:GetSpecialValueFor("num_treants")
	local radius = ability:GetSpecialValueFor("radius")

	caster.treeDmg = casterInt * ability:GetSpecialValueFor("int_to_damage") * 0.01
	caster.treeHp = casterInt * ability:GetSpecialValueFor("int_to_life") * 0.01

	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_furion/furion_force_of_nature_cast.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(particle, 0, targetPoint)
	ParticleManager:SetParticleControl(particle, 1, targetPoint)
	ParticleManager:SetParticleControl(particle, 2, Vector(radius,0,0))

	Timers:CreateTimer(0.03, function()
		for i = 1,maxTreants do
			local treant = CreateUnitByName("furion_treant"..abilityLevel, targetPoint, true, caster, caster, caster:GetTeamNumber())
			treant:SetControllableByPlayer(caster:GetPlayerID(), true)
			treant:SetOwner(caster)
			treant:FindAbilityByName("seed_of_life"):SetLevel(abilityLevel)
			treant:FindAbilityByName("splitting_nightmare"):SetLevel(abilityLevel)
			treant:FindAbilityByName("natures_wrath"):SetLevel(abilityLevel)
			treant:FindAbilityByName("natures_wrath"):SetActivated(false)

			treant:AddNewModifier(caster, ability, "modifier_phased", {duration = 0.05})
			treant:AddNewModifier(caster, ability, "modifier_kill", {duration = ability:GetSpecialValueFor("duration")})

			ability:ApplyDataDrivenModifier(caster, treant, "modifier_treant_bonus_damage", {})
			treant:SetModifierStackCount("modifier_treant_bonus_damage", caster, caster.treeDmg) 
			treant:HandleUnitHealth(90 + 10*abilityLevel + caster.treeHp)
		end
	end)
end

function SeedOfLife( keys )
	local treant = keys.caster
	local ability = keys.ability
	local naturesWrath = treant:FindAbilityByName("natures_wrath")

	if treant:IsAlive() then return end

	EmitSoundOn(keys.soundName, treant)

	local potentialTargets = FindUnitsInRadius(treant:GetTeamNumber(), treant:GetAbsOrigin(), nil, ability:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false)
	for _,unit in pairs(potentialTargets) do
		if IsValidEntity(unit) then
			local name = unit:GetName()
			if not treant:GetName() == "furion_treant_split" and not name == "furion_treant1" and not name == "furion_treant2" and not name == "furion_treant3" and not name == "furion_treant4" then
				naturesWrath:SetActivated(true)
				treant:CastAbilityOnTarget(unit, naturesWrath, treant:GetEntityIndex())
				break
			end
		end
	end

	ability:ApplyDataDrivenThinker(treant, treant:GetAbsOrigin(), "modifier_seed_of_life_thinker", {duration = ability:GetSpecialValueFor("duration")})
end

function SeedOfLifeImpact( keys )
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target

	if not target or not caster or not ability or not caster:GetOwner() then return end

	local damage = ability:GetSpecialValueFor("base_dmg") + caster:GetOwner():GetIntellect() * ability:GetSpecialValueFor("int_to_damage") * 0.01
	local heal = ability:GetSpecialValueFor("base_heal") + caster:GetOwner():GetIntellect() * ability:GetSpecialValueFor("int_to_heal") * 0.01

	if caster:GetTeamNumber() ~= target:GetTeamNumber() then
		ApplyDamage({victim = target, attacker = caster, ability = ability, damage = damage, damage_type = ability:GetAbilityDamageType(), damage_flags = DOTA_DAMAGE_FLAG_NONE})
	else
		target:Heal(heal, caster)
	end
end

function LesserTreant( keys )
	local treant = keys.caster
	local owner = treant:GetOwner()
	local ability = keys.ability
	local abilityLevel = ability:GetLevel()
	local maxTreants = ability:GetSpecialValueFor("num_treants")

	if treant:IsAlive() then return end

	local ownerAbility = owner:FindAbilityByName("treant_guard")
	local treeDmg = owner.treeDmg * 0.5
	local treeHp = owner.treeHp * 0.5

	local i = 0
	while i < maxTreants do
		i=i+1
		local lesser = CreateUnitByName("furion_treant_split", treant:GetAbsOrigin(), false, owner, owner, treant:GetTeamNumber())
		lesser:SetControllableByPlayer(owner:GetPlayerID(), true)
		lesser:SetOwner(owner)
		lesser:FindAbilityByName("seed_of_life"):SetLevel(abilityLevel)
		lesser:SetModelScale(0.50) --reg treants have 0.80

		local center = lesser:GetAbsOrigin() + RandomVector(5):Normalized()
		lesser:AddNewModifier(owner, ownerAbility, "modifier_kill", {duration = ability:GetSpecialValueFor("duration")})
		lesser:AddNewModifier(owner, ownerAbility, "modifier_knockback", {duration = 0.7, should_stun = 1, center_x = center.x, center_y = center.y, center_z = center.z, knockback_duration = 0.7, knockback_distance = 65 , knockback_height = 100})

		ownerAbility:ApplyDataDrivenModifier(owner, lesser, "modifier_treant_bonus_damage", {})
		lesser:SetModifierStackCount("modifier_treant_bonus_damage", owner, treeDmg)
		lesser:HandleUnitHealth(90 + 10*abilityLevel + treeHp)
	end
end