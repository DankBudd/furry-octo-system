wasuro_sword_slash = class({})

function wasuro_sword_slash:GetCastAnimation()
	return 
end

function wasuro_sword_slash:GetPlaybackRateOverride()

end

function wasuro_sword_slash:OnSpellStart()
	--use linear proj for finding units in cone shaped area, damage and apply modifier to each unit
	local proj = ProjectileManager:CreateLinearProjectile({

	})
end


modifier_wasuro_sword_slash = class({
	IsHidden = function(self) return false end,
	IsPurgable = function(self) return true end,
	IsDebuff = function(self) return true end,
})

function modifier_wasuro_sword_slash:OnCreated( kv )
	self.damage = self:GetAbility():GetSpecialValueFor("damage")
	self.pct = self:GetAbility():GetSpecialValueFor("damage_health_pct")
	self:StartIntervalThink(self:GetAbility():GetSpecialValueFor("tick"))
end

function modifier_wasuro_sword_slash:OnIntervalThink()
	local damage = self.damage + (self.pct*self:GetParent():GetMaxHealth()*0.01)
	ApplyDamage({victim = self:GetParent(), attacker = self:GetCaster(), ability = self:GetAbility(), damage = damage, damage_type = self:GetAbility():GetAbilityDamageType()})
end

--"