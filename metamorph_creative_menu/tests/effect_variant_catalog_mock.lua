local root=assert(arg[1],"root required")
local native_dofile=dofile
dofile=function(path)
 local prefix="mods/metamorph_creative_menu/"
 if string.sub(path,1,#prefix)==prefix then return native_dofile(root.."/"..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end
local paths={
 "data/entities/misc/effect_trip_00.xml",
 "data/entities/misc/effect_trip_01.xml",
 "data/entities/misc/effect_trip_02.xml",
 "data/entities/misc/effect_trip_03.xml",
}
local names={"Light trip","Trip","Strong trip","Extreme trip"}
function dofile_once(path)
 assert(path=="data/scripts/status_effects/status_list.lua","unexpected dofile_once")
 status_effects={}
 for i=1,4 do
  status_effects[#status_effects+1]={id="TRIP",ui_name="$trip_"..i,ui_description="$tripdesc_"..i,ui_icon="trip.png",effect_entity=paths[i],min_threshold_normalized=(i-1)*0.5}
 end
 -- Same implementation path at another ingestion threshold must not create a fake fifth intensity.
 status_effects[#status_effects+1]={id="TRIP",ui_name="$trip_duplicate",ui_description="$tripdesc_duplicate",ui_icon="trip.png",effect_entity=paths[2],min_threshold_normalized=9}
end
function GameTextGetTranslatedOrNot(key)
 for i=1,4 do if key=="$trip_"..i then return names[i] end end
 return key
end
function ModDoesFileExist(path)
 for _,candidate in ipairs(paths) do if path==candidate then return true end end
 return path=="trip.png"
end
function ModTextFileGetContent(path)
 for _,candidate in ipairs(paths) do
  if path==candidate then
   return [[<Entity><UIIconComponent name="$unused" description="$unused" icon_sprite_file="trip.png"/><GameEffectComponent effect="CUSTOM" custom_effect_id="TRIP_00" frames="600"/></Entity>]]
  end
 end
 return ""
end

METAMORPH_CREATIVE_MENU_EFFECT_CATALOG=nil
local catalog=assert(native_dofile(root.."/files/features/effects/catalog.lua"))
local entries=catalog.entries()
local trip={}
for _,entry in ipairs(entries) do
 if entry.id=="TRIP" then trip[#trip+1]=entry end
end
assert(#trip==1,"TRIP should be one clean semantic tile, got "..tostring(#trip))
local family=trip[1]
assert(type(family.variants)=="table" and #family.variants==4,"TRIP strength variants missing: "..tostring(type(family.variants)=="table" and #family.variants or 0))
local seen={}
for index,variant in ipairs(family.variants) do
 assert(variant.path~="" and not seen[variant.path],"variant path identity lost")
 seen[variant.path]=true
 assert(variant.custom_effect_id=="TRIP_00","shared vanilla custom id metadata changed")
 assert(variant.variant_index==nil,"catalog should not pre-bind UI variant index")
end
for _,path in ipairs(paths) do assert(seen[path],"missing trip intensity "..path) end
METAMORPH_CREATIVE_MENU_EFFECT_SERVICE=nil
local service=assert(native_dofile(root.."/files/features/effects/service.lua"))
assert(service.max_variant_count()==4,"global strength selector did not expose all authored trip levels")
for i,path in ipairs(paths) do
 local resolved=service.resolve_variant(family,i)
 assert(resolved.path==path and resolved.variant_index==i and resolved.variant_count==4,"strength resolver selected wrong trip level "..i)
end
print("effect_variant_catalog=PASS trip_tile=1 strengths=4 selector=4 same_path_alias_merged=true")
