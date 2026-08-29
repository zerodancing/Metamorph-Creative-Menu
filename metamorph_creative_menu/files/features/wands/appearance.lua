if type(METAMORPH_CREATIVE_MENU_WAND_APPEARANCE) == "table" then return METAMORPH_CREATIVE_MENU_WAND_APPEARANCE end

local appearance = {}
local wand_api = dofile("mods/metamorph_creative_menu/files/platform/noita/wand.lua")
local wand_sync = dofile("mods/metamorph_creative_menu/files/features/wands/sync.lua")

local function valid(component) return component ~= nil and component ~= 0 end
local function finite(value)
    value = tonumber(value)
    return value ~= nil and value == value and value > -math.huge and value < math.huge and value or nil
end

local function first(entity, component_type, tag)
    if tag == nil then
        local ok, component = pcall(EntityGetFirstComponentIncludingDisabled, entity, component_type)
        return ok and (component or 0) or 0
    end
    local ok, component = pcall(EntityGetFirstComponentIncludingDisabled, entity, component_type, tag)
    return ok and (component or 0) or 0
end

-- Vanilla and modded wands are not perfectly consistent about component tags. Prefer the
-- canonical tag, but only fall back when the component type is unambiguous. In particular,
-- never guess between multiple SpriteComponents and accidentally edit a glow/overlay sprite.
local function resolve_component(entity, component_type, tag)
    local component = first(entity, component_type, tag)
    if valid(component) then return component, "primary" end
    if type(EntityGetComponentIncludingDisabled) ~= "function" then return 0, "missing" end
    local ok, list = pcall(EntityGetComponentIncludingDisabled, entity, component_type)
    if not ok or type(list) ~= "table" then return 0, "missing" end
    local candidate, count = 0, 0
    for _, current in ipairs(list) do
        if valid(current) then candidate, count = current, count + 1 end
    end
    if count == 1 then return candidate, "unique_fallback" end
    return 0, count == 0 and "missing" or "ambiguous"
end

local function read(component, field)
    if not valid(component) then return nil end
    local ok, value = pcall(ComponentGetValue2, component, field)
    if not ok then return nil end
    return value
end

local function write(component, field, ...)
    if not valid(component) then return false end
    return pcall(ComponentSetValue2, component, field, ...)
end

local function write_verified(component, field, value)
    if not write(component, field, value) then return false end
    local actual = read(component, field)
    if type(value) == "number" then return tonumber(actual) == tonumber(value) end
    if type(value) == "boolean" then return actual == value end
    return tostring(actual or "") == tostring(value or "")
end

local function write_vector_verified(component, field, x, y)
    if not write(component, field, x, y) then return false end
    local ok, actual_x, actual_y = pcall(ComponentGetValue2, component, field)
    return ok and tonumber(actual_x) == tonumber(x) and tonumber(actual_y) == tonumber(y)
end

function appearance.snapshot(wand)
    local ability = wand_api.ability(wand)
    if ability == 0 then return nil, "not_wand" end
    local item, item_resolution = resolve_component(wand, "ItemComponent")
    local sprite, sprite_resolution = resolve_component(wand, "SpriteComponent", "item")
    local hotspot, hotspot_resolution = resolve_component(wand, "HotspotComponent", "shoot_pos")
    local result = {
        wand=wand, ability=ability, item=item, sprite=sprite, hotspot=hotspot,
        item_resolution=item_resolution, sprite_resolution=sprite_resolution, hotspot_resolution=hotspot_resolution,
        sprite_file=tostring(select(1, wand_api.get_scalar(ability, "sprite_file")) or ""),
    }
    if valid(item) then
        result.name = tostring(read(item, "item_name") or "")
        result.show_name_in_ui = read(item, "always_use_item_name_in_ui") == true
        result.wand_frozen = read(item, "is_frozen") == true
    else
        result.name, result.show_name_in_ui, result.wand_frozen = "", false, false
    end
    if valid(sprite) then
        result.image_file = tostring(read(sprite, "image_file") or "")
        result.offset_x = finite(read(sprite, "offset_x"))
        result.offset_y = finite(read(sprite, "offset_y"))
    end
    if valid(hotspot) then
        local ok, x, y = pcall(ComponentGetValue2, hotspot, "offset")
        if ok then result.tip_x, result.tip_y = finite(x), finite(y) end
    end
    return result, "ok"
end

-- Rollback always resolves fresh component IDs. A synchronization/refresh may replace the
-- component object even though the wand entity remains the same.
local function restore(snapshot)
    if type(snapshot) ~= "table" then return end
    local wand = snapshot.wand
    local ability = wand_api.ability(wand)
    if ability ~= 0 then pcall(wand_api.set_scalar, ability, "sprite_file", snapshot.sprite_file or "") end
    local item = select(1, resolve_component(wand, "ItemComponent"))
    if valid(item) then
        pcall(ComponentSetValue2, item, "item_name", snapshot.name or "")
        pcall(ComponentSetValue2, item, "always_use_item_name_in_ui", snapshot.show_name_in_ui == true)
        pcall(ComponentSetValue2, item, "is_frozen", snapshot.wand_frozen == true)
    end
    local sprite = select(1, resolve_component(wand, "SpriteComponent", "item"))
    if valid(sprite) then
        if snapshot.image_file ~= nil then pcall(ComponentSetValue2, sprite, "image_file", snapshot.image_file) end
        if snapshot.offset_x ~= nil then pcall(ComponentSetValue2, sprite, "offset_x", snapshot.offset_x) end
        if snapshot.offset_y ~= nil then pcall(ComponentSetValue2, sprite, "offset_y", snapshot.offset_y) end
        if type(EntityRefreshSprite) == "function" then pcall(EntityRefreshSprite, wand, sprite) end
    end
    local hotspot = select(1, resolve_component(wand, "HotspotComponent", "shoot_pos"))
    if valid(hotspot) and snapshot.tip_x ~= nil and snapshot.tip_y ~= nil then
        pcall(ComponentSetValue2, hotspot, "offset", snapshot.tip_x, snapshot.tip_y)
    end
end

local function sync_then_snapshot(player, wand, skip_sync)
    if skip_sync ~= true then wand_sync.inventory(player) end
    return appearance.snapshot(wand)
end

local function rollback_after_failure(player, before, skip_sync)
    restore(before)
    if skip_sync ~= true then wand_sync.inventory(player) end
end

function appearance.set_name(player, wand, name, show_name_in_ui)
    local before, reason = appearance.snapshot(wand)
    if before == nil then return false, reason end
    if not valid(before.item) then return false, "item_missing" end
    name = tostring(name or "")
    if #name > 160 then name = string.sub(name, 1, 160) end
    if name == "" then show_name_in_ui = false end
    local target_show = show_name_in_ui == true
    if not write_verified(before.item, "item_name", name)
        or not write_verified(before.item, "always_use_item_name_in_ui", target_show)
    then
        restore(before)
        return false, "name_write_failed"
    end
    local after = select(1, sync_then_snapshot(player, wand, false))
    if after == nil or not valid(after.item)
        or tostring(after.name or "") ~= name or after.show_name_in_ui ~= target_show
    then
        rollback_after_failure(player, before, false)
        return false, "name_verify_failed"
    end
    return true, "ok"
end

function appearance.set_wand_frozen(player, wand, frozen)
    local before, reason = appearance.snapshot(wand)
    if before == nil then return false, reason end
    if not valid(before.item) then return false, "item_missing" end
    local target = frozen == true
    if not write_verified(before.item, "is_frozen", target) then
        restore(before)
        return false, "freeze_write_failed"
    end
    local after = select(1, sync_then_snapshot(player, wand, false))
    if after == nil or not valid(after.item) or after.wand_frozen ~= target then
        rollback_after_failure(player, before, false)
        return false, "freeze_verify_failed"
    end
    return true, "ok"
end

local function spell_items(wand)
    local result = {}
    for _, entity in ipairs(EntityGetAllChildren(wand) or {}) do
        local action = select(1, resolve_component(entity, "ItemActionComponent"))
        local item = select(1, resolve_component(entity, "ItemComponent"))
        if valid(action) and valid(item) then result[#result + 1] = {entity=entity,item=item} end
    end
    return result
end

function appearance.set_spells_frozen(player, wand, frozen)
    if wand_api.ability(wand) == 0 then return false, "not_wand" end
    local target = frozen == true
    local before = {}
    for _, record in ipairs(spell_items(wand)) do
        local old = read(record.item, "is_frozen") == true
        before[#before + 1] = {entity=record.entity,old=old}
        if old ~= target and not write_verified(record.item, "is_frozen", target) then
            for _, previous in ipairs(before) do
                local current_item = select(1, resolve_component(previous.entity, "ItemComponent"))
                if valid(current_item) then pcall(ComponentSetValue2, current_item, "is_frozen", previous.old) end
            end
            return false, "spell_freeze_write_failed"
        end
    end
    wand_sync.inventory(player)
    local all_frozen, mixed, total = appearance.spell_freeze_state(wand)
    local verified = total == 0 or (mixed == false and all_frozen == target)
    if not verified then
        for _, previous in ipairs(before) do
            local current_item = select(1, resolve_component(previous.entity, "ItemComponent"))
            if valid(current_item) then pcall(ComponentSetValue2, current_item, "is_frozen", previous.old) end
        end
        wand_sync.inventory(player)
        return false, "spell_freeze_verify_failed"
    end
    return true, "ok"
end

function appearance.spell_freeze_state(wand)
    local total, frozen = 0, 0
    for _, record in ipairs(spell_items(wand)) do
        total = total + 1
        if read(record.item, "is_frozen") == true then frozen = frozen + 1 end
    end
    if total == 0 or frozen == 0 then return false, false, total end
    if frozen == total then return true, false, total end
    return false, true, total
end

local function visual_matches(snapshot, values)
    if type(snapshot) ~= "table" then return false end
    if values.sprite_file ~= nil and tostring(snapshot.sprite_file or "") ~= tostring(values.sprite_file) then return false end
    if values.image_file ~= nil and tostring(snapshot.image_file or "") ~= tostring(values.image_file) then return false end
    if values.offset_x ~= nil and tonumber(snapshot.offset_x) ~= tonumber(values.offset_x) then return false end
    if values.offset_y ~= nil and tonumber(snapshot.offset_y) ~= tonumber(values.offset_y) then return false end
    if values.tip_x ~= nil and tonumber(snapshot.tip_x) ~= tonumber(values.tip_x) then return false end
    if values.tip_y ~= nil and tonumber(snapshot.tip_y) ~= tonumber(values.tip_y) then return false end
    return true
end

function appearance.set_visual(player, wand, values, options)
    values = type(values) == "table" and values or {}
    options = type(options) == "table" and options or {}
    local before, reason = appearance.snapshot(wand)
    if before == nil then return false, reason end

    local requested = {}
    local path = values.sprite_file
    local image_path = values.image_file
    if path ~= nil then
        path = tostring(path)
        if path == "" then return false, "empty_path" end
        if type(ModDoesFileExist) == "function" and not ModDoesFileExist(path) then return false, "missing_asset" end
        if not wand_api.set_scalar(before.ability, "sprite_file", path) then restore(before); return false, "ability_sprite_failed" end
        requested.sprite_file = path
        if image_path == nil then image_path = path end
    end
    if image_path ~= nil then
        image_path = tostring(image_path)
        if image_path == "" then restore(before); return false, "empty_image_path" end
        if type(ModDoesFileExist) == "function" and not ModDoesFileExist(image_path) then restore(before); return false, "missing_image_asset" end
        if valid(before.sprite) then
            if not write_verified(before.sprite, "image_file", image_path) then restore(before); return false, "sprite_image_failed" end
            requested.image_file = image_path
        else
            restore(before); return false, "sprite_component_missing"
        end
    end

    local offset_x = values.offset_x ~= nil and finite(values.offset_x) or nil
    local offset_y = values.offset_y ~= nil and finite(values.offset_y) or nil
    local tip_x = values.tip_x ~= nil and finite(values.tip_x) or nil
    local tip_y = values.tip_y ~= nil and finite(values.tip_y) or nil
    if (values.offset_x ~= nil and offset_x == nil) or (values.offset_y ~= nil and offset_y == nil)
        or (values.tip_x ~= nil and tip_x == nil) or (values.tip_y ~= nil and tip_y == nil)
    then restore(before); return false, "invalid_geometry" end

    if valid(before.sprite) then
        if offset_x ~= nil and not write_verified(before.sprite, "offset_x", offset_x) then restore(before); return false, "offset_x_failed" end
        if offset_y ~= nil and not write_verified(before.sprite, "offset_y", offset_y) then restore(before); return false, "offset_y_failed" end
        if offset_x ~= nil then requested.offset_x = offset_x end
        if offset_y ~= nil then requested.offset_y = offset_y end
        if type(EntityRefreshSprite) == "function" then pcall(EntityRefreshSprite, wand, before.sprite) end
    elseif offset_x ~= nil or offset_y ~= nil then
        restore(before); return false, "sprite_component_missing"
    end

    if tip_x ~= nil or tip_y ~= nil then
        if not valid(before.hotspot) then restore(before); return false, "shoot_hotspot_missing" end
        local final_x = tip_x ~= nil and tip_x or before.tip_x
        local final_y = tip_y ~= nil and tip_y or before.tip_y
        if final_x == nil or final_y == nil or not write_vector_verified(before.hotspot, "offset", final_x, final_y) then
            restore(before); return false, "tip_write_failed"
        end
        if tip_x ~= nil then requested.tip_x = tip_x end
        if tip_y ~= nil then requested.tip_y = tip_y end
    end

    local after = select(1, sync_then_snapshot(player, wand, options.skip_sync == true))
    if not visual_matches(after, requested) then
        rollback_after_failure(player, before, options.skip_sync == true)
        return false, "visual_verify_failed"
    end
    if after ~= nil and valid(after.sprite) and type(EntityRefreshSprite) == "function" then
        pcall(EntityRefreshSprite, wand, after.sprite)
    end
    return true, "ok"
end

function appearance.apply(player, wand, desired, options)
    desired = type(desired) == "table" and desired or {}
    options = type(options) == "table" and options or {}
    local before, reason = appearance.snapshot(wand)
    if before == nil then return false, reason end
    local meta = type(desired.meta) == "table" and desired.meta or {}

    if desired.sprite_file ~= nil or meta.image_file ~= nil or meta.sprite_offset_x ~= nil or meta.sprite_offset_y ~= nil
        or meta.tip_x ~= nil or meta.tip_y ~= nil
    then
        local ok, err = appearance.set_visual(player, wand, {
            sprite_file=desired.sprite_file, image_file=meta.image_file,
            offset_x=meta.sprite_offset_x, offset_y=meta.sprite_offset_y,
            tip_x=meta.tip_x, tip_y=meta.tip_y,
        }, {skip_sync=true})
        if not ok then restore(before); return false, err end
    end

    local current = select(1, appearance.snapshot(wand)) or before
    if meta.name ~= nil or meta.show_name_in_ui ~= nil then
        if not valid(current.item) then restore(before); return false, "item_missing" end
        local name = meta.name ~= nil and tostring(meta.name) or current.name
        if #name > 160 then name = string.sub(name, 1, 160) end
        local show = current.show_name_in_ui
        if meta.show_name_in_ui ~= nil then show = meta.show_name_in_ui == true end
        if name == "" then show = false end
        if not write_verified(current.item, "item_name", name)
            or not write_verified(current.item, "always_use_item_name_in_ui", show)
        then restore(before); return false, "name_write_failed" end
    end
    current = select(1, appearance.snapshot(wand)) or current
    if meta.wand_frozen ~= nil then
        if not valid(current.item) or not write_verified(current.item, "is_frozen", meta.wand_frozen == true) then
            restore(before); return false, "freeze_write_failed"
        end
    end

    local after = select(1, sync_then_snapshot(player, wand, options.skip_sync == true))
    if after == nil then rollback_after_failure(player, before, options.skip_sync == true); return false, "appearance_verify_failed" end
    if meta.name ~= nil then
        local expected_name = tostring(meta.name or "")
        if #expected_name > 160 then expected_name = string.sub(expected_name, 1, 160) end
        if tostring(after.name or "") ~= expected_name then
            rollback_after_failure(player, before, options.skip_sync == true); return false, "name_verify_failed"
        end
    end
    if meta.show_name_in_ui ~= nil and after.show_name_in_ui ~= (meta.show_name_in_ui == true and tostring(after.name or "") ~= "") then
        rollback_after_failure(player, before, options.skip_sync == true); return false, "name_verify_failed"
    end
    if meta.wand_frozen ~= nil and after.wand_frozen ~= (meta.wand_frozen == true) then
        rollback_after_failure(player, before, options.skip_sync == true); return false, "freeze_verify_failed"
    end
    return true, "ok"
end

METAMORPH_CREATIVE_MENU_WAND_APPEARANCE = appearance
return appearance
