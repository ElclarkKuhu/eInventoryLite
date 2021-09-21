local data = {}

function loadData(identifier) 
    MySQL.Async.fetchAll('SELECT * FROM eInventoryLite WHERE identifier = @identifier', { ['@identifier'] = identifier }, function(result)
        data[identifier] = {}
        for key, value in pairs(result) do
            table.insert(data[identifier], value)
        end
    end)
end

function syncData(xPlayer) 
    local identifier = xPlayer.getIdentifier()
    local items = xPlayer.getInventory()
    local weapons = xPlayer.getLoadout()

    if data[identifier] ~= nil then
        for key, value in pairs(data[identifier]) do 
            if value.type == 'item_weapon' then
                local count = getCount(weapons, value.name)
                if count == 0 then
                    data[identifier][key] = nil
                
                    MySQL.Async.execute('DELETE FROM eInventoryLite WHERE identifier = @identifier AND name = @name',{['identifier'] = identifier, ['name'] = value.name})
                end
            end
        end

        for key, value in pairs(weapons) do
            local count = getCount(data[identifier], value.name)
            if count == 0 then
                value.type = 'item_weapon'
                addData(identifier, value)
            end
        end

        for key, value in pairs(items) do
            local count = getCount(data[identifier], value.name)
            if count ~= value.count then 
                value.type = 'item_standard'
                if count > value.count then
                    for i = count - value.count, 1, -1 do 
                        deleteData(identifier, value.name)
                    end
                elseif count < value.count then
                    for i = value.count - count , 1, -1 do
                        addData(identifier, value)
                    end
                end
            end
        end
    end
end

function addData(identifier,  value)
    local id = value.name .. '-' .. math.random(1000, 9999) .. math.random(1000, 9999)
    local slot = getFreeSlot(identifier, value.name)

    table.insert(data[identifier], {
        id = id,
        name = value.name, 
        slot = slot,
        type = value.type,
    })

    MySQL.Async.execute('INSERT INTO eInventoryLite (id, identifier, name, slot, type) VALUES (@id, @identifier, @name, @slot, @type)', { ['id'] = id, ['identifier'] = identifier, ['name'] = value.name, ['slot'] = slot, ['type'] = value.type})
end

function deleteData(identifier, name)
    for key, value in pairs(data[identifier]) do
        if name == value.name then
            data[identifier][key] = nil
            break
        end
    end

    MySQL.Async.execute('DELETE FROM eInventoryLite WHERE identifier = @identifier AND name = @name LIMIT 1',{['identifier'] = identifier, ['name'] = name})
end

function getFreeSlot(identifier, name)
    for i = 1, 25, 1 do
        local found, slot = false, 'it' .. i .. '-c'
        for key, value in pairs(data[identifier]) do
            if value.slot == slot then
                if value.name == name then
                    return slot
                else
                    found = true
                    break
                end
            end
        end
        if not found then
            return slot
        end
    end
end

function getCount(d, name) 
    local count = 0
    for key, value in pairs(d) do
        if value.name == name then
            count = count + 1
        end
    end
    return count
end

RegisterNetEvent('eInventoryLite:LoadPlayerData', function()
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = xPlayer.getIdentifier()
    loadData(identifier)
end)

RegisterNetEvent('eInventoryLite:getInventory', function()
    local res = {}
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = xPlayer.getIdentifier()
    
    syncData(xPlayer)

    if data[identifier] ~= nil then
        for key, value in pairs(data[identifier]) do
            if value.type == 'item_standard' then
                local item = xPlayer.getInventoryItem(value.name)
                table.insert(res, {
                    id = value.id,
                    name = value.name,
                    label = item.label,
                    type = value.type,
                    slot = value.slot,
                    usable = item.usable,
                    canRemove = item.canRemove
                })
            elseif value.type == 'item_weapon' then
                local loadoutNum, weapon = xPlayer.getWeapon(value.name)
                if weapon then
                    table.insert(res, {
                        id = value.id,
                        name = value.name,
                        label = weapon.label,
                        type = value.type,
                        slot = value.slot,
                        usable = false,
                        canRemove = true
                    })
                end
            end
        end
    else
        loadData(identifier)
    end
    TriggerClientEvent('eInventoryLite:inventoryList', source, res)
end)

RegisterNetEvent('eInventoryLite:useItem', function(item)
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = xPlayer.getIdentifier()

    for key, value in pairs(data[identifier]) do
        if item.id == value.id then
            ESX.UseItem(source, value.name)
            MySQL.Async.execute('DELETE FROM eInventoryLite WHERE identifier = @identifier AND id = @id LIMIT 1',{['identifier'] = identifier, ['id'] = item.id})
            data[identifier][key] = nil
        end
    end
end)

RegisterNetEvent('eInventoryLite:dropItem', function(item)
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = xPlayer.getIdentifier()

    for key, value in pairs(data[identifier]) do
        if item.id == value.id then
            if value.type == 'item_standard' then
                local InventoryItem = xPlayer.getInventoryItem(value.name)
                local count = 1
                if item.all then
                    count = 0
                    for k, v in pairs(data[identifier]) do
                        if v.name == value.name and v.slot == value.slot then
                            count = count + 1
                        end
                    end
                end
                ESX.CreatePickup(value.type, InventoryItem.name, count, InventoryItem.label, source)
                xPlayer.removeInventoryItem(value.name, count)
            else
                local loadoutNum, weapon = xPlayer.getWeapon(value.name)
                if weapon then
                    ESX.CreatePickup(value.type, value.name, weapon.ammo, weapon.label, source, weapon.components, weapon.tintIndex)
                    xPlayer.removeWeapon(value.name)
                end
            end

            data[identifier][key] = nil
            MySQL.Async.execute('DELETE FROM eInventoryLite WHERE identifier = @identifier AND id = @id LIMIT 1',{['identifier'] = identifier, ['id'] = value.id})
        end
    end
end)

RegisterNetEvent('eInventoryLite:moveSlot', function(item)
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = xPlayer.getIdentifier()

    if item.mode == 'move' then
        if item.all then 
            for key, value in pairs(data[identifier]) do
                if item.name == value.name and item.slotFrom == value.slot then
                    data[identifier][key].slot = item.slotTo
                end
            end
        
            MySQL.Async.execute('UPDATE eInventoryLite SET slot = @slotTo WHERE identifier = @identifier AND name = @name AND slot = @slotFrom',{['identifier'] = identifier, ['id'] = item.id, ['slotTo'] = item.slotTo, ['slotFrom'] = item.slotFrom })
        else
            for key, value in pairs(data[identifier]) do
                if item.id == value.id then
                    data[identifier][key].slot = item.slotTo
                end
            end
        
            MySQL.Async.execute('UPDATE eInventoryLite SET slot = @slot WHERE identifier = @identifier AND id = @id',{['identifier'] = identifier, ['id'] = item.id, ['slot'] = item.slotTo })
        end
    elseif item.mode == 'trade' then
        for key, value in pairs(data[identifier]) do
            if item.nameFrom == value.name and item.slotFrom == value.slot then
                data[identifier][key].slot = item.slotTo
            end
            if item.nameTo == value.name and item.slotTo == value.slot then
                data[identifier][key].slot = item.slotFrom
            end
        end
    
        MySQL.Async.transaction({
            'UPDATE eInventoryLite SET slot = @slotFrom WHERE identifier = @identifier AND name = @nameTo AND slot = @slotTo',
            'UPDATE eInventoryLite SET slot = @slotTo WHERE identifier = @identifier AND name = @nameFrom AND slot = @slotFrom'
        }, { ['identifier'] = identifier, ['nameFrom'] = item.nameFrom, ['nameTo'] = item.nameTo, ['slotFrom'] = item.slotFrom, ['slotTo'] = item.slotTo  })
    end
end)