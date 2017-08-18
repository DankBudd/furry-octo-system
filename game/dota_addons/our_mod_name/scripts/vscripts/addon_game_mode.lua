-- This is the entry-point to your game mode and should be used primarily to precache models/particles/sounds/etc

require('internal/util')
require("gamemode")

--RegisterCustomAnimationScriptForModel( "models/heroes/invoker/invoker.vmdl", "animation/invoker_orbs" )

function Precache( context )
--[[
  This function is used to precache resources/units/items/abilities that will be needed
  for sure in your game and that will not be precached by hero selection.  When a hero
  is selected from the hero selection screen, the game will precache that hero's assets,
  any equipped cosmetics, and perform the data-driven precaching defined in that hero's
  precache{} block, as well as the precache{} block for any equipped abilities.

  See GameMode:PostLoadPrecache() in gamemode.lua for more information
  ]]

  DebugPrint("[BAREBONES] Performing pre-load precache")

  -- Particles can be precached individually or by folder
  -- It it likely that precaching a single particle system will precache all of its children, but this may not be guaranteed
--  PrecacheResource("particle", "particles/econ/generic/generic_aoe_explosion_sphere_1/generic_aoe_explosion_sphere_1.vpcf", context)
--  PrecacheResource("particle_folder", "particles/test_particle", context)

  -- Models can also be precached by folder or individually
  -- PrecacheModel should generally used over PrecacheResource for individual models

--  PrecacheResource("model", "particles/heroes/viper/viper.vmdl", context)
--  PrecacheModel("models/heroes/viper/viper.vmdl", context)
  --PrecacheModel("models/props_gameplay/treasure_chest001.vmdl", context)
  --PrecacheModel("models/props_debris/merchant_debris_chest001.vmdl", context)
  --PrecacheModel("models/props_debris/merchant_debris_chest002.vmdl", context)

  local heroes = {
    "antimage",
    "beastmaster",
    "warlock",
    "pudge",
    "lina",
    "ogre_magi",
    "medusa",
    "sven",
    "monkey_king",
    "morphling",
    "lone_druid",
    "enigma",
    "juggernaut",
    "treant_protector",
    "skeleton_king",
    "furion",
    "enchantress",
    "phoenix",
  }
  for _,heroName in pairs(heroes) do
    PrecacheUnitByNameSync("npc_dota_hero_"..heroName, context)
  end
  PrecacheModel("models/items/beastmaster/boar/fotw_wolf/fotw_wolf.vmdl", context)
  PrecacheModel("models/items/beastmaster/boar/beast_heart_marauder_beast_heart_marauder_warhound/beast_heart_marauder_beast_heart_marauder_warhound.vmdl", context)

  -- Sounds can precached here like anything else
--  PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_gyrocopter.vsndevts", context)

  -- Entire items can be precached by name
  -- Abilities can also be precached in this way despite the name
--  PrecacheItemByNameSync("example_ability", context)

  -- Entire heroes (sound effects/voice/models/particles) can be precached with PrecacheUnitByNameSync
  -- Custom units from npc_units_custom.txt can also have all of their abilities and precache{} blocks precached in this way
end

-- Create the game mode when we activate
function Activate()
  GameRules.GameMode = GameMode()
  GameRules.GameMode:_InitGameMode()
end
