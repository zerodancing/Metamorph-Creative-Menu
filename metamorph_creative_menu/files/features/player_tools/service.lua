if type(METAMORPH_CREATIVE_MENU_PLAYER_TOOLS) == "table" then return METAMORPH_CREATIVE_MENU_PLAYER_TOOLS end

local service = {}

local BRING_SEQ = "mcm_teleport_bring_outbox_seq_v1"
local BRING_PEER = "mcm_teleport_bring_outbox_peer_v1"
local BRING_TARGET_X = "mcm_teleport_bring_outbox_target_x_v1"
local BRING_TARGET_Y = "mcm_teleport_bring_outbox_target_y_v1"
local BRING_DEST_X = "mcm_teleport_bring_outbox_dest_x_v1"
local BRING_DEST_Y = "mcm_teleport_bring_outbox_dest_y_v1"
local STREAM_TIMEOUT_FRAMES = 300
local BODY_RADIUS = 9

-- Coordinates are taken from EW's own debug teleports where available. Main-path
-- biome points use their central corridors and are resolved again by
-- FindFreePositionForBody after the destination chunk finishes streaming.
local locations = {
    { id="start", key="$mcm_location_start", fallback="Starting area", x=0, y=-100 },
    { id="mines", key="$mcm_location_mines", fallback="Mines", x=0, y=650 },
    { id="hm_mines", key="$mcm_location_hm_mines", fallback="Holy Mountain after Mines", x=-200, y=1390 },
    { id="coal_pits", key="$mcm_location_coal_pits", fallback="Coal Pits", x=0, y=2150 },
    { id="fungal", key="$mcm_location_fungal", fallback="Fungal Caverns", x=-2012, y=1960 },
    { id="hm_coal", key="$mcm_location_hm_coal", fallback="Holy Mountain after Coal Pits", x=-300, y=2900 },
    { id="snowy", key="$mcm_location_snowy", fallback="Snowy Depths", x=0, y=4100 },
    { id="hm_snowy", key="$mcm_location_hm_snowy", fallback="Holy Mountain after Snowy Depths", x=-300, y=5000 },
    { id="hiisi", key="$mcm_location_hiisi", fallback="Hiisi Base", x=0, y=5850 },
    { id="hm_hiisi", key="$mcm_location_hm_hiisi", fallback="Holy Mountain after Hiisi Base", x=-300, y=6500 },
    { id="jungle", key="$mcm_location_jungle", fallback="Underground Jungle", x=0, y=7750 },
    { id="hm_jungle", key="$mcm_location_hm_jungle", fallback="Holy Mountain after Jungle", x=-300, y=8550 },
    { id="vault", key="$mcm_location_vault", fallback="The Vault", x=0, y=8580 },
    { id="hm_vault", key="$mcm_location_hm_vault", fallback="Holy Mountain after Vault", x=-300, y=10600 },
    { id="temple", key="$mcm_location_temple", fallback="Temple of the Art", x=0, y=11500 },
    { id="lab_portal", key="$mcm_location_lab_portal", fallback="Laboratory portal", x=350, y=12853 },
    { id="kolmi", key="$mcm_location_kolmi", fallback="Kolmisilma room", x=3400, y=13040 },
    { id="work", key="$mcm_location_work", fallback="The Work", x=6300, y=15155 },
    { id="tree", key="$mcm_location_tree", fallback="Giant Tree", x=-1902, y=-1405 },
    { id="orb_zero", key="$mcm_location_orb_zero", fallback="Mountain orb room", x=766, y=-1075 },
    { id="meat", key="$mcm_location_meat", fallback="Meat Realm", x=7328, y=9263 },
    { id="kivi", key="$mcm_location_kivi", fallback="Kivi chamber", x=7427, y=-4960 },
    { id="null_altar", key="$mcm_location_null_altar", fallback="Nullifying Altar", x=14000, y=7500 },
    { id="essence_laser", key="$mcm_location_essence_laser", fallback="Essence of Light", x=16000, y=-1800 },
    { id="essence_eater", key="$mcm_location_essence_eater", fallback="Essence Eater", x=12621, y=-141 },
}

local pending = nil

local function frame_number()
    if type(GameGetFrameNum) ~= "function" then return 0 end
    local ok, value = pcall(GameGetFrameNum)
    return ok and (tonumber(value) or 0) or 0
end

local function valid_entity(entity)
    if entity == nil or entity == 0 then return false end
    if type(EntityGetIsAlive) ~= "function" then return true end
    local ok, alive = pcall(EntityGetIsAlive, entity)
    return ok and alive == true
end

local function local_player(player)
    if valid_entity(player) then return player end
    if type(EntityGetWithTag) ~= "function" then return 0 end
    local ok, list = pcall(EntityGetWithTag, "player_unit")
    if ok and type(list) == "table" then
        for _, entity in ipairs(list) do if valid_entity(entity) then return entity end end
    end
    ok, list = pcall(EntityGetWithTag, "polymorphed_player")
    if ok and type(list) == "table" then
        for _, entity in ipairs(list) do if valid_entity(entity) then return entity end end
    end
    return 0
end

local function world_loaded(x, y)
    if type(DoesWorldExistAt) ~= "function" then return true end
    local ok, loaded = pcall(DoesWorldExistAt, x - 24, y - 32, x + 24, y + 20)
    return ok and loaded == true
end

local function free_position(x, y)
    if type(FindFreePositionForBody) == "function" then
        local ok, px, py = pcall(FindFreePositionForBody, x, y, 0, 0, BODY_RADIUS)
        px, py = tonumber(px), tonumber(py)
        if ok and px ~= nil and py ~= nil and world_loaded(px, py) then return px, py end
    end
    local offsets = {
        {18,0},{-18,0},{0,-20},{24,-16},{-24,-16},{36,0},{-36,0},
        {0,-40},{48,-16},{-48,-16},{0,24},{64,0},{-64,0},
    }
    for _, offset in ipairs(offsets) do
        local px, py = x + offset[1], y + offset[2]
        if world_loaded(px, py) then
            local blocked = false
            if type(RaytraceSurfaces) == "function" then
                local ok_a, hit_a = pcall(RaytraceSurfaces, px - 5, py - 10, px + 5, py + 5)
                local ok_b, hit_b = pcall(RaytraceSurfaces, px + 5, py - 10, px - 5, py + 5)
                blocked = (ok_a and hit_a == true) or (ok_b and hit_b == true)
            end
            if not blocked then return px, py end
        end
    end
    return nil, nil
end

local function clear_velocity(player)
    if type(EntityGetFirstComponentIncludingDisabled) ~= "function" then return end
    local ok, component = pcall(EntityGetFirstComponentIncludingDisabled, player, "CharacterDataComponent")
    if ok and component ~= nil and component ~= 0 and type(ComponentSetValue2) == "function" then
        pcall(ComponentSetValue2, component, "mVelocity", 0, 0)
    end
end

local function perform(player, x, y)
    player = local_player(player)
    if player == 0 or not world_loaded(x, y) then return false, "unloaded" end
    local px, py = free_position(x, y)
    if px == nil then return false, "blocked" end
    local ox, oy = service.position(player)
    clear_velocity(player)
    local ok = pcall(EntitySetTransform, player, px, py)
    if not ok then return false, "transform" end
    if type(EntityLoad) == "function" then
        pcall(EntityLoad, "data/entities/particles/teleportation_source.xml", ox, oy)
        pcall(EntityLoad, "data/entities/particles/teleportation_target.xml", px, py)
    end
    return true, "teleported"
end

function service.visible_players()
    local result, seen = {}, {}
    if type(EntityGetWithTag) ~= "function" then return result end
    -- Demand-driven only: opening another tab stops all player enumeration.
    for _, tag in ipairs({"ew_client", "ew_peer", "player_unit", "polymorphed_player"}) do
        local ok, list = pcall(EntityGetWithTag, tag)
        if ok and type(list) == "table" then
            for _, entity in ipairs(list) do
                if valid_entity(entity) and not seen[entity] then
                    seen[entity] = true
                    result[#result + 1] = entity
                end
            end
        end
    end
    return result
end

function service.position(entity)
    if not valid_entity(entity) or type(EntityGetTransform) ~= "function" then return 0, 0 end
    local ok, x, y = pcall(EntityGetTransform, entity)
    if not ok then return 0, 0 end
    return tonumber(x) or 0, tonumber(y) or 0
end

function service.teleport_position(player, x, y)
    player = local_player(player)
    x, y = tonumber(x), tonumber(y)
    if player == 0 or x == nil or y == nil then return false, "target" end
    if world_loaded(x, y) then return perform(player, x, y) end
    pending = { player=player, x=x, y=y, started=frame_number() }
    if type(GameSetCameraPos) == "function" then pcall(GameSetCameraPos, x, y) end
    return true, "streaming"
end

function service.teleport_to(entity, player)
    if not valid_entity(entity) then return false, "target" end
    local x, y = service.position(entity)
    return service.teleport_position(player, x + 18, y)
end

function service.locations()
    local result = {}
    for index, location in ipairs(locations) do result[index] = location end
    return result
end

function service.teleport_location(location_id, player)
    for _, location in ipairs(locations) do
        if location.id == tostring(location_id or "") then
            return service.teleport_position(player, location.x, location.y)
        end
    end
    return false, "location"
end

local function set_outbox(base, sequence, value)
    GlobalsSetValue(base, tostring(value))
    GlobalsSetValue(base .. "_" .. tostring(sequence), tostring(value))
end

function service.bring_to_me(entity, player)
    player = local_player(player)
    if player == 0 or not valid_entity(entity) or type(GlobalsGetValue) ~= "function"
        or type(GlobalsSetValue) ~= "function"
    then
        return false, "network"
    end
    local peer_id = type(EntityGetName) == "function" and tostring(EntityGetName(entity) or "") or ""
    local tx, ty = service.position(entity)
    local x, y = service.position(player)
    local sequence = (tonumber(GlobalsGetValue(BRING_SEQ, "0")) or 0) + 1
    set_outbox(BRING_PEER, sequence, peer_id)
    set_outbox(BRING_TARGET_X, sequence, tx)
    set_outbox(BRING_TARGET_Y, sequence, ty)
    set_outbox(BRING_DEST_X, sequence, x + 18)
    set_outbox(BRING_DEST_Y, sequence, y)
    GlobalsSetValue(BRING_SEQ, tostring(sequence))
    return true, "queued"
end

function service.update()
    if pending == nil then return false, "idle" end
    if not valid_entity(pending.player) then pending = nil; return false, "player" end
    if frame_number() - pending.started > STREAM_TIMEOUT_FRAMES then
        pending = nil
        return false, "timeout"
    end
    if not world_loaded(pending.x, pending.y) then
        if type(GameSetCameraPos) == "function" then pcall(GameSetCameraPos, pending.x, pending.y) end
        return false, "streaming"
    end
    local request = pending
    pending = nil
    return perform(request.player, request.x, request.y)
end

function service.has_pending_teleport() return pending ~= nil end

METAMORPH_CREATIVE_MENU_PLAYER_TOOLS = service
return service
