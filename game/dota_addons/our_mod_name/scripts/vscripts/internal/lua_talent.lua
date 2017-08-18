function lua_HasTalent( unit, talentname )
  if unit:HasAbility(talentName) then
    if unit:FindAbilityByName(talentName):GetLevel() > 0 then
      return true
    end
  end
  return false
end

function lua_FindTalentValues( unit, talentname )
  if unit:HasAbility(talentName) then
    local values = {}
    local kv = unit:FindAbilityByName(talentName):GetAbilityKeyValues()
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