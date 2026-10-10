local root = assert(arg[1], "root required")
local native_dofile = dofile
local calls = {}
function GetUpdatedEntityID() return 123 end
function EntityHasTag(entity, tag) return entity == 123 and tag == "polymorphed_player" end
function CrossCall(name, entity, reason, responsible, damage, projectile)
    calls[#calls + 1] = {name=name, entity=entity, reason=reason, responsible=responsible, damage=damage, projectile=projectile}
end

dofile = function(path)
    if path == "mods/metamorph_creative_menu/files/integrations/ew/form_death_channel.lua" then
        return native_dofile(root .. "/files/integrations/ew/form_death_channel.lua")
    end
    return native_dofile(path)
end

native_dofile(root .. "/files/features/forms/death_guard.lua")
damage_received(999, "fatal", 77, true, 88)
assert(#calls == 0, "fatal damage handed off before native death callback")
death("DAMAGE_CURSE", "dead", 77, false)
assert(#calls == 1, "death callback did not hand off form death")
assert(calls[1].name == "metamorph_creative_menu_form_died", "wrong CrossCall name")
assert(calls[1].entity == 123 and calls[1].responsible == 77, "death handoff lost entity/responsible")
print("form_death_guard=PASS native_death_boundary=true")
