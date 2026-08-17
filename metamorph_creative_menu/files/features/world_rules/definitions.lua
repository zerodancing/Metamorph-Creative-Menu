if type(METAMORPH_CREATIVE_MENU_WORLD_RULE_DEFINITIONS) == "table" then return METAMORPH_CREATIVE_MENU_WORLD_RULE_DEFINITIONS end

local native_choice = { native=true, label="$mcm_rule_native" }
local off_choice = { value=false, label="$mcm_rule_off" }
local on_choice = { value=true, label="$mcm_rule_on" }

local rules = {
    { id="relations", label="$mcm_rule_relations", description="$mcm_rule_relations_desc", field="global_genome_relations_modifier", kind="field",
      choices={ native_choice, {value=-100,label="$mcm_rule_hostile"}, {value=0,label="$mcm_rule_neutral"}, {value=100,label="$mcm_rule_friendly"} } },
    { id="gold_forever", label="$mcm_rule_gold_forever", description="$mcm_rule_gold_forever_desc", field="perk_gold_is_forever", kind="field", choices={native_choice,on_choice,off_choice} },
    { id="infinite_spells", label="$mcm_rule_infinite_spells", description="$mcm_rule_infinite_spells_desc", field="perk_infinite_spells", secondary="consume_actions", kind="infinite_spells", choices={native_choice,on_choice,off_choice} },
    { id="reveal_world", label="$mcm_rule_reveal_world", description="$mcm_rule_reveal_world_desc", field="open_fog_of_war_everywhere", kind="field", choices={native_choice,on_choice,off_choice} },
    { id="blood_money", label="$mcm_rule_blood_money", description="$mcm_rule_blood_money_desc", field="perk_trick_kills_blood_money", kind="field", choices={native_choice,on_choice,off_choice} },
    { id="hp_drops", label="$mcm_rule_hp_drops", description="$mcm_rule_hp_drops_desc", field="perk_hp_drop_chance", kind="field", integer=true,
      choices={ native_choice, {value=0,label="0"}, {value=10,label="10"}, {value=25,label="25"}, {value=50,label="50"}, {value=100,label="100"} } },
    { id="rats_friendly", label="$mcm_rule_rats_friendly", description="$mcm_rule_rats_friendly_desc", field="perk_rats_player_friendly", kind="field", choices={native_choice,on_choice,off_choice} },
    { id="gore", label="$mcm_rule_gore", description="$mcm_rule_gore_desc", field="gore_multiplier", kind="field",
      choices={ native_choice, {value=0,label="0x"}, {value=1,label="1x"}, {value=2,label="2x"}, {value=5,label="5x"}, {value=10,label="10x"} } },
    { id="trick_gold", label="$mcm_rule_trick_gold", description="$mcm_rule_trick_gold_desc", field="trick_kill_gold_multiplier", kind="field",
      choices={ native_choice, {value=1,label="1x"}, {value=2,label="2x"}, {value=4,label="4x"}, {value=8,label="8x"}, {value=16,label="16x"} } },
    { id="damage_flash", label="$mcm_rule_damage_flash", description="$mcm_rule_damage_flash_desc", field="damage_flash_multiplier", kind="field",
      choices={ native_choice, {value=0,label="0%"}, {value=0.5,label="50%"}, {value=1,label="100%"}, {value=2,label="200%"} } },
    { id="stain_drop", label="$mcm_rule_stain_drop", description="$mcm_rule_stain_drop_desc", field="stain_shaken_drop_chance_multiplier", kind="stain_drop",
      choices={ native_choice, {value=0,label="0x"}, {value=1,label="1x"}, {value=2,label="2x"}, {value=5,label="5x"}, {value=10,label="10x"} } },
    { id="physics_gravity", label="$mcm_rule_physics_gravity", description="$mcm_rule_physics_gravity_desc", kind="physics_gravity",
      choices={ native_choice, {value=-4,label="-4x"}, {value=-2,label="-2x"}, {value=-1,label="-1x"}, {value=-0.5,label="-0.5x"}, {value=-0.25,label="-0.25x"}, {value=-0.1,label="-0.1x"}, {value=0,label="0x"}, {value=0.1,label="0.1x"}, {value=0.25,label="0.25x"}, {value=0.5,label="0.5x"}, {value=1,label="1x"}, {value=2,label="2x"}, {value=4,label="4x"} } },
    { id="physics_damping", label="$mcm_rule_physics_damping", description="$mcm_rule_physics_damping_desc", kind="physics_damping",
      choices={ native_choice, {value=0,label="0x"}, {value=0.5,label="0.5x"}, {value=1,label="1x"}, {value=1.5,label="1.5x"}, {value=2,label="2x"} } },
    { id="blood_amount", label="$mcm_rule_blood_amount", description="$mcm_rule_blood_amount_desc", kind="magic_multiplier",
      magic_keys={"DAMAGE_BLOOD_AMOUNT_MIN","DAMAGE_BLOOD_AMOUNT_MAX"},
      choices={ native_choice, {value=0,label="0x"}, {value=0.5,label="0.5x"}, {value=1,label="1x"}, {value=2,label="2x"}, {value=5,label="5x"}, {value=10,label="10x"} } },
    { id="kick_force", label="$mcm_rule_kick_force", description="$mcm_rule_kick_force_desc", kind="magic_multiplier",
      magic_keys={"PLAYER_KICK_FORCE","PLAYER_KICK_VERLET_FORCE"},
      choices={ native_choice, {value=0,label="0x"}, {value=0.5,label="0.5x"}, {value=1,label="1x"}, {value=2,label="2x"}, {value=4,label="4x"}, {value=8,label="8x"} } },
    { id="joint_strength", label="$mcm_rule_joint_strength", description="$mcm_rule_joint_strength_desc", kind="magic_multiplier",
      magic_keys={"PHYSICS_JOINT_MAX_FORCE_MULTIPLIER"},
      choices={ native_choice, {value=0.25,label="0.25x"}, {value=0.5,label="0.5x"}, {value=1,label="1x"}, {value=2,label="2x"}, {value=4,label="4x"} } },
    { id="day_speed", label="$mcm_rule_day_speed", description="$mcm_rule_day_speed_desc", kind="magic_multiplier",
      magic_keys={"DESIGN_DAY_CYCLE_SPEED"},
      choices={ native_choice, {value=0,label="0x"}, {value=0.25,label="0.25x"}, {value=0.5,label="0.5x"}, {value=1,label="1x"}, {value=2,label="2x"}, {value=4,label="4x"}, {value=10,label="10x"} } },
}

METAMORPH_CREATIVE_MENU_WORLD_RULE_DEFINITIONS = rules
return rules
