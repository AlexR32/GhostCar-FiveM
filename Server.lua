RegisterNetEvent("PC:SpawnServer")
AddEventHandler("PC:SpawnServer", function()
    --print("Spawning Christine for players")
    TriggerClientEvent("PC:SpawnClient", -1)
end)
