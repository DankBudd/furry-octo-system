--Modifier is currently bugged, doesnt properly play flail animation
LinkLuaModifier("modifier_knockback_func", "heroes/modifiers/modifier_knockback.lua", LUA_MODIFIER_MOTION_NONE)
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
		self:CancelKnockback(false)
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
			self:CancelKnockback(true)
		end
		-- continue timer
		return 0.03
	end)
	-- return timer so you can cancel it with CancelKnockback()
	return self.knockback_unit
end

--[[ e.g. black hole
--
 endOnArrival doesnt work quite how i want it to, ends too early
-------------------------
	self        = Entity |
	point       = Vector |
	pullSpeed   = Float  |
	rotateSpeed = Float  |
	rotateDirection = ?  | left or right
	shouldStun  = Bool   |
	endOnArrival= Bool   | should the knockback end when the unit reaches the point?
	duration    = Float  | if neither duration nor endOnArrival are given the timer will not end unless stopped by a third party calling CancelKnockback()
]]
function CDOTA_BaseNPC:RotationalPullUnit( point, pullSpeed, rotateSpeed, rotateDirection, shouldStun, endOnArrival, duration )
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
		--move unit towards point
		local pointDirection = (point - self:GetAbsOrigin()):Normalized()
		self:SetAbsOrigin(self:GetAbsOrigin() + pointDirection * pullSpeed * 1/30)
		-- store forward vector so we can restore it after calculations
		local forward = self:GetForwardVector()
		-- determine rotation direction relative to point. defaults to right
		self:SetForwardVector(pointDirection)
		local direction
		if rotateDirection == "left" then
			direction = self:GetLeftVector()
		else
		 	direction = self:GetRightVector()
		end
		self:SetForwardVector(forward)
		-- move unit in rotation direction
		self:SetAbsOrigin(self:GetAbsOrigin() + direction * (rotateSpeed * 1/30 )/2)
		-- register distance moved for timer
		traveled = traveled + (pullSpeed * 1/30)
		curTick = curTick + 0.03
		-- end timer
		if endOnArrival then
			if traveled >= distance then
				self:CancelKnockback(self.knockback_rotate, true)
			end
		end
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

-- might need to add RemoveMotionControllers()
function CDOTA_BaseNPC:CancelKnockback( timer, bFindClearSpace )
	Timers:RemoveTimer(timer)
	timer = nil
	self:RemoveModifierByName("modifier_knockback_func")
	if bFindClearSpace then
		FindClearSpaceForUnit(self, self:GetAbsOrigin(), false)
	end
end
