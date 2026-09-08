local wand_ghost = {}

local component_ops = dofile("mods/metamorph_creative_menu/files/features/forms/component_ops.lua")
local gameplay_input = dofile("mods/metamorph_creative_menu/files/platform/noita/gameplay_input.lua")
local patcher_bridge = dofile("mods/metamorph_creative_menu/files/platform/noita/patcher_bridge.lua")

local valid = component_ops.valid
local get_value = component_ops.get

-- Wand ghosts are an inventory/item creature, not a projectile descriptor creature.
-- A player-polymorphed root cannot safely reproduce that ownership through AnimalAI:
-- forcing the ranged state fires base_wand_ghost.xml's orb_pink fallback instead of the
-- held procedural wand. Keep the polymorph root solely as the player body and attach an
-- unsynchronised *real vanilla wand_ghost.xml* proxy. Its untouched one-shot
-- wand_ghost.lua generates/picks up the actual wand, the engine renders that held item,
-- and NoitaPatcher UseItem casts that exact wand just like player/companion wand use.
local HELPER_ENTITY = "data/entities/animals/wand_ghost.xml"
local state = nil
local generation_serial = 0

local function component(entity, kind)
    if entity == nil or entity == 0 then return nil end
    return EntityGetFirstComponentIncludingDisabled(entity, kind)
end

local function set_enabled(entity, comp, enabled)
    if valid(comp) then pcall(EntitySetComponentIsEnabled, entity, comp, enabled == true) end
end

local function destroy(entity)
    if entity ~= nil and entity ~= 0 and EntityGetIsAlive(entity) then pcall(EntityKill, entity) end
end

local function sanitize_proxy(helper)
    if type(EntityAddTag) == "function" then
        pcall(EntityAddTag, helper, "metamorph_creative_menu_runtime")
        pcall(EntityAddTag, helper, "ew_no_enemy_sync")
        pcall(EntityAddTag, helper, "metamorph_creative_menu_wand_proxy")
    end
    if type(EntityRemoveTag) == "function" then
        pcall(EntityRemoveTag, helper, "hittable")
        pcall(EntityRemoveTag, helper, "homing_target")
        pcall(EntityRemoveTag, helper, "enemy")
    end

    -- The proxy is presentation/casting infrastructure only. It must never become an
    -- extra combat body, autonomous mover or death/drop source.
    for _, kind in ipairs({"DamageModelComponent", "HitboxComponent", "PhysicsAIComponent", "AnimalAIComponent"}) do
        for _, comp in ipairs(EntityGetComponentIncludingDisabled(helper, kind) or {}) do
            set_enabled(helper, comp, false)
        end
    end

    local pickup = component(helper, "ItemPickUpperComponent")
    if valid(pickup) then
        pcall(ComponentSetValue2, pickup, "drop_items_on_death", false)
        pcall(ComponentSetValue2, pickup, "is_immune_to_kicks", true)
        pcall(ComponentSetValue2, pickup, "is_in_npc", true)
    end
end

local function mouse_world(x, y)
    if type(DEBUG_GetMouseWorld) == "function" then
        local ok, mx, my = pcall(DEBUG_GetMouseWorld)
        if ok and tonumber(mx) ~= nil and tonumber(my) ~= nil then return tonumber(mx), tonumber(my) end
    end
    return x + 100, y
end

local function current_wand(helper)
    if type(GameGetAllInventoryItems) ~= "function" then return 0 end
    local ok, items = pcall(GameGetAllInventoryItems, helper)
    if not ok or type(items) ~= "table" then return 0 end
    for _, item in ipairs(items) do
        if item ~= nil and item ~= 0 and EntityGetIsAlive(item) then
            if type(EntityHasTag) ~= "function" or EntityHasTag(item, "wand") then return item end
        end
    end
    return 0
end

local function spawn_helper(entity)
    local x, y = EntityGetTransform(entity)
    if x == nil then return 0 end
    generation_serial = generation_serial + 1
    local frame = type(GameGetFrameNum) == "function" and (tonumber(GameGetFrameNum()) or 0) or 0
    -- The procedural wand generator seeds from spawn coordinates. Keep the invisible
    -- proxy at a unique seed location until wand_ghost.lua has created the item, then
    -- snap it onto the player. This is why repeated transforms no longer resolve to the
    -- same deck merely because the player stood on the same pixel.
    local sx = x + 257 + generation_serial * 31
    local sy = y + 131 + (frame % 71) * 13 + generation_serial * 7
    local helper = EntityLoad(HELPER_ENTITY, sx, sy) or 0
    if helper == 0 then return 0 end
    sanitize_proxy(helper)
    return helper, sx, sy
end

local function ability_ready(wand, frame)
    local ability = component(wand, "AbilityComponent")
    if not valid(ability) then return true end
    local reload_left = tonumber(get_value(ability, "mReloadFramesLeft", 0)) or 0
    local next_usable = tonumber(get_value(ability, "mNextFrameUsable", 0)) or 0
    return reload_left <= 0 and next_usable <= frame
end

local function use_real_wand(entity)
    if state == nil or state.wand == 0 or not EntityGetIsAlive(state.wand) then return false end
    local bridge = patcher_bridge.get({capability="UseItem", bootstrap_if_installed=true})
    if type(bridge) ~= "table" or type(bridge.UseItem) ~= "function" then return false end

    local frame = tonumber(GameGetFrameNum()) or 0
    if not ability_ready(state.wand, frame) then return false end

    local x, y = EntityGetTransform(entity)
    if x == nil then return false end
    local tx, ty = mouse_world(x, y)
    local wx, wy = EntityGetTransform(state.wand)
    wx, wy = tonumber(wx) or x, tonumber(wy) or y

    -- Patcher item use expects a player-like shooter tag during gun-script execution;
    -- EW and MCM's companion system use the same narrow tag scope. The proxy remains
    -- unsynchronised and non-damageable outside this call.
    if type(EntityAddTag) == "function" then pcall(EntityAddTag, state.helper, "player_unit") end
    local ok = pcall(bridge.UseItem, state.helper, state.wand, true, true, true, wx, wy, tx, ty)
    if type(EntityRemoveTag) == "function" then pcall(EntityRemoveTag, state.helper, "player_unit") end
    return ok == true
end

function wand_ghost.reset()
    if state ~= nil then
        if state.helper ~= 0 and EntityGetIsAlive(state.helper) and type(GameGetAllInventoryItems) == "function" then
            local ok, items = pcall(GameGetAllInventoryItems, state.helper)
            if ok and type(items) == "table" then
                for _, item in ipairs(items) do destroy(item) end
            end
        end
        destroy(state.helper)
    end
    state = nil
end

function wand_ghost.configure(entity)
    wand_ghost.reset()
    local helper, sx, sy = spawn_helper(entity)
    if helper == nil or helper == 0 then return false end
    state = {
        entity=entity,
        helper=helper,
        wand=0,
        seed_x=sx,
        seed_y=sy,
        ready=false,
    }
    gameplay_input.require_release("primary")
    return true
end

function wand_ghost.update(entity, controls)
    if state == nil or entity ~= state.entity or not EntityGetIsAlive(entity) then return false end
    if state.helper == 0 or not EntityGetIsAlive(state.helper) then return false end

    if not state.ready then
        local wand = current_wand(state.helper)
        if wand ~= 0 then
            state.wand = wand
            state.ready = true
        else
            -- Do not move the proxy before its vanilla one-shot init has generated the
            -- procedural wand: these coordinates are intentionally the random seed.
            return true
        end
    end

    local x, y, r, sx, sy = EntityGetTransform(entity)
    if x ~= nil then pcall(EntitySetTransform, state.helper, x, y, r or 0, sx or 1, sy or 1) end

    if gameplay_input.down(controls, "primary") then use_real_wand(entity) end
    return true
end

function wand_ghost.owns_primary()
    return state ~= nil
end

function wand_ghost.wand_entity()
    return state and state.wand or 0
end

function wand_ghost.helper_entity()
    return state and state.helper or 0
end

return wand_ghost
