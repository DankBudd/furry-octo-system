--[[////////////////////
/// Reflecting Pool ///
//////////////////////]]

function CreatePool( keys )
    local caster = keys.caster
    local ability = keys.ability
    local modifier = keys.modifier
    local modifierB = keys.modifierb
    local particleName = keys.particle
    
    -- dummy info
    local abilityDuration = ability:GetSpecialValueFor("duration") -- 7 seconds
    local width = ability:GetSpecialValueFor("width")    
    local casterPoint = caster:GetAbsOrigin()
    local directionToTargetPoint = caster:GetForwardVector()
    local moveFurther = directionToTargetPoint * 150
    local targetPoint = casterPoint + moveFurther
    local targetPointB = targetPoint + moveFurther
    local targetPointC = targetPointB + moveFurther

    local particleA = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN, caster)
    local particleB = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN, caster)
    local particleC = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN, caster)

    -- create dummys
    local dummyA = CreateUnitByName("npc_dummy_unit", targetPoint, false, nil, nil, caster:GetTeamNumber())
    local dummyB = CreateUnitByName("npc_dummy_unit", targetPointB, false, nil, nil, caster:GetTeamNumber())
    local dummyC = CreateUnitByName("npc_dummy_unit", targetPointC, false, nil, nil, caster:GetTeamNumber())
       
    -- apply aura & dummy states
    ability:ApplyDataDrivenModifier(caster, dummyA, modifier, {})
    ability:ApplyDataDrivenModifier(caster, dummyA, modifierB, {})
    ability:ApplyDataDrivenModifier(caster, dummyA, "modifier_reflection_states", {})
    ability:ApplyDataDrivenModifier(caster, dummyB, modifier, {})
    ability:ApplyDataDrivenModifier(caster, dummyB, modifierB, {})
    ability:ApplyDataDrivenModifier(caster, dummyB, "modifier_reflection_states", {})
    ability:ApplyDataDrivenModifier(caster, dummyC, modifier, {})
    ability:ApplyDataDrivenModifier(caster, dummyC, modifierB, {})
    ability:ApplyDataDrivenModifier(caster, dummyC, "modifier_reflection_states", {})

    -- attach particles
    ParticleManager:SetParticleControl(particleA, 0, targetPoint)
    ParticleManager:SetParticleControl(particleB, 0, targetPointB)
    ParticleManager:SetParticleControl(particleC, 0, targetPointC)

    -- emit sounds A, B and C at the appropriate times
    EmitSoundOn("Hero_Kunkka.Attack.Rip", dummyA)

    Timers:CreateTimer({ endTime = 0.15, callback = function()
        EmitSoundOn("Hero_Morphling.ReplicateEnd", dummyB)
    end})

    Timers:CreateTimer({ endTime = 0.3, callback = function()
        EmitSoundOn("Hero_Morphling.Waveform", dummyC)
    end})

    -- delete dummys after delay (7 seconds)
    Timers:CreateTimer({ endTime = abilityDuration, callback = function()
        dummyA:ForceKill(false)
        dummyB:ForceKill(false)
        dummyC:ForceKill(false)
        ParticleManager:DestroyParticle(particleA, false)
        ParticleManager:DestroyParticle(particleB, false)
        ParticleManager:DestroyParticle(particleC, false)
    end})
 end

function ReflectDamage( event )
    local caster = event.caster
    local ability = event.ability
    local attacker = event.attacker
    local damage = event.attack_damage
    local reflect = ability:GetSpecialValueFor("reflect") * 0.01

    if not attacker:IsBuilding() then
        ApplyDamage({attacker = caster, victim = attacker, ability = ability, damage = damage*reflect, damage_type = DAMAGE_TYPE_PURE})
    end
end

--[[///////////
/// Vanity ///
/////////////]]

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
--  print("Angle: " .. angle)


    -- facing check
    if angle <= visionCone/2 then
        -- check if unit is already in table (if it is, we will not increment stack count)
        for k,v in pairs(ability.facingTable) do
            if v == target then
                check = true
--              print("Unit is already in table! ::Check1::")
                target.justAdded = false
            end
        end

        -- add unit to "facing" table, if its not already in it
        if not check then
            table.insert(ability.facingTable, target)
--          print("Unit added to table!")
            target.justAdded = true
        end

        -- increment stackCount if this unit was JUST added to facing table
        if target.justAdded then
--          print("Incrementing stackCount")
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
--              print("Unit is in table! ::Check2::")
            end
        end

        -- remove unit from "facing" table, if its in it
        if check then
            for i = 1, #ability.facingTable do
                if ability.facingTable[i] == target then
                    table.remove(ability.facingTable, i)
--                  print("Unit removed from table!")
                    target.justRemoved = true
                end
            end
        end 

        -- decrement stackCount if unit was JUST removed from table     
        if target.justRemoved and stackCount > 1 then
--          print("Decrementing stackCount")
            caster:SetModifierStackCount(modifier, caster, stackCount - 1)
            target.justRemoved = false
        elseif stackCount <= 1 and #ability.facingTable <= 0 then
            caster:RemoveModifierByNameAndCaster(modifier, caster)
        end
    end
end

--[[////////////////////
/// Enchanting Leer ///
//////////////////////]]

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

--[[////////////////
/// Mirror Hall ///
//////////////////]]

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
    ApplyDamage({attacker = caster, victim = target, ability = ability, damage = damage, damage_type = DAMAGE_TYPE_PURE, damage_flags = DOTA_DAMAGE_FLAG_HPLOSS})
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