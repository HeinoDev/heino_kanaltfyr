local Config = {}

Config.Locale = 'en'

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

return Config
