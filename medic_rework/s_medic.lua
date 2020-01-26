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