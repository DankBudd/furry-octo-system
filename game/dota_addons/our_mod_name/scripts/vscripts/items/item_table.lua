local droppable_souls = {
	CREATURE_WEAK = "item_lesser_soul",
	CREATURE_COMMON = "item_common_soul",
	CREATURE_STRONG ="item_greater_soul",
	--dont think this works, kek
	CREATURE_RARE = "item_divine_soul" or "item_hellish_soul" or "item_realm_soul",
	}

local dropTable = {
	SOULS = droppable_souls,
	}


return dropTable