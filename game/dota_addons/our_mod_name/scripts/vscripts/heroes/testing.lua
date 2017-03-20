function KnockbackTest( keys )
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target

	local distance = ability:GetSpecialValueFor("distance")
	local speed = ability:GetSpecialValueFor("speed")
	local damage = ability:GetSpecialValueFor("dot")
	local direction = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized()
	local vertical = 322

	target:KnockbackUnit(distance, direction, speed, vertical, true)
	local particle = ParticleManager:CreateParticle("particles/units/heroes/spirit_breaker_greater_bash.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
--	ParticleManager:SetParticleControl(particle, int_2, Vector_3)
	EmitSoundOn(target, "Hero_Spirit_Breaker.GreaterBash")

	local tick = 0
	Timers:CreateTimer(0.45, function()
		ApplyDamage({victim = target, attacker = caster, ability = ability, damage = damage, damage_type = ability:GetAbilityDamageType()})
		PopupDoT(target, damage)
		tick = tick + 0.45
		if tick > 2 then
			return nil
		end
		return 0.45
	end)
end

function BlackHoleTest( keys )
	local caster = keys.caster
	local targetPoint = keys.target_points[1]

	for _,unit in pairs(FindUnitsInRadius(caster:GetTeamNumber(), targetPoint, nil, 500, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_CREEP + DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)) do
		local timer = unit:RotationalPullUnit(targetPoint, 200, 1000, "left", true, false, nil)
		Timers:CreateTimer(12, function()
			if not unit or unit:IsNull() then print("test | unit is null") return end
			unit:CancelKnockback(timer, true)
		end)
	end
end