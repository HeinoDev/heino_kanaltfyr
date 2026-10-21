# heino_kanaltfyr

Fence NPC for FiveM. Sell items to a trader at market prices that change over time.

- Requires `ox_lib`, `ox_inventory`, `ox_target`
- Pays out as an `ox_inventory` item. `Config.MoneyItem` sets the cash item name
- Prices re-roll on an interval, one "in demand" item per trader
- Server validates distance, amount, item and price
- Locales: `da`, `en`
- Optional Discord webhook in `server/logs.lua`

## Install

1. Drop the folder in your resources
2. Start it after `ox_lib`, `ox_inventory` and `ox_target`
3. `ensure heino_kanaltfyr`

## Register stock

```lua
AddEventHandler('heino_kanaltfyr:server:Ready', function()
    exports['heino_kanaltfyr']:RegisterTrader('HouseRobbery', {
        Label = 'Kanal-fyren',
        Currency = { Value = 'cash' },
        Items = {
            { Item = 'goldchain', Label = 'Gold chain', Price = 450, Time = 400 },
        },
    })
end)
```

`Currency.Value` is the item paid out, `'cash'` uses `Config.MoneyItem`. `Time` is ms per unit. Trader positions and market settings are in `config.lua`.

## Exports

- server `RegisterTrader(name, data)`, `GetTraders()`, `GetTrader(name)`
- client `OpenTrade(name)`

## Build UI

```
cd web
bun install
bun run build
```
