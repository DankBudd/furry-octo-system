POPUP_SYMBOL_PRE_PLUS = 0
POPUP_SYMBOL_PRE_MINUS = 1
POPUP_SYMBOL_PRE_SADFACE = 2
POPUP_SYMBOL_PRE_BROKENARROW = 3
POPUP_SYMBOL_PRE_SHADES = 4
POPUP_SYMBOL_PRE_MISS = 5
POPUP_SYMBOL_PRE_EVADE = 6
POPUP_SYMBOL_PRE_DENY = 7
POPUP_SYMBOL_PRE_ARROW = 8

POPUP_SYMBOL_POST_EXCLAMATION = 0
POPUP_SYMBOL_POST_POINTZERO = 1
POPUP_SYMBOL_POST_MEDAL = 2
POPUP_SYMBOL_POST_DROP = 3
POPUP_SYMBOL_POST_LIGHTNING = 4
POPUP_SYMBOL_POST_SKULL = 5
POPUP_SYMBOL_POST_EYE = 6
POPUP_SYMBOL_POST_SHIELD = 7
POPUP_SYMBOL_POST_POINTFIVE = 8


-- e.g. when healed by an ability
function PopupHealing(target, amount)
    PopupNumbers(target, "heal", Vector(0, 255, 0), 1.0, amount, POPUP_SYMBOL_PRE_PLUS, nil)
end

-- e.g. the popup you get when you suddenly take a large portion of your health pool in damage at once
function PopupDamage(target, amount)
    PopupNumbers(target, "damage", Vector(255, 0, 0), 1.0, amount, nil, POPUP_SYMBOL_POST_DROP)
end

-- e.g. when dealing critical damage
function PopupCriticalDamage(target, amount)
    PopupNumbers(target, "crit", Vector(255, 0, 0), 1.0, amount, nil, POPUP_SYMBOL_POST_LIGHTNING)
end

-- e.g. when taking damage over time from a poison type spell
function PopupDoT(target, amount)
    PopupNumbers(target, "poison", Vector(215, 50, 248), 1.0, amount, nil, POPUP_SYMBOL_POST_EYE)
end

-- e.g. when blocking damage with a stout shield
function PopupDamageBlock(target, amount)
    PopupNumbers(target, "block", Vector(255, 255, 255), 1.0, amount, POPUP_SYMBOL_PRE_MINUS, nil)
end

-- e.g. when last-hitting a creep
function PopupGoldGain(target, amount)
    PopupNumbers(target, "gold", Vector(255, 200, 33), 1.0, amount, POPUP_SYMBOL_PRE_PLUS, nil)
end

-- e.g. when missing uphill
function PopupMiss(target)
    PopupNumbers(target, "miss", Vector(255, 0, 0), 1.0, nil, POPUP_SYMBOL_PRE_MISS, nil)
end

-- Customizable version.
function CDOTA_BaseNPC:PopupNumbers(target, pfx, color, lifetime, number, presymbol, postsymbol)
    local armor = target:GetPhysicalArmorValue()
    local damageReduction = ((0.02 * armor) / (1 + 0.02 * armor))
    number = number - (number * damageReduction)
    local lens_count = 0
    for i=0,5 do
       local item = self:GetItemInSlot(i)
       if item ~= nil and item:GetName() == "item_aether_lens" then
           lens_count = lens_count + 1
       end
    end
    number = number * (1 + (.08 * lens_count) + (self:GetIntellect()/1600))

    number = math.floor(number)
    local pfxPath = string.format("particles/msg_fx/msg_%s.vpcf", pfx)      
    local pidx      
    if pfx == "gold" or pfx == "lumber" then        
        pidx = ParticleManager:CreateParticleForTeam(pfxPath, PATTACH_CUSTOMORIGIN, target, target:GetTeamNumber())     
    else        
        pidx = ParticleManager:CreateParticle(pfxPath, PATTACH_CUSTOMORIGIN, target)        
    end     
        
    local digits = 0        
    if number ~= nil then       
        digits = #tostring(number)      
    end     
    if presymbol ~= nil then        
        digits = digits + 1     
    end     
    if postsymbol ~= nil then       
        digits = digits + 1     
    end     
        
    ParticleManager:SetParticleControl(pidx, 0, target:GetAbsOrigin())      
    ParticleManager:SetParticleControl(pidx, 1, Vector(tonumber(presymbol), tonumber(number), tonumber(postsymbol)))        
    ParticleManager:SetParticleControl(pidx, 2, Vector(lifetime, digits, 0))        
    ParticleManager:SetParticleControl(pidx, 3, color)      
end