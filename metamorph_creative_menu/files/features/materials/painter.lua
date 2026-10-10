if type(METAMORPH_CREATIVE_MENU_MATERIAL_PAINTER) == "table" then return METAMORPH_CREATIVE_MENU_MATERIAL_PAINTER end

local painter = {}

local input_guard = dofile("mods/metamorph_creative_menu/files/platform/noita/input_guard.lua")
local action_bindings = dofile("mods/metamorph_creative_menu/files/platform/noita/action_bindings.lua")
local grid_backend = dofile("mods/metamorph_creative_menu/files/platform/noita/material_grid.lua")
local ew_material_sync = dofile("mods/metamorph_creative_menu/files/integrations/ew/material_paint_sync.lua")

local BRUSHES = {
    { radius=0, file="mods/metamorph_creative_menu/files/features/materials/brushes/brush_r0.png" },
    { radius=1, file="mods/metamorph_creative_menu/files/features/materials/brushes/brush_r1.png" },
    { radius=2, file="mods/metamorph_creative_menu/files/features/materials/brushes/brush_r2.png" },
    { radius=4, file="mods/metamorph_creative_menu/files/features/materials/brushes/brush_r4.png" },
    { radius=6, file="mods/metamorph_creative_menu/files/features/materials/brushes/brush_r6.png" },
}
local MATERIAL_MASK_COLOR = "ff5ac75a"
local MAX_CELLS_PER_FRAME = 1400
-- Eight stamps cover normal player/camera movement even with the one-pixel brush while
-- bounding proxy messages and relay components during a fast cursor jump.
local MAX_STAMPS_PER_FRAME = 8
local REPEAT_SYNC_INTERVAL = 6
local MIDDLE_MOUSE_FALLBACK = 3

local selected_material = "water"
local selected_force_scene = false
local brush_index = 3
local armed = false
local world_mode_seen = false
local last_x, last_y = nil, nil
local last_published_x, last_published_y = nil, nil
local last_published_frame = -100000
local brush_offsets = {}
local paint_button = nil
local last_runtime_error_frame = -100000

local function translated(key, fallback)
    if type(GameTextGetTranslatedOrNot) == "function" then
        local ok, value = pcall(GameTextGetTranslatedOrNot, key)
        if ok and type(value) == "string" and value ~= "" and value ~= key then return value end
    end
    return fallback
end

local function frame_number()
    if type(GameGetFrameNum) ~= "function" then return 0 end
    local ok, value = pcall(GameGetFrameNum)
    return ok and (tonumber(value) or 0) or 0
end

local function resolve_paint_button()
    if paint_button ~= nil then return paint_button end
    if type(Mouse_middle) == "number" then paint_button = Mouse_middle; return paint_button end
    if type(MOUSE_MIDDLE) == "number" then paint_button = MOUSE_MIDDLE; return paint_button end
    if type(ModTextFileGetContent) == "function" then
        local ok, text = pcall(ModTextFileGetContent, "data/scripts/debug/keycodes.lua")
        if ok and type(text) == "string" then
            local value = text:match("Mouse_middle%s*=%s*(%d+)") or text:match("MOUSE_MIDDLE%s*=%s*(%d+)")
            if value ~= nil then paint_button = tonumber(value) end
        end
    end
    paint_button = paint_button or MIDDLE_MOUSE_FALLBACK
    return paint_button
end

local function mouse_down()
    return action_bindings.is_down("paint_draw")
end

local function mouse_world()
    if type(DEBUG_GetMouseWorld) ~= "function" then return nil, nil end
    local ok, x, y = pcall(DEBUG_GetMouseWorld)
    if not ok then return nil, nil end
    x, y = tonumber(x), tonumber(y)
    if x == nil or y == nil then return nil, nil end
    return math.floor(x + 0.5), math.floor(y + 0.5)
end

local function inventory_open()
    if type(GameIsInventoryOpen) ~= "function" then return false end
    local ok, value = pcall(GameIsInventoryOpen)
    return ok and value == true
end

local function valid_player(player_entity_id)
    player_entity_id = tonumber(player_entity_id) or 0
    if player_entity_id == 0 then return false end
    if type(EntityGetIsAlive) ~= "function" then return true end
    local ok, alive = pcall(EntityGetIsAlive, player_entity_id)
    return ok and alive == true
end

local function current_brush() return BRUSHES[brush_index] or BRUSHES[1] end
local function current_radius() return current_brush().radius end

local function offsets_for_radius(radius)
    local cached = brush_offsets[radius]
    if cached ~= nil then return cached end
    local values = {}
    for dy = -radius, radius do
        for dx = -radius, radius do
            if dx * dx + dy * dy <= radius * radius then values[#values + 1] = { dx, dy } end
        end
    end
    if #values == 0 then values[1] = { 0, 0 } end
    brush_offsets[radius] = values
    return values
end

local function reset_stroke()
    last_x, last_y = nil, nil
    last_published_x, last_published_y = nil, nil
    last_published_frame = -100000
end

local function runtime_failure(reason)
    local frame = frame_number()
    if frame - last_runtime_error_frame >= 300 then
        last_runtime_error_frame = frame
        if type(GamePrint) == "function" then
            pcall(GamePrint, translated("$mcm_material_stopped", "Material brush stopped")
                .. ": " .. tostring(reason or "backend"))
        end
    end
    painter.set_enabled(false)
end

local function stamp(context, x, y, budget)
    local brush = current_brush()
    local offsets = offsets_for_radius(brush.radius)
    if context.mode == "solid_scene" then
        if budget < #offsets then return false, 0, nil, false end
        local ok, reason = grid_backend.paint_solid_scene_prepared(context, brush.file,
            x - brush.radius, y - brush.radius, MATERIAL_MASK_COLOR)
        if ok then return true, #offsets, nil, true end
        if reason == "unloaded" then return false, #offsets, nil, false end
        return false, #offsets, reason, true
    end

    local painted, used = false, 0
    local needs_scene_fallback = false
    local attempted = false
    for _, offset in ipairs(offsets) do
        if used >= budget then break end
        local ok, reason = grid_backend.paint_cell_prepared(context, x + offset[1], y + offset[2])
        used = used + 1
        if ok then
            painted = true
            attempted = true
        elseif reason == "construct" then
            -- Some valid material definitions cannot be constructed at particular
            -- texture coordinates. PixelScene placement is Noita's general authored
            -- fallback and works for dynamic materials too.
            needs_scene_fallback = true
            attempted = true
        elseif reason ~= "unloaded" and reason ~= "construct" then
            return painted, used, reason, true
        end
    end
    if needs_scene_fallback and budget >= #offsets
        and type(grid_backend.paint_scene_prepared) == "function"
    then
        local fallback_ok, fallback_reason = grid_backend.paint_scene_prepared(context,
            brush.file, x - brush.radius, y - brush.radius, MATERIAL_MASK_COLOR)
        if fallback_ok then return true, math.max(used, #offsets), nil, true end
        if fallback_reason ~= "unloaded" then return painted, used, fallback_reason, true end
    end
    return painted, used, nil, attempted
end


function painter.set_material(material_name, options)
    material_name = tostring(material_name or "")
    if grid_backend.material_id(material_name) == nil then return false, "invalid_material" end
    options = type(options) == "table" and options or {}
    selected_material = material_name
    -- The catalog's CellFactory_GetAllSolids membership is the strongest semantic hint
    -- available from the public API. Keep native CellData inspection as a fallback so
    -- callers that select a material by id directly still work.
    selected_force_scene = options.solid == true
    reset_stroke()
    return true
end

function painter.get_material()
    if grid_backend.material_id(selected_material) ~= nil then return selected_material end
    return nil
end

function painter.material_color(material_name)
    if type(grid_backend.material_color) ~= "function" then return nil end
    return grid_backend.material_color(material_name)
end

function painter.brush_radius() return current_radius() end
function painter.brush_diameter() return current_radius() * 2 + 1 end

function painter.set_brush_index(index)
    index = math.floor(tonumber(index) or brush_index)
    brush_index = math.max(1, math.min(#BRUSHES, index))
    reset_stroke()
    return painter.brush_diameter()
end

function painter.adjust_brush(delta) return painter.set_brush_index(brush_index + (tonumber(delta) or 0)) end
function painter.paint_button()
    local value = action_bindings.get("paint_draw")
    local mouse = type(value) == "string" and string.match(value, "Mouse:(%-?%d+)$") or nil
    return tonumber(mouse) or resolve_paint_button()
end

function painter.set_enabled(enabled)
    enabled = enabled == true
    if enabled then
        if painter.get_material() == nil then return false, "invalid_material" end
        local ok, reason = grid_backend.status()
        if not ok then return false, reason or "backend" end
    end
    armed = enabled
    world_mode_seen = false
    reset_stroke()
    return armed, armed and "enabled" or "disabled"
end

function painter.is_enabled() return armed == true end
function painter.reset_stroke() reset_stroke() end

-- Called from OnWorldPreUpdate. The default middle-mouse paint binding avoids competing
-- with Noita's native primary/secondary fire. Liquids/powders/gases/fires use direct
-- cells; textured solids use a tiny PixelScene mask because construct_cell may
-- legitimately return nil for solid texture holes at a world coordinate.
function painter.update(player_entity_id)
    if not armed then reset_stroke(); return false, "inactive" end
    if not valid_player(player_entity_id) then painter.set_enabled(false); return false, "player" end
    if inventory_open() then
        reset_stroke()
        if world_mode_seen then painter.set_enabled(false); return false, "menu_reopened" end
        return false, "armed_in_menu"
    end
    if type(input_guard.actions_allowed) == "function" and input_guard.actions_allowed() ~= true then
        reset_stroke(); return false, "input_blocked"
    end

    world_mode_seen = true
    if not mouse_down() then reset_stroke(); return false, "idle" end

    local material_name = painter.get_material()
    if material_name == nil then runtime_failure("invalid material"); return false, "material" end
    local x, y = mouse_world()
    if x == nil or y == nil then reset_stroke(); return false, "mouse" end
    local paint_context, context_reason = grid_backend.begin_paint(material_name, { force_scene=selected_force_scene })
    if paint_context == nil then runtime_failure(context_reason or "grid backend"); return false, context_reason or "backend" end

    local frame = frame_number()
    local radius = current_radius()
    local spacing = math.max(1, math.floor(radius * 0.75 + 1))
    local from_x, from_y = last_x or x, last_y or y
    local dx, dy = x - from_x, y - from_y
    local distance = math.sqrt(dx * dx + dy * dy)
    local needed_steps = math.max(1, math.ceil(distance / spacing))
    local steps = math.min(MAX_STAMPS_PER_FRAME, needed_steps)

    local budget, any = MAX_CELLS_PER_FRAME, false
    local published_points = {}
    local progress_x, progress_y = from_x, from_y
    for step = 1, steps do
        if budget <= 0 then break end
        -- If a cursor jump exceeds the bounded per-frame budget, continue from the last
        -- processed point next frame instead of skipping the unsent middle of the line.
        local t = step / needed_steps
        local sx = math.floor(from_x + dx * t + 0.5)
        local sy = math.floor(from_y + dy * t + 0.5)
        local painted, used, fatal, attempted = stamp(paint_context, sx, sy, budget)
        budget = budget - used
        any = painted or any
        progress_x, progress_y = sx, sy
        -- Publish the requested stamp even when a valid material could not be
        -- constructed in this exact texture cell. The stock-EW relay has its own
        -- Pixel/particle creation path and must receive the user's intent as well.
        if attempted and (sx ~= last_published_x or sy ~= last_published_y
            or frame - last_published_frame >= REPEAT_SYNC_INTERVAL)
        then
            published_points[#published_points + 1] = { sx, sy }
            last_published_x, last_published_y = sx, sy
            last_published_frame = frame
        end
        if fatal ~= nil then runtime_failure(fatal); return any, fatal end
    end
    if #published_points > 0 and type(ew_material_sync.publish_batch) == "function" then
        -- Publish the backend's actual terrain mode, not just the catalog hint. CellData
        -- can classify authored/static terrain as scene-only even when a caller selected
        -- the material by id and did not pass the public SOLIDS hint.
        ew_material_sync.publish_batch(material_name, paint_context.mode == "solid_scene",
            brush_index, published_points)
    end
    if steps >= needed_steps then last_x, last_y = x, y
    else last_x, last_y = progress_x, progress_y end
    return any, any and "painted" or "world"
end

METAMORPH_CREATIVE_MENU_MATERIAL_PAINTER = painter
return painter
