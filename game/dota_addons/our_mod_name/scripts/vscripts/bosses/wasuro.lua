LinkLuaModifier("modifier_wasuro_sword_slash", "bosses/wasuro.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_wasuro_sword_slash_autocast", "bosses/wasuro.lua", LUA_MODIFIER_MOTION_NONE)

LinkLuaModifier("modifier_wasuro_wild_charge", "bosses/wasuro.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_wasuro_wild_charge_debuff", "bosses/wasuro.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_wasuro_wild_charge_debuff_stun", "bosses/wasuro.lua", LUA_MODIFIER_MOTION_NONE)

LinkLuaModifier("modifier_wasuro_duel_arena_thinker", "bosses/wasuro.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_wasuro_duel_arena_buff", "bosses/wasuro.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_wasuro_duel_arena_debuff", "bosses/wasuro.lua", LUA_MODIFIER_MOTION_NONE)

LinkLuaModifier("modifier_wasuro_blade_cut", "bosses/wasuro.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_wasuro_blade_cut_deductor", "bosses/wasuro.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_wasuro_blade_cut_debuff", "bosses/wasuro.lua", LUA_MODIFIER_MOTION_NONE)

LinkLuaModifier("modifier_wasuro_unbroken_will", "bosses/wasuro.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_wasuro_unbroken_will_buff", "bosses/wasuro.lua", LUA_MODIFIER_MOTION_NONE)

--TODO: particle effects and sounds
-- boss AI

wasuro_sword_slash = class({})

function wasuro_sword_slash:GetCastAnimation()
	return ACT_DOTA_ATTACK2
end

function wasuro_sword_slash:GetPlaybackRateOverride()
	return 0.5
end

function wasuro_sword_slash:OnSpellStart()
	if not IsServer() then return end
	self:RefundManaCost()
	self:EndCooldown()

	local target = self:GetCursorTarget()
	if target then
		self.manualCast = true
		self.manualTarget = target

		ExecuteOrderFromTable({
			UnitIndex = self:GetCaster():entindex(),
			OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
			TargetIndex = target:entindex(),
		})
	end
end

function wasuro_sword_slash:OnUpgrade()
	if not self:GetCaster():HasModifier("modifier_wasuro_sword_slash_autocast") then
		self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_wasuro_sword_slash_autocast", {})

		self.damage = self:GetSpecialValueFor("damage")
		self.duration = self:GetSpecialValueFor("duration")

		self.startRadius = self:GetSpecialValueFor("start_radius")
		self.endRadius = self:GetSpecialValueFor("end_radius")
	end
end

function wasuro_sword_slash:FireProjectile( target )
	local parent = self:GetCaster()
	local direction = target:GetAbsOrigin() - parent:GetAbsOrigin()
	direction.z = 0
	direction = direction:Normalized()

	--use linear proj for finding units in cone shaped area
	local proj = ProjectileManager:CreateLinearProjectile({
		EffectName = "particles/econ/items/sven/sven_ti7_sword/sven_ti7_sword_spell_great_cleave.vpcf",
		Ability = self,
		vSpawnOrigin = parent:GetAbsOrigin(), 
		fStartRadius = self.startRadius,
		fEndRadius = self.endRadius,
		vVelocity = direction * 2000,
		fDistance = 550, --self:GetSpecialValueFor("distance")
		Source = parent,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,

		bHasFrontalCone = true,
		fExpireTime = GameRules:GetGameTime() + 3.0,
	})
end

function wasuro_sword_slash:OnProjectileHit(hTarget, vLocation)
	if not hTarget then return end

	--damage and apply modifier to each unit hit
	ApplyDamage({victim = hTarget, attacker = self:GetCaster(), ability = self, damage = self.damage, damage_type = self:GetAbilityDamageType()})
	hTarget:AddNewModifier(self:GetCaster(), self, "modifier_wasuro_sword_slash", {duration = self.duration})
end


modifier_wasuro_sword_slash_autocast = class({
	IsHidden = function(self) return true end,
	IsPurgable = function(self) return false end,
	OnRefresh = function(self, kv) self:OnCreated() end,
	IsPermanent = function(self) return true end,
	RemoveOnDeath = function(self) return false end,

	DeclareFunctions = function(self) return {MODIFIER_EVENT_ON_ATTACK_LANDED, MODIFIER_EVENT_ON_ORDER,} end,
})

function modifier_wasuro_sword_slash_autocast:OnCreated( kv )
	self.stacks = self:GetAbility():GetSpecialValueFor("blade_cut_stacks")
end

function modifier_wasuro_sword_slash_autocast:OnOrder( keys )
	if not IsServer() then return end

	if not keys.order_type == DOTA_UNIT_ORDER_ATTACK_TARGET then
		if keys.target ~= self:GetAbility().manualTarget then
			self:GetAbility().manualCast = false
		end
	end
end

function modifier_wasuro_sword_slash_autocast:OnAttackLanded( keys )
	local parent = self:GetParent()
	local ability = self:GetAbility()
	local target = keys.target

	if not IsServer() then return end
	if keys.attacker ~= parent then return end

	if not ability:GetAutoCastState() and not ability.manualCast then return end
	if not ability:IsFullyCastable() then return end

	ability:UseResources(true, false, true)
	ability.manualCast = nil
	ability.manualTarget = nil

	--give 3 stacks of blade cut if it is skilled
	if not self:GetCaster():PassivesDisabled() then
		local mod = parent:FindModifierByNameAndCaster("modifier_wasuro_blade_cut", parent)
		if mod then
			for i = 1, self.stacks do
				mod:IncrementStackCount()
				mod:GetParent():AddNewModifier(mod:GetParent(),mod:GetAbility(), "modifier_wasuro_blade_cut_deductor", {duration = mod.duration})
			end
		end
	end

	ability:FireProjectile(target)
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
	if not IsServer() then return end

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
	if not IsServer() then return end

	local ability = self:GetAbility()
	local point = ability.point
	if not point then return end

	local caster = self:GetCaster()
	local speed = ability:GetSpecialValueFor("charge_speed")*0.03
	local damage = ability:GetSpecialValueFor("damage")
	local duration = ability:GetSpecialValueFor("stun_duration")
	local distanceExt = ability:GetSpecialValueFor("extended_distance")

	local maxDistance = (point - caster:GetAbsOrigin()):Length2D()
	local vec = point - caster:GetAbsOrigin()
	vec.z = 0
	vec = vec:Normalized()

	local traveled = 0
	local hit = {}
	Timers:CreateTimer(0.03, function()
		if not caster or caster:IsNull() then print("WASURO NULL") return end

		--find nearby enemies and pull them along
		local units = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 100, ability:GetAbilityTargetTeam(), ability:GetAbilityTargetType(), ability:GetAbilityTargetFlags(), FIND_ANY_ORDER, false)
		for _,unit in pairs(units) do
			if not hit[unit] then
				unit:AddNewModifier(caster, ability, "modifier_wasuro_wild_charge_debuff", {})

				--TODO: 
				--	improve below to be the offset between units location and search origin instead of random
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
			if traveled < maxDistance + distanceExt then
				--TODO: make this smoother
				local temp = speed - (speed*0.03)
				if temp > 100 * 0.03 then
					speed = temp
				end
			else
				for unit,_ in pairs(hit) do
					unit:RemoveModifierByNameAndCaster("modifier_wasuro_wild_charge_debuff", caster)
					unit:AddNewModifier(caster, ability, "modifier_wasuro_wild_charge_debuff_stun", {duration = duration})
					ApplyDamage({victim = unit, attacker = caster, ability = ability, damage = damage, damage_type = ability:GetAbilityDamageType()})
				end
				self:GetCaster():RemoveGesture(ACT_DOTA_CAST_ABILITY_3)
				self:Destroy()
				return
			end
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


modifier_wasuro_wild_charge_debuff_stun = class({
	IsHidden = function(self) return false end,
	IsPurgable = function(self) return false end,
	IsDebuff = function(self) return true end,
	CheckState = function(self) return {[MODIFIER_STATE_STUNNED] = true,} end,
})
---------------------------------------------------------------------------------------------

wasuro_duel_arena = class({})

function wasuro_duel_arena:OnSpellStart()
	local position = self:GetCaster():GetAbsOrigin()
	local duration = self:GetSpecialValueFor("arena_duration")
	CreateModifierThinker(self:GetCaster(), self, "modifier_wasuro_duel_arena_thinker", {duration = duration}, position, self:GetCaster():GetTeamNumber(), false)
end


modifier_wasuro_duel_arena_thinker = class({
	IsPurgable = function(self) return false end,
	IsHidden = function(self) return true end,

	OnDestroy = function(self)
		if IsServer() then self:GetParent():Destroy() end
	end,
})

function modifier_wasuro_duel_arena_thinker:OnCreated( kv )
	local ability = self:GetAbility()

	self.radius = ability:GetSpecialValueFor("arena_radius")
	self.hpDrain = ability:GetSpecialValueFor("hp_drain")
	self.duration = ability:GetSpecialValueFor("arena_duration")

	self.flags = DOTA_UNIT_TARGET_FLAG_NONE
	self.team = DOTA_UNIT_TARGET_TEAM_ENEMY
	self.type = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC

	self:StartIntervalThink(1/30)

	if not IsServer() then return end
	--begin emitting buff aura
	local info = {
		caster = self:GetCaster(),
		auraModifier = "modifier_wasuro_duel_arena_buff",
		ability = self:GetAbility(),
		duration = self.duration,
--		origin = position,
		radius = self.radius,
		unit = self:GetParent(),
		team = DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		type = self.type,
		flags = DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
	}
	EmitAura(info)

	--begin emitting debuff aura
	info.auraModifier = "modifier_wasuro_duel_arena_debuff"
	info.team = DOTA_UNIT_TARGET_TEAM_ENEMY
	EmitAura(info)
end

function modifier_wasuro_duel_arena_thinker:OnIntervalThink()
	if not IsServer() then return end
	local threshold = 1200 + self.radius
	local arena = self:GetParent()
	local units = FindUnitsInRadius(arena:GetTeamNumber(), arena:GetAbsOrigin(), nil, self.radius, self.team, self.type, self.flags, FIND_ANY_ORDER, false)
	self.units = self.units or units

	--add all new units to self table
	for _,v in pairs(units) do
		if not self.units[vlua.find(self.units, v)] then
			table.insert(self.units, v)
		end
	end

	for k,unit in pairs(self.units) do
		if arena:IsNull() or unit:IsNull() then return end
		--get distance between unit and arena
		local distance = (arena:GetAbsOrigin() - unit:GetAbsOrigin()):Length2D()

		--retrap unit if they are not in arena and also not past threshold
		if distance < threshold then
			if distance > self.radius then

				--direction to border of arena
				local dir = unit:GetAbsOrigin() - arena:GetAbsOrigin()
				dir.z = 0
				dir = dir:Normalized()

				--move unit to arena border
				unit:SetAbsOrigin(arena:GetAbsOrigin() + dir * self.radius)
			end
		else
			--otherwise stop tracking unit
			table.remove(self.units, k)
		end
	end
end


modifier_wasuro_duel_arena_buff = class({
	IsPurgable = function(self) return false end,
	IsHidden = function(self) return false end,
	DeclareFunctions = function(self) return {MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE, MODIFIER_EVENT_ON_ATTACK_LANDED,} end,

	OnCreated = function(self, kv)
		self.dmgBuff = self:GetAbility():GetSpecialValueFor("damage_steal")
		self.lifesteal = self:GetAbility():GetSpecialValueFor("lifesteal")
	end,

	OnAttackLanded = function(self, keys )
		if not IsServer() then return end
		if keys.attacker ~= self:GetParent() then return end
		self:GetParent():Lifesteal(keys.target, keys.damage, self.lifesteal)
	end,
	
	GetModifierDamageOutgoing_Percentage = function(self) return self.dmgBuff end,
})


modifier_wasuro_duel_arena_debuff = class({
	IsPurgable = function(self) return false end,
	IsHidden = function(self) return false end,

	DeclareFunctions = function(self) return {MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS, MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,} end,

	OnCreated = function (self, kv)
		self.resistDebuff = (-1) * self:GetAbility():GetSpecialValueFor("resist_debuff")
		self.armorDebuff = (-1) * self:GetAbility():GetSpecialValueFor("armor_debuff")
		self.dmgDebuff = (-1) * self:GetAbility():GetSpecialValueFor("damage_steal")
	end,
	
	GetModifierDamageOutgoing_Percentage = function(self) return self.dmgDebuff end,
	GetModifierPhysicalArmorBonus = function(self) return self.armorDebuff end,
	GetModifierMagicalResistanceBonus = function(self) return self.resistDebuff end,
})

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

	OnCreated = function(self)
		self.atkSpd = self:GetAbility():GetSpecialValueFor("atkspeed_bonus")
		self.duration = self:GetAbility():GetSpecialValueFor("duration")
	end,

	GetModifierAttackSpeedBonus_Constant = function(self)
		if not self:GetCaster():PassivesDisabled() then
			return self:GetStackCount() * self.atkSpd
		end
	end,
})

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

	GetModifierPhysicalArmorBonus = function(self) return self:GetStackCount() * self.armorReduction end,
})

---------------------------------------------------------------------------------------------------------

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
	if not self:GetAbility():IsCooldownReady() or self:GetParent():PassivesDisabled() then return end

	local threshold = self:GetParent():GetMaxHealth() * self.thresholdPct

	--update table
	table.insert(self.hpT, self:GetParent():GetHealth())
	if #self.hpT > self.time then
		table.remove(self.hpT, 1)
	end

	--calculate how much damage has occured in the last self.time seconds
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

	--BUFF wasuro if threshold has been broken
	if diff >= threshold then
		self:GetAbility():UseResources(true, false, true)
		self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_wasuro_unbroken_will_buff", {duration = self.duration})
	end
end


modifier_wasuro_unbroken_will_buff = class({
	IsHidden = function(self) return false end,
	IsPurgable = function(self) return false end,
	OnRefresh = function(self, kv) self:OnCreated() end, 

	DeclareFunctions = function(self) return {MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,} end,
	CheckState = function(self) return {[MODIFIER_STATE_MAGIC_IMMUNE] = true,} end,

	OnCreated = function(self, kv)
		self.atkSpd = self:GetAbility():GetSpecialValueFor("atkspeed_bonus")
	end,

	GetModifierAttackSpeedBonus_Constant = function(self) return self.atkSpd end,
})
