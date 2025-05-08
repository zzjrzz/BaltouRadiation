local QBCore = exports['qb-core']:GetCoreObject()

QBCore.Functions.CreateCallback('checkAntiRadiationMask', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player then
        local item = Player.Functions.GetItemByName('antiradiationmask')
        if item then
            cb(true)
        else
            cb(false)
        end
    else
        cb(false)
    end
end)
