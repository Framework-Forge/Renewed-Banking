locale = pr_lib.locale()
Config = {
    -- Framework automatically detected
    -- QB, QBX, and ESX preconfigured edit the framework.lua to add functionality to other frameworks
    renewedMultiJob = true, -- QBCORE ONLY! https://github.com/Renewed-Scripts/qb-phone  
    progressbar = 'circle', -- circle or rectangle (Anything other than circle will default to rectangle)
    currency = 'USD', -- USD, EUR, GBP ect.....
    bankName = 'Los Santos',
    bankSubtitle = 'Banking',
    bankNotifications = {
        enabled = true,
        senderNumber = '0800000000',
        includeBalance = true,
        includeReason = true,
    },
    appearance = {
        logoUrl = 'img/bank.png',
        overviewTitle = '',
        overviewSubtitle = '',
        uiOpacity = 0.98,
    },
    invoices = {
        defaultDueDays = 7,
        defaultInterestRate = 0.0,
        defaultInterestInterval = 'day',
        maxInterestRate = 100.0,
        maxTotalMultiplier = 10.0,
    },
    theme = {
        primary = '#ff7a1a',
        primaryDark = '#ff8c2a',
        primaryText = '#ffffff',
        background = '#0a0a0c',
        surface = '#121214',
        card = '#18181c',
        border = '#2d2d35',
        text = '#ffffff',
        textMuted = '#8e8e9f'
    },
    atms = {
        `prop_atm_01`,
        `prop_atm_02`,
        `prop_atm_03`,
        `prop_fleeca_atm`
    },
    peds = {
        [1] = { -- Pacific Standard
            model = 'u_m_m_bankman',
            coords = vector4(241.44, 227.19, 106.29, 170.43),
            createAccounts = true
        },
        [2] = {
            model = 'ig_barry',
            coords = vector4(313.84, -280.58, 54.16, 338.31)
        },
        [3] = {
            model = 'ig_barry',
            coords = vector4(149.46, -1042.09, 29.37, 335.43)
        },
        [4] = {
            model = 'ig_barry',
            coords = vector4(-351.23, -51.28, 49.04, 341.73)
        },
        [5] = {
            model = 'ig_barry',
            coords = vector4(-1211.9, -331.9, 37.78, 20.07)
        },
        [6] = {
            model = 'ig_barry',
            coords = vector4(-2961.14, 483.09, 15.7, 83.84)
        },
        [7] = {
            model = 'ig_barry',
            coords = vector4(1174.8, 2708.2, 38.09, 178.52)
        },
        [8] = { -- paleto
            model = 'u_m_m_bankman',
            coords = vector4(-112.22, 6471.01, 31.63, 134.18),
            createAccounts = true
        }
    }
}
