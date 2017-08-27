--[[
freeze a unit in time, no damage can be taken, no regeneration or healing,

TODO: forced motion such as force staff or toss will continue after effect wears off]]

time_manipulation = class({})

function time_manipulation:OnSpellStart()
	local target = self:GetCursorTarget()
	if not target then return end

	local sound
	if target:GetTeam() == self:GetCaster():GetTeam() then
		--?
		sound = ""
	else
		--silencer arcane curse, cast?
		sound = ""
	end

	--EmitSoundOn(sound, target)

	local duration = self:GetSpecialValueFor("duration")
	target:AddNewModifier(self:GetCaster(), self, "modifier_time_manipulation", {duration = duration})
end


modifier_time_manipulation = class({
	IsHidden = function(self) return false end,
	IsPurgable = function(self) return false end,
	IsDebuff = function(self) return self:GetParent():GetTeam() ~= self:GetCaster():GetTeam() end,
	CheckState = function(self) return {[MODIFIER_STATE_COMMAND_RESTRICTED]=true, [MODIFIER_STATE_FROZEN]=true,} end,
	DeclareFunctions = function(self) return {MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, MODIFIER_EVENT_ON_TAKEDAMAGE,} end,
	
	GetModifierConstantHealthRegen = function(self)
		if self:GetCaster():GetTeam() == self:GetParent():GetTeam() then
			return self.regen
		end
		return (-1)*self.regen
	end,

	OnTakeDamage = function(self, keys)
		if self:GetParent() ~= keys.victim then return end
		self:GetParent():SetHealth(self.health)
	end,

	OnCreated = function(self, kv)
		self.health = self:GetParent():GetHealth()
		self.mana = self:GetParent():GetMana()
		self.origin = self:GetParent():GetAbsOrigin()
		self.mult = self:GetAbility():GetSpecialValueFor("duration_multiplier")*0.01
		self.regen = self:GetAbility():GetSpecialValueFor("regen_degen") --35/45/60/75

		self.tick = 0.03
		self:StartIntervalThink(self.tick)
	end,

	OnIntervalThink = function(self)
		self:GetParent():SetHealth(self.health)
		self:GetParent():SetMana(self.mana)

		self:GetParent():SetAbsOrigin(self.origin)

		--dont increase/shorten durations of these
		local exceptions = {
			modifier_time_manipulation,
			modifier_pudge_dismember,
		}

--[[ ally =   buff longer,  debuff shorter
    enemy = debuff longer,  buff shorter]]

		for k,v in pairs(self:GetParent():FindAllModifiers()) do
			--check for execptions and no auras/perma modifiers
			if not exceptions[v:GetName()] and v:GetDuration() ~= -1 then
				local dur = v:GetRemainingTime()+self.tick
				local var = v:GetDuration()*self.mult*self.tick
				local newDur
				if self:GetParent():GetTeam() == self:GetCaster():GetTeam() then
					--ally
					if v:IsDebuff then
						newDur = dur - var else newDur = dur + var
					end
				else
					--enemy
					if v:IsDebuff then
						newDur = dur + var else newDur = dur - var
					end
				end
				v:SetDuration(newDur, true)
			end
		end
	end,
})

-----------------------------------------------------------------------

--passive: makes all damage taken dispersed over time rather than taking damage immedietly. e.g. kunkka ultimate
--active: gain %damage reduction for some time
		--can be cast while disabled, doesnt purge

--change current method to: add each instance of damage into a table with gametime for damage
-- deal damage over the course of X seconds for each instance
time_lord = class({})

function time_lord:OnSpellStart()
end

function time_lord:OnUpgrade()
	self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_time_lord", {})
end


modifier_time_lord = class({
	IsHidden = function(self) return true end,
	IsPurgable = function(self) return false end,
	RemoveOnDeath = function(self) return false end,
	IsPermanent = function(self) return true end,
	DeclareFunctions = function(self) return {MODIFIER_EVENT_ON_TAKEDAMAGE,} end,
	
	OnCreated = function(self, kv)
		self.reduction = self:GetAbility():GetSpecialValueFor("reduction")*0.01
	
		self.tick = 0.1
		self.taken = {}
		self:StartIntervalThink(self.tick)
	end,

	OnTakeDamage = function(self, keys)
		if self:GetParent() ~= keys.victim then return end
		local time = GameRules:GetGameTime()
		
		if self.taken[time] then
			self.taken[time] = self.taken[time] + keys.damage
		else
			self.taken[time] = keys.damage
		end

		--might be inaccurate and heal on hit due to armor and such
		local hp = self:GetParent():GetHealth()
		self:GetParent():SetHealth(hp+keys.damage)
	end,

	--this is probably nonsense
	OnIntervalThink = function(self)
		local time = GameRules:GetGameTime()
		local toDamage = 0
		for t,dmg in pairs(self.taken) do
			if t <= time then
				toDamage = toDamage + dmg*self.tick
				self.taken[t] = self.taken[t] - dmg*self.tick
				if self.taken[t] <= 0 then
					self.taken[t] = nil
				end
			end
		end
		
		local hp = self:GetParent():GetHealth()
		self:GetParent():SetHealth(hp - toDamage)
	end,
})

-----------------------------------------------------------------------

