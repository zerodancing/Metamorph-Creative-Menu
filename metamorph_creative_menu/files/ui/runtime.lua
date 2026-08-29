if type(METAMORPH_CREATIVE_MENU_UI_RUNTIME) == "table" then return METAMORPH_CREATIVE_MENU_UI_RUNTIME end

local ui_runtime = {}

local asset_api = dofile("mods/metamorph_creative_menu/files/platform/noita/assets.lua")
local input_guard = dofile("mods/metamorph_creative_menu/files/platform/noita/input_guard.lua")
local pointer = dofile("mods/metamorph_creative_menu/files/platform/noita/pointer.lua")
local text_entry_guard = dofile("mods/metamorph_creative_menu/files/platform/noita/text_entry_guard.lua")
local keycodes = dofile("mods/metamorph_creative_menu/files/platform/noita/keycodes.lua")
local localization = dofile("mods/metamorph_creative_menu/files/platform/noita/localization.lua")
local search_engine = dofile("mods/metamorph_creative_menu/files/core/search_engine.lua")
local scroll_model = dofile("mods/metamorph_creative_menu/files/ui/widgets/scroll_model.lua")

local gui = nil
local next_widget_id = 1000
local hovered = false
local text_focus_seen = false
local search_keycodes = nil
local search_repeat = { key = nil, started = -1, last = -1 }
local text_input_reset_generation = 0
local text_input_seen_generation = {}
local panel_bounds = nil
local draw_colored_rect = nil
local confirmations = {}
local scroll_states = {}
local error_notices = {}

ui_runtime.EMPTY_SLOT = "data/ui_gfx/inventory/inventory_box.png"
ui_runtime.ICON_STEP = 20
ui_runtime.BACKGROUND_Z = -100

function ui_runtime.bind(bound_gui)
    gui = bound_gui
    asset_api.bind_gui(gui)
end

function ui_runtime.begin_frame()
    next_widget_id = 1000
    hovered = false
    panel_bounds = nil
    text_focus_seen = false
    scroll_model.begin_frame()
end

function ui_runtime.end_frame()
    if text_entry_guard.active() and not text_focus_seen then
        text_entry_guard.clear(nil, "unmounted")
    end
end

function ui_runtime.set_panel_bounds(x, y, width, height)
    panel_bounds = {
        x=tonumber(x) or 0, y=tonumber(y) or 0,
        width=math.max(1, tonumber(width) or 1),
        height=math.max(1, tonumber(height) or 1),
    }
end

function ui_runtime.panel_bounds()
    if panel_bounds == nil then return nil end
    return {
        x=panel_bounds.x, y=panel_bounds.y,
        width=panel_bounds.width, height=panel_bounds.height,
    }
end

function ui_runtime.gui() return gui end
function ui_runtime.next_id() next_widget_id = next_widget_id + 1; return next_widget_id end

function ui_runtime.translated(text)
    if text == nil or text == "" then return "" end
    return localization.translate(text, text)
end

function ui_runtime.tr(key, fallback)
    local value = ui_runtime.translated(key)
    if value == nil or value == "" or value == key then return fallback or key end
    return value
end

function ui_runtime.search_aliases(key, fallback)
    if type(localization.search_aliases) == "function" then return localization.search_aliases(key, fallback) end
    return { ui_runtime.translated(key), fallback or key, key }
end

function ui_runtime.audit(action, details)
    if type(METAMORPH_CREATIVE_MENU_DIAGNOSTICS_USER_ACTION) == "function" then
        pcall(METAMORPH_CREATIVE_MENU_DIAGNOSTICS_USER_ACTION, action, details)
    end
end

-- User-visible operation failures are transient notifications, not permanent layout rows.
-- Keep de-duplication here so individual tabs do not grow their own stale-error state.
function ui_runtime.report_error_once(key, title, reason, diagnostic_scope)
    if reason == nil then return false end
    key = tostring(key or diagnostic_scope or "ui")
    reason = tostring(reason)
    local signature = tostring(title or "") .. "\31" .. reason
    if error_notices[key] == signature then return false end
    error_notices[key] = signature
    local message = tostring(title or "Error")
    if reason ~= "" then message = message .. ": " .. reason end
    if type(GamePrint) == "function" then pcall(GamePrint, message) end
    if type(METAMORPH_CREATIVE_MENU_DIAGNOSTICS_CAPTURE) == "function" then
        pcall(METAMORPH_CREATIVE_MENU_DIAGNOSTICS_CAPTURE, tostring(diagnostic_scope or key), reason)
    end
    return true
end

function ui_runtime.clear_error_notice(key)
    if key ~= nil then error_notices[tostring(key)] = nil end
end

function ui_runtime.actions_allowed() return input_guard.actions_allowed() end
function ui_runtime.mark_hovered(value) if value == true then hovered = true end end
function ui_runtime.hovered() return hovered end

function ui_runtime.white_text(x, y, text)
    GuiColorSetForNextWidget(gui, 1, 1, 1, 1)
    GuiZSetForNextWidget(gui, -102)
    GuiText(gui, x, y, text or "")
end

function ui_runtime.colored_text(x, y, text, color)
    color = type(color) == "table" and color or {1,1,1,1}
    GuiColorSetForNextWidget(gui, tonumber(color[1]) or 1, tonumber(color[2]) or 1,
        tonumber(color[3]) or 1, tonumber(color[4]) or 1)
    GuiZSetForNextWidget(gui, -102)
    GuiText(gui, x, y, text or "")
end

local function approximate_character_count(value)
    local count = 0
    for byte in string.gmatch(tostring(value or ""), "[\1-\127\194-\244][\128-\191]*") do
        if byte ~= "" then count = count + 1 end
    end
    return count
end

function ui_runtime.text_width(text)
    if type(GuiGetTextDimensions) == "function" then
        local ok, width = pcall(GuiGetTextDimensions, gui, tostring(text or ""))
        if ok and tonumber(width) ~= nil then return tonumber(width) end
    end
    return approximate_character_count(text) * 5
end

local function utf8_characters(value)
    return string.gmatch(tostring(value or ""), "[\1-\127\194-\244][\128-\191]*")
end

local function split_token(token, max_width)
    local chunks, chunk = {}, ""
    for character in utf8_characters(token) do
        local candidate = chunk .. character
        if chunk ~= "" and ui_runtime.text_width(candidate) > max_width then
            chunks[#chunks + 1], chunk = chunk, character
        else
            chunk = candidate
        end
    end
    if chunk ~= "" then chunks[#chunks + 1] = chunk end
    return chunks
end

local function wrap_lines(text, max_width)
    text = tostring(text or "")
    max_width = math.max(24, tonumber(max_width) or 220)
    local lines = {}
    for paragraph in string.gmatch(text .. "\n", "([^\n]*)\n") do
        local current = ""
        for word in string.gmatch(paragraph, "%S+") do
            local chunks = ui_runtime.text_width(word) > max_width and split_token(word, max_width) or {word}
            for _, chunk in ipairs(chunks) do
                local candidate = current == "" and chunk or (current .. " " .. chunk)
                if current ~= "" and ui_runtime.text_width(candidate) > max_width then
                    lines[#lines + 1] = current
                    current = chunk
                else
                    current = candidate
                end
            end
        end
        if current ~= "" then lines[#lines + 1] = current
        elseif paragraph == "" then lines[#lines + 1] = "" end
    end
    if #lines == 0 then lines[1] = "" end
    return lines
end

function ui_runtime.truncate_text(text, max_width)
    text = tostring(text or "")
    max_width = math.max(8, tonumber(max_width) or 80)
    if ui_runtime.text_width(text) <= max_width then return text end
    local suffix = "..."
    local allowed = math.max(1, max_width - ui_runtime.text_width(suffix))
    local result = ""
    for character in utf8_characters(text) do
        if ui_runtime.text_width(result .. character) > allowed then break end
        result = result .. character
    end
    return result .. suffix
end

function ui_runtime.wrapped_text(x, y, text, max_width, color)
    local lines = wrap_lines(text, max_width)
    for index, line in ipairs(lines) do
        if color ~= nil then ui_runtime.colored_text(x, index == 1 and y or 0, line, color)
        else ui_runtime.white_text(x, index == 1 and y or 0, line) end
    end
    return #lines
end

-- AutoBox derives its size from children. This zero-height row makes the requested
-- panel width real even on sparse tabs, so resizing is visible.
function ui_runtime.panel_width_anchor(width)
    GuiLayoutBeginHorizontal(gui, 0, 0, true)
    GuiLayoutAddHorizontalSpacing(gui, math.max(1, (tonumber(width) or 240) - 10))
    GuiLayoutEnd(gui)
end

-- Draw translated text buttons in width-aware rows. Fixed "four buttons per row"
-- layouts overflow as soon as Russian/German labels or a narrow panel are used.
function ui_runtime.button_grid(items, max_width)
    items = type(items) == "table" and items or {}
    max_width = math.max(32, tonumber(max_width) or 220)
    local rows, row, row_width = {}, {}, 0
    for index, item in ipairs(items) do
        local label = tostring(item.label or "")
        local display_label = ui_runtime.truncate_text(label, max_width - 8)
        local width = math.min(max_width, math.max(10, ui_runtime.text_width(display_label) + 8))
        if #row > 0 and row_width + width + 2 > max_width then
            rows[#rows + 1], row, row_width = row, {}, 0
        end
        row[#row + 1] = {index=index,item=item,display_label=display_label}
        row_width = row_width + width + (#row > 1 and 2 or 0)
    end
    if #row > 0 then rows[#rows + 1] = row end

    local clicked_index = nil
    for _, current_row in ipairs(rows) do
        GuiLayoutBeginHorizontal(gui, 0, 0, true)
        for _, record in ipairs(current_row) do
            local item = record.item
            local tooltip_title = item.tooltip_title
            if tooltip_title == nil and record.display_label ~= tostring(item.label or "") then
                tooltip_title = item.label
            end
            if ui_runtime.button(0, 0, record.display_label, item.selected == true,
                tooltip_title, item.tooltip_description) then
                clicked_index = record.index
            end
        end
        GuiLayoutEnd(gui)
    end
    return clicked_index
end

local function set_text_focus(key, on_blur)
    key = tostring(key or "text")
    text_entry_guard.focus(key, on_blur)
    text_focus_seen = true
end

local function clear_text_focus(key, reason)
    return text_entry_guard.clear(key, reason or "blur")
end

local function focused_text_key()
    return text_entry_guard.key()
end

local function clear_search_focus_on_action(clicked)
    if clicked == true then clear_text_focus() end
end

local function tooltip_text(value)
    if value == nil then return nil end
    value = tostring(value)
    if string.match(value, "^%s*$") or value == "—" then return nil end
    return value
end

local function show_tooltip(title, description)
    title, description = tooltip_text(title), tooltip_text(description)
    if title == nil and description == nil then return end
    -- Noita's GuiTooltip binding expects both text parameters on builds where a
    -- one-argument call silently draws nothing. An empty description keeps the section
    -- name while avoiding the old placeholder dash on a second line.
    GuiTooltip(gui, title or "", description or "")
end

function ui_runtime.button(x, y, text, selected, tooltip_title, tooltip_description)
    if selected then GuiColorSetForNextWidget(gui, 1.0, 0.78, 0.2, 1.0)
    else GuiColorSetForNextWidget(gui, 1, 1, 1, 1) end
    GuiZSetForNextWidget(gui, -103)
    local clicked = GuiButton(gui, ui_runtime.next_id(), x, y, text or "")
    local _, _, is_hovered, actual_x, actual_y, actual_w, actual_h = GuiGetPreviousWidgetInfo(gui)
    ui_runtime.mark_hovered(is_hovered)
    show_tooltip(tooltip_title, tooltip_description)
    local accepted = clicked == true and ui_runtime.actions_allowed()
    clear_search_focus_on_action(accepted)
    return accepted, is_hovered == true, tonumber(actual_x), tonumber(actual_y), tonumber(actual_w), tonumber(actual_h)
end

function ui_runtime.drag_handle(x, y, layout_text, title, tooltip_title, tooltip_description)
    GuiColorSetForNextWidget(gui, 1, 1, 1, 0)
    GuiZSetForNextWidget(gui, -103)
    GuiButton(gui, ui_runtime.next_id(), x, y, layout_text or title or "")
    local _, _, is_hovered, actual_x, actual_y, actual_w, actual_h = GuiGetPreviousWidgetInfo(gui)
    actual_x, actual_y = tonumber(actual_x) or 0, tonumber(actual_y) or 0
    actual_w, actual_h = math.max(16, tonumber(actual_w) or 16), math.max(9, tonumber(actual_h) or 9)
    ui_runtime.mark_hovered(is_hovered)
    local base = {0.30,0.23,0.14,0.96}
    local hover = {0.42,0.32,0.18,0.98}
    local edge = {0.62,0.47,0.25,0.95}
    local grip = {0.72,0.57,0.34,0.88}
    draw_colored_rect(actual_x, actual_y, actual_w, actual_h, is_hovered and hover or base, -106)
    draw_colored_rect(actual_x, actual_y, actual_w, 1, edge, -107)
    draw_colored_rect(actual_x, actual_y + actual_h - 1, actual_w, 1, edge, -107)
    local grip_x = actual_x + actual_w - 10
    draw_colored_rect(grip_x, actual_y + 3, 6, 1, grip, -108)
    draw_colored_rect(grip_x, actual_y + 5, 6, 1, grip, -108)
    GuiOptionsAddForNextWidget(gui, GUI_OPTION.Layout_NoLayouting)
    GuiColorSetForNextWidget(gui, 0.90, 0.80, 0.58, 1)
    GuiZSetForNextWidget(gui, -109)
    GuiText(gui, actual_x + 4, actual_y + 1, title or "")
    show_tooltip(tooltip_title, tooltip_description)
    return is_hovered == true, actual_x, actual_y, actual_w, actual_h
end

function ui_runtime.stepper(label, value, options)
    options = type(options) == "table" and options or {}
    local delta = 0
    local prefix = tostring(label or "")
    local display = (prefix ~= "" and (prefix .. ": ") or "") .. tostring(value or "")
    local max_width = tonumber(options.max_width)
    local estimated = ui_runtime.text_width(display) + 26
    if max_width ~= nil and estimated > math.max(32, max_width) then
        ui_runtime.wrapped_text(0, tonumber(options.y) or 0, display, math.max(24, max_width))
        local clicked = ui_runtime.button_grid({
            {label="-", selected=false}, {label="+", selected=false},
        }, math.max(24, max_width))
        if clicked == 1 and options.decrease_enabled ~= false then delta = -1 end
        if clicked == 2 and options.increase_enabled ~= false then delta = 1 end
        return delta
    end
    GuiLayoutBeginHorizontal(gui, 0, tonumber(options.y) or 0, true)
    if ui_runtime.button(0, 0, "-") and options.decrease_enabled ~= false then delta = -1 end
    ui_runtime.white_text(0, 1, display)
    if ui_runtime.button(0, 0, "+") and options.increase_enabled ~= false then delta = 1 end
    GuiLayoutEnd(gui)
    return delta
end

local function current_frame()
    if type(GameGetFrameNum) ~= "function" then return 0 end
    local ok, frame = pcall(GameGetFrameNum)
    return ok and (tonumber(frame) or 0) or 0
end

function ui_runtime.confirm_button(key, label, confirmation_label, timeout_frames, max_width)
    key = tostring(key or label or "confirm")
    local frame = current_frame()
    local armed = frame <= (tonumber(confirmations[key]) or -1)
    local visible_label = armed and tostring(confirmation_label or ui_runtime.tr("$mcm_confirm", "CONFIRM"))
        or tostring(label or ui_runtime.tr("$mcm_confirm", "CONFIRM"))
    local clicked
    if tonumber(max_width) ~= nil then
        clicked = ui_runtime.button_grid({{label=visible_label,selected=armed,tooltip_title=visible_label}}, math.max(24,tonumber(max_width))) == 1
    else
        clicked = ui_runtime.button(0, 0, visible_label, armed)
    end
    if not clicked then return false end
    if armed then
        confirmations[key] = nil
        return true
    end
    confirmations[key] = frame + math.max(1, tonumber(timeout_frames) or 120)
    return false
end

local function load_search_keycodes()
    if search_keycodes ~= nil then return search_keycodes end
    search_keycodes = {
        backspace = keycodes.resolve("Key_BACKSPACE", "KEY_BACKSPACE"),
        escape = keycodes.resolve("Key_ESCAPE", "KEY_ESCAPE"),
        ctrl_l = keycodes.resolve("Key_LCTRL", "KEY_LCTRL", "Key_LCONTROL"),
        ctrl_r = keycodes.resolve("Key_RCTRL", "KEY_RCTRL", "Key_RCONTROL"),
    }
    return search_keycodes
end

local function utf8_pop(value)
    local n = #value
    if n == 0 then return value end
    local i = n
    while i > 1 do
        local b = string.byte(value, i)
        if b == nil or b < 128 or b >= 192 then break end
        i = i - 1
    end
    return string.sub(value, 1, i - 1)
end

local function utf8_pop_word(value)
    value = tostring(value or "")
    repeat
        local next_value = utf8_pop(value)
        if next_value == value then break end
        local removed = string.sub(value, #next_value + 1)
        value = next_value
        if not string.match(removed, "%s") then break end
    until value == ""
    while value ~= "" do
        local next_value = utf8_pop(value)
        local removed = string.sub(value, #next_value + 1)
        if string.match(removed, "[%s_/%-%.]") then break end
        value = next_value
    end
    return value
end

-- Gui widget IDs are frame-local inputs to Noita's retained native widget state.
-- Editable fields therefore derive their ID from the semantic focus key instead of
-- the dynamic draw order: the same field is the same GuiTextInput before, during and
-- after logical focus changes. Keep this range well away from ordinary next_id() IDs.
local function stable_text_input_id(focus_key)
    local hash = 0
    focus_key = tostring(focus_key or "text")
    for index = 1, #focus_key do
        hash = (hash * 131 + string.byte(focus_key, index)) % 1000000000
    end
    return 1000000 + hash
end

local function draw_text_input_placeholder(placeholder, actual_x, actual_y)
    placeholder = tostring(placeholder or "")
    if placeholder == "" or tonumber(actual_x) == nil or tonumber(actual_y) == nil then return end
    GuiOptionsAddForNextWidget(gui, GUI_OPTION.Layout_NoLayouting)
    GuiColorSetForNextWidget(gui, 0.72, 0.72, 0.72, 0.72)
    GuiZSetForNextWidget(gui, -104)
    GuiText(gui, actual_x + 3, actual_y + 1, placeholder)
end

function ui_runtime.reset_text_inputs()
    clear_text_focus(nil, "reset")
    search_repeat.key, search_repeat.started, search_repeat.last = nil, -1, -1
    text_input_reset_generation = text_input_reset_generation + 1
    confirmations = {}
end

function ui_runtime.text_input(value, width, max_length, focus_key, options)
    value = tostring(value or "")
    focus_key = tostring(focus_key or "text")
    options = type(options) == "table" and options or {}
    local field_width = math.max(36, tonumber(width) or 112)
    if text_input_seen_generation[focus_key] ~= text_input_reset_generation then
        text_input_seen_generation[focus_key] = text_input_reset_generation
        if options.clear_on_reset == true then value = "" end
    end

    local active_before = focused_text_key() == focus_key
    if active_before then
        text_focus_seen = true
        if type(text_entry_guard.set_blur_callback) == "function" then
            text_entry_guard.set_blur_callback(focus_key, options.on_blur)
        end
    end

    GuiColorSetForNextWidget(gui, 1, 1, 1, 1)
    GuiZSetForNextWidget(gui, -103)
    local widget_id = stable_text_input_id(focus_key)
    local ok, native_value = pcall(GuiTextInput, gui, widget_id, 0, 0, value,
        field_width, math.max(1, tonumber(max_length) or 64), tostring(options.allowed_characters or ""))
    local _, _, is_hovered, actual_x, actual_y = GuiGetPreviousWidgetInfo(gui)
    ui_runtime.mark_hovered(is_hovered)

    local click_on_field = pointer.left_just_down() and is_hovered == true
    if click_on_field and ui_runtime.actions_allowed() then
        set_text_focus(focus_key, options.on_blur)
        search_repeat.key, search_repeat.started, search_repeat.last = nil, -1, -1
    elseif active_before and pointer.left_just_down() and is_hovered ~= true then
        clear_text_focus(focus_key, "pointer")
    end

    local active = focused_text_key() == focus_key
    if active then
        text_focus_seen = true
        if type(text_entry_guard.set_blur_callback) == "function" then
            text_entry_guard.set_blur_callback(focus_key, options.on_blur)
        end
    end

    local new_value = value
    if active and ok and ui_runtime.actions_allowed() and type(native_value) == "string" then
        new_value = native_value
    end
    if value == "" and not active then
        draw_text_input_placeholder(options.placeholder, actual_x, actual_y)
    end

    local keys = load_search_keycodes()
    local frame = GameGetFrameNum()
    if keys.escape ~= nil and active then
        local ok_esc, esc = pcall(InputIsKeyJustDown, keys.escape)
        if ok_esc and esc == true then
            if options.escape_clears == true then new_value = "" end
            clear_text_focus(focus_key, "escape")
            active = false
        end
    end
    if keys.backspace ~= nil and active then
        local ok_down, down = pcall(InputIsKeyDown, keys.backspace)
        if ok_down and down == true then
            if search_repeat.key ~= focus_key then
                search_repeat.key, search_repeat.started, search_repeat.last = focus_key, frame, frame
            elseif new_value == value and frame - search_repeat.started >= 18 and frame - search_repeat.last >= 3 then
                local ctrl = false
                for _, key in ipairs({keys.ctrl_l, keys.ctrl_r}) do
                    if key ~= nil then
                        local ok_ctrl, down_ctrl = pcall(InputIsKeyDown, key)
                        ctrl = ctrl or (ok_ctrl and down_ctrl == true)
                    end
                end
                new_value = ctrl and utf8_pop_word(new_value) or utf8_pop(new_value)
                search_repeat.last = frame
            end
        elseif search_repeat.key == focus_key then
            search_repeat.key, search_repeat.started, search_repeat.last = nil, -1, -1
        end
    end
    return new_value, focused_text_key() == focus_key
end

function ui_runtime.text_input_active()
    return text_entry_guard.active()
end

function ui_runtime.text_input_focus_key()
    return focused_text_key()
end

function ui_runtime.blur_text_input(reason)
    return clear_text_focus(nil, reason or "context_changed")
end

function ui_runtime.search_input(value, width, max_length, focus_key)
    value = tostring(value or "")
    focus_key = tostring(focus_key or "search")
    local field_width = math.max(68, tonumber(width) or 112)
    GuiLayoutBeginHorizontal(gui, 0, 0, true)
    local new_value = ui_runtime.text_input(value, field_width, max_length, focus_key, {
        clear_on_reset=true, escape_clears=true,
        placeholder=ui_runtime.tr("$mcm_search_placeholder", "Search..."),
    })
    if new_value ~= "" and ui_runtime.button(0, 0, "X") then
        new_value = ""
        clear_text_focus()
    end
    GuiLayoutEnd(gui)
    return new_value
end

local function expanded_search_fields(...)
    local fields, seen = {}, {}
    local function add(value)
        if type(value) == "table" then
            for _, nested in ipairs(value) do add(nested) end
            return
        end
        value = tostring(value or "")
        if value == "" or seen[value] then return end
        seen[value], fields[#fields + 1] = true, value
        if string.sub(value, 1, 1) == "$" then
            for _, alias in ipairs(ui_runtime.search_aliases(value, value)) do
                alias = tostring(alias or "")
                if alias ~= "" and not seen[alias] then seen[alias], fields[#fields + 1] = true, alias end
            end
        end
    end
    for index = 1, select("#", ...) do
        add(select(index, ...))
    end
    return fields
end

function ui_runtime.search_score(query, ...)
    return search_engine.score(query, expanded_search_fields(...))
end

function ui_runtime.matches_search(query, ...)
    return ui_runtime.search_score(query, ...) ~= nil
end

function ui_runtime.rank_entries(query, entries, fields_for, identity_for)
    entries = type(entries) == "table" and entries or {}
    query = tostring(query or "")
    if query == "" then return entries end
    fields_for = type(fields_for) == "function" and fields_for or function(entry) return entry end
    identity_for = type(identity_for) == "function" and identity_for or function(entry) return tostring(entry) end
    local ranked = {}
    for index, entry in ipairs(entries) do
        local score = ui_runtime.search_score(query, fields_for(entry))
        if score ~= nil then
            ranked[#ranked + 1] = {entry=entry, score=score, index=index, identity=tostring(identity_for(entry) or "")}
        end
    end
    table.sort(ranked, function(a, b)
        if a.score ~= b.score then return a.score > b.score end
        if a.identity ~= b.identity then return a.identity < b.identity end
        return a.index < b.index
    end)
    local result = {}
    for _, record in ipairs(ranked) do result[#result + 1] = record.entry end
    return result
end

function ui_runtime.search_status(query, count)
    if tostring(query or "") == "" then return end
    count = math.max(0, math.floor(tonumber(count) or 0))
    if count == 0 then
        ui_runtime.white_text(2, 1, ui_runtime.tr("$mcm_no_results", "No results"))
    else
        ui_runtime.white_text(0, 1, ui_runtime.tr("$mcm_results", "Results") .. ": " .. tostring(count))
    end
end

function ui_runtime.resolve(path)
    if type(path) ~= "string" or path == "" then return nil end
    local asset = asset_api.resolve(path)
    return asset_api.path(asset)
end

function ui_runtime.entity_icon(path, role)
    local asset = asset_api.resolve_entity(path, role)
    return asset_api.path(asset)
end

function ui_runtime.dimensions(path) return asset_api.dimensions(path) end

local SOLID_TEXTURE = "data/ui_gfx/health_slider_front.png"

draw_colored_rect = function(x, y, width, height, color, z)
    if type(color) ~= "table" or width <= 0 or height <= 0 then return end
    local r = math.max(0, math.min(1, tonumber(color[1]) or 1))
    local g = math.max(0, math.min(1, tonumber(color[2]) or 1))
    local b = math.max(0, math.min(1, tonumber(color[3]) or 1))
    local alpha = math.max(0, math.min(1, tonumber(color[4]) or 0.95))
    local texture_w, texture_h = ui_runtime.dimensions(SOLID_TEXTURE)
    texture_w, texture_h = math.max(1, tonumber(texture_w) or 24), math.max(1, tonumber(texture_h) or 4)
    GuiOptionsAddForNextWidget(gui, GUI_OPTION.Layout_NoLayouting)
    GuiColorSetForNextWidget(gui, r, g, b, alpha)
    GuiZSetForNextWidget(gui, z or -106)
    GuiImage(gui, ui_runtime.next_id(), x, y, SOLID_TEXTURE, 1, width / texture_w, height / texture_h)
end

function ui_runtime.resize_affordances(x, y, width, height, hovered_edges, active_drag)
    x, y = tonumber(x) or 0, tonumber(y) or 0
    width, height = math.max(16, tonumber(width) or 16), math.max(16, tonumber(height) or 16)
    hovered_edges = type(hovered_edges) == "table" and hovered_edges or {}
    local base = {0.43,0.32,0.19,0.88}
    local hover = {0.60,0.45,0.25,0.95}
    local active = {0.72,0.53,0.28,1.00}
    local shadow = {0.17,0.12,0.07,0.62}
    local accent = active_drag == true and active or hover
    local top = hovered_edges.top and accent or base
    local bottom = hovered_edges.bottom and accent or base
    local left = hovered_edges.left and accent or base
    local right = hovered_edges.right and accent or base

    -- The visible frame straddles the measured AutoBox edge; resize hitboxes use the
    -- same outset so every visible edge remains reachable after viewport clamping.
    local outset, thickness = 2, 5
    local outer_x, outer_y = x - outset, y - outset
    local outer_w, outer_h = width + outset * 2, height + outset * 2
    draw_colored_rect(outer_x, outer_y, outer_w, thickness, top, -109)
    draw_colored_rect(outer_x, outer_y + outer_h - thickness, outer_w, thickness, bottom, -109)
    draw_colored_rect(outer_x, outer_y, thickness, outer_h, left, -109)
    draw_colored_rect(outer_x + outer_w - thickness, outer_y, thickness, outer_h, right, -109)
    draw_colored_rect(x + 3, y + 3, math.max(1, width - 6), 1, shadow, -108)
    draw_colored_rect(x + 3, y + height - 4, math.max(1, width - 6), 1, shadow, -108)
    draw_colored_rect(x + 3, y + 3, 1, math.max(1, height - 6), shadow, -108)
    draw_colored_rect(x + width - 4, y + 3, 1, math.max(1, height - 6), shadow, -108)
end

local function draw_marker(actual_x, actual_y, actual_w, actual_h, marker)
    if type(marker) ~= "table" then return end
    draw_colored_rect(actual_x + 2, actual_y + actual_h - 3,
        math.max(1, actual_w - 4), 2, marker, -107)
end

local function draw_bottle_fill(actual_x, actual_y, actual_w, actual_h, color)
    if type(color) ~= "table" then return end
    -- The vanilla inventory bottle is a grayscale silhouette. A small colour patch
    -- drawn over its lower bulb reads as the liquid while leaving the bright glass
    -- rim visible. Keeping the patch inside the silhouette avoids a square swatch
    -- floating outside the bottle at unusual UI scales.
    draw_colored_rect(actual_x + actual_w * 0.36, actual_y + actual_h * 0.58,
        actual_w * 0.28, actual_h * 0.25, color, -106)
end

local function draw_material_swatch(actual_x, actual_y, actual_w, actual_h, color)
    if type(color) ~= "table" then return end
    draw_colored_rect(actual_x + 2, actual_y + 2,
        math.max(1, actual_w - 4), math.max(1, actual_h - 4), color, -105)
    -- A narrow highlight keeps very dark materials readable while still showing their
    -- actual primary in-world colour instead of a generic material bag.
    draw_colored_rect(actual_x + 3, actual_y + 3,
        math.max(1, actual_w - 6), 2,
        { math.min(1, (color[1] or 0) + 0.18), math.min(1, (color[2] or 0) + 0.18),
          math.min(1, (color[3] or 0) + 0.18), color[4] or 0.96 }, -106)
end

function ui_runtime.tile(x, y, background, icon, fallback_icon, title, description, selected, options)
    options = type(options) == "table" and options or {}
    background = ui_runtime.resolve(background or ui_runtime.EMPTY_SLOT) or ui_runtime.EMPTY_SLOT
    if selected then GuiColorSetForNextWidget(gui, 1.0, 0.78, 0.2, 1.0) end

    GuiZSetForNextWidget(gui, -103)
    local clicked, right_clicked = GuiImageButton(gui, ui_runtime.next_id(), x, y, "", background)
    if not ui_runtime.actions_allowed() then clicked, right_clicked = false, false end
    local _, _, is_hovered, actual_x, actual_y, actual_w, actual_h = GuiGetPreviousWidgetInfo(gui)
    ui_runtime.mark_hovered(is_hovered)
    show_tooltip(title, description)

    actual_x = tonumber(actual_x) or 0
    actual_y = tonumber(actual_y) or 0
    actual_w = tonumber(actual_w) or 18
    actual_h = tonumber(actual_h) or 18

    draw_material_swatch(actual_x, actual_y, actual_w, actual_h, options.swatch_color)
    local draw_icon = ui_runtime.resolve(icon) or ui_runtime.resolve(fallback_icon)
    local icon_w, icon_h = ui_runtime.dimensions(draw_icon)
    if type(draw_icon) == "string" and draw_icon ~= "" and icon_w ~= nil and icon_h ~= nil then
        local padding = math.max(0, tonumber(options.padding) or 1)
        local target = tonumber(options.target_size) or math.min(actual_w, actual_h)
        local max_scale = tonumber(options.max_scale) or 2.0
        local fill = math.max(0.5, tonumber(options.fill) or 1.0)
        local icon_box = tonumber(options.icon_box_size)
        local base_w = icon_box ~= nil and icon_box or math.max(1, actual_w - padding * 2)
        local base_h = icon_box ~= nil and icon_box or math.max(1, actual_h - padding * 2)
        local available_w = math.min(target, base_w) * fill
        local available_h = math.min(target, base_h) * fill
        local scale = math.min(available_w / icon_w, available_h / icon_h, max_scale)
        if scale > 0 then
            local rendered_w, rendered_h = icon_w * scale, icon_h * scale
            GuiOptionsAddForNextWidget(gui, GUI_OPTION.Layout_NoLayouting)
            local tint = options.icon_tint
            if type(tint) == "table" then
                GuiColorSetForNextWidget(gui, tonumber(tint[1]) or 1, tonumber(tint[2]) or 1,
                    tonumber(tint[3]) or 1, tonumber(tint[4]) or 1)
            end
            GuiZSetForNextWidget(gui, -105)
            GuiImage(gui, ui_runtime.next_id(), actual_x + (actual_w - rendered_w) * 0.5,
                actual_y + (actual_h - rendered_h) * 0.5, draw_icon, 1, scale, scale)
        end
    end
    draw_bottle_fill(actual_x, actual_y, actual_w, actual_h, options.bottle_fill_color)
    draw_marker(actual_x, actual_y, actual_w, actual_h, options.marker_color)
    clear_search_focus_on_action(clicked == true or right_clicked == true)
    return clicked == true, right_clicked == true, is_hovered == true, actual_x, actual_y, actual_w, actual_h
end

function ui_runtime.drag_ghost(background, icon, x, y, options)
    options = type(options) == "table" and options or {}
    x, y = tonumber(x), tonumber(y)
    if x == nil or y == nil then return end
    background = ui_runtime.resolve(background or ui_runtime.EMPTY_SLOT) or ui_runtime.EMPTY_SLOT
    GuiOptionsAddForNextWidget(gui, GUI_OPTION.Layout_NoLayouting)
    GuiColorSetForNextWidget(gui, 1, 1, 1, 0.78)
    GuiZSetForNextWidget(gui, -120)
    GuiImage(gui, ui_runtime.next_id(), x + 5, y + 5, background, 0.78, 1, 1)
    local draw_icon = ui_runtime.resolve(icon)
    local icon_w, icon_h = ui_runtime.dimensions(draw_icon)
    if draw_icon ~= nil and icon_w ~= nil and icon_h ~= nil and icon_w > 0 and icon_h > 0 then
        local scale = math.min(16 / icon_w, 16 / icon_h, 2)
        GuiOptionsAddForNextWidget(gui, GUI_OPTION.Layout_NoLayouting)
        GuiColorSetForNextWidget(gui, 1, 1, 1, 0.9)
        GuiZSetForNextWidget(gui, -121)
        GuiImage(gui, ui_runtime.next_id(), x + 6 + (16 - icon_w * scale) * 0.5, y + 6 + (16 - icon_h * scale) * 0.5,
            draw_icon, 0.9, scale, scale)
    end
    if type(options.bottle_fill_color) == "table" then
        draw_colored_rect(x + 5 + 18 * 0.36, y + 5 + 18 * 0.58,
            18 * 0.28, 18 * 0.25, options.bottle_fill_color, -122)
    end
end

function ui_runtime.finish_auto_box(padding, minimum_width, minimum_height)
    GuiZSetForNextWidget(gui, ui_runtime.BACKGROUND_Z)
    GuiEndAutoBoxNinePiece(gui, padding or 4,
        math.max(0, tonumber(minimum_width) or 0), math.max(0, tonumber(minimum_height) or 0))
    local _, _, is_hovered, actual_x, actual_y, actual_w, actual_h = GuiGetPreviousWidgetInfo(gui)
    ui_runtime.mark_hovered(is_hovered)
    return tonumber(actual_x), tonumber(actual_y), tonumber(actual_w), tonumber(actual_h)
end

function ui_runtime.grid_metrics(container_width, step, options)
    return scroll_model.grid_metrics(container_width, step or ui_runtime.ICON_STEP, options)
end

function ui_runtime.columns(container_width, step, options)
    return ui_runtime.grid_metrics(container_width or 260, step or ui_runtime.ICON_STEP, options).columns
end

local function scroll_state_for(key)
    key = tostring(key or "scroll")
    local state = scroll_states[key]
    if state == nil then
        state = {offset=0, content_height=0}
        scroll_states[key] = state
    end
    return state
end

-- Keep scroll contents inside Noita's native container coordinate space. Starting a
-- GuiLayout layer *inside* a scroll container detaches its children from that space in
-- the real engine (their origin becomes the top-left of the screen), even though this is
-- easy to miss in a Lua-only layout mock. The shared wrapper still centralises geometry
-- and padding, but lets the engine own the vertical offset and clipping.
function ui_runtime.begin_scroll_viewport(key, id, x, y, width, height, options)
    options = type(options) == "table" and options or {}
    width = math.max(16, tonumber(width) or 220)
    height = math.max(16, tonumber(height) or 80)
    local padding_left = math.max(0, tonumber(options.padding_left) or scroll_model.PADDING_X)
    local padding_right = math.max(0, tonumber(options.padding_right) or scroll_model.PADDING_X)
    local padding_top = math.max(0, tonumber(options.padding_top) or scroll_model.PADDING_Y)
    local padding_bottom = math.max(0, tonumber(options.padding_bottom) or scroll_model.PADDING_Y)
    local scrollbar_width = options.reserve_scrollbar == false and 0
        or math.max(0, tonumber(options.scrollbar_width) or scroll_model.SCROLLBAR_WIDTH)
    local state = scroll_state_for(key)
    local viewport_height = math.max(1, height - padding_top - padding_bottom)
    -- Manual offsets belonged to the detached-layer implementation. Reset them so a
    -- save/reload or hot-reload cannot shift correctly attached native contents twice.
    state.offset = 0

    GuiBeginScrollContainer(gui, id, x or 0, y or 0, width, height, false, 0, 0)
    local _, _, is_hovered, actual_x, actual_y, actual_w, actual_h = GuiGetPreviousWidgetInfo(gui)
    actual_x, actual_y = tonumber(actual_x) or tonumber(x) or 0, tonumber(actual_y) or tonumber(y) or 0
    actual_w, actual_h = math.max(1, tonumber(actual_w) or width), math.max(1, tonumber(actual_h) or height)
    ui_runtime.mark_hovered(is_hovered)

    local layout_mode = options.layout == "free" and "free" or "vertical"
    if layout_mode == "vertical" then
        GuiLayoutBeginVertical(gui, padding_left, padding_top, true, 0, 0)
    end
    return {
        key=tostring(key or "scroll"), state=state, hovered=is_hovered == true,
        x=actual_x, y=actual_y, width=actual_w, height=actual_h,
        padding_left=padding_left, padding_right=padding_right,
        padding_top=padding_top, padding_bottom=padding_bottom,
        scrollbar_width=scrollbar_width,
        content_width=math.max(1, actual_w - padding_left - padding_right - scrollbar_width),
        viewport_height=math.max(1, actual_h - padding_top - padding_bottom),
        step=math.max(1, tonumber(options.step) or scroll_model.VERTICAL_STEP),
        layout_mode=layout_mode,
    }
end

function ui_runtime.scroll_y(context, y)
    if type(context) ~= "table" then return tonumber(y) or 0 end
    return context.padding_top + (tonumber(y) or 0)
end

function ui_runtime.end_scroll_viewport(context, explicit_content_height)
    if type(context) ~= "table" or type(context.state) ~= "table" then return end
    if context.layout_mode == "vertical" then
        -- A transparent sentinel gives tests/diagnostics a stable logical content
        -- height; it remains in the native scroll coordinate space.
        GuiColorSetForNextWidget(gui, 1, 1, 1, 0)
        GuiZSetForNextWidget(gui, -99)
        GuiText(gui, 0, 0, " ")
        local _, _, _, _, sentinel_y, _, sentinel_h = GuiGetPreviousWidgetInfo(gui)
        sentinel_y, sentinel_h = tonumber(sentinel_y), tonumber(sentinel_h)
        if sentinel_y ~= nil and sentinel_h ~= nil then
            local logical_top = context.y + context.padding_top
            context.state.content_height = math.max(0, sentinel_y + sentinel_h - logical_top)
        end
        GuiLayoutEnd(gui)
    else
        context.state.content_height = math.max(0, tonumber(explicit_content_height) or context.state.content_height or 0)
    end
    GuiEndScrollContainer(gui)
    context.state.maximum = math.max(0, context.state.content_height - context.viewport_height)
    context.state.drag = nil
    return 0, context.state.maximum, context.state.content_height
end

function ui_runtime.grid_height(available_height, reserved_height)
    -- Catalogues consume the remaining resizable panel height instead of a fixed height.
    return math.max(64, (tonumber(available_height) or 240) - (tonumber(reserved_height) or 110))
end

-- Catalogues measure the last real widget above them and consume the remaining panel
-- height. The numeric fallback keeps isolated tabs/tests usable, while real menu layout
-- no longer depends on guessed per-tab constants or the number of translated rows.
function ui_runtime.scroll_height(available_height, reserved_height, bottom_padding)
    local fallback = ui_runtime.grid_height(available_height, reserved_height)
    if panel_bounds == nil or type(GuiGetPreviousWidgetInfo) ~= "function" then return fallback end
    local ok, _, _, _, _, actual_y, _, actual_h = pcall(GuiGetPreviousWidgetInfo, gui)
    actual_y, actual_h = tonumber(actual_y), tonumber(actual_h)
    if not ok or actual_y == nil or actual_h == nil or actual_h < 0 then return fallback end
    local target_bottom = panel_bounds.y + panel_bounds.height
        - math.max(2, tonumber(bottom_padding) or 7)
    if actual_y < panel_bounds.y - 8 or actual_y > target_bottom + 8 then return fallback end
    local remaining = math.floor(target_bottom - (actual_y + actual_h) - 2)
    local maximum = math.max(64, math.floor(panel_bounds.height - 28))
    return math.max(64, math.min(maximum, remaining))
end

METAMORPH_CREATIVE_MENU_UI_RUNTIME = ui_runtime
return ui_runtime
