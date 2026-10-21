local Config = lib.load('config')

lib.locale()

local function IsBlockedByState()
    for i = 1, #Config.BlockedStates do
        if LocalPlayer.state[Config.BlockedStates[i]] then return true end
    end

    return false
end

local function Notify(Title, Description, Type)
    lib.notify({ title = Title, description = Description, type = Type })
end

local function OpenTrade(Name)
    if not Name then return end
    if IsBlockedByState() then return end

    local Trader = lib.callback.await('heino_kanaltfyr:server:GetTrader', false, Name)
    if not Trader then return end

    Trader.Name = Name

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
    cb({})
    SetNuiFocus(false, false)
end)

RegisterNUICallback('HaveItem', function(Data, cb)
    local ItemCount = exports.ox_inventory:Search('count', Data.Item)
    if not ItemCount or ItemCount <= 0 then cb({ Success = false }) return end

    cb({ Success = true, Amount = ItemCount })
end)

RegisterNUICallback('GetCounts', function(Data, cb)
    local Counts = {}
    local Items = type(Data.Items) == 'table' and Data.Items or {}

    for i = 1, #Items do
        Counts[Items[i]] = exports.ox_inventory:Search('count', Items[i]) or 0
    end

    cb(Counts)
end)

RegisterNUICallback('SellItem', function(Data, cb)
    local Payout = lib.callback.await('heino_kanaltfyr:server:SellItem', false, Data)

    if Payout then
        Notify(locale('Notify.Success'), locale('Notify.ItemSold', Data.Item.Label, Payout), 'success')
    else
        Notify(locale('Notify.Error'), locale('Notify.SomethingWentWrong'), 'error')
    end

    cb({ Success = Payout ~= false })
end)

local Peds = {}

for Name, Data in pairs(Config.Traders) do
    local Model = joaat(Data.PedModel)

    if Data.Blip then
        local Blip = AddBlipForCoord(Data.Coords.x, Data.Coords.y, Data.Coords.z)
        SetBlipSprite(Blip, Data.Blip.Sprite or 500)
        SetBlipColour(Blip, Data.Blip.Colour or 5)
        SetBlipScale(Blip, Data.Blip.Scale or 0.7)
        SetBlipAsShortRange(Blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(Data.Blip.Label or Data.Target.Label)
        EndTextCommandSetBlipName(Blip)
    end

    lib.points.new({
        coords = Data.Coords.xyz,
        distance = 100,
        onEnter = function()
            if Peds[Name] and DoesEntityExist(Peds[Name]) then return end

            lib.requestModel(Model)

            local Ped = CreatePed(4, Model, Data.Coords.x, Data.Coords.y, Data.Coords.z - 1.0, Data.Coords.w, false, false)
            Peds[Name] = Ped

            FreezeEntityPosition(Ped, true)
            SetEntityInvincible(Ped, true)
            SetBlockingOfNonTemporaryEvents(Ped, true)
            if Data.Scenario then TaskStartScenarioInPlace(Ped, Data.Scenario, 0, true) end

            exports['ox_target']:addLocalEntity(Ped, {
                {
                    name = 'KanaltfyrTrader_' .. Name,
                    label = Data.Target.Label,
                    icon = Data.Target.Icon,
                    distance = 1.5,
                    onSelect = function() OpenTrade(Name) end
                }
            })

            SetModelAsNoLongerNeeded(Model)
        end,
        onExit = function()
            local Ped = Peds[Name]
            if Ped and DoesEntityExist(Ped) then
                exports['ox_target']:removeLocalEntity(Ped, 'KanaltfyrTrader_' .. Name)
                DeleteEntity(Ped)
            end
            Peds[Name] = nil
        end
    })
end

AddEventHandler('onResourceStop', function(Resource)
    if Resource ~= GetCurrentResourceName() then return end

    for _, Ped in pairs(Peds) do
        if DoesEntityExist(Ped) then DeleteEntity(Ped) end
    end
end)
