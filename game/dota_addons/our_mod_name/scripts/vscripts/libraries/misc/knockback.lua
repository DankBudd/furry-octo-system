--Modifier is currently bugged, doesnt play flail animation
LinkLuaModifier("modifier_knockback_func", "heroes/modifiers/modifier_knockback.lua", LUA_MODIFIER_MOTION_NONE)

-- requires caster, target, distance, speed, optional direction, optional vertical, optional shouldStun
function DataDrivenKnockback( keys )
	local target = keys.target
	local vertical = keys.vertical or 0
	local distance = keys.distance or 500
	local speed = keys.speed or 700
	local shouldStun
	local direction	

	if keys.shouldStun == 0 then
		shouldStun = false
	else
		shouldStun = true
	end

	if keys.direction == "from_caster" then
		direction = (target:GetAbsOrigin() - keys.caster:GetAbsOrigin()):Normalized()
	elseif keys.direction == "forward" then
		direction = target:GetForwardVector()
	elseif keys.direction == "backward" then
		direction = target:GetBackwardVector()
	elseif keys.direction == "left" then
		direction = target:GetLeftVector()
	elseif keys.direction == "right" then
		direction = target:GetRightVector()
	else
		direction = nil
	end

	target:KnockbackUnit(distance, direction, speed, vertical, shouldStun)
end

--[[ throws a unit for some distance
-------------------------
	self       = Entity |
	distance   = Float  |
	direction  = Vector | if direction == nil then direction will be behind unit
	speed      = Float  |
	vertical   = Float  | distance to travel upwards
	shouldStun = Bool   | if false vertical will not work. if they arent stunned they can move, when they move their height position is reset to ground.
]]
function CDOTA_BaseNPC:KnockbackUnit( distance, direction, speed, vertical, shouldStun )
	if not self or self:IsNull() or not distance or not speed then print("Knockback | invalid inputs") return end
	-- if direction is not given then make direction backwards from unit
	if not direction or direction == Vector(0,0,0) then
		direction = self:GetBackwardVector()
	end
	-- remove any existing knockback
	if self.knockback_unit then
		self:CancelKnockback(self.knockback_unit, false)
	end
	-- start knockback
	local traveled = 0
	local curHeight = self:GetAbsOrigin().z
	if shouldStun then
		self:AddNewModifier(nil, nil, "modifier_knockback_func", {})
	end
	self.knockback_unit = Timers:CreateTimer(0, function()
		if not self or self:IsNull() then print("Knockback | unit is null") return end
--		if not self:IsAlive() then print("Knockback | unit died") return end
		-- move towards point
		local newOrig = self:GetAbsOrigin() + direction * (speed * 1/30)
		self:SetAbsOrigin(newOrig)
		traveled = traveled + (speed * 1/30)
		if vertical and not shouldStun then
			if vertical > 0 then
				-- move up
				if traveled < distance/2 then
					curHeight = curHeight + (speed * 1/30)/2
					if curHeight > vertical then
						curHeight = vertical
					end
					self:SetAbsOrigin(GetGroundPosition(self:GetAbsOrigin(), self) + Vector(0,0, curHeight))
				elseif traveled > distance/2 then
					-- move down
					curHeight = curHeight - (speed * 1/30)/2
					self:SetAbsOrigin(GetGroundPosition(self:GetAbsOrigin(), self) + Vector(0,0, curHeight))
				end
			end
		else
			-- maintain ground height. (unit will clip into ground when moving to higher ground without this)
			self:SetAbsOrigin(Vector(newOrig.x, newOrig.y, GetGroundPosition(self:GetAbsOrigin(), self).z))
		end
		-- end timer
		if traveled >= distance then
			self:CancelKnockback(self.knockback_unit, true)
		end
		-- continue timer
		return 0.03
	end)
	-- return timer so you can cancel it with CancelKnockback()
	return self.knockback_unit
end

--[[ e.g. black hole
-------------------------
	self        = Entity |
	point       = Vector |
	pullSpeed   = Float  |
	rotateSpeed = Float  |
	rotateDirection = String  | clockwise or counter-clockwise
	shouldStun  = Bool   |
	duration    = Float  | if neither duration nor endOnArrival are given the timer will not end unless stopped by a third party calling CancelKnockback()
]]
function CDOTA_BaseNPC:RotationalPullUnit( point, pullSpeed, rotateSpeed, rotateDirection, shouldStun, duration )
	if not self or self:IsNull() or not point or not pullSpeed or not rotateSpeed then print("Knockback | invalid inputs") return end
	-- remove any existing knockback
	if self.knockback_rotate then
		self:CancelKnockback(self.knockback_rotate, false)
	end
	-- start knockback
	local distance = (point - self:GetAbsOrigin()):Length2D() -- this is straight line distance from unit to point.
	local traveled = 0
	local curTick = 0
	if shouldStun then
		self:AddNewModifier(nil, nil, "modifier_knockback_func", {})
	end
	self.knockback_rotate = Timers:CreateTimer(0, function()
		if not self or self:IsNull() then print("Knockback | unit is null") return end
		if not self:IsAlive() then print("Knockback | unit is dead") return end
		--move unit towards point
		local pointDirection = (point - self:GetAbsOrigin()):Normalized()
		self:SetAbsOrigin(self:GetAbsOrigin() + pointDirection * pullSpeed * 1/30)
		-- store forward vector so we can restore it after calculations
		local forward = self:GetForwardVector()
		-- determine rotation direction relative to point. defaults to right
		self:SetForwardVector(pointDirection)
		local direction
		if rotateDirection == "clockwise" then
			direction = self:GetLeftVector()
		else
		 	direction = self:GetRightVector()
		end
		self:SetForwardVector(forward)
		-- move unit in rotation direction
		local shouldRotate = true
		for _,unit in pairs(FindUnitsInRadius(self:GetTeamNumber(), point, nil, 10, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)) do
			if unit:entindex() == self:entindex() then
				shouldRotate = false
				break
			end
		end
		if shouldRotate then
			self:SetAbsOrigin(self:GetAbsOrigin() + direction * (rotateSpeed * 1/30 )/2)
		end
		-- register distance moved for timer
		traveled = traveled + (pullSpeed * 1/30)
		curTick = curTick + 0.03
		-- end timer
		if duration then
			if curTick >= duration then
				self:CancelKnockback(self.knockback_rotate, true)
			end
		end
		-- continue timer
		return 0.03
	end)
	-- return timer so you can cancel it with CancelKnockback()
	return self.knockback_rotate
end

function CDOTA_BaseNPC:CancelKnockback( timer, bFindClearSpace )
	Timers:RemoveTimer(timer)
	timer = nil
	self:RemoveModifierByName("modifier_knockback_func")
	if bFindClearSpace then
		FindClearSpaceForUnit(self, self:GetAbsOrigin(), false)
	end
end
