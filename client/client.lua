local QBCore = exports["qb-core"]:GetCoreObject()

local handleMods = {
    {"fInitialDragCoeff", 90.22},
    {"fDriveInertia", .31},
    {"fSteeringLock", 22},
    {"fTractionCurveMax", -1.1},
    {"fTractionCurveMin", -.4},
    {"fTractionCurveLateral", 2.5},
    {"fLowSpeedTractionLossMult", -.57}
}

local playerPed, vehicle
local driftMode = false
local peds = Config.Utility.Peds

CreateThread(function()
    for _, item in pairs(peds) do RequestModel(item.hash) while not HasModelLoaded(item.hash) do Wait(1) end
        ped =  CreatePed(item.type, item.hash, item.x, item.y, item.z, item.a, false, true)
        SetBlockingOfNonTemporaryEvents(ped, true) SetPedDiesWhenInjured(ped, false) SetEntityHeading(ped, item.h) SetPedCanPlayAmbientAnims(ped, true) SetPedCanRagdollFromPlayerImpact(ped, false) 
        SetEntityInvincible(ped, true) FreezeEntityPosition(ped, true)
    end
end)

CreateThread(function()
    if Config.Utility.Blips.Enable then
    for _, info in pairs(Config.Utility.Locations) do local blip = AddBlipForCoord(info.x, info.y, info.z) SetBlipSprite(blip, Config.Utility.Blips.Sprite) SetBlipDisplay(blip, 4) SetBlipScale(blip, Config.Utility.Blips.Scale) SetBlipAsShortRange(blip, true)
        SetBlipColour(blip, Config.Utility.Blips.Colour) BeginTextCommandSetBlipName("STRING") AddTextComponentSubstringPlayerName(Config.Utility.Blips.Name) EndTextCommandSetBlipName(blip)
    end end 
end)

CreateThread(function ()
    for k, v in pairs(Config.Utility.Locations) do
        name = "Drift"..k
        exports["qb-target"]:AddBoxZone(name, vector3(v.x, v.y, v.z), 2, 2, { name = name, heading = 0, debugPoly = false,}, 
        {options = {{event = "m-Drift:Client:Ativar", icon = "fas fa-car", label = "Drift" },
        }, distance = 5.0})
    end
end)

CreateThread( function()
    while true do
        Wait(1)
        playerPed = PlayerPedId()
        if IsPedInAnyVehicle(playerPed) then
            local vehicle = GetVehiclePedIsIn(playerPed, false)
            if (GetPedInVehicleSeat(vehicle, -1) == playerPed) then            
                if GetVehicleHandlingFloat(vehicle, "CHandlingData", "fDriveBiasFront") ~= 1 and IsVehicleOnAllWheels(vehicle) and IsControlJustReleased(0, 21) and IsVehicleClassWhitelisted(GetVehicleClass(vehicle)) then
                    ToggleDrift(vehicle)
                end
                if GetVehicleHandlingFloat(vehicle, "CHandlingData", "fInitialDragCoeff") < 90 then
                    SetVehicleEnginePowerMultiplier(vehicle, 0.0)
                else
                    if GetVehicleHandlingFloat(vehicle, "CHandlingData", "fDriveBiasFront") == 0.0 then SetVehicleEnginePowerMultiplier(vehicle, 190.0) else SetVehicleEnginePowerMultiplier(vehicle, 100.0) end
                end
            end
        end
    end
end)

RegisterNetEvent('m-Drift:Client:Ativar')
AddEventHandler('m-Drift:Client:Ativar', function()
    local playerPed = PlayerPedId()
    if not IsPedSittingInAnyVehicle(playerPed) then return QBCore.Functions.Notify("You must be inside the vehicle.", "error") end
    ToggleDrift()
end)

function ToggleDrift(vehicle)
    local modifier = 1
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    if GetVehicleHandlingFloat(vehicle, "CHandlingData", "fInitialDragCoeff") > 90 then driftMode = true else driftMode = false end
    if driftMode then modifier = -1 end
    for index, value in ipairs(handleMods) do SetVehicleHandlingFloat(vehicle, "CHandlingData", value[1], GetVehicleHandlingFloat(vehicle, "CHandlingData", value[1]) + value[2] * modifier) end
    if driftMode then
        QBCore.Functions.Progressbar("progressBar", "Desactive the drift mode...", 5000, false, true, {disableMovement = true,disableCarMovement = true,disableMouse = false,
        disableCombat = true}, {}, {}, {}, function() end) Wait(5000) QBCore.Functions.Notify("Drifting mode OFF!")
    else
        QBCore.Functions.Progressbar("progressBar", "Activate the drift mode...", 5000, false, true, {disableMovement = true,disableCarMovement = true,disableMouse = false,
        disableCombat = true}, {}, {}, {}, function() end) Wait(5000) QBCore.Functions.Notify("Drifting mode ON!")
    end
end


AddEventHandler('onResourceStop', function(resource) 
    if resource == GetCurrentResourceName() then 
        driftMode = false
    end
end)