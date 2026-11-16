local function clean(value, limit)
    value = type(value) == 'string' and value:match('^%s*(.-)%s*$') or ''
    if value == '' then return nil end
    return value:sub(1, limit)
end

local function affectedRows(result)
    if type(result) == 'number' then return result end
    if type(result) ~= 'table' then return 0 end
    return tonumber(result.affectedRows or result.changedRows or result.affected_rows or result[1]) or 0
end

local invoiceSettings = {}
local function normalizeColor(value, fallback)
    if type(value) == 'string' and value:match('^#%x%x%x%x%x%x$') then return value:lower() end
    return fallback
end

local function normalizeSettings(value)
    value = type(value) == 'table' and value or {}
    local configured = Config.invoices or {}
    local appearance = Config.appearance or {}
    local theme = Config.theme or {}
    local interval = value.defaultInterestInterval or configured.defaultInterestInterval
    return {
        interactionMode = value.interactionMode == 'interact' and 'interact' or 'target',
        respectWalls = value.respectWalls == true,
        defaultDueDays = math.max(0, math.min(3650, tonumber(value.defaultDueDays) or tonumber(configured.defaultDueDays) or 7)),
        defaultInterestRate = math.max(0, math.min(100, tonumber(value.defaultInterestRate) or tonumber(configured.defaultInterestRate) or 0)),
        defaultInterestInterval = interval == 'hour' and 'hour' or 'day',
        maxInterestRate = math.max(0, math.min(100, tonumber(value.maxInterestRate) or tonumber(configured.maxInterestRate) or 100)),
        maxTotalMultiplier = math.max(1, math.min(100, tonumber(value.maxTotalMultiplier) or tonumber(configured.maxTotalMultiplier) or 10)),
        logoUrl = clean(value.logoUrl, 2048) or clean(appearance.logoUrl, 2048) or '',
        bankName = clean(value.bankName, 60) or clean(Config.bankName, 60) or 'Los Santos',
        bankSubtitle = clean(value.bankSubtitle, 80) or clean(Config.bankSubtitle, 80) or 'Banking',
        overviewTitle = clean(value.overviewTitle, 100) or clean(appearance.overviewTitle, 100) or '',
        overviewSubtitle = clean(value.overviewSubtitle, 160) or clean(appearance.overviewSubtitle, 160) or '',
        uiOpacity = math.max(0.55, math.min(1.0, tonumber(value.uiOpacity) or tonumber(appearance.uiOpacity) or 0.98)),
        primaryColor = normalizeColor(value.primaryColor, theme.primary or '#ff7a1a'),
        primaryHoverColor = normalizeColor(value.primaryHoverColor, theme.primaryDark or '#ff8c2a'),
        accentTextColor = normalizeColor(value.accentTextColor, theme.primaryText or '#ffffff'),
        backgroundColor = normalizeColor(value.backgroundColor, theme.background or '#0a0a0c'),
        surfaceColor = normalizeColor(value.surfaceColor, theme.surface or '#121214'),
        cardColor = normalizeColor(value.cardColor, theme.card or '#18181c'),
        borderColor = normalizeColor(value.borderColor, theme.border or '#2d2d35'),
        textColor = normalizeColor(value.textColor, theme.text or '#ffffff'),
        mutedTextColor = normalizeColor(value.mutedTextColor, theme.textMuted or '#8e8e9f'),
    }
end
invoiceSettings = normalizeSettings(Config.invoices)
pr_lib.cache.set('Renewed-Banking:invoiceSettings', invoiceSettings)

local interactionRevision = 0
local function publishInteractionSettings()
    pr_lib.cache.set('Renewed-Banking:invoiceSettings', invoiceSettings)
    interactionRevision = interactionRevision + 1
    local snapshot = {
        mode = invoiceSettings.interactionMode,
        respectWalls = invoiceSettings.respectWalls,
        revision = interactionRevision,
    }
    pr_lib.cache.set('Renewed-Banking:interaction', snapshot)
    TriggerClientEvent('Renewed-Banking:client:interactionSettings', -1, snapshot)
end

pr_lib.callback.register('Renewed-Banking:server:getInteractionSettings', function()
    return pr_lib.cache.get('Renewed-Banking:interaction')
        or {mode=invoiceSettings.interactionMode, respectWalls=invoiceSettings.respectWalls, revision=interactionRevision}
end)

local function canManage(source)
    return source == 0 or IsPlayerAceAllowed(source, 'renewed-banking.admin')
        or IsPlayerAceAllowed(source, 'group.admin') or IsPlayerAceAllowed(source, 'admin')
end

local function invoiceAmount(row, now)
    local principal = math.max(0, math.floor(tonumber(row.principal) or 0))
    local rate = math.max(0, tonumber(row.interest_rate) or 0)
    local dueAt = tonumber(row.due_at) or 0
    local seconds = row.interest_interval == 'hour' and 3600 or 86400
    local periods = now > dueAt and math.floor((now - dueAt) / seconds) or 0
    local multiplier = 1 + (rate / 100) * periods
    local maximum = tonumber(invoiceSettings.maxTotalMultiplier) or 10
    multiplier = math.min(multiplier, math.max(1, maximum))
    return math.floor(principal * multiplier + 0.5), periods
end

local function publicInvoice(row)
    local total, periods = invoiceAmount(row, os.time())
    local metadata = {}
    if type(row.metadata) == 'string' and row.metadata ~= '' then
        local ok, decoded = pcall(json.decode, row.metadata)
        if ok and type(decoded) == 'table' then metadata = decoded end
    end
    return {
        id = tonumber(row.id), externalId = row.external_id, issuer = row.issuer,
        issuerResource = row.issuer_resource, receiverAccount = row.receiver_account,
        title = row.title, description = row.description or '', principal = tonumber(row.principal) or 0,
        interestRate = tonumber(row.interest_rate) or 0, interestInterval = row.interest_interval,
        dueAt = tonumber(row.due_at), status = row.status, createdAt = tonumber(row.created_at),
        paidAt = tonumber(row.paid_at), paidAmount = tonumber(row.paid_amount),
        total = total, overduePeriods = periods, metadata = metadata,
    }
end

local function findByExternal(resource, externalId)
    return pr_lib.database.single(
        'SELECT * FROM renewed_invoices WHERE issuer_resource=? AND external_id=? LIMIT 1',
        { resource, externalId }
    )
end

local function createInvoice(data)
    if type(data) ~= 'table' then return { success = false, reason = 'invalid_data' } end
    local resource = GetInvokingResource() or clean(data.issuerResource, 80)
    local recipient = clean(data.recipient, 60)
    local title = clean(data.title, 120)
    local issuer = clean(data.issuer, 120) or resource
    local amount = math.floor(tonumber(data.amount) or 0)
    if not resource or not recipient or not title or amount < 1 or amount > 100000000 then
        return { success = false, reason = 'invalid_data' }
    end

    local externalId = clean(data.externalId, 120)
    if externalId then
        local existing = findByExternal(resource, externalId)
        if existing then return { success = true, invoice = publicInvoice(existing), existing = true } end
    end

    local defaults = invoiceSettings
    local interval = data.interestInterval == 'hour' and 'hour' or data.interestInterval == 'day' and 'day'
        or defaults.defaultInterestInterval == 'hour' and 'hour' or 'day'
    local rate = tonumber(data.interestRate)
    if rate == nil then rate = tonumber(defaults.defaultInterestRate) or 0 end
    rate = math.max(0, math.min(rate, tonumber(defaults.maxInterestRate) or 100))
    local now = os.time()
    local dueAt = math.floor(tonumber(data.dueAt) or (now + math.max(0, tonumber(defaults.defaultDueDays) or 7) * 86400))
    local metadata = type(data.metadata) == 'table' and json.encode(data.metadata) or nil

    pr_lib.database.insert([[INSERT INTO renewed_invoices
        (external_id,recipient,issuer_resource,issuer,receiver_account,title,description,principal,
         interest_rate,interest_interval,due_at,status,metadata,created_at)
        VALUES (?,?,?,?,?,?,?,?,?,?,?,'active',?,?)]], {
        externalId, recipient, resource, issuer, clean(data.receiverAccount, 50), title,
        clean(data.description, 500), amount, rate, interval, dueAt, metadata, now
    })
    local row = externalId and findByExternal(resource, externalId)
        or pr_lib.database.single('SELECT * FROM renewed_invoices WHERE recipient=? ORDER BY id DESC LIMIT 1', { recipient })
    if not row then return { success = false, reason = 'database_error' } end
    return { success = true, invoice = publicInvoice(row) }
end

exports('CreateInvoice', createInvoice)

exports('UpdateInvoice', function(externalId, data)
    local resource = GetInvokingResource()
    externalId = clean(externalId, 120)
    if not resource or not externalId or type(data) ~= 'table' then return false end
    local amount = math.floor(tonumber(data.amount) or 0)
    if amount < 1 or amount > 100000000 then return false end
    local result = pr_lib.database.update([[UPDATE renewed_invoices SET principal=?,description=COALESCE(?,description),
        metadata=COALESCE(?,metadata) WHERE issuer_resource=? AND external_id=? AND status='active']], {
        amount, clean(data.description,500), type(data.metadata)=='table' and json.encode(data.metadata) or nil,
        resource, externalId
    })
    return affectedRows(result) > 0
end)
exports('ResolveInvoice', function(externalId, status)
    local resource = GetInvokingResource()
    externalId = clean(externalId, 120)
    if not resource or not externalId then return false end
    status = status == 'paid' and 'paid' or 'cancelled'
    local result = pr_lib.database.update([[UPDATE renewed_invoices SET status=?,paid_at=IF(?='paid',?,paid_at),
        paid_amount=IF(?='paid',principal,paid_amount) WHERE issuer_resource=? AND external_id=? AND status IN ('active','processing')]],
        { status, status, os.time(), status, resource, externalId })
    return affectedRows(result) > 0
end)

exports('GetInvoice', function(externalId)
    local resource = GetInvokingResource()
    local row = resource and findByExternal(resource, clean(externalId, 120))
    return row and publicInvoice(row) or nil
end)

local function invoiceAccountFor(source, requestedAccount, permission)
    local player = GetPlayerObject(source)
    if not player then return nil end
    local ownCid = GetIdentifier(player)
    local accountId = type(requestedAccount) == 'string' and requestedAccount or ownCid
    if accountId ~= ownCid and (type(RenewedBankingCanAccountAction) ~= 'function'
        or not RenewedBankingCanAccountAction(source, accountId, permission)) then
        return nil
    end
    return accountId
end

local function invoiceList(recipient)
    local rows = pr_lib.database.query([[SELECT * FROM renewed_invoices WHERE recipient=?
        AND status IN ('active','paid','cancelled') ORDER BY status='active' DESC,due_at ASC,id DESC LIMIT 250]], { recipient }) or {}
    local result = {}
    for index = 1, #rows do result[index] = publicInvoice(rows[index]) end
    return result
end

pr_lib.callback.register('Renewed-Banking:server:getInvoices', function(source, accountId)
    local recipient = invoiceAccountFor(source, accountId, 'payInvoices')
    if not recipient then return { entries = {}, canManage = canManage(source), settings = invoiceSettings, forbidden = true } end
    local result = invoiceList(recipient)
    return { entries=result, canManage=canManage(source), settings=invoiceSettings }
end)

pr_lib.callback.register('Renewed-Banking:server:saveInvoiceSettings', function(source, data)
    if not canManage(source) then return {success=false,reason='no_permission'} end
    invoiceSettings = normalizeSettings(data)
    pr_lib.database.update([[INSERT INTO renewed_invoice_settings (id,settings) VALUES (1,?)
        ON DUPLICATE KEY UPDATE settings=VALUES(settings)]], {json.encode(invoiceSettings)})
    publishInteractionSettings()
    return {success=true,settings=invoiceSettings}
end)

pr_lib.callback.register('Renewed-Banking:server:payInvoice', function(source, data)
    data = type(data) == 'table' and data or { id = data }
    local invoiceId = tonumber(data.id)
    local player = GetPlayerObject(source)
    if not invoiceId or not player then return { success = false, reason = 'invalid_invoice' } end
    local recipient = invoiceAccountFor(source, data.accountId, 'payInvoices')
    if not recipient then return { success = false, reason = 'no_permission' } end
    local row = pr_lib.database.single('SELECT * FROM renewed_invoices WHERE id=? AND recipient=? LIMIT 1', { invoiceId, recipient })
    if not row or row.status ~= 'active' then return { success = false, reason = 'invoice_unavailable' } end
    local amount = invoiceAmount(row, os.time())
    local claimed = pr_lib.database.update("UPDATE renewed_invoices SET status='processing' WHERE id=? AND status='active'", { invoiceId })
    if affectedRows(claimed) < 1 then return { success = false, reason = 'invoice_unavailable' } end

    local comment = locale('invoice_transaction', invoiceId, row.title)
    if type(RenewedBankingDebitAccount) ~= 'function' or not RenewedBankingDebitAccount(recipient, amount, comment) then
        pr_lib.database.update("UPDATE renewed_invoices SET status='active' WHERE id=? AND status='processing'", { invoiceId })
        return { success = false, reason = 'not_enough_money' }
    end

    if row.receiver_account and row.receiver_account ~= '' then
        local credited = AddAccountMoney(row.receiver_account, amount)
        if not credited then
            if type(RenewedBankingCreditAccount) == 'function' then
                RenewedBankingCreditAccount(recipient, amount, locale('invoice_refund', comment))
            end
            pr_lib.database.update("UPDATE renewed_invoices SET status='active' WHERE id=? AND status='processing'", { invoiceId })
            return { success = false, reason = 'receiver_unavailable' }
        end
    end

    local now = os.time()
    pr_lib.database.update("UPDATE renewed_invoices SET status='paid',paid_at=?,paid_amount=? WHERE id=? AND status='processing'", { now, amount, invoiceId })
    -- Payment is complete here. Optional bookkeeping must never prevent the
    -- callback from answering the NUI.
    if type(RenewedBankingHandleTransaction) == 'function' then
        local transactionOk, transactionError = pcall(RenewedBankingHandleTransaction,
            recipient, locale('personal_acc') .. recipient, amount, comment,
            GetCharacterName(player), row.issuer, 'withdraw')
        if not transactionOk then
            print(('[Renewed-Banking] Failed to record invoice #%s transaction: %s')
                :format(invoiceId, tostring(transactionError)))
        end
    end
    row.status, row.paid_at, row.paid_amount = 'paid', now, amount
    local eventOk, eventError = pcall(TriggerEvent, 'Renewed-Banking:server:invoicePaid', publicInvoice(row))
    if not eventOk then
        print(('[Renewed-Banking] Failed to emit paid event for invoice #%s: %s')
            :format(invoiceId, tostring(eventError)))
    end
    return { success = true, invoices = (function()
        return invoiceList(recipient)
    end)(), paidAmount = amount }
end)

pr_lib.database.ready(function()
    pr_lib.database.query([[CREATE TABLE IF NOT EXISTS renewed_invoices (
        id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,external_id VARCHAR(120),recipient VARCHAR(60) NOT NULL,
        issuer_resource VARCHAR(80) NOT NULL,issuer VARCHAR(120) NOT NULL,receiver_account VARCHAR(50),
        title VARCHAR(120) NOT NULL,description VARCHAR(500),principal INT UNSIGNED NOT NULL,
        interest_rate DECIMAL(8,4) NOT NULL DEFAULT 0,interest_interval ENUM('hour','day') NOT NULL DEFAULT 'day',
        due_at BIGINT NOT NULL,status ENUM('active','processing','paid','cancelled') NOT NULL DEFAULT 'active',
        metadata LONGTEXT,created_at BIGINT NOT NULL,paid_at BIGINT,paid_amount INT UNSIGNED,
        PRIMARY KEY(id),UNIQUE KEY uniq_invoice_external(issuer_resource,external_id),
        KEY idx_invoice_recipient_status(recipient,status),KEY idx_invoice_due(due_at))]])
    pr_lib.database.update("UPDATE renewed_invoices SET status='active' WHERE status='processing'")
    pr_lib.database.query([[CREATE TABLE IF NOT EXISTS renewed_invoice_settings (
        id TINYINT UNSIGNED NOT NULL PRIMARY KEY,settings LONGTEXT NOT NULL)]])
    local encoded = pr_lib.database.scalar('SELECT settings FROM renewed_invoice_settings WHERE id=1')
    if type(encoded) == 'string' and encoded ~= '' then
        local ok, decoded = pcall(json.decode, encoded)
        if ok and type(decoded) == 'table' then invoiceSettings = normalizeSettings(decoded) end
    end
    publishInteractionSettings()
end)
