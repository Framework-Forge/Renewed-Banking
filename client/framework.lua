FullyLoaded = false
FullyLoaded = pr_lib.framework.IsPlayerLoaded and pr_lib.framework.IsPlayerLoaded() or false

local function initalizeBanking()
    CreatePeds()
    local locales = locale:getAll()
    SendNUIMessage({
        action = 'updateLocale',
        translations = locales,
        currency = Config.currency,
        locale = locale.currentLocale
    })
end

function SendBankingLocale()
    local locales = locale:getAll()
    SendNUIMessage({
        action = 'updateLocale',
        translations = locales,
        currency = Config.currency,
        locale = locale.currentLocale
    })
end
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    Wait(100)
    FullyLoaded = true
    initalizeBanking()
end)

RegisterNetEvent('esx:playerLoaded', function()
    Wait(100)
    FullyLoaded = true
    initalizeBanking()
end)

AddEventHandler('onResourceStart', function(resourceName)
    Wait(100)
    if resourceName ~= GetCurrentResourceName() then return end
    if not FullyLoaded then return end
    initalizeBanking()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    FullyLoaded = false
    DeletePeds()
end)

AddEventHandler('esx:onPlayerLogout', function()
    FullyLoaded = false
    DeletePeds()
end)
