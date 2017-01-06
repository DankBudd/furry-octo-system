-- check if target should be taunted or slowed on every think interval
function Taunt( keys )
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local visionCone = ability:GetSpecialValueFor("taunt_width")
	local modifier = keys.modifier
	
	-- clear the force attack target
	target:SetForceAttackTarget(nil)

	-- angle information
	local casterPos = caster:GetAbsOrigin()
	local targetPos = target:GetAbsOrigin()
	local direction = (casterPos - targetPos):Normalized()
	local forwardVector = target:GetForwardVector()
	local angle = math.abs(RotationDelta((VectorToAngles(direction)), VectorToAngles(forwardVector)).y)
	
	-- check if target is looking at caster
	if angle <= visionCone/2 then
		-- give the attack order if the caster is alive
		-- otherwise forces the target to sit and do nothing
		if caster:IsAlive() then
			local order = {
					UnitIndex = target:entindex(),
					OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
					TargetIndex = caster:entindex()
			}

			ExecuteOrderFromTable(order)
		else
			target:Stop()
		end
		-- set the force attack target to be the caster
		target:SetForceAttackTarget(caster)
	else
		-- if target is looking away from caster, slow them instead
		ability:ApplyDataDrivenModifier(caster, target, modifier, {})
	end
end

-- clears the force attack target upon expiration
function TauntEnd( keys )
	local target = keys.target

	target:SetForceAttackTarget(nil)
end