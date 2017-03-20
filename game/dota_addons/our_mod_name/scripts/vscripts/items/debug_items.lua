local heroes = {
	"lina",
	"enigma",
	"pudge",
	"sven",
	"ogre_magi",
	"medusa",
	"morphling",
	"furion",
	"enchantress",
	"skeleton_king",
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
	local text = keys.text
	local d = "-debug "
--	DeepPrintTable(keys)

	local cheatNames = {
		[1] = "-debug",
		[2] = "help",
		[3] = "hero or spawn",
		[4] = "heroes or spawn all",
		[5] = "respawn",
		[6] = "kill",
		[7] = "despawn or remove",
		[8] = "center",
		[9] = "center all",
		[10] = "newhero",
	--	[11] = "",
	--	[12] = "",
	}
	local cheatDesc = {
		["-debug"] = "lists all debug commands",
		["help"] = "lists all debug commands",
		["hero"] = "spawn a random hero.",
		["heroes"] = "spawn one of each hero. input a number for a specified amount of heroes",
		["respawn"] = "respawns all debug entities.",
		["kill"] = "kills all debug entities. they can respawn.",
		["despawn or remove"] = "removes all debug entities from the game.",
		["center"] = "moves yourself to the center of the map",
		["center all"] = "moves all heroes to the center of the map",
		["newhero"] = "give yourself a new hero",
	--	[11] = "",
	--	[12] = "",
	}
	
	if text == d.."spawn" or text == d.."hero"then
		CreateHeroesNew(playerID, 1)
	elseif string.find(text, d.."heroes") then
	 	local num = tonumber(string.match(text, "(%d+)"))
		-- will eventually implement more options for this command
		-- such as spawning a specific hero, or spawning more than the tables limit
		if num and num >= 1 and num <= #heroes then
			num = num
		else 
			num = #heroes
		end
		CreateHeroesNew(playerID, num)
	elseif text == d or text == "-debug" or text == d.."help" then
		GameRules:SendCustomMessage("----------- Debug Cheats -----------", PlayerResource:GetTeam(playerID), 1)
		GameRules:SendCustomMessage("put '-debug' before each cheat", PlayerResource:GetTeam(playerID), 1)
		GameRules:SendCustomMessage("", PlayerResource:GetTeam(playerID), 1)
		for _,name in pairs(cheatNames) do
			for cheat, desc in pairs(cheatDesc) do
				if cheat == name then
					GameRules:SendCustomMessage(cheat..": "..desc, PlayerResource:GetTeam(playerID), 1)
				end
			end
		end
		GameRules:SendCustomMessage("-------------------------------------", PlayerResource:GetTeam(playerID), 1)
	elseif string.find(text, d.."newhero") then
		for _,hero in pairs(heroes) do
			if text == d.."newhero "..hero then
				local oldHero = PlayerResource:GetSelectedHeroEntity(playerID)
				if oldHero then
					if oldHero:GetName() ~= "npc_dota_hero_"..hero then
						PlayerResource:ReplaceHeroWith(playerID, "npc_dota_hero_"..hero, PlayerResource:GetGold(playerID), PlayerResource:GetTotalEarnedXP(playerID))
						UTIL_Remove(oldHero)
						return
					else
						GameRules:SendCustomMessage("You are already "..hero.."!", PlayerResource:GetTeam(playerID), 1)
						return
					end
				else
					Notifications:Top(playerID, {text="You have no hero to change from!", duration=2.0})
					Timers:CreateTimer(1.9, function()
						Notifications:Top(playerID, {text="Attempting to create new hero '"..hero.."' for you", duration=2.0})
					end)
					-- dont think this is possible atm
					Timers:CreateTimer(3.5, function()
						local newHero = CreateHeroForPlayer("npc_dota_hero_"..hero, PlayerResource:GetPlayer(playerID))
						newHero:SetControllableByPlayer(playerID, true)
						PlayerResource:SetOverrideSelectionEntity(playerID, newHero)
						FindClearSpaceForUnit(newHero, Vector(0,0,0), true)
						Notifications:Top(playerID, {text="Creation of "..hero.." was unsuccessful. Sorry!", duration=5})
					end)
					return
				end
			end
		end
		GameRules:SendCustomMessage("Incorrect usage of command or invalid hero.", PlayerResource:GetTeam(playerID), 1)
		GameRules:SendCustomMessage("Correct usage: -debug newhero skeleton_king", PlayerResource:GetTeam(playerID), 1)
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
					if not hero:IsAlive() then
						hero:RespawnHero(false, false, false)
					end
					hero:RemoveSelf()
				elseif text == d.."kill" then
					hero:ForceKill(false)
				end
			end
		end
	end
end

function CreateHeroes( playerID, num )
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
		if num ~= 1 then
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

function CreateHeroesNew( playerID, num )
	if not num or not playerID then return end
	if num <= 0 then return end

	local caller = PlayerResource:GetSelectedHeroEntity(playerID)
	local team = DOTA_TEAM_NEUTRALS -- set cursor target to be team later?

	local numSpawned = 0
	local random = RandomInt(1, #heroes)
	for _,hero in pairs(heroes) do
		if numSpawned < num then
			local newHero
			if num == 1 then
				if _ == random then
					newHero = CreateUnitByName("npc_dota_hero_"..hero, caller:GetCursorPosition(), true, caller, nil, team)
					newHero:SetControllableByPlayer(playerID, true)
					newHero.debugEntity = true
					numSpawned = numSpawned+1
				end
			else
				newHero = CreateUnitByName("npc_dota_hero_"..hero, caller:GetCursorPosition(), true, caller, nil, team)
				newHero:SetControllableByPlayer(playerID, true)
				newHero.debugEntity = true
				numSpawned = numSpawned+1
			end
		end
	end
end

--~goal~
-- if at least 3 characters in a row match
-- autocomplete heroname
function AutoComplete( heroName )
	for _,hero in pairs(heroes) do
		local something = string.match(heroName, "("..hero..")")
	end
	return complete
end