local root=assert(arg[1],"root required")
local native_dofile=dofile
local gun,controls=20,21
local values={
 [gun]={image_file="data/enemies_gfx/tank_gun.xml",update_transform_rotation=false,has_special_scale=true,special_scale_x=1,special_scale_y=1},
 [controls]={mButtonDownLeft=false,mButtonDownRight=false},
}
local enabled={[gun]=true,[controls]=true}
local sx=-1
local component_ops={
 valid=function(v)return v~=nil and v~=0 end,
 get=function(c,f,d)local v=values[c] and values[c][f];if v==nil then return d end return v end,
 boolean=function(v)if type(v)=="string" then return v=="1" or v=="true" end return v==true or v==1 end,
}
dofile=function(path)
 if path=="mods/metamorph_creative_menu/files/features/forms/component_ops.lua" then return component_ops end
 local prefix="mods/metamorph_creative_menu/"
 if string.sub(path,1,#prefix)==prefix then return native_dofile(root.."/"..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end
function EntityGetComponentIncludingDisabled(_,kind) if kind=="SpriteComponent" then return {gun} end return {} end
function EntityGetFirstComponentIncludingDisabled(_,kind) if kind=="ControlsComponent" then return controls end return nil end
function EntityGetTransform() return 0,0,0,sx,1 end
function EntityGetIsAlive() return true end
function ComponentSetValue2(c,f,v) values[c]=values[c] or {}; values[c][f]=v end

local adapter=assert(native_dofile(root.."/files/features/forms/adapters/static_weapon_presentation.lua"))
assert(adapter.configure(1)==true,"tank static gun layer was not claimed")
adapter.update(1)
assert(values[gun].has_special_scale==false,"static tank gun did not inherit the root/body mirror")
-- Switching the root/body side must require no fake turret rotation or per-sprite negative scale.
sx=1
adapter.update(1)
assert(values[gun].has_special_scale==false and values[gun].special_scale_x==1,"tank gun presentation invented a separate flip channel")
adapter.reset()
assert(values[gun].has_special_scale==true and values[gun].special_scale_x==1 and values[gun].special_scale_y==1,"tank gun authored scale state was not restored")
print("form_static_weapon_presentation=PASS inherits_body_flip=true reversible=true")
