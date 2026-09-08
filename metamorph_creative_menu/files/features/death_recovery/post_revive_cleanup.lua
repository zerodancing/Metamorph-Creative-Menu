if type(METAMORPH_CREATIVE_MENU_POST_REVIVE_CLEANUP) == "table" then
    return METAMORPH_CREATIVE_MENU_POST_REVIVE_CLEANUP
end

-- Post-revive cleanup owns only side effects that outlive the stock Game Over UI.
-- It deliberately does not restore the player, cancel Game Over, or touch snapshots;
-- those remain death_recovery/service.lua responsibilities.
local post_revive_cleanup = {}

local native_gameover = dofile("mods/metamorph_creative_menu/files/platform/noita/native_gameover_patch.lua")

local state = {
    attempts = 0,
    successes = 0,
    last_reason = nil,
}

function post_revive_cleanup.apply(_player_entity)
    state.attempts = state.attempts + 1

    local ok, reason = native_gameover.cleanup_post_revive()
    state.last_reason = tostring(reason or (ok and "post_revive_cleaned" or "unknown"))
    if ok then state.successes = state.successes + 1 end

    -- Cleanup is best-effort by design. Player authority and Game Over cancellation have
    -- already succeeded before this function is called, so a failed secondary cleanup
    -- must never re-arm death or strand the player on the Game Over screen.
    return ok == true, state.last_reason
end

function post_revive_cleanup.status()
    return {
        attempts = state.attempts,
        successes = state.successes,
        last_reason = state.last_reason,
    }
end

METAMORPH_CREATIVE_MENU_POST_REVIVE_CLEANUP = post_revive_cleanup
return post_revive_cleanup
