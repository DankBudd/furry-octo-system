--[[ 
 	defining the modifier (or ability) as class is essentially the same as doing 
 	 "BaseClass" "ability_datadriven" in a datadriven ability,
 	 and it is required in order to do anything
 ]]
-- hidden aura thinker used to apply attack and movespeed slow
modifier_gravity_well_aura = class({})

-- self explanatory
function modifier_gravity_well_aura:IsAura()
	return true
end

--[[
 	ensures that gravity_well will not continue to apply slow after it expires
 	( this might actually only do something if modifier is attached to a unit ¯\_(ツ)_/¯ )
]]
function modifier_gravity_well_aura:IsAuraActiveOnDeath()
	return false
end

-- this probably is not needed, might remove.
function modifier_gravity_well_aura:AllowIllusionDuplicate()
	return false
end

-- hidden so modkit doesnt generate tooltips for it
function modifier_gravity_well_aura:IsHidden()
	return true
end

-- "self", in this instance, is THIS modifier; modifier_gravity_well_aura
function modifier_gravity_well_aura:GetAuraRadius()
	return self:GetAbility():GetSpecialValueFor("radius")
end

-- self explanatory
function modifier_gravity_well_aura:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_gravity_well_aura:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_gravity_well_aura:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE
end


-- define the modifier to be applied by this aura 
function modifier_gravity_well_aura:GetModifierAura()
	return "modifier_gravity_well_slow"
end


-- modifier applied by aura that will increment stack count, increasing slow amount for each stack, the longer it exists.
modifier_gravity_well_slow = class({})

-- declare the functions you want to use later in this script
function modifier_gravity_well_slow:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_TOOLTIP, -- last comma is not necessary, but also is not wrong.
		--maybe add a second tooltip...?
	}
	return funcs
end

-- self explanatory
function modifier_gravity_well_slow:IsDebuff()
	return true
end

function modifier_gravity_well_slow:IsPurgable()
	return false
end

function modifier_gravity_well_slow:RemoveOnDeath()
	return true
end

--[[ 
	here we gather information from the "kv" (key values) table and store the info in "self",
	 which in this instance is this modifier; "modifier_gravity_well_slow", to be used for later use

	we also use these to start the think interval function,
	 which runs after X seconds delay and then every X seconds thereafter
	  
	(the think can be stopped by calling StartIntervalThink() with -1 as the parameter)
]]
function modifier_gravity_well_slow:OnCreated( kv )
	self.movespeed_penalty = self:GetAbility():GetSpecialValueFor("move_slow")
	self.attackspeed_penalty = self:GetAbility():GetSpecialValueFor("attack_slow")
	self.think_interval = self:GetAbility():GetSpecialValueFor("think_interval")

	-- these tooltips are positive values while the penalties are negative values.
	self.movespeed_tooltip = self:GetAbility():GetSpecialValueFor("move_slow_tooltip")
	self.attackspeed_tooltip = self:GetAbility():GetSpecialValueFor("attack_slow_tooltip")

	if IsServer() then
		self:StartIntervalThink(self.think_interval)
	end
end

-- does the same as above function, but is called when the modifier is refreshed rather than when its created
function modifier_gravity_well_slow:OnRefresh( kv )
	self.movespeed_penalty = self:GetAbility():GetSpecialValueFor("move_slow")
	self.attackspeed_penalty = self:GetAbility():GetSpecialValueFor("attack_slow")
	self.think_interval = self:GetAbility():GetSpecialValueFor("think_interval")

	self.movespeed_tooltip = self:GetAbility():GetSpecialValueFor("move_slow_tooltip")
	self.attackspeed_tooltip = self:GetAbility():GetSpecialValueFor("attack_slow_tooltip")
	
	if self:GetCaster():HasTalent("special_bonus_unique_enigma_3") then
		self.think_interval = self:GetAbility():GetSpecialValueFor("think_interval") - 0.1
	end

	if IsServer() then
		self:StartIntervalThink(self.think_interval)
	end
end

-- think interval called by above functions, seems self explanatory to me
function modifier_gravity_well_slow:OnIntervalThink()
	if IsServer() then
		self:IncrementStackCount()
		self:StartIntervalThink(-1)
		self:ForceRefresh()
	end
end

--[[ 
	return the values you want to be the slow, mana, health, or whatever else you declared in DeclareFunctions()

 	the dota modding sublime package should have all this GetModifierWhatever's in it,
 	but if not, you can go to:

 	https://developer.valvesoftware.com/wiki/Dota_2_Workshop_Tools/Scripting/API#modifierfunction
	
	datadriven stuff for these is under "Name" (also used in DeclareFunctions()),
	and lua under "Description".
]]
function modifier_gravity_well_slow:GetModifierMoveSpeedBonus_Percentage( params )
	return self:GetStackCount() * self.movespeed_penalty
end

function modifier_gravity_well_slow:GetModifierAttackSpeedBonus_Constant( params )
	return self:GetStackCount() * self.attackspeed_penalty
end

--[[ 
	used in modifier descriptions so they display the actual slow amounts on the modifier,
 	rather than something like "attack speed slowed" you can have "attack speed slowed by 12"
]]
function modifier_gravity_well_slow:OnTooltip()
	return self:GetStackCount() * self.movespeed_tooltip
end

function modifier_gravity_well_slow:OnTooltip()
	return self:GetStackCount() * self.attackspeed_tooltip
end
