local Dialog = ImportPackage("dialogui")
local _ = function(k, ...) return ImportPackage("i18n").t(GetPackageName(), k, ...) end


local medicNpcIds = {}
local medicVehicleNpcIds = {}
local medicGarageIds = {}
local medicEquipmentNpcIds = {}
local medicHospitalLocationIds = {}

local wpObject
local currentCallout

AddRemoteEvent("medic:setup", function(_medicNpcIds, _medicVehicleNpcIds, _medicGarageIds, _medicEquipmentNpcIds, _medicHospitalLocationIds)
    medicNpcIds = _medicNpcIds
    medicVehicleNpcIds = _medicVehicleNpcIds
    medicGarageIds = _medicGarageIds
    medicEquipmentNpcIds = _medicEquipmentNpcIds
    medicHospitalLocationIds = _medicHospitalLocationIds
end)

AddEvent("OnTranslationReady", function()

end)


AddRemoteEvent("medic:callout:createwp", function(target)
    currentCallout = target
    local x,y,z = GetPlayerLocation(target)    
    wpObject = CreateWaypoint(x, y, z, "URGENCE MEDICALE")    
end)

AddRemoteEvent("medic:callout:clean", function()
    currentCallout = nil
    if wpObject ~= nil then DestroyWaypoint(wpObject) end    
    wpObject = nil
end)
