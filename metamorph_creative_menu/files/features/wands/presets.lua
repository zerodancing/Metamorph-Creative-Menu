if type(METAMORPH_CREATIVE_MENU_WAND_PRESETS) == "table" then return METAMORPH_CREATIVE_MENU_WAND_PRESETS end

local presets = {}
local codec = dofile("mods/metamorph_creative_menu/files/core/wand_blueprint_codec.lua")
local blueprints = dofile("mods/metamorph_creative_menu/files/features/wands/blueprints.lua")
local inventory_slots = dofile("mods/metamorph_creative_menu/files/platform/noita/inventory_slots.lua")
local wand_sync = dofile("mods/metamorph_creative_menu/files/features/wands/sync.lua")
local ew_world_items = dofile("mods/metamorph_creative_menu/files/integrations/ew/world_items.lua")

local SETTING_KEY = "metamorph_creative_menu.wand_presets_v1"
local HEADER = "MCM_PRESETS_V1\n"
local MAX_PRESETS = 64
local BASE_WAND = "data/entities/items/starting_wand.xml"
local cache = nil

local function clean_name(value)
    value = tostring(value or "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    value = string.gsub(value, "[%c]", " ")
    if #value > 80 then value = string.sub(value, 1, 80) end
    return value
end

local function alive(entity)
    return entity ~= nil and entity ~= 0 and type(EntityGetIsAlive) == "function" and EntityGetIsAlive(entity) == true
end

local function destroy_tree(entity)
    if not alive(entity) then return end
    for _, child in ipairs(EntityGetAllChildren(entity) or {}) do destroy_tree(child) end
    if type(EntityRemoveFromParent) == "function" then pcall(EntityRemoveFromParent, entity) end
    pcall(EntityKill, entity)
end

local function load_cache()
    if cache ~= nil then return cache end
    cache = {}
    local raw = ""
    if type(ModSettingGet) == "function" then
        local ok, value = pcall(ModSettingGet, SETTING_KEY)
        if ok and type(value) == "string" then raw = value end
    end
    if string.sub(raw, 1, #HEADER) ~= HEADER then return cache end
    for line in string.gmatch(string.sub(raw, #HEADER + 1) .. "\n", "([^\n]*)\n") do
        local encoded_name, encoded_blueprint = string.match(line, "^([^\t]*)\t(.*)$")
        if encoded_name ~= nil and encoded_blueprint ~= nil then
            local name = codec.unescape(encoded_name)
            local blueprint = select(1, codec.decode(codec.unescape(encoded_blueprint)))
            if name ~= "" and blueprint ~= nil then cache[#cache + 1] = {name=name,blueprint=blueprint} end
        end
        if #cache >= MAX_PRESETS then break end
    end
    return cache
end

local function persist()
    local lines = {"MCM_PRESETS_V1"}
    for _, preset in ipairs(load_cache()) do
        lines[#lines + 1] = codec.escape(preset.name) .. "\t" .. codec.escape(codec.encode(preset.blueprint))
    end
    if type(ModSettingSet) ~= "function" then return false, "settings_unavailable" end
    local ok = pcall(ModSettingSet, SETTING_KEY, table.concat(lines, "\n"))
    return ok, ok and "ok" or "settings_write_failed"
end

function presets.all()
    local copy = {}
    for index, preset in ipairs(load_cache()) do copy[index] = {name=preset.name,blueprint=preset.blueprint} end
    return copy
end

function presets.save(name, wand)
    name = clean_name(name)
    if name == "" then return false, "name_required" end
    local blueprint, reason = blueprints.capture(wand)
    if blueprint == nil then return false, reason end
    local list = load_cache()
    local target = nil
    for index, preset in ipairs(list) do if string.lower(preset.name) == string.lower(name) then target = index; break end end
    if target == nil then
        if #list >= MAX_PRESETS then return false, "preset_limit" end
        list[#list + 1] = {name=name,blueprint=blueprint}
    else
        list[target] = {name=name,blueprint=blueprint}
    end
    return persist()
end

function presets.load(index, player, wand)
    local preset = load_cache()[tonumber(index)]
    if preset == nil then return false, "missing_preset" end
    return blueprints.apply(player, wand, preset.blueprint)
end

function presets.give(index, player)
    local preset = load_cache()[tonumber(index)]
    if preset == nil then return false, "missing_preset", 0 end
    if player == nil or player == 0 or not alive(player) then return false, "invalid_player", 0 end
    local px, py = EntityGetTransform(player)
    if tonumber(px) == nil or tonumber(py) == nil then return false, "position", 0 end

    local loaded_ok, entity = pcall(EntityLoad, BASE_WAND, px + 12, py - 8)
    entity = loaded_ok and (tonumber(entity) or 0) or 0
    if entity == 0 or not alive(entity) then return false, "wand_load_failed", 0 end

    local applied, apply_reason = blueprints.apply(player, entity, preset.blueprint)
    if not applied then
        destroy_tree(entity)
        return false, apply_reason or "blueprint_failed", 0
    end

    local plan, plan_reason = inventory_slots.preflight(player, entity)
    if plan ~= nil then
        local placed, place_reason = inventory_slots.place_exact(player, entity, plan.name, plan.x, plan.y)
        if not placed then
            destroy_tree(entity)
            wand_sync.inventory(player)
            return false, place_reason or "inventory_failed", 0
        end
        wand_sync.inventory(player)
        return true, "given_inventory", entity
    end

    if plan_reason ~= "full" then
        destroy_tree(entity)
        return false, plan_reason or "inventory_failed", 0
    end

    pcall(EntityRemoveFromParent, entity)
    pcall(EntitySetTransform, entity, px + 12, py - 8)
    inventory_slots.enable_world(entity)
    local notify_ok, notified = pcall(ew_world_items.notify_world_item, entity)
    if not notify_ok or notified == false or not alive(entity) then
        destroy_tree(entity)
        return false, "world_sync_failed", 0
    end
    return true, "given_world", entity
end

function presets.delete(index)
    index = math.floor(tonumber(index) or 0)
    local list = load_cache()
    if list[index] == nil then return false, "missing_preset" end
    table.remove(list, index)
    return persist()
end


METAMORPH_CREATIVE_MENU_WAND_PRESETS = presets
return presets
