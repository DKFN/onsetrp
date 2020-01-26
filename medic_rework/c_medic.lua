local Dialog = ImportPackage("dialogui")
local _ = function(k, ...) return ImportPackage("i18n").t(GetPackageName(), k, ...) end


local medicNpcIds = {}
local medicVehicleNpcIds = {}
local medicGarageIds = {}
local medicEquipmentNpcIds = {}

AddRemoteEvent("medic:setup", function(_medicNpcIds, _medicVehicleNpcIds, _medicGarageIds, _medicEquipmentNpcIds)
    medicNpcIds = _medicNpcIds
    medicVehicleNpcIds = _medicVehicleNpcIds
    medicGarageIds = _medicGarageIds
    medicEquipmentNpcIds = _medicEquipmentNpcIds
end)

AddEvent("OnTranslationReady", function()

end)