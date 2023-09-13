DarkRoomVoidPortal = RegisterMod("Dark Room Void Portal", 1)
local mod = DarkRoomVoidPortal



--[[ Constants ]]--
mod.RNG = RNG()
mod.RequiredItemCount = 2
mod.PortalEffectColor = Color(0.3,0.2,0.2, 1, 1,0,0)

mod.PortalType          = Isaac.GetEntityTypeByName("Void Portal Spawner")
mod.PortalVariant       = Isaac.GetEntityVariantByName("Void Portal Spawner")
mod.PortalEffectVariant = Isaac.GetEntityVariantByName("Void Portal Item Effect")



--[[ Load scripts ]]--
local folder = "drvp_scripts."
include(folder .. "utilities")
include(folder .. "portalTracker")
include(folder .. "portal")
include(folder .. "portalSpawner")