function KnockbackTest( keys )
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target

	local distance = ability:GetSpecialValueFor("distance")
	local speed = ability:GetSpecialValueFor("speed")
	local damage = ability:GetSpecialValueFor("dot")
	local direction = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized()
	local vertical = 322

	target:KnockbackUnit(distance, direction, speed, vertical, true)
	local particle = ParticleManager:CreateParticle("particles/units/heroes/spirit_breaker_greater_bash.vpcf", PATTACH_WORLDORIGIN, target)
--	ParticleManager:SetParticleControl(particle, int_2, Vector_3)
	EmitSoundOn("Hero_Spirit_Breaker.GreaterBash", target)

	local tick = 0
	Timers:CreateTimer(0.45, function()
		ApplyDamage({victim = target, attacker = caster, ability = ability, damage = damage, damage_type = ability:GetAbilityDamageType()})
		PopupDoT(target, damage)
		tick = tick + 0.45
		if tick > 2 then
			return nil
		end
		return 0.45
	end)
end

function BlackHoleTest( keys )
	local caster = keys.caster
	local targetPoint = keys.target_points[1]

	for _,unit in pairs(FindUnitsInRadius(caster:GetTeamNumber(), targetPoint, nil, 500, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_CREEP + DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)) do
		local timer = unit:RotationalPullUnit(targetPoint, 200, 1000, "left", true, false, nil)
		Timers:CreateTimer(12, function()
			if not unit or unit:IsNull() then print("test | unit is null") return end
			unit:CancelKnockback(timer, true)
		end)
	end
end

function CreateArrow( keys )
	local caster = keys.caster
	local ability = keys.ability
	local targetPoint = keys.target_points[1]

	--Vector(x,y,z)
	--projectile velocity must have a zero Z vector
	local direction = ((targetPoint - caster:GetAbsOrigin()) * Vector(1,1,0)):Normalized()
	local speed = 675

	local projectileInfo = {
		Ability = ability,
		EffectName = "particles/units/heroes/hero_mirana/mirana_spell_arrow.vpcf",
		vSpawnOrigin = caster:GetAbsOrigin(),
		fDistance = 1000,
		fStartRadius = 155,
		fEndRadius = 155,
		Source = caster,
		bHasFrontalCone = false,
		bReplaceExisting = false,
		iUnitTargetTeam = ability:GetAbilityTargetTeam(),
		iUnitTargetType = ability:GetAbilityTargetType(),
		iUnitTargetFlags = ability:GetAbilityTargetFlags(),
		bDeleteOnHit = false, -- false because we're destroying it manually
		vVelocity = direction * speed, 
		bProvidesVision = true,
		iVisionRadius = 300,
		iVisionNumber = 1
	}
	-- create and store the projectile in the ability
	ability.arrow = ProjectileManager:CreateLinearProjectile(projectileInfo)
end

function DestroyArrow( keys )
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target
	local damage = ability:GetAbilityDamage()

	if target ~= caster then
		--stun and damage
		ApplyDamage({victim = target, attacker = caster, ability = ability, damage = damage, damage_type = ability:GetAbilityDamageType(), damage_flags = ability:GetAbilityTargetFlags()})
		target:AddNewModifier(caster, ability, "modifier_stunned", {duration = 3.5})
		-- destroy projectile
		ProjectileManager:DestroyLinearProjectile( ability.arrow )
	end
end

--[[Dota's Boot Priority
1-Travel2 
2-Travel	
3-Guardian
4-Power
5-Arcane
6-Phase
7-Tranq
8-Brown
---------
Every time meepo prime performs any action related to his inventory his clone's boots update
this function apparently runs before that which makes it problematic]]

function UpdateMeepoBoots()
	print("Zzz")
	-- 1 is highest priority
	local bootPrio = {
		["item_travel_boots_2"] = 1,
		["item_dagon"] 			= 2, --<testing
		["item_travel_boots"] 	= 3,
		["item_guardian_greaves"] = 4,
		["item_power_treads"] 	= 5,
		["item_arcane_boots"] 	= 6,
		["item_phase_boots"] 	= 7,
		["item_tranquil_boots"] = 8,
		["item_boots"] 			= 9,
	}
	local primeItems = {}
	local currentBoot = nil
	local currentPrio = TableCount(bootPrio)

	local heroes = HeroList:GetAllHeroes()
	for _,hero in pairs(heroes) do
		if hero:HasModifier("modifier_meepo_divided_we_stand") then
			-- this should always happen first, meepo prime is a lower # in the herolist than his clones
			if hero.firstMeepo then
				-- record meepo prime's items
				for i=0,DOTA_ITEM_MAX-1 do
					local item = hero:GetItemInSlot(i)
					if item then
						table.insert(primeItems, i, item)
					end
				end
				-- determine which boot they should get
				for _,item in pairs(primeItems) do
					if item then
						for name,prio in pairs(bootPrio) do
							if item:GetName() == name then
								if currentPrio > prio then
									currentBoot = item
									currentPrio = prio
								end
							end
						end
					end
				end
			else
				-- give the clone prime's boot if they don't already have it
				if TableCount(primeItems) > 0 and currentBoot then
					local item
					for i=0,DOTA_ITEM_MAX-1 do
						if hero:GetItemInSlot(i) then
							item = hero:GetItemInSlot(i)
							-- clone already has item
							if item:GetName() == currentBoot:GetName() then
								print("returning")
								return
							else
							-- clone has wrong item
								print("destroy")
								item:Destroy()
								item = nil
							end
						end
					end
					if not item then
						print('new item')
						-- create new boot
						local newboot = hero:AddItem(CreateItem(currentBoot:GetName(), hero, hero))
						-- move the new boot to the same slot as meepo prime
						hero:SwapItems(PlayerResource:GetSelectedHeroEntity(hero:GetPlayerID()):GetSlot(currentBoot), hero:GetSlot(newboot))
					else
						print("item already exists")
					end
				end
			end
		end
	end
	return
end


function test( keys )

end

--[[
function test( keys )
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target

	local boots = {
		1 = "item_travel_boots_2",
		2 = "item_rapier",
		3 = "item_travel_boots",
		4 = "item_guardian_greaves",
		5 = "item_power_treads",
		6 = "item_arcane_boots",
		7 = "item_phase_boots",
		8 = "item_tranquil_boots",
		9 = "item_boots",
	}

	local secondary = {}
	local primary = {}
	local t

	local units = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, 500, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	for _,unit in pairs(units) do
		if unit then
			t = nil
			if unit:HasModifier("modifier_meepo_divided_we_stand") and not unit.firstMeepo then
				t = secondary
			elseif unit.firstMeepo then
				t = primary
			end
			if t then
				local tempT = {}
				for i=0,DOTA_ITEM_MAX-1 do
					local item = unit:GetItemInSlot(i)
					if item then
						table.insert(tempT, i+1, item:GetName())
					else
						table.insert(tempT, i+1, "no_item")
					end
				end
				if t == primary then
					primary = tempT
				else
					table.insert(t, tempT)
				end
			end
		end
	end
	print("PRIMARY")
	PrintTable(primary)
	print()
	print("SECONDARY")
	PrintTable(secondary)
end]]

--[[

use this for a projectile speed, end projectile if speed < 1.1

	_G.decay = 100

	if _G.timer then
		Timers:RemoveTimer(_G.timer)
	end
	print()
	print("NEW")
	_G.timer = Timers:CreateTimer(function()
		_G.decay = ExponentialDecay( _G.decay, _G.decay+_G.decay/_G.decay, _G.decay/_G.decay*0.3/_G.decay+_G.decay )
		print("Decay | ".._G.decay)
		return 1.0
	end)

]]


function RubickTest( keys )
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability

	--lift unit
	print("0!")
	if caster:GetScepterLevel() >= 1 then
		--set them on fire
		print("1!")
	end

	if caster:GetScepterLevel() >= 2 then
		--hex them upon landing
		print("2!")
	end

	if caster:GetScepterLevel() >= 3 then
		--instantly kill them
		print("3!")
	end

end

function CDOTA_BaseNPC:GetScepterLevel()
	local highest = 0
	for i=0,DOTA_ITEM_MAX-1 do
		local item = self:GetItemInSlot(i)
		if item then
			if string.find(item:GetName(), "item_special_scepter") then
				if highest < item:GetLevel() then
					highest = item:GetLevel()
				end
			end
		end
	end
	return highest
end