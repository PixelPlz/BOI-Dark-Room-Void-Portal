local mod = DarkRoomVoidPortal



function mod:TrySpawnPortal(roomIndex)
    if mod.PortalTracker.RoomIndex ~= nil and roomIndex == mod.PortalTracker.RoomIndex then
        local room = Game():GetRoom()
        local gridEntity = room:GetGridEntity(mod.PortalTracker.GridIndex)

        -- Change the animation of the Void trapdoor if it already spawned
        if gridEntity ~= nil and gridEntity:GetType() == GridEntityType.GRID_TRAPDOOR then
            gridEntity:GetSprite():Load("gfx/voidportal.anm2", true)

        -- Spawn the portal with the saved data
        else
            local spawnPos = room:GetGridPosition(mod.PortalTracker.GridIndex)
            Isaac.Spawn(mod.PortalType, mod.PortalVariant, 0, spawnPos, Vector.Zero, nil):ToNPC()
        end
    end
end



function mod:CheckForPortalSpawnRoom()
    local level = Game():GetLevel()
    local room = Game():GetRoom()

    local roomIndex = level:GetCurrentRoomIndex()
    local roomDesc = level:GetRoomByIdx(roomIndex)
    local roomID = roomDesc.Data.Variant


    -- Check if the current room is the grave room and set it as the portal room if it is
    if room:IsFirstVisit() -- Only check when first entering
    and level:GetAbsoluteStage() == LevelStage.STAGE6 and level:GetStageType() == StageType.STAGETYPE_ORIGINAL -- Currently in the Dark Room
    and room:GetRoomConfigStage() == 0 -- Room is from the special rooms stb
    and room:GetType() == RoomType.ROOM_DEFAULT -- Grave rooms count as normal rooms
    and roomID >= 3 and roomID <= 9 then -- One of several hardcoded IDs (Vinh... why did you hardcode them instead of using a subtype or a new room type...)

        local portalGridIndexes = { -- If Vinh can hardcode room IDs then I can hardcode spawn positions for each room layout
            {65, 69},
            67,
            52,
            67,
            52,
            {32, 42, 92, 102},
            {65, 69},
        }

        -- Get the spawn grid index
        local spawnGrid = portalGridIndexes[roomID - 2]
        if type(spawnGrid) == "table" then
            spawnGrid = spawnGrid[mod:Random(1, #spawnGrid)]
        end

        mod.PortalTracker.RoomIndex  = roomIndex
        mod.PortalTracker.GridIndex  = spawnGrid
        mod.PortalTracker.GivenItems = 0
    end


    -- Spawn the portal if it's the portal room
    mod:TrySpawnPortal(roomIndex)
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.CheckForPortalSpawnRoom)



-- When you re-enter the run in the portal room after restarting the game (MC_POST_NEW_ROOM is triggered before the data can be loaded)
function mod:CheckForLateSpawn(isContinue)
    if isContinue == true then
        local roomIndex = Game():GetLevel():GetCurrentRoomIndex()
        mod:TrySpawnPortal(roomIndex)
    end
end
mod:AddPriorityCallback(ModCallbacks.MC_POST_GAME_STARTED, CallbackPriority.LATE, mod.CheckForLateSpawn)