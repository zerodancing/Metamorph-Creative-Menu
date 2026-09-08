if type(METAMORPH_CREATIVE_MENU_SPELL_SLOT_SETTLER) == "table" then
    return METAMORPH_CREATIVE_MENU_SPELL_SLOT_SETTLER
end

local slot_settler = {}
local pending = {}

local function valid(component_id)
    return component_id ~= nil and component_id ~= 0
end

local function current_frame()
    if type(GameGetFrameNum) ~= "function" then return 0 end
    local ok, value = pcall(GameGetFrameNum)
    return ok and math.floor(tonumber(value) or 0) or 0
end

local function slot(entity_id)
    if entity_id == nil or entity_id == 0 or EntityGetIsAlive(entity_id) ~= true then return nil end
    local item = EntityGetFirstComponentIncludingDisabled(entity_id, "ItemComponent")
    if not valid(item) then return nil end
    local ok, x, y = pcall(ComponentGetValue2, item, "inventory_slot")
    if not ok then return nil end
    return item, tonumber(x), tonumber(y) or 0
end

local function report(label, reason)
    if type(METAMORPH_CREATIVE_MENU_DIAGNOSTICS_CAPTURE) == "function" then
        pcall(METAMORPH_CREATIVE_MENU_DIAGNOSTICS_CAPTURE,
            "spells.slot_settle", tostring(label or "drag") .. ":" .. tostring(reason or "failed"))
    end
end

local function inspect(commit)
    for _, expected in ipairs(commit.specs) do
        local item, x, y = slot(expected.entity)
        if item == nil then return false, "entity_missing" end
        local parent = type(EntityGetParent) == "function" and EntityGetParent(expected.entity) or expected.parent
        if tonumber(parent) ~= tonumber(expected.parent) then return false, "parent_changed" end
        if x ~= expected.x or y ~= expected.y then return false, "slot_changed" end
    end
    return true, "exact"
end

local function has_foreign_collision(commit)
    local tracked = {}
    for _, expected in ipairs(commit.specs) do tracked[expected.entity] = true end
    local scanned = {}
    for _, expected in ipairs(commit.specs) do
        local parent = expected.parent
        if not scanned[parent] then
            scanned[parent] = true
            for _, child in ipairs(EntityGetAllChildren(parent) or {}) do
                if not tracked[child] then
                    local _, x, y = slot(child)
                    if x ~= nil then
                        for _, target in ipairs(commit.specs) do
                            if target.parent == parent and target.x == x and target.y == y then
                                return true
                            end
                        end
                    end
                end
            end
        end
    end
    return false
end

local function force_refresh(player)
    local inventory = EntityGetFirstComponentIncludingDisabled(player, "Inventory2Component")
    if valid(inventory) then pcall(ComponentSetValue2, inventory, "mForceRefresh", true) end
end

local function reapply(commit)
    -- A parent change is external state and must never be "fixed" by MCM. Slot drift inside
    -- the parent that MCM just committed is ours to repair, provided an unrelated card has
    -- not moved into the requested destination in the meantime.
    for _, expected in ipairs(commit.specs) do
        if type(EntityGetParent) == "function"
            and tonumber(EntityGetParent(expected.entity)) ~= tonumber(expected.parent)
        then
            return false, "parent_changed"
        end
    end
    if has_foreign_collision(commit) then return false, "foreign_occupant" end

    local full_assignments = {}
    local direct_specs = {}
    for _, expected in ipairs(commit.specs) do
        local parent_name = type(EntityGetName) == "function" and EntityGetName(expected.parent) or ""
        local root = type(EntityGetRootEntity) == "function" and EntityGetRootEntity(expected.parent) or commit.player
        if parent_name == "inventory_full" and tonumber(root) == tonumber(commit.player) then
            full_assignments[#full_assignments+1] = {entity=expected.entity,x=expected.x,y=expected.y}
        else
            direct_specs[#direct_specs+1] = expected
        end
    end

    -- Never repair a delayed full-inventory packing pass with EntityAddChild/uid rewrites.
    -- That was the old failure mode: the ECS fields looked correct while Noita's private
    -- InventoryComponent.items order still disagreed. Re-run the engine-authoritative exact
    -- pickup transaction instead, so delayed repairs use the same semantics as the original
    -- drag from a wand or another inventory cell.
    if #full_assignments > 0 then
        local api = METAMORPH_CREATIVE_MENU_INVENTORY_SLOTS
        if type(api) ~= "table" or type(api.rebuild_full_exact) ~= "function" then
            return false, "exact_inventory_api_missing"
        end
        local ok, reason, rebuilt_specs, replacements = api.rebuild_full_exact(commit.player, full_assignments)
        if not ok then return false, reason or "inventory_repair_failed" end
        -- Full-build exact repair may intentionally rehydrate an already-registered card
        -- into a fresh entity id. Carry those replacement ids forward in the pending
        -- expectation; otherwise the next inspect would incorrectly report entity_missing
        -- even though the logical spell was repaired into the requested native cell.
        if type(replacements) == "table" then
            for _, expected in ipairs(commit.specs) do
                local replacement = replacements[expected.entity]
                if replacement ~= nil and replacement ~= 0 then expected.entity = replacement end
            end
        elseif type(rebuilt_specs) == "table" then
            for _, rebuilt in ipairs(rebuilt_specs) do
                local old = tonumber(rebuilt.replaces) or 0
                if old ~= 0 then
                    for _, expected in ipairs(commit.specs) do
                        if expected.entity == old then expected.entity = rebuilt.entity; break end
                    end
                end
            end
        end
    end

    -- Wand children do not use InventoryComponent.items; their slot is authored directly by
    -- ItemComponent.inventory_slot. Repair only that field and leave entity registration and
    -- runtime state untouched.
    for _, expected in ipairs(direct_specs) do
        local item = select(1, slot(expected.entity))
        if item == nil then return false, "entity_missing" end
        local wrote = pcall(ComponentSetValue2, item, "inventory_slot", expected.x, expected.y)
        if not wrote then return false, "final_write_failed" end
    end

    local exact, reason = inspect(commit)
    if not exact then return false, reason or "readback_failed" end
    force_refresh(commit.player)
    if type(commit.on_repair) == "function" then pcall(commit.on_repair) end
    return true, "repaired"
end

function slot_settler.schedule(player_entity_id, label, specs, on_repair)
    local normalized, entities = {}, {}
    for _, spec in ipairs(type(specs) == "table" and specs or {}) do
        local entity = math.floor(tonumber(spec.entity) or 0)
        local parent = math.floor(tonumber(spec.parent) or 0)
        local x, y = tonumber(spec.x), tonumber(spec.y)
        if entity ~= 0 and parent ~= 0 and x ~= nil and y ~= nil and not entities[entity] then
            entities[entity] = true
            normalized[#normalized + 1] = {
                entity=entity, parent=parent,
                x=math.floor(x), y=math.floor(y),
            }
        end
    end
    if #normalized == 0 then return false end

    -- A newer drag involving the same card supersedes the older expectation. Full-build
    -- exact inventory moves may also rehydrate a card into a new entity id, so an older
    -- expectation that points at a deliberately retired entity is stale as soon as the
    -- next successful transaction is scheduled and must not become a false diagnostic.
    for index = #pending, 1, -1 do
        local stale = false
        for _, old in ipairs(pending[index].specs) do
            if entities[old.entity] or (type(EntityGetIsAlive) == "function" and EntityGetIsAlive(old.entity) ~= true) then
                stale = true
                break
            end
        end
        if stale then table.remove(pending, index) end
    end
    pending[#pending + 1] = {
        player=player_entity_id, label=tostring(label or "drag"), specs=normalized,
        frame=current_frame(), attempts=0, on_repair=on_repair,
    }
    return true
end

function slot_settler.update()
    local frame = current_frame()
    local repaired, failed = 0, 0
    for index = #pending, 1, -1 do
        local commit = pending[index]
        if frame > commit.frame then
            local exact, reason = inspect(commit)
            if exact then
                table.remove(pending, index)
            elseif commit.attempts < 3 and reason == "slot_changed" then
                local ok, repair_reason = reapply(commit)
                commit.attempts = commit.attempts + 1
                if ok then
                    repaired = repaired + 1
                    -- Keep the expectation alive for two more update boundaries. Native
                    -- InventoryGui can perform a delayed packing pass after mForceRefresh.
                    commit.frame = frame
                else
                    report(commit.label, repair_reason)
                    table.remove(pending, index)
                    failed = failed + 1
                end
            else
                report(commit.label, reason)
                table.remove(pending, index)
                failed = failed + 1
            end
        end
    end
    return repaired, failed
end

function slot_settler.pending_count() return #pending end
function slot_settler.reset() pending = {} end

METAMORPH_CREATIVE_MENU_SPELL_SLOT_SETTLER = slot_settler
return slot_settler
