modifier_knockback_func = class({})

function modifier_knockback_func:IsHidden()
	return true
end

function modifier_knockback_func:IsPurgable()
	return false
end

function modifier_knockback_func:CheckState()
	local states = {
		[MODIFIER_STATE_STUNNED] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_ROOTED] = true,
	}
	return states
end

function modifier_knockback_func:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
	}
	return funcs
end

function modifier_knockback_func:GetOverrideAnimation( params )
	return ACT_DOTA_FLAIL
end

