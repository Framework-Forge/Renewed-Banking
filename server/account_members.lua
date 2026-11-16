local function bool(value)
    return value == true or value == 1 or value == '1'
end

local function affectedRows(result)
    if type(result) == 'number' then return result end
    if type(result) == 'table' then
        return tonumber(result.affectedRows or result.changedRows or result.rowCount) or 0
    end
    return 0
end

local function clean(value, limit)
    value = type(value) == 'string' and value:match('^%s*(.-)%s*$') or ''
    if value == '' then return nil end
    return value:sub(1, limit)
end

function RenewedBankingGetMembership(accountId, memberCid)
    if type(accountId) ~= 'string' or type(memberCid) ~= 'string' then return nil end
    local row = pr_lib.database.single([[SELECT account_id,member_cid,member_name,can_withdraw,can_transfer,can_pay_invoices
        FROM renewed_account_members WHERE account_id=? AND member_cid=? LIMIT 1]], { accountId, memberCid })
    if not row then return nil end
    return {
        accountId = row.account_id,
        cid = row.member_cid,
        name = row.member_name,
        withdraw = bool(row.can_withdraw),
        transfer = bool(row.can_transfer),
        payInvoices = bool(row.can_pay_invoices),
    }
end

function RenewedBankingGetDelegatedAccounts(memberCid)
    if type(memberCid) ~= 'string' then return {} end
    return pr_lib.database.query([[SELECT account_id,member_cid,member_name,can_withdraw,can_transfer,can_pay_invoices
        FROM renewed_account_members WHERE member_cid=? ORDER BY account_id]], { memberCid }) or {}
end

local function authorizedOwner(source, accountId)
    return type(RenewedBankingIsAccountOwner) == 'function'
        and RenewedBankingIsAccountOwner(source, accountId) == true
end

local function publicMember(row)
    return {
        cid = row.member_cid,
        name = row.member_name,
        permissions = {
            withdraw = bool(row.can_withdraw),
            transfer = bool(row.can_transfer),
            payInvoices = bool(row.can_pay_invoices),
        }
    }
end

pr_lib.callback.register('Renewed-Banking:server:getAccountMembers', function(source, accountId)
    accountId = clean(accountId, 60)
    if not accountId or not authorizedOwner(source, accountId) then
        return { success = false, reason = 'no_permission', members = {} }
    end
    local rows = pr_lib.database.query([[SELECT member_cid,member_name,can_withdraw,can_transfer,can_pay_invoices
        FROM renewed_account_members WHERE account_id=? ORDER BY member_name,member_cid]], { accountId }) or {}
    local members = {}
    for i = 1, #rows do members[i] = publicMember(rows[i]) end
    return { success = true, members = members }
end)

pr_lib.callback.register('Renewed-Banking:server:addAccountDependent', function(source, data)
    data = type(data) == 'table' and data or {}
    local accountId = clean(data.accountId, 60)
    if not accountId or not authorizedOwner(source, accountId) then
        return { success = false, reason = 'no_permission' }
    end

    local target = GetPlayerObject(tonumber(data.playerId))
    if not target then return { success = false, reason = 'player_not_found' } end
    local targetCid = GetIdentifier(target)
    local owner = GetPlayerObject(source)
    if not targetCid or targetCid == GetIdentifier(owner) then
        return { success = false, reason = 'invalid_member' }
    end

    local targetName = clean(GetCharacterName(target), 120) or targetCid
    local values = type(data.permissions) == 'table' and data.permissions or {}
    pr_lib.database.update([[INSERT INTO renewed_account_members
        (account_id,member_cid,member_name,can_withdraw,can_transfer,can_pay_invoices,created_at,updated_at)
        VALUES (?,?,?,?,?,?,?,?) ON DUPLICATE KEY UPDATE member_name=VALUES(member_name),
        can_withdraw=VALUES(can_withdraw),can_transfer=VALUES(can_transfer),
        can_pay_invoices=VALUES(can_pay_invoices),updated_at=VALUES(updated_at)]], {
        accountId, targetCid, targetName, bool(values.withdraw) and 1 or 0,
        bool(values.transfer) and 1 or 0, bool(values.payInvoices) and 1 or 0,
        os.time(), os.time()
    })
    local membership = RenewedBankingGetMembership(accountId, targetCid)
    if not membership then return { success = false, reason = 'database_error' } end
    if UpdatePlayerAccount then UpdatePlayerAccount(targetCid) end
    return { success = true, member = membership }
end)

pr_lib.callback.register('Renewed-Banking:server:updateAccountDependent', function(source, data)
    data = type(data) == 'table' and data or {}
    local accountId, memberCid = clean(data.accountId, 60), clean(data.cid, 60)
    if not accountId or not memberCid or not authorizedOwner(source, accountId) then
        return { success = false, reason = 'no_permission' }
    end
    local values = type(data.permissions) == 'table' and data.permissions or {}
    local result = pr_lib.database.update([[UPDATE renewed_account_members SET can_withdraw=?,can_transfer=?,
        can_pay_invoices=?,updated_at=? WHERE account_id=? AND member_cid=?]], {
        bool(values.withdraw) and 1 or 0, bool(values.transfer) and 1 or 0,
        bool(values.payInvoices) and 1 or 0, os.time(), accountId, memberCid
    })
    return { success = affectedRows(result) > 0 }
end)

pr_lib.callback.register('Renewed-Banking:server:removeAccountDependent', function(source, data)
    data = type(data) == 'table' and data or {}
    local accountId, memberCid = clean(data.accountId, 60), clean(data.cid, 60)
    if not accountId or not memberCid or not authorizedOwner(source, accountId) then
        return { success = false, reason = 'no_permission' }
    end
    local result = pr_lib.database.update('DELETE FROM renewed_account_members WHERE account_id=? AND member_cid=?', { accountId, memberCid })
    if UpdatePlayerAccount then UpdatePlayerAccount(memberCid) end
    return { success = affectedRows(result) > 0 }
end)

pr_lib.database.ready(function()
    pr_lib.database.query([[CREATE TABLE IF NOT EXISTS renewed_account_members (
        account_id VARCHAR(60) NOT NULL,member_cid VARCHAR(60) NOT NULL,member_name VARCHAR(120) NOT NULL,
        can_withdraw TINYINT(1) NOT NULL DEFAULT 0,can_transfer TINYINT(1) NOT NULL DEFAULT 0,
        can_pay_invoices TINYINT(1) NOT NULL DEFAULT 0,created_at BIGINT NOT NULL,updated_at BIGINT NOT NULL,
        PRIMARY KEY(account_id,member_cid),KEY idx_renewed_member(member_cid))]])
end)
