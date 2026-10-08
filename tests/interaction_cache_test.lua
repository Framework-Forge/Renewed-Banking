-- Run with lua55.exe tests/interaction_cache_test.lua from the resource root.
local function read(path)
    local file = assert(io.open(path, 'r'))
    local text = file:read('*a')
    file:close()
    return text
end

local function environment(values)
    return setmetatable(values, {__index = function(_, key)
        error('Unexpected global access: ' .. key)
    end})
end

local serverValues, callbacks, messages = {}, {}, {}
local server = environment({
    type=type, tonumber=tonumber, math=math, Config={invoices={}},
    pr_lib={
        cache={
            set=function(key, value) serverValues[key]=value end,
            get=function(key) return serverValues[key] end,
        },
        callback={register=function(name, fn) callbacks[name]=fn end},
    },
    TriggerClientEvent=function(name, target, value)
        assert(target == -1)
        messages[#messages+1]={name=name, value=value}
    end,
})
local serverPrefix = assert(read('server/invoices.lua'):match('^(.-)local function canManage'))
assert(load(serverPrefix .. '\npublishInteractionSettings()', '@server/cache', 't', server))()
local snapshot = callbacks['Renewed-Banking:server:getInteractionSettings']()
assert(snapshot == serverValues['Renewed-Banking:interaction'])
assert(snapshot.mode == 'target' and snapshot.revision == 1)
assert(serverValues['Renewed-Banking:invoiceSettings'])
assert(messages[1].value == snapshot)

local function clientTest(failFirst)
    local values, events, threads = {}, {}, {}
    local calls = 0
    local client = environment({
        type=type, tonumber=tonumber, ipairs=ipairs, pcall=pcall,
        source=65535,
        pr_lib={
            cache={
                set=function(key, value) values[key]=value end,
                get=function(key) return values[key] end,
            },
            callback={await=function(name)
                assert(name == 'Renewed-Banking:server:getInteractionSettings')
                calls=calls+1
                if failFirst and calls == 1 then error('simulated timeout') end
                return snapshot
            end},
        },
        RegisterNetEvent=function(name, fn) events[name]=fn end,
        CreateThread=function(fn) threads[#threads+1]=fn end,
        Wait=function() end,
        print=function() error('Unexpected retry exhaustion') end,
    })
    local prefix = assert(read('client/main.lua'):match('^(.-)local function doProgressBar'))
    assert(load(prefix, '@client/cache', 't', client))()
    local event = assert(events['Renewed-Banking:client:interactionSettings'])
    -- A live update may arrive before the initial snapshot response.
    event({mode='interact', respectWalls=true, revision=2})
    threads[1]()
    local value = values['Renewed-Banking:interaction']
    assert(value.mode == 'interact' and value.respectWalls and value.revision == 2)
    event({mode='target', respectWalls=false, revision=1})
    assert(values['Renewed-Banking:interaction'] == value)
    client.source=0
    event({mode='target', revision=3})
    assert(values['Renewed-Banking:interaction'] == value)
    client.source=65535
    event({mode='unknown', respectWalls='true', revision=3})
    assert(values['Renewed-Banking:interaction'].mode == 'target')
    assert(values['Renewed-Banking:interaction'].respectWalls == false)
    assert(calls == (failFirst and 2 or 1))
end
clientTest(false)
clientTest(true)
print('PASS: cache, snapshot, deltas, stale responses, source guard and retry; no state bag access')
