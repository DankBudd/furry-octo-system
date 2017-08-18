LinkLuaModifier("modifier_true_self", "", LUA_MODIFIER_MOTION_NONE)

--[[
	main hero becomes immune to damage for channel, can still be stunned/silenced/hex/etc

	summons a unit that is immensely powerful, units duration is dependent on channel duration
	has a chance for magical splash for % of attack damage
		projectiles that are Msplash will be 1.75x faster and will release a bolt of lightning upon arrival, providing true sight on and damaging nearby units for the magical 'crit' damage  (zuus bolt, storm overload )

]]


true_self = class({})

function true_self:GetBehavior()
	local behav = DOTA_ABILITY_BEHAVIOR_CHANNELLED + DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_DONT_RESUME_ATTACK + DOTA_ABILITY_BEHAVIOR_DONT_RESUME_MOVEMENT
	return behav
end

function true_self:OnSpellStart()
	local caster = self:GetCaster()

	if caster.unit then
		caster.unit:RemoveSelf()
		caster.unit = nil
	end
	caster.unit = CreateUnitByName(caster:GetUnitName(), caster:GetAbsOrigin()+caster:GetForwardVector()*50, false, caster, caster, caster:GetTeamNumber())
	FindClearSpaceForUnit(caster.unit, caster.unit:GetAbsOrigin(), true)
	caster.unit:AddNewModifier(caster, self, "modifier_true_self", {})
end

---------------------------------------------

modifier_true_self = class({})

function modifier_true_self:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_ATTACK_START,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_PROPERTY_EVASION_CONSTANT,
		MODIFIER_PROPERTY_PRE_ATTACK,
		MODIFIER_PROPERTY_PROJECTILE_SPEED_BONUS,
	}
	return funcs
end

function modifier_true_self:OnCreated( kv )
	self.evasion = self:GetSpecialValueFor("evasion_constant")
	self.critChance = self:GetSpecialValueFor("crit_chance")
	self.critDmg = self:GetSpecialValueFor("crit_damage")*0.01
	self.projSpeed = 0
end

function modifier_true_self:OnAttackStart( keys )
	print("onatk_start")
	PrintTable(keys)
	if --[[] self:GetParent():GetTeam() ~= hTarget:GetTeam() and ]]RollPercentage(self.critChance) then
		--increase projectile speed
		self.projSpeed = self:GetAbility():GetSpecialValueFor("projectile_speed_bonus")
	end
end

function modifier_true_self:OnAttackLanded( keys )
	print("onatk_landed")
	PrintTable(keys)
	--roll crit, play anim
	if --[[] self:GetParent():GetTeam() ~= hTarget:GetTeam() and ]]RollPercentage(self.critChance) then

	end
end

function modifier_true_self:OnAttackFail()
end

function modifier_true_self:GetModifierEvasion_Constant()
end


function modifier_true_self:GetModifierProjectileSpeedBonus()
	return self.projSpeed
end

function modifier_true_self:GetModifierPreAttack()
end