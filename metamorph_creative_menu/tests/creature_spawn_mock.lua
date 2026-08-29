local root = assert(arg[1], "root required")
local native_dofile = dofile
local loaded_path, loaded_x, loaded_y = nil,nil,nil
local load_count = 0
local target_path = "data/entities/animals/test_creature.xml"
local stubs = {
    ["mods/metamorph_creative_menu/files/features/creatures/metadata.lua"]={basename=function(path) return path:match("([^/]+)%.xml$") or "" end},
    ["mods/metamorph_creative_menu/files/features/creatures/classification.lua"]={
        unsafe_reason=function() return nil end,
        path_is_technical=function() return false end,
        internal_helper_path=function() return false end,
        meaningful_duplicate_path=function() return false end,
        catalog_creature=function(path) return path==target_path end,
        known_unsafe_forms=function() return {} end,
    },
    ["mods/metamorph_creative_menu/files/features/creatures/diagnostics.lua"]={collect=function() return {} end, info=function() return {} end},
    ["mods/metamorph_creative_menu/files/features/creatures/catalog_builder.lua"]={
        static_candidates_by_id=function() return {} end,
        has_catalog_path=function(path) return path==target_path end,
        collect_transform_target_paths=function() return {target_path} end,
        collect=function() return {{path=target_path}} end,
        warmup_step=function() return true end,
        catalog_version=function() return 1 end,
        static_catalog=function() return {{path=target_path}} end,
        progress_index=function() return 1 end,
    },
}

dofile=function(path)
    if stubs[path]~=nil then return stubs[path] end
    local prefix="mods/metamorph_creative_menu/"
    if string.sub(path,1,#prefix)==prefix then return native_dofile(root.."/"..string.sub(path,#prefix+1)) end
    return native_dofile(path)
end
function ModDoesFileExist(path) return path==target_path end
function EntityGetIsAlive(entity) return entity==1 end
function EntityGetTransform(entity) assert(entity==1); return 100,200 end
function EntityLoad(path,x,y) load_count=load_count+1; loaded_path,loaded_x,loaded_y=path,x,y; return 77 end

METAMORPH_CREATIVE_MENU_CREATURE_SERVICE=nil
METAMORPH_CREATIVE_MENU_CREATURE_API=nil
local service=assert(native_dofile(root.."/files/features/creatures/service.lua"))
assert(service.is_transformable_creature_path(target_path)==true,"catalog creature stopped being transformable")
local entity=service.spawn_near_player(1,target_path,32,-4)
assert(entity==77,"LMB creature spawn did not return loaded entity")
assert(loaded_path==target_path and loaded_x==132 and loaded_y==196,"creature spawn position/path changed")

local exact,exact_reason=service.spawn_at(target_path,777,-55)
assert(exact==77 and exact_reason=="spawned","exact creature world spawn failed")
assert(loaded_path==target_path and loaded_x==777 and loaded_y==-55,"exact creature spawn changed cursor coordinates")

local before_invalid=load_count
local invalid,invalid_reason=service.spawn_at(target_path,nil,10)
assert(invalid==0 and invalid_reason=="invalid","missing creature coordinates were accepted")
assert(load_count==before_invalid,"invalid creature spawn reached EntityLoad")

local nan=0/0
invalid,invalid_reason=service.spawn_at(target_path,nan,10)
assert(invalid==0 and invalid_reason=="invalid" and load_count==before_invalid,"NaN creature coordinates were accepted")

print("creature_spawn=PASS transformable=true lmb_spawn=true exact_world=true invalid_coordinates_rejected=true")
