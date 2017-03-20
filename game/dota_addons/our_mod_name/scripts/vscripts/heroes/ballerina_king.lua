function BallerinaKing( keys )
	HideWearables(keys.caster)
	Timers:CreateTimer(5, function() ShowWearables(keys.caster) end)
	StartAnimation(keys.caster, {duration = 0.7, activity = ACT_DOTA_ATTACK_EVENT, translate = "wraith_spin"})
end
