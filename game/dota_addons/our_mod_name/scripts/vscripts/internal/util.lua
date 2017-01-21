
-- we can use these imba functions to implement our own cast range / cd reduction stuff, but we'd have to use it in each ability.
-- Returns an unit's existing increased cast range modifiers
function GetCastRangeIncrease( unit )
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
function GetCooldownReduction( unit )

  local reduction = 1.0

  -- Octarine Core
  if unit:HasModifier("modifier_item_imba_octarine_core_unique") then
    reduction = reduction * 0.75
  end

  return reduction
end
--------------------------------------------------------------------------------------------

-- Talent Stuff
function CDOTA_BaseNPC:HasTalent(talentName)
    if self:HasAbility(talentName) then
        if self:FindAbilityByName(talentName):GetLevel() > 0 then return true end
    end
    return false
end

-- this can be improved significantly with a file that contains every talent and their values in it
function CDOTA_BaseNPC:FindTalentValue(talentName)
    if self:HasAbility(talentName) then
      local talent = self:FindAbilityByName(talentName)
      values = {}
      table.insert(values, talent:GetSpecialValueFor("value"))
      if talent:GetSpecialValueFor("value1") ~= nil then
        table.insert(values, talent:GetSpecialValueFor("value1"))
      end
      if talent:GetSpecialValueFor("value2") ~= nil then
        table.insert(values, talent:GetSpecialValueFor("value2"))
      end
      if talent:GetSpecialValueFor("value3") ~= nil then
        table.insert(values, talent:GetSpecialValueFor("value3"))
      end
      if talent:GetSpecialValueFor("value4") ~= nil then
        table.insert(values, talent:GetSpecialValueFor("value4"))
      end
      if talent:GetSpecialValueFor("value5") ~= nil then
        table.insert(values, talent:GetSpecialValueFor("value5"))
      end
      if talent:GetSpecialValueFor("value6") ~= nil then
        table.insert(values, talent:GetSpecialValueFor("value6"))
      end
        return values
    end
    return nil
end

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




--[[Author: Noya
  Date: 09.08.2015.
  Hides all dem hats
]]
function HideWearables( unit )
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

function ShowWearables( unit )

  for i,v in pairs(unit.hiddenWearables) do
    v:RemoveEffects(EF_NODRAW)
  end
end