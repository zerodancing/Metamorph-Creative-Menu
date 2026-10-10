local root = assert(arg[1], "root")
local prefix = "mods/metamorph_creative_menu/"
local real_dofile = dofile

local files = {}
local dimensions = {}
local writes = {}
local existing = {}

local function add(path, content, w, h)
    existing[path] = true
    if content ~= nil then files[path] = content end
    if w ~= nil and h ~= nil then dimensions[path] = {w, h} end
end

local function sprite_xml(png, fw, fh, count, per_row, pos_x, pos_y, default_name, animation_name)
    default_name = default_name == false and nil or (default_name or "default")
    animation_name = animation_name or "default"
    return '<Sprite filename="' .. png .. '"' .. (default_name and (' default_animation="' .. default_name .. '"') or '') .. '>'
        .. '<RectAnimation name="' .. animation_name .. '" pos_x="' .. tostring(pos_x or 0) .. '" pos_y="' .. tostring(pos_y or 0)
        .. '" frame_count="' .. tostring(count or 1) .. '" frame_width="' .. tostring(fw) .. '" frame_height="' .. tostring(fh)
        .. '" frame_wait="0.12" frames_per_row="' .. tostring(per_row or count or 1) .. '" loop="1"></RectAnimation></Sprite>'
end

local HEART_XML = "data/items_gfx/heart_extrahp.xml"
local EVIL_XML = "data/items_gfx/heart_extrahp_evil.xml"
local FULL_XML = "data/items_gfx/heart.xml"
local REFRESH_XML = "data/items_gfx/spell_refresh.xml"
local CHAINSAW_XML = "data/items_gfx/wands/custom/chainsaw.xml"
add(HEART_XML, sprite_xml("data/items_gfx/heart_extrahp.png", 20, 20, 4, 4, 0, 0), nil, nil)
add("data/items_gfx/heart_extrahp.png", nil, 80, 20)
add(EVIL_XML, sprite_xml("data/items_gfx/heart_extrahp_evil.png", 20, 20, 4, 4, 0, 0), nil, nil)
add("data/items_gfx/heart_extrahp_evil.png", nil, 80, 40)
add(FULL_XML, sprite_xml("data/items_gfx/heart.png", 20, 20, 4, 4, 0, 0), nil, nil)
add("data/items_gfx/heart.png", nil, 80, 40)
add(REFRESH_XML, sprite_xml("data/items_gfx/spell_refresh.png", 20, 20, 4, 4, 0, 0), nil, nil)
add("data/items_gfx/spell_refresh.png", nil, 80, 20)
add(CHAINSAW_XML, sprite_xml("data/items_gfx/wands/custom/chainsaw.png", 14, 6, 2, 10, 0, 1), nil, nil)
add("data/items_gfx/wands/custom/chainsaw.png", nil, 28, 8)

for i = 0, 11 do
    local suffix = string.format("%02d", i)
    local xml = "data/items_gfx/orbs/orb_" .. suffix .. ".xml"
    local png = (i == 11) and "data/items_gfx/orbs/orb.png" or ("data/items_gfx/orbs/orb_" .. suffix .. ".png")
    add(xml, sprite_xml(png, 40, 50, 7, 7, 0, 0), nil, nil)
    add(png, nil, 280, 50)
end
add("data/items_gfx/orbs/orb.xml", sprite_xml("data/items_gfx/orbs/orb.png", 40, 50, 7, 7, 0, 0), nil, nil)
add("data/items_gfx/orbs/orb.png", nil, 280, 50)

-- Only the relevant real catalog entities are marked as present. ui_catalog's prewarm
-- therefore exercises the production catalog/outlier/registry collection without a Noita runtime.
for _, path in ipairs({
    "data/entities/items/pickup/heart.xml",
    "data/entities/items/pickup/heart_better.xml",
    "data/entities/items/pickup/heart_evil.xml",
    "data/entities/items/pickup/heart_fullhp.xml",
    "data/entities/items/pickup/heart_fullhp_temple.xml",
    "data/entities/items/pickup/spell_refresh.xml",
    "data/entities/items/wands/experimental/experimental_wand_4.xml",
}) do add(path, "<Entity></Entity>") end
for i = 0, 11 do add("data/entities/items/orbs/orb_" .. string.format("%02d", i) .. ".xml", "<Entity></Entity>") end
add("data/entities/items/orbs/orb_13.xml", "<Entity></Entity>")

local FIRST_XML = "data/test/no_default.xml"
add(FIRST_XML,
    '<Sprite filename="data/test/no_default.png"><RectAnimation name="idle" pos_x="3" pos_y="4" frame_count="2" frame_width="9" frame_height="7" frames_per_row="2"></RectAnimation><RectAnimation name="other" pos_x="0" pos_y="0" frame_count="1" frame_width="5" frame_height="5" frames_per_row="1"></RectAnimation></Sprite>')
add("data/test/no_default.png", nil, 18, 11)
local SIMPLE_PNG = "data/ui_gfx/items/simple_test.png"
add(SIMPLE_PNG, nil, 13, 17)
add("data/ui_gfx/inventory/inventory_box.png", nil, 18, 18)
add("data/ui_gfx/progress_menu/icon_unknown.png", nil, 16, 16)

local LATE_ENTITY = "mods/example/files/late_item.xml"
local LATE_XML = "mods/example/files/late_item_sprite.xml"
add(LATE_XML, sprite_xml("mods/example/files/late_item_sprite.png", 12, 10, 3, 3, 0, 0, false, "idle"))
add("mods/example/files/late_item_sprite.png", nil, 36, 10)
add(LATE_ENTITY, '<Entity><ItemComponent ui_sprite="mods/example/files/late_item_sprite.png"></ItemComponent><SpriteComponent _tags="item" image_file="mods/example/files/late_item_sprite.xml"></SpriteComponent></Entity>')
local BAD_XML = "mods/example/files/bad_sprite.xml"
add(BAD_XML, '<Sprite filename="mods/example/files/bad_sprite.png"></Sprite>')
add("mods/example/files/bad_sprite.png", nil, 64, 16)

function ModTextFileGetContent(path) return files[path] end
function ModTextFileSetContent(path, content)
    writes[#writes + 1] = {path=path, content=content}
    files[path] = content
    existing[path] = true
end
function ModDoesFileExist(path) return existing[path] == true end
function ModGetActiveModIDs() return {} end
function GuiGetImageDimensions(_, path)
    local d = dimensions[path]
    if d then return d[1], d[2] end
    return 0, 0
end

function dofile(path)
    if string.sub(path, 1, #prefix) == prefix then
        return real_dofile(root .. "/" .. string.sub(path, #prefix + 1))
    end
    return real_dofile(path)
end

METAMORPH_CREATIVE_MENU_ASSETS = nil
local assets = dofile(prefix .. "files/platform/noita/assets.lua")
local item_catalog = dofile(prefix .. "files/features/items/ui_catalog.lua")

local generated_catalog = assert(real_dofile(root .. "/files/features/items/catalog.lua"))
local by_path = {}
for _, entry in ipairs(generated_catalog) do by_path[entry.path] = entry end
local expected_gold_icons = {
    ["data/entities/items/pickup/goldnugget.xml"] = "data/ui_gfx/items/goldnugget.png",
    ["data/entities/items/pickup/goldnugget_10.xml"] = "data/ui_gfx/items/goldnugget.png",
    ["data/entities/items/pickup/goldnugget_50.xml"] = "data/ui_gfx/items/goldnugget.png",
    ["data/entities/items/pickup/goldnugget_200.xml"] = "data/ui_gfx/items/goldnugget.png",
    ["data/entities/items/pickup/goldnugget_1000.xml"] = "data/ui_gfx/items/goldnugget.png",
    ["data/entities/items/pickup/goldnugget_10000.xml"] = "data/items_gfx/easter/golden_idol.png",
    ["data/entities/items/pickup/goldnugget_200000.xml"] = "data/items_gfx/easter/golden_idol_big.png",
    ["data/entities/items/pickup/goldnugget_x.xml"] = "data/entities/animals/boss_centipede/rewards/gold_reward_sprite.png",
    ["data/entities/items/pickup/bloodmoney_10.xml"] = "data/ui_gfx/items/goldnugget.png",
    ["data/entities/items/pickup/bloodmoney_10000.xml"] = "data/items_gfx/easter/golden_idol.png",
    ["data/entities/items/pickup/bloodmoney_200000.xml"] = "data/items_gfx/easter/golden_idol_big.png",
    ["data/entities/items/pickup/bloodmoney_x.xml"] = "data/entities/animals/boss_centipede/rewards/gold_reward_sprite.png",
}
for entity_path, icon_path in pairs(expected_gold_icons) do
    assert(by_path[entity_path] and by_path[entity_path].icon == icon_path,
        "gold/catalog presentation still points at generic icon: " .. entity_path)
end

-- Post-init collection must cover the real built-in catalog sources and deduplicate shared icons.
local prepared, failed = item_catalog.prewarm_icons(assets)
assert(prepared > 0 and failed == 0, "catalog icon prewarm failed")
local writes_after_catalog = #writes
assert(writes_after_catalog > 0, "catalog prewarm did not publish proxies")

local heart = assert(assets.resolve(HEART_XML), "heart descriptor missing")
assert(heart.kind == "sprite_proxy" and heart.single_frame == true, "heart did not use prewarmed one-frame proxy")
assert(heart.width == 20 and heart.height == 20, "heart frame dimensions wrong")
assert(heart.animation_name == "default", "heart default animation not selected")
assert(heart.rect_animation.pos_x == 0 and heart.rect_animation.pos_y == 0, "heart crop origin wrong")

local evil = assert(assets.resolve(EVIL_XML), "evil heart descriptor missing")
assert(evil.width == 20 and evil.height == 20 and evil.single_frame == true, "evil heart frame descriptor wrong")
local refresh = assert(assets.resolve(REFRESH_XML), "spell refresh descriptor missing")
assert(refresh.width == 20 and refresh.height == 20 and refresh.single_frame == true, "spell refresh frame descriptor wrong")
local orb = assert(assets.resolve("data/items_gfx/orbs/orb_00.xml"), "orb descriptor missing")
assert(orb.width == 40 and orb.height == 50 and orb.single_frame == true, "orb frame descriptor wrong")
local orb13 = assert(assets.resolve("data/items_gfx/orbs/orb.xml"), "orb 13 descriptor missing")
assert(orb13.width == 40 and orb13.height == 50, "orb 13 frame descriptor wrong")
local chainsaw = assert(assets.resolve(CHAINSAW_XML), "chainsaw descriptor missing")
assert(chainsaw.width == 14 and chainsaw.height == 6, "chainsaw frame dimensions wrong")
assert(chainsaw.rect_animation.pos_y == 1, "chainsaw non-zero pos_y was lost")

-- A source atlas PNG with a sibling Sprite XML must never escape as a successful raster icon.
local atlas_request = assert(assets.resolve("data/items_gfx/heart_extrahp.png"), "atlas request missing descriptor")
assert(atlas_request.path ~= "data/items_gfx/heart_extrahp.png", "animated source atlas returned as icon")
assert(atlas_request.single_frame == true, "atlas request did not route to one-frame descriptor")

-- A genuine single-frame PNG remains a raster and is not forced through XML machinery.
assets.bind_gui({})
local simple = assert(assets.resolve(SIMPLE_PNG), "single-frame PNG missing")
assert(simple.kind == "raster" and simple.path == SIMPLE_PNG and simple.single_frame == true, "single-frame PNG was rewritten")
assert(assets.dimensions(simple) == 13, "single-frame PNG dimensions unavailable")

-- Default animation fallback: when Sprite.default_animation is absent, first RectAnimation wins.
local before_first = #writes
local first_prepared, first_failed = assets.prewarm({FIRST_XML, FIRST_XML})
assert(first_prepared == 1 and first_failed == 0, "deduplicated prewarm count wrong")
assert(#writes == before_first + 1, "duplicate XML path wrote more than one proxy")
local first = assert(assets.resolve(FIRST_XML), "first-animation descriptor missing")
assert(first.animation_name == "idle", "first RectAnimation was not selected")
assert(first.rect_animation.pos_x == 3 and first.rect_animation.pos_y == 4, "first animation crop metadata wrong")
local writes_before_repeat = #writes
assets.resolve(FIRST_XML); assets.resolve(FIRST_XML); assets.prewarm({FIRST_XML})
assert(#writes == writes_before_repeat, "prewarmed proxy was written again during resolve/prewarm")

-- A third-party XML appearing after prewarm cannot receive an init proxy. It must still
-- resolve to its original Sprite XML descriptor with explicit animation metadata, never raw atlas.
local writes_before_late = #writes
local late = assert(assets.resolve_entity(LATE_ENTITY, "item"), "late mod item descriptor missing")
assert(#writes == writes_before_late, "runtime-discovered mod icon attempted late VFS proxy write")
assert(late.kind == "sprite_xml" and late.path == LATE_XML, "late mod item did not keep original Sprite XML")
assert(late.animation_name == "idle" and late.width == 12 and late.height == 10, "late mod animation descriptor incomplete")
assert(late.path ~= late.source_png and late.source_is_atlas == true, "late mod atlas escaped as raster")

-- Malformed mod XML fails closed to a placeholder and is not negative-cached forever.
local bad = assert(assets.resolve(BAD_XML), "malformed XML did not produce descriptor")
assert(bad.kind == "placeholder" and bad.reason == "sprite_xml_missing_animation", "malformed XML failure reason wrong")
local still_good = assert(assets.resolve(HEART_XML), "malformed XML poisoned unrelated asset")
assert(still_good.kind == "sprite_proxy", "malformed XML broke existing proxy")
files[BAD_XML] = sprite_xml("mods/example/files/bad_sprite.png", 16, 16, 4, 4, 0, 0, false, "idle")
local repaired = assert(assets.resolve(BAD_XML), "dynamic repaired XML stayed negative-cached")
assert(repaired.kind == "sprite_xml" and repaired.path == BAD_XML, "dynamic repaired XML did not recover")

-- Runtime presentation: tile and drag ghost must preserve the exact same descriptor metadata
-- through to GuiImage, including playback mode and RectAnimation name.
local stubs = {
    [prefix .. "files/platform/noita/input_guard.lua"] = {actions_allowed=function() return true end},
    [prefix .. "files/platform/noita/pointer.lua"] = {left_just_down=function() return false end},
    [prefix .. "files/platform/noita/text_entry_guard.lua"] = {active=function() return false end, clear=function() end, key=function() return nil end},
    [prefix .. "files/platform/noita/keycodes.lua"] = {resolve=function() return nil end},
    [prefix .. "files/platform/noita/localization.lua"] = {translate=function(v) return tostring(v or "") end, search_aliases=function() return {} end},
    [prefix .. "files/core/search_engine.lua"] = {},
    [prefix .. "files/ui/widgets/scroll_model.lua"] = {begin_frame=function() end},
}
function dofile(path)
    if stubs[path] ~= nil then return stubs[path] end
    if string.sub(path, 1, #prefix) == prefix then return real_dofile(root .. "/" .. string.sub(path, #prefix + 1)) end
    return real_dofile(path)
end

GUI_OPTION = {Layout_NoLayouting=1}
local gui_draws = {}
local previous = {false, 10, 20, 18, 18}
function GuiImageButton(_, _, x, y)
    previous = {false, x, y, 18, 18}
    return false, false
end
function GuiGetPreviousWidgetInfo() return 0, 0, previous[1], previous[2], previous[3], previous[4], previous[5] end
function GuiTooltip() end
function GuiOptionsAddForNextWidget() end
function GuiColorSetForNextWidget() end
function GuiZSetForNextWidget() end
function GuiImage(_, _, x, y, path, alpha, sx, sy, rotation, playback, animation)
    gui_draws[#gui_draws + 1] = {path=path, x=x, y=y, alpha=alpha, sx=sx, sy=sy, rotation=rotation, playback=playback, animation=animation}
end

METAMORPH_CREATIVE_MENU_UI_RUNTIME = nil
local ui = real_dofile(root .. "/files/ui/runtime.lua")
ui.bind({})
ui.begin_frame()
ui.tile(0, 0, "data/ui_gfx/inventory/inventory_box.png", heart, nil, "Heart", "", false, {})
ui.drag_ghost("data/ui_gfx/inventory/inventory_box.png", heart, 50, 60, {})
local icon_draws = {}
for _, draw in ipairs(gui_draws) do if draw.path == heart.path then icon_draws[#icon_draws + 1] = draw end end
assert(#icon_draws == 2, "tile and drag ghost did not both draw the same icon descriptor")
for _, draw in ipairs(icon_draws) do
    assert(draw.playback == heart.playback_mode, "GuiImage playback mode lost")
    assert(draw.animation == heart.animation_name, "GuiImage RectAnimation name lost")
end

assert(#writes >= writes_after_catalog, "write accounting corrupted")
print("item_icon_descriptor=PASS heart=20x20 evil=true refresh=true orb=40x50 chainsaw_pos_y=1 default_first=true dedupe=true png=true prewarm=true late_mod_xml=true malformed_recovery=true no_atlas=true shared_draw_descriptor=true")
