test_ability = class({})

function test_ability:OnSpellStart()

end

function test_ability:GetIntrinsicModifierName()
	return "modifier_test_ability"
end

modifier_test_ability = class({
	IsHidden = function(self) return self:GetParent() == self:GetCaster() end,
	IsPurgable = function(self) return self:GetParent() ~= self:GetCaster() end,
	IsDebuff = function(self) return self:GetParent():GetTeam() ~= self:GetCaster():GetTeam() end,

	DeclareFunctions = function(self)
		return {}
	end,

	CheckState = function(self)
		return {[MODIFIER_STATE_SPECIALLY_DENIABLE] = true,}
	end,

	OnCreated = function(self, kv)
		ListenToGameEvent("modifier_refresh", function(keys)
			PrintTable(keys)
			for k,v in pairs(keys)
				local ent = EntIndexToHScript(v)
				print(ent:GetName())
			end
		end, nil)
	end,
})