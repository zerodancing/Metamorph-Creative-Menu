-- Host-authoritative companion controller. The clone is not a player entity; movement
-- is driven through CharacterData and wand casting is explicit.

local entity = GetUpdatedEntityID()
if entity == nil or entity == 0 or not EntityGetIsAlive(entity) then return end

local function component(kind, tag)
    local value = EntityGetFirstComponentIncludingDisabled(entity, kind, tag)
    return value ~= nil and value ~= 0 and value or nil
end

local function storage(name)
    -- New clones tag their private storages so lookup is O(1). Fall back to the old
    -- name scan for clones created by an earlier build or XML from another mod layer.
    local direct = EntityGetFirstComponentIncludingDisabled(entity, "VariableStorageComponent", name)
    if direct ~= nil and direct ~= 0 then return direct end
    for _, value in ipairs(EntityGetComponentIncludingDisabled(entity, "VariableStorageComponent") or {}) do
        if ComponentGetValue2(value, "name") == name then return value end
    end
    return nil
end

local function number_value(component_id, field, fallback)
    if component_id == nil or component_id == 0 then return fallback or 0 end
    local ok, value = pcall(ComponentGetValue2, component_id, field)
    return ok and tonumber(value) or (fallback or 0)
end

-- Initial max-HP correction belongs to companion_spawn_guard.lua.  Keep this
-- controller focused on movement/targeting/casting; it must never heal combat damage.

local owner_store = storage("mcm_companion_owner")
local target_store = storage("mcm_companion_target")
local owner = owner_store and ComponentGetValue2(owner_store, "value_int") or 0
local target = target_store and ComponentGetValue2(target_store, "value_int") or 0
local controls = component("ControlsComponent")
local inventory = component("Inventory2Component")
local character_data = component("CharacterDataComponent")
if controls == nil or inventory == nil or character_data == nil then return end
-- This entity is never registered as a player. Leaving Controls enabled lets Noita's
-- local input dispatcher feed it the real player's buttons anyway, producing a mirror
-- instead of an NPC. Movement and casting below are fully host-authoritative.
ComponentSetValue2(controls, "enabled", false)

local ew_enabled = false
pcall(function() ew_enabled = ModIsEnabled("quant.ew") == true end)
if ew_enabled and not GameHasFlagRun("ew_flag_this_is_host") then
    -- Synced copies are visual/physical replicas. Only EW's authoritative host is
    -- allowed to make AI decisions or cast a second copy of a projectile.
    for _, field in ipairs({
        "mButtonDownLeft", "mButtonDownRight", "mButtonDownUp", "mButtonDownDown",
        "mButtonDownFly", "mButtonDownFire", "mButtonDownFire2",
        "mButtonDownRightClick", "mButtonDownThrow",
    }) do ComponentSetValue2(controls, field, false) end
    ComponentSetValue2(controls, "enabled", false)
    return
end

local function alive(value)
    return value ~= nil and value ~= 0 and EntityGetIsAlive(value)
end

if not alive(owner) then
    local best, best_distance = 0, math.huge
    local ex, ey = EntityGetTransform(entity)
    for _, tag in ipairs({"player_unit", "polymorphed_player"}) do
        for _, candidate in ipairs(EntityGetWithTag(tag) or {}) do
            if alive(candidate) and not EntityHasTag(candidate, "metamorph_creative_menu_companion")
                and not EntityHasTag(candidate, "ew_client")
            then
                local px, py = EntityGetTransform(candidate)
                if px ~= nil and ex ~= nil then
                    local distance = (px - ex) ^ 2 + (py - ey) ^ 2
                    if distance < best_distance then best, best_distance = candidate, distance end
                end
            end
        end
    end
    owner = best
    if owner_store ~= nil then ComponentSetValue2(owner_store, "value_int", owner) end
end

local function is_player(value)
    return EntityHasTag(value, "player_unit")
        or EntityHasTag(value, "ew_peer")
        or EntityHasTag(value, "ew_client")
        or EntityHasTag(value, "ew_notplayer")
        or EntityHasTag(value, "metamorph_creative_menu_companion")
end

local function is_hostile(value)
    if not alive(value) or value == entity or value == owner or is_player(value)
        or not EntityHasTag(value, "mortal")
    then return false end
    if EntityGetFirstComponentIncludingDisabled(value, "GenomeDataComponent") == nil then return false end
    local ok, relation = pcall(EntityGetHerdRelation, entity, value)
    return ok and tonumber(relation) ~= nil and tonumber(relation) < 40
end

local function center(value)
    local x, y = EntityGetFirstHitboxCenter(value)
    if x == nil then x, y = EntityGetTransform(value) end
    return x, y
end

local x, y = EntityGetTransform(entity)
if x == nil then return end

-- Target scans are staggered by entity id to keep several companions inexpensive.
local frame = GameGetFrameNum()
if not is_hostile(target) or frame % 10 == entity % 10 then
    target = 0
    local best = 640 * 640
    for _, candidate in ipairs(EntityGetInRadiusWithTag(x, y, 640, "mortal") or {}) do
        if is_hostile(candidate) then
            local tx, ty = center(candidate)
            if tx ~= nil then
                local dx, dy = tx - x, ty - y
                local distance = dx * dx + dy * dy
                if distance < best then target, best = candidate, distance end
            end
        end
    end
    if target_store ~= nil then ComponentSetValue2(target_store, "value_int", target) end
end

local move_target = alive(target) and target or (alive(owner) and owner or 0)
local tx, ty
if move_target ~= 0 then tx, ty = center(move_target) end
local left, right, fly, down = false, false, false, false
local attacking = alive(target) and tx ~= nil

if tx ~= nil then
    local dx, dy = tx - x, ty - y
    local distance2 = dx * dx + dy * dy
    if attacking then
        -- Keep enough room for ordinary projectiles, but close distance when needed.
        if math.abs(dx) > 118 then left, right = dx < 0, dx > 0
        elseif math.abs(dx) < 48 then left, right = dx > 0, dx < 0 end
        fly = dy < -18 or (distance2 > 180 * 180 and frame % 60 > 28)
    elseif distance2 > 66 * 66 then
        left, right = dx < -8, dx > 8
        fly = dy < -14 or distance2 > 170 * 170
        down = dy > 85
    end

    local distance = math.sqrt(math.max(0.0001, distance2))
    local aim_distance = math.min(distance, 320)
    local ax, ay = dx / distance, dy / distance
    ComponentSetValue2(controls, "mAimingVector", ax * aim_distance, ay * aim_distance)
    ComponentSetValue2(controls, "mAimingVectorNormalized", ax, ay)
    ComponentSetValue2(controls, "mMousePosition", x + ax * aim_distance, y + ay * aim_distance)
end

for _, field in ipairs({
    "mButtonDownLeft", "mButtonDownRight", "mButtonDownUp", "mButtonDownFly", "mButtonDownDown",
}) do ComponentSetValue2(controls, field, false) end
ComponentSetValue2(controls, "mFlyingTargetY", y - 10)

-- Drive CharacterData directly so local input and EW player ownership are never
-- involved. CharacterData still performs native collision resolution.
local vx, vy = ComponentGetValue2(character_data, "mVelocity")
vx, vy = tonumber(vx) or 0, tonumber(vy) or 0
local desired_x = left and -46 or (right and 46 or 0)
vx = vx * 0.76 + desired_x * 0.24
if fly then vy = math.max(-92, vy - 7.5)
elseif down then vy = math.min(120, vy + 7)
else vy = math.min(190, vy + 7.5) end
ComponentSetValue2(character_data, "mVelocity", vx, vy)

local wand = ComponentGetValue2(inventory, "mActualActiveItem")
if not alive(wand) or not EntityHasTag(wand, "wand") then
    wand = ComponentGetValue2(inventory, "mActiveItem")
end
local has_wand = alive(wand) and EntityHasTag(wand, "wand")
if has_wand and type(np) == "table" and type(np.SetActiveHeldEntity) == "function" then
    pcall(np.SetActiveHeldEntity, entity, wand, false, false)
end

local line_clear = false
if attacking then
    local hit = RaytracePlatforms(x, y - 4, tx, ty)
    line_clear = not hit
end
local fire = has_wand and attacking and line_clear
ComponentSetValue2(controls, "mButtonDownRightClick", false)
ComponentSetValue2(controls, "mButtonDownThrow", false)
ComponentSetValue2(controls, "mButtonDownFire", false)
ComponentSetValue2(controls, "mButtonDownFire2", false)
if fire then
    local ability = EntityGetFirstComponentIncludingDisabled(wand, "AbilityComponent")
    local next_store = storage("mcm_companion_next_fire")
    local next_fire = next_store and tonumber(ComponentGetValue2(next_store, "value_int")) or 0
    local reload_left = number_value(ability, "mReloadFramesLeft", 0)
    local next_usable = number_value(ability, "mNextFrameUsable", 0)
    if frame >= next_fire and reload_left <= 0 and next_usable <= frame then
        local wx, wy = EntityGetTransform(wand)
        wx, wy = wx or x, wy or (y - 4)
        local fired = false
        if type(np) == "table" and type(np.UseItem) == "function" then
            -- With NoitaPatcher available, cast the copied wand exactly like a player.
            EntityAddTag(entity, "player_unit")
            fired = pcall(np.UseItem, entity, wand, true, true, true, wx, wy, tx, ty)
            EntityRemoveTag(entity, "player_unit")
        elseif type(GameShootProjectile) == "function" and ModDoesFileExist("data/entities/projectiles/deck/light_bullet.xml") then
            -- Single-player without NoitaPatcher previously had no attack path at all.
            -- Use a modest basic bolt rather than emulating the entire gun VM; the AI
            -- remains useful while the Patcher path still casts the real copied wand.
            local projectile = EntityLoad("data/entities/projectiles/deck/light_bullet.xml", wx, wy) or 0
            if projectile ~= 0 then
                local ok_shot = pcall(GameShootProjectile, entity, wx, wy, tx, ty, projectile)
                fired = ok_shot == true
                if not fired and EntityGetIsAlive(projectile) then pcall(EntityKill, projectile) end
            end
        end
        if next_store ~= nil then
            ComponentSetValue2(next_store, "value_int", frame + (fired and 18 or 30))
        end
    end
end
