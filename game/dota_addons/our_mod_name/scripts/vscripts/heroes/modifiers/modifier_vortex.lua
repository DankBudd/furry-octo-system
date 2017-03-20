modifier_vortex = class({})

function modifier_vortex:IsHidden()
	return true
end

function modifier_vortex:IsPurgable()
	return false
end

function modifier_vortex:OnCreated( kv )
	StartIntervalThink(0.03)
end

function modifier_vortex:OnIntervalThink()
	local units = FindUnitsInRadius(self:GetParent()(), self:GetParent():GetAbsOrigin(), nil, 500, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	for _,unit in pairs(units) do
		unit:SetAbsOrigin(unit:GetAbsOrigin() + (self:GetAbsOrigin() - unit:GetAbsOrigin()):Normalized() * 3)
	end
end