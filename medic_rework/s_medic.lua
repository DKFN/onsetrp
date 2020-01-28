local _ = function(k, ...) return ImportPackage("i18n").t(GetPackageName(), k, ...) end

local MAX_MEDIC = 10
local ALLOW_RESPAWN_VEHICLE = true
local TIMER_BEFORE_RESPAWN_WITHOUT_MEDIC = 10 -- 10 secondes
local TIMER_BEFORE_RESPAWN = 900 -- 15 minutes
local REVIVE_PERCENT_SUCCESS = 33 -- in percent
local TIME_TO_REVIVE = 5 -- in seconds
local AUTO_CALL_FOR_MEDIC = false
local TIME_TO_HEAL = 5 -- in seconds 
local AMOUNT_TO_HEAL_PER_INTERACTION = 20 -- Hp that will be healed each time the medic interact 

local DEFAULT_RESPAWN_POINT = {x = 212124, y = 159055, z = 1305, h = 90}

local VEHICLE_SPAWN_LOCATION = {
    {x = 213325, y = 161177, z = 1305, h = -90},
}

local MEDIC_SERVICE_NPC = {
    {x = 211596, y = 159679, z = 1320, h = 90},
}

local MEDIC_VEHICLE_NPC = {
    {x = 212571, y = 159486, z = 1320, h = 90},
}

local MEDIC_GARAGE = {
    {x = 215766, y = 161131, z = 1305},
}

local MEDIC_EQUIPMENT_NPC = {
    {x = 211252, y = 158777, z = 1322, h = 90},
}

local MEDIC_HOSPITAL_LOCATION = {
    {x = 212122, y = 158715, radius=2000}
}

local MEDIC_EQUIPEMENT_NEEDED = {
    {item = "defibrillator", qty = 1},
    {item = "adrenaline_syringe", qty = 2},
    {item = "bandage", qty = 5},
    {item = "health_kit", qty = 1},
}

local medicNpcIds = {}
local medicVehicleNpcIds = {}
local medicGarageIds = {}
local medicEquipmentNpcIds = {}
local medicHospitalLocationIds = {}

local callOuts = {}

AddEvent("OnPackageStart", function()
    for k, v in pairs(MEDIC_SERVICE_NPC) do
        v.npcObject = CreateNPC(v.x, v.y, v.z, v.h)
        
        table.insert(medicNpcIds, v.npcObject)
    end
    
    if ALLOW_RESPAWN_VEHICLE then
        for k, v in pairs(MEDIC_GARAGE) do
            v.garageObject = CreatePickup(2, v.x, v.y, v.z)
            table.insert(medicGarageIds, v.garageObject)
        end
    end
    
    for k, v in pairs(MEDIC_VEHICLE_NPC) do
        v.npcObject = CreateNPC(v.x, v.y, v.z, v.h)
        SetNPCAnimation(v.npcObject, "WALLLEAN04", true)
        table.insert(medicVehicleNpcIds, v.npcObject)
    end
    
    for k, v in pairs(MEDIC_EQUIPMENT_NPC) do
        v.npcObject = CreateNPC(v.x, v.y, v.z, v.h)
        SetNPCAnimation(v.npcObject, "WALLLEAN04", true)
        table.insert(medicEquipmentNpcIds, v.npcObject)
    end
end)

AddEvent("OnPlayerJoin", function(player)
    CallRemoteEvent(player, "medic:setup", medicNpcIds, medicVehicleNpcIds, medicGarageIds, medicEquipmentNpcIds, medicHospitalLocationIds)
end)

--------- SERVICE AND EQUIPMENT
function StartStopService(player) -- toggle service
    if PlayerData[player].job == "" then
        StartService(player)
    elseif PlayerData[player].job == "medic" then
        EndService(player)
    else
        CallRemoteEvent(player, "MakeErrorNotification", _("please_leave_previous_job"))
    end
end
AddRemoteEvent("medic:startstopservice", StartStopService)

function StartService(player) -- start service
    -- #1 Check for the medic whitelist of the player
    if PlayerData[player].medic ~= 1 then
        CallRemoteEvent(player, "MakeErrorNotification", _("not_whitelisted"))
        return
    end
    
    -- #2 Check if the player has a job vehicle spawned then destroy it
    if PlayerData[player].job_vehicle ~= nil then
        DestroyVehicle(PlayerData[player].job_vehicle)
        DestroyVehicleData(PlayerData[player].job_vehicle)
        PlayerData[player].job_vehicle = nil
    end
    
    -- #3 Check for the number of medics in service
    local medics = 0
    for k, v in pairs(PlayerData) do
        if v.job == "medic" then medics = medics + 1 end
    end
    if medics >= MAX_MEDIC then
        CallRemoteEvent(player, "MakeErrorNotification", _("job_full"))
        return
    end
    
    -- #4 Set the player job to medic, update the cloths, give equipment
    PlayerData[player].job = "medic"
    SetPlayerPropertyValue(player, "Medic:IsOnDuty", true, true)
    -- CLOTHINGS
    GiveMedicEquipmentToPlayer(player)
    UpdateClothes(player)
    CallRemoteEvent(player, "MakeNotification", _("medic_start_service"), "linear-gradient(to right, #00b09b, #96c93d)")
    return true
end

function EndService(player) -- stop service
    -- #1 Remove medic equipment
    RemoveMedicEquipmentToPlayer(player)
    if PlayerData[player].job_vehicle ~= nil then
        DestroyVehicle(PlayerData[player].job_vehicle)
        DestroyVehicleData(PlayerData[player].job_vehicle)
        PlayerData[player].job_vehicle = nil
    end
    -- #2 Set player job
    PlayerData[player].job = ""
    SetPlayerPropertyValue(player, "Medic:IsOnDuty", false, true)
    -- #3 Trigger update of cloths
    UpdateClothes(player)
    
    CallRemoteEvent(player, "MakeNotification", _("medic_end_service"), "linear-gradient(to right, #00b09b, #96c93d)")
    
    return true
end

function GiveMedicEquipmentToPlayer(player)-- To give medic equipment to medics
    if PlayerData[player].job == "medic" and PlayerData[player].medic == 1 then -- Fail check
        for k, v in pairs(MEDIC_EQUIPEMENT_NEEDED) do
            SetInventory(player, v.item, v.qty)
        end
    end
end
AddRemoteEvent("medic:checkmyequipment", GiveMedicEquipmentToPlayer)

function RemoveMedicEquipmentToPlayer(player) -- remove equipment from a medic
    for k, v in pairs(MEDIC_EQUIPEMENT_NEEDED) do
        SetInventory(player, v.item, 0)
    end
end

AddEvent("job:onspawn", function(player) -- when player is fully loaded
    if PlayerData[player].job == "medic" and PlayerData[player].medic == 1 then -- Anti glitch
        SetPlayerPropertyValue(player, "Medic:IsOnDuty", true, true)
    end
    
    if PlayerData[player].health ~= nil then
        SetPlayerHealth(player, PlayerData[player].health)
    end
end)

AddEvent("OnPlayerSpawn", function(player)-- On player death
    if PlayerData and PlayerData[player] then
        GiveMedicEquipmentToPlayer(player)
    end
end)
--------- SERVICE AND EQUIPMENT END
--------- MEDIC VEHICLE
function SpawnMedicCar(player) -- to spawn an ambulance
    -- #1 Check for the medic whitelist of the player
    if PlayerData[player].medic ~= 1 then
        CallRemoteEvent(player, "MakeErrorNotification", _("not_whitelisted"))
        return
    end
    if PlayerData[player].job ~= "medic" then
        CallRemoteEvent(player, "MakeErrorNotification", _("not_medic"))
        return
    end
    
    -- #2 Check if the player has a job vehicle spawned then destroy it
    if PlayerData[player].job_vehicle ~= nil and ALLOW_RESPAWN_VEHICLE then
        DestroyVehicle(PlayerData[player].job_vehicle)
        DestroyVehicleData(PlayerData[player].job_vehicle)
        PlayerData[player].job_vehicle = nil
    end
    
    -- #3 Try to spawn the vehicle
    if PlayerData[player].job_vehicle == nil then
        local spawnPoint = VEHICLE_SPAWN_LOCATION[GetClosestSpawnPoint(player)]
        if spawnPoint == nil then return end
        for k, v in pairs(GetStreamedVehiclesForPlayer(player)) do
            local x, y, z = GetVehicleLocation(v)
            if x == false then break end
            local dist2 = GetDistance3D(spawnPoint.x, spawnPoint.y, spawnPoint.z, x, y, z)
            if dist2 < 500.0 then
                CallRemoteEvent(player, "MakeErrorNotification", _("cannot_spawn_vehicle"))
                return
            end
        end
        local vehicle = CreateVehicle(8, spawnPoint.x, spawnPoint.y, spawnPoint.z, spawnPoint.h)
        
        PlayerData[player].job_vehicle = vehicle
        CreateVehicleData(player, vehicle, 3)
        SetVehiclePropertyValue(vehicle, "locked", true, true)
        CallRemoteEvent(player, "MakeNotification", _("spawn_vehicle_success", _("medic_car")), "linear-gradient(to right, #00b09b, #96c93d)")
    else
        CallRemoteEvent(player, "MakeErrorNotification", _("cannot_spawn_vehicle"))
    end
end
AddRemoteEvent("medic:spawnvehicle", SpawnMedicCar)

function DespawnMedicCar(player) -- to despawn an ambulance
    -- #2 Check if the player has a job vehicle spawned then destroy it
    if PlayerData[player].job_vehicle ~= nil then
        DestroyVehicle(PlayerData[player].job_vehicle)
        DestroyVehicleData(PlayerData[player].job_vehicle)
        PlayerData[player].job_vehicle = nil
        CallRemoteEvent(player, "MakeNotification", _("vehicle_stored"), "linear-gradient(to right, #00b09b, #96c93d)")
        return
    end
end

AddEvent("OnPlayerPickupHit", function(player, pickup)-- Store the vehicle in garage
    if PlayerData[player].medic ~= 1 then return end
    if PlayerData[player].job ~= "medic" then return end
    for k, v in pairs(MEDIC_GARAGE) do
        if v.garageObject == pickup then
            local vehicle = GetPlayerVehicle(player)
            if vehicle == nil then return end
            local seat = GetPlayerVehicleSeat(player)
            if vehicle == PlayerData[player].job_vehicle and
                VehicleData[vehicle].owner == PlayerData[player].accountid and
                seat == 1
            then
                DespawnMedicCar(player)
            end
        end
    end
end)
--------- MEDIC VEHICLE END
--------- INTERACTIONS
function PutPlayerInCar(player)-- to put player in car
    if PlayerData[player].medic ~= 1 then return end
    if PlayerData[player].job ~= "medic" then return end
    
    local target = GetNearestPlayer(player, 200)
    if target ~= nil then
        SetPlayerInCar(player, target)
    end
end
AddRemoteEvent("medic:playerincar", PutPlayerInCar)

function SetPlayerInCar(player, target) -- put player in car
    if PlayerData[player].job_vehicle == nil then return end
    local x, y, z = GetVehicleLocation(PlayerData[player].job_vehicle)
    local x2, y2, z2 = GetPlayerLocation(target)
    
    if GetDistance3D(x, y, z, x2, y2, z2) <= 400 then
        if GetVehiclePassenger(PlayerData[player].job_vehicle, 3) == 0 then -- First back seat
            SetPlayerInVehicle(target, PlayerData[player].job_vehicle, 3)
            CallRemoteEvent(player, "MakeNotification", _("mediccar_place_player_in_back"), "linear-gradient(to right, #00b09b, #96c93d)")
        elseif GetVehiclePassenger(PlayerData[player].job_vehicle, 4) == 0 then -- Second back seat
            SetPlayerInVehicle(target, PlayerData[player].job_vehicle, 4)
            CallRemoteEvent(player, "MakeNotification", _("mediccar_place_player_in_back"), "linear-gradient(to right, #00b09b, #96c93d)")
        else -- All seats are busy
            CallRemoteEvent(player, "MakeErrorNotification", _("mediccar_no_more_seat"))
        end
    else -- Too far away
        CallRemoteEvent(player, "MakeErrorNotification", _("mediccar_too_far_away"))
    end
end

function RemovePlayerInCar(player) -- remove player from car
    if PlayerData[player].medic ~= 1 then return end
    if PlayerData[player].job ~= "medic" then return end
    if PlayerData[player].job_vehicle == nil then return end
    
    local x, y, z = GetVehicleLocation(PlayerData[player].job_vehicle)
    local x2, y2, z2 = GetPlayerLocation(player)
    
    if GetDistance3D(x, y, z, x2, y2, z2) <= 200 then
        if GetVehiclePassenger(PlayerData[player].job_vehicle, 3) ~= 0 then -- First back seat
            RemovePlayerFromVehicle(GetVehiclePassenger(PlayerData[player].job_vehicle, 3))
        end
        if GetVehiclePassenger(PlayerData[player].job_vehicle, 4) ~= 0 then -- Second back seat
            RemovePlayerFromVehicle(GetVehiclePassenger(PlayerData[player].job_vehicle, 4))
        end
        CallRemoteEvent(player, "MakeNotification", _("mediccar_player_remove_from_car"), "linear-gradient(to right, #00b09b, #96c93d)")
    end
end
AddRemoteEvent("medic:removeplayerincar", RemovePlayerInCar)

function RevivePlayer(player) -- To revive a player. can fail. need defib.
    if PlayerData[player].medic ~= 1 then return end
    if PlayerData[player].job ~= "medic" then return end
    if GetPlayerBusy(player) then return end
    
    local nearestPlayer = GetNearestPlayer(player, 200)-- Get closest player in range
    if nearestPlayer == nil or nearestPlayer == 0 then
        CallRemoteEvent(player, "MakeErrorNotification", _("medic_nobody_nearby"))
        return
    end
    if GetPlayerHealth(nearestPlayer) > 0 then -- Cehck HP
        CallRemoteEvent(player, "MakeErrorNotification", _("medic_nobody_is_dead"))
        return
    end
    
    if GetNumberOfItem(player, "defibrillator") < 1 then -- Check defib in inventory
        CallRemoteEvent(player, "MakeErrorNotification", _("medic_defibrillator_needed"))
        return
    end

    -- Lock player while he's acting
    CallRemoteEvent(player, "LockControlMove", true)
    SetPlayerBusy(player)
    
    CallRemoteEvent(player, "loadingbar:show", _("medic_revive_attempt"), TIME_TO_REVIVE)-- LOADING BAR
    SetPlayerAnimation(player, "REVIVE")
    local timer = CreateTimer(function()
        SetPlayerAnimation(player, "REVIVE")
    end, 4000)
    
    Delay(TIME_TO_REVIVE * 1000, function()
        DestroyTimer(timer)
        SetPlayerAnimation(player, "STOP")

        -- Unlock player
        CallRemoteEvent(player, "LockControlMove", false)
        SetPlayerNotBusy(player)

        math.randomseed(os.time())
        local lucky = math.random(100)
        if lucky > REVIVE_PERCENT_SUCCESS then -- Success !
            local x, y, z = GetPlayerLocation(nearestPlayer)
            local h = GetPlayerHeading(nearestPlayer)
            SetPlayerSpawnLocation(nearestPlayer, x, y, z, h)
            SetPlayerRespawnTime(nearestPlayer, 0)
            Delay(100, function()
                SetPlayerHealth(nearestPlayer, 1.0)
                PlayerData[nearestPlayer].health = 1
            end)
            
            CallRemoteEvent(player, "MakeNotification", _("medic_revived_success"), "linear-gradient(to right, #00b09b, #96c93d)")
            if callOuts[nearestPlayer] and callOuts[nearestPlayer].taken == true then MedicCalloutEnd(player, nearestPlayer) end
            return
        else -- Failure !
            CallRemoteEvent(player, "MakeErrorNotification", _("medic_revived_failure"))
            return
        end
    end)
end
AddRemoteEvent("medic:interact:revive", RevivePlayer)

function TruelyHealPlayer(player) -- To really heal a player. This need to be at the hospital.
    if PlayerData[player].medic ~= 1 then return end
    if PlayerData[player].job ~= "medic" then return end
    if GetPlayerBusy(player) then return end

    local nearestPlayer = GetNearestPlayer(player, 200)-- Get closest player in range
    if nearestPlayer == nil or nearestPlayer == 0 then
        CallRemoteEvent(player, "MakeErrorNotification", _("medic_nobody_nearby"))
        return
    end

    if not IsHospitalInRange(player) or not IsHospitalInRange(tonumber(nearestPlayer)) then
        CallRemoteEvent(player, "MakeErrorNotification", _("medic_hospital_needed_to_heal"))
        return
    end

    if GetPlayerHealth(nearestPlayer) >= 100 then -- Cehck HP
        CallRemoteEvent(player, "MakeErrorNotification", _("medic_player_is_fullhp"))
        return
    end

    -- Lock player while he's healing
    SetPlayerBusy(player)

    CallRemoteEvent(player, "loadingbar:show", _("medic_healing_in_progress"), TIME_TO_HEAL)-- LOADING BAR
    SetPlayerAnimation(player, "HANDSHAKE")
    local timer = CreateTimer(function()
        SetPlayerAnimation(player, "HANDSHAKE")
    end, 4000)
    
    Delay(TIME_TO_HEAL * 1000, function()
        DestroyTimer(timer)
        SetPlayerAnimation(player, "STOP")

        -- Unlock player
        SetPlayerNotBusy(player)
        
        SetPlayerHealth(player, GetPlayerHealth(player) + 20)
        if GetPlayerHealth(player) > 100 then
            SetPlayerHealth(player, 100)
        end
        PlayerData[nearestPlayer].health = GetPlayerHealth(player)
        
        CallRemoteEvent(player, "MakeNotification", _("medic_done_healing"), "linear-gradient(to right, #00b09b, #96c93d)")
        return
    end)    
end
AddRemoteEvent("medic:interact:heal", TruelyHealPlayer)

--------- INTERACTIONS END
--------- HEALTH BEHAVIOR
AddEvent("OnPlayerDeath", function(player, instigator) -- do some stuff when player die
    SetPlayerSpawnLocation(player, DEFAULT_RESPAWN_POINT.x, DEFAULT_RESPAWN_POINT.y, DEFAULT_RESPAWN_POINT.z, DEFAULT_RESPAWN_POINT.h)-- HOSPITAL
    
    AddPlayerChat(player, _("medic_x_medics_on_duty", GetMedicsOnDuty(player)))
    AddPlayerChat(player, _("medic_help_tooltip"))
    if GetMedicsOnDuty(player) > 0 then
        SetPlayerRespawnTime(player, TIMER_BEFORE_RESPAWN * 1000)
        if AUTO_CALL_FOR_MEDIC == true then CreateMedicCallout(player) end
    else
        SetPlayerRespawnTime(player, TIMER_BEFORE_RESPAWN_WITHOUT_MEDIC * 1000)
    end
end)

--------- HEALTH BEHAVIOR END
--------- CALLOUTS
function CreateMedicCallout(player) -- create a new callout
    if GetPlayerHealth(player) > 50 then return end     -- To not bother medics with trolls
    local x, y, z = GetPlayerLocation(player)
    if callOuts[player] ~= nil then return end
    callOuts[player] = {location = {x = x, y = y, z = z}, taken = false}
    MedicCalloutSend(player)
end

function MedicCalloutSend(player) -- send the new callout to medics
    for k, v in pairs(GetAllPlayers()) do
        if PlayerData[v].medic ~= 1 then return end
        if PlayerData[v].job ~= "medic" then return end
        CallRemoteEvent(player, "medic:callout:updatepending", player)
        CallRemoteEvent(player, "MakeNotification", _("medic_someone_is_in_trouble"), "linear-gradient(to right, #00b09b, #96c93d)", 10000)
    end
end

function MedicCalloutTake(player, target) -- allow a medic to take the callout
    if PlayerData[player].medic ~= 1 and PlayerData[player].job ~= "medic" then return end
    if callOuts[tonumber(target)] == nil then return end
    if callOuts[tonumber(target)].taken ~= false then
        CallRemoteEvent(player, "MakeErrorNotification", _("medic_callout_taken"))
        return
    end
    callOuts[tonumber(target)].taken = true
    CallRemoteEvent(player, "medic:callout:createwp", tonumber(target))
    CallRemoteEvent(player, "MakeNotification", _("medic_you_took_callout"), "linear-gradient(to right, #00b09b, #96c93d)")
    CallRemoteEvent(tonumber(target), "MakeNotification", _("medic_callout_medic_is_coming"), "linear-gradient(to right, #00b09b, #96c93d)", 10000)
end
AddRemoteEvent("medic:callout:start", MedicCalloutTake)

function MedicCalloutEnd(player, target) -- allow a medic to end a callout
    if PlayerData[player].medic ~= 1 and PlayerData[player].job ~= "medic" then return end
    if callOuts[tonumber(target)] == nil then return end
    if callOuts[tonumber(target)].taken ~= true then
        CallRemoteEvent(player, "MakeErrorNotification", _("an_error_occured"))
        return
    end
    callOuts[tonumber(target)] = nil
    CallRemoteEvent(player, "medic:callout:clean", tonumber(target))
    CallRemoteEvent(player, "MakeNotification", _("medic_ended_callout"), "linear-gradient(to right, #00b09b, #96c93d)")
end
AddRemoteEvent("medic:callout:end", MedicCalloutEnd)

AddCommand("medcallend", MedicCalloutEnd)
--------- CALLOUTS END
-- Tools
function GetClosestSpawnPoint(player) -- get closeest spawn point for vehicle
    local x, y, z = GetPlayerLocation(player)
    local closestSpawnPoint
    local dist
    for k, v in pairs(VEHICLE_SPAWN_LOCATION) do
        local currentDist = GetDistance3D(x, y, z, v.x, v.y, v.z)
        if (dist == nil or currentDist < dist) and currentDist <= 2000 then
            closestSpawnPoint = k
            dist = currentDist
        end
    end
    return closestSpawnPoint
end

function GetMedicsOnDuty(player) -- numbers of medics on duty
    local nb = 0
    for k, v in pairs(GetAllPlayers()) do
        if PlayerData[v].job == "medic" 
        --and v ~= player 
        then
            nb = nb + 1
        end
    end
    return nb
end

function IsHospitalInRange(player) -- to nknow if player and targets are in range from hospital
    local x,y,z = GetPlayerLocation(player)    
    for k,v in pairs(MEDIC_HOSPITAL_LOCATION) do
        if GetDistance2D(x, y, v.x, v.y) <= v.radius then
            return true
        end        
    end
    return false
end

-- DEV MODE

AddCommand("suicide", function(player)
    SetPlayerHealth(player, 0)
end)

AddCommand("helpme", function(player)
    CreateMedicCallout(player)
end)


