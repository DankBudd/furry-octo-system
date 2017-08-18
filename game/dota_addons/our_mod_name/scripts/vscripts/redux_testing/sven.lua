LinkLuaModifier("modifier_sven_storm_bolt_stun", "redux_testing/sven.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sven_talent", "redux_testing/sven.lua", LUA_MODIFIER_MOTION_NONE)

sven_storm_bolt_lua = class({})

--have to use modifier stacks to transfer the talent value from server to client
--problem with doing this within GetCooldown() is that it will not update the tooltip until the spell is cast.
function sven_storm_bolt_lua:GetCooldown( nLevel )
	local reduction = 0

	if IsServer() and not self:GetCaster():HasModifier("modifier_sven_talent") then 
		local talent = self:GetCaster():FindAbilityByName("special_bonus_unique_sven")
		if talent then
			if talent:GetLevel() > 0 then
				local mod = self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_sven_talent", {})
				mod:SetStackCount(talent:GetSpecialValueFor("value"))
			end
		end
	end

	if self:GetCaster():HasModifier("modifier_sven_talent") then
		reduction = self:GetCaster():GetModifierStackCount("modifier_sven_talent", self:GetCaster())
	end
	return self.BaseClass.GetCooldown(self, nLevel) - reduction
end

function sven_storm_bolt_lua:OnSpellStart()
	local target = self:GetCursorTarget()
	if not target then return end

	EmitSoundOn("Hero_Sven.StormBolt", self:GetCaster())

	self.damage = self:GetAbilityDamage()
	self.radius = self:GetSpecialValueFor("bolt_aoe")
	self.duration = self:GetSpecialValueFor("bolt_stun_duration")
	self.dType = self:GetAbilityDamageType()

	local info = {
		EffectName = "particles/units/heroes/hero_sven/sven_spell_storm_bolt.vpcf",
		Target = target,
		Source = self:GetCaster(),
		Ability = self,
		bDodgeable = true,
		iMoveSpeed = self:GetSpecialValueFor("bolt_speed"),
		iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1,
		bProvidesVision = true,
		iVisionRadius = self:GetSpecialValueFor("vision_radius"),
		iVisionTeamNumber = self:GetCaster():GetTeamNumber(),
	}
	ProjectileManager:CreateTrackingProjectile( info )
end

function sven_storm_bolt_lua:OnProjectileHit( hTarget, vLocation )
	if not IsServer() or not hTarget or hTarget:IsNull() then return end
	if hTarget:GetTeam() ~= self:GetCaster():GetTeam() and hTarget:TriggerSpellAbsorb(self) then return end

	EmitSoundOn("Hero_Sven.StormBoltImpact", hTarget)

	local sven = ParticleManager:CreateParticle("particles/units/heroes/hero_sven/sven_storm_bolt_projectile_explosion.vpcf", PATTACH_POINT, hTarget)
	ParticleManager:SetParticleControlEnt(sven, 3, hTarget, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", hTarget:GetAbsOrigin(), false)

	local units = FindUnitsInRadius(self:GetCaster():GetTeamNumber(), hTarget:GetAbsOrigin(), nil, self.radius, self:GetAbilityTargetTeam(), self:GetAbilityTargetType(), self:GetAbilityTargetFlags(), FIND_ANY_ORDER, false)
	for _,unit in pairs(units) do
		ApplyDamage({victim = unit, attacker = self:GetCaster(), ability = self, damage = self.damage, damage_type = self.dType})
		unit:AddNewModifier(self:GetCaster(), self, "modifier_sven_storm_bolt_stun", {duration = self.duration})		
	end
end


modifier_sven_storm_bolt_stun = class({
	IsHidden = function(self) return false end,
	IsDebuff = function(self) return true end,
	IsPurgable = function(self) return true end,
	IsStunDebuff = function(self) return true end,

	DeclareFunctions = function(self) return {MODIFIER_PROPERTY_OVERRIDE_ANIMATION,} end,
	CheckState = function(self) return {[MODIFIER_STATE_STUNNED] = true,} end,

	GetEffectName = function(self) return "particles/generic_gameplay/generic_stunned.vpcf" end,
	GetEffectAttachType = function(self) return PATTACH_OVERHEAD_FOLLOW end,
	GetOverrideAnimation = function(self) return ACT_DOTA_DISABLED end,
})


modifier_sven_talent = class({
	IsHidden = function(self) return true end,
	IsPurgable = function(self) return false end,
})