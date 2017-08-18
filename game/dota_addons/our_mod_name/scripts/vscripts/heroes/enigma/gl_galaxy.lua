LinkLuaModifier("modifier_gl_galaxy", "scripts/vscripts/heroes/enigma/gl_galaxy", LUA_MODIFIER_MOTION_NONE)

gl_galaxy = class({})

function gl_galaxy:GetBehavior()
	local behav = DOTA_ABILITY_BEHAVIOR_PASSIVE
	return behav
end

function gl_galaxy:GetIntrinsicModifierName()
	return "modifier_gl_galaxy"
end

-------------------------------------------------

modifier_gl_galaxy = class({})

function modifier_gl_galaxy:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE,
	}
	return funcs
end

function modifier_gl_galaxy:IsHidden()
	return true
end

function modifier_gl_galaxy:IsPurgable()
	return false
end

function modifier_gl_galaxy:RemoveOnDeath()
	return false
end

function modifier_gl_galaxy:OnCreated( kv )
	self:StartIntervalThink(0.2)
end

function modifier_gl_galaxy:OnIntervalThink()
	self.reduction = self:GetAbility():GetSpecialValueFor("cd_reduction") * 0.01
end

--https://github.com/darklordabc/Legends-of-Dota-Redux/blob/1eb5217832ea92d3d8b5c7b09bb20d71f28bb997/src/game/scripts/vscripts/abilities/jingtong_op.lua
function modifier_gl_galaxy:GetModifierPercentageCooldown()
	return self.reduction
end