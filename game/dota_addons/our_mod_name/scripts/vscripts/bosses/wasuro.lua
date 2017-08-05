LinkLuaModifier("modifier_wasuro_sword_slash", "bosses/wasuro.lua", LUA_MODIFIER_MOTION_NONE)

LinkLuaModifier("modifier_wasuro_wild_charge", "bosses/wasuro.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_wasuro_wild_charge_debuff", "bosses/wasuro.lua", LUA_MODIFIER_MOTION_NONE)

LinkLuaModifier("wasuro_duel_arena_thinker", "bosses/wasuro.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("wasuro_duel_arena_aura_emitter", "bosses/wasuro.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_wasuro_duel_arena_buff", "bosses/wasuro.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_wasuro_duel_arena_debuff", "bosses/wasuro.lua", LUA_MODIFIER_MOTION_NONE)

LinkLuaModifier("modifier_wasuro_blade_cut", "bosses/wasuro.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_wasuro_blade_cut_deductor", "bosses/wasuro.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_wasuro_blade_cut_debuff", "bosses/wasuro.lua", LUA_MODIFIER_MOTION_NONE)

LinkLuaModifier("modifier_wasuro_unbroken_will", "bosses/wasuro.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_wasuro_unbroken_will_buff", "bosses/wasuro.lua", LUA_MODIFIER_MOTION_NONE)

--[[ TODO:
sword slash is currently not working


wild charge currently moves enemies sporadicly -- potentially fixed, needs testing


most of the abilities are missing particle effects and sounds


need to thoroughly test each ability 

]]


wasuro_sword_slash = class({})

function wasuro_sword_slash:GetCastAnimation()
	return ACT_DOTA_ATTACK2
end

function wasuro_sword_slash:GetPlaybackRateOverride()
	return 0.5
end

function wasuro_sword_slash:OnSpellStart()
	local target = self:GetCursorTarget()
	self.manualCast = true

	ExecuteOrderFromTable({
		UnitIndex = self:GetCaster():entindex(),
		OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
		TargetIndex = target:entindex(),
	})
end


modifier_wasuro_sword_slash_autocast = class({
	IsHidden = function(self) return true end,
	IsPurgable = function(self) return false end,
	OnRefresh = function(self, kv) self:OnCreated() end,

	DeclareFunctions = function(self) return {MODIFIER_EVENT_ON_ATTACK_LANDED,} end,
})

function modifier_wasuro_sword_slash_autocast:OnCreated( kv )
	self.damage = self:GetSpecialValueFor("damage")
	self.hpPct = self:GetSpecialValueFor("damage_health_pct")
	self.duration = self:GetSpecialValueFor("duration")
	self.stacks = self:GetAbility():GetSpecialValueFor("blade_cut_stacks")
end

function modifier_wasuro_sword_slash_autocast:OnAttackLanded( keys )
	local target = keys.target
	if not target then return end

	if not self:GetAbility():GetAutoCastState() and not self:GetAbility().manualCast then return end

	self.manualCast = nil

	--give 3 stacks of blade cut if it is skilled
	if IsServer() then
		if not self:GetCaster():PassivesDisabled() then
			local mod = self:GetParent():FindModifierByNameAndCaster("modifier_wasuro_blade_cut", self:GetParent())
			if mod then
				for i = 1, self.stacks do
					mod:IncrementStackCount()
					mod:GetParent():AddNewModifier(mod:GetParent(),mod:GetAbility(), "modifier_wasuro_blade_cut_deductor", {duration = mod.duration})
				end
			end
		end
	end

	--particles/econ/items/sven/sven_ti7_sword/sven_ti7_sword_spell_great_cleave.vpcf
	--particles/units/heroes/hero_queenofpain/queen_screem_of_pain.vpcf

	--this is super fucking weird
	-- range of projectile seems to be undefineable, perhaps its based on start and end radius
	-- might be missing some info in table
	--TODO:fix it

	local direction = target:GetAbsOrigin() - self:GetAbsOrigin()
	direction.z = 0
	direction = vec:Normalized()

	--use linear proj for finding units in cone shaped area
	local proj = ProjectileManager:CreateLinearProjectile({
		EffectName = "particles/econ/items/sven/sven_ti7_sword/sven_ti7_sword_spell_great_cleave.vpcf",
		Ability = self,
		vSpawnOrigin = self:GetParent():GetAbsOrigin(), 
		fStartRadius = self:GetSpecialValueFor("start_radius"),
		fEndRadius = self:GetSpecialValueFor("end_radius"),
		vVelocity = direction * 2000,
		fDistance = 550, --self:GetSpecialValueFor("distance")
		Source = self:GetParent(),
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,

		bHasFrontalCone = true,
		fExpireTime = GameRules:GetGameTime() + 3.0,
	})
end

--not entirely sure if i can do OnProjectileHit with a modifier
-- might resort to making my own cone shaped targeting thing
function modifier_wasuro_sword_slash_autocast:OnProjectileHit(hTarget, vLocation)
	if not hTarget then return end
	print(hTarget:GetName())

	--damage and apply modifier to each unit hit
	ApplyDamage({victim = hTarget, attacker = self:GetCaster(), ability = self, damage = self.damage, damage_type = self:GetAbilityDamageType()})
	hTarget:AddNewModifier(self:GetCaster(), self, "modifier_wasuro_sword_slash", {duration = self:GetSpecialValueFor("duration")})
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

--potential issues with non hero units? i dont think GetMaxHealth works on them.
--fix with GetHealth() + GetHealthDeficit() ???
function modifier_wasuro_sword_slash:OnIntervalThink()
	local damage = 1 + (self.pct*self:GetParent():GetMaxHealth()*0.01)
	ApplyDamage({victim = self:GetParent(), attacker = self:GetCaster(), ability = self:GetAbility(), damage = damage, damage_type = self:GetAbility():GetAbilityDamageType()})
end

---------------------------------------------------------------------------------------------------

wasuro_wild_charge = class({})

function wasuro_wild_charge:OnChannelFinish(bInterrupted)
	if bInterrupted then return end
	self:GetCaster():StartGesture(ACT_DOTA_CAST_ABILITY_3)
	self.point = self:GetCursorPosition()
	self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_wasuro_wild_charge", {})
end


modifier_wasuro_wild_charge = class({
	IsHidden = function(self) return false end,
	IsPurgable = function(self) return false end,
	IsDebuff = function(self) return false end,
	CheckState = function(self) return {[MODIFIER_STATE_INVULNERABLE] = true, [MODIFIER_STATE_NO_UNIT_COLLISION] = true, [MODIFIER_STATE_COMMAND_RESTRICTED] = true, [MODIFIER_STATE_DISARMED] = true,} end,
})

function modifier_wasuro_wild_charge:OnCreated( kv )
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	local speed = ability:GetSpecialValueFor("charge_speed")*0.03
	local damage = ability:GetSpecialValueFor("damage")

	local point = ability.point
	if not point then return end

	local maxDistance = (point - caster:GetAbsOrigin()):Length2D() + ability:GetSpecialValueFor("extended_distance")
	local vec = point - caster:GetAbsOrigin()
	vec.z = 0
	vec = vec:Normalized()

	--double check if this is needed, i think the issue was fixed with MODIFIER_STATE_DISARMED
	caster:SetForwardVector(vec)

	local traveled = 0
	local hit = {}
	Timers:CreateTimer(0.03, function()
		if not caster or caster:IsNull() then print("WASURO NULL") return end

		--find nearby enemies and pull them along
		local units = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 100, ability:GetAbilityTargetTeam(), ability:GetAbilityTargetType(), ability:GetAbilityTargetFlags(), FIND_ANY_ORDER, false)
		for _,unit in pairs(units) do
			if not hit[unit] then
				unit:AddNewModifier(caster, ability, "modifier_wasuro_wild_charge_debuff", {})

				--store random vec for consistant positioning during pull along
				hit[unit] = RandomVector(75)
			end
		end

		--move caster forward
		caster:SetAbsOrigin(caster:GetAbsOrigin() + vec * speed)

		--pull enemies along, skewer style
		for unit,vec in pairs(hit) do
			if not unit:IsNull() and unit:IsAlive() then
				unit:SetAbsOrigin((caster:GetAbsOrigin()+vec) + caster:GetForwardVector() * 150)
			else
				table.remove(hit, unit)
			end
		end

		--end charge
		traveled = traveled + speed
		if traveled >= maxDistance then
			for _,v in pairs(hit) do
				v:RemoveModifierByNameAndCaster("modifier_wasuro_wild_charge_debuff", caster)
				ApplyDamage({victim = v, attacker = caster, ability = ability, damage = damage, damage_type = ability:GetAbilityDamageType()})
			end
			--TODO: double check this is what i want
			self:GetCaster():StartGesture(ACT_DOTA_CAST_ABILITY_3_END)

			self:Destroy()
			return
		end
		--continue charge
		return 0.03
	end)
end


modifier_wasuro_wild_charge_debuff = class({
	IsHidden = function(self) return false end,
	IsPurgable = function(self) return false end,
	IsDebuff = function(self) return true end,
	RemoveOnDeath = function(self) return true end,
	CheckState = function(self) return {[MODIFIER_STATE_COMMAND_RESTRICTED] = true, [MODIFIER_STATE_NO_UNIT_COLLISION] = true,} end,
})


---------------------------------------------------------------------------------------------

wasuro_duel_arena = class({})

function wasuro_duel_arena:OnSpellStart()
	local position = self:GetCaster():GetAbsOrigin()
	local duration = self:GetSpecialValueFor("arena_duration")
	CreateModifierThinker(self:GetCaster(), self, "wasuro_duel_arena_thinker", {duration = duration}, position, self:GetCaster():GetTeamNumber(), false)
	CreateModifierThinker(self:GetCaster(), self, "wasuro_duel_arena_aura_emitter", {duration = duration}, position, self:GetCaster():GetTeamNumber(), false)
end


wasuro_duel_arena_aura_emitter = class({
	IsPurgable = function(self) return false end,
	IsHidden = function(self) return true end,

	IsAuraActiveOnDeath = function(self) return false end,
	GetAuraSearchFlags = function(self) return self.flags end,
	GetAuraSearchTeam = function(self) return self.team end,
	GetAuraSearchType = function(self) return self.type end,
	GetModifierAura = function(self) return "modifier_wasuro_duel_arena_buff" end,
	GetAuraRadius = function(self) return self.radius end,
})

function wasuro_duel_arena_aura_emitter:OnCreated(kv)
	local ability = self:GetAbility()
	self.radius = ability:GetSpecialValueFor("arena_radius") 
	self.flags = DOTA_UNIT_TARGET_FLAG_NONE
	self.team = ability:GetAbilityTargetTeam()
	self.type = ability:GetAbilityTargetType()
end


wasuro_duel_arena_thinker = class({
	IsPurgable = function(self) return false end,
	IsHidden = function(self) return true end,

	IsAuraActiveOnDeath = function(self) return false end,
	GetAuraSearchFlags = function(self) return self.flags end,
	GetAuraSearchTeam = function(self) return self.team end,
	GetAuraSearchType = function(self) return self.type end,
	GetModifierAura = function(self) return "modifier_wasuro_duel_arena_debuff" end,
	GetAuraRadius = function(self) return self.radius end,
})

function wasuro_duel_arena_thinker:OnCreated( kv )
	local ability = self:GetAbility()

	self.radius = ability:GetSpecialValueFor("arena_radius")
	self.hpDrain = ability:GetSpecialValueFor("hp_drain")
	self.duration = ability:GetSpecialValueFor("arena_duration")

	self.flags = DOTA_UNIT_TARGET_FLAG_NONE
	self.team = ability:GetAbilityTargetTeam()
	self.type = ability:GetAbilityTargetType()

	self:StartIntervalThink(0.5) -- 1/30
end

--ensure every unit who entered arena is still inside arena. 
--but if they move more than 1200 units away between thinks, dont re-trap them)
function wasuro_duel_arena_thinker:OnIntervalThink()
	local threshold = 1200 + self.radius
	local units = FindUnitsInRadius(self:GetParent():GetTeam(), self:GetParent():GetAbsOrigin(), nil, self.radius, self.team, self.type, self.flags, FIND_ANY_ORDER, false)
	self.units = self.units or units

	for _,v in pairs(units) do
		--add all new units to self table
		if not self.units[vlua.find(self.units, v)] then
			table.insert(self.units, v)
		end
	end

	for k,unit in pairs(self.units) do
		--check distance between unit and arena
		local distance = (self:GetParent():GetAbsOrigin() - unit:GetAbsOrigin()):Length2D()
	--	print("unit: "..unit:GetName(), "distance: "..tostring(distance))

		if distance < threshold then
			if distance > self.radius then
				--retrap unit if they are not in arena
				FindClearSpaceForUnit(unit, self:GetParent():GetAbsOrigin()+RandomVector(100), false)
			end
		else
			--stop tracking unit
			table.remove(self.units, k)
		end
	end
end


modifier_wasuro_duel_arena_buff = class({
	IsPurgable = function(self) return false end,
	IsHidden = function(self) return false end,
})

function modifier_wasuro_duel_arena_buff:OnCreated( kv )
	self.dmgBuff = 100 + self:GetAbility():GetSpecialValueFor("dmg_buff")
	self.lifesteal = self:GetAbility():GetSpecialValueFor("lifesteal")
end

function modifier_wasuro_duel_arena_buff:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
	return funcs
end

function modifier_wasuro_duel_arena_buff:GetModifierDamageOutgoing_Percentage()
	return self.dmgBuff
end

function modifier_wasuro_duel_arena_buff:OnAttackLanded( keys )
	if keys.attacker ~= self:GetParent() then return end

	self:GetParent():Lifesteal(keys.victim, keys.dmg, self.lifesteal)
end


modifier_wasuro_duel_arena_debuff = class({
	IsPurgable = function(self) return false end,
	IsHidden = function(self) return false end,
})

function modifier_wasuro_duel_arena_debuff:OnCreated( kv )
	self.resistDebuff = (-1) * self:GetAbility():GetSpecialValueFor("resist_debuff")
	self.armorDebuff = (-1) * self:GetAbility():GetSpecialValueFor("armor_debuff")
	self.dmgDebuff = 100 - self:GetAbility():GetSpecialValueFor("damage_debuff")
end

function modifier_wasuro_duel_arena_debuff:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
	}
	return funcs
end

function modifier_wasuro_duel_arena_debuff:GetModifierDamageOutgoing_Percentage()
	return self.dmgDebuff
end

function modifier_wasuro_duel_arena_debuff:GetModifierPhysicalArmorBonus()
	return self.armorDebuff
end

function modifier_wasuro_duel_arena_debuff:GetModifierMagicalResistanceBonus()
	return self.resistDebuff
end

-----------------------------------------------------------------------------------------------------------------------------------------------

wasuro_blade_cut = class({})

function wasuro_blade_cut:GetIntrinsicModifierName()
	return "modifier_wasuro_blade_cut"
end

modifier_wasuro_blade_cut = class({
	IsHidden = function(self) return (self:GetStackCount() == 0) end,
	IsPurgable = function(self) return false end,
	IsDebuff = function(self) return false end,
	IsPermanent = function(self) return true end,
	RemoveOnDeath = function(self) return false end,

	AllowIllusionDuplicate = function(self) return true end,
	OnRefresh = function(self, kv) self:OnCreated() end,
	GetAttributes = function(self) return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end,
	DeclareFunctions = function(self) return {MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, MODIFIER_EVENT_ON_ATTACK_LANDED} end,
})

function modifier_wasuro_blade_cut:OnCreated( kv )
	self.atkSpd = self:GetAbility():GetSpecialValueFor("atkspeed_bonus")
	self.duration = self:GetAbility():GetSpecialValueFor("duration")
end

function modifier_wasuro_blade_cut:OnAttackLanded( keys )
	if not keys.target then return end
	if keys.attacker ~= self:GetParent() then return end
	if self:GetParent():PassivesDisabled() then return end

	--buff self
	self:IncrementStackCount()
	self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_wasuro_blade_cut_deductor", {duration = self.duration})

	--debuff target
	if IsServer() then
		local mod = keys.target:FindModifierByNameAndCaster("modifier_wasuro_blade_cut_debuff", self:GetCaster())
		if not mod then
			mod = keys.target:AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_wasuro_blade_cut_debuff", {duration = self.duration})
		end
		mod:IncrementStackCount()
		mod:ForceRefresh()
	end
end

function modifier_wasuro_blade_cut:GetModifierAttackSpeedBonus_Constant()
	if self:GetCaster():PassivesDisabled() then return end

	return self:GetStackCount() * self.atkSpd
end


modifier_wasuro_blade_cut_deductor = class({
	IsHidden = function(self) return true end,
	IsPurgable = function(self) return false end,
	IsDebuff = function(self) return false end,
	GetAttributes = function(self) return MODIFIER_ATTRIBUTE_MULTIPLE end,

	OnDestroy = function(self)
		if IsServer() then
			local mod = self:GetParent():FindModifierByNameAndCaster("modifier_wasuro_blade_cut", self:GetCaster())
			if mod then
				mod:DecrementStackCount()
			end
		end
	end,
})


modifier_wasuro_blade_cut_debuff = class({
	IsHidden = function(self) return false end,
	IsPurgable = function(self) return true end,
	IsDebuff = function(self) return true end,

	OnRefresh = function(self) self:OnCreated() end,
	DeclareFunctions = function(self) return {MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,} end,

	OnCreated = function(self, kv)
		self.armorReduction = (-1) * self:GetAbility():GetSpecialValueFor("armor_reduction")
	end,

	GetModifierPhysicalArmorBonus = function(self)
		return self:GetStackCount() * self.armorReduction
	end,
})


wasuro_unbroken_will = class({})

function wasuro_unbroken_will:GetIntrinsicModifierName()
	return "modifier_wasuro_unbroken_will"
end


modifier_wasuro_unbroken_will = class({
	IsHidden = function(self) return true end,
	IsPurgable = function(self) return false end,

	OnRefresh = function(self) self:OnCreated() end,
})

function modifier_wasuro_unbroken_will:OnCreated( kv )
	self.thresholdPct = self:GetAbility():GetSpecialValueFor("pct_threshold") * 0.01
	self.time = self:GetAbility():GetSpecialValueFor("time_frame")
	self.duration = self:GetAbility():GetSpecialValueFor("duration")

	if not IsServer() then return end

	self.hpT = {self:GetParent():GetHealth(),}
	self.tick = 0
	self:StartIntervalThink(0.5)
end

function modifier_wasuro_unbroken_will:OnIntervalThink()
	if not IsServer() then return end
	--calc threshold
	local threshold = self:GetParent():GetMaxHealth() * self.thresholdPct

	--insert current hp to table
	local hp = self:GetParent():GetHealth()
	table.insert(self.hpT, hp)

	--remove oldest hp record
	if #self.hpT > self.time then
		table.remove(self.hpT, 1)
	end

	if not self:GetAbility():IsCooldownReady() then return end
	if self:GetParent():PassivesDisabled() then return end

	--calculate how much damage has occured
	local diff = 0
	local temp
	for k,v in pairs(self.hpT) do
		if k == 1 then
			temp = v
		else
			temp = self.hpT[k-1]
		end

		temp = temp - v
		diff = diff + temp
	end

	--BUFF parent if threshold has been broken
	if diff >= threshold then
		--cooldown
		self:GetAbility():UseResources(true, false, true)

		--buff
		self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_wasuro_unbroken_will_buff", {duration = self.duration})
	end
end


modifier_wasuro_unbroken_will_buff = class({
	IsHidden = function(self) return false end,
	IsPurgable = function(self) return false end,
	OnRefresh = function(self, kv) self:OnCreated() end, 

	DeclareFunctions = function(self) return {MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,} end,
	CheckState = function(self) return {[MODIFIER_STATE_MAGIC_IMMUNE] = true,} end,
})

function modifier_wasuro_unbroken_will_buff:OnCreated( kv )
	self.atkSpd = self:GetAbility():GetSpecialValueFor("atkspeed_bonus")

end

function modifier_wasuro_unbroken_will_buff:GetModifierAttackSpeedBonus_Constant()
	return self.atkSpd
end
