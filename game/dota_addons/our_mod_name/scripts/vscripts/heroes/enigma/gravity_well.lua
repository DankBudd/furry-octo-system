-- need to check refresher compatibility
function CreateGravityWellThinker( keys )
	local caster = keys.caster
	local ability = keys.ability
	local duration = ability:GetSpecialValueFor("duration") + 0.01
	local interval = ability:GetSpecialValueFor("think_interval")
	local radius = ability:GetSpecialValueFor("radius")

	local talentDuration = "special_bonus_unique_enigma_4"
	local talentDamage = "special_bonus_unique_enigma_3"

--	print("-------------- CreateGravityWellThinker --------------")

	-- gives me a table called values. values, in this instance, is {duration, tick_interval}
	-- in order to access these table values, you have to use whateverYouDefinedTheTableAs[1], whateverYouDefinedTheTableAs[2], and so on.
	-- or if you didnt define the table, then it should be:
	-- caster:FindTalentValue(talentDuration)[1]
	local talentValues = caster:FindTalentValue(talentDuration)

	if caster:HasTalent(talentDuration) then
		duration = duration + talentValues[1]
		interval = talentValues[2]
	end

	ability:ApplyDataDrivenThinker(caster, keys.target_points[1], "modifier_gravity_well_particle", {duration = duration})

	Timers:CreateTimer(function()
		-- initialize duration tracker
		if not ability.endTime then
--			print("creating endTime")
			ability.endTime = 0.0 
		end
--		print("adding interval to endTime")
		ability.endTime = ability.endTime + interval

		-- kill timer if gravity_well has reached the end of its duration
		if ability.endTime >= duration then
--		print("killing timer")
			ability.endTime = 0.0
			return nil
		end

--		print("finding targets")
		-- find targets
		local targets = FindUnitsInRadius(caster:GetTeamNumber(), keys.target_points[1], nil, radius,
						ability:GetAbilityTargetTeam(), ability:GetAbilityTargetType(), ability:GetAbilityTargetFlags(), FIND_ANY_ORDER, false)
		-- iterate through targets and damage/slow them
		for _,target in pairs(targets) do
			SlowTarget(ability, target, keys.modifier, duration)
			DamageTarget(ability, target, keys.modifier, talentDamage)
		end

--		print("endTime: ".. ability.endTime)
		-- repeat timer
		return interval
	end)
	--	print("-------------- CreateGravityWellThinker --------------")
end

function SlowTarget( ability, target, modifier, duration )
	local caster = ability:GetCaster()
	local debuff_duration = ability:GetSpecialValueFor("debuff_duration")
	local stackCount = target:GetModifierStackCount(modifier, caster)

--	print("-------------- SlowTarget --------------")
--	print("stackCount is: ".. stackCount)

	if target:HasModifier(modifier) then
--		print("incrementing stackCount")
		target:SetModifierStackCount(modifier, caster, stackCount+1)
	else
--		print("applying modifier")
		ability:ApplyDataDrivenModifier(caster, target, modifier, {duration = duration+debuff_duration})
	end
--	print("-------------- SlowTarget --------------")
end

function DamageTarget( ability, target, modifier, talentName )
	local caster = ability:GetCaster()
	local damage = ability:GetSpecialValueFor("damage")
	local talentValues = caster:FindTalentValue(talentName)

	-- if talent exists then increase damage based on debuff stacks and talent %value
	if caster:HasTalent( talentName ) and target:HasModifier( "modifier_gravity_well_slow" ) then
		-- damage = base dmg + % of base dmg
		damage = damage + (damage * target:GetModifierStackCount("modifier_gravity_well_slow", caster) * talentValues[1] * 0.01)
	end
	ApplyDamage({victim = target, attacker = caster, ability = ability, damage = damage, damage_type = ability:GetAbilityDamageType(), damage_flags = DOTA_DAMAGE_FLAG_NONE})
end