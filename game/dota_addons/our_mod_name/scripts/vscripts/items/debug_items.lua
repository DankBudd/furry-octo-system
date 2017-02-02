function SpawnHeroes( keys )
	local heroes = {
		"lina",
		"pudge",
	--	"sven",
		"ogre_magi",
		"medusa",
	--	"monkey_king",
	--	"",
	}

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
			unit:SetControllableByPlayer(keys.caster:GetPlayerID(), true)
			unit.debugEntity = true
			break
		end
	end
end

function SpawnCreeps( keys )
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
		"lone_druid_bear3",
	--	"",
	}
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
		else
			Say(nil,"target is invalid, no experience given", true)
		end
	else
		keys.caster:AddExperience(1000,0,false,false)
	end
end

-- dead units will not be found
function RemoveSpawnedEntities( keys )
	if keys.target then
	--	print(keys.target:GetUnitName())
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