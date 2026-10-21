# heino_kanaltfyr

A small fence NPC for FiveM. Players walk up to a trader, open a clean card-based UI and sell items for cash or for another item. Prices drift over time, one item per trader is "in demand" for a bonus, and the server owns every price and payout.

## Features

- Standalone: needs only `ox_lib`, `ox_inventory` and `ox_target`
- Money works on ESX, QBCore, Qbox, or falls back to an `ox_inventory` item
- Live market: prices re-roll on an interval inside a configurable range, with a rotating "in demand" bonus item
- Trend arrows, owned counts, total value, an "only what I have" filter and a countdown to the next price change
- Server-side validation of distance, amount, item and price. The UI is display only
- Opening and closing animations that respect `prefers-reduced-motion`
- Locales: Danish (`da`) and English (`en`), picked up from the `ox:locale` convar
- Optional Discord webhook logging in `server/logs.lua`

## Install

1. Put `heino_kanaltfyr` in your resources folder
2. Make sure `ox_lib`, `ox_inventory` and `ox_target` start before it
3. `ensure heino_kanaltfyr`

The built UI is committed in `web/build`, so nothing needs compiling to run it.

## Configuration

Everything lives in `config.lua`.

| Option | Description |
| --- | --- |
| `Framework` | `'auto'`, `'esx'`, `'qb'`, `'qbx'` or `'ox'` |
| `BlockedStates` | Player state bags that block trading while `true` |
| `ImageUrl` | Where item images are loaded from |
| `Currency` | Symbol, position and separator used by the UI |
| `MaxSellAmount` | Largest amount accepted in one sale |
| `InteractDistance` | How close the player must be, checked on the server |
| `Market` | `Enabled`, `Interval` (minutes), `MinMultiplier`, `MaxMultiplier`, `HotBonus` |
| `Traders` | Ped model, scenario, coords, target label and optional blip |

## Registering a trader's stock

Traders in `Config.Traders` define where the ped stands. What they buy is registered from any server script:

```lua
AddEventHandler('heino_kanaltfyr:server:Ready', function()
    exports['heino_kanaltfyr']:RegisterTrader('HouseRobbery', {
        Label = 'Kanal-fyren',
        Currency = { Type = 'Money', Value = 'cash' },
        Items = {
            { Item = 'goldchain', Label = 'Gold chain', Price = 450, Time = 400 },
            { Item = 'laptop', Label = 'Laptop', Price = 900, Time = 600 },
        },
    })
end)
```

- `Currency.Type = 'Item'` pays out the item named in `Value`, anything else pays that account
- `Price` is the base price, the market multiplier is applied on top
- `Time` is the sell time per unit in milliseconds, shown as the progress bar

## Exports

| Side | Export | Description |
| --- | --- | --- |
| server | `RegisterTrader(name, data)` | Register or overwrite a trader's stock |
| server | `GetTraders()` / `GetTrader(name)` | Read the registered traders |
| client | `OpenTrade(name)` | Open a trader's UI |

The server also triggers `heino_kanaltfyr:server:Ready` on start so other resources can register again after a restart.

## Webhook

Set the `Webhook` local at the top of `server/logs.lua`. An empty string disables logging.

## Building the UI

```
cd web
npm install
npm run build
```

`npm run check` runs `svelte-check` and TypeScript.

## License

MIT
