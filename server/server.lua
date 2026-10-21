local Config = lib.load('config')

local Traders = {}
local Market = {}
local NextRoll = os.time() + Config.Market.Interval * 60

lib.locale()

local function RollMultiplier()
    return Config.Market.MinMultiplier + math.random() * (Config.Market.MaxMultiplier - Config.Market.MinMultiplier)
end

local function RollMarket(Name)
    local Trader = Traders[Name]
    if not Trader then return end

    local Count = #Trader.Items
    local HotIndex = Count > 1 and math.random(1, Count) or 0
    local Prices = {}

    for i = 1, Count do
        local Hot = i == HotIndex
        local Multiplier = RollMultiplier() + (Hot and Config.Market.HotBonus or 0)

        Prices[Trader.Items[i].Item] = { Multiplier = Multiplier, Hot = Hot }
    end

    Market[Name] = Prices
end

local function GetMarketEntry(Name, ItemName)
    local Prices = Config.Market.Enabled and Market[Name]

    return Prices and Prices[ItemName] or { Multiplier = 1.0, Hot = false }
end

local function GetCurrentPrice(Name, TraderItem)
    local Entry = GetMarketEntry(Name, TraderItem.Item)

    return math.max(1, math.floor((tonumber(TraderItem.Price) or 0) * Entry.Multiplier + 0.5))
end

local function GetTrend(Multiplier)
    if Multiplier >= 1.03 then return 'up' end
    if Multiplier <= 0.97 then return 'down' end

    return 'flat'
end

local function BuildTraderView(Name)
    local Trader = Traders[Name]
    if not Trader then return nil end

    local Items = {}

    for i = 1, #Trader.Items do
        local TraderItem = Trader.Items[i]
        local Entry = GetMarketEntry(Name, TraderItem.Item)
        local Row = {}

        for Key, Value in pairs(TraderItem) do Row[Key] = Value end

        Row.Price = GetCurrentPrice(Name, TraderItem)
        Row.Trend = GetTrend(Entry.Multiplier)
        Row.Hot = Entry.Hot
        Items[i] = Row
    end

    return {
        Label = Trader.Label,
        Currency = Trader.Currency,
        Items = Items,
        RefreshIn = Config.Market.Enabled and math.max(0, NextRoll - os.time()) or nil
    }
end

exports('RegisterTrader', function(Name, Data)
    if Traders[Name] then lib.print.info(('[Kanaltfyr] Overwriting trader: %s'):format(Name)) end

    Traders[Name] = Data
    RollMarket(Name)
end)

exports('GetTraders', function() return Traders end)
exports('GetTrader', function(Name) return Traders[Name] end)

lib.callback.register('heino_kanaltfyr:server:GetTrader', function(_, Name)
    local View = BuildTraderView(Name)
    if not View then lib.print.warn(('[Kanaltfyr] Trader not registered: %s'):format(tostring(Name))) end

    return View
end)

local function IsBlockedByState(Source)
    local PlayerState = Player(Source) and Player(Source).state
    if not PlayerState then return false end

    for i = 1, #Config.BlockedStates do
        if PlayerState[Config.BlockedStates[i]] == true then return true end
    end

    return false
end

local function IsNearTrader(Source, Name)
    local Data = Config.Traders[Name]
    if not Data then return false end

    local Ped = GetPlayerPed(Source)
    if not Ped or Ped == 0 then return false end

    return #(GetEntityCoords(Ped) - Data.Coords.xyz) <= Config.InteractDistance
end

local function Pay(Source, Trader, Payout, Amount, ItemName)
    if Trader.Currency.Type == 'Item' then
        exports.ox_inventory:AddItem(Source, Trader.Currency.Value, Payout)
    else
        Framework.AddMoney(Source, Trader.Currency.Value, Payout, locale('MoneyReason', Amount, ItemName))
    end
end

lib.callback.register('heino_kanaltfyr:server:SellItem', function(Source, Data)
    if IsBlockedByState(Source) then return false end
    if type(Data) ~= 'table' or type(Data.Item) ~= 'table' then return false end
    if type(Data.Trader) ~= 'string' or type(Data.Item.Item) ~= 'string' then return false end

    local Trader = Traders[Data.Trader]
    if not Trader or not IsNearTrader(Source, Data.Trader) then return false end

    local Amount = math.floor(tonumber(Data.Amount) or 0)
    if Amount < 1 or Amount > Config.MaxSellAmount then return false end

    for i = 1, #Trader.Items do
        local TraderItem = Trader.Items[i]

        if TraderItem.Item == Data.Item.Item then
            local Payout = GetCurrentPrice(Data.Trader, TraderItem) * Amount

            if not exports.ox_inventory:RemoveItem(Source, TraderItem.Item, Amount) then return false end

            Pay(Source, Trader, Payout, Amount, TraderItem.Item)
            KanaltfyrLogs.Sold(Source, Data.Trader, TraderItem.Item, Amount, Payout)

            return Payout
        end
    end

    return false
end)

if Config.Market.Enabled then
    CreateThread(function()
        while true do
            Wait(Config.Market.Interval * 60000)

            for Name in pairs(Traders) do RollMarket(Name) end

            NextRoll = os.time() + Config.Market.Interval * 60
        end
    end)
end

AddEventHandler('onResourceStart', function(Resource)
    if Resource ~= GetCurrentResourceName() then return end

    TriggerEvent('heino_kanaltfyr:server:Ready')
end)
