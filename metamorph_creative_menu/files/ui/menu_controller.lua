if type(METAMORPH_CREATIVE_MENU_MENU_CONTROLLER) == "table" then return METAMORPH_CREATIVE_MENU_MENU_CONTROLLER end

local menu_controller = {}

local ui = dofile("mods/metamorph_creative_menu/files/ui/runtime.lua")
local audit = ui.audit
local player_locator = dofile("mods/metamorph_creative_menu/files/platform/noita/player_locator.lua")
local input_guard = dofile("mods/metamorph_creative_menu/files/platform/noita/input_guard.lua")
local menu_inventory_guard = dofile("mods/metamorph_creative_menu/files/platform/noita/menu_inventory_guard.lua")
local action_bindings = dofile("mods/metamorph_creative_menu/files/platform/noita/action_bindings.lua")
local panel_layout = dofile("mods/metamorph_creative_menu/files/core/panel_layout.lua")
local pointer = dofile("mods/metamorph_creative_menu/files/platform/noita/pointer.lua")
local drag_drop = dofile("mods/metamorph_creative_menu/files/ui/drag_drop.lua")

local tabs = {
    { id="spells", key="$mcm_tab_spells", fallback="SPELLS", icon="data/ui_gfx/gun_actions/light_bullet.png", fallback_icon="data/ui_gfx/inventory/icon_gun.png", module=dofile("mods/metamorph_creative_menu/files/ui/tabs/spells.lua") },
    { id="items", key="$mcm_tab_items", fallback="ITEMS", icon="data/ui_gfx/items/potion.png", fallback_icon="data/ui_gfx/items/ingredient_1.png", module=dofile("mods/metamorph_creative_menu/files/ui/tabs/items.lua") },
    { id="materials", key="$mcm_tab_materials", fallback="MATERIALS", icon="data/ui_gfx/items/material_pouch.png", fallback_icon="data/ui_gfx/items/potion.png", module=dofile("mods/metamorph_creative_menu/files/ui/tabs/materials.lua") },
    { id="perks", key="$mcm_tab_perks", fallback="PERKS", icon="data/ui_gfx/perk_icons/respawn.png", fallback_icon="data/ui_gfx/perk_icons/extra_hp.png", icon_fill=1.55, icon_max_scale=3.5, module=dofile("mods/metamorph_creative_menu/files/ui/tabs/perks.lua") },
    { id="mobs", key="$mcm_tab_creatures", fallback="MOBS", icon="data/ui_gfx/animal_icons/sheep.png", fallback_icon="data/ui_gfx/animal_icons/zombie.png", module=dofile("mods/metamorph_creative_menu/files/ui/tabs/creatures.lua") },
    { id="effects", key="$mcm_tab_effects", fallback="EFFECTS", icon="data/ui_gfx/status_indicators/hp_regeneration.png", fallback_icon="data/ui_gfx/status_indicators/wet.png", module=dofile("mods/metamorph_creative_menu/files/ui/tabs/effects.lua") },
    { id="weather", key="$mcm_tab_weather", fallback="WEATHER", icon="data/ui_gfx/status_indicators/wet.png", fallback_icon="data/ui_gfx/items/waterstone.png", module=dofile("mods/metamorph_creative_menu/files/ui/tabs/weather.lua") },
    { id="rules", key="$mcm_tab_rules", fallback="RULES", icon="data/ui_gfx/perk_icons/peace_with_gods.png", fallback_icon="data/ui_gfx/perk_icons/gold_is_forever.png", module=dofile("mods/metamorph_creative_menu/files/ui/tabs/world_rules.lua") },
    { id="players", key="$mcm_tab_players", fallback="TELEPORTATION", icon="data/ui_gfx/gun_actions/teleport_projectile_static.png", fallback_icon="data/ui_gfx/gun_actions/light_bullet.png", module=dofile("mods/metamorph_creative_menu/files/ui/tabs/players.lua") },
    { id="controls", action="open_controls", key="$mcm_tab_controls", fallback="CONTROLS", icon="data/ui_gfx/gun_actions/divide_2.png", fallback_icon="data/ui_gfx/gun_actions/light_bullet.png", module=dofile("mods/metamorph_creative_menu/files/ui/tabs/controls.lua") },
}

for _, tab in ipairs(tabs) do if tab.action == nil then tab.action = "open_" .. tab.id end end

local gui = nil
local active_tab = 1
local panel_hovered = false
local pending_selection_restore = nil
local last_panel_width = 260
local layout = nil
local pointer_operation = nil
local minimized = false
local tab_error_signatures = {}
local last_resume_serial = 0
local suppress_inventory_until_closed = false
local warmup_tab_cursor = 1
local warmup_done = {}
local menu_opened = false
local visible_last_frame = false
local manual_open = false
local suppress_native_until_closed = false
local last_native_open = false
local resize_hover_edges = nil
local frame_insets = nil
local restored_last_tab = false
local LAST_TAB_SETTING = "metamorph_creative_menu.ui_last_tab"
local LAYOUT_X_SETTING = "metamorph_creative_menu.ui_panel_x"
local LAYOUT_Y_SETTING = "metamorph_creative_menu.ui_panel_y"
local LAYOUT_WIDTH_SETTING = "metamorph_creative_menu.ui_panel_width"
local LAYOUT_HEIGHT_SETTING = "metamorph_creative_menu.ui_panel_height"
local HEADER_CONTROL_RESERVE = 34
local BORDER_VISUAL_OUTSET = 2
local BORDER_VISUAL_THICKNESS = 5
local DEFAULT_FRAME_INSET = 4


local function layout_outsets()
    local insets = frame_insets or {left=DEFAULT_FRAME_INSET,right=DEFAULT_FRAME_INSET,top=DEFAULT_FRAME_INSET,bottom=DEFAULT_FRAME_INSET}
    return {
        left=(tonumber(insets.left) or DEFAULT_FRAME_INSET) + BORDER_VISUAL_OUTSET,
        right=(tonumber(insets.right) or DEFAULT_FRAME_INSET) + BORDER_VISUAL_OUTSET,
        top=(tonumber(insets.top) or DEFAULT_FRAME_INSET) + BORDER_VISUAL_OUTSET,
        bottom=(tonumber(insets.bottom) or DEFAULT_FRAME_INSET) + BORDER_VISUAL_OUTSET,
    }
end

local function tab_index_by_id(id)
    for index, tab in ipairs(tabs) do if tab.id == id then return index end end
    return nil
end

local function save_active_tab()
    local tab = tabs[active_tab]
    if tab ~= nil and type(ModSettingSet) == "function" then
        pcall(ModSettingSet, LAST_TAB_SETTING, tab.id)
    end
end

local function set_active_tab(index, source)
    index = tonumber(index)
    if index == nil or tabs[index] == nil then return false end
    if index ~= active_tab and type(ui.blur_text_input) == "function" then
        ui.blur_text_input("tab_changed")
    end
    active_tab = index
    save_active_tab()
    audit("menu.tab", "id=" .. tostring(tabs[index].id) .. " source=" .. tostring(source or "ui"))
    return true
end

local function open_tab(id, source)
    local index = tab_index_by_id(id)
    return index ~= nil and set_active_tab(index, source) or false
end

local function restore_last_tab()
    if restored_last_tab then return end
    restored_last_tab = true
    if type(ModSettingGet) ~= "function" then return end
    local ok, id = pcall(ModSettingGet, LAST_TAB_SETTING)
    if ok and type(id) == "string" then
        local index = tab_index_by_id(id)
        if index ~= nil then active_tab = index end
    end
end

local function step_tab(direction)
    local count = #tabs
    if count == 0 then return end
    set_active_tab(((active_tab - 1 + direction) % count) + 1, "shortcut")
end

local function close_menu(native_open)
    manual_open = false
    menu_opened = false
    if native_open then suppress_native_until_closed = true end
    if type(ui.reset_text_inputs) == "function" then ui.reset_text_inputs() end
    drag_drop.cancel()
end

local function process_shortcuts(native_open)
    action_bindings.update()
    if native_open and not last_native_open then suppress_native_until_closed = false end
    if not native_open then suppress_native_until_closed = false end

    local visible_before = manual_open or (native_open and not suppress_native_until_closed)
    if action_bindings.consume("menu_toggle") then
        if visible_before then close_menu(native_open) else manual_open = true end
    elseif action_bindings.consume("menu_close") and visible_before then
        close_menu(native_open)
    end

    for _, tab in ipairs(tabs) do
        if action_bindings.consume(tab.action) then
            open_tab(tab.id, "shortcut")
            suppress_native_until_closed = false
            if not native_open then manual_open = true end
        end
    end

    local visible_after = manual_open or (native_open and not suppress_native_until_closed)
    if visible_after then
        if action_bindings.consume("tab_previous") then step_tab(-1) end
        if action_bindings.consume("tab_next") then step_tab(1) end
    end
    last_native_open = native_open
end

local function background_warmup()
    -- Warm catalog-heavy tabs by stable ids rather than positional indexes so adding a
    -- new UI section cannot silently redirect background work to the wrong feature.
    local order = { tab_index_by_id("mobs"), tab_index_by_id("perks") }
    local all_done = true
    for _, index in ipairs(order) do if index ~= nil and not warmup_done[index] then all_done = false; break end end
    if all_done then return end
    for _ = 1, #order do
        local index = order[warmup_tab_cursor]
        warmup_tab_cursor = warmup_tab_cursor % #order + 1
        if index ~= nil and not warmup_done[index] then
            local warmup_tab_module = tabs[index] and tabs[index].module or nil
            if type(warmup_tab_module) == "table" and type(warmup_tab_module.warmup_step) == "function" then
                -- Keep background work conservative on every machine. Feature modules may
                -- internally amortize heavier work, while UI stays unaware of network mods.
                local ok, done = pcall(warmup_tab_module.warmup_step, 1)
                if ok and done == true then warmup_done[index] = true end
            else
                warmup_done[index] = true
            end
            return
        end
    end
end

local function read_number_setting(id)
    if type(ModSettingGet) ~= "function" then return nil end
    local ok, value = pcall(ModSettingGet, id)
    return ok and tonumber(value) or nil
end

local function save_layout()
    if layout == nil or type(ModSettingSet) ~= "function" then return end
    pcall(ModSettingSet, LAYOUT_X_SETTING, math.floor(layout.x + 0.5))
    pcall(ModSettingSet, LAYOUT_Y_SETTING, math.floor(layout.y + 0.5))
    pcall(ModSettingSet, LAYOUT_WIDTH_SETTING, math.floor(layout.width + 0.5))
    pcall(ModSettingSet, LAYOUT_HEIGHT_SETTING, math.floor(layout.height + 0.5))
end

local function ensure_layout(screen_width, screen_height)
    if layout == nil then
        layout = panel_layout.create(screen_width, screen_height, {
            x=read_number_setting(LAYOUT_X_SETTING),
            y=read_number_setting(LAYOUT_Y_SETTING),
            width=read_number_setting(LAYOUT_WIDTH_SETTING),
            height=read_number_setting(LAYOUT_HEIGHT_SETTING),
        }, layout_outsets())
    else
        panel_layout.clamp(layout, screen_width, screen_height, nil, layout_outsets())
    end
    last_panel_width = layout.width
end

local function mouse_gui_position(screen_width, screen_height)
    return pointer.gui_position(screen_width, screen_height)
end

local function left_mouse(action)
    -- Do not express this as `just_down and ... or down`: in Lua that falls through
    -- to the held state whenever just_down is false, which makes an already-held
    -- pointer look like a fresh click as soon as it crosses the frame/title bar.
    if action == "just_down" then return pointer.left_just_down() end
    return pointer.left_down()
end

local function begin_pointer_operation(kind, screen_width, screen_height, edges)
    if pointer_operation ~= nil or not left_mouse("just_down") then return end
    local mouse_x, mouse_y = mouse_gui_position(screen_width, screen_height)
    if mouse_x == nil then return end
    pointer_operation = {
        kind=kind,
        mouse_x=mouse_x,
        mouse_y=mouse_y,
        x=layout.x,
        y=layout.y,
        width=layout.width,
        height=layout.height,
        edges=edges,
    }
    audit("menu.layout_begin", "kind=" .. tostring(kind))
end

local function update_pointer_operation(screen_width, screen_height)
    if pointer_operation == nil then return end
    if not left_mouse("down") then
        audit("menu.layout_end", "kind=" .. tostring(pointer_operation.kind))
        pointer_operation = nil
        save_layout()
        return
    end
    local mouse_x, mouse_y = mouse_gui_position(screen_width, screen_height)
    if mouse_x == nil then return end
    local delta_x, delta_y = mouse_x - pointer_operation.mouse_x, mouse_y - pointer_operation.mouse_y
    if pointer_operation.kind == "move" then
        panel_layout.move(layout, pointer_operation.x + delta_x, pointer_operation.y + delta_y,
            screen_width, screen_height, nil, layout_outsets())
    else
        panel_layout.resize_edges(layout, pointer_operation, pointer_operation.edges,
            delta_x, delta_y, screen_width, screen_height, layout_outsets())
    end
    last_panel_width = layout.width
end

local function border_edges_at_mouse(screen_width, screen_height)
    local mouse_x, mouse_y = mouse_gui_position(screen_width, screen_height)
    if mouse_x == nil or mouse_y == nil then return nil end
    local insets = frame_insets or {left=0,right=0,top=0,bottom=0}
    local left = layout.x - (tonumber(insets.left) or 0)
    local top = layout.y - (tonumber(insets.top) or 0)
    local right = layout.x + layout.width + (tonumber(insets.right) or 0)
    local bottom = layout.y + (minimized and 16 or layout.height)
        + (not minimized and (tonumber(insets.bottom) or 0) or 0)

    -- The hit band is exactly the visible frame: part of it overlays the stock menu
    -- edge and part sits just outside it. Nothing is armed merely by crossing this
    -- band while the mouse button is already held; begin_border_operation only asks
    -- for these edges on the frame where a new press begins. This makes the rule
    -- universal for spells, items and any future draggable payloads.
    local outer = BORDER_VISUAL_OUTSET
    local inner = math.max(1, BORDER_VISUAL_THICKNESS - BORDER_VISUAL_OUTSET)
    if mouse_x < left - outer or mouse_x > right + outer
        or mouse_y < top - outer or mouse_y > bottom + outer
    then
        return nil
    end
    local edges = {
        left=mouse_x <= left + inner,
        right=mouse_x >= right - inner,
        top=mouse_y <= top + inner,
        bottom=not minimized and mouse_y >= bottom - inner,
    }
    return (edges.left or edges.right or edges.top or edges.bottom) and edges or nil
end

local function begin_border_operation(screen_width, screen_height)
    local hovered_edges = border_edges_at_mouse(screen_width, screen_height)
    -- Hover advertises that the frame can resize, but a held press that originated
    -- elsewhere never arms or highlights the frame while crossing it.
    resize_hover_edges = pointer_operation == nil and not left_mouse("down") and hovered_edges or nil
    if pointer_operation ~= nil or not left_mouse("just_down") then return end
    local pressed_edges = hovered_edges
    if pressed_edges == nil then return end
    begin_pointer_operation("resize", screen_width, screen_height, pressed_edges)
end

local function begin_titlebar_operation(screen_width, screen_height)
    if pointer_operation ~= nil or not left_mouse("just_down") then return end
    local mouse_x, mouse_y = mouse_gui_position(screen_width, screen_height)
    if mouse_x == nil or mouse_y == nil then return end
    local insets = frame_insets or {left=0,top=0}
    local left = layout.x - (tonumber(insets.left) or 0) + 5
    local right = layout.x + layout.width - HEADER_CONTROL_RESERVE
    local top = layout.y - (tonumber(insets.top) or 0) + 5
    local bottom = layout.y + (minimized and 14 or 24)
    if mouse_x >= left and mouse_x <= right and mouse_y >= top and mouse_y <= bottom then
        begin_pointer_operation("move", screen_width, screen_height)
    end
end

local function reset_layout(screen_width, screen_height)
    layout = panel_layout.create(screen_width, screen_height, {}, layout_outsets())
    last_panel_width = layout.width
    pointer_operation = nil
    frame_insets = nil
    minimized = false
    save_layout()
    audit("menu.layout_reset", "width=" .. tostring(math.floor(layout.width + 0.5)))
end

local function draw_tab_bar(width)
    -- The header is a responsive grid rather than a permanently growing row. New
    -- tabs can be added without changing panel geometry or depending on label length.
    local per_row = math.max(1, math.floor(((tonumber(width) or 260) - 8) / ui.ICON_STEP))
    for start = 1, #tabs, per_row do
        GuiLayoutBeginHorizontal(ui.gui(), 0, 0, true)
        for index = start, math.min(start + per_row - 1, #tabs) do
            local tab = tabs[index]
            local title = ui.tr(tab.key, tab.fallback)
            local clicked = ui.tile(0, 0, ui.EMPTY_SLOT, tab.icon, tab.fallback_icon or ui.EMPTY_SLOT,
                title, nil, active_tab == index, { target_size=18,
                    max_scale=tab.icon_max_scale or 2.5, fill=tab.icon_fill or 1.0, padding=1 })
            if clicked then set_active_tab(index, "ui") end
        end
        GuiLayoutEnd(ui.gui())
    end
end

local function draw_header(native_open, screen_width, screen_height)
    local tab = tabs[active_tab]
    local title = tab and ui.tr(tab.key, tab.fallback) or ui.tr("$mcm_menu_title", "CREATIVE MENU")
    local title_width = type(ui.text_width) == "function" and ui.text_width(title) or #title * 5
    local space_width = type(ui.text_width) == "function" and ui.text_width(" ") or 3
    local remaining = math.max(1, last_panel_width - title_width - HEADER_CONTROL_RESERVE)
    local drag_text = title .. string.rep(" ", math.max(1, math.floor(remaining / math.max(1, space_width))))
    GuiLayoutBeginHorizontal(ui.gui(), 0, 0, true)
    if type(ui.drag_handle) == "function" then
        ui.drag_handle(0, 0, drag_text, title,
            ui.tr("$mcm_menu_drag", "Drag menu"), ui.tr("$mcm_menu_drag_hint", "Hold and move the mouse"))
    else
        ui.button(0, 0, drag_text, true,
            ui.tr("$mcm_menu_drag", "Drag menu"), ui.tr("$mcm_menu_drag_hint", "Hold and move the mouse"))
    end
    if not minimized then
        if ui.button(0, 0, "R", false, ui.tr("$mcm_menu_layout_reset", "Reset menu position and size"), "") then
            reset_layout(screen_width, screen_height)
        end
    end
    local minimize_label = minimized and "+" or "-"
    local minimize_title = minimized and ui.tr("$mcm_menu_restore", "Restore window")
        or ui.tr("$mcm_menu_minimize", "Hide window")
    if ui.button(0, 0, minimize_label, false, minimize_title, "") then
        minimized = not minimized
        menu_opened = not minimized
        if minimized then
            if type(ui.reset_text_inputs) == "function" then ui.reset_text_inputs() end
        end
        pointer_operation = nil
        audit("menu.minimized", "value=" .. tostring(minimized))
    end
    if ui.button(0, 0, "X", false, ui.tr("$mcm_bind_menu_close", "Close creative menu"), "") then
        close_menu(native_open)
    end
    GuiLayoutEnd(ui.gui())
end

local function pointer_click_inside_window(screen_width, screen_height)
    if layout == nil then return false end
    local mouse_x, mouse_y = mouse_gui_position(screen_width, screen_height)
    local insets = frame_insets or {left=0,right=0,top=0,bottom=0}
    local x = layout.x - (tonumber(insets.left) or 0) - BORDER_VISUAL_OUTSET
    local y = layout.y - (tonumber(insets.top) or 0) - BORDER_VISUAL_OUTSET
    local width = layout.width + (tonumber(insets.left) or 0) + (tonumber(insets.right) or 0)
        + BORDER_VISUAL_OUTSET * 2
    local content_height = minimized and 16 or layout.height
    local height = content_height + (tonumber(insets.top) or 0)
        + (minimized and 0 or (tonumber(insets.bottom) or 0)) + BORDER_VISUAL_OUTSET * 2
    local clicking = pointer.left_down() or (type(pointer.right_down) == "function" and pointer.right_down())
    return clicking and pointer.inside(x, y, width, height, mouse_x, mouse_y)
end

local function remember_scroll_selection(player_entity_id)
    if not panel_hovered or player_entity_id == 0 then return end
    local wheel_up_succeeded, wheel_up_pressed = pcall(InputIsMouseButtonJustDown, 4)
    local wheel_down_succeeded, wheel_down_pressed = pcall(InputIsMouseButtonJustDown, 5)
    local wheel_changed = (wheel_up_succeeded and wheel_up_pressed == true)
        or (wheel_down_succeeded and wheel_down_pressed == true)
    if not wheel_changed then return end
    pending_selection_restore = menu_inventory_guard.capture_scroll_selection(player_entity_id)
end
function menu_controller.draw()
    menu_opened = false
    if gui == nil then gui = GuiCreate() end
    GuiStartFrame(gui)
    GuiOptionsAdd(gui, GUI_OPTION.NoPositionTween)
    ui.bind(gui)
    ui.begin_frame()
    panel_hovered = false

    local player = player_locator.get()
    restore_last_tab()
    local native_inventory_open = menu_inventory_guard.inventory_open(player)
    process_shortcuts(native_inventory_open)
    if not native_inventory_open and not manual_open then background_warmup() end
    local serial = type(input_guard.resume_serial) == "function" and input_guard.resume_serial() or 0
    if serial ~= last_resume_serial then
        last_resume_serial = serial
        -- Alt-Tab commonly toggles/open the vanilla inventory. Do not immediately draw
        -- hundreds of creative-menu tiles while EW is draining its resume backlog.
        if native_inventory_open then suppress_inventory_until_closed = true end
    end
    if suppress_inventory_until_closed then
        if native_inventory_open then
            if visible_last_frame and type(ui.reset_text_inputs) == "function" then ui.reset_text_inputs() end
            visible_last_frame = false
            drag_drop.cancel()
            menu_inventory_guard.release_manual_controls()
            return
        end
        suppress_inventory_until_closed = false
    end
    local opened = manual_open or (native_inventory_open and not suppress_native_until_closed)
    if not opened or input_guard.blocked() then
        if visible_last_frame and type(ui.reset_text_inputs) == "function" then ui.reset_text_inputs() end
        visible_last_frame = false
        drag_drop.cancel()
        menu_inventory_guard.release_manual_controls()
        return
    end
    visible_last_frame = true
    local screen_width, screen_height = GuiGetScreenDimensions(gui)
    drag_drop.begin_frame(screen_width, screen_height)
    ensure_layout(screen_width, screen_height)
    local text_entry_active = type(ui.text_input_active) == "function" and ui.text_input_active() == true
    local pointer_drag_active = pointer.left_down() and (pointer_operation ~= nil
        or (type(drag_drop.pending) == "function" and drag_drop.pending() == true))
    -- Hovering keeps gameplay live. A click within the window or keyboard focus owns
    -- controls only for the interaction, preventing the same click from firing a wand.
    if (not minimized and text_entry_active) or pointer_click_inside_window(screen_width, screen_height)
        or pointer_drag_active
    then
        menu_inventory_guard.acquire_manual_controls(player)
    else
        menu_inventory_guard.release_manual_controls()
    end
    menu_opened = not minimized
    -- Continue an already-owned window gesture before layout. A new press is not armed
    -- until after tile sources have been drawn, so a spell press at the inner frame edge
    -- gets first refusal and cannot be stolen by move/resize.
    if pointer_operation ~= nil then update_pointer_operation(screen_width, screen_height) end
    if type(ui.set_panel_bounds) == "function" then
        ui.set_panel_bounds(layout.x, layout.y, layout.width, layout.height)
    end
    GuiLayoutBeginVertical(gui, layout.x, layout.y, true)
    GuiBeginAutoBox(gui)
    if type(ui.panel_width_anchor) == "function" then ui.panel_width_anchor(last_panel_width) end
    draw_header(native_inventory_open, screen_width, screen_height)
    if not minimized then draw_tab_bar(last_panel_width) end

    if minimized then
        -- The title bar remains as the restore target; gameplay controls are released.
    elseif player == 0 then
        ui.white_text(0, 2, ui.tr("$mcm_player_missing", "Player has not spawned yet"))
    else
        local tab = tabs[active_tab]
        if tab ~= nil and type(tab.module) == "table" and type(tab.module.draw) == "function" then
            local available_height = math.max(96, layout.height - 42)
            local ok, err = pcall(tab.module.draw, player, last_panel_width, available_height, {
                open_tab=function(id) return open_tab(id, "home") end,
                close=function() close_menu(native_inventory_open) end,
            })
            if not ok then
                ui.white_text(0, 2, ui.tr("$mcm_tab_runtime_error", "This section could not be drawn"))
                local signature = tostring(err)
                if tab_error_signatures[tab.id] ~= signature then
                    tab_error_signatures[tab.id] = signature
                    if type(METAMORPH_CREATIVE_MENU_DIAGNOSTICS_CAPTURE) == "function" then
                        pcall(METAMORPH_CREATIVE_MENU_DIAGNOSTICS_CAPTURE, "ui." .. tostring(tab.id), signature)
                    end
                    print("[Metamorph: Creative Menu] UI tab '" .. tostring(tab.id) .. "' failed: " .. signature)
                end
            else
                tab_error_signatures[tab.id] = nil
            end
        end
    end

    -- Sources are registered during tab draw. Only a press that no draggable tile claimed
    -- may start a window move/resize operation. This intentionally adds at most one frame
    -- before the panel begins moving, while preserving press-origin ownership for tiles.
    local tile_press_owned = type(drag_drop.pending) == "function" and drag_drop.pending() == true
    if pointer_operation == nil and not tile_press_owned then
        begin_border_operation(screen_width, screen_height)
        if pointer_operation == nil then begin_titlebar_operation(screen_width, screen_height) end
    end

    if type(ui.end_frame) == "function" then ui.end_frame() end
    if minimized then drag_drop.cancel() else drag_drop.end_frame() end

    local minimum_height = minimized and 14 or layout.height
    local frame_x, frame_y, measured_width, measured_height = ui.finish_auto_box(5, layout.width, minimum_height)
    if not minimized and tonumber(frame_x) ~= nil and tonumber(frame_y) ~= nil
        and tonumber(measured_width) ~= nil and tonumber(measured_height) ~= nil
    then
        frame_x, frame_y = tonumber(frame_x), tonumber(frame_y)
        measured_width, measured_height = tonumber(measured_width), tonumber(measured_height)
        frame_insets = {
            left=math.max(0, layout.x - frame_x),
            top=math.max(0, layout.y - frame_y),
            right=math.max(0, frame_x + measured_width - (layout.x + layout.width)),
            bottom=math.max(0, frame_y + measured_height - (layout.y + layout.height)),
        }
        if type(ui.resize_affordances) == "function" then
            local highlighted = pointer_operation ~= nil and pointer_operation.kind == "resize"
                and pointer_operation.edges or resize_hover_edges
            ui.resize_affordances(frame_x, frame_y, measured_width, measured_height, highlighted,
                pointer_operation ~= nil and pointer_operation.kind == "resize")
        end
    end
    GuiLayoutEnd(gui)
    local before_x, before_y, before_width, before_height = layout.x, layout.y, layout.width, layout.height
    panel_layout.clamp(layout, screen_width, screen_height, nil, layout_outsets())
    last_panel_width = layout.width
    if pointer_operation == nil and (layout.x ~= before_x or layout.y ~= before_y
        or layout.width ~= before_width or layout.height ~= before_height)
    then
        save_layout()
    end
    panel_hovered = ui.hovered()
    -- Native InventoryGui can still process number keys on some builds even while the
    -- player ControlsComponent is disabled. Snapshot the selected held item while typing
    -- and restore it after the frame so "2"/"3" remain text instead of wand-slot input.
    if type(ui.text_input_active) == "function" and ui.text_input_active() == true and player ~= 0 then
        pending_selection_restore = menu_inventory_guard.capture_scroll_selection(player)
    else
        remember_scroll_selection(player)
    end
end

function menu_controller.post_update()
    local selection_snapshot = pending_selection_restore
    pending_selection_restore = nil
    if selection_snapshot ~= nil then menu_inventory_guard.restore_scroll_selection(selection_snapshot) end
end
function menu_controller.active_tab() return tabs[active_tab] and tabs[active_tab].id or "" end
function menu_controller.is_hovered() return panel_hovered end
function menu_controller.is_open() return menu_opened end
function menu_controller.layout()
    if layout == nil then return nil end
    return { x=layout.x, y=layout.y, width=layout.width, height=layout.height, minimized=minimized }
end
function menu_controller.open_tab(id)
    local opened = open_tab(id, "external")
    if opened then manual_open = true end
    return opened
end

METAMORPH_CREATIVE_MENU_MENU_CONTROLLER = menu_controller
return menu_controller
