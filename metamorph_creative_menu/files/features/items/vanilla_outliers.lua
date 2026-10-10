-- Vanilla stores these genuine ItemComponent entities under the animals tree, so a
-- directory-based item catalogue misses them. Keep the explicit role correction
-- separate from the generated catalogue: game updates can regenerate catalog.lua
-- without silently dropping these authored collectibles again.
return {
    { path="data/entities/animals/boss_alchemist/key.xml", name="$item_key",
      description="$itemdesc_key_0", icon="data/ui_gfx/items/key.png", category="QUEST" },
    { path="data/entities/animals/boss_centipede/sampo.xml", name="$item_mcguffin",
      description="$itemdesc_mcguffin", icon="data/ui_gfx/items/sampo.png", category="QUEST" },

    { path="data/entities/animals/boss_centipede/rewards/gold_reward.xml",
      name="$reward_gold_statue", category="BONUSES" },
    { path="data/entities/animals/boss_centipede/rewards/reward_almostpacifist.xml",
      name="$reward_almostpacifist", category="BONUSES" },
    { path="data/entities/animals/boss_centipede/rewards/reward_clock.xml",
      name="$reward_clock", category="BONUSES" },
    { path="data/entities/animals/boss_centipede/rewards/reward_crown.xml",
      name="$reward_crown", category="BONUSES" },
    { path="data/entities/animals/boss_centipede/rewards/reward_dollar.xml",
      name="$reward_dollar", category="BONUSES" },
    { path="data/entities/animals/boss_centipede/rewards/reward_kicksonly.xml",
      name="$reward_kicksonly", category="BONUSES" },
    { path="data/entities/animals/boss_centipede/rewards/reward_minit.xml",
      name="$reward_minit", category="BONUSES" },
    { path="data/entities/animals/boss_centipede/rewards/reward_nohit.xml",
      name="$reward_nohit", category="BONUSES" },
    { path="data/entities/animals/boss_centipede/rewards/reward_nolla.xml",
      name="$reward_nolla", category="BONUSES" },
    { path="data/entities/animals/boss_centipede/rewards/reward_notinkeringofwands.xml",
      name="$reward_notinkeringofwands", category="BONUSES" },
    { path="data/entities/animals/boss_centipede/rewards/reward_nowands.xml",
      name="$reward_nowands", category="BONUSES" },
    { path="data/entities/animals/boss_centipede/rewards/reward_peace.xml",
      name="$reward_peace", category="BONUSES" },
    { path="data/entities/animals/boss_centipede/rewards/reward_sun.xml",
      name="$reward_sun", category="BONUSES" },
}
