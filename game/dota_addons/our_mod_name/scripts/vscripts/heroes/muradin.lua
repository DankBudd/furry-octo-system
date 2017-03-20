function HammerTesting( keys )
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local modelSize = ability:GetLevel()/0.75

	local targetPos = target:GetAbsOrigin()
	local casterPos = caster:GetAbsOrigin()

	local particle = ParticleManager:CreateParticle("particles/hammer_concept.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
	ParticleManager:SetParticleControl(particle, 0, targetPos)
	ParticleManager:SetParticleControl(particle, 1, casterPos)
--[[local model = caster:FirstMoveChild()
	while model ~= nil do
		if model:GetClassname() == "dota_item_wearable" then
			print("Name: "..model:GetName())
			print("Classname: "..model:GetClassname())
			print("Model Name: "..model:GetModelName())
			print("Private: ")
			DeepPrintTable(model:GetOrCreatePrivateScriptScope())
			print("Model: ")
			DeepPrintTable(model)
			print("---next---")
		end
		model = model:NextMovePeer()
	end]]
end

--[[///////////////
/// Storm Bolt ///
/////////////////]]

function MuradinQ( keys )
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability

	local baseDamage = ability:GetSpecialValueFor("damage")
	local strDamage = ability:GetSpecialValueFor("str_dmg")
	local knockback = ability:GetSpecialValueFor("knockback")
	local resistReduction = ability:GetSpecialValueFor("resist_reduction")
	local armorReduction = ability:GetSpecialValueFor("armor_reduction")
	local stunDuration = ability:GetSpecialValueFor("stun_duration")

	local talentValues = caster:FindTalentValues("special_bonus_unique_muradin_2")
	if caster:HasTalent("special_bonus_unique_muradin_2") then
		baseDamage = baseDamage + talentValues["damage"]
		strDamage = strDamage + talentValues["str_dmg"]
		knockback = knockback + talentValues["knockback"]
		resistReduction = resistReduction + talentValues["resist_reduction"]
	end

	ability.damage = baseDamage + caster:GetStrength()*strDamage*0.01
	ability.knockback = knockback
	ability.resistReduction = resistReduction
	ability.armorReduction = armorReduction
	ability.stunDuration = stunDuration
	ability.primaryOrigin = caster:GetAbsOrigin()

	local info = {
		hTarget = target,
		hCaster = caster,
		hAbility = ability,
		iMoveSpeed = 1100,
		EffectName = "particles/units/heroes/hero_sven/sven_spell_storm_bolt.vpcf",
		SoundName = "Hero_Sven.StormBoltImpact",
		flRadius = 200,
		OnProjectileHitUnit = function( params, projectileID )
			--primary hammer hit
			local caster = params.caster
			local target = params.target
			local ability = params.ability
			local talentValues = caster:FindTalentValues("special_bonus_unique_muradin_2")

			if target and not target:IsNull() then
				local units = FindUnitsInRadius(caster:GetTeam(), target:GetAbsOrigin(), nil, talentValues["radius"], ability:GetAbilityTargetTeam(), ability:GetAbilityTargetType(), DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
				if caster:HasTalent("special_bonus_unique_muradin_2") then
					if #units > 1 then
						--damage primary
						ability.secondaryOrigin = target:GetAbsOrigin()
						ApplyDamage({victim = target, attacker = caster, ability = ability, damage = ability.damage, damage_type = ability:GetAbilityDamageType()})
						target:KnockbackUnit(ability.knockback, (target:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized(), 700, 0, true)
						target:AddNewModifier(caster, ability, "modifier_stunned", ability.stunDuration)
						ability:ApplyDataDrivenModifier(caster, target, "modifier_muradin_q_armor_reduction", {})
						ability:ApplyDataDrivenModifier(caster, target, "modifier_muradin_q_resist_reduction", {})
						target:SetModifierStackCount("modifier_muradin_q_armor_reduction", caster, ability.armorReduction)
						target:SetModifierStackCount("modifier_muradin_q_resist_reduction", caster, ability.resistReduction)
						--fire secondary hammers
						for _,unit in pairs(units) do
							local infoSecondary = {
								hTarget = unit,
								hCaster = caster,
								hAbility = ability,
								iMoveSpeed = 900,
								EffectName = "particles/units/heroes/hero_sven/sven_spell_storm_bolt.vpcf",
								SoundName = "Hero_Sven.StormBoltImpact",
								flRadius = 200,
								OnProjectileHitUnit = function( params, projectileID )
									--secondary hammer hit
									local caster = params.caster
									local target = params.target
									local ability = params.ability

									if target and not target:IsNull() then
										ApplyDamage({victim = target, attacker = caster, ability = ability, damage = ability.damage, damage_type = ability:GetAbilityDamageType()})
										target:KnockbackUnit(ability.knockback, (target:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized(), 700, 0, true)
										target:AddNewModifier(caster, ability, "modifier_stunned", ability.stunDuration)
										ability:ApplyDataDrivenModifier(caster, target, "modifier_muradin_q_armor_reduction", {})
										ability:ApplyDataDrivenModifier(caster, target, "modifier_muradin_q_resist_reduction", {})
										target:SetModifierStackCount("modifier_muradin_q_armor_reduction", caster, ability.armorReduction)
										target:SetModifierStackCount("modifier_muradin_q_resist_reduction", caster, ability.resistReduction)
									end
								end,
								OnProjectileDestroy = function( params, projectileID )
									-- do nothing
								end,
								bDodgeable = true,
							}
							local projectileSecondary = TrackingProjectiles:Projectile(infoSecondary)
						end
					else
						--bonus dmg to target
						ApplyDamage({victim = target, attacker = caster, ability = ability, damage = ability.damage + target:GetMaxHealth()*talentValues["bonus_damage"]*0.01, damage_type = caster:FindAbilityByName("special_bonus_unique_muradin_2"):GetAbilityDamageType()})
						target:KnockbackUnit(ability.knockback, (target:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized(), 700, 0, true)
						target:AddNewModifier(caster, ability, "modifier_stunned", ability.stunDuration)
						ability:ApplyDataDrivenModifier(caster, target, "modifier_muradin_q_armor_reduction", {})
						ability:ApplyDataDrivenModifier(caster, target, "modifier_muradin_q_resist_reduction", {})
						target:SetModifierStackCount("modifier_muradin_q_armor_reduction", caster, ability.armorReduction)
						target:SetModifierStackCount("modifier_muradin_q_resist_reduction", caster, ability.resistReduction)
					end
				else
					--normal stuff
					ApplyDamage({victim = target, attacker = caster, ability = ability, damage = ability.damage, damage_type = ability:GetAbilityDamageType()})
					target:KnockbackUnit(ability.knockback, (target:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized(), 700, 0, true)
					target:AddNewModifier(caster, ability, "modifier_stunned", ability.stunDuration)
					ability:ApplyDataDrivenModifier(caster, target, "modifier_muradin_q_armor_reduction", {})
					ability:ApplyDataDrivenModifier(caster, target, "modifier_muradin_q_resist_reduction", {})
					target:SetModifierStackCount("modifier_muradin_q_armor_reduction", caster, ability.armorReduction)
					target:SetModifierStackCount("modifier_muradin_q_resist_reduction", caster, ability.resistReduction)
				end
			end
		end,
		OnProjectileDestroy = function( params, projectileID )
			--do nothing
		end,
		bDodgeable = true,
	}
	local projectile = TrackingProjectiles:Projectile(info)
end

--[[/////////////////
/// Thunder Clap ///
///////////////////]]

function MuradinW( keys )
	local caster = keys.caster
	local ability = keys.ability
	local radius = ability:GetSpecialValueFor("radius")
	local duration = ability:GetSpecialValueFor("duration")
	local baseDamage = ability:GetSpecialValueFor("damage")
	local strDamage = ability:GetSpecialValueFor("str_dmg") * 0.01
	local perUnitDamage = ability:GetSpecialValueFor("unit_dmg")

	local talent = "special_bonus_unique_muradin_1"
	local talentValues
	if caster:HasTalent(talent) then
		talentValues = caster:FindTalentValues(talent)
		baseDamage = baseDamage + talentValues["damage"]
		strDamage = strDamage + talentValues["str_dmg"] * 0.01
		radius = radius + talentValues["radius"]
		perUnitDamage = talentValues["unit_dmg"]
	end

	local units = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, radius, ability:GetAbilityTargetTeam(), ability:GetAbilityTargetType(), DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	local damage = baseDamage + caster:GetStrength() * strDamage + perUnitDamage * #units
	for _,unit in pairs(units) do
		if #units >= 1 then
			local damageFinal = damage
			if caster:HasTalent("special_bonus_unique_muradin_4") then
				local abilityF = caster:FindAbilityByName("muradin_f")
				abilityF:ApplyDataDrivenModifier(caster, unit, "modifier_muradin_f_burn", {})
				unit:SetModifierStackCount("modifier_muradin_f_burn", caster, abilityf:GetSpecialValueFor("w_dps") + abilityf:GetSpecialValueFor("w_str_dps") * caster:GetStrength() * 0.01)
			end
			if caster:HasTalent(talent) then
				if not caster:HasModifier("modifier_muradin_w_bonus_damage") then
					ability:ApplyDataDrivenModifier(caster, caster, "modifier_muradin_w_bonus_damage", {})
				else
					caster:SetModifierStackCount("modifier_muradin_w_bonus_damage", caster, caster:GetModifierStackCount("modifier_muradin_w_bonus_damage", caster) + talentValues["bonus_damage"])
				end
				PopupHealing(caster, caster:GetMaxHealth() * talentValues["heal"] * 0.01 * #units)
				caster:Heal(caster:GetMaxHealth() * talentValues["heal"] * 0.01, caster)
				damageFinal = damageFinal + damageFinal * unit:GetMaxHealth() * talentValues["pct_dmg"] * 0.01
			end
			ApplyDamage({victim = unit, attacker = caster, ability = ability, damage = damage, damage_type = ability:GetAbilityDamageType(), damage_flags = DOTA_DAMAGE_FLAG_NONE})
			ability:ApplyDataDrivenModifier(caster, unit, "modifier_muradin_w_slow", {duration = duration})
		end
	end
end

--[[/////////////////////////////
/// Strength of the Mountain ///
///////////////////////////////]]

function MuradinE( keys )
	local caster = keys.caster
	local ability = keys.ability
	
	local attackDamage = ability:GetSpecialValueFor("damage_bonus")
	local attackSpeed = ability:GetSpecialValueFor("atkspeed_bonus")
	local numAttack = ability:GetSpecialValueFor("num_atk")

	local talentValues = caster:FindTalentValues("special_bonus_unique_muradin_3")
	if caster:HasTalent("special_bonus_unique_muradin_3") then
		attackDamage = attackDamage + talentValues["damage_bonus"]
		attackSpeed = attackSpeed + talentValues["atkspeed_bonus"]
	end
	--apply modifiers
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_muradin_e_buff", {})
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_muradin_e_bonus_damage", {})
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_muradin_e_attack_speed", {})
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_muradin_e_cleave", {})

	caster:SetModifierStackCount("modifier_muradin_e_buff", caster, numAttack)
	caster:SetModifierStackCount("modifier_muradin_e_bonus_damage", caster, attackDamage)
	caster:SetModifierStackCount("modifier_muradin_e_attack_speed", caster, attackSpeed)
end

function MuradinEDecrement( keys )
	local caster = keys.caster
	local ability = keys.ability
	caster:SetModifierStackCount("modifier_muradin_e_buff", caster, caster:GetModifierStackCount("modifier_muradin_e_buff", caster)-1)
	if caster:GetModifierStackCount("modifier_muradin_e_buff", caster) <= 0 then
		ApplyDamage({victim = keys.target, attacker = caster, ability = ability, damage = caster:GetAttackDamage(), damage_type = ability:GetAbilityDamageType()})
		caster:RemoveModifierByNameAndCaster("modifier_muradin_e_buff", caster)
		caster:RemoveModifierByNameAndCaster("modifier_muradin_e_bonus_damage", caster)
		caster:RemoveModifierByNameAndCaster("modifier_muradin_e_attack_speed", caster)
		caster:RemoveModifierByNameAndCaster("modifier_muradin_e_cleave", caster)
	end
end

function MuradinEUnitKilled( keys )
	local ability = keys.ability
	if not keys.unit:IsBuilding() and not keys.caster:IsIllusion() then
		local oldCD = ability:GetCooldownTime()
		local reduction = ability:GetSpecialValueFor("cd_reduction")
		ability:EndCooldown()
		ability:StartCooldown(oldCD - reduction)
	end
end

--[[///////////
/// Avatar ///
/////////////]]

function MuradinR( keys ) 
	local caster = keys.caster
	local ability = keys.ability

	local bonusDamage = ability:GetSpecialValueFor("bonus_damage")
	local bonusArmor = ability:GetSpecialValueFor("bonus_armor")
	local bonusLife = ability:GetSpecialValueFor("bonus_life")
	local duration = ability:GetSpecialValueFor("duration")

	local talentValues = caster:FindTalentValues("special_bonus_unique_muradin_6")
	if caster:HasTalent("special_bonus_unique_muradin_6") then
		bonusDamage = bonusDamage + talentValues["bonus_damage"]
		bonusArmor = bonusArmor + talentValues["bonus_armor"]
		bonusLife = bonusLife + talentValues["bonus_life"]
		--reduce duration???
		duration = duration + talentValues["duration"]

		local units = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, talentValues["radius"], ability:GetAbilityTargetTeam(), ability:GetAbilityTargetType(), DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
		for _,unit in pairs(units) do
			if #units >= 1 then
				--damage and stun units
				unit:AddNewModifier(caster, ability, "modifier_stunned", {duration = talentValues["stun_duration"]})
				ApplyDamage({victim = unit, attacker = caster, ability = ability, damage = talentValues["aoe_damage"], damage_type = caster:FindAbilityByName("special_bonus_unique_muradin_5"):GetAbilityDamageType()})
			end
		end
	end
	--apply modifiers
	caster:AddNewModifier(caster, ability, "modifier_omniknight_repel", {duration = duration})
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_muradin_r_buff", {duration = duration})
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_muradin_r_bonus_damage", {})
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_muradin_r_bonus_armor", {})
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_muradin_r_bonus_life", {})

	caster:SetModifierStackCount("modifier_muradin_r_bonus_damage", caster, bonusDamage)
	caster:SetModifierStackCount("modifier_muradin_r_bonus_armor", caster, bonusArmor)
	caster:SetModifierStackCount("modifier_muradin_r_bonus_life", caster, bonusLife)
end

--[[/////////////////
/// Dwarft Might ///
///////////////////]]

function MuradinD( keys )
	local caster = keys.caster
	local ability = keys.ability

	local strBonus = ability:GetSpecialValueFor("str_bonus")
	local lifeRegen = ability:GetSpecialValueFor("life_regen")
	local lifeBonus = ability:GetSpecialValueFor("life_bonus")
	local magicResist = ability:GetSpecialValueFor("magic_resist")
	local strForArmor = ability:GetSpecialValueFor("str_for_armor")

	local talentValues = caster:FindTalentValues("special_bonus_unique_muradin_5")
	if caster:HasTalent("special_bonus_unique_muradin_5") then
		strForArmor = strForArmor + talentValues["str_for_armor"]
		strBonus = strBonus * talentValues["multiplier"]
		lifeRegen = lifeRegen * talentValues["multiplier"]
		lifeBonus = lifeBonus * talentValues["multiplier"]
		magicResist = magicResist * talentValues["multiplier"]
	end

	local casterStr = caster:GetStrength()
	local calc = casterStr * strForArmor * 0.01
	if calc >= 1 then
		if not caster:HasModifier("modifier_muradin_d_armor") then
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_muradin_d_armor", {})
		end
		caster:SetModifierStackCount("modifier_muradin_d_armor", caster, calc)
	else
		if caster:HasModifier("modifier_muradin_d_armor") then
			RemoveModifierByNameAndCaster("modifier_muradin_d_armor", caster)
		end
	end
	caster:SetModifierStackCount("modifier_muradin_d_strength", caster, strBonus)
	caster:SetModifierStackCount("modifier_muradin_d_regen", caster, lifeRegen)
	caster:SetModifierStackCount("modifier_muradin_d_life", caster, lifeBonus)
	caster:SetModifierStackCount("modifier_muradin_d_resist", caster, magicResist)

	caster:CalculateStatBonus()
end

--[[///////////////////
/// Dwarft Mastery ///
/////////////////////]]

function MuradinF( keys )
	local caster = keys.caster
	local ability = keys.ability

	local damage = ability:GetSpecialValueFor("bonus_damage")
	local speed = ability:GetSpecialValueFor("atkspeed_bonus")

	local talentValues = caster:FindTalentValues("special_bonus_unique_muradin_4")
	if caster:HasTalent("special_bonus_unique_muradin_4") then
		speed = speed + talentValues["atkspeed_bonus"]
	end

	caster:SetModifierStackCount("modifier_muradin_f_damage", caster, damage)
	caster:SetModifierStackCount("modifier_muradin_f_attack_speed", caster, speed)
end

function MuradinFBash( keys )
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target

	local bashDamage = ability:GetSpecialValueFor("bash_damage")
	local damageType = ability:GetAbilityDamageType()

	local talentValues = caster:FindTalentValues("special_bonus_unique_muradin_4")
	if caster:HasTalent("special_bonus_unique_muradin_4") then
		local stacks = caster:GetModifierStackCount("modifier_muradin_f_bash_stack", caster)
		if stacks ~= 0 then
			bashDamage = bashDamage + talentValues["bash_damage"] * stacks
		else
			bashDamage = bashDamage + talentValues["bash_damage"]
		end
		if stacks >= 4 and not caster:HasModifier("modifier_muradin_f_bash_speed_cd") then
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_muradin_f_bash_speed", {duration = 5})
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_muradin_f_bash_speed_cd", {duration = 14})
			damageType = caster:FindAbilityByName("special_bonus_unique_muradin_4"):GetAbilityDamageType()
		end
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_muradin_f_bash_stack", {duration = talentValues["duration"]})
		caster:SetModifierStackCount("modifier_muradin_f_bash_stack", caster, stacks + 1)
	end

	ApplyDamage({victim = target, attacker = caster, ability = ability, damage = bashDamage, damage_type = damageType})
end

function MuradinFBurn( keys )
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local damage = target:GetModifierStackCount("modifier_muradin_f_burn", caster)

	ApplyDamage({victim = target, attacker = caster, ability = ability, damage = damage, damage_type = caster:FindAbilityByName("special_bonus_unique_muradin_4"):GetAbilityDamageType()})
end