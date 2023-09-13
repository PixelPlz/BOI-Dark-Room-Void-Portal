local mod = DarkRoomVoidPortal



-- Lerp
function mod:Lerp(first, second, percent)
	return (first + (second - first) * percent)
end

-- Lerp to Vector.Zero
function mod:StopLerp(vector)
	return mod:Lerp(vector, Vector.Zero, 0.25)
end


-- Replaces math.random 
function mod:Random(min, max, rng)
	rng = rng or mod.RNG

	-- Float
	if not min and not max then
		return rng:RandomFloat()

	-- Integer
	elseif min and not max then
		return rng:RandomInt(min + 1)

	-- Range
	else
		local difference = math.abs(min)

		-- For ranges with negative numbers
		if min < 0 then
			max = max + difference
			return rng:RandomInt(max + 1) - difference
		-- For positive only
		else
			max = max - difference
			return rng:RandomInt(max + 1) + difference
		end
	end
end


-- Get a random index from a table
function mod:RandomIndex(fromTable)
	return fromTable[mod:Random(1, #fromTable)]
end


-- Better sound function
function mod:PlaySound(entity, id, volume, pitch, cooldown, loop, pan)
	volume = volume or 1
	pitch = pitch or 1
	cooldown = cooldown or 0
	pan = pan or 0

	if entity then
		entity:ToNPC():PlaySound(id, volume, cooldown, loop, pitch)
	else
		SFXManager():Play(id, volume, cooldown, loop, pitch, pan)
	end
end


-- Looping animation
function mod:LoopingAnim(sprite, anim)
	if not sprite:IsPlaying(anim) then
		sprite:Play(anim, true)
	end
end