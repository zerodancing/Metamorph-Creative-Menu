local root=assert(arg[1], 'root required')
local calls={}
local lists={
    CellFactory_GetAllLiquids={'water','oil','shared'},
    CellFactory_GetAllSands={'sand','shared'},
    CellFactory_GetAllGases={'smoke'},
    CellFactory_GetAllFires={'fire'},
    CellFactory_GetAllSolids={'rock_static'},
}
for name, values in pairs(lists) do
    _G[name]=function(include_statics, include_particle_fx)
        calls[name]=(calls[name] or 0)+1
        calls[name..'_args']={include_statics,include_particle_fx}
        local out={}; for i,v in ipairs(values) do out[i]=v end; return out
    end
end
local ids={water=1,oil=2,shared=3,sand=4,smoke=5,fire=6,rock_static=7}
function CellFactory_GetType(name) return ids[name] or -1 end
function CellFactory_GetUIName(id) return '$mat_'..tostring(id) end
local function translate(key) return ({['$mat_1']='Water',['$mat_7']='Rock'})[key] or key end
METAMORPH_CREATIVE_MENU_MATERIAL_CATALOG=nil
local catalog=assert(dofile(root..'/files/features/materials/catalog.lua'))

-- Opening the default LIQUIDS category must not synchronously enumerate every material
-- class. Per-material processing is also bounded by the requested frame budget.
local done,used=catalog.step('LIQUIDS',translate,1)
assert(not done and used==1,'incremental material budget ignored')
assert(calls.CellFactory_GetAllLiquids==1,'liquid source not enumerated')
assert(calls.CellFactory_GetAllSands==nil and calls.CellFactory_GetAllGases==nil
    and calls.CellFactory_GetAllFires==nil and calls.CellFactory_GetAllSolids==nil,
    'opening one material category eagerly scanned unrelated categories')
assert(#catalog.entries_for('LIQUIDS')==1,'incremental category exposed wrong number of processed entries')
while not catalog.is_ready('LIQUIDS') do catalog.step('LIQUIDS',translate,2) end
assert(#catalog.entries_for('LIQUIDS')==3,'liquid catalog incomplete')

local all=catalog.collect(translate)
assert(#all==7, 'ALL must deduplicate materials reported by multiple classes')
for api,_ in pairs(lists) do
    local args=calls[api..'_args']
    assert(calls[api] and args and args[1]==true and args[2]==true,
        api..' must include static and particle-fx materials')
end
local categories=catalog.categories()
assert(#categories==6 and categories[1].id=='ALL' and categories[6].id=='SOLIDS', 'material category surface changed')
assert(#catalog.entries_for('SANDS')==2, 'sand catalog incomplete')
assert(catalog.get('water').display_name=='Water', 'translated material name not used')
assert(catalog.get('rock_static').categories.SOLIDS==true, 'static solid membership missing')
io.write('material_catalog=PASS lazy=true bounded=true any_loaded_materials=true deduplicated=true\n')
