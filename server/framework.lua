local Config = lib.load('config')

Framework = {}

local function DetectFramework()
    if Config.Framework ~= 'auto' then return Config.Framework end
    if GetResourceState('qbx_core') == 'started' then return 'qbx' end
    if GetResourceState('qb-core') == 'started' then return 'qb' end
    if GetResourceState('es_extended') == 'started' then return 'esx' end

    return 'ox'
end

local Name = DetectFramework()

local Adapters = {}

function Adapters.esx(Source, Account, Amount, Reason)
    local ESX = exports.es_extended:getSharedObject()
    local Player = ESX.GetPlayerFromId(Source)
    if not Player then return false end

    Player.addAccountMoney(Account == 'cash' and 'money' or Account, Amount, Reason)
    return true
end

function Adapters.qbx(Source, Account, Amount, Reason)
    return exports.qbx_core:AddMoney(Source, Account == 'money' and 'cash' or Account, Amount, Reason)
end

function Adapters.qb(Source, Account, Amount, Reason)
    local Player = exports['qb-core']:GetCoreObject().Functions.GetPlayer(Source)
    if not Player then return false end

    return Player.Functions.AddMoney(Account == 'money' and 'cash' or Account, Amount, Reason)
end

function Adapters.ox(Source, Account, Amount)
    return exports.ox_inventory:AddItem(Source, Account == 'cash' and Config.MoneyItem or Account, Amount) and true or false
end

function Framework.GetName()
    return Name
end

function Framework.AddMoney(Source, Account, Amount, Reason)
    local Adapter = Adapters[Name] or Adapters.ox

    return Adapter(Source, Account, Amount, Reason)
end
