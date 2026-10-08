local cachedAccounts = {}
local cachedPlayers = {}
-- Server-only collections: never replicate balances or account permissions.
pr_lib.cache.set('Renewed-Banking:accounts', cachedAccounts)
pr_lib.cache.set('Renewed-Banking:players', cachedPlayers)

CreateThread(function()
    Wait(500)
    if not LoadResourceFile("Renewed-Banking", 'web/public/build/bundle.js') or GetCurrentResourceName() ~= "Renewed-Banking" then
        error(locale("ui_not_built"))
        return StopResource("Renewed-Banking")
    end
    local accounts = pr_lib.database.query('SELECT * FROM bank_accounts_new', {})
    if accounts then
        for _,v in pairs (accounts) do
            local job = v.id
            v.auth = json.decode(v.auth)
            cachedAccounts[job] = { --  cachedAccounts[#cachedAccounts+1]
                id = job,
                type = locale("org"),
                name = GetSocietyLabel(job),
                frozen = v.isFrozen == 1,
                amount = v.amount,
                transactions = json.decode(v.transactions),
                auth = {},
                creator = v.creator
            }
            if #v.auth >= 1 then
                for k=1, #v.auth do
                    cachedAccounts[job].auth[v.auth[k]] = true
                end
            end
        end
    end
    local jobs, gangs = GetFrameworkGroups()
    local query = {}
    local function addCachedAccount(group)
        cachedAccounts[group] = {
            id = group,
            type = locale('org'),
            name = GetSocietyLabel(group),
            frozen = 0,
            amount = 0,
            transactions = {},
            auth = {},
            creator = nil
        }
        query[#query + 1] = {"INSERT INTO bank_accounts_new (id, amount, transactions, auth, isFrozen, creator) VALUES (?, ?, ?, ?, ?, NULL) ",
        { group, cachedAccounts[group].amount, json.encode(cachedAccounts[group].transactions), json.encode({}), cachedAccounts[group].frozen }}
    end
    for job in pairs(jobs) do
        if not cachedAccounts[job] then
            addCachedAccount(job)
        end
    end
    for gang in pairs(gangs) do
        if not cachedAccounts[gang] then
            addCachedAccount(gang)
        end
    end
    if #query >= 1 then
        pr_lib.database.transaction(query)
    end
end)

function UpdatePlayerAccount(cid)
    local p = promise.new()
    pr_lib.database.query('SELECT * FROM player_transactions WHERE id = ?', {cid}, function(account)
        local query = '%' .. cid .. '%'
        pr_lib.database.query("SELECT * FROM bank_accounts_new WHERE auth LIKE ? ", {query}, function(shared)
            cachedPlayers[cid] = {
                isFrozen = 0,
                transactions = #account > 0 and json.decode(account[1].transactions) or {},
                accounts = {}
            }

            if #shared >= 1 then
                for k=1, #shared do
                    cachedPlayers[cid].accounts[#cachedPlayers[cid].accounts+1] = shared[k].id
                end
            end
            p:resolve(true)
        end)
    end)
	return Citizen.Await(p)
end

local fullAccess = { withdraw = true, transfer = true, payInvoices = true }

local function copyAccess(access)
    return {
        withdraw = access and access.withdraw == true or false,
        transfer = access and access.transfer == true or false,
        payInvoices = access and access.payInvoices == true or false,
    }
end

local function groupAccountAccess(Player, accountId)
    local jobs = GetJobs(Player)
    if #jobs > 0 then
        for i = 1, #jobs do
            if jobs[i].name == accountId and IsJobAuth(accountId, jobs[i].grade) then return true end
        end
    elseif jobs.name == accountId and IsJobAuth(accountId, jobs.grade) then
        return true
    end
    local gang = GetGang(Player)
    return gang == accountId and IsGangAuth(Player, gang) == true
end

local function getAccountAccess(source, accountId)
    local Player = GetPlayerObject(source)
    if not Player or type(accountId) ~= 'string' then return nil end
    local cid = GetIdentifier(Player)
    if accountId == cid then return copyAccess(fullAccess), true end

    local account = cachedAccounts[accountId]
    if account and (account.creator == cid or groupAccountAccess(Player, accountId)) then
        return copyAccess(fullAccess), account.creator == cid
    end

    local membership = type(RenewedBankingGetMembership) == 'function'
        and RenewedBankingGetMembership(accountId, cid) or nil
    if membership then return copyAccess(membership), false end
    if account and account.auth[cid] then return copyAccess(fullAccess), false end
    return nil
end

function RenewedBankingIsAccountOwner(source, accountId)
    local Player = GetPlayerObject(source)
    if not Player then return false end
    local cid = GetIdentifier(Player)
    return accountId == cid or cachedAccounts[accountId] and cachedAccounts[accountId].creator == cid or false
end

function RenewedBankingCanAccountAction(source, accountId, action)
    local access = getAccountAccess(source, accountId)
    return access ~= nil and (action == 'deposit' or access[action] == true)
end

local function ensurePlayerCache(cid)
    if not cachedPlayers[cid] then UpdatePlayerAccount(cid) end
    return cachedPlayers[cid]
end

local function personalAccountData(accountId, access, owner)
    local accountPlayer = GetPlayerObjectFromID(accountId, true)
    if not accountPlayer then return nil end
    local cache = ensurePlayerCache(accountId)
    local funds = GetFunds(accountPlayer)
    return {
        id = accountId,
        type = locale('personal'),
        name = GetCharacterName(accountPlayer),
        frozen = cache.isFrozen == 1,
        amount = funds.bank,
        cash = funds.cash,
        transactions = cache.transactions,
        access = copyAccess(access),
        owner = owner == true,
    }
end

local function sharedAccountData(account, access, owner)
    return {
        id = account.id, type = account.type, name = account.name, frozen = account.frozen,
        amount = account.amount, transactions = account.transactions, creator = account.creator,
        access = copyAccess(access), owner = owner == true,
    }
end

local function getBankData(source)
    local Player = GetPlayerObject(source)
    if not Player then return {} end
    local bankData, included = {}, {}
    local cid = GetIdentifier(Player)
    ensurePlayerCache(cid)
    bankData[#bankData + 1] = personalAccountData(cid, fullAccess, true)
    included[cid] = true

    local function includeShared(accountId)
        if included[accountId] or not cachedAccounts[accountId] then return end
        local access, owner = getAccountAccess(source, accountId)
        if not access then return end
        bankData[#bankData + 1] = sharedAccountData(cachedAccounts[accountId], access, owner)
        included[accountId] = true
    end

    local jobs = GetJobs(Player)
    if #jobs > 0 then
        for i = 1, #jobs do includeShared(jobs[i].name) end
    elseif jobs.name then
        includeShared(jobs.name)
    end
    local gang = GetGang(Player)
    if gang and gang ~= 'none' then includeShared(gang) end
    for i = 1, #cachedPlayers[cid].accounts do includeShared(cachedPlayers[cid].accounts[i]) end

    local delegated = type(RenewedBankingGetDelegatedAccounts) == 'function'
        and RenewedBankingGetDelegatedAccounts(cid) or {}
    for i = 1, #delegated do
        local accountId = delegated[i].account_id
        if not included[accountId] then
            local access = getAccountAccess(source, accountId)
            if cachedAccounts[accountId] then
                bankData[#bankData + 1] = sharedAccountData(cachedAccounts[accountId], access, false)
            else
                local personal = personalAccountData(accountId, access, false)
                if personal then bankData[#bankData + 1] = personal end
            end
            included[accountId] = true
        end
    end
    return bankData
end

pr_lib.callback.register('renewed-banking:server:initalizeBanking', function(source)
    local bankData = getBankData(source)
    return bankData
end)

-- Events
local function genTransactionID()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

local function sanitizeMessage(message)
    if type(message) ~= "string" then
        message = tostring(message)
    end
    message = message:gsub("'", "''"):gsub("\\", "\\\\")
    return message
end

local Type = type
local function handleTransaction(account, title, amount, message, issuer, receiver, transType, transID)
    if not account or Type(account) ~= 'string' then return print(locale("err_trans_account", account)) end
    if not title or Type(title) ~= 'string' then return print(locale("err_trans_title", title)) end
    if not amount or Type(amount) ~= 'number' then return print(locale("err_trans_amount", amount)) end
    if not message or Type(message) ~= 'string' then return print(locale("err_trans_message", message)) end
    if not issuer or Type(issuer) ~= 'string' then return print(locale("err_trans_issuer", issuer)) end
    if not receiver or Type(receiver) ~= 'string' then return print(locale("err_trans_receiver", receiver)) end
    if not transType or Type(transType) ~= 'string' then return print(locale("err_trans_type", transType)) end
    if transID and Type(transID) ~= 'string' then return print(locale("err_trans_transID", transID)) end

    local transaction = {
        trans_id = transID or genTransactionID(),
        title = title,
        amount = amount,
        trans_type = transType,
        receiver = receiver,
        message = sanitizeMessage(message),
        issuer = issuer,
        time = os.time()
    }
    if cachedAccounts[account] then
        table.insert(cachedAccounts[account].transactions, 1, transaction)
        local transactions = json.encode(cachedAccounts[account].transactions)
        pr_lib.database.execute("INSERT INTO bank_accounts_new (id, transactions) VALUES (?, ?) ON DUPLICATE KEY UPDATE transactions = ?",{
            account, transactions, transactions
        })
    elseif cachedPlayers[account] then
        table.insert(cachedPlayers[account].transactions, 1, transaction)
        local transactions = json.encode(cachedPlayers[account].transactions)
        pr_lib.database.execute("INSERT INTO player_transactions (id, transactions) VALUES (?, ?) ON DUPLICATE KEY UPDATE transactions = ?", {
            account, transactions, transactions
        })
    else
        print(locale("invalid_account", account))
    end
    return transaction
end

-- Server files in the same resource do not share local variables.
RenewedBankingHandleTransaction = handleTransaction
exports("handleTransaction", handleTransaction)

function GetAccountMoney(account)
    if not cachedAccounts[account] then
        locale("invalid_account", account)
        return false
    end
    return cachedAccounts[account].amount
end
exports('getAccountMoney', GetAccountMoney)

local function updateBalance(account)
    pr_lib.database.update("UPDATE bank_accounts_new SET amount = ? WHERE id = ?",{ cachedAccounts[account].amount, account })
end

function AddAccountMoney(account, amount)
    if not cachedAccounts[account] then
        locale("invalid_account", account)
        return false
    end
    cachedAccounts[account].amount = cachedAccounts[account].amount + amount
    updateBalance(account)
    return true
end
exports('addAccountMoney', AddAccountMoney)

local function getPlayerData(source, id)
    local Player = source and GetPlayerObject(source)
    if not Player then Player = GetPlayerObjectFromID(id) end
    if not Player then
        local msg = locale('invalid_account', id)
        print(locale("invalid_account", id))
        if source then
            Notify(source, {title = locale("bank_name"), description = msg, type = "error"})
        end
    end
    return Player
end

local function accountPlayer(accountId)
    return GetPlayerObjectFromID(accountId, true)
end

local function accountName(accountId)
    if cachedAccounts[accountId] then return cachedAccounts[accountId].name end
    local Player = accountPlayer(accountId)
    return Player and GetCharacterName(Player) or accountId
end

local function creditAccount(accountId, amount, comment)
    if cachedAccounts[accountId] then return AddAccountMoney(accountId, amount) end
    local Player = accountPlayer(accountId)
    if not Player then return false end
    ensurePlayerCache(accountId)
    return AddMoney(Player, amount, 'bank', comment)
end

local function debitAccount(accountId, amount, comment)
    if cachedAccounts[accountId] then return RemoveAccountMoney(accountId, amount) end
    local Player = accountPlayer(accountId)
    if not Player then return false end
    ensurePlayerCache(accountId)
    return RemoveMoney(Player, amount, 'bank', comment)
end

RenewedBankingCreditAccount = creditAccount
RenewedBankingDebitAccount = debitAccount

local function denyAction(source)
    Notify(source, { title = locale('bank_name'), description = locale('operation_failed'), type = 'error' })
    return false
end

pr_lib.callback.register('Renewed-Banking:server:deposit', function(source, data)
    data = type(data) == 'table' and data or {}
    local Player, amount = GetPlayerObject(source), tonumber(data.amount)
    if not Player or not amount or amount < 1 then
        Notify(source, {title = locale('bank_name'), description = locale('invalid_amount', locale('deposit_but')), type = 'error'})
        return false
    end
    if not RenewedBankingCanAccountAction(source, data.fromAccount, 'deposit') then return denyAction(source) end
    local name = GetCharacterName(Player)
    data.comment = data.comment and data.comment ~= '' and sanitizeMessage(data.comment)
        or locale('comp_transaction', name, 'deposited', amount)
    if not RemoveMoney(Player, amount, 'cash', data.comment) then
        Notify(source, {title = locale('bank_name'), description = locale('not_enough_money'), type = 'error'})
        return false
    end
    if not creditAccount(data.fromAccount, amount, data.comment) then
        AddMoney(Player, amount, 'cash', 'Estorno: ' .. data.comment)
        return denyAction(source)
    end
    handleTransaction(data.fromAccount, locale('personal_acc') .. data.fromAccount, amount,
        data.comment, name, accountName(data.fromAccount), 'deposit')
    return getBankData(source)
end)

function RemoveAccountMoney(account, amount)
    if not cachedAccounts[account] then
        print(locale("invalid_account", account))
        return false
    end
    if cachedAccounts[account].amount < amount then
        print(locale("broke_account", account, amount))
        return false
    end

    cachedAccounts[account].amount = cachedAccounts[account].amount - amount
    updateBalance(account)
    return true
end
exports('removeAccountMoney', RemoveAccountMoney)

pr_lib.callback.register('Renewed-Banking:server:withdraw', function(source, data)
    data = type(data) == 'table' and data or {}
    local Player, amount = GetPlayerObject(source), tonumber(data.amount)
    if not Player or not amount or amount < 1 then
        Notify(source, {title = locale('bank_name'), description = locale('invalid_amount', locale('withdraw_but')), type = 'error'})
        return false
    end
    if not RenewedBankingCanAccountAction(source, data.fromAccount, 'withdraw') then return denyAction(source) end
    local name = GetCharacterName(Player)
    data.comment = data.comment and data.comment ~= '' and sanitizeMessage(data.comment)
        or locale('comp_transaction', name, 'withdrawed', amount)
    if not debitAccount(data.fromAccount, amount, data.comment) then
        Notify(source, {title = locale('bank_name'), description = locale('not_enough_money'), type = 'error'})
        return false
    end
    if not AddMoney(Player, amount, 'cash', data.comment) then
        creditAccount(data.fromAccount, amount, 'Estorno: ' .. data.comment)
        return denyAction(source)
    end
    handleTransaction(data.fromAccount, locale('personal_acc') .. data.fromAccount, amount,
        data.comment, accountName(data.fromAccount), name, 'withdraw')
    return getBankData(source)
end)

pr_lib.callback.register('Renewed-Banking:server:transfer', function(source, data)
    data = type(data) == 'table' and data or {}
    local Player, amount = GetPlayerObject(source), tonumber(data.amount)
    if not Player or not amount or amount < 1 or type(data.stateid) ~= 'string' or data.stateid == '' then
        Notify(source, {title = locale('bank_name'), description = locale('invalid_amount', locale('transfer_but')), type = 'error'})
        return false
    end
    if data.fromAccount == data.stateid then return denyAction(source) end
    if not RenewedBankingCanAccountAction(source, data.fromAccount, 'transfer') then return denyAction(source) end
    local name = GetCharacterName(Player)
    data.comment = data.comment and data.comment ~= '' and sanitizeMessage(data.comment)
        or locale('comp_transaction', name, 'transfered', amount)
    if not cachedAccounts[data.stateid] and not accountPlayer(data.stateid) then
        Notify(source, {title = locale('bank_name'), description = locale('fail_transfer'), type = 'error'})
        return false
    end
    if not debitAccount(data.fromAccount, amount, data.comment) then
        Notify(source, {title = locale('bank_name'), description = locale('not_enough_money'), type = 'error'})
        return false
    end
    if not creditAccount(data.stateid, amount, data.comment) then
        creditAccount(data.fromAccount, amount, 'Estorno: ' .. data.comment)
        return denyAction(source)
    end
    local fromName, toName = accountName(data.fromAccount), accountName(data.stateid)
    local title = ('%s / %s'):format(fromName, data.fromAccount)
    local transaction = handleTransaction(data.fromAccount, title, amount, data.comment, fromName, toName, 'withdraw')
    if transaction then
        handleTransaction(data.stateid, title, amount, data.comment, fromName, toName, 'deposit', transaction.trans_id)
    end
    return getBankData(source)
end)

pr_lib.callback.register('Renewed-Banking:server:createNewAccount', function(source, accountid)
    local Player = GetPlayerObject(source)
    if cachedAccounts[accountid] then
        Notify(source, {title = locale("bank_name"), description = locale("account_taken"), type = "error"})
        return false
    end

    local cid = GetIdentifier(Player)
    cachedAccounts[accountid] = {
        id = accountid,
        type = locale("org"),
        name = accountid,
        frozen = 0,
        amount = 0,
        transactions = {},
        auth = { [cid] = true },
        creator = cid

    }
    cachedPlayers[cid].accounts[#cachedPlayers[cid].accounts+1] = accountid
    pr_lib.database.insert("INSERT INTO bank_accounts_new (id, amount, transactions, auth, isFrozen, creator) VALUES (?, ?, ?, ?, ?, ?) ",{
        accountid, cachedAccounts[accountid].amount, json.encode(cachedAccounts[accountid].transactions), json.encode({cid}), cachedAccounts[accountid].frozen, cid
    })
    return true
end)

pr_lib.callback.register("Renewed-Banking:server:getPlayerAccounts", function(source)
    local Player = GetPlayerObject(source)
    local cid = GetIdentifier(Player)
    local accounts = cachedPlayers[cid].accounts
    local data = {}
    if #accounts >= 1 then
        for k=1, #accounts do
            if cachedAccounts[accounts[k]].creator == cid then
                data[#data+1] = accounts[k]
            end
        end
    end
    return data
end)

pr_lib.callback.register("Renewed-Banking:server:viewMemberManagement", function(source, data)
    local Player = GetPlayerObject(source)

    local account = data.account
    local retData = {
        account = account,
        members = {}
    }
    local cid = GetIdentifier(Player)

    for k,_ in pairs(cachedAccounts[account].auth) do
        local Player2 = getPlayerData(source, k)
        if cid ~= GetIdentifier(Player2) then
            retData.members[k] = GetCharacterName(Player2)
        end
    end

    return retData
end)

pr_lib.callback.register('Renewed-Banking:server:addAccountMember', function(source, account, member)
    local Player = GetPlayerObject(source)

    if GetIdentifier(Player) ~= cachedAccounts[account].creator then print(locale("illegal_action", GetPlayerName(source))) return false end
    local Player2 = getPlayerData(source, member)
    if not Player2 then return false end

    local targetCID = GetIdentifier(Player2)
    if cachedPlayers[targetCID] then
        cachedPlayers[targetCID].accounts[#cachedPlayers[targetCID].accounts+1] = account
    end

    local auth = {}
    for k in pairs(cachedAccounts[account].auth) do auth[#auth+1] = k end
    auth[#auth+1] = targetCID
    cachedAccounts[account].auth[targetCID] = true
    pr_lib.database.update('UPDATE bank_accounts_new SET auth = ? WHERE id = ?',{json.encode(auth), account})
    return true
end)

pr_lib.callback.register('Renewed-Banking:server:removeAccountMember', function(source, data)
    local Player = GetPlayerObject(source)
    if GetIdentifier(Player) ~= cachedAccounts[data.account].creator then print(locale("illegal_action", GetPlayerName(source))) return false end
    local Player2 = getPlayerData(source, data.cid)
    if not Player2 then return false end

    local targetCID = GetIdentifier(Player2)
    local tmp = {}
    for k in pairs(cachedAccounts[data.account].auth) do
        if targetCID ~= k then
            tmp[#tmp+1] = k
        end
    end

    if cachedPlayers[targetCID] then
        local newAccount = {}
        if #cachedPlayers[targetCID].accounts >= 1 then
            for k=1, #cachedPlayers[targetCID].accounts do
                if cachedPlayers[targetCID].accounts[k] ~= data.account then
                    newAccount[#newAccount+1] = cachedPlayers[targetCID].accounts[k]
                end
            end
        end
        cachedPlayers[targetCID].accounts = newAccount
    end
    cachedAccounts[data.account].auth[targetCID] = nil
    pr_lib.database.update('UPDATE bank_accounts_new SET auth = ? WHERE id = ?',{json.encode(tmp), data.account})
    return true
end)

pr_lib.callback.register('Renewed-Banking:server:deleteAccount', function(source, data)
    local account = data.account
    local Player = GetPlayerObject(source)
    local cid = GetIdentifier(Player)

    if not cachedAccounts[account] or cachedAccounts[account].creator ~= cid then
        return denyAction(source)
    end

    cachedAccounts[account] = nil

    for k=1, #cachedPlayers[cid].accounts do
        if cachedPlayers[cid].accounts[k] == account then
            cachedPlayers[cid].accounts[k] = nil
        end
    end

    pr_lib.database.update("DELETE FROM `bank_accounts_new` WHERE id=:id", { id = account })
    pr_lib.database.update('DELETE FROM renewed_account_members WHERE account_id = ?', { account })
    return true
end)

local find = string.find
local sub = string.sub
local function split(str, delimiter)
    local result = {}
    local from = 1
    local delim_from, delim_to = find(str, delimiter, from)
    while delim_from do
        result[#result + 1] = sub(str, from, delim_from - 1)
        from = delim_to + 1
        delim_from, delim_to = find(str, delimiter, from)
    end
    result[#result + 1] = sub(str, from)
    return result
end


local function updateAccountName(account, newName, src)
    if not account or not newName then return false end
    if not cachedAccounts[account] then
        local getTranslation = locale("invalid_account", account)
        print(getTranslation)
        if src then Notify(src, {title = locale("bank_name"), description = split(getTranslation, '0')[2], type = "error"}) end
        return false
    end
    if cachedAccounts[newName] then
        local getTranslation = locale("existing_account", account)
        print(getTranslation)
        if src then Notify(src, {title = locale("bank_name"), description = split(getTranslation, '0')[2], type = "error"}) end
        return false
    end
    if src then
        local Player = GetPlayerObject(src)
        if GetIdentifier(Player) ~= cachedAccounts[account].creator then
            local getTranslation = locale("illegal_action", GetPlayerName(src))
            print(getTranslation)
            Notify(src, {title = locale("bank_name"), description = split(getTranslation, '0')[2], type = "error"})
            return false
        end
    end

    cachedAccounts[newName] = json.decode(json.encode(cachedAccounts[account]))
    cachedAccounts[newName].id = newName
    cachedAccounts[newName].name = newName
    cachedAccounts[account] = nil
    for _, id in ipairs(GetPlayers()) do
        local Player2 = GetPlayerObject(id)
        if not Player2 then goto Skip end
        local cid = GetIdentifier(Player2)
        if #cachedPlayers[cid].accounts >= 1 then
            for k=1, #cachedPlayers[cid].accounts do
                if cachedPlayers[cid].accounts[k] == account then
                    table.remove(cachedPlayers[cid].accounts, k)
                    cachedPlayers[cid].accounts[#cachedPlayers[cid].accounts+1] = newName
                end
            end
        end
        ::Skip::
    end
    pr_lib.database.update('UPDATE bank_accounts_new SET id = ? WHERE id = ?',{newName, account})
    pr_lib.database.update('UPDATE renewed_account_members SET account_id = ? WHERE account_id = ?', {newName, account})
    return true
end

pr_lib.callback.register('Renewed-Banking:server:changeAccountName', function(source, account, newName)
    return updateAccountName(account, newName, source)
end) exports("changeAccountName", updateAccountName)-- Should only use this on very secure backends to avoid anyone using this as this is a server side ONLY export --

--- Retrieves a cached job account if it exists.
---@param jobName string The name of the job whose account is being retrieved.
---@return table|nil account Returns the job account if it exists, otherwise `nil`.
function GetJobAccount(jobName)
    if type(jobName) ~= "string" or jobName == "" then
        error(("^5[%s]^7-^1[ERROR]^7 %s"):format(GetInvokingResource(), "Invalid job name: expected a non-empty string"))
    end
    return cachedAccounts[jobName] or nil -- Returns account if found, otherwise nil
end
exports('GetJobAccount', GetJobAccount)

--- Creates a shared job account for an organization/society.
--- @param job table A table containing job account details:
---        job.name string - The unique identifier for the job (e.g., "mechanic", "police").
---        job.label string - The display name/label for the job (e.g., "Mechanic", "Police Department").
--- @param initialBalance number? The starting balance of the account. Default is 0.
--- @return table Returns the account table if found or successfully created. This function may raise an error if validation or database insertion fails.
local function CreateJobAccount(job, initialBalance)
    local currentResourceName = GetInvokingResource()

    -- Validate input parameters
    if type(job) ~= "table" then
        error(("^5[%s]^7-^1[ERROR]^7 %s"):format(currentResourceName, "Invalid parameter: expected a table (job)"))
    end


    if type(job.name) ~= "string" or job.name == "" then
        error(("^5[%s]^7-^1[ERROR]^7 %s"):format(currentResourceName, "Invalid job name: expected a non-empty string"))
    end

    if type(job.label) ~= "string" or job.label == "" then
        error(("^5[%s]^7-^1[ERROR]^7 %s"):format(currentResourceName, "Invalid job label: expected a non-empty string"))
    end
    
    -- Check if account already exists
    if cachedAccounts[job.name] then
        return cachedAccounts[job.name]
    end

    -- Create the job account in cache
    cachedAccounts[job.name] = {
        id = job.name,
        type = locale("org"),
        name = job.label,
        frozen = 0,
        amount = tonumber(initialBalance) or 0,
        transactions = {},
        auth = {},
        creator = nil
    }

    local success, errorMsg = pr_lib.database.insert("INSERT INTO bank_accounts_new (id, amount, transactions, auth, isFrozen, creator) VALUES (?, ?, ?, ?, ?, NULL)", {
        job.name,
        cachedAccounts[job.name].amount,
        json.encode(cachedAccounts[job.name].transactions), -- Convert transactions to JSON
        json.encode(cachedAccounts[job.name].auth), -- Convert auth list to JSON
        cachedAccounts[job.name].frozen
    })

    -- Handle potential database errors
    if not success then
	cachedAccounts[job.name] = nil
        error(("^5[%s]^7-^1[ERROR]^7 %s"):format(currentResourceName, "Database error: " .. tostring(errorMsg)))
    end

    return cachedAccounts[job.name]
end
exports("CreateJobAccount", CreateJobAccount)

local function addAccountMember(account, member)
    if not account or not member then return end

    if not cachedAccounts[account] then print(locale("invalid_account", account)) return end

    local Player2 = getPlayerData(false, member)
    if not Player2 then return end

    local targetCID = GetIdentifier(Player2)
    if cachedPlayers[targetCID] then
        cachedPlayers[targetCID].accounts[#cachedPlayers[targetCID].accounts+1] = account
    end

    local auth = {}
    for k, _ in pairs(cachedAccounts[account].auth) do auth[#auth+1] = k end
    auth[#auth+1] = targetCID
    cachedAccounts[account].auth[targetCID] = true
    pr_lib.database.update('UPDATE bank_accounts_new SET auth = ? WHERE id = ?',{json.encode(auth), account})

end
exports("addAccountMember", addAccountMember)

local function removeAccountMember(account, member)
    local Player2 = getPlayerData(false, member)

    if not Player2 then return end
    if not cachedAccounts[account] then print(locale("invalid_account", account)) return end

    local targetCID = GetIdentifier(Player2)

    local tmp = {}
    for k in pairs(cachedAccounts[account].auth) do
        if targetCID ~= k then
            tmp[#tmp+1] = k
        end
    end

    if cachedPlayers[targetCID] then
        local newAccount = {}
        if #cachedPlayers[targetCID].accounts >= 1 then
            for k=1, #cachedPlayers[targetCID].accounts do
                if cachedPlayers[targetCID].accounts[k] ~= account then
                    newAccount[#newAccount+1] = cachedPlayers[targetCID].accounts[k]
                end
            end
        end
        cachedPlayers[targetCID].accounts = newAccount
    end

    cachedAccounts[account].auth[targetCID] = nil

    pr_lib.database.update('UPDATE bank_accounts_new SET auth = ? WHERE id = ?',{json.encode(tmp), account})
end
exports("removeAccountMember", removeAccountMember)

local function getAccountTransactions(account)
    if cachedAccounts[account] then
        return cachedAccounts[account].transactions
    elseif cachedPlayers[account] then
        return cachedPlayers[account].transactions
    end
    print(locale("invalid_account", account))
    return false
end
exports("getAccountTransactions", getAccountTransactions)

pr_lib.addCommand.add('givecash', {
    help = 'Gives an item to a player',
    params = {
        {
            name = 'target',
            type = 'playerId',
            help = locale("cmd_plyr_id"),
        },
        {
            name = 'amount',
            type = 'number',
            help = locale("cmd_amount"),
        }
    }
}, function(source, args)
    local target = args.values.target
    local amount = args.values.amount
    local Player = GetPlayerObject(source)
    if not Player then return end

    local iPlayer = GetPlayerObject(target)
    if not iPlayer then return Notify(source, {title = locale("bank_name"), description = locale('unknown_player', target), type = "error"}) end

    if IsDead(Player) then return Notify(source, {title = locale("bank_name"), description = locale('dead'), type = "error"}) end
    if #(GetEntityCoords(GetPlayerPed(source)) - GetEntityCoords(GetPlayerPed(target))) > 10.0 then return Notify(source, {title = locale("bank_name"), description = locale('too_far_away'), type = "error"}) end
    if amount < 0 then return Notify(source, {title = locale("bank_name"), description = locale('invalid_amount', locale('givecash')), type = "error"}) end

    if RemoveMoney(Player, amount, 'cash') then
        AddMoney(iPlayer, amount, 'cash')
        local nameA = GetCharacterName(Player)
        local nameB = GetCharacterName(iPlayer)
        Notify(source, {title = locale("bank_name"), description = locale('give_cash', nameB, tostring(amount)), type = "error"})
        Notify(target, {title = locale("bank_name"), description = locale('received_cash', nameA, tostring(amount)), type = "success"})
    else
        Notify(target, {title = locale("bank_name"), description = locale('not_enough_money'), type = "error"})
    end
end)

function ExportHandler(resource, name, cb)
    AddEventHandler(('__cfx_export_%s_%s'):format(resource, name), function(setCB)
        setCB(cb)
    end)
end

local createTables = {
    { query = "CREATE TABLE IF NOT EXISTS `bank_accounts_new` (`id` varchar(50) NOT NULL, `amount` int(11) DEFAULT 0, `transactions` longtext DEFAULT '[]', `auth` longtext DEFAULT '[]', `isFrozen` int(11) DEFAULT 0, `creator` varchar(50) DEFAULT NULL, PRIMARY KEY (`id`));", values = nil },
    { query = "CREATE TABLE IF NOT EXISTS `player_transactions` (`id` varchar(50) NOT NULL, `isFrozen` int(11) DEFAULT 0, `transactions` longtext DEFAULT '[]', PRIMARY KEY (`id`));", values = nil }
}

assert(pr_lib.database.transaction(createTables), "Failed to create tables")
