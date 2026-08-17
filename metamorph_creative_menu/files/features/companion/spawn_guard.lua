-- Per-entity fallback for companions created in a Lua context that does not share the
-- main mod's player_avatar registry (notably EW's extra-module VM). The repair semantics
-- are centralized in companion_health.lua; this component only supplies an execution path.
local entity = GetUpdatedEntityID()
if entity == nil or entity == 0 or not EntityGetIsAlive(entity) then return end

if type(METAMORPH_CREATIVE_MENU_COMPANION_HEALTH) ~= "table" then
    pcall(dofile, "mods/metamorph_creative_menu/files/features/companion/health.lua")
end
local guard = METAMORPH_CREATIVE_MENU_COMPANION_HEALTH
if type(guard) ~= "table" or type(guard.repair) ~= "function" then return end

local _, finished = guard.repair(entity)
if finished and type(GetUpdatedComponentID) == "function" then
    local component = GetUpdatedComponentID()
    if component ~= nil and component ~= 0 then EntitySetComponentIsEnabled(entity, component, false) end
end
