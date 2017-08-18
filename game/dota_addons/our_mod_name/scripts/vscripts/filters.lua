function BashDamageFilter( filterTable )
  local attackerIndex = filterTable.entindex_attacker_const
  local victimIndex = filterTable.entindex_victim_const
  local inflictorIndex = filterTable.entindex_inflictor_const
  --------disable filter----------
  if true then return filterTable end
  --------------------------------
  if not attackerIndex or not victimIndex or not inflictorIndex then
    return filterTable
  end
  local attacker = EntIndexToHScript(attackerIndex)
  local victim = EntIndexToHScript(victimIndex)
  local inflictor = EntIndexToHScript(inflictorIndex)
  local damage = filterTable.damage
  local damagetype = filterTable.damagetype_const
  if inflictor and attacker then
    if inflictor:IsPassive() --[[and inflictor:HasAbilityFlag("bash")]] then
      if not inflictor:IsCooldownReady() then
        return false
      end
    end
  end
  return filterTable
end

function BashModifierFilter( filterTable )
  local parentIndex = filterTable["entindex_parent_const"]
  local casterIndex = filterTable["entindex_caster_const"]
  local abilityIndex = filterTable["entindex_ability_const"]
  --------disable filter----------
  if true then return filterTable end
  --------------------------------
  if not parentIndex or not casterIndex or not abilityIndex then
    return filterTable
  end
  local parent = EntIndexToHScript( parentIndex )
  local caster = EntIndexToHScript( casterIndex )
  local ability = EntIndexToHScript( abilityIndex )
  local modifierName = filterTable["name_const"]
  local modifier = parent:FindModifierByNameAndCaster(modifierName, caster)
  local duration = filterTable["duration"]
  local multiplier = 1.5
  
  local sounds = {
    --dota
    roshan_bash = "Roshan.Bash",
    slardar_bash = "Hero_Slardar.Bash",
    faceless_void_time_lock = "Hero_FacelessVoid.TimeLockImpact",
    troll_warlord_berserkers_rage = "Hero_TrollWarlord.BerserkersRage.Stun",
    troll_warlord_berserkers_rage_active = "Hero_TrollWarlord.BerserkersRage.Stun",
    spirit_breaker_greater_bash = (parent:IsHero() and "Hero_Spirit_Breaker.GreaterBash") or "Hero_Spirit_Breaker.GreaterBash.Creep",
    --custom
    spell_lab_survivor_bash = "DOTA_Item.SkullBasher",
    android_pocket_factory_spawn_goblin1 = "Roshan.Bash",
    android_pocket_factory_spawn_goblin2 = "Roshan.Bash",
    android_pocket_factory_spawn_goblin3 = "Roshan.Bash",
    imba_tower_permabash = "Hero_FacelessVoid.TimeLockImpact",
    imba_tower_spacecow = (parent:IsHero() and "Hero_Spirit_Breaker.GreaterBash") or "Hero_Spirit_Breaker.GreaterBash.Creep",

    testing_bash = "DOTA_Item.SkullBasher",
  }
  --ability:HasAbilityFlag("bash")
  if modifier:IsStunDebuff() and ability:IsPassive() and not ability:IsItem() then
    if ability:IsCooldownReady() then
      ability:StartCooldown(duration * multiplier)
      return filterTable
    else
      --attempt to remove bash sound on every frame for 6 frames
      if sounds[ability:GetName()] then
        for i=0.01,0.06 do
          Timers:CreateTimer(i, function()
            StopSoundOn(sounds[ability:GetName()], parent)
          end)
        end
      end
      return false
    end
  end
  --return true by default
  return filterTable
end

function TrackModifier( filterTable )
  local parentIndex = filterTable["entindex_parent_const"]
  local casterIndex = filterTable["entindex_caster_const"]
  local abilityIndex = filterTable["entindex_ability_const"]
  if not parentIndex or not casterIndex or not abilityIndex then
    return
  end
  local parent = EntIndexToHScript( parentIndex )
  local caster = EntIndexToHScript( casterIndex )
  local modifierName = filterTable["name_const"]
  local duration = filterTable["duration"]

  Timers:CreateTimer(0.1, function()
  local modifier = parent:FindModifierByNameAndCaster(modifierName, caster)
  if not modifier or modifier:IsNull() then return end
    local remaining = modifier:GetRemainingTime()
    local elapsed = modifier:GetElapsedTime()

    modifier.prevElapsed = modifier.prevElapsed or elapsed
    if modifier.prevElapsed > elapsed then
      if duration ~= -1 then
        FireGameEvent("modifier_refresh", {modifierName = modifierName, parentIndex = parentIndex, casterIndex = casterIndex, abilityIndex = abilityIndex})
      end
    end

    if elapsed >= duration then
      return
    end
    return 0.1
  end)
end