if type(METAMORPH_CREATIVE_MENU_PLAYER_LOCATOR) == "table" then return METAMORPH_CREATIVE_MENU_PLAYER_LOCATOR end

local player_locator = {}

local bridge_api = dofile("mods/metamorph_creative_menu/files/platform/noita/patcher_bridge.lua")

local function alive(entity)
    return entity ~= nil and entity ~= 0 and EntityGetIsAlive(entity)
end

local function acceptable(entity, options)
    if not alive(entity) then return false end
    -- Both tags mean "not the local authoritative player" in EW. Reject them by
    -- default instead of letting a companion/proxy with player_unit win a fallback
    -- lookup. Callers can opt in only for a very specific diagnostic use-case.
    if EntityHasTag(entity, "ew_client") then return false end
    if EntityHasTag(entity, "ew_notplayer") and not (options ~= nil and options.allow_notplayer == true) then return false end
    if options ~= nil and options.require_inventory == true then
        local inventory = EntityGetFirstComponentIncludingDisabled(entity, "Inventory2Component")
        if inventory == nil or inventory == 0 then return false end
    end
    return true
end

local function bridge_player(options)
    local bridge = bridge_api.get()
    if bridge == nil or type(bridge.GetPlayerEntity) ~= "function" then return 0 end
    local ok, entity = pcall(bridge.GetPlayerEntity)
    if ok and acceptable(entity, options) then return entity end
    return 0
end

function player_locator.get(options)
    options = type(options) == "table" and options or {}

    -- NoitaPatcher is authoritative when it is already available. Importantly this
    -- lookup never bootstraps NoitaPatcher by itself; ordinary menu rendering must
    -- not change mod load order just to discover the player.
    local from_bridge = bridge_player(options)
    if from_bridge ~= 0 then return from_bridge end

    -- During polymorph the engine may remove/alter the normal player tag. Prefer the
    -- explicit polymorphed tag before falling back to player_unit.
    for _, tag in ipairs({ "polymorphed_player", "player_unit" }) do
        for _, entity in ipairs(EntityGetWithTag(tag) or {}) do
            if acceptable(entity, options) then return entity end
        end
    end
    return 0
end

function player_locator.get_human()
    for _, entity in ipairs(EntityGetWithTag("player_unit") or {}) do
        if acceptable(entity, { require_inventory = true })
            and not EntityHasTag(entity, "polymorphed_player")
        then
            return entity
        end
    end
    return 0
end

function player_locator.is_local(entity)
    return entity ~= nil and entity ~= 0 and player_locator.get() == entity
end

METAMORPH_CREATIVE_MENU_PLAYER_LOCATOR = player_locator
return player_locator
