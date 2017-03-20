local heroes = {
	"lina",
	"pudge",
	"sven",
	"ogre_magi",
	"medusa",
	"monkey_king",
	"morphling",
	"furion",
	"juggernaut",
	"enchantress",
	"skeleton_king"
}

local creeps = {
	"creep_badguys_ranged",
	"creep_goodguys_ranged",
	"creep_badguys_melee",
	"creep_goodguys_melee",
	"neutral_kobold",
	"necronomicon_warrior_2",
	"necronomicon_archer_2",
	"dark_troll_warlord_skeleton_warrior",
	"roshan",
	"lycan_wolf2",
	"lone_druid_bear2",
	"lone_druid_bear3"
}

function SpawnHeroes( keys )
	local team
	if keys.target then
		if keys.target:GetTeam() == keys.caster:GetTeam() then
			team = keys.caster:GetTeamNumber()
		else
			team = keys.target:GetTeamNumber()
		end
	else
		team = DOTA_TEAM_NEUTRALS
	end
 	local theChosenOne = RandomInt(1,#heroes)
	for _,hero in pairs(heroes) do
		if _ == theChosenOne then
			local unit = CreateUnitByName("npc_dota_hero_"..hero, keys.caster:GetCursorPosition(), true, keys.caster, nil, team)
			FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), false)
			unit:SetControllableByPlayer(keys.caster:GetPlayerID(), true)
			unit.debugEntity = true
			break
		end
	end
end

function SpawnCreeps( keys )
	local team
	if keys.target then
		if keys.target:GetTeam() == keys.caster:GetTeam() then
			team = keys.caster:GetTeamNumber()
		else
			team = keys.target:GetTeamNumber()
		end
	else
		team = DOTA_TEAM_NEUTRALS
	end
	local theChosenOne = RandomInt(1,#creeps)
	for _,creep in pairs(creeps) do
		if _ == theChosenOne then
			local unit = CreateUnitByName("npc_dota_"..creep, keys.caster:GetCursorPosition(), true, keys.caster, nil, team)
			FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), false)
			unit:SetControllableByPlayer(keys.caster:GetPlayerID(), true)
			unit.debugEntity = true
			break
		end
	end
end

function LevelUp( keys )
	if keys.target then
		if keys.target:IsRealHero() then
			keys.target:AddExperience(1000,0,false,false)
		end
	else
		keys.caster:AddExperience(1000,0,false,false)
	end
end

function RemoveSpawnedEntities( keys )
	if keys.target then
		if keys.target:GetUnitName() == ("npc_dota_goodguys_fort" or "npc_dota_badguys_fort") then
			local units = FindUnitsInRadius(keys.caster:GetTeamNumber(), Vector(0,0,0), nil, 20000, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
			for _,unit in pairs(units) do
				if unit.debugEntity then
					unit:RemoveSelf()
				end
			end
		end
	end
end

function ControlAllUnits( keys )
	local units = FindUnitsInRadius(keys.caster:GetTeamNumber(), Vector(0,0,0), nil, 20000, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	for _,unit in pairs(units) do
		if unit:GetPlayerID() ~= 0 then
			unit:SetControllableByPlayer(keys.caster:GetPlayerID(), true)
		end
	end
end


--[[///////////////////
/// Debug Commands ///
/////////////////////]]

function DebugScripts( keys, playerID )
	print("debug_scripts_called")
	local teamonly = keys.teamonly
	local userID = keys.userid
	local text = keys.text
	local d = "-debug "
--	DeepPrintTable(keys)

	local cheatNames = {
		[1] = "-debug",
		[2] = "help",
		[3] = "hero or spawn",
		[4] = "heroes or 'spawn all'",
		[5] = "respawn",
		[6] = "kill",
		[7] = "despawn or remove",
		[8] = "center",
		[9] = "'center all'",
	--	[10] = "",
	--	[11] = "",
	--	[12] = "",
	}
	local cheatDesc = {
		["-debug"] = "lists all debug commands",
		["help"] = "lists all debug commands",
		["hero or spawn"] = "spawn a random hero.",
		["heroes or 'spawn all'"] = "spawn one of each hero.",
		["respawn"] = "respawns all debug entities.",
		["kill"] = "kills all debug entities. they can respawn.",
		["despawn or remove"] = "removes all debug entities from the game.",
		["center"] = "moves yourself to the center of the map",
		["'center all'"] = "moves all heroes to the center of the map"
	--	[10] = "",
	--	[11] = "",
	--	[12] = "",
	}
	
	if text == d.."spawn" or text == d.."hero" or text == d.."create hero" or text == d.."createhero" then
		CreateHeroes(playerID, 1)
	elseif text == d.."spawn all" or text == d.."spawnall" or text == d.."create heroes" or text == d.."createheroes" or text == d.."heroes" then
		CreateHeroes(playerID, nil)
	elseif text == d or text == "-debug" or text == d.."help" then
		Say(nil, "view console for more information", false)
		print("----------- Debug Cheats -----------")
		print("put '-debug' before each cheat")
		print()
		for _,name in pairs(cheatNames) do
			for cheat, desc in pairs(cheatDesc) do
				if cheat == name then
					print(cheat..": "..desc)
				end
			end
		end
		print("------------------------------------")
	elseif text == d.."newhero" then
		for _,hero in pairs(heroes) do
			if text == d.."newhero "..hero then
				PlayerResource:ReplaceHeroWith(playerID, "npc_dota_hero_"..hero, PlayerResource:GetGold(playerID), PlayerResource:GetTotalEarnedXP(playerID))
				return
			end
		end
		UTIL_MessageText(playerID, "Incorrect usage of command or invalid hero. Correct usage: -debug newhero skeleton_king", 255,255,255,255)
	end

	local heroes = HeroList:GetAllHeroes()
	for heroID in pairs(heroes) do
		local hero = HeroList:GetHero(heroID-1)
		if hero ~= nil then
			if text == d.."center" then
				if hero:GetPlayerID() == playerID then
					FindClearSpaceForUnit(hero, Vector(0,0,0), false)
					break
				end
			elseif text == d.."center all" then
				FindClearSpaceForUnit(hero, Vector(0,0,0), false)
			end
			-- so that these cheats dont effect the user
			if hero:GetPlayerID() ~= playerID then
				if text == d.."respawn" then
					if not hero:IsAlive() then
						hero:RespawnHero(false, false, false)
					end
				elseif text == d.."despawn" or text == d.."remove" then
					hero:RemoveSelf()
				elseif text == d.."kill" then
					hero:ForceKill(false)
				end
			end
		end
	end
end

function CreateHeroes( playerID, num )
	local cap
	if num == nil then
		cap = #heroes
	else
		cap = num
	end

	local units = FindUnitsInRadius(1, Vector(0,0,0), nil, 20000, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_UNITS_EVERYWHERE, false)
	local playerHero
	for _,unit in pairs(units) do
		if unit:GetPlayerID() == playerID then
			playerHero = unit
		end
	end

	local random = RandomInt(1, #heroes)
	local passed = 0
	for _,heroName in pairs(heroes) do
		if cap ~= 1 then
			local newHero = CreateUnitByName("npc_dota_hero_"..heroName, playerHero:GetCursorPosition(), true, playerHero, nil, DOTA_TEAM_NEUTRALS)
			FindClearSpaceForUnit(newHero, newHero:GetAbsOrigin(), false)
			newHero:SetControllableByPlayer(playerID, true)
			newHero.debugEntity = true
		else
			if _ == random then
				local newHero = CreateUnitByName("npc_dota_hero_"..heroName, playerHero:GetCursorPosition(), true, playerHero, nil, DOTA_TEAM_NEUTRALS)
				FindClearSpaceForUnit(newHero, newHero:GetAbsOrigin(), false)
				newHero:SetControllableByPlayer(playerID, true)
				newHero.debugEntity = true
			end
		end
	end
end