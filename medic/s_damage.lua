local _ = function(k, ...) return ImportPackage("i18n").t(GetPackageName(), k, ...) end

local BLEEDING_CHANCE = 20 -- Chance for the player to bleed on damage
local INITIAL_DAMAGE_TO_BLEED = 2 -- how much the damages have to be divided by
local DAMAGE_PER_TICK = 1 -- the damages the player will take on each tick
local BLEEDING_DAMAGE_INTERVAL = 5000 -- The interval to apply damages
local BLEED_EFFECT_AMOUNT = 70 -- the amount of bleed effect (red flash)

local BODY_Z = 50
local HEAD_Z = 150

local WEAPON_HEADSHOT_MULTIPLIER = 1.7
local WEAPON_BODY_MULTIPLIER = 0.9
local WEAPON_FOOT_MULTIPLIER = 0.3

local TASER_DAMAGES = 5

local bleedingTimers = {}

AddEvent("OnPlayerDeath", function(player, instigator)
    CallRemoteEvent(player, "damage:death:toggleeffect", 1)
end)

AddEvent("OnPlayerSpawn", function(player)
    CallRemoteEvent(player, "damage:death:toggleeffect", 0)
end)

AddEvent("OnPlayerWeaponShot", function(player, weapon, hittype, hitid, hitX, hitY, hitZ, startX, startY, normalX, normalY, normalZ)
        
        if hittype == 2 then -- player
            if weapon == 21 then -- TASER
                SetPlayerHealth(hitid, GetPlayerHealth(hitid) - TASER_DAMAGES) 
                return 
            end
            -- GET WEAPON DAMAGES
            local weaponDamages = 0
            local weaponTable = File_LoadJSONTable('weapons.json')
            weaponDamages = weaponTable.weapons[weapon].Damage or 20
            
            -- GET PLAYER POS
            local x, y, z = GetPlayerLocation(hitid)
            -- GET PLAYER FEETS POS
            local npcFeetPos = z - 90
            
            local damages = 0
            if hitZ > npcFeetPos + HEAD_Z then -- THIS LANDED IN HEAD
                print('TETE')
                damages = (weaponDamages) * WEAPON_HEADSHOT_MULTIPLIER
            elseif hitZ > npcFeetPos + BODY_Z then -- THIS LANDED IN BODY
                print('CORPS')
                damages = (weaponDamages) * WEAPON_BODY_MULTIPLIER
            else -- THIS LANDED IN FEETS
                print('PIED')
                damages = (weaponDamages) * WEAPON_FOOT_MULTIPLIER
            end
            
            print('DAMAGES', damages)
            
            -- SET PLAYER HEALTH
            SetPlayerHealth(hitid, GetPlayerHealth(hitid) - damages)
            PlayerData[hitid].health = GetPlayerHealth(hitid)
            if GetPlayerHealth(hitid) < 0 then -- FAIL CHECK
                SetPlayerHealth(hitid, 0)
                PlayerData[hitid].health = 0
            end
            
            print('VIE', GetPlayerHealth(hitid))
            
            print('DONE ...')

            math.randomseed(os.time())
            local lucky = math.random(100)
            print('LUCKY BLEED', lucky)
            if lucky <= BLEEDING_CHANCE then
                ApplyBleeding(hitid, damages)
                CallRemoteEvent(hitid, "MakeNotification", _("medic_damage_you_are_bleeding"), "linear-gradient(to right, #00b09b, #96c93d)")
            end
        
        end

        return false
end)

local npctest
AddEvent("OnPackageStart", function()
    npctest = CreateNPC(210165, 160910, 1305, 0)
end)

function ApplyBleeding(player, damageAmount)
    local damages = (tonumber(damageAmount) / INITIAL_DAMAGE_TO_BLEED)
    local bleedingTime = math.ceil(damages / DAMAGE_PER_TICK)-- calculate the amount of time while the player will bleed
    print('time', bleedingTime, damages)
    
    bleedingTimers[player] = {}
    
    CallRemoteEvent(player, "damage:bleed:toggleeffect", 1)
    
    local i = 0
    bleedingTimers[player].timer = CreateTimer(function()
        if i >= bleedingTime or GetPlayerHealth(player) < 1 then -- end is reached
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

AddCommand("hh", function(player)
    SetPlayerHealth(player, 100)    
end)
