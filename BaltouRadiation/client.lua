local QBCore = exports['qb-core']:GetCoreObject()

local isInRadiationZone = false
local hasAntiRadiationMask = false
local currentPercentage = 0
local ActiveRadiationZones = {}

-- Local function to check if player has the mask
local function updateMaskStatus()
    QBCore.Functions.TriggerCallback('checkAntiRadiationMask', function(hasMask)
        hasAntiRadiationMask = hasMask
    end)
end

-- Function to add radiation blips
function addRadiationBlips()
    ActiveRadiationZones = {} -- Clear previous

    local availableZones = {}
    for i, zone in pairs(Config.RadiationZones) do
        table.insert(availableZones, zone)
    end

    local minZones = 2 -- Minimum zones active
    local maxZones = 5 -- Maximum zones active
    local numberOfZones = math.random(minZones, math.min(maxZones, #availableZones))

    for i = 1, numberOfZones do
        if #availableZones == 0 then break end

        local randomIndex = math.random(1, #availableZones)
        local selectedZone = availableZones[randomIndex]

        table.insert(ActiveRadiationZones, selectedZone)

        -- Add blip for this zone
        local blip = AddBlipForRadius(selectedZone.position, selectedZone.radius)
        SetBlipColour(blip, 66) -- Yellow
        SetBlipAlpha(blip, 128) -- Semi-transparent

        table.remove(availableZones, randomIndex) -- Prevent duplicates
    end
end

-- Initialize
CreateThread(function()
    addRadiationBlips()
    updateMaskStatus() -- Initial check

    while true do
        local sleep = 5000 -- Default sleep if not near zone

        local playerPed = PlayerPedId()
        local playerPos = GetEntityCoords(playerPed)

        local foundZone = false
        local closestDistance = nil
        local closestZone = nil

        for _, zone in pairs(ActiveRadiationZones) do
            local distance = #(playerPos - zone.position)
            if distance <= zone.radius then
                foundZone = true
                sleep = 1000 -- Check faster when inside a zone
                if not closestDistance or distance < closestDistance then
                    closestDistance = distance
                    closestZone = zone
                end
            end
        end

        if foundZone and closestZone then
            if not hasAntiRadiationMask then
                local percentage = 100 * (1 - (closestDistance / closestZone.radius))
                if math.floor(currentPercentage) ~= math.floor(percentage) then
                    currentPercentage = percentage
                    -- Apply radiation damage and effects
                    ApplyRadiationDamage(playerPed, percentage)
                    ApplyRadiationEffects()
                    SendNUIMessage({
                        type = "updateRadiation",
                        percentage = percentage,
                        showIcon = true
                    })
                end
            else
                if currentPercentage ~= 0 then
                    -- Has mask, remove effects
                    RemoveRadiationEffects()
                    currentPercentage = 0
                    SendNUIMessage({
                        type = "updateRadiation",
                        percentage = 0,
                        showIcon = true
                    })
                end
            end
        else
            if isInRadiationZone then
                -- Left radiation zone
                RemoveRadiationEffects()
                currentPercentage = 0
                SendNUIMessage({
                    type = "updateRadiation",
                    percentage = 0,
                    showIcon = false
                })
            end
        end

        isInRadiationZone = foundZone
        Wait(sleep)
    end
end)

-- Listen for inventory changes to update mask status
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    updateMaskStatus()
end)

RegisterNetEvent('QBCore:Client:OnInventoryUpdate', function()
    updateMaskStatus()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    hasAntiRadiationMask = false
end)

-- Radiation Damage Application
function ApplyRadiationDamage(playerPed, percentage)
    local health = GetEntityHealth(playerPed)
    local damage = math.floor(1 + (9 * (percentage / 100)))
    if health > 0 then
        SetEntityHealth(playerPed, math.max(0, health - damage))
    end
end

-- Radiation Effects
function ApplyRadiationEffects()
    if not AnimpostfxIsRunning("DrugsMichaelAliensFightIn") then
        StartScreenEffect("DrugsMichaelAliensFightIn", 0, true)
    end
    SendNUIMessage({
        type = "playSound",
        sound = "radiation_sound"
    })
end

function RemoveRadiationEffects()
    if AnimpostfxIsRunning("DrugsMichaelAliensFightIn") then
        StopScreenEffect("DrugsMichaelAliensFightIn")
    end
    SendNUIMessage({
        type = "stopSound",
        sound = "radiation_sound"
    })
end
