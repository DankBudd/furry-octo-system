LinkLuaModifier("modifier_void_curse", "heroes/gravity_lord.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_void_curse_reduction", "heroes/gravity_lord.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_void_curse_talent", "heroes/gravity_lord.lua", LUA_MODIFIER_MOTION_NONE)


gravity_lord_void_curse = class({})

function gravity_lord_void_curse:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	if target then
		print("---------------------------------")
		print("GetIntellect() "..caster:GetIntellect(), "IsServer() "..IsServer())
		print("---------------------------------")

		local int = caster:GetIntellect()

		local damage = (self:GetSpecialValueFor("int_to_damage")*int*0.01) + self:GetSpecialValueFor("damage")
		local tDur = 0
		if caster:HasTalent("unique_special_bonus_gravity_lord_1") then
			local values = caster:GetTalentValues("unique_special_bonus_gravity_lord_1")
			tDur = values["duration"]
			damage = (int*values["int_to_damage"]0.01) + damage
			
			local units = FindUnitsInRadius(int_1,Vector_2,handle_3,float_4,int_5,int_6,int_7,int_8,bool_9)
			for _,unit in pairs(units) do
				unit:AddNewModifier(caster, self, "modifier_void_curse_talent", {duration = duration, damage = damage, target = target})
			end
		end

		target:AddNewModifier(caster, self, "modifier_void_curse", {damage = damage, duration = self:GetSpecialValueFor("damage_duration")+tDur, tick = self:GetSpecialValueFor("tick_rate")})
		target:AddNewModifier(caster, self, "modifier_void_curse_reduction", {resist = self:GetSpecialValueFor("resist_loss"), degen = self:GetSpecialValueFor("degen"), duration = self:GetSpecialValueFor("debuff_duration")+tDur})
	end
end


modifier_void_curse = class({})

function modifier_void_curse:IsHidden()
	return false
end

function modifier_void_curse:IsPurgable()
	return true
end

function modifier_void_curse:OnCreated( kv )
	self.damage = kv.damage
	self:StartIntervalThink(kv.tick)
end

function modifier_void_curse:OnIntervalThink()
	ApplyDamage({victim = self:GetParent(), attacker = self:GetCaster(), ability = self:GetAbility(), damage = self.damage, damage_type = self:GetAbility():GetAbilityDamageType()})
	--ParticleManager:CreateParticle(string_1,int_2,handle_3)
	--EmitSoundOn(string_1,handle_2)
end


modifier_void_curse_reduction = class({})

function modifier_void_curse_reduction:IsHidden()
	return true
end

function modifier_void_curse_reduction:IsPurgable()
	return true
end

function modifier_void_curse_reduction:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
	}
	return funcs
end

function modifier_void_curse_reduction:OnCreated( kv )
	self.degen = kv.degen*-1
	self.resist = kv.resist*-1
	if self:GetCaster():HasTalent("unique_special_bonus_gravity_lord_1") then
		local values = caster:FindTalentValues("unique_special_bonus_gravity_lord_1")
		self.degen = self.degen + values[3]
		self.resist = self.resist + values[4]
	end
end

function modifier_void_curse_reduction:GetModifierConstantHealthRegen()
	return self.degen
end

function modifier_void_curse_reduction:GetModifierMagicalResistanceBonus()
	return self.resist
end


modifier_void_curse_talent = class({})

function modifier_void_curse_talent:OnCreated( kv )
	local parent = self:GetParent()
	local values = self:GetCaster():FindTalentValues("unique_special_bonus_gravity_lord_1")
	local speed = values[2]*0.03
	self.damage = kv.damage*values[1]
	self:StartIntervalThink(kv.tick)

	self.timer = Timers:CreateTimer(0.03, function()
		if kv.target:IsNull() or parent:IsNull() then return end

		local vec = kv.target:GetAbsOrigin() - parent:GetAbsOrigin()
		if vec:Length2D() > speed then
			parent:SetAbsOrigin(parent:GetAbsOrigin()+vec:Normalized()*speed)
		end
		--if distance between parent and target is greater than 1300 stop
		--
		--
		--end
		return 0.03
	end)
end

function modifier_void_curse_talent:OnDestroy()
	if self.timer then
		Timers:RemoveTimer(self.timer)
	end
end

function modifier_void_curse_talent:OnIntervalThink()
	ApplyDamage({victim = self:GetParent(), attacker = self:GetCaster(), ability = self:GetAbility(), damage = self.damage, damage_type = self:GetAbility():GetAbilityDamageType()})
	--ParticleManager:CreateParticle(string_1,int_2,handle_3)
	--EmitSoundOn(string_1,handle_2)
end


--TODO: increase duration of all stuns and slows by 100% on main target
-- ^stuns done, didnt do slows. not sure how to detect if a modifier applys a slow.

--[[
SPELL Q level needed 1 4 9 15

Void Curse

Curse the enemy dealing damage over time to a target lowering magic resist and reducing life regeneration for the duration

Damage 6 9 12 15 type magical plus 10% of intelligence
Duration 5 6 7 8 second damage every 1 second
life regeneration lost -0.2 -0.3 -0.4 -0.5 per tick of damage
Magic resist lost 0.50% 1% 1.50% 2% per tick of damage
debuff duration 2 second
Cooldown 32 29 26 23
Mana cost 100 130 160 190 plus 1% of max mana


Talent level 10 Upgrade Void Curse
increase damage by 10% of enigma intelligence
increase duration by 2
increase life regeneration lost by 0.3
increase magic resist lost by 1%
mana cost increase by 120

add a new modifier Void Corruption
now damage enemys in a 300 area of effect of the main target only dealing 60% of the damage to them and pulling them to the target
for 100 speed unit and also increase all stun and roots on the main target by 100%]]

gravity_lord_gravity_well = class({})

function gravity_lord_gravity_well:OnSpellStart()
	--create thinker at point
	CreateModifierThinker(self:GetCaster(), self, "gravity_well_thinker", {}, self:GetCursorPosition(), self:GetCaster():GetTeamNumber(), false)
end



gravity_well_thinker = class({})

function gravity_well_thinker:OnCreated( kv )
	self.damage = self:GetSpecialValueFor("damage")

	--particle, sound loop

	self:StartIntervalThink(0.5)
end

function gravity_well_thinker:OnIntervalThink()
	local units = FindUnitsInRadius(int_1,Vector_2,handle_3,float_4,int_5,int_6,int_7,int_8,bool_9)
	for _,unit in pairs(units) do
		ApplyDamage({victim = unit, attacker = self:GetCaster(), ability = self:GetAbility(), damage = self.damage, damage_type = self:GetAbility():GetAbilityDamageType()})
		unit:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_gravity_well_slow", {})
	end

end



modifier_gravity_well_slow = class({})

function modifier_gravity_well_slow:OnCreated( kv )
	self:ForceRefresh()
end

function modifier_gravity_well_slow:OnRefresh( kv )
	self.moveSpeed = self:GetAbility():GetSpecialValueFor("move_slow")
	self.atkSpeed = self:GetAbility():GetSpecialValueFor("atk_slow")
end

function modifier_gravity_well_slow:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_ATTACK_POINT_CONSTANT,
	}
	return funcs
end

function modifier_gravity_well_slow:GetModifierMoveSpeedBonus_Percentage()
	return self.moveSpeed * self:GetStackCount()
end

function modifier_gravity_well_slow:GetModifierAttackSpeedBonus_Constant()
	return self.atkSpeed * self:GetStackCount()
end

--[[SPELL W level needed 1 4 9 15

Gravity Well
Infest the ground with pure energy of gravity dealing damage overtime and slowing attackspeed and movement speed also having
a small chance of stuning the target as well or rooting them

Damage 12 18 24 30 type magical per second
duration 6 second
increase duration by 1 for every 40 inteillgence
Attack slow 2 per damage
Movement slow 1% per damage
chance for roots or stuns 10%
root duration 0.4 0.6 0.8 1
stun duration 0.2 0.3 0.4 0.5
Radius 400
radius increase by 1 for every point of int
Cooldown 38 34 30 26
Mana cost 160 200 240 280 plus 1% of max mana

talent level 10 Upgrade Gravity Well
increase damage by 10
increase the radius by 200
reduce cooldown by 6
increase chance for roots and stuns by 5%
mana cost reduce by 100

add a new modifier Void Gate
now spawn 3 Eidolons they have 50% of engima life and 100% of engima damage with 2.40 BAT they last
60 second, only 6 Eidolons can be alive if here is more than 6 the others will die replacing them
and any enemys inside of Gravity Well will take 15% more damage from enigma spell, Gravity Well gets 30% instead]]