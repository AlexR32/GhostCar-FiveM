-- Brain Vars
local CanSpawn = true
local Destroyed = false
local Angry = false

-- Entity Vars
local Christine = nil
local Driver = nil
local FlamesFX = nil
local FlamesSoundId = nil
local Brip = nil

function LoadModel(ModelHash)
    if not IsModelInCdimage(ModelHash) then return end
    RequestModel(ModelHash)
    while not HasModelLoaded(ModelHash) do
        Citizen.Wait(0)
    end
    return ModelHash
end

function GetBearing(A,B)
    --return math.atan2(A[1] - B[1],A[2] - B[2]) * (180 / math.pi) 
    return math.abs(math.fmod((math.atan2(A[1] - B[1],A[2] - B[2]) * (180 / math.pi)), 360) - 180)
end

function SpawnChristine()
    local Player = PlayerPedId()
    local PlayerPosition = GetEntityCoords(Player)
    local PlayerHeading = GetEntityHeading(Player)
    local Success, NodePosition = GetNthClosestVehicleNode(PlayerPosition[1], PlayerPosition[2], PlayerPosition[3], 10, 1, 0, 0)
    if not Christine and not Driver and Success then
        Christine = CreateVehicle(LoadModel("TORNADO5"), NodePosition, GetBearing(NodePosition,PlayerPosition), true, false)
        RequestScriptAudioBank("DLC_TUNER/DLC_Tuner_Phantom_Car", false, -1)
        PlaySoundFromEntity(-1,"Spawn_In_Game",Christine,"DLC_Tuner_Halloween_Phantom_Car_Sounds", false, false)
        TriggerMusicEvent("H21_PC_START_MUSIC")

        NetworkFadeInEntity(Christine, false, true)
        local Health = GetEntityMaxHealth(Christine) * 5
        SetEntityMaxHealth(Christine,Health)
        SetEntityHealth(Christine,Health,0)
        SetVehicleDoorsLocked(Christine, 2)
        SetEntityProofs(Christine, false, true, false, false, false, false, false, false)
        SetVehicleStrong(Christine, true)
        SetVehicleProvidesCover(Christine, false)
        SetVehicleHasStrongAxles(Christine, true)
        SetVehicleExplodesOnHighExplosionDamage(Christine, false)
        SetVehicleCanDeformWheels(Christine, false)
        SetVehicleHasUnbreakableLights(Christine, true)
        SetVehicleDisableTowing(Christine, true)
        SetVehicleCanBeVisiblyDamaged(Christine, false)
        SetVehicleRadioEnabled(Christine, false)

        SetVehicleColours(Christine,32,32)
        SetVehicleExtraColours(Christine,0,156)
        SetVehicleWheelType(Christine, 8)
        SetVehicleRoofLivery(Christine, 0)
        SetVehicleMod(Christine, 23, 94, false)
        SetVehicleMod(Christine, 10, -1, false)
        SetVehicleWindowTint(Christine, 3)
        SetVehicleHeadlightsColour(Christine, 8)
        SetVehicleNumberPlateTextIndex(Christine, 1)
        SetVehicleNumberPlateText(Christine, "EAB__211")

        Driver = CreatePedInsideVehicle(Christine, 26, LoadModel("S_M_Y_ROBBER_01"), -1, true, false)
        Citizen.Wait(500)
        SetEntityVisible(Driver, false)
        SetEntityInvincible(Driver, true)
        SetBlockingOfNonTemporaryEvents(Driver, true)

        Blip = AddBlipForEntity(Christine)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName("Christine")
        EndTextCommandSetBlipName(Blip)

        Angry = IsPedSittingInAnyVehicle(Player)
        SetModelAsNoLongerNeeded("TORNADO5")
        SetModelAsNoLongerNeeded("S_M_Y_ROBBER_01")
    end
end

function DespawnChristine()
    if Christine and Driver and Blip then
        NetworkFadeOutEntity(Christine,false,true)
        PlaySoundFromEntity(-1,"Despawn_In_Game",Christine,"DLC_Tuner_Halloween_Phantom_Car_Sounds", false, false)
        TriggerMusicEvent("H21_PC_STOP_MUSIC")
        Citizen.Wait(1000)
        RemoveBlip(Blip)
        DeleteEntity(Driver)
        DeleteEntity(Christine)
        Christine = nil
        Driver = nil
        Blip = nil
    end
end

AddEventHandler("gameEventTriggered", function(Name, Args)
    if Name == "CEventNetworkEntityDamage" and Driver then
        if Args[2] == Driver and Angry then
            if Args[6] == true then
                StopEntityFire(PlayerPedId())
            end
            if not IsEntityOnFire(PlayerPedId()) then
                StartEntityFire(PlayerPedId())
            end
        end
    end
end)

RegisterNetEvent("PC:SpawnClient")
AddEventHandler("PC:SpawnClient", function()
    SpawnChristine()
end)

RegisterNetEvent("PC:DespawnClient")
AddEventHandler("PC:DespawnClient", function()
    DespawnChristine()
end)


Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if not HasNamedPtfxAssetLoaded("scr_tn_phantom") then
            RequestNamedPtfxAsset("scr_tn_phantom")
        end
        if Christine and Driver then
            local Player = PlayerPedId()
            if GetVehicleEngineHealth(Christine) <= 0 and not Destroyed then
                Destroyed = true
                TriggerServerEvent("PC:DespawnServer")
            end
            if IsEntityDead(Player) and not Destroyed then
                Destroyed = true
                TriggerServerEvent("PC:DespawnServer")
            end

            if not IsPedSittingInAnyVehicle(Player) and not Angry then
                Angry = true
                ToggleVehicleMod(Christine, 22, true)
                TaskVehicleFollow(Driver, Christine, Player, 30.0, 262656, 0)
                
                UseParticleFxAsset("scr_tn_phantom")
                FlamesFX = StartParticleFxLoopedOnEntity("scr_tn_phantom_flames", Christine, 0.0, 0.0, 0.0, 0.0, 0.0, 180.0, 1.0, false, true, false)
                FlamesSoundId = GetSoundId()
                PlaySoundFromEntity(FlamesSoundId,"Flames_Loop",Christine,"DLC_Tuner_Halloween_Phantom_Car_Sounds", false, false)
                PlaySoundFrontend(-1,"Spawn_FE","DLC_Tuner_Halloween_Phantom_Car_Sounds", true)
            elseif IsPedSittingInAnyVehicle(Player) and Angry then
                Angry = false
                ToggleVehicleMod(Christine, 22, false)
                TaskVehicleFollow(Driver, Christine, Player, 30.0, 786469, 20)

                StopSound(FlamesSoundId)
                ReleaseSoundId(FlamesSoundId)
                StopParticleFxLooped(FlamesFX,true)
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(2000)
        if GetTimeDifference(GetClockHours(),21) == 0 and CanSpawn then
            CanSpawn = false
            Destroyed = false
            TriggerServerEvent("PC:SpawnServer")
        end
        if GetTimeDifference(GetClockHours(),5) == 0 then
            if not CanSpawn and not Destroyed then
                CanSpawn = true
                TriggerServerEvent("PC:DespawnServer")
            else
                CanSpawn = true
            end
        end
    end
end)
