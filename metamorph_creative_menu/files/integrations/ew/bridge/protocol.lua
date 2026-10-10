-- Stable Metamorph: Creative Menu transport contract.
-- RPC namespaces are positional in Entangled Worlds: slot order is wire protocol state.
-- Change NAMESPACE whenever RPC_ORDER or any registered RPC signature changes.
return {
    NAMESPACE = "metamorph_creative_menu:world_rules:v4:",
    RPC_ORDER = {
        "apply_world_rules",
        "request_world_rules",
        "sync_qa_state",
        "request_player_companion",
        "sync_form_pose",
        "remove_global_perk",
        "apply_weather_state",
        "request_weather_state",
        "retire_possession_target",
        "announce_light_form_protocol",
        "sync_material_paint",
    },
}
