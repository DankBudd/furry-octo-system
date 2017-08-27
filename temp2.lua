LinkLuaModifier("modifier_custom_quas", "heroes/invoker.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_custom_wex", "heroes/invoker.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_custom_exort", "heroes/invoker.lua", LUA_MODIFIER_MOTION_NONE)

LinkLuaModifier("modifier_custom_quas_special", "heroes/invoker.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_custom_wex_special", "heroes/invoker.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_custom_wex_special_aura", "heroes/invoker.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_custom_exort_special", "heroes/invoker.lua", LUA_MODIFIER_MOTION_NONE)

LinkLuaModifier("modifier_custom_invoke_death", "heroes/invoker.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_custom_cold_snap", "heroes/invoker.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_custom_cold_snap_stun", "heroes/invoker.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_custom_alacrity", "heroes/invoker.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_custom_alacrity_p", "heroes/invoker.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_custom_sun_strike_thinker", "heroes/invoker.lua", LUA_MODIFIER_MOTION_NONE)

--TODO: make orbs transferable to illusions
-- i would have to move particle creation to the modifiers,

local function removeAllOrbs(c)
	for k,v in pairs(c.oc) do
		ParticleManager:DestroyParticle(v.p, false)
		ParticleManager:ReleaseParticleIndex(v.p)
		v:Destroy()
	end
	c.oc = {}
end

local function cycle(c) c.attachP=c.attachP+1 if c.attachP>3 then c.attachP=1 end end

--------------------------------------------------------------------------
--[[
local function castOrb(ability)
	local name = string.sub(ability:GetName(), 7)
	local caster = ability:GetCaster()

	--roll cast animation
	local random = (true and RandomInt(1,2) == 1) or false
	local handAttach
	if random then
		--left
		caster:StartGesture(ACT_DOTA_OVERRIDE_ABILITY_1)
		handAttach = "attach_attack1"
	else
		--right
		caster:StartGesture(ACT_DOTA_OVERRIDE_ABILITY_2)
		handAttach = "attach_attack2"
	end

	caster.oc = caster.oc or {}
	caster.attachP = caster.attachP or 1

	--setup orb attach point
	local orbAttach = "attach_orb"..#caster.oc+1
	if #caster.oc+1>3 then
		orbAttach = "attach_orb"..caster.attachP
		cycle(caster)

		--remove oldest orb
		ParticleManager:DestroyParticle(caster.oc[3].p, false)
		ParticleManager:ReleaseParticleIndex(caster.oc[3].p)
		caster.oc[3]:Destroy()
		caster.oc[3] = nil
	end

	--create new orb particle
	local p = ParticleManager:CreateParticle("particles/units/heroes/hero_invoker/invoker_"..name.."_orb.vpcf", PATTACH_ROOTBONE_FOLLOW, caster)

	--TODO: need a better way for below
	--shitty solution for making orbs come from hands
	ParticleManager:SetParticleControlEnt(p, 1, caster, PATTACH_POINT_FOLLOW, handAttach, caster:GetAbsOrigin(), false)
	Timers:CreateTimer(0.4, function()
		ParticleManager:SetParticleControlEnt(p, 1, caster, PATTACH_POINT_FOLLOW, orbAttach, caster:GetAbsOrigin(), false)
	end)

	--create new orb modifier, store mod and particle in table
	table.insert(caster.oc, 1, caster:AddNewModifier(caster, ability, "modifier_custom_"..name, {p = p}))
end]]

--TODO: TEST - - - string.sub 7 might need to be 8
local function castOrb(ability)
	local name = string.sub(ability:GetName(), 7)
	local caster = ability:GetCaster()

	--roll cast animation
	local random = (true and RandomInt(1,2) == 1) or false
	local handAttach
	if random then
		--left
		caster:StartGesture(ACT_DOTA_OVERRIDE_ABILITY_1)
		handAttach = "attach_attack1"
	else
		--right
		caster:StartGesture(ACT_DOTA_OVERRIDE_ABILITY_2)
		handAttach = "attach_attack2"
	end

	caster.oc = caster.oc or {}
	caster.attachP = caster.attachP or 1

	--setup orb attach point
	local orbAttach = "attach_orb"..#caster.oc+1
	if #caster.oc+1>3 then
		orbAttach = "attach_orb"..caster.attachP
		cycle(caster)

		--remove oldest orb
		ParticleManager:DestroyParticle(caster.oc[3].p, false)
		ParticleManager:ReleaseParticleIndex(caster.oc[3].p)
		caster.oc[3]:Destroy()
		caster.oc[3] = nil
	end

	--create new orb modifier, store mod
	table.insert(caster.oc, 1, caster:AddNewModifier(caster, ability, "modifier_custom_"..name, {orbAttach = orbAttach}))
end

local function upgradeOrbs(ability)
	local name = string.sub(ability:GetName(), 7)
	for k,v in pairs(ability:GetCaster():FindAllModifiersByName("modifier_custom_"..name)) do
		v:ForceRefresh()
	end
end

--used to easily manage special orb properties
local function manageOrbSpecial(ability)
	local name = string.sub(ability:GetName(), 7)
	local orbs = {q="quas", w="wex", e="exort"}
	--iterate through orbs table
	for _,str in pairs(orbs) do
		--if current orb is not passed orb then decrement
		local orb = (name ~= str and str) or nil
		if orb then
			local mod = ability:GetCaster():FindModifierByName("modifier_custom_"..str.."special")
			if mod then
				mod:DecrementStackCount()
				if mod:GetStackCount() <= 0 then
					mod:Destroy()
				end
			end
		end
	end
	--create or increment new orb
	local newMod = ability:GetCaster():FindModifierByName("modifier_custom_"..name.."special")
	if not newMod then
		newMod = ability:GetCaster():AddNewModifier(ability:GetCaster(), ability, "modifier_custom_"..name.."special", {})
	end
	newMod:IncrementStackCount()
end

--this is gunna have problems with illusions.
--need to actually see results to make this code work
local function createOrbParticle(modifier, orbAttach)
	local name = string.sub(modifier, 17)
	--create new orb particle
	local p = ParticleManager:CreateParticle("particles/units/heroes/hero_invoker/invoker_"..name.."_orb.vpcf", PATTACH_ROOTBONE_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(p, 1, caster, PATTACH_POINT_FOLLOW, orbAttach, caster:GetAbsOrigin(), false)


	return p
end

--------------------------------------------------------------------------

--quas: (water) TODO
custom_quas = class({})

function custom_quas:OnSpellStart()
	castOrb(self)

--	manageOrbSpecial(self)
end

function custom_quas:OnUpgrade()
	upgradeOrbs(self)
end

modifier_custom_quas = class({
	IsHidden = function(self) return false end,
	IsDebuff = function(self) return false end,
	IsPurgable = function(self) return false end,
	IsPermanent = function(self) return false end,
	RemoveOnDeath = function(self) return false end,
	AllowIllusionDuplicate = function(self) return true end,
	OnRefresh = function(self, kv) self:OnCreated() end,
	GetAttributes = function(self) return MODIFIER_ATTRIBUTE_MULTIPLE + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end,

	DeclareFunctions = function(self) return {MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,}end,
	GetModifierConstantHealthRegen = function(self) return self.regen end,

	OnCreated = function(self, kv)
		self.attach = kv.orbAttach
		self.p = self.p or createOrbParticle(self, kv.orbAttach)
		self.regen = self:GetAbility():GetSpecialValueFor("hp_regen")
	end,
})


modifier_custom_quas_special = class({
	IsHidden = function(self) return true end,
	IsPurgable = function(self) return false end,
	IsDebuff = function(self) return false end,
	RemoveOnDeath = function(self) return false end,
	IsPermanent = function(self) return true end,

})

-------------------------------------------------------------------------

--wex: (lightning) slow and mana absorbtion aura
custom_wex = class({})

function custom_wex:OnSpellStart()
	castOrb(self)

	manageOrbSpecial(self)
end

function custom_wex:OnUpgrade()
	upgradeOrbs(self)
end


modifier_custom_wex = class({
	IsHidden = function(self) return false end,
	IsDebuff = function(self) return false end,
	IsPurgable = function(self) return false end,
	IsPermanent = function(self) return false end,
	RemoveOnDeath = function(self) return false end,
	AllowIllusionDuplicate = function(self) return false end,
	OnRefresh = function(self, kv) self:OnCreated() end,

	DeclareFunctions = function(self) return {MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,} end,
	GetAttributes = function(self) return MODIFIER_ATTRIBUTE_MULTIPLE + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end,
	
	GetModifierAttackSpeedBonus_Constant = function(self) return self.atk_speed end,
	GetModifierMoveSpeedBonus_Percentage = function(self) return self.move_speed end,

	OnCreated = function(self, kv)
		self.p = self.p or kv.p
		self.atk_speed = self:GetAbility():GetSpecialValueFor("atk_speed")
		self.move_speed = self:GetAbility():GetSpecialValueFor("move_speed")
	end,
})


modifier_custom_wex_special = class({
	IsHidden = function(self) return true end,
	IsDebuff = function(self) return false end,
	IsPurgable = function(self) return false end,
	RemoveOnDeath = function(self) return false end,
	IsPermanent = function(self) return true end,
	DeclareFunctions = function(self) return {MODIFIER_EVENT_ON_RESPAWN, MODIFIER_EVENT_ON_DEATH,} end,
	OnRefresh = function(self, kv) self:OnCreated() end,

	OnRespawn = function(self) self:OnCreated() end,
	OnDeath = function(self)
		if self.emitter then
			self.emitter:Destroy()
		end
	end,

	OnCreated = function(self, kv)
		local wex = self:GetAbility():GetLevel() + (self:GetCaster():HasScepter() and 1) or 0
		if self.emitter then
			self.emitter:Destroy()
		end
		self.emitter = EmitAura({
			caster = self:GetCaster(),
			auraModifier = "modifier_custom_wex_special_aura",
			ability = self,
			duration = -1,
		--	origin = nil,
			radius = self:GetSpecialLevelValueFor("radius", wex),
			unit = self:GetCaster(),
			team = DOTA_UNIT_TARGET_TEAM_ENEMY,
			type = DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC,
			flags = DOTA_UNIT_TARGET_FLAG_MANA_ONLY,
		})
	end,
})

modifier_custom_wex_special_aura = class({
	IsHidden = function(self) return false end,
	IsPurgable = function(self) return false end,
	IsDebuff = function(self) return true end,
	OnRefresh = function(self, kv) self:OnCreated() end,
	DeclareFunctions = function(self) return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,} end,

	GetModifierMoveSpeedBonus_Percentage = function(self)
		local stacks = self.parentStacks or 1 
		return self.slow * stacks
	end

	OnCreated = function(self, kv)
		local wex = self:GetAbility():GetLevel() + (self:GetCaster():HasScepter() and 1) or 0
		self.tick = 0.25
		self.parentStacks = self:GetCaster():GetModifierStackCount("modifier_custom_wex_special", self:GetCaster())
		self.drain = self:GetAbility():GetLevelSpecialValueFor("flat_mana_absorb_per_second", wex)
		self.creep = (-1) * self:GetAbility():GetLevelSpecialValueFor("pct_creep_reduction", wex)
		self.slow = (-1) * self:GetAbility():GetLevelSpecialValueFor("slow", wex)

		self:StartIntervalThink(self.tick)
	end,

	OnIntervalThink = function(self)
		local drain = self.drain*self:GetStackCount()*self.tick + self.drain * (self:GetParent():IsHero() and 0) or self.creep
		--lower target mana
		self:GetParent():SetMana(self:GetParent():GetMana() - drain)
		--raise caster mana
		self:GetCaster():SetMana(self:GetCaster():GetMana() + drain)
	end,
})

--------------------------------------------------------------------------------

--exort: (fire) stacking dot on attack for %attack_damage per stack, stacks decay over time
custom_exort = class({})

function custom_exort:OnSpellStart()
	castOrb(self)

	manageOrbSpecial(self)
end

function custom_exort:OnUpgrade()
	upgradeOrbs(self)
end

modifier_custom_exort = class({
	IsHidden = function(self) return false end,
	IsDebuff = function(self) return false end,
	IsPurgable = function(self) return false end,
	RemoveOnDeath = function(self) return false end,
	AllowIllusionDuplicate = function(self) return true end,
	OnRefresh = function(self, kv) self:OnCreated() end,

	GetAttributes = function(self) return MODIFIER_ATTRIBUTE_MULTIPLE + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end,
	DeclareFunctions = function(self) return {MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,} end,
	GetModifierPreAttack_BonusDamage = function(self) return self.damage end,

	OnCreated = function(self, kv)
		self.p = self.p or kv.p
		self.damage = self:GetAbility():GetSpecialValueFor("bonus_damage")
	end
})


modifier_custom_exort_special = class({
	IsHidden = function(self) return self:GetCaster() == self:GetParent() end,
	IsDebuff = function(self) return self:GetCaster() ~= self:GetParent() end,
	IsPurgable = function(self) return self:GetCaster() ~= self:GetParent() end,
	RemoveOnDeath = function(self) return self:GetCaster() ~= self:GetParent() end,
	IsPermanent = function(self) return self:GetCaster() ~= self:GetParent() end,
	DeclareFunctions = function(self) return {MODIFIER_EVENT_ON_ATTACK_LANDED,} end,
	OnRefresh = function(self, kv) self:IncrementStackCount() end,

	OnCreated = function(self) 
		self.decay = 0
		self.tick = 0

		if self:GetCaster() == self:GetParent() then return end
		self:StartIntervalThink(0.5) 
	end,

	OnIntervalThink = function(self)
		local exort = self:GetAbility():GetLevel() + (self:GetCaster():HasScepter() and 1) or 0

		--stacks decay over time
		self.decay = self.decay + self.tick
		if self.decay >= self:GetAbility():GetSpecialLevelValueFor("stack_decay_time", exort) then
			self:DecrementStackCount()
			self.decay = 0
		end
		--remove if no stacks
		if self:GetStackCount() <= 0 and self:GetDuration() == -1 then 
			self:SetDuration(self.tick, true)
		end

		local damage = self:GetCaster():GetAttackDamage() * self:GetAbility():GetSpecialLevelValueFor("damage_per_stack", exort) * stacks * 0.01
		ApplyDamage({victim = self:GetParent(), attacker = self:GetCaster(), ability = self:GetAbility(), damage = damage, damage_type = self:GetAbility():GetAbilityDamageType()})
	end,

	OnAttackLanded = function(self, keys)
		if keys.attacker ~= self:GetCaster() then return end
		if self:GetParent():PassivesDisabled() then return end

		keys.target:AddNewModifier(self:GetCaster(), self, "modifier_custom_exort_special", {})
	end,
})

-------------------------------------------------------------------------------------------------

custom_invoke = class({})

function custom_invoke:OnSpellStart()
	local caster = self:GetCaster()
	local spells = {
		 cold_snap = "QQQ",
		ghost_walk = "QQW",
		  ice_wall = "QQE",

		       emp = "WWW",
		   tornado = "WWQ",
		  alacrity = "WWE",

		sun_strike = "EEE",
	  forge_spirit = "EEQ",
	  chaos_meteor = "EEW",

   deafening_blast = "QWE",
	}

	--determine which orbs caster currently has
	local quas = 0
	local wex = 0
	local exort = 0
	for k,v in pairs(caster.oc) do
		local name = string.sub(v:GetName(), 17)

		if name == "quas" then
			quas = quas+1
		elseif name == "wex" then
			wex = wex+1
		elseif name == "exort" then
			exort = exort+1
		end
	end

	--compare orbs to spell table and grab matched spell
	local function grabSpell()
		local combo 
		for spell,str in pairs(spells) do
			local q,w,e = 0,0,0
			for i = 1,string.len(str) do
				local var = string.sub(str,i-1,i)
				if var == "Q" then q=q+1
				elseif var == "W" then w=w+1
				elseif var == "E" then e=e+1
				end
			end
			if quas==q and wex==w and exort==e then
				return spell
			end
		end
	end

	local newSpell = grabSpell()

	if not newSpell then return end
	newSpell = "custom_"..newSpell

	local slot1 = 3
	local slot2 = 4

	---TODO: test code, make swapToEmpty function if it doesnt work
	
	--if spell is already invoked, refund mana, reset cd, and potentially swap skill slots
	if caster:GetAbilityByIndex(slot1):GetName() == newSpell then
		self:RefundManaCost()
		self:EndCooldown()
		return
	elseif caster:GetAbilityByIndex(slot2):GetName() == newSpell then
		self:RefundManaCost()
		self:EndCooldown()
		--this probably wont work, need to swap to empty first
		caster:SwapAbilities(caster:GetAbilityByIndex(slot1):GetName(), caster:GetAbilityByIndex(slot2):GetName(), true, true)
	end

	--swap slots to empty
	local oldSpell = caster:GetAbilityByIndex(slot1):GetName()
	if oldSpell ~= "invoker_empty1" then
		caster:SwapAbilities(oldSpell, "invoker_empty1", false, true)
	else
		oldSpell = nil
	end
	if caster:GetAbilityByIndex(slot2):GetName() ~= "invoker_empty2" then
		caster:SwapAbilities(caster:GetAbilityByIndex(slot2):GetName(), "invoker_empty2", false, true)
	end

	--[[swap spells into appropriate slots. 
	new spell moves to slot 1]]
		caster:SwapAbilities("invoker_empty1", newSpell, false, true)

	--old spell moves to slot 2.
	if oldSpell then
		caster:SwapAbilities("invoker_empty2", oldSpell, false, true)
	end

	caster:FindAbilityByName(newSpell):SetLevel(1)
end

function custom_invoke:OnUpgrade()
	self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_custom_invoke_death", {})
end


modifier_custom_invoke_death = class({
	IsHidden = function(self) return true end,
	IsPurgable = function(self) return false end,
	IsDebuff = function(self) return false end,
	RemoveOnDeath = function(self) return false end,
	IsPermanent = function(self) return true end,
	DeclareFunctions = function(self) return {MODIFIER_EVENT_ON_DEATH,} end,
	OnDeath = function(self) if self:GetCaster().oc then removeAllOrbs(self:GetCaster()) end end,
})

---------------------------------------------------------------------------------

custom_cold_snap = class({})

function custom_cold_snap:OnSpellStart()
	local target = self:GetCursorTarget()
	if target then
		EmitSoundOn("Hero_Invoker.ColdSnap.Cast", caster)
		EmitSoundOn("Hero_Invoker.ColdSnap", target)
		target:AddNewModifier(self:GetCaster(), self, "modifier_custom_cold_snap", {})
	end
end


modifier_custom_cold_snap = class({
	IsPurgable = function(self) return true end,
	IsHidden = function(self) return false end,
	IsDebuff = function(self) return true end,
	DeclareFunctions = function(self) return {MODIFIER_EVENT_ON_TAKEDAMAGE,} end,
	GetEffectName = function(self) return "particles/units/heroes/hero_invoker/invoker_cold_snap_status.vpcf" end,
	GetEffectAttachType = function(self) return PATTACH_ABSORIGIN_FOLLOW end,

	OnCreated = function(self, kv)
		local quas = self:GetCaster():FindAbilityByName("custom_quas"):GetLevel()
		if self:GetCaster():HasScepter() then
			quas = quas + 1
		end

		self.duration = self:GetAbility():GetLevelSpecialValueFor("duration", quas)
		self.interval = self:GetAbility():GetLevelSpecialValueFor("interval", quas)
		self.damage = self:GetAbility():GetLevelSpecialValueFor("damage", quas)
		self.threshold = self:GetAbility():GetSpecialValueFor("damage_threshold")
		self.stun = self:GetAbility():GetSpecialValueFor("stun_duration")

		self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_custom_cold_snap_stun", {duration = self.stun})
		
		self.stunCD = true
		self:StartIntervalThink(self.interval)
	end,

	--TODO: Cold Snap does not trigger on self-inflicted damage, and on damage flagged as HP Removal.
	OnTakeDamage = function(self, keys)
		if keys.victim == self:GetParent() and (not self.stunCD) then
			--[[for k,v in pairs(keys) do print(k,v) end]]
			if keys.damage >= self.threshold then
				ApplyDamage({victim = self:GetParent(), attacker = self:GetCaster(), ability = self:GetAbility(), damage = self.damage, damage_type = self:GetAbility():GetAbilityDamageType()})
				self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_custom_cold_snap_stun", {duration = self.stun})

				self.stunCD = true
				self:StartIntervalThink(self.interval)
			end
		end
	end,

	OnIntervalThink = function(self)
		self.stunCD = false
		self:StartIntervalThink(-1)
	end,
})


modifier_custom_cold_snap_stun = class({
	IsPurgable = function(self) return true end,
	IsHidden = function(self) return false end,
	IsDebuff = function(self) return true end,
	CheckState = function(self) return {[MODIFIER_STATE_STUNNED] = true, [MODIFIER_STATE_FROZEN] = true,} end,
	OnCreated = function(self, kv) EmitSoundOn("Hero_Invoker.ColdSnap.Freeze", self:GetParent()) end,
	
	--[[ use this if MODIFIER_STATE_FROZEN doesnt work
	OnCreated = function(self, kv) FreezeAnimation(self:GetParent(), kv.duration) --self:GetDuration() end,]]

	GetEffectName = function(self) return "particles/units/heroes/hero_invoker/invoker_cold_snap.vpcf" end,
	GetStatusEffectName = function(self) return "particles/status_fx/status_effect_frost.vpcf" end,
	GetEffectAttachType = function(self) return PATTACH_ABSORIGIN_FOLLOW end,
	StatusEffectPriority = function(self) return 10 end,
})

------------------------------------------------------------------------------------

custom_alacrity = class({})

function custom_alacrity:OnSpellStart()
	local target = self:GetCursorTarget()
	if target then
		EmitSoundOn("Hero_Invoker.Alacrity", target)
		target:AddNewModifier(self:GetCaster(), self, "modifier_custom_alacrity", {duration = self:GetSpecialValueFor("duration")})
		target:AddNewModifier(self:GetCaster(), self, "modifier_custom_alacrity_p", {duration = self:GetSpecialValueFor("duration")})
	end
end


modifier_custom_alacrity = class({
	IsPurgable = function(self) return true end,
	IsHidden = function(self) return false end,
	IsDebuff = function(self) return false end,
	DeclareFunctions = function(self) return {MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,} end,
	
	OnCreated = function(self, kv)
		local wex = self:GetCaster():FindAbilityByName("custom_wex"):GetLevel()
		local exort = self:GetCaster():FindAbilityByName("custom_exort"):GetLevel()
		if self:GetCaster():HasScepter() then
			wex = wex + 1
			exort = exort + 1
		end

		self.atkSpeed = self:GetAbility():GetLevelSpecialValueFor("attack_speed", quas)
		self.damage = self:GetAbility():GetLevelSpecialValueFor("damage", exort)
	end,

	GetEffectName = function(self) return "particles/units/heroes/hero_invoker/invoker_alacrity.vpcf" end,
	GetStatusEffectName = function(self) return "particles/status_fx/status_effect_alacrity.vpcf" end,
	GetEffectAttachType = function(self) return PATTACH_OVERHEAD_FOLLOW end,
	StatusEffectPriority = function(self) return 10 end,

	GetModifierAttackSpeedBonus_Constant = function(self) return self.atkSpeed end,
	GetModifierPreAttack_BonusDamage = function(self) return self.damage end,
})


modifier_custom_alacrity_p = class({
	IsHidden = function(self) return true end,
	IsPurgable = function(self) return false end,
	IsDebuff = function (self) return false end,

	GetEffectName = function(self) return "particles/units/heroes/hero_invoker/invoker_alacrity_buff.vpcf" end,
	GetEffectAttachType = function(self) return PATTACH_OVERHEAD_FOLLOW end,
})



--------------------------------------------------------------------------------------------------


custom_sun_strike = class({})

function custom_sun_strike:OnSpellStart()
	local point = self:GetCursorPosition()
	CreateModifierThinker(self:GetCaster(), self:GetAbility(), "modifier_custom_sun_strike_thinker", {}, point, self:GetCaster():GetTeamNumber(), false)
end

modifier_custom_sun_strike_thinker = class({
	IsHidden = function(self) return true end,
	IsPurgable = function(self) return false end,

	OnCreated = function(self, kv)
		local exort = self:GetCaster():FindAbilityByName("custom_exort"):GetLevel()
		if self:GetCaster():HasScepter() then
			exort = exort + 1
		end

		self.radius = self:GetAbility():GetSpecialValueFor("radius")
		self.damage = self:GetAbility():GetLevelSpecialValueFor("damage", exort)

		--particle for casters team
		local p = ParticleManager:CreateParticleForTeam("particles/units/heroes/hero_invoker/invoker_sun_strike_team.vpcf", PATTACH_WORLDORIGIN, caster, caster:GetTeamNumber())
		ParticleManager:SetParticleControl(p, 0, self:GetAbsOrigin())
		--ParticleManager:SetParticleControl(p, 1, Vector(self.radius,0,0))

		EmitSoundOnLocationForAllies(self:GetAbsOrigin(), "Hero_Invoker.SunStrike.Charge", self:GetCaster())

		self:StartIntervalThink(self:GetAbility():GetSpecialValueFor("delay"))
	end,

	OnIntervalThink = function(self)
		local caster = self:GetCaster()
		local ability = self:GetAbility()
		local units = FindUnitsInRadius(caster:GetTeam(), self:GetAbsOrigin(), nil, self.radius, ability:GetAbilityTargetTeam(), ability:GetAbilityTargetType(), ability:GetAbilityTargetFlags(), FIND_ANY_ORDER, false)

		local p = ParticleManager:CreateParticle("particles/units/heroes/hero_invoker/invoker_sun_strike.vpcf", PATTACH_WORLDORIGIN, caster)
		ParticleManager:SetParticleControl(p, 0, self:GetAbsOrigin())
		ParticleManager:SetParticleControl(p, 1, Vector(self.radius,0,0))

		--pretty sure a different sound is played if no hero is hit, but i didnt see a third sound in invokers file so
		--maybe this sound only fires if a hero is hit? 
		EmitSoundOn("Hero_Invoker.SunStrike.Ignite", self)

		for k,v in pairs(units) do
			ApplyDamage({victim = v, attacker = caster, ability = ability, damage = self.damage/#units, damage_type = ability:GetAbilityDamageType()})
		end
		self:Destroy()
	end,
})
