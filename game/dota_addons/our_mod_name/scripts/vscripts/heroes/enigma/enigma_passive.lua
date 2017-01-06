--Borrowed from LoD:Redux
function SetCastRange(keys)
	local caster = keys.caster
	local ability = keys.ability
	local abLvl = ability:GetLevel()
	if abLvl <= 0 then return end
        -- FIXME: Remove this hack once the proper property is released.
	-- Remove old cast range
	caster:RemoveModifierByName("modifier_item_aether_lens")
	-- Replace cast range
	caster:AddNewModifier(caster,ability,"modifier_item_aether_lens", {}) 
	
end

LinkLuaModifier("modifier_enigma_mana_bonus", "heroes/enigma/modifier_enigma_mana_bonus.lua", LUA_MODIFIER_MOTION_NONE)

function CalculateManaBonus( keys )
	local caster = keys.caster
	local ability = keys.ability

	caster:RemoveModifierByName("modifier_enigma_mana_bonus")
	caster:AddNewModifier(caster, ability, "modifier_enigma_mana_bonus", {})
end

-- put both above functions into this one
-- add application of mana regen and spell amp modifier
function ApplyBonuses( keys )
end