function SummonInfernal( keys )
	local caster = keys.caster
	local ability = keys.ability
	local abLvl = ability:GetLevel()-1
	local targetPoint = caster:GetAbsOrigin()

	local golem = CreateUnitByName("npc_infernal_summon", targetPoint, true, caster, caster, caster:GetTeamNumber())
	golem:SetControllableByPlayer(caster:GetPlayerID(), true)
	golem:SetOwner(caster)
	golem:FindAbilityByName(keys.ability_bash):SetLevel(abLvl)
	golem:FindAbilityByName(keys.ability_slam):SetLevel(abLvl)
	golem:FindAbilityByName(keys.ability_fist):SetLevel(abLvl)
	golem:FindAbilityByName(keys.ability_stats):SetLevel(abLvl)

	local casterInt = caster:GetIntellect()
	local casterHealth = caster:GetMaxHealth()
	local intLife = ability:GetSpecialValueFor("int_to_life") * 0.01
	local healthLife = ability:GetSpecialValueFor("life_to_life") * 0.01
	print("golem health: "..casterInt * intLife + casterHealth * healthLife)
	golem:HandleUnitHealth(golem:GetHealth() + golem:GetHealthDeficit() + casterInt * intLife + casterHealth * healthLife)
end

--[[/////////////////////////
/// Infernal Rapid Fists ///
///////////////////////////]]

function InfernalFist( keys )
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target

	local radius = ability:GetSpecialValueFor("radius")
	local minPull = ability:GetSpecialValueFor("min_pull")
	local maxPull = ability:GetSpecialValueFor("max_pull")
	local atkTime = ability:GetSpecialValueFor("time_between_atk")
	local maxAttacks = ability:GetSpecialValueFor("num_atk")

	local baseDamage = ability:GetSpecialValueFor("damage")
	local healthToDamage = ability:GetSpecialValueFor("life_to_damage") * 0.01
	local damage = baseDamage + caster:GetMaxHealth() * healthToDamage

	caster:Interrupt()
	caster:Stop()

	ability.unitTable = {}

	Timers:CreateTimer(atkTime, function()
		--attack main target
		if target then
			--print("target")
			if target:IsAlive() then
				--print("performing attack: target")
				local order = {
					UnitIndex = caster:entindex(),
					OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
					TargetIndex = target:entindex()
				}
				ExecuteOrderFromTable(order)
				caster:PerformAttack(target, true, true, true, true, false, false, false)
				if ability.currentAtk then
					--print("incrementing currentAtk")
					ability.currentAtk = ability.currentAtk + 1
				else
					--print("starting currentAtk")
					ability.currentAtk = 1
				end
			end

			--print("finding units")
			local units = FindUnitsInRadius(caster:GetTeamNumber(), target:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, ability:GetAbilityTargetType(), DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false)
			for _,unit in pairs(units) do

				--pull units towards target
				local unitPos = unit:GetAbsOrigin()
				local targetPos = target:GetAbsOrigin()
				local distance = (targetPos - unitPos):Length2D()
				local direction = (targetPos - unitPos):Normalized()
				local random = RandomFloat(minPull, maxPull) * distance

				unit:SetAbsOrigin(unitPos + direction * random)
				ApplyDamage({victim = unit, attacker = caster, ability = ability, damage = damage, damage_type = ability:GetAbilityDamageType(), damage_flags = DOTA_DAMAGE_FLAG_NONE})
				--print("pulling and damaging unit")

				--attack closest unit if target died
				if target:IsAlive() then
					-- do nothing
				else
					--print("target is dead")
					if unit and unit:IsAlive() then
						if ability.currentAtk and ability.currentAtk < maxAttacks then
							--print("performing attack: unit")
							local order = {
								UnitIndex = caster:entindex(),
								OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
								TargetIndex = unit:entindex()
							}
							ExecuteOrderFromTable(order)
							caster:PerformAttack(unit, true, true, true, true, false, false, false)
							if ability.currentAtk then
								--print("incrementing currentAtk")
								ability.currentAtk = ability.currentAtk + 1
							else
								--print("starting currentAtk")
								ability.currentAtk = 1
							end
						end
					end
				end
			end
			if ability.currentAtk < maxAttacks then
				--run timer again
				--print("running again")
				if target:IsAlive() then
					return atkTime
				else
					--print("ending timer")
					return nil
				end
			else
				--end timer
				ability.currentAtk = 0
				--print("ending timer")

				-- Add the phased modifier to prevent getting stuck
				target:AddNewModifier(caster, nil, "modifier_phased", {duration = 0.03})
				caster:AddNewModifier(caster, nil, "modifier_phased", {duration = 0.03})
				local toPhase = FindUnitsInRadius(caster:GetTeamNumber(), target:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, ability:GetAbilityTargetType(), DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false)
				for _,phased in pairs(toPhase) do
					phased:AddNewModifier(caster, nil, "modifier_phased", {duration = 0.03})
				end
				return nil
			end
		end
	end)
end

--[[//////////////////
/// Infernal Slam ///
////////////////////]]

function SlamDamage ( keys )
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target

	local baseDamage = ability:GetSpecialValueFor("damage")
	local healthToDamage = ability:GetSpecialValueFor("life_to_damage") * 0.01
	local damage = baseDamage + caster:GetMaxHealth() * healthToDamage

	if target and target:IsAlive() then
		ApplyDamage({victim = target, attacker = caster, ability = ability, damage = damage, damage_type = ability:GetAbilityDamageType(), damage_flags = DOTA_DAMAGE_FLAG_NONE})
	end
end

--[[///////////////////
/// Infernal Stats ///
/////////////////////]]

function UpdateStats ( keys )
	local summon = keys.caster
	if not summon then return end 
	if not summon:GetOwner() then return end

	local ability = keys.ability
	local casterInt = summon:GetOwner():GetIntellect()
	local casterHealth = summon:GetOwner():GetMaxHealth()

	local modifierMana = keys.modifier_mana
	local modifierDamage = keys.modifier_damage
	local modifierSpeed = keys.modifier_speed

	local intLife = ability:GetSpecialValueFor("int_to_life") * 0.01
	local healthLife = ability:GetSpecialValueFor("life_to_life") * 0.01
	local intMana = ability:GetSpecialValueFor("int_to_mana") * 0.01
	local intDamage = ability:GetSpecialValueFor("int_to_damage") * 0.01
	local intSpeed = ability:GetSpecialValueFor("int_to_atkspd") * 0.01

	summon:SetModifierStackCount(modifierMana, summon, casterInt * intMana)
	summon:SetModifierStackCount(modifierDamage, summon, casterInt * intDamage)
	summon:SetModifierStackCount(modifierSpeed, summon, casterInt * intSpeed)
end
