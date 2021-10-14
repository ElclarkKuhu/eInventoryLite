local display = false

-- When player connected Load Player data and cache it on server
RegisterNetEvent('esx:playerLoaded', function(playerData)
    TriggerServerEvent('eInventoryLite:LoadPlayerData')
end)

RegisterKeyMapping("-openInventory", "Open Inventory", "keyboard", "F2")
RegisterCommand('-openInventory', function()
    TriggerServerEvent('eInventoryLite:getInventory')
    TriggerEvent('eInventory:openInventory') -- For Add-On
    
    SendNUIMessage({
        action = 'display',
        is = true,
        showLoading = true
    })

    SetNuiFocus(true, true)
    display = true
end, false)

RegisterNetEvent('eInventoryLite:inventoryList', function(data, weights)
    SendNUIMessage({
        action = 'clearItem',
    })
    
    SendNUIMessage({
        action = 'addItem',
        type = 0,
        weights = weights,
        data = data, 
    })
end)

RegisterCommand('closeInventory', function()
    closeNUI()
end, false)

RegisterNetEvent('esx:addInventoryItem', function(item, count, showNotification)
    if tostring(count) ~= 'false' then
        TriggerServerEvent('eInventoryLite:addData', item, 'item_standard', count)
    end
end)

RegisterNetEvent('esx:removeInventoryItem', function(item, count, showNotification)
    if tostring(count) ~= 'false' then
        TriggerServerEvent('eInventoryLite:deleteData', item, 'item_standard', count)
    end
end)

if configs.includeWeapons then
    RegisterNetEvent('esx:addWeapon', function(weapon)
        TriggerServerEvent('eInventoryLite:addData', weapon, 'item_weapon', 1)
    end)
    
    RegisterNetEvent('esx:removeWeapon', function(weapon)
        TriggerServerEvent('eInventoryLite:deleteData', weapon, 'item_weapon', 0)
    end)
end

RegisterNUICallback('getConfig', function(data, cb)
    cb(configs)
end)

RegisterNUICallback('useItem', function(data, cb)
    TriggerServerEvent('eInventoryLite:useItem', data)
end)

RegisterNUICallback('moveSlot', function(data, cb)
    TriggerServerEvent('eInventoryLite:moveSlot', data)
end)

RegisterNUICallback('dropItem', function(data, cb)
    TriggerServerEvent('eInventoryLite:dropItem', data)
end)

RegisterNUICallback('close', function(data, cb)
    SetNuiFocus(false, false)
    display = false
end)

function closeNUI()
    SendNUIMessage({
        action = 'clearItem',
    })

    SendNUIMessage({
        action = 'display',
        is = false
    })
    SetNuiFocus(false, false)
    display = false
end