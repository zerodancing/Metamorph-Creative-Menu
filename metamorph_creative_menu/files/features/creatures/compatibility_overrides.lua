-- Exact-path compatibility knowledge for creature forms.
--
-- This file is intentionally boring: no substring rules, no basename rules and no
-- directory-wide bans. A verdict belongs here only after the exact XML path has been
-- confirmed in game or is a tiny engine-specific alias that we deliberately own.
return {
    safe = {
        ["data/entities/animals/boss_wizard/meteor.xml"] = "manual_verified_playable",
        ["data/entities/animals/boss_centipede/orb_mat_radioactive.xml"] = "manual_verified_playable",
    },
    unsafe = {
        ["data/entities/animals/boss_sky/boss_sky_damage.xml"] = "native_transform_crash",
        ["data/entities/animals/boss_robot/rocket.xml"] = "projectile_death_overlay",
    },
    canonical = {
        ["data/entities/animals/the_end/worm_skull.xml"] = "data/entities/animals/worm_skull.xml",
        ["data/entities/animals/crypt/worm_skull.xml"] = "data/entities/animals/worm_skull.xml",
    },
}
