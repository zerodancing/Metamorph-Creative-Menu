if type(METAMORPH_CREATIVE_MENU_PLAYERS_TAB) == "table" then return METAMORPH_CREATIVE_MENU_PLAYERS_TAB end

local tab = {}

local ui = dofile("mods/metamorph_creative_menu/files/ui/runtime.lua")
local player_tools = dofile("mods/metamorph_creative_menu/files/features/player_tools/service.lua")

function tab.draw(player, width, height)
    GuiLayoutBeginVertical(ui.gui(), 0, 2, true)
    ui.wrapped_text(0, 0, ui.tr("$mcm_players_hint",
        "Safe teleports to players and world locations"), width - 12)
    if player_tools.has_pending_teleport() then
        ui.colored_text(0, 1, ui.tr("$mcm_teleport_loading", "LOADING DESTINATION..."),
            {1.0,0.78,0.2,1.0})
    end

    local scroll_height = ui.scroll_height(height, 52)
    local scroll = ui.begin_scroll_viewport("players.main", 17100, 0, 0, width - 4, scroll_height)
    local content_width = math.max(24, scroll.content_width)

    ui.colored_text(0, 2, ui.tr("$mcm_teleport_players", "NETWORK PLAYERS"), {1.0,0.78,0.2,1.0})
    local players = {}
    for _, entity in ipairs(player_tools.visible_players()) do
        if tonumber(entity) ~= tonumber(player) then players[#players + 1] = entity end
    end
    table.sort(players, function(a, b) return (tonumber(a) or 0) < (tonumber(b) or 0) end)
    if #players == 0 then
        ui.wrapped_text(0, 1, ui.tr("$mcm_players_empty", "No remote players found"), content_width)
    end
    for index, entity in ipairs(players) do
        local x, y = player_tools.position(entity)
        local label = ui.tr("$mcm_players_player", "Player") .. " " .. tostring(index)
            .. "  (" .. tostring(math.floor(x)) .. ", " .. tostring(math.floor(y)) .. ")"
        ui.wrapped_text(0, 2, label, content_width)
        local remote_action = ui.button_grid({
            {label=ui.tr("$mcm_teleport_to_player", "GO TO"),
                tooltip_description=ui.tr("$mcm_teleport_to_player_hint", "Teleport safely beside this player")},
            {label=ui.tr("$mcm_teleport_bring_player", "BRING HERE"),
                tooltip_description=ui.tr("$mcm_teleport_bring_hint", "Ask this peer to teleport safely to you")},
        }, math.max(32, content_width - 4))
        if remote_action == 1 then player_tools.teleport_to(entity, player)
        elseif remote_action == 2 then player_tools.bring_to_me(entity, player) end
    end

    ui.colored_text(0, 6, ui.tr("$mcm_teleport_locations", "WORLD LOCATIONS"), {1.0,0.78,0.2,1.0})
    ui.wrapped_text(0, 0, ui.tr("$mcm_teleport_locations_hint",
        "The destination is streamed first and adjusted to nearby free space."), content_width)
    local location_buttons = {}
    for _, location in ipairs(player_tools.locations()) do
        location_buttons[#location_buttons + 1] = {
            label=ui.tr(location.key, location.fallback),
            location=location,
            tooltip_title=ui.tr(location.key, location.fallback),
            tooltip_description="(" .. tostring(math.floor(location.x)) .. ", "
                .. tostring(math.floor(location.y)) .. ")",
        }
    end
    local clicked = ui.button_grid(location_buttons, content_width)
    if clicked ~= nil and location_buttons[clicked] ~= nil then
        player_tools.teleport_location(location_buttons[clicked].location.id, player)
    end

    ui.end_scroll_viewport(scroll)
    GuiLayoutEnd(ui.gui())
end

METAMORPH_CREATIVE_MENU_PLAYERS_TAB = tab
return tab
