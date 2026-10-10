-- Run the real vanilla + Entangled Worlds Sampo pickup entrypoint from an external VM.
-- This is intentionally not a reimplementation of Kolmi phases. The stock script owns
-- component activation, boss flags, protection removal and every subsequent combat/death
-- coroutine transition.
local controller = GetUpdatedEntityID()
local SAMPO_PICKUP = "data/entities/animals/boss_centipede/sampo_pickup.lua"
local STATUS = "mcm25_kolmi_encounter_status_v1"
local VERIFY = "mods/metamorph_creative_menu/files/features/creatures/kolmi_combat_verify.lua"

local function controller_var(name)
    for _, storage in ipairs(EntityGetComponentIncludingDisabled(controller, "VariableStorageComponent") or {}) do
        if ComponentGetValue2(storage, "name") == name then
            return tonumber(ComponentGetValue2(storage, "value_int")) or 0
        end
    end
    return 0
end

local function alive(entity)
    return entity ~= 0 and EntityGetIsAlive(entity) == true
end

local boss = controller_var("mcm_kolmi_boss_id_v3")
local reference = controller_var("mcm_kolmi_reference_id_v3")
if not alive(boss) or not alive(reference) then
    if type(GlobalsSetValue) == "function" then GlobalsSetValue(STATUS, "failed:missing_boss_or_reference") end
    EntityKill(controller)
    return
end

local bx, by = EntityGetTransform(boss)
local old_get_with_tag = EntityGetWithTag

local function nearest_player()
    local players = old_get_with_tag("player_unit") or {}
    local best, best_d = nil, nil
    for _, player in ipairs(players) do
        if EntityGetIsAlive(player) then
            local px, py = EntityGetTransform(player)
            local dx, dy = (tonumber(px) or 0) - (tonumber(bx) or 0), (tonumber(py) or 0) - (tonumber(by) or 0)
            local d = dx * dx + dy * dy
            if best_d == nil or d < best_d then best, best_d = player, d end
        end
    end
    return best
end

local player = nearest_player()
if player == nil then
    if type(GlobalsSetValue) == "function" then GlobalsSetValue(STATUS, "failed:no_player") end
    EntityKill(controller)
    return
end

-- During the one synchronous vanilla item_pickup call, provide the exact encounter roots
-- it would see in a real boss arena. This prevents an unrelated natural Sampo/Kolmi or a
-- second world's reference point from being activated accidentally. The boss' own update
-- VM is untouched and receives the engine EntityGetWithTag afterwards.
EntityGetWithTag = function(tag)
    if tag == "sampo_or_boss" then return { boss } end
    if tag == "reference" then return { reference } end
    if tag == "player_unit" then return { player } end
    return old_get_with_tag(tag)
end

local ok, failure = pcall(function()
    dofile(SAMPO_PICKUP) -- includes EW 1.6.3's ModLuaFileAppend wrapper in multiplayer
    if type(item_pickup) ~= "function" then error("sampo item_pickup unavailable") end
    -- The controller sits at the same +80 Y offset as the authored Sampo. The function
    -- uses this entity only for pickup position; it does not require an ItemComponent.
    item_pickup(controller, player, "$item_mcguffin")
end)

EntityGetWithTag = old_get_with_tag

if ok then
    if type(EntityAddTag) == "function" then EntityAddTag(boss, "mcm_creative_kolmi_encounter_started_v3") end
    if type(GlobalsSetValue) == "function" then GlobalsSetValue(STATUS, "started_via_stock_sampo_pickup") end
    -- Keep the external controller alive only long enough to verify that the authored
    -- enable_coroutines component really entered init_boss().  The verifier never owns
    -- combat; it either observes success or restarts the same stock VM once.
    if type(EntityAddComponent2) == "function" then
        EntityAddComponent2(controller, "VariableStorageComponent", {
            name = "mcm_kolmi_verify_start_frame_v1",
            value_int = GameGetFrameNum(),
        })
        EntityAddComponent2(controller, "LuaComponent", {
            script_source_file = VERIFY,
            execute_on_added = false,
            execute_every_n_frame = 1,
            remove_after_executed = false,
        })
        return
    end
    EntityKill(controller)
else
    if type(GlobalsSetValue) == "function" then GlobalsSetValue(STATUS, "failed:" .. tostring(failure)) end
    if type(GamePrintImportant) == "function" then
        local title = "$mcm_kolmi_encounter_failed"
        local details = "$mcm_kolmi_encounter_failed_desc"
        if type(GameTextGetTranslatedOrNot) == "function" then
            local ok_title, translated_title = pcall(GameTextGetTranslatedOrNot, title)
            if ok_title and translated_title ~= title then title = translated_title end
            local ok_details, translated_details = pcall(GameTextGetTranslatedOrNot, details)
            if ok_details and translated_details ~= details then details = translated_details end
        end
        GamePrintImportant(title, details .. ": " .. tostring(failure))
    end
    EntityKill(controller)
end
