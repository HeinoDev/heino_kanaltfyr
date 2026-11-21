local Client = {}

function Client.CountItem(Item)
    return exports.ox_inventory:Search('count', Item) or 0
end

function Client.AddTarget(Entity, Options)
    exports.ox_target:addLocalEntity(Entity, Options)
end

function Client.RemoveTarget(Entity, Name)
    exports.ox_target:removeLocalEntity(Entity, Name)
end

function Client.Notify(Title, Description, Type)
    lib.notify({ title = Title, description = Description, type = Type })
end

return Client
