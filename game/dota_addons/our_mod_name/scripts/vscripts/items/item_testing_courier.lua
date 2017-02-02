function SummonCourier( keys )
	local caster = keys.caster
	local ability = keys.ability

	-- create courier unit
	local courier = CreateUnitByName("npc_testing_courier", caster:GetAbsOrigin() + RandomVector(75), true, caster, caster, caster:GetTeamNumber())
	courier:AddNewModifier(caster, ability, "modifier_magicimmune", {})

--[[
	-- set courier to be controllable by summoners team
	local casterTeam = FindUnitsInRadius(caster:GetTeamNumber(), Vector(0,0,0), nil, 22000, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	for i = 1, #casterTeam do
		local playerID = i:GetPlayerID()
		if playerID ~= -1 then
			courier:SetControllableByPlayer(playerID, true)
		end
	end
]]
end