LinkLuaModifier("modifier_frost_arrows", "heroes/hero_drow/frost_arrows_lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_frost_arrows_slow", "heroes/hero_drow/frost_arrows_lua", LUA_MODIFIER_MOTION_NONE)

----
local function IsFrostAttack( mod, id )
	mod.frost = mod.frost or {}
	print(id, mod.frost[id])
	return mod.frost[id] or false
end
local function SetFrostAttack( mod, id )
	if mod.autoCast or id == "-1" then
		mod.frost = mod.frost or {}
		table.insert(mod.frost, id, true)
	end
end
-----

frost_arrows_lua = class({})

function frost_arrows_lua:GetIntrinsicModifierName()
	return "modifier_frost_arrows"
end

function frost_arrows_lua:OnSpellStart()
	if IsServer() then
		local target = self:GetCursorTarget()
		local caster = self:GetCaster()
		if target and IsValidEntity(target) then
			local spoofedRecord = "-1"
			SetFrostAttack(caster:FindModifierByNameAndCaster(self:GetIntrinsicModifierName(), caster), spoofedRecord)
			caster:MoveToTargetToAttack(target)
			self:RefundManaCost()
		end
	end
end

modifier_frost_arrows = class({})

function modifier_frost_arrows:IsHidden()
	return true
end

function modifier_frost_arrows:IsPurgable()
	return false
end

function modifier_frost_arrows:RemoveOnDeath()
	return false
end

function modifier_frost_arrows:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_ATTACK_START,
		MODIFIER_EVENT_ON_ATTACK,
		MODIFIER_EVENT_ON_ATTACK_RECORD,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
	return funcs
end

function modifier_frost_arrows:OnCreated( kv )
	self:StartIntervalThink(0.03)
end

function modifier_frost_arrows:OnIntervalThink()
	if IsServer() then
		if not self:GetAbility() or not self:GetAbility():GetAutoCastState() then
			self.autoCast = nil
		else
			self.autoCast = true
		end
	end
end

--projectile might get weird with deso and what-not
--needs further testing
function modifier_frost_arrows:OnAttackStart( keys )
	local parent = self:GetParent()
	local name = parent:GetRangedProjectileName()
	if parent == keys.attacker then
		if not self.original then
			self.original = name
		end
		if self.autoCast or IsFrostAttack(self, "-1") then
			parent:SetRangedProjectileName("particles/units/heroes/hero_drow/drow_frost_arrow.vpcf")
		else
			if name ~= self.original then
				parent:SetRangedProjectileName(self.original)
			end
		end
	end
end

function modifier_frost_arrows:OnAttackRecord( keys )
	if self:GetParent() == keys.attacker then
		SetFrostAttack(self, keys.record)
	end
end

function modifier_frost_arrows:OnAttack( keys )
	local parent = self:GetParent()
	if IsFrostAttack(self, keys.record) or IsFrostAttack(self, "-1") then
		if IsServer() then
			local ability = self:GetAbility()
			if ability then
				parent:SpendMana(ability:GetManaCost(-1), ability)
			end
		end
		EmitSoundOn("Hero_DrowRanger.FrostArrows", parent)
	end
end

function modifier_frost_arrows:OnAttackLanded( keys )
	local parent = self:GetParent()
	if parent == keys.attacker then
		if IsFrostAttack(self, keys.record) or IsFrostAttack(self, "-1") then
			--clear attack record from table
			table.remove(self.frost, keys.record)
			table.remove(self.frost, "-1")
			--splash attack
			local ability = self:GetAbility()
			local radius = ability:GetSpecialValueFor("radius")
			local units = FindUnitsInRadius(parent:GetTeam(), keys.target:GetAbsOrigin(), nil, radius, ability:GetAbilityTargetTeam(), ability:GetAbilityTargetType(), ability:GetAbilityTargetFlags(), FIND_ANY_ORDER, false)
			for _,unit in pairs(units) do
				ApplyDamage({victim = unit, attacker = parent, ability = ability, damage = ability:GetAbilityDamage(), damage_type = ability:GetAbilityDamageType()})
				unit:AddNewModifier(parent, ability, "modifier_frost_arrows_slow", {duration = (unit:IsHero() and ability:GetSpecialValueFor("duration") or ability:GetSpecialValueFor("duration_creep"))})
			end
		end
	end
end

modifier_frost_arrows_slow = class({})

function modifier_frost_arrows_slow:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
	return funcs
end

function modifier_frost_arrows_slow:OnCreated( kv )
	self.slow = self:GetAbility():GetSpecialValueFor("slow") * -1

	self.pfx = ParticleManager:CreateParticle("particles/generic_gameplay/generic_slowed_cold.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, self:GetParent())
	ParticleManager:SetParticleControlEnt(self.pfx, 0, self:GetParent(), PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
end

function modifier_frost_arrows_slow:OnDestroy()
	ParticleManager:DestroyParticle(self.pfx, false)
	ParticleManager:ReleaseParticleIndex(self.pfx)
	self.pfx = nil
end

function modifier_frost_arrows_slow:GetModifierMoveSpeedBonus_Percentage()
	return self.slow
end