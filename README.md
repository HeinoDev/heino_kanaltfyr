# heino_kanaltfyr

Fence NPC for FiveM. Sell items to a trader at market prices that change over time.

- Requires `ox_lib`, `ox_inventory`, `ox_target`
- Pays out as an `ox_inventory` item. `Config.MoneyItem` sets the cash item name
- Prices re-roll on an interval, one "in demand" item per trader
- Server validates distance, amount, item and price
- Locales: `da`, `en`
- Closing the trader cancels an in-progress sale
- Optional Discord webhook in `utils/logs.lua`

## Install

1. Drop the folder in your resources
2. Start it after `ox_lib`, `ox_inventory` and `ox_target`
3. `ensure heino_kanaltfyr`

## Configure stock

Edit `server/stock.lua` to set what each trader buys. The default trader buys phones and radios. Another resource can override a trader with `RegisterTrader`.

```lua
AddEventHandler('heino_kanaltfyr:server:Ready', function()
    exports['heino_kanaltfyr']:RegisterTrader('HouseRobbery', {
        Label = 'Kanal-fyren',
        Currency = { Value = 'cash' },
        Items = {
            { Item = 'phone', Label = 'Phone', Price = 100, Time = 400 },
        },
    })
end)
```

`Currency.Value` is the payout item. Use `'cash'` to pay out `Config.MoneyItem`. `Time` sets the sale duration per unit in milliseconds. Market settings and the locale are in `config.lua`. Configure one or more NPC positions per trader with `Coordinates` in `server/traders.lua`.

Set `Config.BlockedStates` to player state keys that should prevent trading while active.

## Integrations

- `utils/client.lua` connects item counts, targeting, and notifications.
- `utils/inventory.lua` handles the server-side item exchange.
- `utils/logs.lua` handles Discord sale logging. Set `Webhook` there to enable it.

## Exports

- server `RegisterTrader(name, data)`, `GetTraders()`, `GetTrader(name)`
- client `OpenTrade(name)`

## Build UI

```
cd web
bun install
bun run build
```
