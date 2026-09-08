local root=assert(arg[1],'root required')
local function read(path)
 local f=assert(io.open(root..'/'..path,'rb')); local s=f:read('*a'); f:close(); return s
end
local source=read('files/features/companion/player_avatar.lua')
assert(string.find(source,'local CLONE_PATH = "data/entities/misc/player_drone_clone.xml"',1,true),
 'PLAYER network base is not a vanilla Noita entity available to stock peers')
assert(not string.find(source,'local CLONE_PATH = "mods/metamorph_creative_menu/',1,true),
 'PLAYER still exposes an MCM-only filename to native DES')
assert(string.find(source,'ensure_companion_structure(clone)',1,true),
 'vanilla network base is not upgraded with the local companion controls/inventory')
assert(string.find(source,'EntityAddTag(clone, tag)',1,true),
 'vanilla PLAYER base is not made DES-eligible as an enemy')
assert(not string.find(source,'companion_request.lua',1,true),'client companion still depends on an MCM RPC handler at the host')
assert(string.find(source,'ew_world_entities.is_tracked(clone)',1,true),'MCM-only controller is not delayed until after DES identity exists')
assert(string.find(source,'"local_des"',1,true),'network spawn no longer reports local DES ownership')
print('companion_network_des=PASS vanilla_filename=true stock_peer_no_mcm=true local_controller_after_des=true')
