local BLEEDING_CHANCE = 20 -- Chance for the player to bleed on damage
local INITIAL_DAMAGE_TO_BLEED = 2 -- how much the damages have to be divided by
local DAMAGE_PER_TICK = 1 -- the damages the player will take on each tick
local BLEEDING_DAMAGE_INTERVAL = 5000 -- The interval to apply damages
local BLEED_EFFECT_AMOUNT = 70 -- the amount of bleed effect (red flash)

local BODY_Z = 50
local HEAD_Z = 150

local WEAPON_HEADSHOT_MULTIPLIER = 2
local WEAPON_BODY_MULTIPLIER = 1
local WEAPON_FOOT_MULTIPLIER = 0.5

local bleedingTimers = {}

AddEvent("OnPlayerDeath", function(player, instigator)
    CallRemoteEvent(player, "damage:death:toggleeffect", 1)
end)

AddEvent("OnPlayerSpawn", function(player)
    CallRemoteEvent(player, "damage:death:toggleeffect", 0)
end)

AddEvent("OnPlayerWeaponShot", function(player, weapon, hittype, hitid, hitX, hitY, hitZ, startX, startY, normalX, normalY, normalZ)
    print('SHOT', weapon)

    local playerHealth = GetPlayerHealth(hitid)    
    local weaponDamages = 0

    local weaponTable = File_LoadJSONTable('weapons.json')
    weaponDamages = weaponTable.weapons[weapon].Damage or 20

    print('DAMAGE',weaponDamages)
    if hittype == 2 then -- player
    else -- npc

        local npcx,npcy,npcz = GetPlayerLocation(hitid)
        local npcFeetPos = npcz-90

        print('Z', npcFeetPos, hitZ)

        if hitZ > npcFeetPos + HEAD_Z then
            print('TETE')
            
            playerHealth = playerHealth - (weaponDamages) * WEAPON_HEADSHOT_MULTIPLIER
        elseif hitZ > npcFeetPos + BODY_Z then
            print('CORPS')
            playerHealth = playerHealth - (weaponDamages) * WEAPON_BODY_MULTIPLIER
        else
            print('PIED')
            playerHealth = playerHealth - (weaponDamages) * WEAPON_FOOT_MULTIPLIER
        end
        
        print('VIE',playerHealth)

        SetPlayerHealth(hitid, playerHealth)
        print('damage dealt')        

    end
end)

local npctest
AddEvent("OnPackageStart", function()
    npctest = CreateNPC(210165, 160910, 1305, 0)    
end)



AddEvent("OnPlayerDamage", function(player, damagetype, amount)
    print('DAMAGE', player, damagetype, amount)

    math.randomseed(os.time())
    local lucky = math.random(100)
    if lucky <= BLEEDING_CHANCE then
        ApplyBleeding(player, amount)
        CallRemoteEvent(player, "MakeNotification", _("medic_damage_you_are_bleeding"), "linear-gradient(to right, #00b09b, #96c93d)")
    end
-- Weapn = 1
end)

function ApplyBleeding(player, damageAmount)
    local damages = (tonumber(damageAmount) / INITIAL_DAMAGE_TO_BLEED)
    local bleedingTime = math.ceil(damages / DAMAGE_PER_TICK)-- calculate the amount of time while the player will bleed
    print('time', bleedingTime, damages)
    
    bleedingTimers[player] = {}
    
    CallRemoteEvent(player, "damage:bleed:toggleeffect", 1)
    
    local i = 0
    bleedingTimers[player].timer = CreateTimer(function()
        if i >= bleedingTime then -- end is reached
            CallRemoteEvent(player, "damage:bleed:toggleeffect", 0)
            DestroyTimer(bleedingTimers[player].timer)
            bleedingTimers[player] = nil
            print('bleeding stopped')
            return
        end
        i = i + 1
        
        print('applying ' .. DAMAGE_PER_TICK .. ' dmg')
        SetPlayerHealth(player, GetPlayerHealth(player) - DAMAGE_PER_TICK)
        CallRemoteEvent(player, "damage:bleed:tickeffect", BLEED_EFFECT_AMOUNT)
    
    end, BLEEDING_DAMAGE_INTERVAL)
end

AddCommand("bleed", function(player, amount)
    ApplyBleeding(player, amount)
end)

AddCommand("death", function(player, active)
    CallRemoteEvent(player, "damage:death:toggleeffect", active)
    
end)



-- EN TEST
-- local OGK_TRUE_DMG_DEBUG = true
-- local debug_npc
-- local HEADSHOT_BONUS = 35
-- local CORPSE_BONUS = 10

-- local function debug(message)
--     if OGK_TRUE_DMG_DEBUG then
--         print("[OGK][GG] True DMG -- " .. message)
--     end
-- end

-- local function OnPlayerWeaponShot(player, weapon, hittype, hitid, hitx, hity, hitz, startx, starty, startz, normalx, normaly, normalz)
--     local healthSetter
--     local healthGetter
--     local positionGetter
    
--     if hittype == 2 then
--         healthSetter = SetPlayerHealth
--         healthGetter = GetPlayerHealth
--         positionGetter = GetPlayerLocation
--         armorGetter = GetPlayerArmor
--     elseif hittype == 4 then
--         healthSetter = SetNPCHealth
--         healthGetter = GetNPCHealth
--         positionGetter = GetNPCLocation
--         armorGetter = function() return 0 end
--     end
    
--     if hittype == 2 or hittype == 4 then
--         -- First find the player that is in range of the hit
--         local victim = hitid
--         local victimx, victimy, victimz = positionGetter(hitid)
        
        
--         local victim_feet_pos = victimz - 90;
        
--         -- Finding where the hit happend and then adding bonus/malus to dmg
--         local hit_pos
--         local victim_health = healthGetter(hitid)
--         local final_health = victim_health
--         local crouched = GetPlayerMovementMode(hitid) == 4 -- 2 Walking 4 Crouched
--         local corpseThreshold
        
--         if crouched then
--             corpseThreshold = 25
--             headTreshold = 50
--         else
--             corpseThreshold = 50
--             headTreshold = 150
--         end
        
--         -- TODO: Handle armor
--         if hitz > victim_feet_pos + corpseThreshold then
--             final_health = victim_health - CORPSE_BONUS
--         end
--         if hitz > victim_feet_pos + headTreshold then
--             CallRemoteEvent(player, "TrueDmgHeadShot")
--             final_health = victim_health - HEADSHOT_BONUS
--         end
        
--         if final_health <= 0 then
--             final_health = 1
--         end
        
--         healthSetter(victim, final_health)
--         --debug("Registered hit by "..player.." | VICTIM FEETS "..victim_feet_pos.." | HIT Y: "..hity.." HIT Z: "..hitz)
--         debug("Pre-hit damage setting" .. final_health)
--     end
-- end
-- AddEvent("OnPlayerWeaponShot", OnPlayerWeaponShot)

-- if OGK_TRUE_DMG_DEBUG then
--     AddEvent("OnPackageStart", function()
--         debug("Debug mode")
--         debug_npc = CreateNPC(42180.0, 201287.0, 551.0, 0)
--     end)
-- end
