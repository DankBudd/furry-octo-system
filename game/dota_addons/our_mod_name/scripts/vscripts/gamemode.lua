BAREBONES_VERSION = "1.00"
BAREBONES_DEBUG_SPEW = false 

if GameMode == nil then
    DebugPrint( '[BAREBONES] creating barebones game mode' )
    _G.GameMode = class({})
end

--require Barebones stuff
  require('libraries/timers')
  require('libraries/physics')
  require('libraries/projectiles')
  require('libraries/notifications')
  require('libraries/animations')
  require('libraries/attachments')
  require('libraries/playertables')
  require('libraries/containers')
  require('libraries/modmaker')
  require('libraries/pathgraph')
  require('libraries/selection')
  require('internal/gamemode')
  require('internal/events')
  require('settings')
  require('events')

--require misc stuff
  require('libraries/tracking_projectiles')
  require('libraries/popup')
  require('libraries/misc/knockback')
  require('libraries/misc/mana_item_table_functions')
  require('heroes/hero_drow/frost_arrows_lua')
  require('heroes/juggernaut')
  require("items/item_special_combiner_test")
  require("heroes/testing")
  require("items/debug_items")
  require('filters')

--link global modifiers
  LinkLuaModifier("modifier_custom_aura", "heroes/modifiers/modifier_custom_aura", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_no_health_bar", "heroes/modifiers/modifier_no_health_bar", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_info", "heroes/modifiers/modifier_info", LUA_MODIFIER_MOTION_NONE)

--gamemode events
  function GameMode:PostLoadPrecache()
  end

  function GameMode:OnFirstPlayerLoaded()
  end

  function GameMode:OnAllPlayersLoaded()
  end

  function GameMode:OnHeroInGame(hero)
    if hero:GetName() == "npc_dota_hero_meepo" then
      local prime = PlayerResource:GetSelectedHeroEntity(hero:GetPlayerID())
      prime.firstMeepo = prime.firstMeepo or {}
      if prime ~= hero then
        prime.firstMeepo[#prime.firstMeepo+1] = hero
      end
    end


    local enableDebugMode = true
    if not enableDebugMode then return end

    local debugItems = {
      "item_debug_hero_spawn",
      "item_debug_creep_spawn",
      "item_debug_level_up",
      "item_debug_control_all_units",
    }

    Timers:CreateTimer(1.0, function()
      if not hero:IsNull() then
        if hero:GetPlayerID() ~= -1 and not hero:IsJuggernautIllusion() then
          for _,itemName in pairs(debugItems) do
            local newItem = CreateItem(itemName, hero, hero)
            hero:AddItem(newItem)
          end
        end
      end
    end)
  end

  function GameMode:OnGameInProgress()
  end

--init and gamemode functions
  function GameMode:InitGameMode()
    GameMode = self

    --damage and healing
    GameRules:GetGameModeEntity():SetDamageFilter(Dynamic_Wrap(GameMode, "DamageManager"), self)
    GameRules:GetGameModeEntity():SetHealingFilter(Dynamic_Wrap(GameMode, "HealingManager"), self)
    --gold and exp
    GameRules:GetGameModeEntity():SetModifyGoldFilter(Dynamic_Wrap(GameMode, "GoldManager"), self)
    GameRules:GetGameModeEntity():SetModifyExperienceFilter(Dynamic_Wrap(GameMode, "ExperienceManager"), self)
    --runes
    GameRules:GetGameModeEntity():SetRuneSpawnFilter(Dynamic_Wrap(GameMode, "RuneFilter"), self)
    GameRules:GetGameModeEntity():SetBountyRunePickupFilter(Dynamic_Wrap(GameMode, "BountyRuneFilter"), self)
    --other
    GameRules:GetGameModeEntity():SetExecuteOrderFilter(Dynamic_Wrap(GameMode, "OrderManager"), self)
    GameRules:GetGameModeEntity():SetModifierGainedFilter(Dynamic_Wrap(GameMode, "ModifierManager"), self)
    GameRules:GetGameModeEntity():SetTrackingProjectileFilter(Dynamic_Wrap(GameMode, "TrackingProjectileManager"), self)
    GameRules:GetGameModeEntity():SetAbilityTuningValueFilter(Dynamic_Wrap(GameMode, "AbilityTuningManager"), self)
    GameRules:GetGameModeEntity():SetItemAddedToInventoryFilter(Dynamic_Wrap(GameMode, "ItemAddedFilter"), self)
  end

  --filter managers
  function GameMode:HealingManager( filterTable )
    return true
  end

  function GameMode:DamageManager( filterTable )
    return true
  end

  function GameMode:GoldManager( filterTable )
    return true
  end

  function GameMode:ExperienceManager( filterTable )
    return true
  end

  function GameMode:ModifierManager( filterTable )
    Timers:CreateTimer(function() TrackModifier(filterTable) end)

    local parentIndex = filterTable["entindex_parent_const"]
    local casterIndex = filterTable["entindex_caster_const"]
    local abilityIndex = filterTable["entindex_ability_const"]

    --------disable filter----------
    if false then return true end
    --------------------------------

--[[if not parentIndex or not casterIndex or not abilityIndex then
      return true
    end
    local parent = EntIndexToHScript( parentIndex )
    local caster = EntIndexToHScript( casterIndex )
    local ability = EntIndexToHScript( abilityIndex )
    local modifierName = filterTable["name_const"]
    local duration = filterTable["duration"]]]


    if false then
      alteredTable = BashModifierFilter(filterTable)
    end

    if alteredTable then
      return alteredTable
    end
    return true 
  end

  function GameMode:OrderManager( filterTable )
    local issuer = filterTable["issuer_player_id_const"]
    local units = filterTable["units"]
    local orderType = filterTable["order_type"]
    local abilityIndex = filterTable["entindex_ability"]
    local targetIndex = filterTable["entindex_target"]
    local pos = Vector(filterTable["position_x"], filterTable["position_y"], filterTable["position_z"])
    local queue = filterTable["queue"]
    local sequenceNumber = filterTable["sequence_number_const"]

    --  PrintRelevent(filterTable)

    for _,unitIndex in pairs(units) do
      local unit = EntIndexToHScript(unitIndex)
      if unit then
        if unit:GetUnitName() == "npc_dota_hero_juggernaut" and unit:IsRealHero() then
          JuggernautIllusionLogic(filterTable)
        end

    --allows meepo to use custom boots
    --[[if unit:GetUnitName() == "npc_dota_hero_meepo" then
          UpdateMeepoBoots()
        end]]
      end
    end

    if orderType == DOTA_UNIT_ORDER_SELL_ITEM then
      CombinerSellItemListener(filterTable)
    end

    return true
  end

  --static filters
  function GameMode:RuneFilter( filterTable )
    return true
  end

  function GameMode:BountyRuneFilter( filterTable )
    return true
  end



  --orderfilter printer, prints only data relevant to ordertype passed in filterTable
  function PrintRelevent(t)
    local oT = {
      [0] = "DOTA_UNIT_ORDER_NONE",
      [1] = "DOTA_UNIT_ORDER_MOVE_TO_POSITION",
      [2] = "DOTA_UNIT_ORDER_MOVE_TO_TARGET",
      [3] = "DOTA_UNIT_ORDER_ATTACK_MOVE",
      [4] = "DOTA_UNIT_ORDER_ATTACK_TARGET",
      [5] = "DOTA_UNIT_ORDER_CAST_POSITION",
      [6] = "DOTA_UNIT_ORDER_CAST_TARGET",
      [7] = "DOTA_UNIT_ORDER_CAST_TARGET_TREE",
      [8] = "DOTA_UNIT_ORDER_CAST_NO_TARGET", 
      [9] = "DOTA_UNIT_ORDER_CAST_TOGGLE",
     [10] = "DOTA_UNIT_ORDER_HOLD_POSITION",
     [11] = "DOTA_UNIT_ORDER_TRAIN_ABILITY",
     [12] = "DOTA_UNIT_ORDER_DROP_ITEM",
     [13] = "DOTA_UNIT_ORDER_GIVE_ITEM",
     [14] = "DOTA_UNIT_ORDER_PICKUP_ITEM",
     [15] = "DOTA_UNIT_ORDER_PICKUP_RUNE",
     [16] = "DOTA_UNIT_ORDER_PURCHASE_ITEM",
     [17] = "DOTA_UNIT_ORDER_SELL_ITEM",
     [18] = "DOTA_UNIT_ORDER_DISASSEMBLE_ITEM",
     [19] = "DOTA_UNIT_ORDER_MOVE_ITEM",
     [20] = "DOTA_UNIT_ORDER_CAST_TOGGLE_AUTO",
     [21] = "DOTA_UNIT_ORDER_STOP",
     [22] = "DOTA_UNIT_ORDER_TAUNT",
     [23] = "DOTA_UNIT_ORDER_BUYBACK",
     [24] = "DOTA_UNIT_ORDER_GLYPH",
     [25] = "DOTA_UNIT_ORDER_EJECT_ITEM_FROM_STASH",
     [26] = "DOTA_UNIT_ORDER_CAST_RUNE",

     --below are not constants
     [32] = "DOTA_UNIT_ORDER_TOGGLE_LOCK_COMBINING",
     [33] = "DOTA_UNIT_ORDER_INTERRUPT?",
    }
    --print all non-zero values. does print ordertype if it's zero
    local printed = false
    print()
    print("-------------")
    if t["order_type"] then
      for o,n in pairs(oT) do
        if t["order_type"] == o then
          print("order_type: "..n)
          printed = true
        end
      end
    end
    if not printed then
      print("order_type: "..t["order_type"])
    end
    for k,v in pairs(t) do
      if type(v)=="table" then
        PrintTable({["units"]=v})
      end
      if k~="order_type" and type(v) ~= "table" and v ~= 0 then
        print(k..": "..v)
      end
    end
  end

--end of script