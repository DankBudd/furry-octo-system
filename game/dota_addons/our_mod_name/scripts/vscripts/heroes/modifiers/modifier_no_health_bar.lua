modifier_no_health_bar = class({})

function modifier_no_health_bar:IsHidden()
	return true
end

function modifier_no_health_bar:IsPurgable()
	return false
end

function modifier_no_health_bar:CheckState()
	local states = {
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
	}
	return states
end
