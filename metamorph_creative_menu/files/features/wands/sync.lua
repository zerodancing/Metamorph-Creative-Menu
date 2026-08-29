if type(METAMORPH_CREATIVE_MENU_WAND_SYNC) == "table" then return METAMORPH_CREATIVE_MENU_WAND_SYNC end

local wand_sync = {}
local ew_runtime = dofile("mods/metamorph_creative_menu/files/integrations/ew/runtime.lua")

function wand_sync.inventory(player)
    if player ~= nil and player ~= 0 and EntityGetIsAlive(player) then
        local inventory = EntityGetFirstComponentIncludingDisabled(player, "Inventory2Component")
        if inventory ~= nil and inventory ~= 0 then pcall(ComponentSetValue2, inventory, "mForceRefresh", true) end
    end
    ew_runtime.force_inventory_sync()
end

METAMORPH_CREATIVE_MENU_WAND_SYNC = wand_sync
return wand_sync
