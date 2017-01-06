function CreateMirror( keys )
	local caster = keys.caster
	local targetPoint = keys.target_points[1]
	local ability = keys.ability
	local maxMirrors = ability:GetSpecialValueFor("max_mirrors")

	-- initialize the tracking data
	caster.mirrorUnitCount = caster.mirrorUnitCount or 0
	caster.mirrorTable = caster.mirrorTable or {}

	-- create mirror unit
	local mirror = CreateUnitByName("mirror_hall_mirror", targetPoint, true, caster, caster, caster:GetTeamNumber())
	mirror:SetControllableByPlayer(caster:GetPlayerID(), true)
	mirror:SetOwner(caster)

	-- find and level the mirror ability
	local mirrorAbility = mirror:FindAbilityByName("mirror_pulse")
	mirrorAbility:SetLevel(ability:GetLevel())

	-- track the unit
	caster.mirrorUnitCount = caster.mirrorUnitCount + 1
	table.insert(caster.mirrorTable, mirror)

	if caster.mirrorUnitCount > maxMirrors then
		caster.mirrorTable[1]:RemoveSelf()
		table.remove(caster.mirrorTable, 1)
		caster.mirrorUnitCount = caster.mirrorUnitCount - 1
	end
end

function RemoveMirror( keys )
	local ability = keys.ability
	local mirror = keys.caster
	local caster = mirror:GetOwner()

	for k,v in pairs(caster.mirrorTable) do
		if caster.mirrorTable[v] == mirror then
			table.remove(caster.mirrorTable, v)
			caster.mirrorUnitCount = caster.mirrorUnitCount - 1
		end
	end
end

function RecordLastHit( keys )
	keys.ability.last_hitter = keys.attacker
end

function DeathDamage( keys )
	local mirror = keys.caster
	local caster = mirror:GetOwner()
	local ability = keys.ability
	local target = ability.last_hitter
	local healthPct = ability:GetSpecialValueFor("health_pct") * 0.01
	local modifier = keys.modifier

	if target:IsBuilding() or target:IsAncient() or target:GetTeam() == caster:GetTeam() then return end
	if caster:HasScepter() then
		healthPct = ability:GetSpecialValueFor("scepter_health_pct")
		ability:ApplyDataDrivenModifier(caster, target, modifier, {})
	end

	local damage = target:GetMaxHealth() * healthPct
	ApplyDamage({attacker =	caster, victim = target, ability = ability, damage = damage, damage_type = DAMAGE_TYPE_PURE, damage_flags = DOTA_DAMAGE_FLAG_HPLOSS})
end


function MirrorPulse( keys )
	local mirror = keys.caster
	local caster = mirror:GetPlayerOwner()
	local target = keys.target
	local ability = keys.ability
	local outgoing = ability:GetSpecialValueFor("illusion_outgoing")
	local incoming = ability:GetSpecialValueFor("illusion_incoming")
	local duration = ability:GetSpecialValueFor("illusion_duration")
	local cooldown = ability:GetSpecialValueFor("pulse_interval")

	-- Aesthetic cooldown to help people keep track of the pulses, does not actually effect the ability
	ability:StartCooldown(cooldown)

	-- Create illusion of target and set it to be owned by the caster
	local illusion = CreateUnitByName(target:GetUnitName(), target:GetAbsOrigin() + RandomVector(100), true, caster, caster, caster:GetTeamNumber())
	illusion:SetControllableByPlayer(caster:GetPlayerID(), true)

	-- Level Up the unit to the targets level
	local targetLevel = target:GetLevel()
	for i=1, targetLevel-1 do
		illusion:HeroLevelUp(false)
	end

	-- Set the skill points to 0 and learn the skills of the target
	illusion:SetAbilityPoints(0)
	for abilitySlot = 0,15 do
		local targetAbility = target:GetAbilityByIndex(abilitySlot)
		if targetAbility ~= nil then 
			local abilityLevel = targetAbility:GetLevel()
			local abilityName = targetAbility:GetAbilityName()
			local illusionAbility = illusion:FindAbilityByName(abilityName)
			illusionAbility:SetLevel(abilityLevel)
		end
	end

	-- Recreate the items of the target
	for itemSlot=0,5 do
		local item = target:GetItemInSlot(itemSlot)
		if item ~= nil then
			local itemName = item:GetName()
			local newItem = CreateItem(itemName, illusion, illusion)
			illusion:AddItem(newItem)
		end
	end

	-- Set the unit as an illusion
	-- modifier_illusion controls many illusion properties like +Green damage not adding to the unit damage, not being able to cast spells and the team-only blue particle
	illusion:AddNewModifier(mirror:GetOwner(), mirror:GetOwner():FindAbilityByName("mirror_hall"), "modifier_illusion", {duration = duration, outgoing_damage = outgoing, incoming_damage = incoming})
	-- Without MakeIllusion the unit counts as a hero, e.g. if it dies to neutrals it says killed by neutrals, it respawns, etc.
	illusion:MakeIllusion()
	-- Set the illusion hp to be the same as the target
	illusion:SetHealth(target:GetHealth())

	-- give the attack order if the caster is alive
	-- otherwise forces the target to sit and do nothing
	if target:IsAlive() then
		local order = {
				UnitIndex = illusion:entindex(),
				OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
				TargetIndex = target:entindex()
		}

		ExecuteOrderFromTable(order)
	else
		illusion:Stop()
	end
end