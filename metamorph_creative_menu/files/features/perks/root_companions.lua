if type(METAMORPH_CREATIVE_MENU_PERK_ROOT_COMPANIONS) == "table" then return METAMORPH_CREATIVE_MENU_PERK_ROOT_COMPANIONS end

local root_companions = {}

-- Detached companions are world roots, not player descendants, so structural perk
-- transactions cannot own them. We claim only roots that appear after a pickup made by
-- this menu; anything present in the pre-pickup snapshot remains external ownership.
local ROOT_COMPANION_SPECS = {
    HOMUNCULUS = { tags={"homunculus"}, fragments={"homunculus"}, radius=640, watch_frames=90 },
    LUKKI_MINION = {
        tags={"lukki_minion", "perk_lukki_minion", "lukki_minion_friend"},
        fragments={"lukki_minion", "/lukki/"}, radius=640, watch_frames=90,
    },
    MEGA_BEAM_STONE = {
        tags={}, fragments={"data/entities/items/pickup/beamstone.xml"}, radius=320, watch_frames=120,
    },
    ANGRY_GHOST = {
        tags={"angry_ghost", "ghostly_ghost"}, fragments={"angry_ghost", "ghostly_ghost"}, radius=640, watch_frames=120,
    },
    HUNGRY_GHOST = {
        tags={"hungry_ghost", "ghostly_ghost"}, fragments={"hungry_ghost", "ghostly_ghost"}, radius=640, watch_frames=120,
    },
    DEATH_GHOST = {
        tags={"death_ghost", "ghostly_ghost"}, fragments={"death_ghost", "ghostly_ghost"}, radius=640, watch_frames=120,
    },
    GAMBLE = {
        tags={"homunculus", "lukki_minion", "perk_lukki_minion", "lukki_minion_friend",
            "angry_ghost", "hungry_ghost", "death_ghost", "ghostly_ghost"},
        fragments={"homunculus", "lukki_minion", "/lukki/", "angry_ghost", "hungry_ghost", "death_ghost", "ghostly_ghost"},
        radius=640, watch_frames=120,
    },
}

local owned_roots_by_perk = {}
local watch_by_perk = {}

local function valid_entity(entity)
    return entity ~= nil and entity ~= 0 and EntityGetIsAlive(entity)
end

local function root_entity(entity)
    if not valid_entity(entity) then return 0 end
    if type(EntityGetRootEntity) ~= "function" then return entity end
    local read_succeeded, root = pcall(EntityGetRootEntity, entity)
    if not read_succeeded or root == nil or root == 0 then return entity end
    return root
end

local function matches(entity, spec)
    if not valid_entity(entity) or root_entity(entity) ~= entity then return false end
    for _, player_tag in ipairs({"player_unit", "ew_peer", "ew_client", "polymorphed_player"}) do
        local tag_read_succeeded, has_tag = pcall(EntityHasTag, entity, player_tag)
        if tag_read_succeeded and has_tag then return false end
    end
    for _, companion_tag in ipairs(spec.tags or {}) do
        local tag_read_succeeded, has_tag = pcall(EntityHasTag, entity, companion_tag)
        if tag_read_succeeded and has_tag then return true end
    end
    local filename = string.lower(tostring(EntityGetFilename(entity) or ""))
    for _, filename_fragment in ipairs(spec.fragments or {}) do
        if string.find(filename, string.lower(filename_fragment), 1, true) then return true end
    end
    return false
end

local function candidate_belongs_nearest_to_player(candidate, player)
    if type(EntityGetTransform) ~= "function" or type(EntityGetWithTag) ~= "function" then return true end
    local ok_candidate, candidate_x, candidate_y = pcall(EntityGetTransform, candidate)
    local ok_owner, owner_x, owner_y = pcall(EntityGetTransform, player)
    if not ok_candidate or not ok_owner then return true end
    local owner_distance = (candidate_x - owner_x) * (candidate_x - owner_x)
        + (candidate_y - owner_y) * (candidate_y - owner_y)
    local seen_players = {}
    for _, player_tag in ipairs({"player_unit", "ew_peer", "ew_client", "polymorphed_player"}) do
        local ok_scan, players = pcall(EntityGetWithTag, player_tag)
        if ok_scan and type(players) == "table" then
            for _, other_player in ipairs(players) do
                if other_player ~= player and not seen_players[other_player] and valid_entity(other_player) then
                    seen_players[other_player] = true
                    local ok_other, other_x, other_y = pcall(EntityGetTransform, other_player)
                    if ok_other then
                        local other_distance = (candidate_x - other_x) * (candidate_x - other_x)
                            + (candidate_y - other_y) * (candidate_y - other_y)
                        if other_distance + 0.001 < owner_distance then return false end
                    end
                end
            end
        end
    end
    return true
end

local function snapshot(player, perk_id)
    local spec = ROOT_COMPANION_SPECS[tostring(perk_id or "")]
    local result = {}
    if spec == nil or not valid_entity(player) then return result end
    local seen = {}
    local function consider(entity)
        entity = tonumber(entity) or entity
        if entity ~= nil and entity ~= 0 and not seen[entity] then
            seen[entity] = true
            if matches(entity, spec) and candidate_belongs_nearest_to_player(entity, player) then result[entity] = true end
        end
    end
    if type(EntityGetTransform) == "function" and type(EntityGetInRadius) == "function" then
        local position_read_succeeded, player_x, player_y = pcall(EntityGetTransform, player)
        if position_read_succeeded then
            local scan_succeeded, nearby_entities = pcall(EntityGetInRadius, player_x, player_y, spec.radius or 640)
            if scan_succeeded and type(nearby_entities) == "table" then
                for _, entity in ipairs(nearby_entities) do consider(entity) end
            end
        end
    end
    return result
end

local function scan_watch(perk_id, watch_record)
    local spec = ROOT_COMPANION_SPECS[perk_id]
    if spec == nil or type(watch_record) ~= "table" or not valid_entity(watch_record.player) then return end
    local current_roots = snapshot(watch_record.player, perk_id)
    local owned_roots = owned_roots_by_perk[perk_id] or {}
    for entity in pairs(current_roots) do
        if not (watch_record.before or {})[entity] then owned_roots[entity] = true end
    end
    owned_roots_by_perk[perk_id] = owned_roots
end

local function retire_owned(perk_id, keep_watch)
    local owned_roots = owned_roots_by_perk[perk_id]
    local killed_count = 0
    if type(owned_roots) == "table" then
        for entity in pairs(owned_roots) do
            if valid_entity(entity) then
                for _, lua_component in ipairs(EntityGetComponentIncludingDisabled(entity, "LuaComponent") or {}) do
                    pcall(EntitySetComponentIsEnabled, entity, lua_component, false)
                end
                pcall(EntityKill, entity)
                killed_count = killed_count + 1
            end
        end
    end
    owned_roots_by_perk[perk_id] = nil
    if keep_watch ~= true then watch_by_perk[perk_id] = nil end
    return killed_count
end

function root_companions.supports(perk_id)
    return ROOT_COMPANION_SPECS[tostring(perk_id or "")] ~= nil
end

function root_companions.capture_before(player, perk_id)
    return snapshot(player, perk_id)
end

function root_companions.capture_all_before(player)
    local result = {}
    for perk_id in pairs(ROOT_COMPANION_SPECS) do result[perk_id] = snapshot(player, perk_id) end
    return result
end

function root_companions.commit_from_all(perk_id, player, all_before)
    if type(all_before) ~= "table" then return end
    root_companions.commit(perk_id, player, all_before[tostring(perk_id or "")])
end

function root_companions.abort_pickup(perk_id, player, before_snapshot)
    perk_id = tostring(perk_id or "")
    if ROOT_COMPANION_SPECS[perk_id] == nil or type(before_snapshot) ~= "table" then return 0 end
    local current = snapshot(player, perk_id)
    local retired = 0
    for entity in pairs(current) do
        if not before_snapshot[entity] and valid_entity(entity) then
            for _, lua_component in ipairs(EntityGetComponentIncludingDisabled(entity, "LuaComponent") or {}) do
                pcall(EntitySetComponentIsEnabled, entity, lua_component, false)
            end
            pcall(EntityKill, entity)
            retired = retired + 1
        end
    end
    return retired
end

function root_companions.commit(perk_id, player, before_snapshot)
    perk_id = tostring(perk_id or "")
    local spec = ROOT_COMPANION_SPECS[perk_id]
    if spec == nil or type(before_snapshot) ~= "table" then return end
    local current_frame = tonumber(GameGetFrameNum()) or 0
    local watch_record = {
        player=player,
        before=before_snapshot,
        until_frame=current_frame + (tonumber(spec.watch_frames) or 90),
    }
    watch_by_perk[perk_id] = watch_record
    scan_watch(perk_id, watch_record)
end

function root_companions.rebind_player(old_player_entity_id, new_player_entity_id)
    if old_player_entity_id == new_player_entity_id then return true end
    for _, watch_record in pairs(watch_by_perk) do
        if type(watch_record) == "table" and watch_record.player == old_player_entity_id then
            watch_record.player = new_player_entity_id
        end
    end
    return true
end

function root_companions.on_count_zero(perk_id)
    perk_id = tostring(perk_id or "")
    if not root_companions.supports(perk_id) then return end
    local watch_record = watch_by_perk[perk_id]
    if watch_record ~= nil then
        scan_watch(perk_id, watch_record)
        -- Keep the pre-pickup baseline briefly: some callbacks create detached roots a
        -- few engine ticks after the pickup/removal operation.
        watch_record.cleanup_mode = true
        watch_record.until_frame = (tonumber(GameGetFrameNum()) or 0) + 120
        watch_by_perk[perk_id] = watch_record
    end
    retire_owned(perk_id, watch_record ~= nil)
end

function root_companions.update(count_provider)
    local current_frame = tonumber(GameGetFrameNum()) or 0
    for perk_id, watch_record in pairs(watch_by_perk) do
        if type(watch_record) ~= "table" or not valid_entity(watch_record.player)
            or current_frame > (tonumber(watch_record.until_frame) or 0)
        then
            watch_by_perk[perk_id] = nil
        else
            scan_watch(perk_id, watch_record)
            if type(count_provider) == "function" and (tonumber(count_provider(perk_id)) or 0) <= 0 then
                watch_record.cleanup_mode = true
                retire_owned(perk_id, true)
            end
        end
    end
end

function root_companions.owned_counts()
    local result = {}
    for perk_id in pairs(ROOT_COMPANION_SPECS) do
        local alive_count = 0
        for entity in pairs(owned_roots_by_perk[perk_id] or {}) do
            if valid_entity(entity) then alive_count = alive_count + 1 end
        end
        result[perk_id] = alive_count
    end
    return result
end

function root_companions.ownership_summary()
    local rows = {}
    for perk_id in pairs(ROOT_COMPANION_SPECS) do
        local owned_roots = owned_roots_by_perk[perk_id] or {}
        local alive_count = 0
        for entity in pairs(owned_roots) do if valid_entity(entity) then alive_count = alive_count + 1 end end
        rows[#rows + 1] = perk_id .. ":owned=" .. tostring(alive_count)
            .. ":watch=" .. tostring(watch_by_perk[perk_id] ~= nil)
    end
    table.sort(rows)
    return table.concat(rows, ",")
end

METAMORPH_CREATIVE_MENU_PERK_ROOT_COMPANIONS = root_companions
return root_companions
