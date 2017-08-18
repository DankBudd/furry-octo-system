--[[--WARNING: can return a variety of things
function CDotaBaseAbility:GetKeyValue( string )
  local kv = self:GetAbilityKeyValues()
  --search for key
  for k,v in pairs(kv) do
    if k == string then
      return v
    end
  end
  --check ability special if string not found
  for k,v in pairs(kv) do
    if k == "AbilitySpecial" then
      for l,m in pairs(v) do
        if l == string then
          return v
        end
        for key,val in pairs(m) do
          if key == string then
            return val
          end
        end
      end
    end
  end
  print("GetKeyValue | Error: string not found")
end]]

function EmitAura( infoTable )
  if infoTable == {} or type(infoTable) ~= "table" then
    print("EmitAura | proper table inputs are:")
    PrintTable({caster, auraModifier, ability, duration, origin, radius, unit, team, type, flags,})
    return
  end

  local caster = infoTable["caster"]
  local auraModifier = infoTable["auraModifier"]
  if not caster then
    print("EmitAura | error, caster input is not optional") return
  end
  if not auraModifier then
    print("EmitAura | error, auraModifier input is not optional") return
  end

  local ability = infoTable["ability"] or nil
  local duration = infoTable["duration"] or -1
  local origin = infoTable["origin"] or Vector(0,0,0)
  local radius = infoTable["radius"] or 550
  local unit = infoTable["unit"] or CreateDummy(origin, caster:GetTeamNumber(), nil, duration)
  local team = infoTable["team"] or DOTA_UNIT_TARGET_TEAM_BOTH
  local type = infoTable["type"] or DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
  local flags = infoTable["flags"] or DOTA_UNIT_TARGET_FLAG_NONE

  unit:AddNewModifier(caster, ability, "modifier_custom_aura", {auraModifier = auraModifier, radius = radius, type = type, team = team, flags = flags,})
end

--does not account for reductions such as stout shield or dispersion
function CDOTA_BaseNPC:Lifesteal( target, damage, pct, optReduction )
  if not target or not damage or not pct then print("Lifesteal | incorrect inputs") return end

  local reduction = 1
  if not optReduction then
    local armor = target:GetPhysicalArmorValue()
    reduction = (0.06 * armor) / (1 + 0.06 * armor)
  end
  local lifesteal = (damage - damage * reduction) * pct * 0.01

  self:Heal(lifesteal, self)
  ParticleManager:ReleaseParticleIndex(ParticleManager:CreateParticle("particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_OVERHEAD_FOLLOW, self))
end

function RandomBool()
  return (true and RandomInt(1,2) == 1) or false
end

function CDOTA_Item:IsConsumable()
  local kv = LoadKeyValues("scripts/npc/kv/shops.kv")
  if kv then
    for k,v in pairs(kv) do
      if k == "consumables" then
        if v then
          for name,_ in pairs(v) do
            if self:GetName() == name then
              return true
            end
          end
        end
      end
    end
  end
  return false
end

function CDOTA_BaseNPC:GetItems()
  local items = {}
  for i=0,DOTA_ITEM_MAX-1 do
    local item = self:GetItemInSlot(i)
    if item then
      items[i+1] = item
    end
  end
  return items
end

function CreateDummy( pos, team, func, duration )
  if pos and team then
    local dummy = CreateUnitByNameAsync("npc_dummy_unit", pos, false, nil, nil, team, func or function(unit) end)

    if duration and not duration == -1 then
      dummy:AddNewModifier(nil, nil, "modifier_kill", {duration = duration})
    end
    return dummy
  end
  print("CreateDummy | requires vector, team, optional function, and optional duration inputs")
end

function DisplayError( pid, message )
  if pid then
    if type(pid) == "userdata" then
      pid = pid:GetPlayerID()
    end
    local player = PlayerResource:GetPlayer(pid)
    if player then
      CustomGameEventManager:Send_ServerToPlayer(player, "dotaHudErrorMessage", {message=(message or "error")})
      return
    end
  end
  print("DisplayError | requires (player or playerID) and optional string inputs")
end

function CDOTA_BaseNPC:RemoveAbilityAndModifiers( abilityName )
  if self and abilityName then
    if type(abilityName) == "string" then
      local ability = self:FindAbilityByName(abilityName)
      if ability then
        local mods = self:FindAllModifiers()
        for _,mod in pairs(mods) do
          if mod then
            if mod:GetAbility() == ability then
              self:RemoveModifierByNameAndCaster(mod:GetName(), mod:GetCaster())
            end
          end
        end
        self:RemoveAbility(abilityName)
      end
      return
    end
  end
  print("RemoveAbilityAndModifiers | requires hero_entity class and ability name input")
end

function CDOTA_BaseNPC:ClearModifiers( bClearIntrinsicMods )
  local mods = self:FindAllModifiers()
  local shouldRemove = false
  for _,mod in pairs(mods) do
    if mod then
      if not string.find(mod:GetName(), "special_bonus") then
        local intrinsic = mod:GetAbility():GetIntrinsicModifierName()
        if not intrinsic then
          shouldRemove = true
        else
          if not bClearIntrinsicMods or mod:GetName() ~= intrinsic then
            shouldRemove = true
          elseif bClearIntrinsicMods and mod:GetName() == intrinsic then
            shouldRemove = true
          else
            shouldRemove = false
          end
        end
        if shouldRemove then
          self:RemoveModifierByNameAndCaster(mod:GetName(), mod:GetCaster())
        end
      end
    end
  end
end

function CDOTA_BaseNPC:ReplaceAbility( oldName, newName )
  if self and oldName and newName then
    if type(oldName) == "string" and type(newName) == "string" then
      local oldAb = self:FindAbilityByName(oldName)
      if oldAb then
        local index = oldAb:GetAbilityIndex()
        local level = oldAb:GetLevel()
        if level > 0 then
          self:SetAbilityPoints(self:GetAbilityPoints()+level)
        end
        self:RemoveAbilityAndModifiers(oldName)
        local newAb = self:AddAbility(newName)
        if newAb then
          newAb:SetAbilityIndex(index)
          return newAb
        end
        print("ReplaceAbility | "..newName.." is not a valid ability name")
        return
      end
      print("ReplaceAbility | "..oldName.." is not a valid ability name")
      return
    end
  end
  print("ReplaceAbility | requires hero_entity class and two ability name inputs")
end

--should probably change this to a dummy unit w/ a vision modifier
function AttachFOWViewer( nTeamID, hUnit, flRadius, flDuration, bObstructedVision )
  local time = 0
  Timers:CreateTimer(0.03, function()
    if hUnit:IsNull() then return end
    AddFOWViewer(nTeamID, hUnit:GetAbsOrigin(), flRadius, 0.03, bObstructedVision)
    time = time + 0.03
    if time < flDuration then
      return 0.03
    end
    return nil
  end)
end

function BoolToString(b)
  if b == true or b == 1 then return "true" end
  if b == false or b == 0 then return "false" end
end

function TableCount(t)
  local count = 0
  if type(t) == "table" then
    for k,v in pairs(t) do
      count = count+1
    end
  end
  return count
end

function CDOTA_BaseNPC:GetSlot(item)
  if item then
    if item:IsItem() then
      for i = 0,DOTA_ITEM_MAX-1 do
        local itemInSlot = self:GetItemInSlot(i)
        if item == itemInSlot then
          return i
        end
      end
      return nil
    end
  end
end

--from SWAT:REBORN
function FindItemsInRadius( point, radius )
  local found = {}
  for _,item in pairs(Entities:FindAllInSphere(point, radius)) do
    if item.GetContainedItem then
      table.insert(found, item)
    end       
  end
  return found
end

function DoAnyUnitsHaveModifier( modifier, unitTable )
  for _,unit in pairs(unitTable) do
    if unit:HasModifier(modifier) then
      return true
    end
  end
  return false
end

function FindCentralUnit( unitTable )
  local positions = {}
  local lengths = {}
  local lowest = {}
  if #unitTable == 1 then return unitTable[1] end
  if #unitTable < 2 then return end
  -- gather positions of units
  for pos, unit in pairs(unitTable) do
    positions[pos] = unit:GetAbsOrigin()
  end
  -- determine distances between each unit
  for pos, unit in pairs(unitTable) do
    local i = 1
    while i <= #unitTable do
      if not lengths[pos] then lengths[pos] = 0 end
      lengths[pos] = lengths[pos] + (positions[pos] - positions[i]):Length2D()
      i=i+1
    end
  end
  -- compare distances and find central unit
  for pos, lengthTotal in pairs(lengths) do
    if not lowest[1] then
      lowest[1] = lengthTotal
      lowest[2] = pos
    elseif lengthTotal < lowest[1] then
      lowest[1] = lengthTotal
      lowest[2] = pos
    end
  end
  -- return central unit
  return unitTable[lowest[2]]
end

function CDOTA_BaseNPC:GetBackwardVector()
  return (self:GetAbsOrigin() - (self:GetAbsOrigin() + self:GetForwardVector()*2)):Normalized()
end

function CDOTA_BaseNPC:GetLeftVector()
  return (self:GetAbsOrigin() - (self:GetAbsOrigin() + self:GetRightVector()*2)):Normalized()
end

function CDOTA_BaseNPC:GetDownVector()
  return (self:GetAbsOrigin() - (self:GetAbsOrigin() + self:GetUpVector()*2)):Normalized()
end

function CDOTA_BaseNPC:IsJuggernautIllusion()
  if self:HasModifier("modifier_juggernaut_r_illusion") or self:HasModifier("modifier_juggernaut_d_vulnerable") then
    return true
  end
  return false
end

function CDOTA_BaseNPC:HandleUnitHealth( desiredHealth )
  local relativeHealth = self:GetHealthPercent() * 0.01
  self:SetMaxHealth(desiredHealth)
  self:SetBaseMaxHealth(desiredHealth)
  self:SetHealth(desiredHealth * relativeHealth)
end

--currently unused
function CDOTA_BaseNPC:HasSpecialScepter()
  local scepters = {
      ["npc_dota_hero_pudge"] = "special_scepter_name",
      ["npc_dota_hero_enigma"] = "special_scepter_name",
  }
  for hero, item in pairs(scepters) do
    if self:GetUnitName() == hero then
      if self:HasItemInInventory(item) then
        return true
      end
    end
  end
  return false
end

--[[Author: Noya
  Date: 09.08.2015.
  Hides all dem hats
]]
function HideWearables(unit)
  unit.hiddenWearables = {} -- Keep every wearable handle in a table to show them later
  local model = unit:FirstMoveChild()
  while model ~= nil do
    if model:GetClassname() == "dota_item_wearable" then
      model:AddEffects(EF_NODRAW) -- Set model hidden
      table.insert(unit.hiddenWearables, model)
    end
    model = model:NextMovePeer()
  end
end

function ShowWearables(unit)
  for i,v in pairs(unit.hiddenWearables) do
    v:RemoveEffects(EF_NODRAW)
  end
end

------------------------------------------------------------------------------------------
--borrowed from IMBA for reference when i actually need similar functions
------------------------------------------------------------------------------------------
-- Returns an unit's existing increased cast range modifiers
function GetCastRangeIncrease(unit)
  local cast_range_increase = 0
  
  -- From items
  if unit:HasModifier("modifier_item_imba_elder_staff_range") then
    cast_range_increase = cast_range_increase + 300
  elseif unit:HasModifier("modifier_item_imba_aether_lens_range") then
    cast_range_increase = cast_range_increase + 225
  end

  -- From talents
  for talent_name,cast_range_bonus in pairs(CAST_RANGE_TALENTS) do
    if unit:FindAbilityByName(talent_name) and unit:FindAbilityByName(talent_name):GetLevel() > 0 then
      cast_range_increase = cast_range_increase + cast_range_bonus
    end
  end

  return cast_range_increase
end

-- Returns the total cooldown reduction on a given unit
function GetCooldownReduction(unit)
  local reduction = 1.0

  -- Octarine Core
  if unit:HasModifier("modifier_item_imba_octarine_core_unique") then
    reduction = reduction * 0.75
  end

  return reduction
end
--------------
-- IMBA END --
--------------

------------------
-- Talent Stuff --
------------------
function CDOTA_BaseNPC:HasTalent( talentName )
  if self:HasAbility(talentName) then
    if self:FindAbilityByName(talentName):GetLevel() > 0 then
      return true
    end
  end
  return false
end

function CDOTA_BaseNPC:FindTalentValues( talentName )
  if self:HasAbility(talentName) then
    local values = {}
    local kv = self:FindAbilityByName(talentName):GetAbilityKeyValues()
    for k,v in pairs(kv) do
      if k == "AbilitySpecial" then
        for num,tab in pairs(v) do
          for key,val in pairs(tab) do
            if key ~= "var_type" then
              values[tonumber(num)] = val
              values[key] = val
            end
          end
        end
      end
    end
    return values
  end
  return nil
end

-----------
-- Debug --
-----------
function DebugPrint(...)
  local spew = Convars:GetInt('barebones_spew') or -1
  if spew == -1 and BAREBONES_DEBUG_SPEW then
    spew = 1
  end

  if spew == 1 then
    print(...)
  end
end

function DebugPrintTable(...)
  local spew = Convars:GetInt('barebones_spew') or -1
  if spew == -1 and BAREBONES_DEBUG_SPEW then
    spew = 1
  end

  if spew == 1 then
    PrintTable(...)
  end
end

function PrintTable(t, indent, done)
  --print ( string.format ('PrintTable type %s', type(keys)) )
  if type(t) ~= "table" then return end

  done = done or {}
  done[t] = true
  indent = indent or 0

  local l = {}
  for k, v in pairs(t) do
    table.insert(l, k)
  end

  table.sort(l)
  for k, v in ipairs(l) do
    -- Ignore FDesc
    if v ~= 'FDesc' then
      local value = t[v]

      if type(value) == "table" and not done[value] then
        done [value] = true
        print(string.rep ("\t", indent)..tostring(v)..":")
        PrintTable (value, indent + 2, done)
      elseif type(value) == "userdata" and not done[value] then
        done [value] = true
        print(string.rep ("\t", indent)..tostring(v)..": "..tostring(value))
        PrintTable ((getmetatable(value) and getmetatable(value).__index) or getmetatable(value), indent + 2, done)
      else
        if t.FDesc and t.FDesc[v] then
          print(string.rep ("\t", indent)..tostring(t.FDesc[v]))
        else
          print(string.rep ("\t", indent)..tostring(v)..": "..tostring(value))
        end
      end
    end
  end
end

-- Colors
COLOR_NONE = '\x06'
COLOR_GRAY = '\x06'
COLOR_GREY = '\x06'
COLOR_GREEN = '\x0C'
COLOR_DPURPLE = '\x0D'
COLOR_SPINK = '\x0E'
COLOR_DYELLOW = '\x10'
COLOR_PINK = '\x11'
COLOR_RED = '\x12'
COLOR_LGREEN = '\x15'
COLOR_BLUE = '\x16'
COLOR_DGREEN = '\x18'
COLOR_SBLUE = '\x19'
COLOR_PURPLE = '\x1A'
COLOR_ORANGE = '\x1B'
COLOR_LRED = '\x1C'
COLOR_GOLD = '\x1D'

function DebugAllCalls()
    if not GameRules.DebugCalls then
        print("Starting DebugCalls")
        GameRules.DebugCalls = true

        debug.sethook(function(...)
            local info = debug.getinfo(2)
            local src = tostring(info.short_src)
            local name = tostring(info.name)
            if name ~= "__index" then
                print("Call: ".. src .. " -- " .. name .. " -- " .. info.currentline)
            end
        end, "c")
    else
        print("Stopped DebugCalls")
        GameRules.DebugCalls = false
        debug.sethook(nil, "c")
    end
end