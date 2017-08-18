--[[enigma functions
--------------------]]

function ApplyVoidFissure( caster, target )
	if target and caster then
	local gl = caster:FindAbilityByName("gl_gravity_lord")
		if caster:HasTalent("special_bonus_unique_gravity_lord_6") and gl:GetLevel() > 0 then
			if target:HasModifier("modifier_gl_void_fissure") then
				target:SetModifierStackCount("modifier_gl_void_fissure", caster, target:GetModifierStackCount("modifier_gl_void_fissure", caster)+1)
			else
				target:AddNewModifier(caster, gl, "modifier_gl_void_fissure", {})
			end
		end
	end
	return target:FindModifierByNameAndCaster("modifier_gl_void_fissure", caster)
end
