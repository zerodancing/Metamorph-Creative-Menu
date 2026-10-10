if type(METAMORPH_CREATIVE_MENU_FIXED_NUMERIC_EDITOR) == "table" then
    return METAMORPH_CREATIVE_MENU_FIXED_NUMERIC_EDITOR
end

local numeric_editor = {}
local ui = dofile("mods/metamorph_creative_menu/files/ui/runtime.lua")

local drafts = {}

local function format_number(value, integer)
    value = tonumber(value)
    if value == nil then return "?" end
    if integer then return tostring(math.floor(value + (value >= 0 and 0.5 or -0.5))) end
    return string.format("%.6g", value)
end

local function truncate_to_width(text, width)
    text = tostring(text or "")
    width = math.max(1, tonumber(width) or 1)
    if ui.text_width(text) <= width then return text end
    if type(ui.truncate_text) == "function" then return ui.truncate_text(text, width) end
    local suffix = "..."
    local result = ""
    local allowed = math.max(1, width - ui.text_width(suffix))
    for character in string.gmatch(text, "[\1-\127\194-\244][\128-\191]*") do
        if ui.text_width(result .. character) > allowed then break end
        result = result .. character
    end
    return result .. suffix
end

local function fixed_label(text, width, tooltip_description)
    width = math.max(8, tonumber(width) or 86)
    text = tostring(text or "")
    local display = truncate_to_width(text, width)
    ui.white_text(0, 1, display)
    if tooltip_description ~= nil and tostring(tooltip_description) ~= "" and type(GuiTooltip) == "function" then
        GuiTooltip(ui.gui(), text, tostring(tooltip_description))
    elseif display ~= text and type(GuiTooltip) == "function" then
        GuiTooltip(ui.gui(), text)
    end
    GuiLayoutAddHorizontalSpacing(ui.gui(), math.max(0, width - ui.text_width(display)))
end

local function button_natural_width(label)
    return math.max(8, ui.text_width(label) + 6)
end

local function fixed_button(label, width)
    width = math.max(8, tonumber(width) or button_natural_width(label))
    local clicked = ui.button(0, 0, label)
    GuiLayoutAddHorizontalSpacing(ui.gui(), math.max(0, width - button_natural_width(label)))
    return clicked
end

-- A numeric stat always uses the same four columns: label, decrement, field, increment.
-- Widths depend only on the panel and options, never on the current value/draft. This is
-- especially important for capacity: 1 -> 26 -> 64 must not move either arrow under the
-- pointer. Long translations are clipped inside the label cell instead of pushing controls.
local function row_layout(options)
    options = type(options) == "table" and options or {}
    local available = math.max(64, tonumber(options.max_width) or 220)
    local left_label = tostring(options.left_label or "<")
    local right_label = tostring(options.right_label or ">")
    local left_width = math.max(12, tonumber(options.arrow_width) or button_natural_width(left_label))
    local right_width = math.max(12, tonumber(options.arrow_width) or button_natural_width(right_label))
    local suffix = tostring(options.suffix or "")
    local suffix_width = suffix ~= "" and math.max(8, tonumber(options.suffix_width) or 12) or 0
    local preferred_value = math.max(36, tonumber(options.value_width) or 58)
    local preferred_label = math.max(28, tonumber(options.label_width) or 94)
    local minimum_label = math.max(8, tonumber(options.min_label_width) or 8)

    local fixed = left_width + right_width + suffix_width
    local value_width = math.min(preferred_value, math.max(36, available - fixed - minimum_label))
    local label_width = math.min(preferred_label, math.max(minimum_label, available - fixed - value_width))
    if label_width + fixed + value_width > available then
        label_width = math.max(8, available - fixed - value_width)
    end
    return {
        available=available,
        label_width=label_width,
        left_width=left_width,
        value_width=value_width,
        right_width=right_width,
        suffix_width=suffix_width,
        left_label=left_label,
        right_label=right_label,
        suffix=suffix,
    }
end

function numeric_editor.reset(prefix)
    local focused_key = type(ui.text_input_focus_key) == "function" and ui.text_input_focus_key() or nil
    if prefix == nil then
        if focused_key ~= nil and type(ui.blur_text_input) == "function" then
            ui.blur_text_input("numeric_reset")
        end
        drafts = {}
        return
    end
    prefix = tostring(prefix)
    if focused_key ~= nil and string.sub(focused_key, 1, #prefix) == prefix
        and type(ui.blur_text_input) == "function"
    then
        ui.blur_text_input("numeric_reset")
    end
    for key in pairs(drafts) do
        if string.sub(key, 1, #prefix) == prefix then drafts[key] = nil end
    end
end

function numeric_editor.draw(key, label, current, options)
    options = type(options) == "table" and options or {}
    key = tostring(key or "numeric")
    local integer = options.integer == true
    local step = tonumber(options.step) or 1
    local current_number = tonumber(current)
    local canonical = format_number(current_number, integer)
    if drafts[key] == nil or options.force_sync == true then drafts[key] = canonical end

    local changed, last_error = false, nil
    local value_chars = tonumber(options.value_chars) or 24
    local layout = row_layout(options)

    local function normalize_candidate(value)
        value = tonumber(value)
        if value == nil or value ~= value or value == math.huge or value == -math.huge then return nil end
        if integer then value = math.floor(value + (value >= 0 and 0.5 or -0.5)) end
        local minimum = tonumber(options.min)
        local maximum = tonumber(options.max)
        if minimum ~= nil then value = math.max(minimum, value) end
        if maximum ~= nil then value = math.min(maximum, value) end
        return value
    end

    local function apply(value, source)
        if type(options.on_apply) ~= "function" then return false, "missing_callback" end
        value = normalize_candidate(value)
        if value == nil then return false, "invalid_value" end
        local ok, reason = options.on_apply(value, source)
        if ok then
            changed = true
            drafts[key] = format_number(value, integer)
        else
            last_error = reason
        end
        return ok
    end

    local before = drafts[key]
    local edited, focused
    -- Numeric values commit as soon as they parse successfully. On blur/context change,
    -- only an unfinished intermediate draft (for example "-" or ".") needs cancelling;
    -- resetting to the current canonical value gives that same rule to clicks, ESC, tab
    -- switches and wand switches, including when the widget disappears before redraw.
    local function cancel_unfinished_draft()
        drafts[key] = canonical
    end

    GuiLayoutBeginHorizontal(ui.gui(), 0, 0, true)
    fixed_label(label, layout.label_width, options.label_tooltip_description)
    if fixed_button(layout.left_label, layout.left_width) and current_number ~= nil then
        apply(current_number - step, "decrement")
    end
    edited, focused = ui.text_input(before, layout.value_width, value_chars, key, {
        allowed_characters=options.allowed_characters or "0123456789.-",
        escape_clears=false,
        on_blur=cancel_unfinished_draft,
    })
    if fixed_button(layout.right_label, layout.right_width) and current_number ~= nil then
        apply(current_number + step, "increment")
    end
    if layout.suffix_width > 0 then fixed_label(layout.suffix, layout.suffix_width) end
    GuiLayoutEnd(ui.gui())

    if edited ~= before then
        drafts[key] = edited
        local numeric = tonumber(edited)
        -- Intermediate values such as '-' or '.' remain editable without generating
        -- an error. A valid number is committed immediately and can be coalesced by
        -- the caller's history layer. Bounded fields replace the draft with the clamped
        -- value returned through apply(), so typing 1000 into a 64-slot field visibly
        -- becomes 64 instead of leaving a stale unsafe number on screen.
        if numeric ~= nil then apply(numeric, "typing") end
    elseif not changed then
        drafts[key] = edited
    end

    if not focused and not changed then drafts[key] = canonical end
    return changed, last_error, drafts[key], focused
end

function numeric_editor.format(value, integer)
    return format_number(value, integer == true)
end

METAMORPH_CREATIVE_MENU_FIXED_NUMERIC_EDITOR = numeric_editor
return numeric_editor
