if type(METAMORPH_CREATIVE_MENU_PANEL_LAYOUT) == "table" then return METAMORPH_CREATIVE_MENU_PANEL_LAYOUT end

local panel_layout = {}

panel_layout.MARGIN = 4
panel_layout.MIN_WIDTH = 190
panel_layout.MIN_HEIGHT = 112
panel_layout.DEFAULT_MIN_WIDTH = 210
panel_layout.DEFAULT_MIN_HEIGHT = 170
panel_layout.DEFAULT_Y = 28

local function finite_number(value)
    value = tonumber(value)
    if value == nil or value ~= value or value == math.huge or value == -math.huge then return nil end
    return value
end

local function clamp(value, minimum, maximum)
    if maximum < minimum then maximum = minimum end
    return math.max(minimum, math.min(maximum, value))
end

local function normalized_outsets(outsets)
    outsets = type(outsets) == "table" and outsets or {}
    return {
        left=math.max(0, finite_number(outsets.left) or 0),
        right=math.max(0, finite_number(outsets.right) or 0),
        top=math.max(0, finite_number(outsets.top) or 0),
        bottom=math.max(0, finite_number(outsets.bottom) or 0),
    }
end

function panel_layout.default_width(screen_width)
    screen_width = math.max(1, finite_number(screen_width) or 320)
    local available = math.max(1, screen_width - panel_layout.MARGIN * 2)
    local responsive = math.min(320, math.floor(screen_width * 0.64))
    return math.min(available, math.max(math.min(panel_layout.DEFAULT_MIN_WIDTH, available), responsive))
end

function panel_layout.default_height(screen_height)
    screen_height = math.max(1, finite_number(screen_height) or 240)
    local available = math.max(1, screen_height - panel_layout.MARGIN * 2)
    local responsive = math.min(300, math.floor(screen_height * 0.78))
    return math.min(available, math.max(math.min(panel_layout.DEFAULT_MIN_HEIGHT, available), responsive))
end

function panel_layout.default_y(screen_height)
    screen_height = math.max(1, finite_number(screen_height) or 240)
    return math.max(panel_layout.DEFAULT_Y, math.floor(screen_height * 0.12))
end

function panel_layout.clamp(layout, screen_width, screen_height, measured_height, outsets)
    layout = type(layout) == "table" and layout or {}
    screen_width = math.max(1, finite_number(screen_width) or 320)
    screen_height = math.max(1, finite_number(screen_height) or 240)

    local margin = math.min(panel_layout.MARGIN, math.floor(math.min(screen_width, screen_height) * 0.25))
    outsets = normalized_outsets(outsets)
    local available_width = math.max(1, screen_width - margin * 2 - outsets.left - outsets.right)
    local minimum_width = math.min(panel_layout.MIN_WIDTH, available_width)
    layout.width = clamp(finite_number(layout.width) or panel_layout.default_width(screen_width),
        minimum_width, available_width)

    local minimum_x = margin + outsets.left
    local maximum_x = math.max(minimum_x, screen_width - layout.width - margin - outsets.right)
    if finite_number(layout.x) == nil then layout.x = maximum_x end
    layout.x = clamp(layout.x, minimum_x, maximum_x)

    local available_height = math.max(1, screen_height - margin * 2 - outsets.top - outsets.bottom)
    local minimum_height = math.min(panel_layout.MIN_HEIGHT, available_height)
    layout.height = clamp(finite_number(layout.height) or finite_number(measured_height)
        or panel_layout.default_height(screen_height), minimum_height, available_height)

    local minimum_y = margin + outsets.top
    local maximum_y = math.max(minimum_y, screen_height - layout.height - margin - outsets.bottom)
    layout.y = clamp(finite_number(layout.y) or panel_layout.default_y(screen_height), minimum_y, maximum_y)
    return layout
end

function panel_layout.create(screen_width, screen_height, saved, outsets)
    saved = type(saved) == "table" and saved or {}
    return panel_layout.clamp({
        x=finite_number(saved.x),
        y=finite_number(saved.y),
        width=finite_number(saved.width),
        height=finite_number(saved.height),
    }, screen_width, screen_height, saved.measured_height, outsets)
end

function panel_layout.move(layout, x, y, screen_width, screen_height, measured_height, outsets)
    layout.x = finite_number(x) or layout.x
    layout.y = finite_number(y) or layout.y
    return panel_layout.clamp(layout, screen_width, screen_height, measured_height, outsets)
end

function panel_layout.resize_edges(layout, original, edges, dx, dy, screen_width, screen_height, outsets)
    original = type(original) == "table" and original or layout
    edges = type(edges) == "table" and edges or {}
    dx, dy = finite_number(dx) or 0, finite_number(dy) or 0
    local right = (finite_number(original.x) or layout.x) + (finite_number(original.width) or layout.width)
    local bottom = (finite_number(original.y) or layout.y) + (finite_number(original.height) or layout.height)

    if edges.left then
        layout.x = (finite_number(original.x) or layout.x) + dx
        layout.width = right - layout.x
    elseif edges.right then
        layout.width = (finite_number(original.width) or layout.width) + dx
    end
    if edges.top then
        layout.y = (finite_number(original.y) or layout.y) + dy
        layout.height = bottom - layout.y
    elseif edges.bottom then
        layout.height = (finite_number(original.height) or layout.height) + dy
    end

    local safe_outsets = normalized_outsets(outsets)
    local minimum_width = math.min(panel_layout.MIN_WIDTH,
        math.max(1, (finite_number(screen_width) or 320) - panel_layout.MARGIN * 2
            - safe_outsets.left - safe_outsets.right))
    local minimum_height = math.min(panel_layout.MIN_HEIGHT,
        math.max(1, (finite_number(screen_height) or 240) - panel_layout.MARGIN * 2
            - safe_outsets.top - safe_outsets.bottom))
    if layout.width < minimum_width then
        layout.width = minimum_width
        if edges.left then layout.x = right - layout.width end
    end
    if layout.height < minimum_height then
        layout.height = minimum_height
        if edges.top then layout.y = bottom - layout.height end
    end
    return panel_layout.clamp(layout, screen_width, screen_height, nil, outsets)
end

METAMORPH_CREATIVE_MENU_PANEL_LAYOUT = panel_layout
return panel_layout
