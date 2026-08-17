local root = assert(arg[1], "root required")
local native_dofile = dofile
local player = 1
local frame = 1
local body_visible = true
local body = { gravity=1.0, linear=0.2, angular=0.3 }
local body_exists = true
local globals = {}

function GlobalsGetValue(key, fallback) local v=globals[key]; if v==nil then return fallback end; return v end
function GlobalsSetValue(key, value) globals[key]=tostring(value) end
function EntityGetIsAlive(entity) return entity == player end
function EntityGetTransform(entity) assert(entity==player); return 0,0 end
function EntityGetInRadius() return {} end
function EntityGetComponentIncludingDisabled() return {} end
function EntityGetFilename() return "data/entities/player.xml" end
function ComponentGetTypeName() return nil end
function ComponentGetEntity() return nil end
function PhysicsBodyIDQueryBodies() return body_visible and {77} or {} end
function PhysicsBodyIDGetGravityScale(id) if id~=77 or not body_exists then error("gone") end; return body.gravity end
function PhysicsBodyIDSetGravityScale(id, value) if id~=77 or not body_exists then error("gone") end; body.gravity=value end
function PhysicsBodyIDGetDamping(id) if id~=77 or not body_exists then error("gone") end; return body.linear, body.angular end
function PhysicsBodyIDSetDamping(id, linear, angular) if id~=77 or not body_exists then error("gone") end; body.linear,body.angular=linear,angular end
function PhysicsBodyIDApplyForce() end

local stubs = {
    ["mods/metamorph_creative_menu/files/platform/noita/player_locator.lua"]={get=function() return player end},
    ["mods/metamorph_creative_menu/files/core/rule_math.lua"]={
        same=function(a,b) return math.abs((tonumber(a) or 0)-(tonumber(b) or 0))<1e-9 end,
        scaled=function(a,b) return tonumber(a)*tonumber(b) end,
    },
}
dofile=function(path)
    if stubs[path] ~= nil then return stubs[path] end
    local prefix="mods/metamorph_creative_menu/"
    if string.sub(path,1,#prefix)==prefix then return native_dofile(root.."/"..string.sub(path,#prefix+1)) end
    return native_dofile(path)
end

METAMORPH_CREATIVE_MENU_WORLD_RULE_RECOVERY=nil
METAMORPH_CREATIVE_MENU_WORLD_RULE_PHYSICS=nil
local physics=assert(native_dofile(root.."/files/features/world_rules/physics.lua"))

-- First entry: own exact native values and apply factors.
physics.scan(player, 2.0, 2.0, frame)
assert(math.abs(body.gravity-2.0)<1e-9, "gravity factor not applied")
assert(math.abs(body.linear-0.4)<1e-9 and math.abs(body.angular-0.6)<1e-9, "damping factor not applied")

-- Leaving the active neighbourhood must restore before releasing ownership.
frame=2; body_visible=false
physics.scan(player, 2.0, 2.0, frame)
assert(math.abs(body.gravity-1.0)<1e-9, "offscreen body kept creative gravity")
assert(math.abs(body.linear-0.2)<1e-9 and math.abs(body.angular-0.3)<1e-9, "offscreen body kept creative damping")
assert(physics.has_overrides()==false, "offscreen restored body remained owned")

-- Re-entering must capture the real native value again, not compound 2x -> 4x.
frame=3; body_visible=true
physics.scan(player, 2.0, 2.0, frame)
assert(math.abs(body.gravity-2.0)<1e-9, "re-entry compounded gravity instead of reapplying from native")
assert(math.abs(body.linear-0.4)<1e-9, "re-entry compounded damping instead of reapplying from native")

-- Rule reset must restore a tracked body by ID even when the current spatial query no longer sees it.
body_visible=false
local restored_g, reason_g=physics.restore_rule("physics_gravity")
assert(restored_g==true and reason_g=="ok", "offscreen gravity restore failed")
assert(math.abs(body.gravity-1.0)<1e-9, "restore_rule did not restore offscreen body gravity")
-- Damping is still owned independently until its rule is restored.
assert(physics.has_overrides()==true, "gravity restore incorrectly discarded damping ownership")
assert(physics.has_gravity_overrides()==false,"gravity-specific ownership remained after gravity restore")
assert(physics.has_damping_overrides()==true,"damping-specific ownership disappeared while damping was still active")
local restored_d, reason_d=physics.restore_rule("physics_damping")
assert(restored_d==true and reason_d=="ok", "offscreen damping restore failed")
assert(math.abs(body.linear-0.2)<1e-9 and math.abs(body.angular-0.3)<1e-9, "restore_rule did not restore offscreen damping")
assert(physics.has_overrides()==false, "restored body ownership leaked")

io.write("world_rules_physics_ownership=PASS offscreen_restore=true reentry_no_compound=true separate_rule_state=true\n")
