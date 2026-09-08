-- Runtime traits, not a list of vanilla filenames: inherited/custom mod XML works too.
-- Kolmisilma retains her separately tested TEST 31 encounter lifecycle.
local policy = {}
local KOLMI = "data/entities/animals/boss_centipede/boss_centipede.xml"
policy.EVENTS = "mcm32_boss_death_events_v1"
policy.EVENT_GID = "mcm32_boss_death_gid_v1_"

function policy.eligible(entity)
    if not entity or entity == 0 or EntityGetIsAlive(entity) ~= true then return false end
    for _, tag in ipairs({"player_unit", "polymorphed_player", "ew_peer", "ew_notplayer",
        "ew_no_enemy_sync"}) do
        if EntityHasTag(entity, tag) then return false end
    end
    if EntityHasTag(entity, "boss_centipede") and EntityGetFilename(entity) == KOLMI then return false end
    return EntityGetRootEntity(entity) == entity
end

local function boss_component(entity)
    -- LimbBossComponent alone also occurs on ordinary lukki and leggy chests.
    for _, kind in ipairs({"BossHealthBarComponent", "BossDragonComponent"}) do
        if EntityGetFirstComponentIncludingDisabled(entity, kind) then return true end
    end
    return false
end

local function child_boss_component(entity)
    for _, child in ipairs(EntityGetAllChildren(entity) or {}) do
        if not EntityHasTag(child, "player_unit") and not EntityHasTag(child, "polymorphed_player") then
            if boss_component(child) or child_boss_component(child) then return true end
        end
    end
    return false
end

function policy.is_boss(entity)
    if not policy.eligible(entity) then return false end
    for _, tag in ipairs({"boss", "miniboss", "mcm_boss"}) do
        if EntityHasTag(entity, tag) then return true end
    end
    if boss_component(entity) then return true end
    local damage = EntityGetFirstComponentIncludingDisabled(entity, "DamageModelComponent")
    -- These also cover custom bosses with their own HUD. Keepalive+damage roots use
    -- the same global DES retention path even when no standard boss tag was provided.
    if damage ~= nil and (ComponentGetValue2(damage, "wait_for_kill_flag_on_death") == true
        or EntityGetFirstComponentIncludingDisabled(entity, "StreamingKeepAliveComponent") ~= nil)
    then return true end
    -- Some mods put the HUD/controller on a child of the actual DES root. Do not
    -- inspect every projectile tree: only actors or explicit EW synchronization roots.
    return (damage ~= nil or EntityHasTag(entity, "enemy") or EntityHasTag(entity, "ew_synced"))
        and child_boss_component(entity)
end

function policy.identity(entity)
    for _, var in ipairs(EntityGetComponentIncludingDisabled(entity, "VariableStorageComponent") or {}) do
        if ComponentGetValue2(var, "name") == "ew_gid_lid" then
            local gid = ComponentGetValue2(var, "value_string")
            if type(gid) == "string" and gid:match("^%d+$") then
                return gid, ComponentGetValue2(var, "value_bool") == true
            end
        end
    end
end

return policy
