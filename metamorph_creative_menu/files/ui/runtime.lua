if type(METAMORPH_CREATIVE_MENU_UI_RUNTIME) == "table" then return METAMORPH_CREATIVE_MENU_UI_RUNTIME end

local ui_runtime = {}

local asset_api = dofile("mods/metamorph_creative_menu/files/platform/noita/assets.lua")
local input_guard = dofile("mods/metamorph_creative_menu/files/platform/noita/input_guard.lua")
local keycodes = dofile("mods/metamorph_creative_menu/files/platform/noita/keycodes.lua")

local gui = nil
local next_widget_id = 1000
local hovered = false
local search_focus = nil
local search_keycodes = nil
local search_repeat = { key = nil, started = -1, last = -1 }

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
end

function ui_runtime.gui() return gui end
function ui_runtime.next_id() next_widget_id = next_widget_id + 1; return next_widget_id end

function ui_runtime.translated(text)
    if text == nil or text == "" then return "" end
    return GameTextGetTranslatedOrNot(text)
end

function ui_runtime.tr(key, fallback)
    local value = ui_runtime.translated(key)
    if value == nil or value == "" or value == key then return fallback or key end
    return value
end

function ui_runtime.audit(action, details)
    if type(METAMORPH_CREATIVE_MENU_DIAGNOSTICS_USER_ACTION) == "function" then
        pcall(METAMORPH_CREATIVE_MENU_DIAGNOSTICS_USER_ACTION, action, details)
    end
end

function ui_runtime.actions_allowed() return input_guard.actions_allowed() end
function ui_runtime.mark_hovered(value) if value == true then hovered = true end end
function ui_runtime.hovered() return hovered end

function ui_runtime.white_text(x, y, text)
    GuiColorSetForNextWidget(gui, 1, 1, 1, 1)
    GuiZSetForNextWidget(gui, -102)
    GuiText(gui, x, y, text or "")
end

local function clear_search_focus_on_action(clicked)
    if clicked == true then search_focus = nil end
end

function ui_runtime.button(x, y, text, selected)
    if selected then GuiColorSetForNextWidget(gui, 1.0, 0.78, 0.2, 1.0)
    else GuiColorSetForNextWidget(gui, 1, 1, 1, 1) end
    GuiZSetForNextWidget(gui, -103)
    local clicked = GuiButton(gui, ui_runtime.next_id(), x, y, text or "")
    local _, _, is_hovered = GuiGetPreviousWidgetInfo(gui)
    ui_runtime.mark_hovered(is_hovered)
    local accepted = clicked == true and ui_runtime.actions_allowed()
    clear_search_focus_on_action(accepted)
    return accepted
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

-- Centralized native text input. GuiTextInput is the only text-entry widget exposed by
-- Noita. Keeping it behind the same input quarantine as every other action means a
-- stale Alt-Tab event can never edit a query or trigger a neighbouring action.
function ui_runtime.search_input(value, width, max_length, focus_key)
    value = tostring(value or "")
    focus_key = tostring(focus_key or "search")
    local field_width = math.max(68, tonumber(width) or 112)

    GuiLayoutBeginHorizontal(gui, 0, 0, true)
    -- A single slash is deliberately used instead of a wide SEARCH label: it reads as
    -- a filter/search affordance in every language and keeps dense catalog tabs compact.
    ui_runtime.white_text(0, 1, "/")
    GuiColorSetForNextWidget(gui, 1, 1, 1, 1)
    GuiZSetForNextWidget(gui, -103)
    local ok, new_value = pcall(GuiTextInput, gui, ui_runtime.next_id(), 0, 0, value,
        field_width, math.max(8, tonumber(max_length) or 64), "")
    local clicked, _, is_hovered = GuiGetPreviousWidgetInfo(gui)
    ui_runtime.mark_hovered(is_hovered)
    if clicked == true or (ok and type(new_value) == "string" and new_value ~= value) then
        search_focus = focus_key
    end
    if not ok or not ui_runtime.actions_allowed() then new_value = value end

    -- GuiTextInput accepts held keyboard input differently across Noita builds. Keep
    -- native editing authoritative, but if a held Backspace produced no native change,
    -- provide deterministic repeat after a short delay. This never double-erases a
    -- frame where GuiTextInput already changed the value.
    if search_focus == focus_key and ui_runtime.actions_allowed() then
        local keys = load_search_keycodes()
        local frame = GameGetFrameNum()
        if keys.escape ~= nil then
            local ok_esc, esc = pcall(InputIsKeyJustDown, keys.escape)
            if ok_esc and esc == true then new_value, search_focus = "", nil end
        end
        if keys.backspace ~= nil then
            local ok_down, down = pcall(InputIsKeyDown, keys.backspace)
            if ok_down and down == true then
                if search_repeat.key ~= focus_key then
                    search_repeat.key, search_repeat.started, search_repeat.last = focus_key, frame, frame
                elseif type(new_value) == "string" and new_value == value
                    and frame - search_repeat.started >= 18 and frame - search_repeat.last >= 3
                then
                    local ctrl = false
                    for _, key in ipairs({keys.ctrl_l, keys.ctrl_r}) do
                        if key ~= nil then local ok_ctrl, down_ctrl = pcall(InputIsKeyDown, key); ctrl = ctrl or (ok_ctrl and down_ctrl == true) end
                    end
                    new_value = ctrl and utf8_pop_word(new_value) or utf8_pop(new_value)
                    search_repeat.last = frame
                end
            elseif search_repeat.key == focus_key then
                search_repeat.key, search_repeat.started, search_repeat.last = nil, -1, -1
            end
        end
    end

    if new_value ~= "" and ui_runtime.button(0, 0, "X") then
        new_value, search_focus = "", nil
    end
    GuiLayoutEnd(gui)
    return type(new_value) == "string" and new_value or value
end

local function utf8_encode_codepoint(codepoint)
    if codepoint < 0x80 then return string.char(codepoint) end
    if codepoint < 0x800 then
        return string.char(0xC0 + math.floor(codepoint / 0x40), 0x80 + (codepoint % 0x40))
    end
    if codepoint < 0x10000 then
        return string.char(0xE0 + math.floor(codepoint / 0x1000),
            0x80 + (math.floor(codepoint / 0x40) % 0x40), 0x80 + (codepoint % 0x40))
    end
    return string.char(0xF0 + math.floor(codepoint / 0x40000),
        0x80 + (math.floor(codepoint / 0x1000) % 0x40),
        0x80 + (math.floor(codepoint / 0x40) % 0x40), 0x80 + (codepoint % 0x40))
end

local function lower_search(value)
    value = string.lower(tostring(value or ""))
    local out, index, length = {}, 1, #value
    while index <= length do
        local first = string.byte(value, index)
        local codepoint, width
        if first < 0x80 then
            codepoint, width = first, 1
        elseif first < 0xE0 and index + 1 <= length then
            codepoint = (first - 0xC0) * 0x40 + (string.byte(value, index + 1) - 0x80)
            width = 2
        elseif first < 0xF0 and index + 2 <= length then
            codepoint = (first - 0xE0) * 0x1000
                + (string.byte(value, index + 1) - 0x80) * 0x40
                + (string.byte(value, index + 2) - 0x80)
            width = 3
        elseif index + 3 <= length then
            codepoint = (first - 0xF0) * 0x40000
                + (string.byte(value, index + 1) - 0x80) * 0x1000
                + (string.byte(value, index + 2) - 0x80) * 0x40
                + (string.byte(value, index + 3) - 0x80)
            width = 4
        else
            out[#out + 1], index = string.sub(value, index, index), index + 1
            codepoint = nil
        end
        if codepoint ~= nil then
            -- Russian uppercase U+0410..U+042F maps to lowercase by +0x20.
            -- U+0401/U+0451 (Yo/yo) is normalized to U+0435 (e) for search.
            if codepoint >= 0x0410 and codepoint <= 0x042F then codepoint = codepoint + 0x20 end
            if codepoint == 0x0401 or codepoint == 0x0451 then codepoint = 0x0435 end
            out[#out + 1] = utf8_encode_codepoint(codepoint)
            index = index + width
        end
    end
    return table.concat(out)
end

local normalized_search_cache = {}
local last_query_text = nil
local last_query_positive = nil
local last_query_negative = nil

local function normalize_search(value)
    local cache_key = tostring(value or "")
    local cached = normalized_search_cache[cache_key]
    if cached ~= nil then return cached end
    value = lower_search(cache_key)
    value = string.gsub(value, "[_%-%./\\]+", " ")
    value = string.gsub(value, "%s+", " ")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    normalized_search_cache[cache_key] = value
    return value
end

local function query_terms(query)
    local query_key = tostring(query or "")
    if query_key == last_query_text then return last_query_positive, last_query_negative end
    local positive, negative = {}, {}
    query = lower_search(query_key)
    -- Detect exclusion prefixes BEFORE separator normalization: normalizing the whole
    -- query first would turn "-boss" into " boss" and silently lose the operator.
    for raw in string.gmatch(query, "%S+") do
        local excluded = (string.sub(raw, 1, 1) == "!" or string.sub(raw, 1, 1) == "-") and #raw > 1
        local body = excluded and string.sub(raw, 2) or raw
        body = normalize_search(body)
        for token in string.gmatch(body, "%S+") do
            local target = excluded and negative or positive
            target[#target + 1] = token
        end
    end
    last_query_text = query_key
    last_query_positive = positive
    last_query_negative = negative
    return positive, negative
end

-- Search is token based rather than a single literal substring. "fire bolt" means
-- both words may occur anywhere across name/id/path/description; -boss or !boss excludes
-- a term. Separators in ids and file paths are normalized to spaces, so e.g.
-- "extra hp" matches EXTRA_HP and paths containing extra_hp.
function ui_runtime.matches_search(query, ...)
    local positive, negative = query_terms(query)
    if #positive == 0 and #negative == 0 then return true end
    local haystacks = {}
    for index = 1, select("#", ...) do
        local value = normalize_search(select(index, ...))
        if value ~= "" then haystacks[#haystacks + 1] = value end
    end
    local joined = table.concat(haystacks, " ")
    for _, token in ipairs(negative) do
        if token ~= "" and string.find(joined, token, 1, true) ~= nil then return false end
    end
    for _, token in ipairs(positive) do
        if token ~= "" and string.find(joined, token, 1, true) == nil then return false end
    end
    return true
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

local function draw_colored_rect(x, y, width, height, color, z)
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

function ui_runtime.tile(x, y, background, icon, fallback_icon, title, description, selected, options)
    options = type(options) == "table" and options or {}
    background = ui_runtime.resolve(background or ui_runtime.EMPTY_SLOT) or ui_runtime.EMPTY_SLOT
    if selected then GuiColorSetForNextWidget(gui, 1.0, 0.78, 0.2, 1.0) end

    GuiZSetForNextWidget(gui, -103)
    local clicked, right_clicked = GuiImageButton(gui, ui_runtime.next_id(), x, y, "", background)
    if not ui_runtime.actions_allowed() then clicked, right_clicked = false, false end
    local _, _, is_hovered, actual_x, actual_y, actual_w, actual_h = GuiGetPreviousWidgetInfo(gui)
    ui_runtime.mark_hovered(is_hovered)
    GuiTooltip(gui, title or "", description or "")

    actual_x = tonumber(actual_x) or 0
    actual_y = tonumber(actual_y) or 0
    actual_w = tonumber(actual_w) or 18
    actual_h = tonumber(actual_h) or 18

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
            GuiZSetForNextWidget(gui, -105)
            GuiImage(gui, ui_runtime.next_id(), actual_x + (actual_w - rendered_w) * 0.5,
                actual_y + (actual_h - rendered_h) * 0.5, draw_icon, 1, scale, scale)
        end
    end
    draw_bottle_fill(actual_x, actual_y, actual_w, actual_h, options.bottle_fill_color)
    draw_marker(actual_x, actual_y, actual_w, actual_h, options.marker_color)
    clear_search_focus_on_action(clicked == true or right_clicked == true)
    return clicked == true, right_clicked == true, is_hovered == true
end

function ui_runtime.finish_auto_box(padding)
    GuiZSetForNextWidget(gui, ui_runtime.BACKGROUND_Z)
    GuiEndAutoBoxNinePiece(gui, padding or 4)
    local _, _, is_hovered = GuiGetPreviousWidgetInfo(gui)
    ui_runtime.mark_hovered(is_hovered)
end

function ui_runtime.columns(panel_width, step)
    step = math.max(1, tonumber(step) or ui_runtime.ICON_STEP)
    return math.max(1, math.floor(((tonumber(panel_width) or 260) - 8) / step))
end

function ui_runtime.grid_height(screen_height, preferred, reserved)
    return math.max(64, math.min(preferred or 190, (tonumber(screen_height) or 240) - (reserved or 110)))
end

METAMORPH_CREATIVE_MENU_UI_RUNTIME = ui_runtime
return ui_runtime
