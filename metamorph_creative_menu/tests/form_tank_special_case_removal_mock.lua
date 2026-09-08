local root=assert(arg[1],"root required")
local function read(path)local f=assert(io.open(root.."/"..path,"rb"));local s=f:read("*a");f:close();return s end
local runtime=read("files/features/forms/runtime.lua")
local family=read("files/features/forms/family.lua")
assert(not string.find(runtime,"tank_native",1,true),"legacy tank-native special runtime still present")
assert(not string.find(runtime,"native_tank_mode",1,true),"legacy tank animation mode flag still present")
assert(not string.find(family,"is_native_tank_path",1,true),"tank path special-case classifier still present")
assert(string.find(runtime,"configure_character_player",1,true) and string.find(runtime,"setup_manual_barrels(entity)",1,true),"tanks no longer flow through the ordinary character attack presentation path")
print("form_tank_special_case_removal=PASS special_runtime_removed=true generic_family=true")
