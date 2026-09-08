local root=assert(arg[1],'root required')
local native_dofile=dofile

dofile=function(path)
 local prefix='mods/metamorph_creative_menu/'
 if string.sub(path,1,#prefix)==prefix then return native_dofile(root..'/'..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end

local paths={
 oiled='data/entities/misc/effect_oiled.xml',
 drunk='data/entities/misc/effect_drunk.xml',
 drunk2='data/entities/misc/effect_drunk_01.xml',
 berserk='data/entities/misc/effect_berserk.xml',
 trip0='data/entities/misc/effect_trip_00.xml',
 trip1='data/entities/misc/effect_trip_01.xml',
 trip2='data/entities/misc/effect_trip_02.xml',
 trip3='data/entities/misc/effect_trip_03.xml',
 breath='data/entities/misc/effect_breath_underwater.xml',
 technical='data/entities/misc/effect_no_heal.xml',
 spirit_berserk='data/entities/misc/effect_spirit_berserk.xml',
 twitchy='data/entities/misc/effect_twitchy.xml',
}
local icons={
 oiled='data/ui_gfx/status_indicators/oiled.png',
 alcoholic='data/ui_gfx/status_indicators/alcoholic.png',
 drunk='data/ui_gfx/status_indicators/drunk.png',
 berserk='data/ui_gfx/status_indicators/berserk.png',
 trip='data/ui_gfx/status_indicators/trip.png',
 breath='data/ui_gfx/perk_icons/breath_underwater.png',
 technical='data/ui_gfx/status_indicators/weakness.png',
 twitchy='data/ui_gfx/status_indicators/twitchy.png',
}

function dofile_once(path)
 if path=='data/scripts/perks/perk_list.lua' then perk_list={{game_effect='BREATH_UNDERWATER',ui_name='$breath',ui_description='$breath_desc',ui_icon=icons.breath}}; return end
 assert(path=='data/scripts/status_effects/status_list.lua','unexpected status source')
 status_effects={
  {id='OILED',ui_name='$oiled',ui_description='$oiled_desc',ui_icon=icons.oiled,effect_entity=paths.oiled},
  {id='HYDRATED',ui_name='$oiled',ui_description='$oiled_desc',ui_icon=icons.oiled,effect_entity=paths.oiled},
  {id='ALCOHOLIC',ui_name='$alcoholic',ui_description='$alcoholic_desc',ui_icon=icons.alcoholic,effect_entity=paths.drunk},
  {id='INGESTION_DRUNK',ui_name='$drunk0',ui_description='$drunk0_desc',ui_icon=icons.drunk,effect_entity=paths.drunk,min_threshold_normalized=0},
  {id='INGESTION_DRUNK',ui_name='$drunk1',ui_description='$drunk1_desc',ui_icon=icons.drunk,effect_entity=paths.drunk,min_threshold_normalized=.25},
  {id='INGESTION_DRUNK',ui_name='$drunk2',ui_description='$drunk2_desc',ui_icon=icons.drunk,effect_entity=paths.drunk2,min_threshold_normalized=.75},
  {id='BERSERK',ui_name='$berserk',ui_description='$berserk_desc',ui_icon=icons.berserk,effect_entity=paths.berserk},
  {id='TRIP',ui_name='$trip0',ui_description='$trip0_desc',ui_icon=icons.trip,effect_entity=paths.trip0},
  {id='TRIP',ui_name='$trip1',ui_description='$trip1_desc',ui_icon=icons.trip,effect_entity=paths.trip1,min_threshold_normalized=.5},
  {id='TRIP',ui_name='$trip2',ui_description='$trip2_desc',ui_icon=icons.trip,effect_entity=paths.trip2,min_threshold_normalized=1.5},
  {id='TRIP',ui_name='$trip3',ui_description='$trip3_desc',ui_icon=icons.trip,effect_entity=paths.trip3,min_threshold_normalized=3},
 }
end

local translated={
 ['$oiled']='Oiled', ['$oiled_desc']='Oil',
 ['$alcoholic']='Alcoholic', ['$alcoholic_desc']='Alcohol',
 ['$drunk0']='Tipsy', ['$drunk0_desc']='Mild alcohol',
 ['$drunk1']='Drunk', ['$drunk1_desc']='Alcohol',
 ['$drunk2']='Very drunk', ['$drunk2_desc']='Strong alcohol',
 ['$berserk']='Berserk', ['$berserk_desc']='Rage',
 ['$trip0']='Light trip', ['$trip0_desc']='Trip 1',
 ['$trip1']='Trip', ['$trip1_desc']='Trip 2',
 ['$trip2']='Strong trip', ['$trip2_desc']='Trip 3',
 ['$trip3']='Extreme trip', ['$trip3_desc']='Trip 4',
 ['$breath']='Breathe underwater', ['$breath_desc']='Breathe while submerged',
 ['$twitchy']='Twitchy', ['$twitchy_desc']='Random firing',
}
function GameTextGetTranslatedOrNot(key) return translated[key] or key end

local existing={}
for _,v in pairs(paths) do existing[v]=true end
for _,v in pairs(icons) do existing[v]=true end
function ModDoesFileExist(path) return existing[path]==true end
function ModTextFileGetContent(path)
 if not existing[path] or string.sub(path,-4)~='.xml' then return '' end
 if path==paths.breath then
  return '<Entity><GameEffectComponent effect="BREATH_UNDERWATER" frames="600"/></Entity>'
 end
 if path==paths.technical then
  -- Deliberately has a visible icon and a raw English developer label. It must still be
  -- rejected because no localized/status/perk presentation exists for this technical XML.
  return '<Entity><UIIconComponent name="Weakness" description="" icon_sprite_file="'..icons.technical..'"/><GameEffectComponent effect="TECHNICAL_ONLY" frames="600"/></Entity>'
 end
 if path==paths.spirit_berserk then
  return '<Entity><UIIconComponent name="$berserk" description="$berserk_desc" icon_sprite_file="'..icons.berserk..'"/><GameEffectComponent effect="BERSERK" frames="600"/></Entity>'
 end
 if path==paths.twitchy then
  return '<Entity><UIIconComponent name="$twitchy" description="$twitchy_desc" icon_sprite_file="'..icons.twitchy..'"/><LifetimeComponent lifetime="1200"/></Entity>'
 end
 if path==paths.berserk then
  return '<Entity><UIIconComponent name="$berserk" description="$berserk_desc" icon_sprite_file="'..icons.berserk..'"/><GameEffectComponent effect="BERSERK" frames="600"/></Entity>'
 end
 local custom='TEST_'..string.gsub(path,'[^%w]','_')
 return '<Entity><UIIconComponent name="" description="" icon_sprite_file=""/><GameEffectComponent effect="CUSTOM" custom_effect_id="'..custom..'" frames="600"/></Entity>'
end

METAMORPH_CREATIVE_MENU_EFFECT_CATALOG=nil
METAMORPH_CREATIVE_MENU_EFFECT_SERVICE=nil
METAMORPH_CREATIVE_MENU_EFFECT_EDITOR=nil
local catalog=assert(native_dofile(root..'/files/features/effects/catalog.lua'))
local entries=catalog.entries()
local by_id={}
for _,entry in ipairs(entries) do
 by_id[entry.id]=by_id[entry.id] or {}
 by_id[entry.id][#by_id[entry.id]+1]=entry
end
assert(by_id.ALCOHOLIC and #by_id.ALCOHOLIC==1,'alcoholic status disappeared from effect editor catalog')
assert(by_id.INGESTION_DRUNK and #by_id.INGESTION_DRUNK==1,'ingestion alcohol family disappeared')
assert(type(by_id.INGESTION_DRUNK[1].variants)=='table' and #by_id.INGESTION_DRUNK[1].variants==2,
 'ingestion alcohol should expose only two distinct authored implementations')
assert(by_id.TRIP and #by_id.TRIP==1 and type(by_id.TRIP[1].variants)=='table' and #by_id.TRIP[1].variants==4,
 'trip editor family must expose four authored stages')
assert(by_id.BERSERK and #by_id.BERSERK==1 and by_id.BERSERK[1].variants==nil,
 'single-state effect unexpectedly got a fake stage selector or duplicate implementation')
local oil_aliases=(by_id.OILED and #by_id.OILED or 0)+(by_id.HYDRATED and #by_id.HYDRATED or 0)
assert(oil_aliases==1,'exact OILED/HYDRATED presentation alias was not deduplicated')
assert(by_id.BREATH_UNDERWATER==nil,
 'perk-backed passive GameEffect leaked into the EFFECTS catalog')
assert(by_id.TECHNICAL_ONLY==nil,'raw English technical GameEffect leaked into user-facing catalog')
local twitchy_entry=nil
for _,entry in ipairs(entries) do if entry.path==paths.twitchy then twitchy_entry=entry; break end end
assert(twitchy_entry~=nil and twitchy_entry.authored_lifetime==1200,
 'localized LifetimeComponent status effect disappeared from editor catalog')

local ui_source=assert(io.open(root..'/files/ui/tabs/effects.lua','rb')):read('*a')
assert(not string.find(ui_source,'ui.stepper',1,true),'effects editor still uses tiny +/- stepper controls')
assert(not string.find(ui_source,'$mcm_apply',1,true),'effects editor still requires a separate APPLY button')
assert(string.find(ui_source,'apply_tile(player,entry,snapshot)',1,true),
 'LMB tile no longer applies the selected effect immediately')
assert(string.find(ui_source,'label=tostring(variant_index)',1,true),
 'multi-stage effect editor is not using direct stage buttons')
assert(string.find(ui_source,'effect_service.switch_variant',1,true),
 'active stage selection is not an immediate editor operation')
assert(string.find(ui_source,'local duration_index_by_key = {}',1,true),
 'effect duration presets are still shared globally instead of being per effect')
assert(string.find(ui_source,'draw_duration_bar(player, entry, panel_width, snapshot)',1,true),
 'selected effect no longer exposes its contextual duration editor')
assert(not string.find(ui_source,'local duration_index = 2',1,true),
 'legacy global effect duration state is still present')
assert(not string.find(ui_source,'fallback="AUTO"',1,true),'effects editor still exposes ambiguous AUTO duration clutter')
print('effect_editor_catalog=PASS alcohol=true ingestion_variants=2 trip_variants=4 single_state_clean=true aliases_deduped=true technical_hidden=true perk_hidden=true lifetime_effects=true status_impl_deduped=true one_click_apply=true per_effect_duration=true immediate_editor=true')
