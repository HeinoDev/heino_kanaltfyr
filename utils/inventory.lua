local Inventory = {}

function Inventory.CountItem(Source, Item)
    return exports.ox_inventory:Search(Source, 'count', Item) or 0
end

function Inventory.Exchange(Source, Item, Amount, PayItem, Payout)
    local OxInventory = exports.ox_inventory
    if Inventory.CountItem(Source, Item) < Amount then return false end
    if not OxInventory:CanCarryItem(Source, PayItem, Payout) then return false end
    if not OxInventory:AddItem(Source, PayItem, Payout) then return false end
    if OxInventory:RemoveItem(Source, Item, Amount, nil, nil, false, false) then return true end

    if not OxInventory:RemoveItem(Source, PayItem, Payout, nil, nil, false, false) then
        lib.print.error(('Kanaltfyr: failed to reverse payout %d for player %s'):format(Payout, Source))
    end
    return false
end

return Inventory
