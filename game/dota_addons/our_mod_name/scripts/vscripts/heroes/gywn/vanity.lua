--TEMPORARY FIX FOR INCORRECT STACKCOUNTS (maybe permanant bc im lazy)
--RE-INITIALIZE TABLE EVERY 3RD THINK INTERVAL
function InitializeTable( keys )
	keys.ability.facingTable = {}
	keys.caster:RemoveModifierByNameAndCaster(keys.modifier, keys.caster)
end

-- leveling vanity while it has stacks makes it bug out, fixed by temp fix
-- killing a unit that is in table causes it to not be removed, fixed by temp fix
function Vanity( keys )
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local radius = ability:GetSpecialValueFor("radius")
	local visionCone = ability:GetSpecialValueFor("vision_cone")
	local modifier = keys.modifier

	if caster:PassivesDisabled() then
		if caster:HasModifier(modifier) then
			caster:RemoveModifierByNameAndCaster(modifier, caster)
		end
		return
	end

	local stackCount = caster:GetModifierStackCount(modifier, caster)
	local check = false

	local casterPos = caster:GetAbsOrigin()
	local targetPos = target:GetAbsOrigin()

	local direction = (casterPos - targetPos):Normalized()
	local forwardVector = target:GetForwardVector()
	local angle = math.abs(RotationDelta((VectorToAngles(direction)), VectorToAngles(forwardVector)).y)
--	print("Angle: " .. angle)


	-- facing check
	if angle <= visionCone/2 then
		-- check if unit is already in table (if it is, we will not increment stack count)
		for k,v in pairs(ability.facingTable) do
			if v == target then
				check = true
--				print("Unit is already in table! ::Check1::")
				target.justAdded = false
			end
		end

		-- add unit to "facing" table, if its not already in it
		if not check then
			table.insert(ability.facingTable, target)
--			print("Unit added to table!")
			target.justAdded = true
		end

		-- increment stackCount if this unit was JUST added to facing table
		if target.justAdded then
--			print("Incrementing stackCount")
			if not caster:HasModifier(modifier) then
				ability:ApplyDataDrivenModifier(caster, caster, modifier, {})
				caster:SetModifierStackCount(modifier, caster, 1)
			else
				caster:SetModifierStackCount(modifier, caster, stackCount + 1)
			end
		end
	else
		-- check if unit is in table (if it is, we will decrement stack count)
		for k,v in pairs(ability.facingTable) do
			if v == target then
				check = true
--				print("Unit is in table! ::Check2::")
			end
		end

		-- remove unit from "facing" table, if its in it
		if check then
			for i = 1, #ability.facingTable do
				if ability.facingTable[i] == target then
					table.remove(ability.facingTable, i)
--					print("Unit removed from table!")
					target.justRemoved = true
				end
			end
		end	

		-- decrement stackCount if unit was JUST removed from table		
		if target.justRemoved and stackCount > 1 then
--			print("Decrementing stackCount")
			caster:SetModifierStackCount(modifier, caster, stackCount - 1)
			target.justRemoved = false
		elseif stackCount <= 1 and #ability.facingTable <= 0 then
			caster:RemoveModifierByNameAndCaster(modifier, caster)
		end
	end
end