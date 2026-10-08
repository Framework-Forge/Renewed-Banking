RegisterNetEvent("Renewed-Banking:client:accountManagmentMenu", function()
    pr_lib.registerContext({
        id = 'renewed_banking_account_management',
        title = locale("bank_name"),
        position = 'top-right',
        options = {
            {
                title = locale("create_account"),
                icon = 'file-invoice-dollar',
                description = locale("create_account_txt"),
                onSelect = function()
                    TriggerEvent("Renewed-Banking:client:createAccountMenu")
                end
            },
            {
                title = locale("manage_account"),
                icon = 'users-gear',
                description = locale("manage_account_txt"),
                onSelect = function()
                    TriggerEvent('Renewed-Banking:client:viewAccountsMenu')
                end
            }
        }
    })
    pr_lib.showContext("renewed_banking_account_management")
end)

RegisterNetEvent("Renewed-Banking:client:createAccountMenu", function()
    local input = pr_lib.inputDialog(locale("bank_name"), {{
        type = "input",
        label = locale("account_id"),
        placeholder = "a_test_account"
    }})
    if input and input[1] then
        input[1] = input[1]:lower():gsub("%s+", "")
        pr_lib.callback.await("Renewed-Banking:server:createNewAccount", 10000, input[1])
    end
end)

RegisterNetEvent("Renewed-Banking:client:accountsMenu", function(data)
    local menuOpts = {}
    if #data >= 1 then
        for k=1, #data do
            local acc = data[k]
            menuOpts[#menuOpts+1] = {
                title = acc,
                icon = 'users-gear',
                description = locale("view_members"),
                onSelect = function()
                    TriggerEvent("Renewed-Banking:client:accountsMenuView", { account = acc })
                end
            }
        end
    else
        menuOpts[#menuOpts+1] = {
            title = locale("no_account"),
            description = locale("no_account_txt"),
            disabled = true
        }
    end
    pr_lib.registerContext({
        id = 'renewed_banking_account_list',
        title = locale("bank_name"),
        position = 'top-right',
        menu = "renewed_banking_account_management",
        options = menuOpts
    })
    pr_lib.showContext("renewed_banking_account_list")
end)

RegisterNetEvent("Renewed-Banking:client:accountsMenuView", function(data)
    pr_lib.registerContext({
        id = 'renewed_banking_account_view',
        title = locale("bank_name"),
        position = 'top-right',
        menu = "renewed_banking_account_list",
        options = {
            {
                title = locale("manage_members"),
                icon = 'users-gear',
                description = locale("manage_members_txt"),
                onSelect = function()
                    TriggerEvent("Renewed-Banking:client:openMemberManagement", data)
                end
            },
            {
                title = locale("edit_acc_name"),
                icon = 'users-gear',
                description = locale("edit_acc_name_txt"),
                onSelect = function()
                    TriggerEvent("Renewed-Banking:client:changeAccountName", data)
                end
            },
            {
                title = locale("delete_account"),
                icon = 'users-gear',
                description = locale("delete_account_txt"),
                onSelect = function()
                    TriggerEvent("Renewed-Banking:client:deleteAccount", data)
                end
            }
        }
    })
    pr_lib.showContext("renewed_banking_account_view")
end)

RegisterNetEvent("Renewed-Banking:client:openMemberManagement", function(data)
    local memberData = pr_lib.callback.await("Renewed-Banking:server:viewMemberManagement", 10000, data)
    if memberData then
        TriggerEvent("Renewed-Banking:client:viewMemberManagement", memberData)
    end
end)

RegisterNetEvent("Renewed-Banking:client:viewMemberManagement", function(data)
    local menuOpts = {}
    local account = data.account
    for k,v in pairs(data.members) do
        local cidKey, memberName = k, v
        menuOpts[#menuOpts+1] = {
            title = memberName,
            description = locale("remove_member_txt"),
            onSelect = function()
                TriggerEvent('Renewed-Banking:client:removeMemberConfirmation', { account = account, cid = cidKey })
            end
        }
    end
    menuOpts[#menuOpts+1] = {
        title = locale("add_member"),
        description = locale("add_member_txt"),
        icon = 'user-plus',
        onSelect = function()
            TriggerEvent('Renewed-Banking:client:addAccountMember', { account = account })
        end
    }
    pr_lib.registerContext({
        id = 'renewed_banking_member_manage',
        title = locale("bank_name"),
        position = 'top-right',
        menu = 'renewed_banking_account_view',
        options = menuOpts
    })
    pr_lib.showContext("renewed_banking_member_manage")
end)

RegisterNetEvent('Renewed-Banking:client:removeMemberConfirmation', function(data)
    pr_lib.registerContext({
        id = 'renewed_banking_member_remove',
        title = locale('bank_name'),
        position = 'top-right',
        menu = 'renewed_banking_account_view',
        options = {
            {
                title = locale('remove_member'),
                description = locale('remove_member_txt2', data.cid),
                icon = 'user-minus',
                onSelect = function()
                    TriggerEvent('Renewed-Banking:client:removeAccountMember', data)
                end
            }
        }
    })
    pr_lib.showContext('renewed_banking_member_remove')
end)

RegisterNetEvent('Renewed-Banking:client:removeAccountMember', function(data)
    pr_lib.callback.await('Renewed-Banking:server:removeAccountMember', 10000, data)
end)

RegisterNetEvent('Renewed-Banking:client:addAccountMember', function(data)
    local input = pr_lib.inputDialog(locale('add_account_member'), {{
        type = 'input',
        label = locale('citizen_id'),
        placeholder = '1001'
    }})
    if input and input[1] then
        input[1] = input[1]:upper():gsub("%s+", "")
        pr_lib.callback.await('Renewed-Banking:server:addAccountMember', 10000, data.account, input[1])
    end
end)

RegisterNetEvent('Renewed-Banking:client:changeAccountName', function(data)
    local input = pr_lib.inputDialog(locale('change_account_name'), {{
        type = 'input',
        label = locale('account_id'),
        placeholder = 'savings-1001'
    }})
    if input and input[1] then
        input[1] = input[1]:lower():gsub("%s+", "")
        pr_lib.callback.await('Renewed-Banking:server:changeAccountName', 10000, data.account, input[1])
    end
end)

RegisterNetEvent('Renewed-Banking:client:deleteAccount', function(data)
    pr_lib.callback.await('Renewed-Banking:server:deleteAccount', 10000, data)
end)
