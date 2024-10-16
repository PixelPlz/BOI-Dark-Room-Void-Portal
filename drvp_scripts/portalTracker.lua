local mod = DarkRoomVoidPortal
local json = require("json")



-- Create portal tracker
function mod.ResetPortalTracker()
    mod.PortalTracker = {
        RoomIndex  = nil,
        GridIndex  = nil,
        GivenItems = nil,
    }
end
mod.ResetPortalTracker()



-- Load portal tracker when continuing a run / reset it when starting a new one
function mod:LoadPortalTracker(isContinue)
    if not isContinue then
        mod.ResetPortalTracker()

    elseif mod:HasData() then
		mod.PortalTracker = json.decode(mod:LoadData())
    end
end
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mod.LoadPortalTracker)

-- Save portal tracker
function mod:SavePortalTracker()
	mod:SaveData(json.encode(mod.PortalTracker))
end
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, mod.SavePortalTracker)



-- Reset the portal tracker when entering a new floor
function mod:ClearPortalTracker()
	mod.ResetPortalTracker()
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, mod.ClearPortalTracker)