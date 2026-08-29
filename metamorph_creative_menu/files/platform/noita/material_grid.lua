if type(METAMORPH_CREATIVE_MENU_MATERIAL_GRID_BACKEND) == "table" then
    return METAMORPH_CREATIVE_MENU_MATERIAL_GRID_BACKEND
end

local backend = {}

local patcher_bridge = dofile("mods/metamorph_creative_menu/files/platform/noita/patcher_bridge.lua")

local world_ffi = nil
local init_failed_frame = -100000
local INIT_RETRY_FRAMES = 120
local CELL_TYPE_SOLID = 3

local function frame_number()
    if type(GameGetFrameNum) ~= "function" then return 0 end
    local ok, value = pcall(GameGetFrameNum)
    return ok and (tonumber(value) or 0) or 0
end

local function ensure_world_ffi()
    if type(world_ffi) == "table" then return world_ffi end
    local frame = frame_number()
    if frame - init_failed_frame < INIT_RETRY_FRAMES then return nil, "retry" end
    local np = patcher_bridge.get({ bootstrap_if_installed=true, capability="GetWorldInfo" })
    if type(np) ~= "table" then init_failed_frame = frame; return nil, "noitapatcher" end
    local ok, module = pcall(require, "noitapatcher.nsew.world_ffi")
    if not ok or type(module) ~= "table" then init_failed_frame = frame; return nil, "world_ffi" end
    world_ffi = module
    return world_ffi
end

local function material_id(material_name)
    if type(material_name) ~= "string" or material_name == "" or type(CellFactory_GetType) ~= "function" then return nil end
    local ok, value = pcall(CellFactory_GetType, material_name)
    value = ok and tonumber(value) or nil
    if value == nil or value < 0 then return nil end
    return math.floor(value)
end

function backend.status()
    local ffi_world, reason = ensure_world_ffi()
    if ffi_world == nil then return false, reason end
    return true, "ready"
end

function backend.material_id(material_name) return material_id(material_name) end

function backend.material_color(material_name)
    local id = material_id(material_name)
    if id == nil then return nil end
    local ffi_world = ensure_world_ffi()
    if type(ffi_world) ~= "table" then return nil end
    local ok, packed = pcall(function()
        local ptr = ffi_world.get_material_ptr(id)
        if ptr == nil then return nil end
        local value = tonumber(ptr.default_primary_colour)
        if value == nil or value == 0 then value = tonumber(ptr.wang_color) end
        return value
    end)
    packed = ok and tonumber(packed) or nil
    if packed == nil then return nil end
    packed = packed % 4294967296
    local b = packed % 256
    local g = math.floor(packed / 256) % 256
    local r = math.floor(packed / 65536) % 256
    return { r / 255, g / 255, b / 255, 0.96 }
end

function backend.begin_paint(material_name, options)
    options = type(options) == "table" and options or {}
    local id = material_id(material_name)
    if id == nil then return nil, "material" end
    local ffi_world, reason = ensure_world_ffi()
    if ffi_world == nil then return nil, reason end
    local ok, context, detail = pcall(function()
        local grid_world = ffi_world.get_grid_world()
        if grid_world == nil then return nil, "grid_world" end
        local chunk_map = grid_world.vtable.get_chunk_map(grid_world)
        if chunk_map == nil then return nil, "chunk_map" end
        local ptr = nil
        local cell_type = 0
        local liquid_static = false
        local solid_static_type = 0
        local platform_type = 0
        local cell_holes_in_texture = false
        if id ~= 0 then
            ptr = ffi_world.get_material_ptr(id)
            if ptr ~= nil then
                local ok_fields, fields = pcall(function()
                    return {
                        cell_type=tonumber(ptr.cell_type),
                        liquid_static=ptr.liquid_static == true,
                        solid_static_type=tonumber(ptr.solid_static_type),
                        platform_type=tonumber(ptr.platform_type),
                        cell_holes_in_texture=ptr.cell_holes_in_texture == true,
                    }
                end)
                if ok_fields and type(fields) == "table" then
                    cell_type = math.floor(tonumber(fields.cell_type) or 0)
                    liquid_static = fields.liquid_static == true
                    solid_static_type = math.floor(tonumber(fields.solid_static_type) or 0)
                    platform_type = math.floor(tonumber(fields.platform_type) or 0)
                    cell_holes_in_texture = fields.cell_holes_in_texture == true
                end
            end
        end
        -- Noita's material taxonomy is not identical to CellData.cell_type. In
        -- particular many authored terrain materials (for example *_static rock-like
        -- materials) are represented internally as static liquid/sand cells so that
        -- CellFactory_GetAllSolids() does not imply CELL_TYPE_SOLID. construct_cell()
        -- may also legitimately return nil on a transparent material-texture texel.
        -- Route every static/textured terrain material through PixelScene placement;
        -- keep the proven direct-cell path for ordinary liquids/powders/gases/fires.
        local requires_scene = options.force_scene == true
            or (id ~= 0 and ptr == nil)
            or cell_type == CELL_TYPE_SOLID
            or liquid_static
            or solid_static_type > 0
            or platform_type > 0
            or cell_holes_in_texture
        return {
            ffi=ffi_world, grid_world=grid_world, chunk_map=chunk_map,
            material_id=id, material_ptr=ptr, material_name=material_name,
            cell_type=cell_type, liquid_static=liquid_static,
            solid_static_type=solid_static_type, platform_type=platform_type,
            cell_holes_in_texture=cell_holes_in_texture,
            mode=requires_scene and "solid_scene" or "direct_cell",
        }, "ready"
    end)
    if not ok then return nil, "ffi_error" end
    return context, detail
end

local function restore_previous(context, ppixel, old_id, x, y)
    if old_id == nil or old_id == 0 then return false end
    local ffi_world = context.ffi
    local old_ptr = ffi_world.get_material_ptr(old_id)
    if old_ptr == nil then return false end
    local old_cell = ffi_world.construct_cell(context.grid_world, x, y, old_ptr, nil)
    if old_cell == nil then return false end
    ppixel[0] = old_cell
    return true
end

-- Fast direct-cell path for ordinary liquids, powders, gases and fires. Static/textured
-- terrain is not constructed here: its CellData may even report liquid while construct_cell
-- can legally return nil for material-texture holes. It uses LoadPixelScene via
-- paint_solid_scene_prepared(), Noita's authored terrain placement path.
function backend.paint_cell_prepared(context, x, y)
    if type(context) ~= "table" or type(context.ffi) ~= "table" then return false, "context" end
    if context.mode == "solid_scene" then return false, "solid_scene_required" end
    x, y = math.floor(tonumber(x) or 0), math.floor(tonumber(y) or 0)
    local ok, result, detail = pcall(function()
        local ffi_world = context.ffi
        if ffi_world.chunk_loaded(context.chunk_map, x, y) ~= true then return false, "unloaded" end
        local ppixel = ffi_world.get_cell(context.chunk_map, x, y)
        if ppixel == nil then return false, "cell_slot" end
        local current = ppixel[0]
        local current_id = 0
        if current ~= nil then
            local current_material = current.vtable.get_material(current)
            if current_material ~= nil then current_id = math.floor(tonumber(ffi_world.get_material_id(current_material)) or 0) end
            if current_id == context.material_id then return true, "unchanged" end
            ffi_world.remove_cell(context.grid_world, current, x, y, false)
        end
        if context.material_id == 0 then return true, "erased" end
        local cell = ffi_world.construct_cell(context.grid_world, x, y, context.material_ptr, nil)
        if cell == nil then
            if current ~= nil then restore_previous(context, ppixel, current_id, x, y) end
            return false, "construct"
        end
        ppixel[0] = cell
        return true, "painted"
    end)
    if not ok then return false, "ffi_error" end
    return result == true, detail
end


local function material_scene_transport_safe()
    if type(GlobalsGetValue) ~= "function" then return true end
    local ok, status = pcall(GlobalsGetValue, "mcm_compat_material_scene_patch_v1", "")
    if not ok then return true end
    status = tostring(status or "")
    return status ~= "read_failed" and status ~= "anchor_mismatch"
        and status ~= "verification_failed" and status ~= "write_failed"
end

function backend.paint_scene_prepared(context, mask_file, top_left_x, top_left_y, mask_color)
    if type(context) ~= "table" or type(context.material_name) ~= "string"
        or context.material_name == ""
    then
        return false, "context"
    end
    -- On an incompatible EW build, fail closed instead of letting stock EW replay an
    -- MCM-owned mask without its dynamic color/material map. In single-player the
    -- compatibility status is "disabled" (or absent), so this remains a pure no-op.
    if not material_scene_transport_safe() then return false, "ew_material_scene_patch" end
    if type(LoadPixelScene) ~= "function" then return false, "pixel_scene" end
    top_left_x, top_left_y = math.floor(tonumber(top_left_x) or 0), math.floor(tonumber(top_left_y) or 0)
    if type(mask_file) ~= "string" or mask_file == "" then return false, "mask" end
    local radius_probe = 1
    if type(DoesWorldExistAt) == "function" then
        local ok_loaded, loaded = pcall(DoesWorldExistAt,
            top_left_x - radius_probe, top_left_y - radius_probe,
            top_left_x + 16, top_left_y + 16)
        if ok_loaded and loaded ~= true then return false, "unloaded" end
    end
    local color_map = { [tostring(mask_color or "ff5ac75a")] = tostring(context.material_name or "") }
    local ok = pcall(LoadPixelScene, mask_file, "", top_left_x, top_left_y, "",
        true, false, color_map, 50, true)
    return ok == true, ok and "painted" or "pixel_scene"
end

function backend.paint_solid_scene_prepared(context, mask_file, top_left_x, top_left_y, mask_color)
    if type(context) ~= "table" or context.mode ~= "solid_scene" then return false, "mode" end
    return backend.paint_scene_prepared(context, mask_file, top_left_x, top_left_y, mask_color)
end

function backend.paint_cell(material_name, x, y)
    local context, reason = backend.begin_paint(material_name)
    if context == nil then return false, reason end
    if context.mode == "solid_scene" then return false, "solid_scene_required" end
    return backend.paint_cell_prepared(context, x, y)
end

METAMORPH_CREATIVE_MENU_MATERIAL_GRID_BACKEND = backend
return backend
