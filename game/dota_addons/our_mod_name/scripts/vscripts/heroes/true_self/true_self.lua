LinkLuaModifier("modifier_true_self", "heroes/true_self/true_self.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_true_self_crit", "heroes/true_self/true_self.lua", LUA_MODIFIER_MOTION_NONE)

--[[
	--not implemented yet--
	main hero becomes immune to damage for channel, can still be stunned/silenced/hex/etc

	--implemented--
	summons a unit that is immensely powerful, units duration is dependent on channel duration

	has a chance for magical splash for % of attack damage
		projectiles that are Msplash will be faster and will release a bolt of lightning upon arrival, providing true sight on and damaging nearby units for the magical 'crit' damage  (zuus bolt, storm overload )

]]

true_self = class({})

function true_self:GetBehavior()
	local behav = DOTA_ABILITY_BEHAVIOR_CHANNELLED + DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_DONT_RESUME_ATTACK + DOTA_ABILITY_BEHAVIOR_DONT_RESUME_MOVEMENT
	return behav
end

function true_self:OnSpellStart()
	local caster = self:GetCaster()

	if caster.unit and not caster.unit:IsNull() then
		caster.unit:RemoveSelf()
		caster.unit = nil
	end
	caster.unit = CreateUnitByName(caster:GetUnitName(), caster:GetAbsOrigin()+caster:GetForwardVector()*100, false, caster, caster, caster:GetTeamNumber())
	caster.unit:SetOwner(caster)
	caster.unit:SetControllableByPlayer(caster:GetPlayerID(), true)

	-- will give true_self abilities later
	for i=0,18 do
		local ability = caster.unit:GetAbilityByIndex(i)
		if ability then
			ability:RemoveSelf()
		end
	end

	-- remove debug items, give moonshards for testing
	-- will later replace with copying casters items
	Timers:CreateTimer(2.1, function()
		for i=0,DOTA_ITEM_MAX-1 do
			local item = caster.unit:GetItemInSlot(i)
			if item then
				item:RemoveSelf()
			end
		end
		caster.unit:AddItem(CreateItem("item_moon_shard", caster.unit, caster.unit))
		caster.unit:AddItem(CreateItem("item_manta", caster.unit, caster.unit))
	end)

	caster.unit:SetCanSellItems(false)
	caster.unit:SetCanDisassemble(false)
	caster.unit:SetHasInventory(false)

	FindClearSpaceForUnit(caster.unit, caster.unit:GetAbsOrigin(), true)
	caster.unit:AddNewModifier(caster, self, "modifier_true_self", {})
	self.duration = 0
end

-- increment duration on each think
function true_self:OnChannelThink(flInterval)
	self.duration = self.duration + flInterval
end

-- on channel end, regardless of interruption, set a lifetime for true_self based on time channeled
function true_self:OnChannelFinish(bInterrupted)
	self:GetCaster().unit:AddNewModifier(self:GetCaster(), self, "modifier_kill", {duration = self.duration})
end

----
----

modifier_true_self = class({})

function modifier_true_self:IsHidden()
	return false
end
function modifier_true_self:IsPurgable()
	return false
end
function modifier_true_self:IsDebuff()
	return false
end
function modifier_true_self:AllowIllusionDuplicate()
	return true
end
function modifier_true_self:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end
function modifier_true_self:GetStatusEffectName()
	return "particles/status_fx/status_effect_ancestral_spirit.vpcf"
end
function modifier_true_self:StatusEffectPriority()
	return 1005
end

function modifier_true_self:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_ATTACK_RECORD,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_EVENT_ON_ATTACK_FAIL,
		MODIFIER_EVENT_ON_TAKEDAMAGE,
		MODIFIER_PROPERTY_EVASION_CONSTANT,
		MODIFIER_PROPERTY_PROJECTILE_SPEED_BONUS,

	}
	return funcs
end

-- prevent them from respawning, give illusion bounty, etc.
function modifier_true_self:OnTakeDamage( event )
	if event.unit == self:GetParent() and not event.unit:IsAlive() then
		event.unit:MakeIllusion()
	end
end

--miss, disjoint, etc
function modifier_true_self:OnAttackFail( event )
	local mods = self:GetParent():FindAllModifiersByName("modifier_true_self_crit")
	for _,mod in pairs(mods) do
		if mod then
			if mod.crit then
				print("FAILED", event.record)
				self.projSpeed = 0
				mod:Destroy()
			end
		end
	end
end

function modifier_true_self:OnCreated( kv )
	self.evasion = self:GetAbility():GetSpecialValueFor("evasion_constant")
	self.critChance = self:GetAbility():GetSpecialValueFor("crit_chance")
	self.critDmg = self:GetAbility():GetSpecialValueFor("crit_damage")*0.01
	self.projSpeed = 0
	self.mult = 1.25 --[[self:GetAbility():GetSpecialValueFor("projectile_speed_mult")]]
end


--pre projectile creation
function modifier_true_self:OnAttackRecord( event )
--	print("NEWLINE", "////////////////", "NEWLINE")
	self.projSpeed = 0
	if RollPercentage(self.critChance) then
		self.projSpeed = self:GetParent():GetProjectileSpeed() * self.mult	
		print("atk","CRIT", event.record,"", self.projSpeed)

		local mod = self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_true_self_crit", {})	
		mod.crit = event.record
	end
end

-- weird event, this runs when any unit anywhere lands an attack
function modifier_true_self:OnAttackLanded( event )
--	PrintTable(event)
	local parent = self:GetParent()
	local attacker = event.attacker
	local target = event.target
	if attacker ~= parent or not target or target:IsOther() then return end

--	print("hit", event.record)
	for _,mod in pairs(self:GetParent():FindAllModifiersByName("modifier_true_self_crit")) do
		if mod then
			if mod.crit then
				print("hit","CRITHIT "..mod.crit,"", self.projSpeed)
				self.projSpeed = 0
				mod:Destroy()

				local ability = self:GetAbility()
				local units = FindUnitsInRadius(parent:GetTeam(), target:GetAbsOrigin(), nil, 325, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE,FIND_CLOSEST, false)
				if #units<1 or not target:IsAlive() then return end

				-- bolt anim
				local unitPos = target:GetAbsOrigin()
				local bolt = ParticleManager:CreateParticle("particles/units/heroes/hero_zuus/zuus_lightning_bolt.vpcf", PATTACH_WORLDORIGIN, units[1])
				ParticleManager:SetParticleControl(bolt, 0, unitPos+Vector(0,0,1000)) --sky position 
				ParticleManager:SetParticleControl(bolt, 1, unitPos) --ground position
				ParticleManager:ReleaseParticleIndex(bolt)

				ParticleManager:ReleaseParticleIndex(ParticleManager:CreateParticle("particles/units/heroes/hero_stormspirit/stormspirit_overload_discharge.vpcf", PATTACH_ABSORIGIN_FOLLOW, unit))

				--mSplash,
				for _,unit in pairs(units) do
					local damage = self.critDmg * parent:GetAverageTrueAttackDamage(unit)
					if unit == units[1] then
						-- damage popup
						parent:PopupNumbers(unit, "damage" , Vector(0,191,255), 1.5, damage, nil, 4)
					
						--true sight
						target:AddNewModifier(parent, self:GetAbility(), "modifier_custom_aura", {
							duration = 3.5,
							radius = 550,
							type = DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC+DOTA_UNIT_TARGET_OTHER,
							team = DOTA_UNIT_TARGET_TEAM_ENEMY,
							activeOnDeath = true,
							removeOnDeath = false,
							auraModifier = "modifier_true_sight"
						})

						AddFOWViewer(parent:GetTeamNumber(), target:GetAbsOrigin(), 550, 3.5, false)
					end
					ApplyDamage({victim = unit, attacker = parent, ability = ability, damage = damage, damage_type = ability:GetAbilityDamageType()})
				end
				break
			end
		end
	end
end

function modifier_true_self:GetModifierEvasion_Constant()
	return self.evasion
end

function modifier_true_self:GetModifierProjectileSpeedBonus()
	return self.projSpeed
end

----
----

modifier_true_self_crit = class({})

function modifier_true_self_crit:IsHidden()
	return true
end

function modifier_true_self_crit:IsPurgable()
	return false
end

function modifier_true_self_crit:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_true_self_crit:OnCreated( kv )
	self:SetDuration(5.0, false)
end