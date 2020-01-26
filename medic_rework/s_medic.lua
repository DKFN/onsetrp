local _ = function(k, ...) return ImportPackage("i18n").t(GetPackageName(), k, ...) end

local MAX_MEDIC = 10
local ALLOW_RESPAWN_VEHICLE = true

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
    CallRemoteEvent(player, "medic:setup", medicNpcIds, medicVehicleNpcIds, medicGarageIds, medicEquipmentNpcIds)
end)

--------- SERVICE AND EQUIPMENT
function StartStopService(player)
    if PlayerData[player].job == "" then
        StartService(player)
    elseif PlayerData[player].job == "medic" then
        EndService(player)
    else
        CallRemoteEvent(player, "MakeErrorNotification", _("please_leave_previous_job"))
    end
end
AddRemoteEvent("medic:startstopservice", StartStopService)

function StartService(player)
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
    CallRemoteEvent(player, "MakeNotification", _("join_police"), "linear-gradient(to right, #00b09b, #96c93d)")
    return true
end

function EndService(player)
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
    
    CallRemoteEvent(player, "MakeNotification", _("quit_police"), "linear-gradient(to right, #00b09b, #96c93d)")
    
    return true
end

function GiveMedicEquipmentToPlayer(player)-- To give medic equipment to medics
    if PlayerData[player].job == "medic" and PlayerData[player].medic == 1 then -- Fail check
        for k,v in pairs(MEDIC_EQUIPEMENT_NEEDED)do
            SetInventory(player, v.item, v.qty)
        end
    end
end
AddRemoteEvent("medic:checkmyequipment", GivePoliceEquipmentToPlayer)

function RemoveMedicEquipmentToPlayer(player)
    for k,v in pairs(MEDIC_EQUIPEMENT_NEEDED)do
        SetInventory(player, v.item, 0)
    end
end

AddEvent("job:onspawn", function(player)
    if PlayerData[player].job == "medic" and PlayerData[player].medic == 1 then -- Anti glitch
        GiveMedicEquipmentToPlayer(player)
        SetPlayerPropertyValue(player, "Medic:IsOnDuty", true, true)
    end
end)

AddEvent("OnPlayerSpawn", function(player)-- On player death
    if PlayerData and PlayerData[player] then
        GiveMedicEquipmentToPlayer(player)
    end
end)

-- DEV MODE
AddCommand("medic", function(player)
    StartStopService(player)
end)
