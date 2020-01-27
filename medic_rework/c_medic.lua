local Dialog = ImportPackage("dialogui")
local _ = function(k, ...) return ImportPackage("i18n").t(GetPackageName(), k, ...) end

local medicMenu
local medicNpcGarageMenu
local medicEquipmentMenu

local medicNpcIds = {}
local medicVehicleNpcIds = {}
local medicGarageIds = {}
local medicEquipmentNpcIds = {}
local medicHospitalLocationIds = {}

local wpObject
local currentCallout
local pendingCallout

AddRemoteEvent("medic:setup", function(_medicNpcIds, _medicVehicleNpcIds, _medicGarageIds, _medicEquipmentNpcIds, _medicHospitalLocationIds)
    medicNpcIds = _medicNpcIds
    medicVehicleNpcIds = _medicVehicleNpcIds
    medicGarageIds = _medicGarageIds
    medicEquipmentNpcIds = _medicEquipmentNpcIds
    medicHospitalLocationIds = _medicHospitalLocationIds
end)

AddEvent("OnTranslationReady", function()
        -- MEDIC MENU : Gros soins, Mettre / sortir d'un véhicle, end callout
        medicMenu = Dialog.create(_("medic_menu"), nil, _("medic_menu_true_heal"), _("medic_menu_revive"), _("medic_menu_put_player_in_vehicle"), _("medic_menu_remove_player_from_vehicle"), _("medic_callout_take"), _("medic_menu_end_callout"), _("cancel"))
        
        -- MEDIC NPC GARAGE MENU
        medicNpcGarageMenu = Dialog.create(_("medic_garage_menu"), nil, _("medic_garage_menu_spawn_ambulance"), _("cancel"))
        
        -- MEDIC EQUIPMENT MENU
        medicEquipmentMenu = Dialog.create(_("medic_equipment_menu"), nil, _("medic_equipment_menu_check_equipment"), _("cancel"))
end)

AddEvent("OnKeyPress", function(key)
    local IsOnDuty = GetPlayerPropertyValue(GetPlayerId(), "Medic:IsOnDuty") or false
    if key == JOB_MENU_KEY and not GetPlayerBusy() and IsOnDuty then
        Dialog.show(medicMenu)
    end
    
    if key == INTERACT_KEY and not GetPlayerBusy() and IsOnDuty and IsNearbyNpc(GetPlayerId(), medicVehicleNpcIds) ~= false then
        Dialog.show(medicNpcGarageMenu)
    end
    
    if key == INTERACT_KEY and not GetPlayerBusy() and IsOnDuty and IsNearbyNpc(GetPlayerId(), medicEquipmentNpcIds) ~= false then
        Dialog.show(medicEquipmentMenu)
    end
end)

AddEvent("OnDialogSubmit", function(dialog, button, ...)
    local args = {...}
    if dialog == medicMenu then
        if button == 1 then -- heal
            CallRemoteEvent("medic:interact:heal")
        end
        if button == 2 then -- revive
            CallRemoteEvent("medic:interact:revive")
        end
        if button == 3 then -- put in vehicle
            CallRemoteEvent("medic:playerincar")
        end
        if button == 4 then -- remove from vehicle
            CallRemoteEvent("medic:removeplayerincar")
        end
        if button == 5 then -- take callout
            CallRemoteEvent("medic:callout:start", pendingCallout)
        end
        if button == 6 then -- end callout
            CallRemoteEvent("medic:callout:end", currentCallout)
        end
    end
    
    if dialog == medicNpcGarageMenu then
        if button == 1 then
            CallRemoteEvent("medic:spawnvehicle")
        end
    end
    
    if dialog == medicEquipmentMenu then
        if button == 1 then
            CallRemoteEvent("medic:checkmyequipment")
            MakeNotification(_("medic_equipment_checked"), "linear-gradient(to right, #00b09b, #96c93d)")
        end
    end
end)

AddRemoteEvent("medic:callout:updatepending", function(target)
    pendingCallout = target
end)

AddRemoteEvent("medic:callout:createwp", function(target)
    currentCallout = target
    local x, y, z = GetPlayerLocation(target)
    wpObject = CreateWaypoint(x, y, z, _("medic_waypoing_label"))
end)

AddRemoteEvent("medic:callout:clean", function()
    currentCallout = nil
    if wpObject ~= nil then DestroyWaypoint(wpObject) end
    wpObject = nil
end)
