local FrameworkResource = pr_lib.framework.GetResourceName()
local Jobs, Gangs = {}, {}
local deadPlayers = {}

local function refreshGroups()
    Jobs = pr_lib.framework.GetFrameworkJobs and pr_lib.framework.GetFrameworkJobs() or {}
    Gangs = pr_lib.framework.GetFrameworkGangs and pr_lib.framework.GetFrameworkGangs() or {}
end

local function isQbLike()
    return FrameworkResource == 'qb-core' or FrameworkResource == 'qbx_core' or FrameworkResource == 'qbx-core'
end

local function gradeLevel(grade)
    if type(grade) == 'table' then
        return tonumber(grade.level or grade.grade or grade.value) or 0
    end

    return tonumber(grade) or 0
end

local function playerSource(Player)
    if type(Player) == 'number' then return Player end
    if type(Player) ~= 'table' then return nil end

    if pr_lib.framework.getPlayerSourceFromPlayer then
        local ok, source = pcall(pr_lib.framework.getPlayerSourceFromPlayer, Player)
        if ok and tonumber(source) then return tonumber(source) end
    end

    return tonumber(Player.source or Player.PlayerData and Player.PlayerData.source)
end

local function playerData(Player)
    if type(Player) == 'table' and Player.PlayerData then return Player.PlayerData end

    local source = playerSource(Player)
    if source and pr_lib.framework.GetPlayerData then
        return pr_lib.framework.GetPlayerData(source)
    end
end

local function normalizeMoneyAccount(account)
    if account == 'money' then return 'cash' end
    return account or 'cash'
end

local function groupGradeData(groups, groupName, grade)
    if type(groups) ~= 'table' then return nil end

    local isJobsTable = groups == Jobs
    local group = groups[groupName]
    if not group then
        refreshGroups()
        group = (isJobsTable and Jobs or Gangs)[groupName]
    end

    local grades = type(group) == 'table' and group.grades or nil
    if type(grades) ~= 'table' then return nil end

    local gradeString = tostring(grade or 0)
    local gradeNumber = tonumber(gradeString) or 0
    return grades[gradeString] or grades[gradeNumber]
end

local function isBankAuth(gradeData)
    if type(gradeData) ~= 'table' then return false end
    return gradeData.bankAuth == true or gradeData.isboss == true or gradeData.name == 'boss'
end

local function registerCompatExport(resource, name, cb)
    AddEventHandler(('__cfx_export_%s_%s'):format(resource, name), function(setCB)
        setCB(cb)
    end)
end

CreateThread(function()
    if not FrameworkResource then
        print('^6[^3Renewed-Banking^6]^0 Unsupported framework detected by pr_bridge.')
        StopResource(GetCurrentResourceName())
        return
    end

    refreshGroups()

    registerCompatExport('qb-management', 'GetAccount', GetAccountMoney)
    registerCompatExport('qb-management', 'GetGangAccount', GetAccountMoney)
    registerCompatExport('qb-management', 'AddMoney', AddAccountMoney)
    registerCompatExport('qb-management', 'AddGangMoney', AddAccountMoney)
    registerCompatExport('qb-management', 'RemoveMoney', RemoveAccountMoney)
    registerCompatExport('qb-management', 'RemoveGangMoney', RemoveAccountMoney)

    registerCompatExport('esx_society', 'GetSociety', GetAccountMoney)
    RegisterServerEvent('esx_society:getSociety', GetAccountMoney)
    RegisterServerEvent('esx_society:depositMoney', AddAccountMoney)
    RegisterServerEvent('esx_society:withdrawMoney', RemoveAccountMoney)
end)

function GetSocietyLabel(society)
    if (not Jobs[society] and not Gangs[society]) then refreshGroups() end

    return Jobs[society] and Jobs[society].label
        or Gangs[society] and Gangs[society].label
        or society
end

function GetPlayerObject(source)
    return pr_lib.framework.GetPlayer(tonumber(source))
end

function GetPlayerObjectFromID(identifier, includeOffline)
    if type(identifier) ~= 'string' then return nil end
    if isQbLike() then identifier = identifier:upper() end
    local Player = pr_lib.framework.GetPlayerFromIdentifier(identifier)
    if not Player and includeOffline and pr_lib.framework.GetOfflinePlayer then
        Player = pr_lib.framework.GetOfflinePlayer(identifier)
    end
    return Player
end

function GetCharacterName(Player)
    local source = playerSource(Player)
    if source and pr_lib.framework.GetPlayerName then
        local name = pr_lib.framework.GetPlayerName(source)
        if type(name) == 'table' then return name.fullName or ((name.firstName or '') .. ' ' .. (name.lastName or '')) end
        if type(name) == 'string' and name ~= '' then return name end
    end

    local data = playerData(Player) or {}
    local charinfo = data.charinfo or data.character or {}
    local firstName = charinfo.firstname or charinfo.firstName or data.firstName or ''
    local lastName = charinfo.lastname or charinfo.lastName or data.lastName or ''
    local fullName = (firstName .. ' ' .. lastName):match('^%s*(.-)%s*$')

    return fullName ~= '' and fullName or data.name or Player and Player.name or 'Unknown'
end

function GetIdentifier(Player)
    local source = playerSource(Player)
    if source and pr_lib.framework.GetIdentifier then
        local identifier = pr_lib.framework.GetIdentifier(source)
        if identifier then return identifier end
    end

    local data = playerData(Player) or {}
    return data.citizenid or data.identifier or data.charId or Player and Player.identifier
end

function GetFunds(Player)
    local source = playerSource(Player)
    local identifier = Player and GetIdentifier(Player)
    if source or identifier then
        return {
            cash = tonumber(pr_lib.framework.GetPlayerAccountBalance(source or identifier, 'cash')) or 0,
            bank = tonumber(pr_lib.framework.GetPlayerAccountBalance(source or identifier, 'bank')) or 0,
        }
    end

    local data = playerData(Player) or {}
    local money = data.money or {}
    return {
        cash = tonumber(money.cash or money.money) or 0,
        bank = tonumber(money.bank) or 0,
    }
end

local function formatBankAmount(amount)
    local formatted = ('%.2f'):format(math.abs(tonumber(amount) or 0))
    local integer, decimal = formatted:match('^(%d+)%.(%d+)$')

    integer = integer:reverse():gsub('(%d%d%d)', '%1,'):reverse():gsub('^,', '')
    return ('%s %s.%s'):format(Config.currency or 'USD', integer, decimal)
end

local function sendBankMessage(Player, transactionType, amount, comment)
    local settings = Config.bankNotifications
    if type(settings) ~= 'table' or settings.enabled ~= true then return end
    if GetResourceState('npwd') ~= 'started' then return end

    local data = playerData(Player) or {}
    local charinfo = data.charinfo or data.character or {}
    local targetNumber = charinfo.phone or charinfo.phoneNumber or data.phone_number or data.phoneNumber
    if targetNumber == nil or tostring(targetNumber) == '' then return end

    local action = locale(transactionType == 'credit' and 'transaction_credit' or 'transaction_debit')
    local message = locale('bank_message_transaction', action, formatBankAmount(amount))

    if settings.includeBalance == true then
        local subject = playerSource(Player) or GetIdentifier(Player)
        local balance = subject and pr_lib.framework.GetPlayerAccountBalance(subject, 'bank')
        if tonumber(balance) then
            message = locale('bank_message_balance', message, formatBankAmount(balance))
        end
    end

    if settings.includeReason == true and type(comment) == 'string' then
        local reason = comment:match('^%s*(.-)%s*$')
        if reason ~= '' then
            message = locale('bank_message_reason', message, reason:sub(1, 160))
        end
    end

    CreateThread(function()
        local ok, err = pcall(function()
            exports.npwd:emitMessage({
                senderNumber = tostring(settings.senderNumber or '0800000000'),
                targetNumber = tostring(targetNumber),
                message = message,
            })
        end)

        if not ok then
            print(('[Renewed-Banking] Falha ao enviar mensagem bancaria para %s: %s')
                :format(tostring(targetNumber), tostring(err)))
        end
    end)
end

function AddMoney(Player, Amount, Type, comment)
    local source = playerSource(Player)
    local identifier = Player and GetIdentifier(Player)
    Amount = tonumber(Amount) or 0
    if (not source and not identifier) or Amount <= 0 then return false end

    local account = normalizeMoneyAccount(Type)
    local result = pr_lib.framework.AddPlayerAccountBalance(source or identifier, account, Amount, comment or 'Renewed-Banking')
    if result == false then return false end

    if account == 'bank' then sendBankMessage(Player, 'credit', Amount, comment) end
    return true
end

function RemoveMoney(Player, Amount, Type, comment)
    local source = playerSource(Player)
    local identifier = Player and GetIdentifier(Player)
    Amount = tonumber(Amount) or 0
    if (not source and not identifier) or Amount <= 0 then return false end

    local account = normalizeMoneyAccount(Type)
    local subject = source or identifier
    local currentAmount = tonumber(pr_lib.framework.GetPlayerAccountBalance(subject, account)) or 0
    if currentAmount < Amount then return false end

    local result = pr_lib.framework.RemovePlayerAccountBalance(subject, account, Amount, comment or 'Renewed-Banking')
    if result == false then return false end

    if account == 'bank' then sendBankMessage(Player, 'debit', Amount, comment) end
    return true
end

function GetJobs(Player)
    local data = playerData(Player) or {}

    if Config.renewedMultiJob and type(data.jobs) == 'table' then
        local jobs = {}

        for name, grade in pairs(data.jobs) do
            jobs[#jobs + 1] = {
                name = name,
                grade = tostring(gradeLevel(grade)),
            }
        end

        if #jobs > 0 then return jobs end
    end

    local source = playerSource(Player)
    local job = source and pr_lib.framework.GetPlayerJob(source) or data.job
    if type(job) ~= 'table' then return { name = 'unemployed', grade = '0' } end

    return {
        name = job.name or 'unemployed',
        grade = tostring(gradeLevel(job.grade)),
    }
end

function GetGang(Player)
    local data = playerData(Player) or {}
    local gang = data.gang

    if type(gang) == 'table' then return gang.name end
    if type(gang) == 'string' then return gang end

    return false
end

function IsJobAuth(job, grade)
    return isBankAuth(groupGradeData(Jobs, job, grade))
end

function IsGangAuth(Player, gang)
    local data = playerData(Player) or {}
    local grade = type(data.gang) == 'table' and gradeLevel(data.gang.grade) or 0
    return isBankAuth(groupGradeData(Gangs, gang, grade))
end

function Notify(src, settings)
    return pr_lib.notify.Notify(src, settings, settings and settings.type, settings and settings.duration)
end

function IsDead(Player)
    local source = playerSource(Player)
    if source then
        local metadataDead = pr_lib.framework.GetPlayerMetadata and pr_lib.framework.GetPlayerMetadata(source, 'isdead')
        if metadataDead ~= nil then return metadataDead == true end
    end

    local data = playerData(Player) or {}
    return data.metadata and data.metadata.isdead == true or deadPlayers[source] == true
end

function GetFrameworkGroups()
    refreshGroups()
    return Jobs, Gangs
end

local function updatePlayerAccountFromSource(src)
    local Player = GetPlayerObject(src)
    local cid = Player and GetIdentifier(Player)
    if cid and UpdatePlayerAccount then UpdatePlayerAccount(cid) end
end

AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
    local cid = Player and GetIdentifier(Player)
    if cid and UpdatePlayerAccount then UpdatePlayerAccount(cid) end
end)

RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    updatePlayerAccountFromSource(source)
end)

RegisterNetEvent('esx:onPlayerDeath', function()
    deadPlayers[source] = true
end)

RegisterNetEvent('esx:onPlayerSpawn', function()
    if deadPlayers[source] then deadPlayers[source] = nil end
    updatePlayerAccountFromSource(source)
end)

AddEventHandler('esx:playerDropped', function(playerId)
    deadPlayers[playerId] = nil
end)

AddEventHandler('qbx_core:server:onJobUpdate', function(jobName, job)
    Jobs[jobName] = job
end)

AddEventHandler('qbx_core:server:onGangUpdate', function(gangName, gang)
    Gangs[gangName] = gang
end)

AddEventHandler('onResourceStart', function(resourceName)
    Wait(500)
    if resourceName ~= GetCurrentResourceName() then return end

    refreshGroups()
    for _, source in ipairs(GetPlayers()) do
        updatePlayerAccountFromSource(tonumber(source))
    end
end)
