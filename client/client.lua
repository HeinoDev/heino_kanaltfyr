local Config = lib.load('config')
local Client = lib.load('utils.client')
local TradeSession = 0

lib.locale(Config.Locale)

local function IsBlockedByState()
    for i = 1, #Config.BlockedStates do
        if LocalPlayer.state[Config.BlockedStates[i]] then return true end
    end

    return false
end

local function OpenTrade(Name)
    if not Name then return end
    if IsBlockedByState() then return end

    local Trader = lib.callback.await('heino_kanaltfyr:server:GetTrader', false, Name)
    if not Trader then return end

    Trader.Name = Name
    TradeSession = TradeSession + 1

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'InitializeConfig',
        data = {
            Config = { ImageUrl = Config.ImageUrl, Currency = Config.Currency },
            Locale = lib.getLocales()
        }
    })
    SendNUIMessage({
        action = 'OpenTrader',
        data = Trader
    })
end

exports('OpenTrade', OpenTrade)

RegisterNUICallback('HideUI', function(_, cb)
    TradeSession = TradeSession + 1
    TriggerServerEvent('heino_kanaltfyr:server:CancelSale')
    SetNuiFocus(false, false)
    cb({})
end)

RegisterNUICallback('HaveItem', function(Data, cb)
    local ItemCount = Client.CountItem(Data.Item)
    if ItemCount <= 0 then cb({ Success = false }) return end

    cb({ Success = true, Amount = math.min(ItemCount, Config.MaxSellAmount) })
end)

RegisterNUICallback('GetCounts', function(Data, cb)
    local Counts = {}
    local Items = type(Data.Items) == 'table' and Data.Items or {}

    for i = 1, #Items do
        Counts[Items[i]] = Client.CountItem(Items[i])
    end

    cb(Counts)
end)

RegisterNUICallback('SellItem', function(Data, cb)
    local Session = TradeSession
    lib.callback('heino_kanaltfyr:server:SellItem', false, function(Payout)
        if Session == TradeSession then
            if Payout then
                Client.Notify(locale('Notify.Success'), locale('Notify.ItemSold', Data.Item.Label, Payout), 'success')
            else
                Client.Notify(locale('Notify.Error'), locale('Notify.SomethingWentWrong'), 'error')
            end
        end
        cb({ Success = Payout ~= false and Payout ~= nil })
    end, Data)
end)

local Peds = {}

local function SetupTrader(Name, Data, Coords, Index)
    local Key = Name .. ":" .. Index
    local Model = joaat(Data.PedModel)

    if Data.Blip then
        local Blip = AddBlipForCoord(Coords.x, Coords.y, Coords.z)
        SetBlipSprite(Blip, Data.Blip.Sprite or 500)
        SetBlipColour(Blip, Data.Blip.Colour or 5)
        SetBlipScale(Blip, Data.Blip.Scale or 0.7)
        SetBlipAsShortRange(Blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(Data.Blip.Label or Data.Target.Label)
        EndTextCommandSetBlipName(Blip)
    end

    lib.points.new({
        coords = Coords.xyz,
        distance = 100,
        onEnter = function()
            if Peds[Key] and DoesEntityExist(Peds[Key]) then return end

            lib.requestModel(Model)

            local Ped = CreatePed(4, Model, Coords.x, Coords.y, Coords.z - 1.0, Coords.w, false, false)
            Peds[Key] = Ped

            FreezeEntityPosition(Ped, true)
            SetEntityInvincible(Ped, true)
            SetBlockingOfNonTemporaryEvents(Ped, true)
            if Data.Scenario then TaskStartScenarioInPlace(Ped, Data.Scenario, 0, true) end

            Client.AddTarget(Ped, {
                {
                    name = 'KanaltfyrTrader_' .. Key,
                    label = Data.Target.Label,
                    icon = Data.Target.Icon,
                    distance = 1.5,
                    onSelect = function() OpenTrade(Name) end
                }
            })

            SetModelAsNoLongerNeeded(Model)
        end,
        onExit = function()
            local Ped = Peds[Key]
            if Ped and DoesEntityExist(Ped) then
                Client.RemoveTarget(Ped, 'KanaltfyrTrader_' .. Key)
                DeleteEntity(Ped)
            end
            Peds[Key] = nil
        end
    })
end

CreateThread(function()
    local Locations = lib.callback.await('heino_kanaltfyr:server:GetLocations', false)

    for Name, Data in pairs(Locations or {}) do
        local CoordsList = Data.Coordinates or { Data.Coords }
        for Index, Coords in ipairs(CoordsList) do SetupTrader(Name, Data, Coords, Index) end
    end
end)

AddEventHandler('onResourceStop', function(Resource)
    if Resource ~= GetCurrentResourceName() then return end

    for _, Ped in pairs(Peds) do
        if DoesEntityExist(Ped) then DeleteEntity(Ped) end
    end
end)
