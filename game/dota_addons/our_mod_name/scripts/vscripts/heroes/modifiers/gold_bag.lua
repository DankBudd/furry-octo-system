gold_bag_ability = class({})

function gold_bag_ability:GetIntrinsicModifierName()
	return "modifier_bag_dropper"
end


modifier_bag_dropper = class({})

function modifier_bag_dropper:OnCreated( kv )
	self.gold = kv.gold or self:GetAbility():GetSpecialValueFor("gold_bag_amount") or 25
	self.duration = kv.duration or self:GetAbility():GetSpecialValueFor("gold_bag_duration") or -1
end

function modifier_bag_dropper:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_DEATH,
	}
end

function modifier_bag_dropper:OnDeath()
	for i=1,2--[[some shit for how many bags]] do
		i=i+1
		CreateModifierThinker(self:GetParent(), self:GetAbility(), "modifier_bag_thinker", {gold = self.gold, duration = self.duration}, self:GetParent():GetAbsOrigin(), self:GetParent():GetTeamNumber(), false)
	end
end


modifier_bag_thinker = class({})

function modifier_bag_thinker:OnCreated( kv )
	self.bag = ParticleManager:CreateParticle("", PATTACH_WORLDORIGIN, self:GetCaster())

	self:StartIntervalThink(0.03)
end

--droploot like effect in random direction
function modifier_bag_thinker:OnIntervalThink()
end

function modifier_bag_thinker:IsPurgable()
	return false
end
function modifier_bag_thinker:IsHidden()
	return true
end
function modifier_bag_thinker:IsAura()
	return true
end
function modifier_bag_thinker:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end
function modifier_bag_thinker:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO
end
function modifier_bag_thinker:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_NONE
end
function modifier_bag_thinker:GetAuraRadius()
	return 50
end
function modifier_bag_thinker:GetModifierAura()
	return "modifier_bag_give_gold"
end


modifier_bag_give_gold = class({})

function modifier_bag_give_gold:OnCreated( kv )
	self.gold = kv.gold or self:GetAbility():GetSpecialValueFor("gold_bag_amount") or 25
	--give gold to parents team

	--remove aura emitter
end