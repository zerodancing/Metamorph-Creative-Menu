-- Compatibility registry for third-party items.
-- Other mods may ModLuaFileAppend() a file to this path and insert descriptors:
-- table.insert(METAMORPH_CREATIVE_MENU_EXTERNAL_ITEMS, {
--   path = "mods/example/files/item.xml",
--   name = "$example_item_name", -- or plain text
--   description = "$example_item_desc",
--   icon = "mods/example/files/item.png",
--   category = "OTHER", -- optional
-- })
METAMORPH_CREATIVE_MENU_EXTERNAL_ITEMS = METAMORPH_CREATIVE_MENU_EXTERNAL_ITEMS or {}
