if type(METAMORPH_CREATIVE_MENU_SPELL_FACTORY) == "table" then return METAMORPH_CREATIVE_MENU_SPELL_FACTORY end

local spell_factory = {}
local spell_catalog = dofile("mods/metamorph_creative_menu/files/features/spells/catalog.lua")

local function unlock_flag(action_id)
    if not spell_catalog.load() then return nil end
    local actions = spell_catalog.by_id()
    local action = type(actions) == "table" and actions[action_id] or nil
    local flag = type(action) == "table" and action.spawn_requires_flag or nil
    return type(flag) == "string" and flag ~= "" and flag or nil
end

-- CreateItemActionEntity can set some vanilla persistent unlock flags as a side effect.
-- A creative editor should not silently change metagame progression merely because a
-- card was previewed/inserted, so restore only a flag that this exact creation added.
function spell_factory.create(action_id)
    if type(action_id) ~= "string" or action_id == "" then return 0, "invalid_action" end
    local flag = unlock_flag(action_id)
    local had_flag = nil
    if flag ~= nil and type(GameHasFlagPersistent) == "function" then
        local ok, value = pcall(GameHasFlagPersistent, flag)
        if ok then had_flag = value == true end
    end

    local entity_id = CreateItemActionEntity(action_id) or 0
    if entity_id == 0 then return 0, "create_failed" end

    if flag ~= nil and had_flag == false and type(GameHasFlagPersistent) == "function"
        and type(RemoveFlagPersistent) == "function"
    then
        local ok, now_has = pcall(GameHasFlagPersistent, flag)
        if ok and now_has == true then pcall(RemoveFlagPersistent, flag) end
    end
    return entity_id, "ok"
end

METAMORPH_CREATIVE_MENU_SPELL_FACTORY = spell_factory
return spell_factory
