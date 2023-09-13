local mod = DarkRoomVoidPortal



-- Create a list of all items the player has
function mod:GetRandomPlayerItem(player)
    local maxID = Isaac.GetItemConfig():GetCollectibles().Size - 1
    local playerItems = {}

    -- Go through all valid items
    for id = 1, maxID do
        if ItemConfig.Config.IsValidCollectible(id) then
            local itemConfig = Isaac.GetItemConfig():GetCollectible(id)
            local itemType = itemConfig.Type

            if itemType == ItemType.ITEM_PASSIVE or itemType == ItemType.ITEM_FAMILIAR -- Only check for passive items
            and not itemConfig:HasTags(ItemConfig.TAG_QUEST) then -- Don't include quest items
                local itemCount = player:GetCollectibleNum(id, true)

                -- If the player has at least one of the item
                if itemCount > 0 then
                    for j = 1, itemCount do
                        table.insert(playerItems, id)
                    end
                end
            end
        end
    end

    -- Choose a random item
    if #playerItems > 0 then
        return mod:RandomIndex(playerItems)
    else
        return false
    end
end



-- Portal AI
function mod:portalInit(entity)
	if entity.Variant == mod.PortalVariant then
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYERONLY
		entity:AddEntityFlags(EntityFlag.FLAG_NO_STATUS_EFFECTS | EntityFlag.FLAG_NO_TARGET | EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK | EntityFlag.FLAG_NO_REWARD)
		entity.State = NpcState.STATE_IDLE
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.portalInit, mod.PortalType)

function mod:PortalUpdate(entity)
	if entity.Variant == mod.PortalVariant then
        entity.Velocity = Vector.Zero
        mod:LoopingAnim(entity:GetSprite(), "Closed")


        -- Make pickups not spawn on top of it
        local room = Game():GetRoom()
        for i = -1, 1 do
            for j = -1, 1 do
                local gridPos = entity.Position + Vector(i * 40, j * 40)
                local grid = room:GetGridIndex(gridPos)
                room:SetGridPath(grid, 900)
            end
        end


        -- Waiting
        if entity.State == NpcState.STATE_IDLE then
            -- If the player left before the animation finished
            if mod.PortalTracker.GivenItems and mod.PortalTracker.GivenItems >= mod.RequiredItemCount then
                entity.State = NpcState.STATE_SUMMON
            end


        -- Taking away item
        elseif entity.State == NpcState.STATE_SUMMON then
            if not entity.Child then
                -- Needs more
                if mod.PortalTracker.GivenItems < mod.RequiredItemCount then
                    entity.State = NpcState.STATE_IDLE

                -- Spawn Void trap door
                else
                    -- Push away players
                    for i, player in pairs(Isaac.FindInRadius(entity.Position, 80, EntityPartition.PLAYER)) do
                        player:AddVelocity((player.Position - entity.Position):Resized(12))
                    end

                    entity:Remove()
                    mod:PlaySound(entity, SoundEffect.SOUND_PORTAL_OPEN)

                    -- Spawn the trap door
                    local trapDoor = Isaac.GridSpawn(GridEntityType.GRID_TRAPDOOR, 1, entity.Position, true)
                    trapDoor.VarData = 1 -- Set the destination to The Void and apply the pulse effect
                    trapDoor:GetSprite():Load("gfx/voidportal.anm2", true)
                end
            end
        end
    end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.PortalUpdate, mod.PortalType)

function mod:portalCollide(entity, target, bool)
	if entity.Variant == mod.PortalVariant and target.Type == EntityType.ENTITY_PLAYER and entity:ToNPC().State == NpcState.STATE_IDLE then
        local player = target:ToPlayer()
        local itemID = mod:GetRandomPlayerItem(player)

        -- Take away an item if the player has valid items
        if itemID ~= false then
            player:RemoveCollectible(itemID, true)
            mod.PortalTracker.GivenItems = mod.PortalTracker.GivenItems + 1
            entity:ToNPC().State = NpcState.STATE_SUMMON

            -- Effects
            mod:PlaySound(nil, SoundEffect.SOUND_BISHOP_HIT)
            player:SetColor(mod.PortalEffectColor, 15, 1, true, false)


            -- Item effect
            local velocity = (player.Position - entity.Position):Rotated(mod:Random(-30, 30)):Resized(18)
            local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, mod.PortalEffectVariant, 0, player.Position, velocity, player):ToEffect()
            effect.Parent = entity
            entity.Child = effect

            local icon = Isaac.GetItemConfig():GetCollectible(itemID).GfxFileName
            effect:GetSprite():ReplaceSpritesheet(1, icon)
            effect:GetSprite():LoadGraphics()
        end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.portalCollide, mod.PortalType)



-- Item effect
function mod:itemEffectUpdate(effect)
	local sprite = effect:GetSprite()

    -- Come out of the player
	if effect.State == 0 then
        effect.Velocity = mod:StopLerp(effect.Velocity)

		if sprite:IsFinished() then
			effect.State = 1
		end


    -- Go into the portal
	elseif effect.State == 1 then
		mod:LoopingAnim(sprite, "Move")

        -- Trail
        if not effect.Child then
            local trail = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.SPRITE_TRAIL, 0, effect.Position, Vector.Zero, effect):ToEffect()
            trail.Parent = effect
            effect.Child = trail

            trail.MinRadius = 0.1
            trail.Color = mod.PortalEffectColor
            trail:Update()

        else
            effect.Child.Velocity = effect.Position - effect.Child.Position
        end


        -- Collect
		if effect.Position:Distance(effect.Parent.Position) < 5 then
            effect.Parent:SetColor(mod.PortalEffectColor, 15, 1, true, false)
            Game():MakeShockwave(effect.Parent.Position, 0.02, 0.02, 12)
            mod:PlaySound(nil, SoundEffect.SOUND_PORTAL_SPAWN)

            effect.Parent.Child = nil
            effect.Child:Remove()
			effect:Remove()

        -- Go to the portal
        else
            effect.Velocity = mod:Lerp(effect.Velocity, (effect.Parent.Position - effect.Position):Resized(22), 0.15)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.itemEffectUpdate, mod.PortalEffectVariant)