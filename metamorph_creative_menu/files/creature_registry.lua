-- Compatibility registry for creatures from third-party mods.
-- A mod may ModLuaFileAppend() this file and insert descriptors:
-- table.insert(METAMORPH_CREATIVE_MENU_EXTERNAL_CREATURES, {
--   path = "mods/example/files/enemy.xml",
--   name = "$example_enemy_name", -- or plain text
--   category = "OTHER", -- optional
--   transform_safe = true, -- optional: author explicitly opts this target into the verified transform set
-- })
METAMORPH_CREATIVE_MENU_EXTERNAL_CREATURES = METAMORPH_CREATIVE_MENU_EXTERNAL_CREATURES or {}
