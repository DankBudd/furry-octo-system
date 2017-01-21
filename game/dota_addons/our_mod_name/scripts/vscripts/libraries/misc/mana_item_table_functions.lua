manaItemTable = require("libraries/misc/item_table")

function CDOTA_BaseNPC:CalculateBaseMana(bStats, bBonusMana)
	local outcome = 0
	if bStats then
		outcome = self:GetStatsBasedMana()
	end
	if bBonusMana then
		local itemBasedMana = 0
		for i = 0,5 do
			local item = self:GetItemInSlot(i)
			if item ~= nil then
				for valueName,value in pairs(manaItemTable) do
					if item:GetName() == valueName then
						itemBasedMana = itemBasedMana + value
						--print("post calc: "..itemBasedMana)
						--print("item name: "..item:GetName())
					end
				end
			end
		end
		if outcome ~= 0 then
			--print("pre outcome: "..outcome)
			outcome = outcome + itemBasedMana
		else
			--print("pre outcome: "..outcome)
			outcome = itemBasedMana
		end
	end
	--print("outcome: "..outcome)
	return outcome
end

function CDOTA_BaseNPC:GetStatsBasedMana()
	return self:GetIntellect() * 12 -- change number value to whatever amount of mana you get per int once that is implemented
end