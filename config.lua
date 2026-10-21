local Config = {}

Config.MoneyItem = 'money'

Config.BlockedStates = { 'HouseRobberyActive' }

Config.ImageUrl = 'nui://ox_inventory/web/images/'

Config.Currency = {
    Symbol = ' kr.',
    Position = 'after',
    Separator = ','
}

Config.MaxSellAmount = 1000

Config.InteractDistance = 5.0

Config.Market = {
    Enabled = true,
    Interval = 30,
    MinMultiplier = 0.85,
    MaxMultiplier = 1.2,
    HotBonus = 0.25
}

Config.Traders = {
    HouseRobbery = {
        PedModel = 'A_M_M_TrampBeac_01',
        Scenario = 'WORLD_HUMAN_SMOKING',
        Coords = vec4(1391.08, -1508.34, 58.43, 30.0),
        Target = {
            Label = 'Snak med kanal-fyren',
            Icon = 'fa-solid fa-sack-dollar',
        },
        Blip = nil,
    },
}

return Config
