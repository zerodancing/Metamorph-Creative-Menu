-- Runs inside the temporary polymorph entity Lua context.
-- IMPORTANT: do not hand off on damage_received(is_fatal). At that point Noita has
-- applied fatal damage but has not completed the entity's native death transition yet.
-- Player authority must not switch from damage_received; death() owns that transition.
-- Otherwise the old form can retain wait_for_kill_flag_on_death and remain as an
-- immortal, still-simulating detached entity.
--
-- Keep this callback deliberately dependency-free. Entity LuaComponents run in their
-- own VM, so CrossCall itself is the stable boundary back to the main mod runtime.
local function handoff(reason, responsible, damage, projectile)
    local entity = GetUpdatedEntityID()
    if entity == nil or entity == 0 or not EntityHasTag(entity, "polymorphed_player") then return end
    if type(CrossCall) == "function" then
        pcall(CrossCall, "metamorph_creative_menu_form_died", entity, tostring(reason or "death"),
            tonumber(responsible) or 0, tonumber(damage), tonumber(projectile) or 0)
    end
end

-- Intentionally observe fatal damage only. The actual handoff happens from death().
function damage_received(damage, message, responsible, is_fatal, projectile)
    return
end

function death(damage_type, damage_message, responsible, drop_items)
    handoff("death", responsible, nil, 0)
end
