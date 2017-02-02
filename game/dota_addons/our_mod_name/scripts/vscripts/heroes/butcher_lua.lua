LinkLuaModifier( "modifier_rotting_flesh", "heroes/butcher_lua_modifier.lua" , LUA_MODIFIER_MOTION_NONE )

--[[//////////////////
/// Rotting Flesh ///
////////////////////]]

rotting_flesh = class({})

--------------------------------------------------------------------------------

function rotting_flesh:ProcsMagicStick()
	return false
end


function rotting_flesh:GetBehavior()
	local behav = DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_TOGGLE + DOTA_ABILITY_BEHAVIOR_IGNORE_CHANNEL + DOTA_ABILITY_BEHAVIOR_IGNORE_BACKSWING
	return behav
end
--------------------------------------------------------------------------------

function rotting_flesh:OnToggle()
	-- Apply the rot modifier if the toggle is on
	if self:GetToggleState() then
		self:GetCaster():AddNewModifier( self:GetCaster(), self, "modifier_rotting_flesh", nil )

		if not self:GetCaster():IsChanneling() then
			self:GetCaster():StartGesture( ACT_DOTA_CAST_ABILITY_ROT )
		end
	else
		-- Remove it if it is off
		local hRotBuff = self:GetCaster():FindModifierByName( "modifier_rotting_flesh" )
		if hRotBuff ~= nil then
			hRotBuff:Destroy()
		end
	end
end
--------------------------------------------------------------------------------