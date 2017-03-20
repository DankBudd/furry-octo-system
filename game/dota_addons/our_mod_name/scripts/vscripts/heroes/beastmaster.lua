function SummonBoar( keys )
	local caster = keys.caster
	local ability = keys.ability
	local summonPoints = {Vector(50,50,0), Vector(50,-50,0), Vector(-50,50,0)} -------------
	local numBoars = ability:GetSpecialValueFor("boar_count")
	if caster:HasScepter() then
		numBoars = numBoars+1
	end
	caster.existingBoars = caster.existingBoars or {}

	local models = {
		"models/items/beastmaster/boar/fotw_wolf/fotw_wolf.vmdl",
		"models/items/beastmaster/boar/beast_heart_marauder_beast_heart_marauder_warhound/beast_heart_marauder_beast_heart_marauder_warhound.vmdl",
		"models/items/beastmaster/boar/beast_heart_marauder_beast_heart_marauder_warhound/beast_heart_marauder_beast_heart_marauder_warhound.vmdl",
	}
	local modelChanging = {
		"asd",
		"asds",
		"asdasdasd",
		"asdass",
		"asdasda",
	}
	-- if caster has a wearable that changes boar model, leave it as is. otherwise replace the boar model with appropriate model from models table
	local wearables = {}
	local model = caster:FirstMoveChild()
	local modelName
	while model ~= nil do
		if model:GetClassname() == "dota_item_wearable" then
			for k,v in pairs(modelChanging) do
				if model:GetName() == v then
					modelName = ""
					break
				end
			end
		end
		model = model:NextMovePeer()
	end
	if modelName == nil then
		modelName = models[ability:GetLevel()] ----------- minus 1?
	end
	
	local i = 1
	while i <= numBoars do
		if caster.existingBoars[i] ~= nil then
			--respawn boar
			caster.existingBoars[i]:RespawnUnit()--this needs testing, ive been told it doesnt work properly
		else
			--create boar
			local testing = CreateUnitByName("npc_dota_hero_enigma", Vector(0,0,0), false, caster, caster, caster:GetTeamNumber())
			local boar = CreateUnitByName("npc_ultra_boar", caster:GetAbsOrigin() + summonPoints[i], true, caster, caster, caster:GetTeamNumber()) --2nd caster might need to be nil
			boar:SetOwner(caster)
			boar:SetControllableByPlayer(caster:GetPlayerID(), true)
			boar:SetPlayerID(caster:GetPlayerID())
			boar:SetForwardVector(caster:GetForwardVector())
			if not modelName == "base_model" then
				boar:SetModel(modelName)
				boar:SetOriginalModel(modelName)
			end
			boar:SetModelScale(ability:Getlevel()/1.25)
--			boar:SetMaxHealth(amt)
--			boar:SetBaseMoveSpeed(iMoveSpeed)

			FindClearSpaceForUnit(boar, boar:GetAbsOrigin(), true)
			caster.existingBoars[i] = boar
		end
		i = i + 1
	end
end