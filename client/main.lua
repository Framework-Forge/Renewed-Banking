local bankPoints = {}
local atmOptions
local atmInteraction
local interactionSettings = pr_lib.cache.get('Renewed-Banking:interaction') or {mode='target', respectWalls=false, revision=-1}

local function clearBankPoint(point)
    if point.interactionId then
        exports.pr_bridge:RemoveInteraction(point.interactionId)
        point.interactionId = nil
    end
    if point.ped then
        pr_lib.target.removeLocalEntity(point.ped, {'renewed_banking_accountmng','renewed_banking_openui'})
    end
end

local function interactionData(options, distance)
    local converted = {}
    for i, option in ipairs(options) do
        option.ignoreLos = not interactionSettings.respectWalls
        option.wallDetection = interactionSettings.respectWalls == true
        converted[i] = {
            label=option.label, name=option.name,
            canInteract=function(entity,coords)
                return not option.canInteract or option.canInteract(entity,#(GetEntityCoords(PlayerPedId())-coords))
            end,
            action=function() TriggerEvent(option.event, {atm=option.atm}) end
        }
    end
    return {
        options=converted, distance=math.max(8,distance), interactDst=distance,
        ignoreLos=not interactionSettings.respectWalls,
        wallDetection=interactionSettings.respectWalls == true
    }
end

local function bindBankPoint(point)
    clearBankPoint(point)
    if not point.ped or not DoesEntityExist(point.ped) then return end
    local data = interactionData(point.targetOptions,4.5)
    if interactionSettings.mode == 'interact' then
        data.entity=point.ped
        data.offset=vector3(0,0,0.8)
        point.interactionId=exports.pr_bridge:AddLocalEntityInteraction(data)
    else
        pr_lib.target.addLocalEntity(point.ped,point.targetOptions)
    end
end

local function bindBankAtms()
    if not atmOptions then return end
    pr_lib.target.removeModel(Config.atms, {'renewed_banking_openui'})
    if atmInteraction then exports.pr_bridge:RemoveInteraction(atmInteraction); atmInteraction=nil end
    local data=interactionData(atmOptions,2.5)
    if interactionSettings.mode == 'interact' then
        data.models=Config.atms
        atmInteraction=exports.pr_bridge:AddModelInteraction(data)
    else
        pr_lib.target.addModel(Config.atms,atmOptions)
    end
end

local function applyInteractionSettings(value)
    if type(value)~='table' then return end
    local revision = tonumber(value.revision)
    if not revision or revision <= (interactionSettings.revision or -1) then return end
    interactionSettings={mode=value.mode == 'interact' and 'interact' or 'target', respectWalls=value.respectWalls == true, revision=revision}
    pr_lib.cache.set('Renewed-Banking:interaction', interactionSettings)
    bindBankAtms()
    for _,point in ipairs(bankPoints) do bindBankPoint(point) end
end

RegisterNetEvent('Renewed-Banking:client:interactionSettings', function(value)
    -- Only the server may publish authoritative settings.
    if source ~= 65535 then return end
    applyInteractionSettings(value)
end)

CreateThread(function()
    for attempt = 1, 3 do
        local ok, snapshot = pcall(pr_lib.callback.await, 'Renewed-Banking:server:getInteractionSettings', false)
        if ok and type(snapshot) == 'table' then
            applyInteractionSettings(snapshot)
            return
        end
        Wait(1000 * attempt)
    end
    print('[Renewed-Banking] Nao foi possivel obter a configuracao de interacao pelo bridge.')
end)

local function doProgressBar(data)
    if type(pr_lib.progressCircle) == "function" and Config.progressbar == "circle" then
        return pr_lib.progressCircle(data)
    elseif type(pr_lib.progressBar) == "function" then
        return pr_lib.progressBar(data)
    elseif type(pr_lib.progressbar) == "table" then
        if Config.progressbar == "circle" and type(pr_lib.progressbar.doProgressCircle) == "function" then
            return pr_lib.progressbar.doProgressCircle(data)
        elseif type(pr_lib.progressbar.progressBar) == "function" then
            return pr_lib.progressbar.progressBar(data)
        elseif type(pr_lib.progressbar.doProgressbar) == "function" then
            return pr_lib.progressbar.doProgressbar(data)
        end
    end
    return true
end
local progressBar = doProgressBar
PlayerPed = pr_lib.cache.ped

pr_lib.onCache('ped', function(newPed)
	PlayerPed = newPed
end)

local function nuiHandler(val)
    isVisible = val
    SetNuiFocus(val, val)
end

local function openBankUI(isAtm)
    SendBankingLocale()
    SendNUIMessage({
        action = 'setLoading',
        status = true,
        theme = Config.theme,
        bankName = Config.bankName,
        bankSubtitle = Config.bankSubtitle,
        appearance = Config.appearance
    })
    nuiHandler(true)
    pr_lib.callback.trigger('renewed-banking:server:initalizeBanking', function(accounts)
        if not accounts then
            nuiHandler(false)
            pr_lib.notify.Notify({title = locale('bank_name'), description = locale('loading_failed'), type = 'error'})
            return
        end
        SetTimeout(1000, function()
            SendNUIMessage({
                action = 'setVisible',
                status = isVisible,
                accounts = accounts,
                loading = false,
                atm = isAtm,
                theme = Config.theme,
                bankName = Config.bankName,
                bankSubtitle = Config.bankSubtitle,
                appearance = Config.appearance
            })
        end)
    end)
end

RegisterNetEvent('Renewed-Banking:client:openBankUI', function(data)
    local txt = data.atm and locale('open_atm') or locale('open_bank')
    TaskStartScenarioInPlace(PlayerPed, 'PROP_HUMAN_ATM', 0, true)
    if progressBar({
        label = txt,
        duration = math.random(3000,5000),
        position = 'bottom',
        useWhileDead = false,
        allowCuffed = false,
        allowFalling = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true,
            mouse = false,
        }
    }) then
        openBankUI(data.atm)
        Wait(500)
        ClearPedTasksImmediately(PlayerPed)
    else
        ClearPedTasksImmediately(PlayerPed)
        pr_lib.notify.Notify({title = locale('bank_name'), description = locale('canceled'), type = 'error'})
    end
end)

RegisterNUICallback('closeInterface', function(_, cb)
    nuiHandler(false)
    cb('ok')
end)

RegisterCommand('closeBankUI', function() nuiHandler(false) end, false)

local bankActions = {'deposit', 'withdraw', 'transfer'}
CreateThread(function ()
    for k=1, #bankActions do
        RegisterNUICallback(bankActions[k], function(data, cb)
            local newTransaction = pr_lib.callback.await('Renewed-Banking:server:'..bankActions[k], 10000, data)
            cb(newTransaction)
        end)
    end
    RegisterNUICallback('getInvoices', function(data, cb)
        cb(pr_lib.callback.await('Renewed-Banking:server:getInvoices', 10000, data and data.accountId) or {})
    end)
    RegisterNUICallback('saveInvoiceSettings', function(data, cb)
        cb(pr_lib.callback.await('Renewed-Banking:server:saveInvoiceSettings', 10000, data) or {success=false})
    end)
    RegisterNUICallback('payInvoice', function(data, cb)
        local ok, result = pcall(function()
            return pr_lib.callback.await('Renewed-Banking:server:payInvoice', 10000, data)
        end)
        if not ok then
            print(('[Renewed-Banking] payInvoice callback failed: %s'):format(tostring(result)))
            result = { success = false, reason = 'server_error' }
        elseif type(result) ~= 'table' then
            result = { success = false, reason = 'no_response' }
        end
        if result.success then
            local accountsOk, updatedAccounts = pcall(function()
                return pr_lib.callback.await('renewed-banking:server:initalizeBanking', 10000)
            end)
            result.accounts = accountsOk and updatedAccounts or {}
        end
        cb(result)
    end)
    local memberCallbacks = {'getAccountMembers', 'addAccountDependent', 'updateAccountDependent', 'removeAccountDependent'}
    for i = 1, #memberCallbacks do
        local callbackName = memberCallbacks[i]
        RegisterNUICallback(callbackName, function(data, cb)
            local payload = callbackName == 'getAccountMembers' and data and data.accountId or data
            cb(pr_lib.callback.await('Renewed-Banking:server:' .. callbackName, 10000, payload)
                or {success=false, reason='no_response'})
        end)
    end
    atmOptions = {{
        name = 'renewed_banking_openui',
        event = 'Renewed-Banking:client:openBankUI',
        icon = 'fas fa-money-check',
        label = locale('view_bank'),
        atm = true,
        canInteract = function(_, distance)
            return distance < 2.5
        end
    }}
    bindBankAtms()
end)

local pedSpawned = false
local blips = {}
function CreatePeds()
    if pedSpawned then return end
    for k = 1, #Config.peds do
        local coords = Config.peds[k].coords
        local pedPoint = pr_lib.points.new({
            coords = coords,
            distance = 300,
            model = joaat(Config.peds[k].model),
            heading = coords.w,
            ped = nil,
            targetOptions = {{
                name = 'renewed_banking_accountmng',
                event = 'Renewed-Banking:client:accountManagmentMenu',
                icon = 'fas fa-money-check',
                label = locale('manage_bank'),
                atm = false,
                canInteract = function(_, distance)
                    return distance < 4.5 and Config.peds[k].createAccounts
                end
            },
            {
                name = 'renewed_banking_openui',
                event = 'Renewed-Banking:client:openBankUI',
                icon = 'fas fa-money-check',
                label = locale('view_bank'),
                atm = false,
                canInteract = function(_, distance)
                    return distance < 4.5
                end
            }}
        })

        bankPoints[#bankPoints+1]=pedPoint

        function pedPoint:onEnter()
            pr_lib.requestModel(self.model, 10000)

            self.ped = CreatePed(0, self.model, self.coords.x, self.coords.y, self.coords.z-1, self.heading, false, false)
            SetEntityHeading(self.ped, self.heading)
            SetModelAsNoLongerNeeded(self.model)

            TaskStartScenarioInPlace(self.ped, 'PROP_HUMAN_STAND_IMPATIENT', 0, true)
            FreezeEntityPosition(self.ped, true)
            SetEntityInvincible(self.ped, true)
            SetBlockingOfNonTemporaryEvents(self.ped, true)
            bindBankPoint(self)
        end

        function pedPoint:onExit()
            clearBankPoint(self)
            if DoesEntityExist(self.ped) then
                DeletePed(self.ped)
            end
            self.ped = nil
        end

        blips[k] = AddBlipForCoord(coords.x, coords.y, coords.z-1)
        SetBlipSprite(blips[k], 108)
        SetBlipDisplay(blips[k], 4)
        SetBlipScale  (blips[k], 0.80)
        SetBlipColour (blips[k], 2)
        SetBlipAsShortRange(blips[k], true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString('Bank')
        EndTextCommandSetBlipName(blips[k])
    end
    pedSpawned = true
end

function DeletePeds()
    if not pedSpawned then return end
    local points = bankPoints
    for i = 1, #points do
        clearBankPoint(points[i])
        if DoesEntityExist(points[i].ped) then
            DeletePed(points[i].ped)
        end
        points[i]:remove()
    end
    for i = 1, #blips do
        RemoveBlip(blips[i])
    end
    bankPoints = {}
    blips = {}
    pedSpawned = false
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    pr_lib.target.removeModel(Config.atms, {'renewed_banking_openui'})
    if atmInteraction then exports.pr_bridge:RemoveInteraction(atmInteraction) end
    DeletePeds()
end)

RegisterNetEvent('Renewed-Banking:client:viewAccountsMenu', function()
    local accounts = pr_lib.callback.await('Renewed-Banking:server:getPlayerAccounts', 10000)
    if accounts then
        TriggerEvent('Renewed-Banking:client:accountsMenu', accounts)
    end
end)
