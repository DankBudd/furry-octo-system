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