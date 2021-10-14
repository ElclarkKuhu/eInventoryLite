local data = {}
local insertData = -1

function loadData(source, identifier, items, weapons)
    MySQL.Async.store("INSERT INTO eInventoryLite SET ?", function(storeId) insertData = storeId end)
    
    MySQL.Async.fetchAll('SELECT * FROM eInventoryLite WHERE identifier = @identifier', { ['@identifier'] = identifier }, function(result)
        data[identifier] = {}
        
        for key, value in pairs(result) do
            table.insert(data[identifier], value)
        end

        syncData(source, identifier, items, weapons)
    end)
end

function syncData(source, identifier, items, weapons)
    if configs.includeWeapons and weapons ~= nil then
        for key, value in pairs(data[identifier]) do 
            if value.type == 'item_weapon' then
                local count = getCount(weapons, value.name)
                if count == 0 then
                    deleteData(identifier, value.name)
                end
            end
        end
    
        for key, value in pairs(weapons) do
            local count = getCount(data[identifier], value.name)
            if count == 0 then
                addData(identifier, value.name, 'item_weapon')
            end
        end
    end

    for key, value in pairs(items) do
        local count = getCount(data[identifier], value.name)
        if count ~= value.count then 
            if count > value.count then
                deleteData(identifier, value.name, nil, nil, nil, count - value.count)
            elseif count < value.count then
                addData(identifier, value.name, 'item_standard', nil, value.count - count)
            end
        end
    end

    sendInventory(source)
end

function addData(identifier, name, type, slot, count)
    if count == nil then count = 1 end
    if slot == nil then slot = getFreeSlot(identifier, name) end

    for i = count, 1, -1 do
        local id = name .. '-' .. math.random(1000, 9999) .. math.random(1000, 9999)

        table.insert(data[identifier], {
            id = id,
            name = name, 
            slot = slot,
            type = type
        })

        MySQL.Async.insert(insertData, {{
            ['id'] = id,
            ['identifier'] = identifier,
            ['name'] = name,
            ['slot'] = slot,
            ['type'] = type
        }})          

    end
end

function deleteData(identifier, name, type, slot, id, count)
    local counting = 0

    if count ~= nil then
        for key, value in pairs(data[identifier]) do
            if name == value.name then
                if count > counting then
                    data[identifier][key] = nil
                    counting = counting + 1
                else
                    break
                end
            end
        end
    
        MySQL.Async.execute('DELETE FROM eInventoryLite WHERE identifier = @identifier AND name = @name LIMIT @limit',{
            ['identifier'] = identifier,
            ['name'] = name,
            ['limit'] = count
        })

        return counting
    end

    if id ~= nil then
        for key, value in pairs(data[identifier]) do
            if id == value.id then
                data[identifier][key] = nil
                counting = counting + 1
            end
        end
    
        MySQL.Async.execute('DELETE FROM eInventoryLite WHERE identifier = @identifier AND id = @id',{
            ['identifier'] = identifier,
            ['id'] = id
        })
        
        return counting
    end

    if slot ~= nil then
        for key, value in pairs(data[identifier]) do
            if slot == value.slot then
                data[identifier][key] = nil
                counting = counting + 1
            end
        end
    
        MySQL.Async.execute('DELETE FROM eInventoryLite WHERE identifier = @identifier AND slot = @slot',{
            ['identifier'] = identifier,
            ['slot'] = slot
        })

        return counting
    end

    for key, value in pairs(data[identifier]) do
        if name == value.name then
            data[identifier][key] = nil
            counting = counting + 1
        end
    end

    MySQL.Async.execute('DELETE FROM eInventoryLite WHERE identifier = @identifier AND name = @name',{
        ['identifier'] = identifier,
        ['name'] = name
    })

    return counting
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

function getCount(sourceData, name, slot) 
    local count = 0
    
    if sourceData == nil then
        return 0 
    end

    for key, value in pairs(sourceData) do
        if slot ~= nil then
            if value.name == name and value.slot == slot then
                count = count + 1
            end
        else
            if value.name == name then
                count = count + 1
            end
        end
    end

    return count
end

function getMoreData(xPlayer, type, id, name, slot)
    if type == 'item_standard' then
        local item = xPlayer.getInventoryItem(name)
        return {
            id = id,
            name = name,
            label = item.label,
            type = type,
            slot = slot,
            weight = item.weight,
            usable = item.usable,
            canRemove = item.canRemove
        }
    elseif type == 'item_weapon' then
        return {
            id = id,
            name = name,
            label = ESX.GetWeaponLabel(name),
            type = type,
            slot = slot,
            weight = 0,
            usable = false,
            canRemove = true
        }
    end
end

function sendInventory(source)
    local response = {}

    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = xPlayer.getIdentifier()

    local items = xPlayer.getInventory()
    local weapons = xPlayer.getLoadout()

    if data[identifier] ~= nil then
        for key, value in pairs(data[identifier]) do
            table.insert(response, getMoreData(xPlayer, value.type, value.id, value.name, value.slot))
        end
    else
        loadData(source, identifier, items, weapons)
    end

    TriggerClientEvent('eInventoryLite:inventoryList', source, response, {type = 0, weight = xPlayer.getWeight(), maxWeight = ESX.GetConfig().MaxWeight})
end

function useItem(xPlayer, source, name, id) 
    local items = xPlayer.getInventory()
    local identifier = xPlayer.getIdentifier()

    for key, value in pairs(items) do
        if value.name == name then 
            if value.count > 0 then
                ESX.UseItem(source, value.name)
                deleteData(identifier, nil, nil, nil, id)
            else
                xPlayer.showNotification('NICE TRY!', true, false, 130)
            end
        end
    end
end

RegisterNetEvent('eInventoryLite:LoadPlayerData', function()
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = xPlayer.getIdentifier()

    local items = xPlayer.getInventory()
    local weapons = xPlayer.getLoadout()

    loadData(source, identifier, items, weapons)
end)

RegisterNetEvent('eInventoryLite:getInventory', function()
    sendInventory(source)
end)

RegisterNetEvent('eInventoryLite:addData', function(name, type, count, slot)
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = xPlayer.getIdentifier()

    local currentCount = getCount(data[identifier], name)
    
    addData(identifier, name, type, slot, count - currentCount)

    sendInventory(source)
end)

RegisterNetEvent('eInventoryLite:deleteData', function(name, type, count)
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = xPlayer.getIdentifier()

    local currentCount = getCount(data[identifier], name)
    
    print(currentCount - count)
    deleteData(identifier, name, type, nil, nil, currentCount - count)

    sendInventory(source)
end)

RegisterNetEvent('eInventoryLite:useItem', function(item)
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = xPlayer.getIdentifier()

    if item.slot ~= nil then
        for key, value in pairs(data[identifier]) do
            if value.slot == item.slot then 
                useItem(xPlayer, source, value.name, value.id)
                break
            end
        end
    else
        useItem(xPlayer, source, item.name, item.id)
    end
end)

RegisterNetEvent('eInventoryLite:dropItem', function(item)
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = xPlayer.getIdentifier()

    for key, value in pairs(data[identifier]) do
        if item.id == value.id then
            if value.type == 'item_standard' then
                local count = 0
                local inventoryItem = xPlayer.getInventoryItem(value.name)

                if item.all then
                    count = deleteData(identifier, nil, nil, item.slot)
                else
                    count = deleteData(identifier, nil, nil, nil, item.id)
                end

                if count <= inventoryItem.count then
                    ESX.CreatePickup(value.type, inventoryItem.name, count, inventoryItem.label, source)
                    xPlayer.removeInventoryItem(inventoryItem.name, count)
                else
                    xPlayer.showNotification('NICE TRY!', true, false, 130)
                end
            else
                local loadoutNum, weapon = xPlayer.getWeapon(value.name)
                if weapon then
                    deleteData(identifier, nil, nil, nil, item.id)

                    ESX.CreatePickup(value.type, weapon.name, weapon.ammo, weapon.label, source, weapon.components, weapon.tintIndex)
                    xPlayer.removeWeapon(weapon.name)
                else
                    xPlayer.showNotification('NICE TRY!', true, false, 130)
                end
            end
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

            MySQL.Async.execute('UPDATE eInventoryLite SET slot = @slotTo WHERE identifier = @identifier AND name = @name AND slot = @slotFrom', {
                ['identifier'] = identifier,
                ['name'] = item.name,
                ['slotTo'] = item.slotTo,
                ['slotFrom'] = item.slotFrom
            })
        else
            for key, value in pairs(data[identifier]) do
                if item.id == value.id then
                    data[identifier][key].slot = item.slotTo
                end
            end
        
            MySQL.Async.execute('UPDATE eInventoryLite SET slot = @slot WHERE identifier = @identifier AND id = @id', {
                ['identifier'] = identifier,
                ['id'] = item.id,
                ['slot'] = item.slotTo 
            })
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
        }, { 
            ['identifier'] = identifier,
            ['nameFrom'] = item.nameFrom,
            ['nameTo'] = item.nameTo,
            ['slotFrom'] = item.slotFrom,
            ['slotTo'] = item.slotTo
        })
    end
end)