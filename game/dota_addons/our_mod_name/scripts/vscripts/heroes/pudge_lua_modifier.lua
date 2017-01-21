modifier_rotting_flesh = class({})

--------------------------------------------------------------------------------

function modifier_rotting_flesh:IsDebuff()
	return true
end

--------------------------------------------------------------------------------

function modifier_rotting_flesh:IsAura()
	if self:GetCaster() == self:GetParent() then
		return true
	end
	
	return false
end

--------------------------------------------------------------------------------

function modifier_rotting_flesh:GetModifierAura()
	return "modifier_rotting_flesh"
end

--------------------------------------------------------------------------------

function modifier_rotting_flesh:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

--------------------------------------------------------------------------------

function modifier_rotting_flesh:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

--------------------------------------------------------------------------------

function modifier_rotting_flesh:GetAuraRadius()
	return self.rot_radius
end

--------------------------------------------------------------------------------

function modifier_rotting_flesh:OnCreated( kv )
	self.rot_radius = self:GetAbility():GetSpecialValueFor( "rot_radius" )
	self.rot_slow = self:GetAbility():GetSpecialValueFor( "rot_slow" )
	self.rot_damage = self:GetAbility():GetSpecialValueFor( "rot_damage" )
	self.rot_tick = self:GetAbility():GetSpecialValueFor( "rot_tick" )
	self.resist_reduction = self:GetAbility():GetSpecialValueFor("resist_reduction")
	self.health_to_damage = self:GetAbility():GetSpecialValueFor("health_to_damage") * 0.01

	if IsServer() then
		if self:GetParent() == self:GetCaster() then
			EmitSoundOn( "Hero_Pudge.Rot", self:GetCaster() )
			local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_pudge/pudge_rot.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
			ParticleManager:SetParticleControl( nFXIndex, 1, Vector( self.rot_radius, 1, self.rot_radius ) )
			self:AddParticle( nFXIndex, false, false, -1, false, false )
		else
			local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_pudge/pudge_rot_recipient.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
			self:AddParticle( nFXIndex, false, false, -1, false, false )
		end

		self:StartIntervalThink( self.rot_tick )
	end
end

--------------------------------------------------------------------------------

function modifier_rotting_flesh:OnDestroy()
	if IsServer() then
		StopSoundOn( "Hero_Pudge.Rot", self:GetCaster() )
	end
end

--------------------------------------------------------------------------------

function modifier_rotting_flesh:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
	}

	return funcs
end

--------------------------------------------------------------------------------

function modifier_rotting_flesh:GetModifierMoveSpeedBonus_Percentage( params )
	return self.rot_slow
end

--------------------------------------------------------------------------------

function modifier_rotting_flesh:GetModifierMagicalResistanceBonus( params )
	return self.resist_reduction
end

--------------------------------------------------------------------------------

function modifier_rotting_flesh:OnIntervalThink()
	if IsServer() then
		local flDamagePerTick = self.rot_tick * (self.rot_damage + self:GetCaster():GetMaxHealth() * self.health_to_damage)

		if self:GetCaster():IsAlive() then
			local damage = {
				victim = self:GetParent(),
				attacker = self:GetCaster(),
				damage = flDamagePerTick,
				damage_type = DAMAGE_TYPE_MAGICAL,
				ability = self:GetAbility()
			}

			ApplyDamage( damage )
		end
	end
end