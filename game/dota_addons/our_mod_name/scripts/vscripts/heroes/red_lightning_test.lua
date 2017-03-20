function Start( keys )
	local targetPos = keys.ability:GetCursorPosition()
	local particle = ParticleManager:CreateParticle("particles/red_lightning.vpcf", PATTACH_WORLDORIGIN, keys.caster)
	ParticleManager:SetParticleControl(particle, 0, Vector(targetPos.x, targetPos.y, 10)) --ground position
	ParticleManager:SetParticleControl(particle, 1, Vector(targetPos.x, targetPos.y, 1000)) --sky position
end