if type(METAMORPH_CREATIVE_MENU_QA_CASES) == "table" then return METAMORPH_CREATIVE_MENU_QA_CASES end

local cases = {}
cases.WAIT_SHORT = 6
cases.WAIT_RULE = 20
cases.WAIT_WEATHER = 45
cases.FORM_DWELL = 12
cases.NETWORK_FORM_DWELL = 30
cases.NETWORK_FORM_SETTLE = 12
cases.NETWORK_PEER_LOSS_GRACE = 30
cases.NETWORK_FORM_CASES = {
    "data/entities/animals/miner.xml",
    "data/entities/animals/shotgunner_weak.xml",
    "data/entities/animals/fish.xml",
    "data/entities/animals/drone_physics.xml",
    "data/entities/animals/crystal_physics.xml",
    "data/entities/animals/darkghost.xml",
    "data/entities/animals/worm.xml",
    "data/entities/animals/worm_big.xml",
    "data/entities/animals/worm_end.xml",
    "data/entities/animals/boss_dragon.xml",
    "data/entities/animals/maggot.xml",
    "data/entities/animals/maggot_tiny/maggot_tiny.xml",
}
cases.SINGLEPLAYER_ITEM_RUNTIME_CASES = {
    -- Exhaustive catalogue validation is static. Only this small visible set is loaded
    -- into the world, then every new item-root created by the step is verified and retired.
    "data/entities/items/starting_wand.xml",
    "data/entities/items/pickup/broken_wand.xml",
    "data/entities/items/pickup/potion_empty.xml",
    "data/entities/items/pickup/beamstone.xml",
    "data/entities/items/pickup/physics_die.xml",
}
cases.NETWORK_ITEM_CASES = {
    "data/entities/items/starting_wand.xml",
    "data/entities/items/pickup/broken_wand.xml",
    "data/entities/items/pickup/potion_empty.xml",
    "data/entities/items/pickup/physics_die.xml",
    "data/entities/items/pickup/powder_stash.xml",
    "data/entities/items/pickup/egg_fire.xml",
    "data/entities/items/pickup/wandstone.xml",
}
cases.FORM_TIMEOUT = 180
cases.RETURN_TIMEOUT = 180
cases.HEARTBEAT_INTERVAL = 300

cases.QA_SKIP_PERKS = {
    -- GAMBLE is skipped only by the one-perk deterministic loop because it has its own
    -- random-reward round-trip. It is still included in the all-perks batch, where its
    -- parent transaction is removed before independently acquired reward copies.
    GAMBLE = "tested_by_random_roundtrip_and_all_perks_batch",
}

cases.CORE_FORM_CASES = {
    "data/entities/animals/illusions/worm_big.xml",
    "data/entities/animals/drone_physics.xml",
    "data/entities/animals/boss_dragon.xml",
    "data/entities/animals/maggot.xml",
    "data/entities/animals/maggot_tiny/maggot_tiny.xml",
    "data/entities/animals/worm_end.xml",
    "data/entities/animals/boss_wizard/meteor.xml",
    "data/entities/animals/boss_centipede/orb_mat_radioactive.xml",
}

cases.QA_UNSAFE_FORMS = {
    ["data/entities/animals/the_end/worm_skull.xml"] = "native_crash_observed",
    ["data/entities/animals/crypt/worm_skull.xml"] = "wrapper_uses_crash_prone_worm_skull_variant",
}


METAMORPH_CREATIVE_MENU_QA_CASES = cases
return cases
