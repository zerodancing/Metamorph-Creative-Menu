local world_entities = {}
local ew_runtime = dofile("mods/metamorph_creative_menu/files/integrations/ew/runtime.lua")

-- Entangled Worlds 1.6.3 native DES discovers ordinary enemies itself.  MCM must not
-- allocate another GID, replace EW's death callback, or attach custom damage guards.
-- Only unusual creature-like roots that are not covered by native DES receive EW's
-- documented opt-in tag.
local NATIVE_TRACK_TAGS = {
    "enemy", "ew_synced", "plague_rat", "seed_f", "seed_e", "seed_d", "seed_c",
    "perk_fungus_tiny", "helpless_animal", "nest",
}

local function valid(entity)
    return entity ~= nil and tonumber(entity) ~= 0
        and type(EntityGetIsAlive) == "function" and EntityGetIsAlive(tonumber(entity)) == true
end

local function root_entity(entity)
    entity = tonumber(entity) or 0
    if not valid(entity) then return 0 end
    if type(EntityGetRootEntity) == "function" then
        local ok, root = pcall(EntityGetRootEntity, entity)
        root = ok and (tonumber(root) or 0) or 0
        if root ~= 0 and valid(root) then return root end
    end
    return entity
end

local function has_tag(entity, tag)
    if type(EntityHasTag) ~= "function" then return false end
    local ok, value = pcall(EntityHasTag, entity, tag)
    return ok and value == true
end

local function local_des_identity(entity)
    if not valid(entity) or type(EntityGetComponentIncludingDisabled) ~= "function" then return false, "" end
    local ok, values = pcall(EntityGetComponentIncludingDisabled, entity, "VariableStorageComponent")
    if not ok or type(values) ~= "table" then return false, "" end
    for _, storage in ipairs(values) do
        local ok_name, name = pcall(ComponentGetValue2, storage, "name")
        if ok_name and tostring(name or "") == "ew_gid_lid" then
            local ok_owner, owner = pcall(ComponentGetValue2, storage, "value_bool")
            local ok_gid, gid = pcall(ComponentGetValue2, storage, "value_string")
            return ok_owner and owner == true, ok_gid and tostring(gid or "") or ""
        end
    end
    return false, ""
end

function world_entities.is_tracked(entity)
    entity = root_entity(entity)
    if entity == 0 then return false end
    if has_tag(entity, "ew_des") then return true end
    local _, gid = local_des_identity(entity)
    return gid ~= ""
end

function world_entities.track(entity, _options)
    if not valid(entity) then return false, "invalid" end
    if not ew_runtime.enabled() then return true, "singleplayer" end
    entity = root_entity(entity)
    if entity == 0 then return false, "root" end

    for _, tag in ipairs(NATIVE_TRACK_TAGS) do
        if has_tag(entity, tag) then return true, "native_auto" end
    end

    if type(EntityAddTag) ~= "function" then return false, "tag_api_unavailable" end
    local ok = pcall(EntityAddTag, entity, "ew_synced")
    return ok, ok and "native_forced" or "tag_failed"
end

-- Kept for the main-loop API; native DES owns lifecycle updates.
function world_entities.update() end

function world_entities.outbox_state()
    return 0, 0, "native_des_stock_only_v1"
end

return world_entities
