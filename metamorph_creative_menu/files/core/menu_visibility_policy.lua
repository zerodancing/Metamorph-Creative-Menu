if type(METAMORPH_CREATIVE_MENU_VISIBILITY_POLICY) == 'table' then
    return METAMORPH_CREATIVE_MENU_VISIBILITY_POLICY
end

local policy = {}

policy.ALWAYS_OPEN = 'always_open'
policy.ALWAYS_CLOSED = 'always_closed'
policy.REMEMBER = 'remember'

function policy.normalize_mode(value)
    value = tostring(value or '')
    if value == policy.ALWAYS_CLOSED or value == policy.REMEMBER then return value end
    return policy.ALWAYS_OPEN
end

function policy.new()
    return {
        native_open = false,
        session_visible = false,
        manual_open = false,
        mode = policy.ALWAYS_OPEN,
    }
end

function policy.sync_inventory(state, native_open, mode, remembered_open)
    state = type(state) == 'table' and state or policy.new()
    native_open = native_open == true
    mode = policy.normalize_mode(mode)

    if native_open and state.native_open ~= true then
        if mode == policy.ALWAYS_OPEN then
            state.session_visible = true
        elseif mode == policy.REMEMBER then
            state.session_visible = remembered_open == true
        else
            state.session_visible = false
        end
    elseif not native_open and state.native_open == true then
        state.session_visible = false
    end

    state.native_open = native_open
    state.mode = mode
    return nil
end

function policy.visible(state)
    if type(state) ~= 'table' then return false end
    return state.manual_open == true or (state.native_open == true and state.session_visible == true)
end

function policy.set_user_visible(state, visible)
    state = type(state) == 'table' and state or policy.new()
    visible = visible == true
    if state.native_open == true then
        -- A manual window opened while native inventory is active belongs to that
        -- inventory session. Closing the native inventory therefore hides it again.
        state.session_visible = visible
        if not visible then state.manual_open = false end
    else
        state.manual_open = visible
    end
    if state.mode == policy.REMEMBER then return visible end
    return nil
end

function policy.toggle_user(state)
    return policy.set_user_visible(state, not policy.visible(state))
end

METAMORPH_CREATIVE_MENU_VISIBILITY_POLICY = policy
return policy
