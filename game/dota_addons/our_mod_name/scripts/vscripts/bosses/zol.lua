LinkLuaModifier("modifier_zol_demonic_bolt_debuff", "bosses/zol.lua", LUA_MODIFIER_MOTION_NONE)

LinkLuaModifier("modifier_zol_chaos_will_debuff", "bosses/zol.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_zol_chaos_will_debuff_stun", "bosses/zol.lua", LUA_MODIFIER_MOTION_NONE)

LinkLuaModifier("modifier_zol_chaotic_decay", "bosses/zol.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_zol_chaotic_decay_debuff", "bosses/zol.lua", LUA_MODIFIER_MOTION_NONE)


zol_demonic_bolt = class({})

function zol_demonic_bolt:OnSpellStart()
	local caster = self:GetCaster()

	self.duration = self:GetSpecialValueFor("debuff_duration")
	self.dmg = self:GetSpecialValueFor("damage")
	self.pct = self:GetSpecialValueFor("hp_pct")

	--3 proj fired at random heroes
	local units = FindUnitsInRadius(self:GetCaster():GetTeamNumber(), self:GetCaster():GetAbsOrigin(), nil, self:GetSpecialValueFor("castrange"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	if #units < 1 then return end

	for i=1,3 do
		local target = units[i]
		if not target then
			target = units[1]
		end

		print("tracking proj")
		ProjectileManager:CreateTrackingProjectile({
			Target = target,
			Source = caster,
			Ability = self,	
			EffectName = "",
			iMoveSpeed = 400,
			vSourceLoc= caster:GetAbsOrigin(),
			bDrawsOnMinimap = false,
			bDodgeable = true,
			bIsAttack = false,
			bVisibleToEnemies = true,
			bReplaceExisting = false,
			flExpireTime = GameRules:GetGameTime() + 10,
			bProvidesVision = true,
			iVisionRadius = 400,
			iVisionTeamNumber = caster:GetTeamNumber()
		})
	end
end


--apparently hTarget will always be nil when using CreateTrackingProjectile, need to test
function zol_demonic_bolt:OnProjectileHit( hTarget, vLocation )
	if not IsServer() then return end
	if not hTarget then print("NO TARGET, SHIT IS BROKE") return end

	print("HIT")

	local damage = self.dmg + hTarget:GetMaxHealth() * self.pct

	ApplyDamage({victim = hTarget, attacker = self:GetCaster(), ability = self, damage = damage, damage_type = self:GetAbilityDamageType()})
	hTarget:AddNewModifier(self:GetCaster(), self, "modifier_zol_demonic_bolt_debuff", {duration = self.duration}) 
end


modifier_zol_demonic_bolt_debuff = class({
	IsHidden = function(self) return false end,
	IsPurgable = function(self) return true end,
	GetAttributes = function(self) return MODIFIER_ATTRIBUTE_MULTIPLE end,
	DeclareFunctions = function(self) return {MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,} end,


	OnCreated = function(self, kv)
		self.reduction = self:GetAbility():GetSpecialValueFor("damage_output_reduction")

		--create particles here
	end,

	GetModifierDamageOutgoing_Percentage = function(self)
		return self.reduction
	end,
})

-----------------------------------------------------------------------------------------------------------------------

zol_chaos_will = class({})

function zol_chaos_will:OnSpellStart()
	local duration = self:GetSpecialValueFor("debuff_duration")
	local units = FindUnitsInRadius(self:GetCaster():GetTeamNumber(), self:GetCaster():GetAbsOrigin(), nil, self:GetSpecialValueFor("castrange"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)

	for k,unit in pairs(units) do
		if k > 2 then break end
		unit:AddNewModifier(self:GetCaster(), self, "modifier_zol_chaos_will_debuff", {duration = duration})
	end
end


modifier_zol_chaos_will_debuff = class({
	IsHidden = function(self) return false end,
	IsPurgable = function(self) return true end,
	DeclareFunctions = function(self) return {MODIFIER_EVENT_ON_TAKEDAMAGE,} end,
})

function modifier_zol_chaos_will_debuff:OnCreated( kv )
	self.tick = 0.5

	self.dmg = self:GetAbility():GetSpecialValueFor("damage") * tick
	self.pct = self:GetAbility():GetSpecialValueFor("hp_pct") * 0.01
	self.heal = self:GetAbility():GetSpecialValueFor("heal_pct") * tick
	self.crit = self:GetAbility():GetSpecialValueFor("crit_dmg") * 0.01

	self.isCrit = RollPercentage(self:GetAbility():GetSpecialValueFor("crit_chance"))

	if self.isCrit then
		self.heal = self.heal*2
		self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), "zol_chaos_will_debuff_stun", {duration = self:GetAbility():GetSpecialValueFor("stun_duration")})
	end

	self:StartIntervalThink(tick)
end

function modifier_zol_chaos_will_debuff:OnIntervalThink()
	if not IsServer() then return end

	local mult = 1
	if self.isCrit then
		mult = self.crit
	end
	local damage = self.dmg + self:GetParent():GetMaxHealth() * self.pct * mult

	--apply half magical half physical damage
	local info = {
		victim = self:GetParent(),
		attacker = self:GetCaster(),
		ability = self:GetAbility(),
		damage = damage/2,
		damage_type = DAMAGE_TYPE_PHYSICAL,
	}
	ApplyDamage({info})

	info.damage_type = DAMAGE_TYPE_MAGICAL
	ApplyDamage({info})
end

function modifier_zol_chaos_will_debuff:OnTakeDamage( keys )
	if not IsServer() or not keys.ability then return end
	if keys.attacker ~= self:GetCaster() or keys.ability ~= self:GetAbility() then return end

	local heal = self.heal * keys.damage

	--spell vamp
	self:GetCaster():Heal(heal, self:GetCaster())

	--spell vamp particle
end


modifier_zol_chaos_will_debuff_stun = class({
	IsHidden = function(self) return false end,
	IsPurgable = function(self) return true end,
	CheckState = function(self) return {[MODIFIER_STATE_STUNNED] = true,} end,
})

-----------------------------------------------------------------------------------------------------------------------------------------

zol_chaotic_decay = class({})

function zol_chaotic_decay:GetIntrinsicModifierName()
	return "modifier_zol_chaotic_decay"
end


modifier_zol_chaotic_decay = class({
	IsHidden = function(self) return true end,
	IsPurgable = function(self) return false end,
	IsPermanent = function(self) return true end,
	RemoveOnDeath = function(self) return false end,
})

function modifier_zol_chaotic_decay:OnCreated(kv) 
	self.pct = self:GetAbility():GetSpecialValueFor("hp_dmg") * 0.01
	self.healReduce = self:GetAbility():GetSpecialValueFor("healing_reduction")
	self.duration = self:GetAbility():GetSpecialValueFor("duration")
	self.radius = self:GetAbility():GetSpecialValueFor("search_radius")

	self:StartIntervalThink(0.5)
end


function modifier_zol_chaotic_decay:OnIntervalThink()
	if not IsServer() then return end
	if not self:GetAbility():IsCooldownReady() or self:GetParent():PassivesDisabled() then return end

	--check every units hp and find the one with the highest current hp
	local units = FindUnitsInRadius(self:GetParent():GetTeamNumber(), self:GetParent():GetAbsOrigin(), nil, self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	local target, hp = nil, 0
	for k,v in pairs(units) do
		if v:GetHealth() > hp then
			target, hp = v, v:GetHealth()
		end
	end

	--start cd, damage, debuff
	if target and hp then
		self:GetAbility():UseResources(true, false, true)
		local damage = self.pct * hp *0.01

		ApplyDamage({victim = target, attacker = self:GetCaster(), ability = self:GetAbility(), damage = damage, damage_type = self:GetAbility():GetAbilityDamageType()})
		target:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_zol_chaotic_decay_debuff", {duration = self.duration,})
	end
end


modifier_zol_chaotic_decay_debuff = class({
	IsHidden = function(self) return false end,
	IsPurgable = function(self) return true end,
	DeclareFunctions = function(self) return {MODIFIER_EVENT_ON_HEALTH_GAINED,} end,
	GetAttributes = function(self) return MODIFIER_ATTRIBUTE_MULTIPLE end,

	OnCreated = function(self, kv) 
		self.pct = self:GetAbility():GetSpecialValueFor("hp_dmg") * 0.01
		self.healReduce = self:GetAbility():GetSpecialValueFor("healing_reduction")
		self.duration = self:GetAbility():GetSpecialValueFor("duration")
		self.radius = self:GetAbility():GetSpecialValueFor("search_radius")

		if kv.half then
			self.dontSplode = kv.half

			self.pct = self.pct/2
			self.healReduce = self.healReduce/2
		end
	end,

	OnDestroy = function(self)
		if self.dontSplode then return end

		local units = FindUnitsInRadius(self:GetParent():GetTeamNumber(), self:GetParent():GetAbsOrigin(), nil, self.radius/2, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
		for k,v in pairs(units) do
			if not v == self:GetParent() then
				ApplyDamage({victim = target, attacker = self:GetCaster(), ability = self:GetAbility(), damage = damage, damage_type = self:GetAbility():GetAbilityDamageType()})
				v:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_zol_chaotic_decay_debuff", {duration = self.duration/2, half = true,})
			end
		end
	end,

	OnHealthGained = function(self, keys)
		local newHp = self:GetParent():GetHealth()
		local reduction = self.healReduce * keys.gain
		self:GetParent():SetHealth(newHp - reduction)
	end,
})

-------------------------------------------------------------------------------------------------------------------------------------------

zol_unbroken_will = class({})

function zol_unbroken_will:GetIntrinsicModifierName()
	return "modifier_zol_unbroken_will"
end


modifier_zol_unbroken_will = class({
	IsHidden = function(self) return true end,
	IsPurgable = function(self) return false end,
	IsPermanent = function(self) return true end,
	RemoveOnDeath = function(self) return false end,
	OnRefresh = function(self) self:OnCreated() end,
})


function modifier_zol_unbroken_will:OnCreated( kv )
	if not IsServer() then return end
	self.thresholdPct = self:GetAbility():GetSpecialValueFor("pct_threshold") * 0.01
	self.time = self:GetAbility():GetSpecialValueFor("time_frame")

	self.radius = 700 --self:GetAbility():GetKeyValue("AbilityCastRange")
	self.duration = self:GetAbility():GetSpecialValueFor("duration")

	self.hpT = {self:GetParent():GetHealth(),}
	self:StartIntervalThink(0.5)
end

function modifier_zol_unbroken_will:OnIntervalThink()
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

	if diff >= threshold then
		self:GetAbility():UseResources(false, false, true)
		self:GetParent():GiveMana(self:GetParent():GetMaxMana())
		self:GetParent():Purge(false, true, false, true, false)

		local units = FindUnitsInRadius(int_1, self:GetParent():GetAbsOrigin(), nil, self.radius, int_5, int_6, int_7, FIND_ANY_ORDER, false)
		for k,v in pairs(units) do
			v:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_zol_unbroken_will_debuff", {duration = self.duration})
		end
	end
end


modifier_zol_unbroken_will_debuff = class({
	IsHidden = function(self) return false end,
	IsPurgable = function(self) return true end,
	DeclareFunctions = function(self) return {MODIFIER_STATE_SILENCED,} end,

	OnCreated = function(self, kv)
		self.damage = self:GetAbility():GetSpecialValueFor("damage")
		self:StartIntervalThink(1.0)
	end,

	OnIntervalThink = function(self)
		if not IsServer() then return end
		ApplyDamage({victim = self:GetParent(), attacker = self:GetCaster(), ability = self:GetAbility(), damage = self.damage, damage_type = self:GetAbility():GetAbilityDamageType(),})
	end,
})


zol_rage_of_zol = class({})

function zol_rage_of_zol:OnSpellStart()
	
end

--TODO: Ult, particles, sounds
--[[
ULTIMATE Rage of Zol
Zol will Become Enrage after reaching 70% health 40% and 10% Becoming immnunity to all damage for 10 second, he will start casting
7 Chaos Bolt at random target Location at 400 speed unit heroes that touch those Chaos Bolt will suffer from 100 plus 15% of their max
health in pure damage and slowing them by 60% for 1.5 second, if any heroes touch more than 3 Chaos Bolt durring Rage of Zol they will
take 100% of their max health in damage killing them and not being able to be revive and for every allys dead durring Rage of Zol other
Heroes will lose 6% max health until Zol dies meaning that they cannot regain more health than normal




SPELL 1 Demonic Bolt -- mana cost 95 cooldown 11
Zol will Throw 3 Demonic Bolt at random target
dealing 115 plus 0.4% of the heroes health in pure damage
if there is 3 or less heroes and get damage by 1 or more Demonic Bolt they will do 60% less damage,
the Demonic Bolt will also give Heroes a debuff that reduce both
physical and magical damage dealt by 35% that last 3.5 second

SPELL 2 Chaos Will -- mana cost 140 cooldown 15
Zol will curse 1 or 2 heroes dealing 30 plus 1% of their max health for 50% magical and 50% physical damage and Zol will heal for 35%
of the damage done with Chaos Will, the debuff last 5 second. Chaos Will also got 15% chance to deal 100% more damage and stun Heroes
for 2 second and it will heal him for 70% instead of 35%

Passive 1 Chaotic Decaytion -- cd 20 second
Zol will Target the Hero with the most current Health dealing 45% of it current health in damage and reducing all healing by 85% for 6 second, 
after the duration of the debuff end, it will spread to 2 random heroes 700 range
dealing 15% of their max health in damage and reducing healing by 30% for 4 second

Passive 2 Unbroken Will (Zol)
if Zol take more than 20% of is max health in 7 second he will Curse all enemys dealing 50 damage per second and silencing them for 
4 second and remove all stun and debuff with restoring is mana to full


BOSS Zol Level 16 -xp gain 70% bonus
STATS
range 350
BAT 1.95
life 4700/4700
mana 1000/1000
damage 5-88
armor 8
magic resist 25%
life regeneration 3.8
mana regeneration 4.5
]]