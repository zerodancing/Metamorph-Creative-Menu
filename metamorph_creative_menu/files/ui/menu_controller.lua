if type(METAMORPH_CREATIVE_MENU_MENU_CONTROLLER) == "table" then return METAMORPH_CREATIVE_MENU_MENU_CONTROLLER end

local menu_controller = {}

local ui = dofile("mods/metamorph_creative_menu/files/ui/runtime.lua")
local audit = ui.audit
local player_locator = dofile("mods/metamorph_creative_menu/files/platform/noita/player_locator.lua")
local input_guard = dofile("mods/metamorph_creative_menu/files/platform/noita/input_guard.lua")
local keycodes = dofile("mods/metamorph_creative_menu/files/platform/noita/keycodes.lua")
local menu_inventory_guard = dofile("mods/metamorph_creative_menu/files/platform/noita/menu_inventory_guard.lua")

local tabs = {
    { id="spells", key="$mcm_tab_spells", fallback="SPELLS", icon="data/ui_gfx/gun_actions/light_bullet.png", fallback_icon="data/ui_gfx/inventory/icon_gun.png", module=dofile("mods/metamorph_creative_menu/files/ui/tabs/spells.lua") },
    { id="items", key="$mcm_tab_items", fallback="ITEMS", icon="data/ui_gfx/items/potion.png", fallback_icon="data/ui_gfx/items/ingredient_1.png", module=dofile("mods/metamorph_creative_menu/files/ui/tabs/items.lua") },
    { id="perks", key="$mcm_tab_perks", fallback="PERKS", icon="data/ui_gfx/perk_icons/edit_wands_everywhere.png", fallback_icon="data/ui_gfx/perk_icons/extra_hp.png", module=dofile("mods/metamorph_creative_menu/files/ui/tabs/perks.lua") },
    { id="mobs", key="$mcm_tab_creatures", fallback="MOBS", icon="data/ui_gfx/animal_icons/sheep.png", fallback_icon="data/ui_gfx/animal_icons/zombie.png", module=dofile("mods/metamorph_creative_menu/files/ui/tabs/creatures.lua") },
    { id="effects", key="$mcm_tab_effects", fallback="EFFECTS", icon="data/ui_gfx/status_indicators/wet.png", fallback_icon="data/ui_gfx/status_indicators/on_fire.png", module=dofile("mods/metamorph_creative_menu/files/ui/tabs/effects.lua") },
    { id="weather", key="$mcm_tab_weather", fallback="WEATHER", icon="data/ui_gfx/items/thunderstone.png", fallback_icon="data/ui_gfx/items/waterstone.png", module=dofile("mods/metamorph_creative_menu/files/ui/tabs/weather.lua") },
    { id="rules", key="$mcm_tab_rules", fallback="RULES", icon="data/ui_gfx/perk_icons/peace_with_gods.png", fallback_icon="data/ui_gfx/perk_icons/gold_is_forever.png", module=dofile("mods/metamorph_creative_menu/files/ui/tabs/world_rules.lua") },
}

local gui = nil
local active_tab = 1
local panel_hovered = false
local pending_scroll_restore = nil
local last_panel_width = 260
local tab_error_signatures = {}
local emergency_open = false
local last_resume_serial = 0
local suppress_inventory_until_closed = false
local warmup_tab_cursor = 1
local warmup_done = {}


local function update_emergency_open(player)
    if not menu_inventory_guard.controls_disabled(player) then emergency_open = false; return end
    if not input_guard.actions_allowed() then return end
    local key = keycodes.resolve("Key_TAB", "KEY_TAB"); if key == nil then return end
    local ok, pressed = pcall(InputIsKeyJustDown, key)
    if ok and pressed == true then emergency_open = not emergency_open; audit("menu.emergency_toggle", "open="..tostring(emergency_open)) end
end


local function background_warmup()
    -- Warm the two catalog-heavy tabs incrementally. Singleplayer can spend a slightly
    -- larger budget because no networking work shares the frame.
    local order = {4, 3}
    if warmup_done[4] and warmup_done[3] then return end
    for _ = 1, #order do
        local index = order[warmup_tab_cursor]
        warmup_tab_cursor = warmup_tab_cursor % #order + 1
        if not warmup_done[index] then
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

local function panel_width(screen_width)
    screen_width = tonumber(screen_width) or 320
    -- Responsive in Noita GUI coordinates: keep the world readable while allowing
    -- wider grids on high-resolution displays. All tabs consume this same metric.
    return math.max(240, math.min(360, math.floor(screen_width - 112)))
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
                title, "", active_tab == index, { target_size=18, max_scale=2.5, padding=1 })
            if clicked then active_tab = index; audit("menu.tab", "id="..tostring(tab.id)) end
        end
        GuiLayoutEnd(ui.gui())
    end
end

local function remember_scroll_selection(player_entity_id)
    if not panel_hovered or player_entity_id == 0 then return end
    local wheel_up_succeeded, wheel_up_pressed = pcall(InputIsMouseButtonJustDown, 4)
    local wheel_down_succeeded, wheel_down_pressed = pcall(InputIsMouseButtonJustDown, 5)
    local wheel_changed = (wheel_up_succeeded and wheel_up_pressed == true)
        or (wheel_down_succeeded and wheel_down_pressed == true)
    if not wheel_changed then return end
    pending_scroll_restore = menu_inventory_guard.capture_scroll_selection(player_entity_id)
end
function menu_controller.draw()
    if gui == nil then gui = GuiCreate() end
    GuiStartFrame(gui)
    GuiOptionsAdd(gui, GUI_OPTION.NoPositionTween)
    ui.bind(gui)
    ui.begin_frame()
    panel_hovered = false

    local player = player_locator.get()
    update_emergency_open(player)
    local native_inventory_open = menu_inventory_guard.inventory_open(player)
    if not native_inventory_open and not emergency_open then background_warmup() end
    local serial = type(input_guard.resume_serial) == "function" and input_guard.resume_serial() or 0
    if serial ~= last_resume_serial then
        last_resume_serial = serial
        -- Alt-Tab commonly toggles/open the vanilla inventory. Do not immediately draw
        -- hundreds of creative-menu tiles while EW is draining its resume backlog.
        if native_inventory_open then suppress_inventory_until_closed = true end
    end
    if suppress_inventory_until_closed then
        if native_inventory_open then return end
        suppress_inventory_until_closed = false
    end
    local opened = native_inventory_open or emergency_open
    if not opened or input_guard.blocked() then return end

    local screen_width, screen_height = GuiGetScreenDimensions(gui)
    last_panel_width = panel_width(screen_width)
    local x = math.max(4, screen_width - last_panel_width - 6)
    GuiLayoutBeginVertical(gui, x, 46, true)
    GuiBeginAutoBox(gui)
    draw_tab_bar(last_panel_width)

    if player == 0 then
        ui.white_text(0, 2, ui.tr("$mcm_player_missing", "Player has not spawned yet"))
    else
        local tab = tabs[active_tab]
        if tab ~= nil and type(tab.module) == "table" and type(tab.module.draw) == "function" then
            local ok, err = pcall(tab.module.draw, player, last_panel_width, screen_height)
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

    ui.finish_auto_box(5)
    GuiLayoutEnd(gui)
    panel_hovered = ui.hovered()
    remember_scroll_selection(player)
end

function menu_controller.post_update()
    local selection_snapshot = pending_scroll_restore
    pending_scroll_restore = nil
    if selection_snapshot ~= nil then menu_inventory_guard.restore_scroll_selection(selection_snapshot) end
end
function menu_controller.active_tab() return tabs[active_tab] and tabs[active_tab].id or "" end
function menu_controller.is_hovered() return panel_hovered end

METAMORPH_CREATIVE_MENU_MENU_CONTROLLER = menu_controller
return menu_controller
