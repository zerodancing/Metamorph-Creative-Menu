local held_wand_forms = {}

local component_ops = dofile("mods/metamorph_creative_menu/files/features/forms/component_ops.lua")
local wand_ghost = dofile("mods/metamorph_creative_menu/files/features/forms/held_wand_forms/wand_ghost.lua")

local valid = component_ops.valid
local ensure_controls = component_ops.ensure_controls

local PATHS = {
    ["data/entities/animals/wand_ghost.xml"] = true,
    ["data/entities/animals/wand_ghost_charmed.xml"] = true,
    ["data/entities/animals/wand_ghost_with_sampo.xml"] = true,
}

local active = nil
local active_entity = 0

function held_wand_forms.reset()
    if active ~= nil and type(active.reset) == "function" then active.reset() end
    active = nil
    active_entity = 0
end

function held_wand_forms.configure(entity, path)
    held_wand_forms.reset()
    if PATHS[tostring(path or "")] ~= true then return false end
    if wand_ghost.configure(entity) ~= true then return false end
    active = wand_ghost
    active_entity = entity
    return true
end

function held_wand_forms.update(entity)
    if active == nil or entity ~= active_entity then return false end
    local controls = ensure_controls(entity)
    if not valid(controls) then return false end
    -- ensure_controls() intentionally enables polymorph_hax for ordinary creature forms.
    -- Held-wand ghosts own primary fire themselves, so immediately take that surface back
    -- before the native ghost AI is pulsed. Otherwise the fallback orb_pink descriptor can
    -- leak through on the same click.
    pcall(ComponentSetValue2, controls, "polymorph_hax", false)
    return active.update(entity, controls) == true
end

function held_wand_forms.active()
    return active ~= nil
end

function held_wand_forms.owns_primary()
    return active ~= nil and type(active.owns_primary) == "function" and active.owns_primary() == true
end

return held_wand_forms
