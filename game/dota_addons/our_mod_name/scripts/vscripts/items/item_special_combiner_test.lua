LinkLuaModifier("modifier_special_combiner_test", "scripts/vscripts/items/item_special_combiner_test.lua", LUA_MODIFIER_MOTION_NONE)

--[[
	purpose of this item (might make it a spell instead) is to 'combine' any two items. 

	we do this by hiding one of the items via destroying its container
	then whenever you cast a combined item it will swap places with its corresponding hidden item

	Notes:
		-hidden item's cooldowns will continue to tick down
		-an already combined item cannot combine again
		-cannot combine two of the same items (force staff + force staff)

		-swap method might not be very user-friendly? panorama button for swapping?

	Known Bugs: 
	FIXED -selling a combined item will make the hidden item unobtainable
		  -destroying a combined item will make the hidden item unobtainable
]]

item_special_combiner_test = class({})

function item_special_combiner_test:GetBehavior()
	return DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_OPTIONAL_NO_TARGET
end

function item_special_combiner_test:OnSpellStart()
	local caster = self:GetCaster()
	local point = caster:GetCursorPosition()
	local radius = self:GetSpecialValueFor("search_radius") -- 20 units

	-- optional no target cast (ctrl+cast), clears the queue and give the item back to caster(might make it drop instead)
	if point == Vector(0,0,0) then
		if caster.toBeCombined then
			caster:AddItem(caster.toBeCombined[1])
			caster.toBeCombined = nil
		end
		return
	end

	local container = FindItemsInRadius(point, radius)[1]
	if container then
		local item = container:GetContainedItem()
		-- check if caster actually owns item in question
		if item:GetPurchaser() ~= caster then
			Notifications:Bottom(caster:GetPlayerID(), {text = "#error_item_not_owned_by_caster", duration = 3.0})
			return
		end
		-- no consumables... need to compile a list of reject items probably.. doesnt work well with items like treads, and not at all with armlet specifically(armlet is actually two items, one for on and one for off)
		if item:IsConsumable() or item:IsRecipe() or item:GetName() == "item_armlet" then
			Notifications:Bottom(caster:GetPlayerID(), {text = "#error_item_not_combinable", duration = 3.0})
			return
		end
		-- cant combine same item
		if caster.toBeCombined then
			if caster.toBeCombined[1] == item then
				Notifications:Bottom(caster:GetPlayerID(), {text = "#error_cant_combine_same_item", duration = 3.0})
				return
			end
		end
		-- if item has already been combined then do nothing
		if item.swapItem then
			Notifications:Bottom(caster:GetPlayerID(), {text = "#error_item_already_combined", duration = 3.0})
			self:StartCooldown(2.5)
			return
		end

		--ensure table exists
		caster.toBeCombined = caster.toBeCombined or {}
		local t = caster.toBeCombined

		--move item to table
		table.insert(t, item)
		--destroy container
		container:Destroy()

		if #t == 2 then
			--combine items
			caster:AddItem(t[1])
			t[1].swapItem = t[2]
			t[2].swapItem = t[1]

			Notifications:Bottom(caster:GetPlayerID(), {text = "#success_items_combined", duration = 3.0})

			--clear table for further combining
			caster.toBeCombined = nil
			--start tracking item casts for item swapping
			caster:AddNewModifier(caster, nil, "modifier_special_combiner_test", {})
			--remove combiner
			caster:RemoveItem(self)
		end
	end
end

----------------------------------------------------------

modifier_special_combiner_test = class({})

function modifier_special_combiner_test:RemoveOnDeath()
	return false
end

function modifier_special_combiner_test:IsHidden()
	return true
end

function modifier_special_combiner_test:IsPurgable()
	return false
end

function modifier_special_combiner_test:DeclareFunctions()
	return {MODIFIER_EVENT_ON_ABILITY_FULLY_CAST}
end

--track spell casts, swap items if cast spell is an item and has item to swap
function modifier_special_combiner_test:OnAbilityFullyCast( keys )
	local item = keys.ability
	local unit = keys.unit
	if item and unit then
		if item.swapItem then
--			print("item: "..item:GetName(), "|    swap: "..item.swapItem:GetName())

			-- grab item's slot before removing it from inventory
			local slot = unit:GetSlot(item)

			-- remove item from units inventory... RemoveItem() makes the item nil
			unit:DropItemAtPositionImmediate(item, unit:GetAbsOrigin())
			item:GetContainer():Destroy()

			-- add swap item to units inventory
			unit:AddItem(item.swapItem)

			-- move swapped item to the same slot as original item was in
			unit:SwapItems(slot, unit:GetSlot(item.swapItem))
		end
	end
end

--retrieve any hidden items 
function CombinerSellItemListener( filterTable )
	local orderType = filterTable["order_type"]
	local itemIndex = filterTable["entindex_ability"]

	local item = EntIndexToHScript(itemIndex)
	if itemIndex and item and orderType == DOTA_UNIT_ORDER_SELL_ITEM then
		local seller = item:GetPurchaser()
		-- grab any uncombined items
		if seller.toBeCombined then
			if caster:HasRoomForItem(item:GetName(), true, false) then
				seller:AddItem(seller.toBeCombined[1])
			else
				DropItemAtPositionImmediate(item, seller:GetAbsOrigin())
				item:LaunchLoot(false, 150, 1.765, seller:GetAbsOrigin()+RandomVector(85))
			end
			seller.toBeCombined = nil
		end
		-- grab any combined items
		if item.swapItem then
			if caster:HasRoomForItem(item.swapItem:GetName(), true, false) then
				seller:AddItem(item.swapItem)
			else
				DropItemAtPositionImmediate(item.swapItem, seller:GetAbsOrigin())
				item.swapItem:LaunchLoot(false, 150, 1.765, seller:GetAbsOrigin()+RandomVector(85))
			end
			item.swapItem = nil
		end
	end
end

--still need to check for when items are destroyed
function soemts( setsd )
end