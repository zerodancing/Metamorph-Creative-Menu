local projectile_forms = {}

local boss_pit_wand = dofile("mods/metamorph_creative_menu/files/features/forms/projectile_forms/boss_pit_wand.lua")

local WAND_PATH = "data/entities/animals/boss_pit/wand.xml"
local active = nil
local active_entity = 0

function projectile_forms.reset()
    if active ~= nil and type(active.reset) == "function" then active.reset() end
    active = nil
    active_entity = 0
end

function projectile_forms.configure(entity, path, profile)
    projectile_forms.reset()
    if tostring(path or "") == WAND_PATH then
        active = boss_pit_wand
    else
        return false
    end
    if active.configure(entity, profile) ~= true then
        active = nil
        return false
    end
    active_entity = entity
    return true
end

function projectile_forms.update(entity)
    if active == nil or entity ~= active_entity then return false end
    return active.update(entity) == true
end

function projectile_forms.active()
    return active ~= nil
end

return projectile_forms
