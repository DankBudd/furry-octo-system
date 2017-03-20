function Applier( keys )
	if keys.ability:GetAutoCastState() and not keys.target:IsBuilding() then
		local particle = ParticleManager:CreateParticle("particles/dark_purple_smoke.vpcf", PATTACH_ABSORIGIN, keys.target)
		if keys.target:HasModifier("modifier_black_smoke_dot") then
			keys.target:RemoveModifierByNameAndCaster("modifier_black_smoke_dot", keys.caster)
		end
		keys.ability:ApplyDataDrivenModifier(keys.caster, keys.target, "modifier_black_smoke_dot", {})
		local tick = 0
		Timers:CreateTimer(0.03, function()
			if keys.target:IsNull() then return nil end
			if not keys.target:IsAlive() then
				ParticleManager:DestroyParticle(particle,false)
				return nil
			end
			tick = tick+0.03
			ParticleManager:SetParticleControl(particle, 0, keys.target:GetAbsOrigin()+Vector(0,0,50))
			-- 2.76 = particle duration
			if tick < 2.76 then
				return 0.03
			end
		end)
	end
end

function Attack( keys )
	if keys.target and keys.caster then
		if keys.target:IsAlive() and keys.caster:IsAlive() then
			keys.caster:PerformAttack(keys.target, true, true, false, true, true, false, true)
		end
	end
end