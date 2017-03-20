function JuggernautQ( keys )
	local ability = keys.ability
	-- find caster and potential target
	local caster
	local mainTarget
	if keys.castAttack then
		caster = keys.attacker
		mainTarget = keys.target
	else
		caster = keys.caster
		mainTarget = nil
	end

	-- handle whether or not the ability should actually be cast
	if caster.castingQ or caster.manaCostQ or caster.cooldownQ or caster:IsSilenced() or keys.castAttack and not ability:GetAutoCastState() then return end 
	
	-- start casting
	caster.castingQ = true

	--find main hero
	local owner
	if caster:IsJuggernautIllusion() then
		owner = caster:GetOwner()
	else
		owner = keys.caster
	end

	local bonusDamage = ability:GetSpecialValueFor("bonus_damage")
	if caster ~= owner then bonusDamage = bonusDamage/2 end
	--stackable bonus damage modifier
	if not caster:HasModifier("modifier_juggernaut_q_bonus_damage") then
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_juggernaut_q_bonus_damage", {duration = ability:GetSpecialValueFor("duration")})
		caster:SetModifierStackCount("modifier_juggernaut_q_bonus_damage", caster, bonusDamage)
	else
		caster:SetModifierStackCount("modifier_juggernaut_q_bonus_damage", caster, caster:GetModifierStackCount("modifier_juggernaut_q_bonus_damage", caster) + bonusDamage)
	end

	-- attack visible targets in front of caster
	local unitsHit = 0
	local targets = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, ability:GetSpecialValueFor("radius"), ability:GetAbilityTargetTeam(), ability:GetAbilityTargetType(), DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, FIND_CLOSEST, false)
	if #targets > 0 then
		for _,target in pairs(targets) do
			-- angle info
			local casterPos = caster:GetAbsOrigin()
			local casterForward = caster:GetForwardVector()
			local visionCone = 85
			local targetPos = target:GetAbsOrigin()
			local direction = (targetPos - casterPos):Normalized()
			local angle = math.abs(RotationDelta((VectorToAngles(direction)), VectorToAngles(casterForward)).y)
		--	DeepTablePrint({casterPos, casterForward, visionCone, targetPos, direction, angle})

			if angle <= visionCone/2 and unitsHit < ability:GetSpecialValueFor("max_units") then
				if mainTarget then
					if mainTarget ~= target then
						JuggernautQAttack(caster, target, owner)
					end
				else
					JuggernautQAttack(caster, target, owner)
				end
				unitsHit = unitsHit+1
			end
		end
	end
	-- spend mana and cd if ability was autocasted
	if keys.castAttack then
		ability:UseResources(true, false, true)
	end
	-- stop casting
	caster:SetForceAttackTarget(nil)
	caster.castingQ = false
end

--seperated this from the ability so i didnt have to write it twice
function JuggernautQAttack( caster, target, owner )
	Timers:CreateTimer(0.08+RandomFloat(0.01, 0.02), function()
		if not target:IsAlive() then return end
		ExecuteOrderFromTable({UnitIndex = caster:entindex(), OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET, TargetIndex = target:entindex()})
		caster:SetForceAttackTarget(target)
		caster:PerformAttack(target, true, true, true, true, false, false, true)		
		CreateJuggernautIllusion(caster, owner)
	end)
	Timers:CreateTimer(0.15, function()
		-- stop casting
		caster:SetForceAttackTarget(nil)
		caster.castingQ = false
	end)
end

function PhaseStartGesture( keys )
	local caster = keys.caster
	local ability = keys.ability
	--part of autocast logic
	caster.cooldownQ = ability:IsCooldownReady() == false
	caster.manaCostQ = ability:GetManaCost(ability:GetLevel()-1) > caster:GetMana()

	if not keys.ordered then
		local targets = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, ability:GetSpecialValueFor("radius"), ability:GetAbilityTargetTeam(), ability:GetAbilityTargetType(), DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, FIND_CLOSEST, false)
		--replace current animation with rare animation
		if #targets <= 0 then
			caster.playingRare = true
			if keys.castAttack and ability:GetAutoCastState() then
				caster:RemoveGesture(ACT_DOTA_ATTACK) -- attack animation
				caster:StartGesture(ACT_DOTA_IDLE_RARE) -- replacement animation
			else
				caster:RemoveGesture(ACT_DOTA_ATTACK_EVENT) -- cast animation
				caster:StartGesture(ACT_DOTA_IDLE_RARE) -- replacement animation
			end
			caster.rareTimer = Timers:CreateTimer(1.8, function()
				caster.playingRare = false
			end)
		elseif not keys.castAttack then
			--"illuminate" caster
			if not caster:HasModifier("modifier_juggernaut_q_illumination") then
				ability:ApplyDataDrivenModifier(caster, caster, "modifier_juggernaut_q_illumination", {duration = 2.0})
			end
		end
	-- cancel rare animation
	elseif caster.playingRare then
		Timers:RemoveTimer(caster.rareTimer)
		caster:RemoveGesture(ACT_DOTA_IDLE_RARE)
		caster.playingRare = false
	-- stop "illuminating" caster
	elseif not caster.playingRare then
		caster:RemoveModifierByNameAndCaster("modifier_juggernaut_q_illumination", caster)
	end
end

function CreateJuggernautIllusion(caster, owner)
	local ultimate = owner:FindAbilityByName("juggernaut_r")
	
	--should we spawn an illusion right now?
	if not (ultimate:GetLevel() > 0) or not owner:IsAlive() or owner:PassivesDisabled() or #owner.illusionTable > ultimate:GetSpecialValueFor("max_illusions") then return end
	caster.currentHits = caster.currentHits or 0
	if caster.currentHits < ultimate:GetSpecialValueFor("num_hit_for_illusion") then
		caster.currentHits = caster.currentHits + 1
		return
	end

	local vector = caster:GetAbsOrigin() + RandomVector(75)
	--spawn an illusion and reset 'hit' counter
	caster.currentHits = 0
	local illusion = CreateUnitByName(owner:GetUnitName(), vector, false, owner, nil, owner:GetTeamNumber())
	illusion:SetOwner(owner)
	illusion:SetPlayerID(owner:GetPlayerID())
	illusion:SetForwardVector(caster:GetForwardVector())
	table.insert(owner.illusionTable, illusion)

	-- Level Up the unit to the casters level
	local casterLevel = caster:GetLevel()-1
	for i = 1, casterLevel do
		illusion:HeroLevelUp(false)
	end
	-- mightve broken it
-------------------------------------------------------------------------
	-- Set the skill points to 0 and learn the skills of the caster
	illusion:SetAbilityPoints(0)
	for abilitySlot = 0, 17 do
		local ability = caster:GetAbilityByIndex(abilitySlot)
		if ability ~= nil then 
			local abilityLevel = ability:GetLevel()
			local abilityName = ability:GetAbilityName()
			local illusionAbility = illusion:FindAbilityByName(abilityName)
			illusionAbility:SetLevel(abilityLevel)
			if ability:GetAutoCastState() ~= illusionAbility:GetAutoCastState() then
				illusionAbility:ToggleAutoCast()
			end
		end
	end
------------------------------------------------------------------------------
	-- Recreate the items of the caster
	for itemSlot = 0, 8 do
		local item = caster:GetItemInSlot(itemSlot)
		if item ~= nil then
			local itemName = item:GetName()
			if itemName ~= "item_aegis" and itemName ~= "item_rapier" and itemName ~= "item_gem" then
				local newItem = CreateItem(itemName, illusion, illusion)
				illusion:AddItem(newItem)
			end
		end
	end

	-- Set the unit as an a juggernaut illusion
	illusion:AddNewModifier(owner, nil, "modifier_kill", {duration = ultimate:GetSpecialValueFor("illusion_duration")})
	ultimate:ApplyDataDrivenModifier(owner, illusion, "modifier_juggernaut_r_illusion", nil)
end

function JuggernautIllusionLogic( filterTable )
	-- find the caster, e.g. illusion owner
	local caster 
	for _,unitIndex in pairs(filterTable["units"]) do
		local unit = EntIndexToHScript(unitIndex)
		if unit:GetUnitName() == "npc_dota_hero_juggernaut" and unit:IsRealHero() and not unit:IsJuggernautIllusion() then
			caster = unit
			break
		end
	end

	-- does the caster have any illusions to command?
	caster.illusionTable = caster.illusionTable or {}
	if #caster.illusionTable <= 0 then return end

	-- order information
	local orderType = filterTable["order_type"]
	local casterAbilityIndex = filterTable["entindex_ability"]
	local casterAbility = EntIndexToHScript(casterAbilityIndex)
	local casterTarget = EntIndexToHScript(filterTable["entindex_target"])
	local casterTargetPoint = Vector(filterTable["position_x"], filterTable["position_y"], filterTable["position_z"])

	-- go through all existing ultimate illusions and command them.
	for _,illusion in pairs(caster.illusionTable) do
		-- for as long as caster is alive and not broken continue to follow his orders
		if caster:IsAlive() and not caster:PassivesDisabled() then
			--apply phased modifier so illusions dont get clustered
			illusion:AddNewModifier(caster, nil, "modifier_phased", {duration = 0.7})

			-- support for ability casting
			if casterAbilityIndex ~= 0 then
				for abilitySlot = 0, 17 do
					local ability = illusion:GetAbilityByIndex(abilitySlot)
					if ability ~= nil and casterAbility ~= nil then
						if ability:GetAbilityName() == casterAbility:GetAbilityName() then
							-- Cast No Target
							if orderType == DOTA_UNIT_ORDER_CAST_NO_TARGET then
								StateCastNoTarget(illusion, ability)
							-- Cast Target
							elseif orderType == DOTA_UNIT_ORDER_CAST_TARGET then
								StateCastTarget(illusion, ability, casterTarget)
							-- Cast Position
							elseif orderType == DOTA_UNIT_ORDER_CAST_POSITION then
								StateCastPoint(illusion, ability, casterTargetPoint)
							end
						end
					end
				end
			
			-- support for item casting
				for itemSlot = 0, 5 do
					local item = illusion:GetItemInSlot(itemSlot)
					if item ~= nil and casterAbility ~= nil then
						if item:GetName() == casterAbility:GetName() then
							-- Cast No Target
							if orderType == DOTA_UNIT_ORDER_CAST_NO_TARGET then
								StateCastNoTarget(illusion, item)
							-- Cast Target
							elseif orderType == DOTA_UNIT_ORDER_CAST_TARGET then
								StateCastTarget(illusion, item, casterTarget)
							-- Cast Position
							elseif orderType == DOTA_UNIT_ORDER_CAST_POSITION then
								StateCastPoint(illusion, item, casterTargetPoint)
							end
						end
					end
				end
			end
			--orderType inputs are optional, set it up this way incase i plan on adding more orders that work more dynamically.
			
			-- Passive
			if orderType == (DOTA_UNIT_ORDER_MOVE_TO_POSITION or DOTA_UNIT_ORDER_MOVE_TO_TARGET) then
				StatePassiveMove(illusion, orderType, casterTarget, casterTargetPoint)
			-- Aggresive
			elseif orderType == DOTA_UNIT_ORDER_ATTACK_MOVE then
				StateAggressiveMove(illusion, orderType, casterTargetPoint)
			-- Attack Target
			elseif orderType == DOTA_UNIT_ORDER_ATTACK_TARGET then
				StateAttackTarget(illusion, orderType, casterTarget)
			-- Halt
			elseif orderType == DOTA_UNIT_ORDER_HOLD_POSITION then
				StateHold(illusion, orderType)
			end
		else
			break
		end
	end
end

--[[
	ILLUSION ORDERS
	---------------
]]
function StatePassiveMove( illusion, orderType, target, targetPoint )
	if target and not targetPoint then
		if target:IsAlive() then
			orderType = DOTA_UNIT_ORDER_MOVE_TO_TARGET
		else
			orderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION
			targetPoint = target:GetAbsOrigin()
		end
	elseif not target and targetPoint then
		orderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION
	end
	local order
	if orderType == DOTA_UNIT_ORDER_MOVE_TO_POSITION then
		order = {
			UnitIndex = illusion:entindex(),
			OrderType = orderType,
			Position = targetPoint

		}
	elseif orderType == DOTA_UNIT_ORDER_MOVE_TO_TARGET then
		order = {
			UnitIndex = illusion:entindex(),
			OrderType = orderType,
			TargetIndex = target:entindex()
		}
	end
	ExecuteOrderFromTable(order)
end


function StateAggressiveMove( illusion, orderType, targetPoint )
	if not orderType then orderType = DOTA_UNIT_ORDER_ATTACK_MOVE end
	local order = {
		UnitIndex = illusion:entindex(),
		OrderType = orderType,
		Position = targetPoint
	}
	ExecuteOrderFromTable(order)
end


function StateAttackTarget( illusion, orderType, target )
	if not orderType then orderType = DOTA_UNIT_ORDER_ATTACK_TARGET end
	if not target:IsAlive() then
		StatePassiveMove(illusion, nil, target, nil)
	end
	local order = {
		UnitIndex = illusion:entindex(),
		OrderType = orderType,
		TargetIndex = target:entindex()
	}
	ExecuteOrderFromTable(order)
end


function StateHold( illusion, orderType )
	if not orderType then orderType = DOTA_UNIT_ORDER_HOLD_POSITION end
	local order = {
		UnitIndex = illusion:entindex(),
		OrderType = orderType
	}
	ExecuteOrderFromTable(order)
end

function StateCastNoTarget( illusion, ability )
	if not ability:IsCooldownReady() then
		StateAggressiveMove(illusion, nil, illusion:GetOwner():GetAbsOrigin())
	end
	illusion:CastAbilityNoTarget(ability, illusion:GetEntityIndex())
end

function StateCastTarget( illusion, ability, target )
	if not ability:IsCooldownReady() then 
			StateAttackTarget(illusion, nil, target)
		return 
	end
	illusion:CastAbilityOnTarget(target:GetEntityIndex(), ability, illusion:GetEntityIndex())
end

function StateCastPoint( illusion, ability, targetPoint )
	if not ability:IsCooldownReady() then
		 	StateAggressiveMove(illusion, nil, targetPoint)
		return 
	end
	illusion:CastAbilityOnPosition(targetPoint, ability, illusion:GetEntityIndex())
end
------------------------------------------------------------------------------------

function RemoveIllusionFromTable( keys )
	local caster = keys.caster
	local unit = keys.unit
	for pos, illusion in pairs(caster.illusionTable) do
		if illusion == unit then
			-- turn them into actual illusions before removing them to prevent respawning
			unit:MakeIllusion()
			table.remove(caster.illusionTable, pos)
		end
	end
end

function CheckAutoCast( keys )
	local target = keys.target
	if target:IsJuggernautIllusion() then
		local owner = target:GetOwner()
		local ability = keys.ability
		local ownerAbility = owner:FindAbilityByName(ability:GetAbilityName())

		if ability:GetAutoCastState() ~= ownerAbility:GetAutoCastState() then
			ability:ToggleAutoCast()
		end
	end
end

function Disperse( keys )
	local caster = keys.caster
	local ability = keys.ability
	local tick = 2.65
	if caster:IsJuggernautIllusion() then return end

	for _,illusion in pairs(caster.illusionTable) do
		illusion.currentTick = 0
		Timers:CreateTimer(0.1, function()
			if not illusion or illusion:IsNull() then return nil end
			illusion.currentTick = illusion.currentTick + 1
			-- 50/50 for running to random point or attacking closest enemy every tick
			local random = RandomInt(1, 100)
			local orderType
			if random < 50 then
				orderType = DOTA_UNIT_ORDER_ATTACK_MOVE
			else
				orderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION
			end
			ExecuteOrderFromTable({UnitIndex = illusion:entindex(), OrderType = orderType, Position = illusion:GetAbsOrigin() + RandomVector(500):Normalized()})
			
			-- weaken illusions until they die
			if illusion:HasModifier("modifier_juggernaut_r_disperse") then
				illusion:SetModifierStackCount("modifier_juggernaut_r_disperse", caster, illusion:GetModifierStackCount("modifier_juggernaut_r_disperse", caster)+1)
			else
				ability:ApplyDataDrivenModifier(caster, illusion, "modifier_juggernaut_r_disperse", {})
				illusion:SetModifierStackCount("modifier_juggernaut_r_disperse", caster, 1)
			end

			-- kill illusions if caster respawns or is no longer broken or if disperse has gone on too long
			if not illusion:IsAlive() or caster:IsAlive() and not caster:PassivesDisabled() or illusion.currentTick > ability:GetSpecialValueFor("illusion_duration") / 2 then
				if illusion:IsAlive() then
					illusion:ForceKill(false)
				end
				return nil
			end
			return tick
		end)
	end
end




--[[
-- order your illusions to 'materialize', making them vulnerable
-- if cast by illusion 
function JuggernautD( keys )
	local caster = keys.caster
	local ability = keys.ability
	caster.illusionTable = caster.illusionTable or {}
	if #caster.illusionTable <= 0 then return end

	if not caster:IsJuggernautIllusion() then
		--caster script
		for pos, illusion in pairs(caster.illusionTable) do
			illusion:RemoveModifierByName("modifier_juggernaut_r_illusion")
			ability:ApplyDataDrivenModifier(caster, illusion, "modifier_juggernaut_r_vulnerable", {})
		end
	else
		--illusion script

	end
end

--order your illusions to disperse
function JuggernautF( keys )
end]]