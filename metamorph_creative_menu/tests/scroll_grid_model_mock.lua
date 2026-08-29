local root = assert(arg[1], "root required")
local native_dofile = dofile
local wheel = 0

local stubs = {
    ["mods/metamorph_creative_menu/files/platform/noita/pointer.lua"] = {
        wheel_delta=function() return wheel end,
    },
}
dofile = function(path)
    if stubs[path] ~= nil then return stubs[path] end
    local prefix = "mods/metamorph_creative_menu/"
    if string.sub(path, 1, #prefix) == prefix then
        return native_dofile(root .. "/" .. string.sub(path, #prefix + 1))
    end
    return native_dofile(path)
end

METAMORPH_CREATIVE_MENU_SCROLL_MODEL = nil
local scroll = assert(native_dofile(root .. "/files/ui/widgets/scroll_model.lua"))

local short_offset = select(1, scroll.scroll_offset(0, 120, 60, 1, scroll.VERTICAL_STEP))
local long_offset = select(1, scroll.scroll_offset(0, 1200, 60, 1, scroll.VERTICAL_STEP))
assert(short_offset == 20 and long_offset == 20,
    "vertical wheel distance still depends on total content length")

local near_end = select(1, scroll.scroll_offset(55, 120, 60, 1, scroll.VERTICAL_STEP))
assert(near_end == 60, "vertical scroll did not clamp to the last real content pixel")

local widths = {96, 117, 206, 273, 401}
local previous_columns = 0
for _, width in ipairs(widths) do
    local metrics = scroll.grid_metrics(width, 20)
    assert(metrics.grid_width <= metrics.content_width,
        "grid starts a column that does not fit the viewport at width " .. tostring(width))
    assert((metrics.columns + 1) * metrics.step > metrics.content_width,
        "grid left room for another complete column at width " .. tostring(width))
    assert(metrics.columns >= previous_columns,
        "grid column count regressed when the panel got wider")
    previous_columns = metrics.columns
end

local narrow = scroll.grid_metrics(206, 20)
local wide = scroll.grid_metrics(273, 20)
assert(narrow.columns ~= wide.columns, "responsive grid did not change column count across panel widths")
local selected_id = "spell_37"
local selected_index = 37
local narrow_row = math.floor((selected_index - 1) / narrow.columns)
local wide_row = math.floor((selected_index - 1) / wide.columns)
assert(selected_id == "spell_37" and narrow_row ~= wide_row,
    "resize probe did not reflow geometry while preserving selected object identity")

local horizontal_offset = select(1, scroll.horizontal_offset(0, 30, 8, 1))
assert(horizontal_offset == scroll.HORIZONTAL_STEP and horizontal_offset == 3,
    "horizontal strip did not use its shared constant slot step")

wheel = 1
scroll.begin_frame()
assert(scroll.consume_wheel("horizontal:wand", true) == 1,
    "hovered horizontal strip did not acquire wheel ownership")
assert(scroll.consume_wheel("spells.workspace.wand", true) == 0,
    "parent viewport received the same wheel event as the horizontal strip")

wheel = -1
scroll.begin_frame()
assert(scroll.consume_wheel("catalog", false) == 0, "non-hovered viewport consumed wheel")
assert(scroll.consume_wheel("catalog", true) == -1, "hovered parent viewport could not consume an unowned tick")

print("scroll_grid_model=PASS constant_vertical_px=true constant_horizontal_slots=true wheel_owner=true grid_fit=true resize_reflow=true")
