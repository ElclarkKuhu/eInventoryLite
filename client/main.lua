local display = false

RegisterCommand('OpenInventory', function()
    TriggerServerEvent('eInventoryLite:getInventory')
    SendNUIMessage({
        action = 'display',
        is = true
    })
    SetNuiFocus(true, true)
    display = true
end, false)

RegisterKeyMapping("OpenInventory", "Open Inventory", "keyboard", "F2")

RegisterCommand('CloseInventory', function()
    closeNUI()
end, false)

RegisterNetEvent('esx:playerLoaded', function(playerData)
    TriggerServerEvent('eInventoryLite:LoadPlayerData')
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

RegisterNetEvent('eInventoryLite:inventoryList', function(data)
    SendNUIMessage({
        action = 'clearItem',
    })
    SendNUIMessage({
        action = 'addItem',
        data = data, 
    })
end)

function closeNUI()
    SendNUIMessage({
        action = 'display',
        is = false
    })
    SetNuiFocus(false, false)
    display = false
end