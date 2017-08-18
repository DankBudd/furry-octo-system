LinkLuaModifier("modifier_custom_quas", "heroes/invoker.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_custom_wex", "heroes/invoker.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_custom_exort", "heroes/invoker.lua", LUA_MODIFIER_MOTION_NONE)

LinkLuaModifier("modifier_custom_invoke_death", "heroes/invoker.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_custom_cold_snap", "heroes/invoker.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_custom_cold_snap_stun", "heroes/invoker.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_custom_alacrity", "heroes/invoker.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_custom_alacrity_p", "heroes/invoker.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("custom_sun_strike_thinker", "heroes/invoker.lua", LUA_MODIFIER_MOTION_NONE)


--TODO: make orbs transferable to illusions, volvo doesnt do this but i want to
-- i would have to move particle creation to the modifiers,
-- 

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

--cast passed orb
local function castOrb(ability, name)
	local caster = ability:GetCaster()

	--roll cast animation, left or right hand
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

	--table to store orb particle id's
	caster.oc = caster.oc or {}
	--lazy variable for attach point
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


--debug remove orbs
--	removeAllOrbs(caster)
end

--called when quas wex or exort are upgraded
local function upgradeOrbs(ability, name)
	for k,v in pairs(ability:GetCaster():FindAllModifiersByName("modifier_custom_"..name)) do
		v:ForceRefresh()
	end
end


--------------------------------------------------------------------------

custom_quas = class({})

function custom_quas:OnSpellStart()
	castOrb(self, "quas")
end

function custom_quas:OnUpgrade()
	upgradeOrbs(self, "quas")
end

modifier_custom_quas = class({
	IsHidden = function(self) return false end,
	IsPurgable = function(self) return false end,
	IsDebuff = function(self) return false end,
	RemoveOnDeath = function(self) return false end,
	AllowIllusionDuplicate = function(self) return false end,
	IsPermanent = function(self) return false end,
	GetAttributes = function(self) return MODIFIER_ATTRIBUTE_MULTIPLE + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end,
})

function modifier_custom_quas:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
	}
	return funcs
end

function modifier_custom_quas:OnCreated( kv )
	self.p = self.p or kv.p
	self.regen = self:GetAbility():GetSpecialValueFor("hp_regen")
end

function modifier_custom_quas:OnRefresh( kv )
	self:OnCreated()
end

function modifier_custom_quas:GetModifierConstantHealthRegen()
	return self.regen
end

-------------------------------------------------------------------------

custom_wex = class({})

function custom_wex:OnSpellStart()
	castOrb(self, "wex")
end

function custom_wex:OnUpgrade()
	upgradeOrbs(self, "wex")
end

modifier_custom_wex = class({
	IsHidden = function(self) return false end,
	IsPurgable = function(self) return false end,
	IsDebuff = function(self) return false end,
	RemoveOnDeath = function(self) return false end,
	AllowIllusionDuplicate = function(self) return false end,
	IsPermanent = function(self) return false end,
	GetAttributes = function(self) return MODIFIER_ATTRIBUTE_MULTIPLE + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end,
})

function modifier_custom_wex:OnCreated( kv )
	self.p = self.p or kv.p
	self.atk_speed = self:GetAbility():GetSpecialValueFor("atk_speed")
	self.move_speed = self:GetAbility():GetSpecialValueFor("move_speed")
end

function modifier_custom_wex:OnRefresh( kv )
	self:OnCreated()
end

function modifier_custom_wex:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
	return funcs
end

function modifier_custom_wex:GetModifierAttackSpeedBonus_Constant()
	return self.atk_speed
end

function modifier_custom_wex:GetModifierMoveSpeedBonus_Percentage()
	return self.move_speed
end

--------------------------------------------------------------------------------

custom_exort = class({})

function custom_exort:OnSpellStart()
	castOrb(self, "exort")
end

function custom_exort:OnUpgrade()
	upgradeOrbs(self, "exort")
end

modifier_custom_exort = class({
	IsHidden = function(self) return false end,
	IsPurgable = function(self) return false end,
	IsDebuff = function(self) return false end,
	RemoveOnDeath = function(self) return false end,
	AllowIllusionDuplicate = function(self) return false end,
	IsPermanent = function(self) return false end,
	GetAttributes = function(self) return MODIFIER_ATTRIBUTE_MULTIPLE + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end,
})

function modifier_custom_exort:OnCreated( kv )
	self.p = self.p or kv.p
	self.damage = self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_custom_exort:OnRefresh( kv )
	self:OnCreated()
end

function modifier_custom_exort:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
	}
	return funcs
end

function modifier_custom_exort:GetModifierPreAttack_BonusDamage()
	return self.damage
end

-------------------------------------------------------------------------------------------------

custom_invoke = class({})

function custom_invoke:OnSpellStart()
	local caster = self:GetCaster()
	--reference table, not used in code
	local spells = {
		"cold_snap",
		"ghost_walk",
		"ice_wall",
		"emp",
		"tornado",
		"alacrity",
		"sun_strike",
		"forge_spirit",
		"chaos_meteor",
		"deafening_blast",
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

	--determine which spell held orbs should invoke
	local newSpell
	if quas == 3 then
		newSpell = "cold_snap"
	elseif quas == 2 and wex == 1 then
		newSpell = "ghost_walk"
	elseif quas == 2 and exort == 1 then
		newSpell = "ice_wall"
	elseif wex == 3 then
		newSpell = "emp"
	elseif wex == 2 and quas == 1 then
		newSpell = "tornado"
	elseif wex == 2 and exort == 1 then
		newSpell = "alacrity"
	elseif exort == 3 then
		newSpell = "sun_strike"
	elseif exort == 2 and quas == 1 then
		newSpell = "forge_spirit"
	elseif exort == 2 and wex == 1 then
		newSpell = "chaos_meteor"
	elseif quas == 1 and wex == 1 and exort == 1 then
		newSpell = "deafening_blast"
	end
	
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

	--and oldest spell gets sent to another dimension Kappa

	caster:FindAbilityByName(newSpell):SetLevel(1)
end

function custom_invoke:OnUpgrade()
	self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_custom_invoke_death", {})
end

modifier_custom_invoke_death = class({
	IsHidden = function(self) return true end,
	IsPurgable = function(self) return false end,
	IsDebuff = function(self) return false end,
})

function modifier_custom_invoke_death:OnDeath()
	local caster = self:GetCaster()
	if caster.oc then
		removeAllOrbs(caster)
	end
end

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
})

function modifier_custom_cold_snap:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_TAKEDAMAGE,
	}
	return funcs
end

function modifier_custom_cold_snap:OnCreated( kv )
	local quas = self:GetCaster():FindAbilityByName("custom_quas"):GetLevel()
	if self:GetCaster():HasScepter() then
		quas = quas + 1
	end

	self.duration = self:GetAbility():GetLevelSpecialValueFor("duration", quas)
	self.interval = self:GetAbility():GetLevelSpecialValueFor("interval", quas)
	self.damage = self:GetAbility():GetLevelSpecialValueFor("damage", quas)

	self.stun = self:GetAbility():GetSpecialValueFor("stun_duration")
	self.threshold = self:GetAbility():GetSpecialValueFor("damage_threshold")

	self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_custom_cold_snap_stun", {duration = self.stun})
	
	self.stunCD = true
	self:StartIntervalThink(self.interval)
end

function modifier_custom_cold_snap:OnIntervalThink()
	self.stunCD = false
	self:StartIntervalThink(-1)
end

--TODO:
--Cold Snap does not trigger on self-inflicted damage, and on damage flagged as HP Removal.
function modifier_custom_cold_snap:OnTakeDamage( keys )
	if keys.victim == self:GetParent() and (not self.stunCD) then
		--[[for k,v in pairs(keys) do
			print(k,v)
		end]]
		if keys.damage >= self.threshold then
			--damage
			ApplyDamage({victim = self:GetParent(), attacker = self:GetCaster(), ability = self:GetAbility(), damage = self.damage, damage_type = self:GetAbility():GetAbilityDamageType()})
			--stun
			self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_custom_cold_snap_stun", {duration = self.stun})
			--think
			self.stunCD = true
			self:StartIntervalThink(self.interval)
		end
	end
end

function modifier_custom_cold_snap:GetEffectName()
	return "particles/units/heroes/hero_invoker/invoker_cold_snap_status.vpcf"
end

function modifier_custom_cold_snap:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

modifier_custom_cold_snap_stun = class({
	IsPurgable = function(self) return true end,
	IsHidden = function(self) return false end,
	IsDebuff = function(self) return true end,
})

function modifier_custom_cold_snap_stun:CheckState()
	local state = {
		[MODIFIER_STATE_STUNNED] = true,
		[MODIFIER_STATE_FROZEN] = true,
	}
	return state
end

function modifier_custom_cold_snap_stun:OnCreated( kv )
	EmitSoundOn("Hero_Invoker.ColdSnap.Freeze", self:GetParent())
end

function modifier_custom_cold_snap_stun:GetEffectName()
	return "particles/units/heroes/hero_invoker/invoker_cold_snap.vpcf"
end

function modifier_custom_cold_snap_stun:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_custom_cold_snap_stun:GetStatusEffectName()
	return "particles/status_fx/status_effect_frost.vpcf"
end

function modifier_custom_cold_snap_stun:StatusEffectPriority()
	return 10
end

--[[ use this if MODIFIER_STATE_FROZEN doesnt work
function modifier_custom_cold_snap_stun:OnCreated( kv )
	FreezeAnimation(self:GetParent(), kv.duration) --self:GetDuration()
end
]]
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
})

function modifier_custom_alacrity:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
	}
	return funcs
end

function modifier_custom_alacrity:OnCreated( kv )
	local wex = self:GetCaster():FindAbilityByName("custom_wex"):GetLevel()
	local exort = self:GetCaster():FindAbilityByName("custom_exort"):GetLevel()
	if self:GetCaster():HasScepter() then
		wex = wex + 1
		exort = exort + 1
	end

	self.atkSpeed = self:GetAbility():GetLevelSpecialValueFor("attack_speed", quas)
	self.damage = self:GetAbility():GetLevelSpecialValueFor("damage", exort)
end

function modifier_custom_alacrity:GetModifierAttackSpeedBonus_Constant()
	return self.atkSpeed
end

function modifier_custom_alacrity:GetModifierPreAttack_BonusDamage()
	return self.damage
end

function modifier_custom_alacrity:GetStatusEffectName()
	return "particles/status_fx/status_effect_alacrity.vpcf"
end

function modifier_custom_alacrity:StatusEffectPriority()
	return 10
end

function modifier_custom_alacrity:GetEffectName()
	return "particles/units/heroes/hero_invoker/invoker_alacrity.vpcf"
end

function modifier_custom_alacrity:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

modifier_custom_alacrity_p = class({
	IsHidden = function(self) return true end,
	IsPurgable = function(self) return false end,
	IsDebuff = function (self) return false end,
})

function modifier_custom_alacrity_p:GetEffectName()
	return "particles/units/heroes/hero_invoker/invoker_alacrity_buff.vpcf"
end

function modifier_custom_alacrity_p:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end


--------------------------------------------------------------------------------------------------


custom_sun_strike = class({})

function custom_sun_strike:OnSpellStart()
	local point = self:GetCursorPosition()
	CreateModifierThinker(self:GetCaster(), self:GetAbility(), "custom_sun_strike_thinker", {}, point, self:GetCaster():GetTeamNumber(), false)
end

custom_sun_strike_thinker = class({})

function custom_sun_strike_thinker:OnCreated( kv )
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
end

function custom_sun_strike_thinker:OnIntervalThink()
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
end
