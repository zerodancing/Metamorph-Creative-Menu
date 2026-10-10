local root=assert(arg[1], 'root required')
local calls={}
local lists={
    CellFactory_GetAllLiquids={'water','rock_static','sand','hax_liquid','shared'},
    CellFactory_GetAllSands={'sand','rock_static','shared'},
    CellFactory_GetAllGases={'smoke'},
    CellFactory_GetAllFires={'fire'},
    CellFactory_GetAllSolids={'physics_rock','rock_static'},
}
for name, values in pairs(lists) do
    _G[name]=function(include_statics, include_particle_fx)
        calls[name]=(calls[name] or 0)+1
        calls[name..'_args']={include_statics,include_particle_fx}
        local out={}; for i,v in ipairs(values) do out[i]=v end; return out
    end
end
local ids={water=1,rock_static=2,sand=3,hax_liquid=4,shared=5,smoke=6,fire=7,physics_rock=8}
local tags={
    [1]={'[liquid]'},
    [2]={'[static]'},
    [3]={'[sand_ground]'},
    [4]={'[hax]'},
    [5]={}, -- third-party material: falls back to the API family
    [6]={'[gas]'},
    [7]={'[fire]'},
    [8]={'[box2d]'},
}
function CellFactory_GetType(name) return ids[name] or -1 end
function CellFactory_GetUIName(id) return '$mat_'..tostring(id) end
function CellFactory_GetTags(id) local out={}; for i,v in ipairs(tags[id] or {}) do out[i]=v end; return out end
local function translate(key) return ({['$mat_1']='Water',['$mat_2']='Rock'})[key] or key end
METAMORPH_CREATIVE_MENU_MATERIAL_CATALOG=nil
local catalog=assert(dofile(root..'/files/features/materials/catalog.lua'))

-- Opening LIQUIDS is still lazy and bounded, but a static/sand/hax definition reported
-- by the low-level liquids API must not leak into the user-facing liquid family.
local done,used=catalog.step('LIQUIDS',translate,1)
assert(not done and used==1,'incremental material budget ignored')
assert(calls.CellFactory_GetAllLiquids==3,'liquid source not enumerated')
assert(calls.CellFactory_GetAllSands==nil and calls.CellFactory_GetAllGases==nil
    and calls.CellFactory_GetAllFires==nil and calls.CellFactory_GetAllSolids==nil,
    'opening one material category eagerly scanned unrelated categories')
while not catalog.is_ready('LIQUIDS') do catalog.step('LIQUIDS',translate,2) end
local liquids=catalog.entries_for('LIQUIDS')
assert(#liquids==2,'semantic liquid filtering failed: '..tostring(#liquids))
assert(catalog.get('water').display_name=='Water','translated material name not used')
assert(catalog.get('rock_static')==nil,'filtered static should not be materialized by LIQUIDS alone')

-- Static/special categories intentionally scan all enumerators but remain incremental.
while not catalog.is_ready('STATIC') do catalog.step('STATIC',translate,2) end
assert(#catalog.entries_for('STATIC')==1 and catalog.entries_for('STATIC')[1].id=='rock_static',
    'static terrain classification failed')
while not catalog.is_ready('SPECIAL') do catalog.step('SPECIAL',translate,2) end
assert(#catalog.entries_for('SPECIAL')==1 and catalog.entries_for('SPECIAL')[1].id=='hax_liquid',
    'special/hax classification failed')

local all=catalog.collect(translate)
assert(#all==8, 'ALL must deduplicate materials reported by multiple classes')
for api,_ in pairs(lists) do
    local args=calls[api..'_args']
    assert(calls[api]==3 and args, api..' must cache its full/static/particle enumerations')
end
local categories=catalog.categories()
assert(#categories==8 and categories[1].id=='ALL' and categories[4].id=='STATIC'
    and categories[7].id=='SOLIDS' and categories[8].id=='SPECIAL','material category surface wrong')
assert(#catalog.entries_for('SANDS')==0,'SANDS should remain lazy until requested')
while not catalog.is_ready('SANDS') do catalog.step('SANDS',translate,4) end
local sands=catalog.entries_for('SANDS')
assert(#sands==1,'powders must use one deterministic family for untagged duplicate API entries')
local sand_seen=false; for _,entry in ipairs(sands) do if entry.id=='sand' then sand_seen=true end; assert(entry.id~='rock_static','static leaked into powders') end
assert(sand_seen,'tagged powder missing')
while not catalog.is_ready('SOLIDS') do catalog.step('SOLIDS',translate,4) end
assert(#catalog.entries_for('SOLIDS')==1 and catalog.entries_for('SOLIDS')[1].id=='physics_rock','box2d classification failed')
assert(catalog.get('rock_static').categories.STATIC==true,'static membership missing')
assert(catalog.get('physics_rock').categories.SOLIDS==true,'physics-solid membership missing')
io.write('material_catalog=PASS lazy=true semantic_tags=true static=true physics=true special=true deduplicated=true\n')
