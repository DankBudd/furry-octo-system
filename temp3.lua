function EmitAura( infoTable )
  local err = false
  if infoTable == {} or type(infoTable) ~= "table" then
    print("EmitAura | proper table inputs are:")
    PrintTable({caster, auraModifier, ability, duration, origin, radius, unit, team, type, flags,})
    err = true
  end

  local caster = infoTable["caster"]
  local auraModifier = infoTable["auraModifier"]
  if not caster then
    print("EmitAura | error, caster input is not optional")
    err = true
  end
  if not auraModifier then
    print("EmitAura | error, auraModifier input is not optional")
    err = true
  end
  if err then return end

  local ability = infoTable["ability"] or nil
  local duration = infoTable["duration"] or -1
  local origin = infoTable["origin"] or Vector(0,0,0)
  local radius = infoTable["radius"] or 550
  local unit = infoTable["unit"] or CreateDummy(origin, caster:GetTeamNumber(), nil, duration)
  local team = infoTable["team"] or DOTA_UNIT_TARGET_TEAM_BOTH
  local type = infoTable["type"] or DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
  local flags = infoTable["flags"] or DOTA_UNIT_TARGET_FLAG_NONE

  return unit:AddNewModifier(caster, ability, "modifier_custom_aura", {auraModifier = auraModifier, radius = radius, type = type, team = team, flags = flags,})
end

function EmitCustomAura( infoTable )
  local err = false
  if infoTable == {} or type(infoTable) ~= "table" then
    print("EmitCustomAura | proper table inputs are:")
    PrintTable({caster, auraModifier, ability, duration, origin, radius, unit, team, type, flags,})
    err = true
  end

  local caster = infoTable["caster"]
  local auraModifier = infoTable["auraModifier"]
  if not caster then
    print("EmitCustomAura | error, caster input is not optional")
    err = true
  end
  if not auraModifier then
    print("EmitCustomAura | error, auraModifier input is not optional")
    err = true
  end
  if err then return end

  local ability = infoTable["ability"] or nil
  local duration = infoTable["duration"] or -1
  local origin = infoTable["origin"] or Vector(0,0,0)
  local radius = infoTable["radius"] or 550
  local unit = infoTable["unit"] or CreateDummy(origin, caster:GetTeamNumber(), nil, duration)
  local team = infoTable["team"] or DOTA_UNIT_TARGET_TEAM_BOTH
  local type = infoTable["type"] or DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
  local flags = infoTable["flags"] or DOTA_UNIT_TARGET_FLAG_NONE

  --auramodifier what..
  local mod = unit:AddNewModifier(caster, ability, auraModifier, {})
  Timers:CreateTimer(function()
    if not mod or mod:IsNull() then return end
    local found = FindUnitsInRadius(caster:GetTeamNumber(), unit:GetAbsOrigin(), nil, radius, team, type, flags, FIND_ANY_ORDER, false)
    for _,target in pairs(found) do
      local aura = target:AddNewModifier(caster, ability, auraModifier, {})
      local tracking = aura.customExpire
      aura.customExpire = aura.customExpire or 0.53
      if not tracking then
        Timers:CreateTimer(0.1, function()
          if not aura or aura:IsNull() then return end
          aura.customExpire = aura.customExpire - 0.1
          ListenToGameEvent("modifier_refresh", function(kv)
            if kv.modifierName ~= auraModifier then return end
            local parent = EntIndexToHScript(kv.parentIndex)
            if parent == aura:GetParent() then
              aura.customExpire = 0.53
            end
          end, nil)
          if aura.customExpire < 0.1 then
            if aura.customExpire < 0.03 then
              aura:Destroy()
              return
            end
            return 0.03
          end
          return 0.1
        end)
      end
    end
    if mod:GetElapsedTime() >= mod:GetDuration() then
      mod:Destroy()
      return
    end
    return 0.5
  end)
  return mod
end


   --[[crazy hack idea to merge modifier functions
   grab modifier function via: mod.functionName
   take additional parameters wanted in said function,
  
        mod.functionName = function(self)
          grabbedFunction(self)
          
          newFunc()
        end

    might need to wrap the whole thing up with class({})
  ]]

--this wont really work as a function i can call, needs to be hardcoded for each instance
-- if it even works at all
--
--could potentially make a table with preset function layouts and pass the newFunc into those instead,
--and then set the preset holding newFunc as the modifierFunc
function MergeModifierFunction(modifier, func, newFunc)

  local ref = modifier.OnCreated 
  modifier.OnCreated = function(self, kv)
    ref(self, kv)
    newFunc(self, kv)
  end
--[[
  modifier.OnCreated = class({
    function(self, kv)
      ref(self, kv)
      newFunc(self, kv)
    end,
  })
]]
end
