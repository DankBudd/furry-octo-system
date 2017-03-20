--[[///////////////
/// Glory Hook ///
/////////////////]]

--[[ 	Authors: Pizzalol and D2imba
		Date: 10.07.2015				]]
function HookCast( keys )
	local caster = keys.caster
	local target = keys.target_points[1]
	local ability = keys.ability

	local modifier = "modifier_glory_hook_cast_check"

	-- Parameters
	local baseRange = ability:GetSpecialValueFor("base_range")
	local castDistance = (target - caster:GetAbsOrigin()):Length2D()
	caster.stopHookCast = nil

	-- Check if the target point is inside range, if not, stop casting and move closer
	if castDistance > baseRange then

		-- Start moving
		caster:MoveToPosition(target)
		Timers:CreateTimer(0.1, function()

			-- Update distance and range
			castDistance = (target - caster:GetAbsOrigin()):Length2D()

			-- If it's not a legal cast situation and no other order was given, keep moving
			if castDistance > baseRange and not caster.stopHookCast then
				return 0.1

			-- If another order was given, stop tracking the cast distance
			elseif caster.stopHookCast then
				caster:RemoveModifierByName(modifier)
				caster.stopHookCast = nil

			-- If all conditions are met, recast Hook
			else
				caster:CastAbilityOnPosition(target, ability, caster:GetPlayerID())
			end
		end)
		return nil
	end
end

function HookCastCheck( keys )
	keys.caster.stopHookCast = true
end

function GloryHook( keys )
	local caster = keys.caster
	local ability = keys.ability

	-- If another hook is already out, refund mana cost and do nothing
	if caster.hookLaunched then
		caster:GiveMana(ability:GetManaCost(ability:GetLevel() - 1))
		ability:EndCooldown()
		return nil
	end

	-- Set the global hookLaunched variable
	caster.hookLaunched = true

	-- Sound, particle and modifier keys
	local soundExtend = "Hero_Pudge.AttackHookExtend"
	local soundHit = "Hero_Pudge.AttackHookImpact"
	local soundRetract = "Hero_Pudge.AttackHookRetract"
	local soundRetractStop = "Hero_Pudge.AttackHookRetractStop"
	local particleHook = "particles/units/heroes/hero_pudge/pudge_meathook_chain.vpcf"
	local particleHit = "particles/units/heroes/hero_pudge/pudge_meathook_impact.vpcf"
	local modifierCaster = "modifier_glory_hook_caster"
	local modifierTargetEnemy = "modifier_glory_hook_target_enemy"
	local modifierTargetDebuff = "modifier_glory_hook_armor_reduction"
	local modifierTargetAlly = "modifier_glory_hook_target_ally"
	local modifierDummy = "modifier_glory_hook_dummy"

	-- Parameters
	local baseSpeed = ability:GetSpecialValueFor("base_speed")
	local hookWidth = ability:GetSpecialValueFor("hook_width")
	local baseRange = ability:GetSpecialValueFor("base_range")
	local baseDamage = ability:GetSpecialValueFor("base_damage")
	local visionRadius = ability:GetSpecialValueFor("vision_radius")
	local visionDuration = ability:GetSpecialValueFor("vision_duration")
	local baseArmorReduction = ability:GetSpecialValueFor("base_armor_reduction") * 0.01
	local maxUnits = ability:GetSpecialValueFor("max_units")
	local unitsHit = {}

	local casterLoc = caster:GetAbsOrigin()
	local startLoc = casterLoc + (keys.target_points[1] - casterLoc):Normalized() * hookWidth

	-- Stun the caster for the hook duration
	ability:ApplyDataDrivenModifier(caster, caster, modifierCaster, {})

	-- Play Hook launch sound
	caster:EmitSound(soundExtend)

	-- Create and set up the Hook dummy unit
	local hookDummy = CreateUnitByName("npc_dummy_blank", startLoc + Vector(0, 0, 150), false, caster, caster, caster:GetTeam())
	hookDummy:AddNewModifier(caster, nil, "modifier_phased", {})
	ability:ApplyDataDrivenModifier(caster, hookDummy, modifierDummy, {})
	hookDummy:SetForwardVector(caster:GetForwardVector())

	-- Make the hook always visible to both teams
	caster:MakeVisibleToTeam(DOTA_TEAM_GOODGUYS, baseRange / baseSpeed)
	caster:MakeVisibleToTeam(DOTA_TEAM_BADGUYS, baseRange / baseSpeed)
	
	-- Attach the Hook particle
	local hookPfx = ParticleManager:CreateParticle(particleHook, PATTACH_RENDERORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleAlwaysSimulate(hookPfx)
	ParticleManager:SetParticleControlEnt(hookPfx, 0, caster, PATTACH_POINT_FOLLOW, "attach_weapon_chain_rt", casterLoc, true)
	ParticleManager:SetParticleControl(hookPfx, 1, startLoc)
	ParticleManager:SetParticleControl(hookPfx, 2, Vector(baseSpeed, baseRange, hookWidth))
	ParticleManager:SetParticleControl(hookPfx, 6, startLoc)
	ParticleManager:SetParticleControlEnt(hookPfx, 6, hookDummy, PATTACH_POINT_FOLLOW, "attach_overhead", startLoc, false)
	ParticleManager:SetParticleControlEnt(hookPfx, 7, caster, PATTACH_CUSTOMORIGIN, nil, casterLoc, true)

	-- Remove the caster's hook
	local weaponHook
	if caster:IsHero() then
		weaponHook = caster:GetTogglableWearable( DOTA_LOADOUT_TYPE_WEAPON )
		if weaponHook ~= nil then
			weaponHook:AddEffects( EF_NODRAW )
		end
	end

	-- Initialize Hook variables
	local hookLoc = startLoc
	local tickRate = 0.03
	baseSpeed = baseSpeed * tickRate

	local travelDistance = (hookLoc - casterLoc):Length2D()
	local hookStep = (keys.target_points[1] - casterLoc):Normalized() * baseSpeed

	local targetHit = false
	local target

	-- Main Hook loop
	Timers:CreateTimer(tickRate, function()

		-- Check for valid units in the area
		local units = FindUnitsInRadius(caster:GetTeamNumber(), hookLoc, nil, hookWidth, ability:GetAbilityTargetTeam(), ability:GetAbilityTargetType(), ability:GetAbilityTargetFlags(), FIND_CLOSEST, false)
		for _,unit in pairs(units) do
			if unit ~= caster and unit:GetUnitName() ~= ("npc_dummy_blank" or "npc_dummy_unit" or "mirror_hall_mirror") and not unit:IsAncient() then
				targetHit = true
				target = unit
			end
		end

		-- If a valid target was hit, add them to table and start dragging them
		if targetHit and not target.beenHooked then
			-- Apply stun/root modifier, and damage if the target is an enemy
			if caster:GetTeam() == target:GetTeam() then
				ability:ApplyDataDrivenModifier(caster, target, modifierTargetAlly, {})
			else
				ability:ApplyDataDrivenModifier(caster, target, modifierTargetEnemy, {})
				ability:ApplyDataDrivenModifier(caster, target, modifierTargetDebuff, {})

				ApplyDamage({attacker = caster, victim = target, ability = ability, damage = baseDamage, damage_type = ability:GetAbilityDamageType()})
				SendOverheadEventMessage(nil, OVERHEAD_ALERT_DAMAGE, target, baseDamage, nil)
			end

			-- Play the hit sound and particle
			target:EmitSound(soundHit)
			local hookPfx = ParticleManager:CreateParticle(particleHit, PATTACH_ABSORIGIN_FOLLOW, target)

			-- Grant vision on the hook hit area
			ability:CreateVisibilityNode(hookLoc, visionRadius, visionDuration)

			target.beenHooked = true
			table.insert(unitsHit, target)
		end

		-- If max number of units was not hit and the maximum range is not reached, move the hook and keep going
		if #unitsHit < maxUnits and travelDistance < baseRange then

			-- Move the hook
			hookDummy:SetAbsOrigin(hookLoc + hookStep)

			-- Recalculate position and distance
			hookLoc = hookDummy:GetAbsOrigin()
			travelDistance = (hookLoc - casterLoc):Length2D()

			ability.pullAlong = Timers:CreateTimer(function()
				-- Move the hook and an eventual target
				hookDummy:SetAbsOrigin(hookLoc + hookStep)
				ParticleManager:SetParticleControl(hookPfx, 6, hookLoc + hookStep + Vector(0, 0, 90))

				if targetHit then
					for reelTarget = 1, #unitsHit do
						FindClearSpaceForUnit(unitsHit[reelTarget], hookLoc + hookStep, false)
						unitsHit[reelTarget]:SetForwardVector((casterLoc - hookLoc):Normalized())
					end
				end
			end)
			return tickRate
		end

		-- If we are here, this means the hook has to start reeling back; prepare return variables
		local direction = ( casterLoc - hookLoc )
		local currentTick = 0

		-- Stop the extending sound and start playing the return sound
		caster:StopSound(soundExtend)
		caster:EmitSound(soundRetract)

		-- Remove the caster's self-stun
		caster:RemoveModifierByName(modifierCaster)

		-- Play sound reaction according to which target was hit
		if targetHit and target:IsRealHero() and target:GetTeam() ~= caster:GetTeam() then
			caster:EmitSound("pudge_pud_ability_hook_0"..RandomInt(1,9))
		elseif targetHit and target:IsRealHero() and target:GetTeam() == caster:GetTeam() then
			caster:EmitSound("pudge_pud_ability_hook_miss_01")
		elseif targetHit then
			caster:EmitSound("pudge_pud_ability_hook_miss_0"..RandomInt(2,6))
		else
			caster:EmitSound("pudge_pud_ability_hook_miss_0"..RandomInt(8,9))
		end

		-- Hook reeling loop
		Timers:CreateTimer(tickRate, function()

			-- Recalculate position variables
			casterLoc = caster:GetAbsOrigin()
			hookLoc = hookDummy:GetAbsOrigin()
			direction = ( casterLoc - hookLoc )
			hookStep = direction:Normalized() * baseSpeed
			currentTick = currentTick + 1
			
			-- If the target is close enough, or the hook has been out too long, finalize the hook return
			if direction:Length2D() < baseSpeed or currentTick > 300 then

				-- Stop moving the target
				if targetHit then
					local finalLoc = casterLoc + caster:GetForwardVector() * 100
					for releaseTarget = 1, #unitsHit do
						FindClearSpaceForUnit(unitsHit[releaseTarget], finalLoc, false)

						-- Remove the target's modifiers
						unitsHit[releaseTarget]:RemoveModifierByName(modifierTargetAlly)
						unitsHit[releaseTarget]:RemoveModifierByName(modifierTargetEnemy)

						unitsHit[releaseTarget].beenHooked = false
					end
				end

				-- Destroy the hook dummy and particles
				hookDummy:Destroy()
				ParticleManager:DestroyParticle(hookPfx, false)
				ParticleManager:ReleaseParticleIndex(hookPfx)

				-- Stop playing the reeling sound
				caster:StopSound(soundRetract)
				caster:EmitSound(soundRetractStop)

				-- Give back the caster's hook
				if weaponHook ~= nil then
					weaponHook:RemoveEffects( EF_NODRAW )
				end

				-- Clear global variables
				caster.hookLaunched = nil

			-- If this is not the final step, keep reeling the hook in
			else

				-- Move the hook and an eventual target
				hookDummy:SetAbsOrigin(hookLoc + hookStep)
				ParticleManager:SetParticleControl(hookPfx, 6, hookLoc + hookStep + Vector(0, 0, 90))

				if targetHit then
					for reelTarget = 1, #unitsHit do
						FindClearSpaceForUnit(unitsHit[reelTarget], hookLoc + hookStep, false)
						unitsHit[reelTarget]:SetForwardVector(direction:Normalized())
						ability:CreateVisibilityNode(hookLoc, visionRadius, 0.5)
					end
				end
				
				return tickRate
			end
		end)
	end)
end

--[[///////////////
/// Fresh Meat ///
/////////////////]]

function FreshMeatModifier( keys )
	local caster = keys.caster
	local ability = keys.ability
	local hpToDamage = ability:GetSpecialValueFor("hp_to_damage") * 0.01
	local talent = "special_bonus_unique_butcher_3"

	local stackCount = caster:GetMaxHealth() * hpToDamage
	local stackCountSelf = ability:GetSpecialValueFor("self_damage_increase")

	if caster:HasTalent(talent) then
		stackCount = caster:GetMaxHealth() * (hpToDamage + (caster:FindTalentValues(talent)[2] * 0.01))
		stackCountSelf = stackCountSelf - caster:FindTalentValues(talent)[4]
	end
	caster:SetModifierStackCount(keys.modifier, caster, stackCount)
	caster:SetModifierStackCount(keys.modifier_self, caster, stackCountSelf)
end

function FreshMeat( keys )
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target
	local lifesteal = ability:GetSpecialValueFor("lifesteal") * 0.01
	local duration = ability:GetSpecialValueFor("disarm_duration")
	local heal = keys.attack_damage * lifesteal
	local talent = "special_bonus_unique_butcher_3"
	local damage = caster:FindTalentValues(talent)[6] * keys.attack_damage * 0.01

	if caster:HasTalent(talent) then
		duration = duration + caster:FindTalentValues(talent)[1]
		heal = keys.attack_damage * (lifesteal + (caster:FindTalentValues(talent)[3] * 0.01))
		DoCleaveAttack(caster, target, ability, damage, 400, 400, 400, "particles/units/heroes/hero_sven/sven_spell_great_cleave.vpcf")
	end
	ability:ApplyDataDrivenModifier(caster, target, keys.modifier_disarm, {duration = duration})
	caster:Heal(heal, caster)
end

function FreshMeatCooldown( keys )
	local caster = keys.caster
	local ability = keys.ability
	local talent = "special_bonus_unique_butcher_3"

	if caster:HasTalent(talent) then
		ability:EndCooldown()
		ability:StartCooldown(ability:GetCooldown(ability:GetLevel()) - caster:FindTalentValues(talent)[5])
	end
end

--[[//////////////
/// Dismember ///
////////////////]]

function DismemberStart( keys )
	local caster = keys.caster
	local ability = keys.ability
	local duration = ability:GetSpecialValueFor("creep_duration")
	local target = keys.target
	ability.target = target

	if caster:HasScepter() then
		ability.damage = ability:GetSpecialValueFor("dismember_damage") + ability:GetSpecialValueFor("strength_damage_scepter") * 0.01
	else
		ability.damage = ability:GetSpecialValueFor("dismember_damage")
	end
	if caster:HasTalent("special_bonus_unique_butcher_6") then
		ability.damage = ability.damage * caster:FindTalentValues("special_bonus_unique_butcher_6")[2] * 0.01
	end

--	target:EmitSound(keys.sound_name)

	ability:ApplyDataDrivenModifier(caster, target, keys.modifier, {duration = duration})
	ability:ApplyDataDrivenModifier(caster, target, "modifier_butcher_dismember_channeling", {duration = duration})
	ApplyDamage({victim = target, attacker = caster, ability = ability, damage = ability.damage, damage_type = ability:GetAbilityDamageType(), damage_flags = DOTA_DAMAGE_FLAG_NONE})
end

function DismemberDropMeat( keys )
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	if not target or not caster or not ability then return end

	ApplyDamage({victim = target, attacker = caster, ability = ability, damage = ability.damage, damage_type = ability:GetAbilityDamageType(), damage_flags = DOTA_DAMAGE_FLAG_NONE})
	
	local meatDropped
	if target:IsAlive() then
		meatDropped = keys.meatToDrop - 1
	else
		meatDropped = 0
	end
	
	while meatDropped <= keys.meatToDrop do
		local targetPos = target:GetAbsOrigin() + RandomVector(1)
		local meat = CreateUnitByName("npc_dummy_blank", targetPos, true, nil, nil, caster:GetTeamNumber())
		local particle = ParticleManager:CreateParticle("particles/dismember_meat_blood_spray.vpcf", PATTACH_ABSORIGIN_FOLLOW, meat)
		ability:ApplyDataDrivenModifier(caster, meat, "modifier_butcher_dismember_meat_thinker", {})
		ability:ApplyDataDrivenModifier(caster, meat, "modifier_butcher_dismember_meat_dummy", {})

		meat:AddNewModifier(caster, nil, "modifier_knockback", {should_stun = 0, knockback_distance = RandomInt(25, 165), knockback_height = RandomInt(80, 180), knockback_duration = RandomFloat(0.5, 1.2),
			center_x = targetPos.x,
			center_y = targetPos.y,
			center_z = targetPos.z})
		meatDropped = meatDropped + 1
	end
end

--[[
CDOTA_Modifier_Knockback
    Int: "should_stun"
    Int: "knockback_distance"
    Int: "knockback_height"
    Float: "center_x"
    Float: "center_y"
    Float: "center_z"
    Float: "knockback_duration"
]]

function DismemberMeatHeal( keys )
	local caster = keys.caster
	local meat = keys.target
	local ability = keys.ability
	local baseHeal = ability:GetSpecialValueFor("meat_heal")	
	local gracePeriod = 0.565

	local strengthHeal = ability:GetSpecialValueFor("str_to_meat_heal") * 0.01
	if caster:HasScepter() then
		strengthHeal = strengthHeal + ability:GetSpecialValueFor("str_to_meat_heal_scepter") * 0.01
	end
	if caster:HasTalent("special_bonus_unique_butcher_6") then
		strengthHeal = strengthHeal + caster:FindTalentValues("special_bonus_unique_butcher_6")[3] * 0.01
	end

	local heal = baseHeal + strengthHeal * caster:GetStrength()
	if not meat then return end
	Timers:CreateTimer(0.1, function()
		if meat and not meat:IsNull() then 
			if caster and not caster:IsNull() then
				local units = FindUnitsInRadius(caster:GetTeamNumber(), meat:GetAbsOrigin(), nil, 75, DOTA_UNIT_TARGET_TEAM_FRIENDLY, ability:GetAbilityTargetType(), DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
				if #units >= 1 then
					if not meat.graceTimer then
						for _,unit in pairs(units) do
							if not unit:HasModifier("modifier_butcher_dismember_channeling") then
								if not unit:HasModifier("modifier_butcher_dismember_meat_dummy") then
									meat.graceTimer = Timers:CreateTimer(gracePeriod, function()
										SendOverheadEventMessage(unit, OVERHEAD_ALERT_HEAL, unit, heal, nil)
										unit:Heal(heal, caster)
										meat:RemoveSelf()
									end)
									break
								end
							end
						end
					end
				else
					if meat.graceTimer then
						Timers:RemoveTimer(meat.graceTimer)
					end
				end
				return 0.1
			end
		end
	end)
end

function DismemberEnd( keys )
	local caster = keys.caster
	local ability = keys.ability

	if ability.target then
		ability.target:RemoveModifierByNameAndCaster(keys.modifier, caster)
		ability.target = nil
	end
	caster:RemoveModifierByNameAndCaster("modifier_butcher_dismember_channeling", caster)
end

--[[///////////////
/// Weird Meat ///
/////////////////]]

function WeirdMeatUpdate( keys )
	local caster = keys.caster
	local ability = keys.ability

	local healthBonus = ability:GetSpecialValueFor("health_bonus") 
	local strToLife = ability:GetSpecialValueFor("str_to_life")
	local regen = ability:GetSpecialValueFor("regen")
	local magicResist = ability:GetSpecialValueFor("magic_resist")
	local damageReduction = ability:GetSpecialValueFor("damage_reduction")
	local spellAmp = ability:GetSpecialValueFor("spell_amp")

	local talent = "special_bonus_unique_butcher_5"
	local talentValues = caster:FindTalentValues(talent)
	if caster:HasTalent(talent) then
		healthBonus = healthBonus * talentValues["mult"]
		strToLife = strToLife * talentValues["str_bonus"]
		regen = regen * talentValues["mult"]
		magicResist = magicResist * talentValues["mult"]
		damageReduction = damageReduction * talentValues["mult"]
		spellAmp = spellAmp * talentValues["mult"]
		if not caster:HasModifier("modifier_meat_eater") then
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_meat_eater", {})
		end
	end
	-- doing it like this should give them 0.2/0.4/0.6/0.8 more hp than they should have, kek
	-- if this doesnt work then remove modifier instead, reapply after life is calculated
	caster:SetModifierStackCount("modifier_weird_meat_health_bonus", caster, 0)
	local life = healthBonus*0.01 * caster:GetMaxHealth() + strToLife* 0.01 * caster:GetStrength()

	caster:SetModifierStackCount("modifier_weird_meat_health_bonus", caster, life)
	caster:SetModifierStackCount("modifier_weird_meat_regen", caster, regen)
	caster:SetModifierStackCount("modifier_weird_meat_magic_resist", caster, magicResist)
	caster:SetModifierStackCount("modifier_weird_meat_damage_reduction", caster, damageReduction)
	caster:SetModifierStackCount("modifier_weird_meat_spell_amp", caster, spellAmp)
end

function WeirdMeatOnHit( keys )
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target
	if not caster or not target or caster:HasModifier("modifier_meat_eater_cooldown") then return end

	ApplyDamage({victim = target, attacker = caster, ability = ability, damage = target:GetMaxHealth() * talentValues["health_damage"]*0.01, damage_type = DAMAGE_TYPE_PURE})
	caster:RemoveModifierByNameAndCaster("modifier_meat_eater", caster)
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_meat_eater_cooldown", {duration = talentValues["cooldown"]})
end


--[[///////////////
/// Flesh Heap ///
/////////////////]]

function FleshHeapDecrement( keys )
	local caster = keys.caster
	local oldStacks = caster:GetModifierStackCount(keys.modifier, caster)

	if oldStacks > 0 then
		caster:SetModifierStackCount(keys.modifier, caster, oldStacks - 1)
	end
end

function FleshHeapKill( keys )
	local caster = keys.caster
	local ability = keys.ability
	local unit = keys.unit
	local duration = ability:GetSpecialValueFor("duration")
	local maxStacks = ability:GetSpecialValueFor("max_stacks")
	local curStacks = caster:GetModifierStackCount("modifier_butcher_flesh_heap", caster)

	local talentValues = caster:FindTalentValues("special_bonus_unique_butcher_4")
	if caster:HasTalent("special_bonus_unique_butcher_4") then
		if not caster:HasModifier("modifier_butcher_flesh_heap_magic_resist_talent") then
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_butcher_flesh_heap_magic_resist_talent", {})
		end
		maxStacks = maxStacks + talentValues["max_stacks"]
		duration = duration + talentValues["duration"]
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_butcher_flesh_heap_str_talent", {duration = duration})
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_butcher_flesh_heap_regen_talent", {duration = duration})
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_butcher_flesh_heap_life_talent", {duration = duration})
	end

	if not unit:IsBuilding() and not unit:HasModifier("modifier_butcher_flesh_heap_aura") then
		if curStacks < maxStacks then
			caster:SetModifierStackCount("modifier_butcher_flesh_heap", caster, curStacks + 1)
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_butcher_flesh_heap_str", {duration = duration})
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_butcher_flesh_heap_atk_spd", {duration = duration})
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_butcher_flesh_heap_regen", {duration = duration})
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_butcher_flesh_heap_life", {duration = duration})
		end
	end
end

function FleshHeapDeath( keys )
	local caster = keys.caster
	local ability = keys.ability
	local unit = keys.unit
	local duration = ability:GetSpecialValueFor("duration")
	local maxStacks = ability:GetSpecialValueFor("max_stacks")
	local curStacks = caster:GetModifierStackCount("modifier_butcher_flesh_heap", caster)

	local talentValues = caster:FindTalentValues("special_bonus_unique_butcher_4")
	if caster:HasTalent("special_bonus_unique_butcher_4") then
		if not caster:HasModifier("modifier_butcher_flesh_heap_magic_resist_talent") then
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_butcher_flesh_heap_magic_resist_talent", {})
		end
		maxStacks = maxStacks + talentValues["max_stacks"]
		duration = duration + talentValues["duration"]
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_butcher_flesh_heap_str_talent", {duration = duration})
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_butcher_flesh_heap_regen_talent", {duration = duration})
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_butcher_flesh_heap_life_talent", {duration = duration})
	end

	if curStacks < maxStacks then
		caster:SetModifierStackCount("modifier_butcher_flesh_heap", caster, curStacks + 1)
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_butcher_flesh_heap_str", {duration = duration})
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_butcher_flesh_heap_atk_spd", {duration = duration})
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_butcher_flesh_heap_regen", {duration = duration})
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_butcher_flesh_heap_life", {duration = duration})
	end
end