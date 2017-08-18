LinkLuaModifier("modifier_wall_degeneration", "scripts/vscripts/heroes/squab_concepts/castle_walls.lua", LUA_MODIFIER_MOTION_NONE)

local function DestroyWalls(unit, forceDestroy)
	if IsServer() then
		if unit:GetHealth() <= 0 or forceDestroy then
			if unit.walls then
				for k,v in pairs(unit.walls) do
					if v and not v:IsNull() then
						v:RemoveSelf()
					end
				end
			end
			unit:RemoveSelf()
		end
	end
end

--------------------------------------------------------------------

castle_walls = class({})

function castle_walls:GetBehavior()
	local behav = DOTA_ABILITY_BEHAVIOR_CHANNELLED + DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_DONT_RESUME_ATTACK
	return behav
end

function castle_walls:GetChannelTime()
	return 3.0
end

function castle_walls:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	local width = self:GetSpecialValueFor("wall_width")
	local length = self:GetSpecialValueFor("wall_length")
	local health = self:GetSpecialValueFor("wall_health")

 	--numWalls must be a whole number
	local numWalls = length/width

 	--make walls
	self.walls = {}
	for i=1,numWalls do
		table.insert(self.walls, CreateUnitByName("castle_wall", point, false, caster, caster, caster:GetTeamNumber()))
	end

	ScreenShake(self.walls[1]:GetCenter(), --Vector
				900, --amplitude
				2, --frequency
				3.0, --duration
				1000, --radius
				0, -- ecommand(0=start, 1=stop)
				true) --airshake

--[[print("pre sound")
	EmitSoundOn("CastleWalls.Raise", self.walls[1])
	print("post sound")]]
	
	--placed here to make use of "width"
	local function RaiseWalls(wall, caster, pos, delay)
		local tick = 0.03
		local currentPos = pos + Vector(0,0,-270)
		local speed = 100 * tick
		wall:SetAbsOrigin(currentPos)
		Timers:CreateTimer(delay, function()
			if not wall or wall:IsNull() then return end
			--update current pos and move wall, use randomfloat for "shake" effect
			currentPos = Vector(pos.x,pos.y,currentPos.z)+Vector(RandomFloat(-3.5,3.5),RandomFloat(-3.5,3.5),speed)
			wall:SetAbsOrigin(currentPos)
			--if wall has reached pos then stop raising.
			if wall:GetAbsOrigin().z >= pos.z then
				wall:SetAbsOrigin(pos)
				wall:RemoveModifierByNameAndCaster("modifier_invulnerable", wall:GetOwner())
				-- make sure no one gets stuck inside the walls
				local unitsInsideWall = FindUnitsInRadius(wall:GetTeamNumber(), pos, nil, width, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
				for k,v in pairs(unitsInsideWall) do
					if v:GetUnitName() ~= wall:GetUnitName() then
						FindClearSpaceForUnit(v, v:GetAbsOrigin(), false)
					end
				end
				return
			end
			return tick
		end)
	end

	--give center wall a wall shaped hitbox
	self.walls[1]:SetModel("models/wall_"..numWalls.."box.vmdl")
	self.walls[1]:SetOriginalModel("models/wall_"..numWalls.."box.vmdl")
	self.walls[1]:SetControllableByPlayer(caster:GetPlayerID(), false)

	--set up walls
	local i = 1 --lazy second parameter for wall positioning
	for k,wall in pairs(self.walls) do
		-- need some calculation for setting model scale based on width
		wall:SetModelScale(1.25)
		wall:SetHullRadius(width)
		wall:SetNeverMoveToClearSpace(true)
		wall:HandleUnitHealth(health)

		--[[doesnt work with npc_dota_building, buildings cant turn
		wall:SetForwardVector(caster:GetForwardVector())]]

		for i=0,2 do
			local ability = wall:GetAbilityByIndex(i)
			if ability then
				if ability:GetName() == "wall_damage_return" then
					ability:SetLevel(self:GetLevel())
				elseif ability:GetName() == "wall_imbued_mortar" then
					ability:SetLevel(1)
					ability:ToggleAutoCast()
				else
					ability:SetLevel(1)
				end
			end
		end

		wall.walls = {}
		for l,m in pairs(self.walls) do
			if m ~= wall then
				table.insert(wall.walls, l, m)
			end
		end

		wall:AddNewModifier(caster, self, "modifier_invulnerable", {})
		wall:AddNewModifier(caster, self, "modifier_wall_degeneration", {})

		if wall ~= self.walls[1] then
			wall:AddNewModifier(caster, self, "modifier_no_health_bar", {})

			--left wall
			if k <= (#self.walls+1)/2 then
				local leftOffset = caster:GetLeftVector()*width*(k-1)
				RaiseWalls(wall, caster, GetGroundPosition(point+leftOffset, wall), k*0.2)

			--right wall
			else
				local rightOffset = caster:GetRightVector()*width*i
				RaiseWalls(wall, caster, GetGroundPosition(point+rightOffset, wall), i*0.2)
				i=i+1
			end

		--center wall
		else
			RaiseWalls(wall, caster, point, 0)
		end
	end
end

--channel finish will determine whether the walls stay or get destroyed
function castle_walls:OnChannelFinish( bInterrupted )
	if bInterrupted then
		if self.walls then
			ScreenShake(self.walls[1]:GetCenter(), --Vector
				900, --amplitude
				2, --frequency
				3.0, --duration
				1000, --radius
				1, -- ecommand(0=start, 1=stop)
				true) --airshake

			DestroyWalls(self.walls[1], true)
		end
	end
end

--------------------------------------------------------------------

LinkLuaModifier("modifier_no_dmg", "scripts/vscripts/heroes/squab_concepts/castle_walls.lua", LUA_MODIFIER_MOTION_NONE)

modifier_wall_degeneration = class({})

function modifier_wall_degeneration:IsHidden()
	return true
end

function modifier_wall_degeneration:IsPurgable()
	return false
end

function modifier_wall_degeneration:DeclareFunctions()
	local func = {
		MODIFIER_EVENT_ON_TAKEDAMAGE,
		MODIFIER_EVENT_ON_DEATH,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
		MODIFIER_PROPERTY_MANA_BONUS,
	}
	return func
end

function modifier_wall_degeneration:OnTakeDamage( keys )
	if IsServer() then
		local unit = keys.unit
		if unit == self:GetParent() then
			if unit:GetHealth() > 0 then
				for _,wall in pairs(unit.walls) do
					wall:SetHealth(wall:GetHealth() - keys.damage)
					wall:AddNewModifier(nil, nil, "modifier_no_dmg", {duration = 0.03})
				end
			end
			DestroyWalls(unit)
		end
	end
end

function modifier_wall_degeneration:OnDeath()
	DestroyWalls(self:GetParent())
end

function modifier_wall_degeneration:GetModifierMagicalResistanceBonus()
	return self.resist
end

function modifier_wall_degeneration:GetModifierPhysicalArmorBonus()
	return self.armor
end

function modifier_wall_degeneration:GetModifierManaBonus()
	return self.mana
end

function modifier_wall_degeneration:OnCreated( kv )
	self.resist = self:GetAbility():GetSpecialValueFor("resist_bonus")
	self.armor = self:GetAbility():GetSpecialValueFor("armor_bonus")
	self.mana = self:GetAbility():GetSpecialValueFor("wall_mana")

	--value to %, divided by numWalls because all walls have degen, multiplied by hp for %hp we'll degen, and finally multiply by 0.1 to account for tick rate 
	if IsServer() then
		self.degen = (self:GetAbility():GetSpecialValueFor("wall_degeneration")* -0.01) / #self:GetParent().walls * self:GetParent():GetMaxHealth() * 0.1
	end
	self:StartIntervalThink(0.1)
end

function modifier_wall_degeneration:OnIntervalThink()
	local parent = self:GetParent()
	if not parent:HasModifier("modifier_invulnerable") then
		self.state = nil
		if IsServer() then
			parent:SetHealth(parent:GetHealth()+self.degen)
		end
	else
		self.state = true
	end
	DestroyWalls(parent)
end

function modifier_wall_degeneration:CheckState()
	local state = {[MODIFIER_STATE_LOW_ATTACK_PRIORITY] = true,}
	if self.state then
		state[MODIFIER_STATE_NO_UNIT_COLLISION] = true
	end
	return state
end

--------------------------------------------------------------------

--this is used to prevent aoe abilites damaging every wall (e.g. pugnas blast)
modifier_no_dmg = class({})

function modifier_no_dmg:IsHidden()
	return true
end

function modifier_no_dmg:IsPurgable()
	return false
end

function modifier_no_dmg:CheckState()
	local state = {[MODIFIER_STATE_INVULNERABLE] = true,}
	return state
end

--------------------------------------------------------------------

LinkLuaModifier("modifier_builders_blessing", "scripts/vscripts/heroes/squab_concepts/castle_walls.lua", LUA_MODIFIER_MOTION_NONE)

wall_builders_blessing = class({})

function wall_builders_blessing:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	if target and caster.walls then
		local targetPos = target:GetAbsOrigin()
		--check if we can actually reach this target with any walls
		local range = 475
		local targetPos = target:GetAbsOrigin()
		local b = false
		for k,v in pairs(caster.walls) do
			--dont cast if out of range
			if (targetPos - v:GetAbsOrigin()):Length2D() <= range then
				b = true
			end
		end
		if not b then
			print("cancel")
			caster:Interrupt()
			return
		end
		print("cast")
	end
end

function wall_builders_blessing:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	if target then
		if caster.walls then
			target:AddNewModifier(caster, self, "modifier_builders_blessing", {duration = self:GetSpecialValueFor("duration")})
			--spend resources on all walls
			for k,v in pairs(caster.walls) do
				local ability = v:FindAbilityByName(self:GetName())
				ability:UseResources(true, false, true)
			end
		end
	end
end

modifier_builders_blessing = class({})

function modifier_builders_blessing:IsHidden()
	return false
end

function modifier_builders_blessing:IsPurgable()
	return true
end

function modifier_builders_blessing:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT}
end

function modifier_builders_blessing:OnCreated( kv )
	self.movespeed = self:GetAbility():GetSpecialValueFor("movespeed_bonus")
end

function modifier_builders_blessing:GetModifierMoveSpeedBonus_Constant()
	return self.movespeed
end

--------------------------------------------------------------------

LinkLuaModifier("modifier_imbued_mortar", "scripts/vscripts/heroes/squab_concepts/castle_walls.lua", LUA_MODIFIER_MOTION_NONE)

wall_imbued_mortar = class({})

function wall_imbued_mortar:OnUpgrade()
	local caster = self:GetCaster()
	if not caster:HasModifier("modifier_imbued_mortar") then
		caster:AddNewModifier(caster, self, "modifier_imbued_mortar", {})
	end
end

function wall_imbued_mortar:OnSpellStart()
	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("taunt_range")

	local p = ParticleManager:CreateParticle("particles/units/heroes/hero_axe/axe_beserkers_call_owner.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(p, 0, caster, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)

	--cp 1 is shout from axe's mouth?
	--ParticleManager:SetParticleControlEnt(p, 1, caster, PATTACH_ABSORIGIN_FOLLOW, "attach_", blahblah, blah)
	--ParticleManager:SetParticleControlOrientation(p, 1, caster:GetForwardVector(), caster:GetRightVector(), caster:GetUpVector())
	ParticleManager:ReleaseParticleIndex(p)

	local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, radius, self:GetAbilityTargetTeam(), self:GetAbilityTargetType(), self:GetAbilityTargetFlags(), FIND_ANY_ORDER, false)
	for _,unit in pairs(targets) do
		if unit then
			if not unit:HasModifier("modifier_imbued_mortar") then
				unit:SetForceAttackTarget(caster)
				unit:AddNewModifier(caster, self, "modifier_imbued_mortar", {duration = self:GetSpecialValueFor("duration")})
			end
		end
	end
end

modifier_imbued_mortar = class({})

function modifier_imbued_mortar:IsHidden()
	return self:GetParent() == self:GetCaster()
end

function modifier_imbued_mortar:IsPurgable()
	return false
end

function modifier_imbued_mortar:RemoveOnDeath()
	return false
end

function modifier_imbued_mortar:OnCreated( kv )
	if IsServer() then
		if self:GetParent() == self:GetCaster() then
			self.radius = self:GetAbility():GetSpecialValueFor("taunt_range")
			self:StartIntervalThink(2.0)
		end
	end
end

function modifier_imbued_mortar:OnIntervalThink()
	local parent = self:GetParent()
	if not parent:HasModifier("modifier_invulnerable") then
		local ability = self:GetAbility()
		if ability then
			if ability:GetAutoCastState() and ability:IsCooldownReady() and ability:GetManaCost(-1) <= parent:GetMana() then
				local units = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil, self.radius, ability:GetAbilityTargetTeam(), ability:GetAbilityTargetType(), ability:GetAbilityTargetFlags(), FIND_ANY_ORDER, false)
				local seen = 0
				for k,v in pairs(units) do
					if parent:CanEntityBeSeenByMyTeam(v) then
						seen = seen + 1
					end
				end
				if seen >= 2 then
					ability:UseResources(true, false, true)
					ability:OnSpellStart()
					EmitSoundOn("Hero_Axe.Berserkers_Call", parent)
					for k,v in pairs(parent.walls) do
						if v then
							local wallAbil = v:FindAbilityByName("wall_imbued_mortar")
							if wallAbil then
								wallAbil:UseResources(true, false, true)
								wallAbil:OnSpellStart()
							end
						end
					end
				end
			end
		end
	end
end

function modifier_imbued_mortar:OnDestroy()
	if IsServer() then
		self:GetParent():SetForceAttackTarget(nil)
	end
end

function modifier_imbued_mortar:CheckState()
	if self:GetParent() ~= self:GetCaster() then
		local states = {
			[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
		}
		return states
	end
	return {}
end

function modifier_imbued_mortar:GetStatusEffectName()
	if self:GetParent() ~= self:GetCaster() then
		return "particles/status_fx/status_effect_beserkers_call.vpcf"
	end
end

function modifier_imbued_mortar:StatusEffectPriority()
	return 10
end

------------------------------------------------------------------------

LinkLuaModifier("modifier_wall_damage_return", "scripts/vscripts/heroes/squab_concepts/castle_walls.lua", LUA_MODIFIER_MOTION_NONE)

wall_damage_return = class({})

function wall_damage_return:GetIntrinsicModifierName()
	return "modifier_wall_damage_return"
end

------------------------------------------------------------------------

modifier_wall_damage_return = class({})

function modifier_wall_damage_return:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_ATTACKED,
	}
	return funcs
end

function modifier_wall_damage_return:OnAttacked( keys )
	if self:GetParent() == keys.target then

		local p = ParticleManager:CreateParticle("particles/units/heroes/hero_centaur/centaur_return.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
		ParticleManager:SetParticleControlEnt(p, 0, self:GetParent(), PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), false)
		ParticleManager:ReleaseParticleIndex(p)

		local pct = self:GetAbility():GetSpecialValueFor("damage_return")*0.01
		ApplyDamage({victim = keys.attacker, attacker = self:GetParent(), damage = keys.damage*pct, damage_type = self:GetAbility():GetAbilityDamageType()})
	end
end
