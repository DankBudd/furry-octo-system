LinkLuaModifier("modifier_couriers_reign_transmogrification", "heroes/couriers_reign.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_couriers_reign_courier_stats", "heroes/couriers_reign.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_couriers_reign_hero_stats", "heroes/couriers_reign.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_couriers_reign_hero_movement_speed", "heroes/couriers_reign.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_couriers_reign_courier_movement_speed", "heroes/couriers_reign.lua", LUA_MODIFIER_MOTION_NONE)

function Transmogrify( keys )
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target
	local duration = ability:GetSpecialValueFor("duration")

	if target:IsCourier() then
		print("target is courier")
		target:AddNewModifier(caster, ability, "modifier_couriers_reign_hero_stats", {duration = duration})
	--	target:AddNewModifier(caster, ability, "modifier_couriers_reign_hero_movement_speed", {duration = duration})
	end
	if target ~= caster then
		print("target is not caster")
		if target:IsRealHero() then
			print("target is real hero")
			target:AddNewModifier(caster, ability, "modifier_couriers_reign_courier_stats", {duration = duration})
		--	target:AddNewModifier(caster, ability, "modifier_couriers_reign_courier_movement_speed", {duration = duration})
		end
		target:AddNewModifier(caster, ability, "modifier_couriers_reign_transmogrification", {duration = duration})
		target:EmitSound(keys.soundName)
		local particle = ParticleManager:CreateParticle(keys.particle, PATTACH_ABSORIGIN, target)
		print("sound, particle, and transmogrification")
	end
end


modifier_couriers_reign_transmogrification = class({})

function modifier_couriers_reign_transmogrification:GetTexture()
	local texture = "holdout_fiery_soul"
	if self:GetParent():IsRealHero() then
		texture = "holdout_voodoo"
	end
	return texture
end

function modifier_couriers_reign_transmogrification:IsPurgable()
	return false
end

function modifier_couriers_reign_transmogrification:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MODEL_CHANGE
	}
	return funcs
end

function modifier_couriers_reign_transmogrification:GetModifierModelChange()
	self.courierModels = {}
	self.courierModels[1] = "models/courier/sillydragon/sillydragon"
	self.courierModels[2] = "models/courier/minipudge/minipudge"
	self.courierModels[3] = "models/courier/huntling/huntling"
	self.courierModels[4] = "models/courier/mech_donkey/mech_donkey"
	self.courierModels[5] = "models/courier/drodo/drodo"
	self.courierModels[6] = "models/courier/donkey_crummy_wizard_2014/donkey_crummy_wizard_2014"
	self.courierModels[7] = "models/courier/godhorse/godhorse"
	self.courierModels[8] = "models/courier/turtle_rider/turtle_rider"
	self.courierModels[9] = "models/courier/stump/stump"
	self.courierModels[10] = "models/courier/seekling/seekling"

	self.heroModels = {}
	self.heroModels[1] = "models/heroes/blood_seeker/blood_seeker"
	self.heroModels[2] = "models/heroes/legion_commander/legion_commander"
	self.heroModels[3] = "models/heroes/phantom_lancer/phantom_lancer"
	self.heroModels[4] = "models/heroes/shopkeeper/shopkeeper"
	self.heroModels[5] = "models/heroes/shopkeeper_dire/shopkeeper_dire"
	self.heroModels[6] = "models/heroes/slark/slark"
	self.heroModels[7] = "models/heroes/tuskarr/tuskarr"
	self.heroModels[8] = "models/heroes/morphling/morphling"
	self.heroModels[9] = "models/heroes/nerubian_assassin/nerubian_assassin"
	self.heroModels[10] = "models/heroes/magnataur/magnataur"

	--probably gunna replace this with findunitsinradius(...) because it doesnt seem to work
	-- search for a flying courier on modifier owners team
	if self:GetParent():IsRealHero() then
		for i = 0, PlayerResource:GetNumCouriersForTeam(PlayerResource:GetCustomTeamAssignment(self:GetParent():GetPlayerID())) - 1 do
			local courier = PlayerResource:GetNthCourierForTeam(i, PlayerResource:GetCustomTeamAssignment(self:GetParent():GetPlayerID()))
			if courier:HasFlyMovementCapability() then
				local isFlying = courier:HasFlyMovementCapability() == true
				self:GetParent():SetMoveCapability(DOTA_UNIT_CAP_MOVE_FLY)
				break
			end
		end
	end

--	print("transmog: model stuff")
	local table 
	if self:GetParent():IsRealHero() then
		table = self.courierModels
	else
		table = self.heroModels
	end

	local modelNum = RandomInt(1, #table)
	for key, model in pairs(table) do
		if key == modelNum then
--			print("transmog: success")
			return model .. (isFlying and "_flying.vmdl" or ".vmdl")
		end
--		print("transmog: key is not = to model num")
	end
--	print("transmog: failed")
end


modifier_couriers_reign_courier_stats = class({})

function modifier_couriers_reign_courier_stats:IsHidden()
	return true
end

function modifier_couriers_reign_courier_stats:IsPurgable()
	return false
end

function modifier_couriers_reign_courier_stats:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_HEALTH_BONUS,
		MODIFIER_PROPERTY_MANA_BONUS,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
	}
	return funcs
end

function modifier_couriers_reign_courier_stats:OnCreated( kv )
	if IsServer() then
		self.healthReduction = 75 - self:GetParent():GetMaxHealth()
		self.originalHealth = self:GetParent():GetHealth()
		self.originalMana = self:GetParent():GetMana()
	end
	self.manaReduction = 0 - self:GetParent():GetMaxMana()
	self.armorReduction = 0 - self:GetParent():GetPhysicalArmorValue()

	self:StartIntervalThink(0.03)
end

function modifier_couriers_reign_courier_stats:OnIntervalThink()
	if IsServer() then
		if self:GetParent():IsAlive() then
			self:GetParent():SetHealth(75)
			self:StartIntervalThink(-1)
		end
	end
end

function modifier_couriers_reign_courier_stats:OnDestroy()
	if IsServer() and self:GetParent():IsAlive() then
		self:GetParent():SetHealth(self.originalHealth)
		self:GetParent():SetMana(self.originalMana)
	end
end

function modifier_couriers_reign_courier_stats:GetModifierHealthBonus()
	if self.healthReduction then
		return self.healthReduction
	end
end

function modifier_couriers_reign_courier_stats:GetModifierManaBonus()
	return self.manaReduction
end

function modifier_couriers_reign_courier_stats:GetModifierPhysicalArmorBonus()
	return self.armorReduction
end


modifier_couriers_reign_hero_stats = class({})

function modifier_couriers_reign_hero_stats:IsHidden()
	return false
end

function modifier_couriers_reign_hero_stats:IsPurgable()
	return false
end

function modifier_couriers_reign_hero_stats:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_HEALTH_BONUS,
		MODIFIER_PROPERTY_MANA_BONUS,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
	}
	return funcs
end

function modifier_couriers_reign_hero_stats:OnCreated( kv )
	self.healthMin = self:GetAbility():GetSpecialValueFor("hero_min_health")
	self.healthMax = self:GetAbility():GetSpecialValueFor("hero_max_health")

	self.mana = self:GetParent():GetMaxMana()
	self.manaMin = self:GetAbility():GetSpecialValueFor("hero_min_mana")
	self.manaMax = self:GetAbility():GetSpecialValueFor("hero_max_mana")

	self.armor = self:GetParent():GetPhysicalArmorValue()
	self.armorMin = self:GetAbility():GetSpecialValueFor("hero_min_armor")
	self.armorMax = self:GetAbility():GetSpecialValueFor("hero_max_armor")

	self.manaBonus = self.mana + RandomInt(self.manaMin, self.manaMax)
	self.armorBonus = self.armor + RandomInt(self.armorMin, self.armorMax)

	if IsServer() then
		self.health = self:GetParent():GetMaxHealth()
		self.healthBonus = self.health + RandomInt(self.healthMin, self.healthMax)
	end
end

function modifier_couriers_reign_hero_stats:OnDestroy()
	if IsServer() then
	end
end

function modifier_couriers_reign_hero_stats:GetModifierHealthBonus()
	if self.health then
		return self.healthBonus
	end
end

function modifier_couriers_reign_hero_stats:GetModifierManaBonus()
	return self.manaBonus
end

function modifier_couriers_reign_hero_stats:GetModifierPhysicalArmorBonus()
	return self.armorBonus
end


modifier_couriers_reign_courier_movement_speed = class({})

function modifier_couriers_reign_courier_movement_speed:IsHidden()
	return true
end

function modifier_couriers_reign_courier_movement_speed:IsPurgable()
	return false
end

function modifier_couriers_reign_courier_movement_speed:OnCreated( kv )
	self.courierSpeed = self:GetAbility():GetSpecialValueFor("courier_speed")
end

function modifier_couriers_reign_courier_movement_speed:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_LIMIT,
	}
	return funcs
end

function modifier_couriers_reign_courier_movement_speed:GetModifierMoveSpeed_Limit()
	return self.courierSpeed
end


modifier_couriers_reign_hero_movement_speed = class({})

function modifier_couriers_reign_hero_movement_speed:OnCreated( kv )
	if IsServer() then
	end
	--base movespeed for each hero
	self.heroTable = {
		blood_seeker = 290,
		legion_commander = 320,
		phantom_lancer = 290,
		shopkeeper = 0.1,
		shopkeeper_dire = 0.1,
		slark = 1,
		tuskarr = 1,
		morphling = 1,
		nerubian_assassin = 1,
		magnataur = 1,
	}

	--extra movespeed from boots
	self.bootTable = {
		item_boots = 45,
		item_phase_boots = 45,
		item_travel_boots = 100,
		item_travel_boots2 = 100,
		item_tranquil_boots = 85,
		item_arcane_boots = 50
	}

--these need to be counted as special cases in the code below, ill do that later.
--	self.bootTable[item_wind_lace] = 20 
--	self.bootTable[drums] =
--	self.bootTable[euls] =

	for hero, heroSpeed in pairs(self.heroTable) do
		if self:GetParent():GetModelName() == hero then
			self.moveSpeed = heroSpeed
		end
	end

	self.highestBootSpeed = 0
	for i = 0,5 do
		local item = self:GetParent():GetItemInSlot(i)
		for boot, bootSpeed in pairs(self.bootTable) do
			if item then
				if item:GetName() == boot then
					if bootSpeed > self.highestBootSpeed then
						self.moveSpeed = self.moveSpeed - self.highestBootSpeed
						self.moveSpeed = self.moveSpeed + bootSpeed
						self.highestBootSpeed = bootSpeed
					end
				end
			end
		end
	end
end

function modifier_couriers_reign_hero_movement_speed:IsHidden()
	return true
end

function modifier_couriers_reign_hero_movement_speed:IsPurgable()
	return false
end

function modifier_couriers_reign_hero_movement_speed:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_MAX,
		MODIFIER_PROPERTY_MOVESPEED_LIMIT,
		MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE,
	}
	return funcs
end

function modifier_couriers_reign_hero_movement_speed:GetModifierMoveSpeed_Max()
	return self.moveSpeed
end

function modifier_couriers_reign_hero_movement_speed:GetModifierMoveSpeed_Limit()
	return self.moveSpeed
end

function modifier_couriers_reign_hero_movement_speed:GetModifierMoveSpeed_Absolute()
	return self.moveSpeed
end