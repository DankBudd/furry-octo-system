function CDOTA_BaseNPC:GetBackwardVector()
  return (self:GetAbsOrigin() - (self:GetAbsOrigin() + self:GetForwardVector() * 2)):Normalized()
end

function CDOTA_BaseNPC:GetLeftVector()
  return (self:GetAbsOrigin() - (self:GetAbsOrigin() + self:GetRightVector() * 2)):Normalized()
end

function CDOTA_BaseNPC:GetDownVector()
  return (self:GetAbsOrigin() - (self:GetAbsOrigin() + self:GetUpVector() * 2)):Normalized()
end

function CDOTA_BaseNPC:IsJuggernautIllusion()
  if self:HasModifier("modifier_juggernaut_r_illusion") or self:HasModifier("modifier_juggernaut_r_vulnerable") then
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

--------------------------------------------------------------------------------------------
-- Talent Stuff
--------------------------------------------------------------------------------------------
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
          for key,value in pairs(tab) do
            if key ~= "var_type" then
              values[tonumber(num)] = value
              values[key] = value
            end
          end
        end
      end
    end
    return values
  end
  return nil
end
------------------------------------------------------------------
-- Debug
------------------------------------------------------------------
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