local root=assert(arg[1], 'root required')
local policy=assert(dofile(root..'/files/core/menu_visibility_policy.lua'))

local function fresh() return policy.new() end

-- Always Open: each new native inventory session starts visible, but an explicit close
-- is respected for the remainder of the current session only.
do
    local state=fresh()
    policy.sync_inventory(state, true, 'always_open', true)
    assert(policy.visible(state)==true, 'always_open did not open on inventory edge')
    local remembered=policy.set_user_visible(state, false)
    assert(remembered==nil and policy.visible(state)==false, 'always_open explicit close was not temporary')
    policy.sync_inventory(state, false, 'always_open', true)
    assert(policy.visible(state)==false, 'always_open stayed visible after inventory close')
    policy.sync_inventory(state, true, 'always_open', true)
    assert(policy.visible(state)==true, 'always_open did not reopen on next inventory cycle')
end

-- Always Closed: inventory edges never auto-open. A manual open inside an inventory
-- session is session-scoped, while a manual open outside inventory remains a real manual window.
do
    local state=fresh()
    policy.sync_inventory(state, true, 'always_closed', true)
    assert(policy.visible(state)==false, 'always_closed auto-opened')
    assert(policy.set_user_visible(state, true)==nil and policy.visible(state)==true,
        'always_closed manual in-inventory open failed')
    policy.sync_inventory(state, false, 'always_closed', true)
    assert(policy.visible(state)==false, 'always_closed in-inventory manual window leaked past inventory close')
    policy.sync_inventory(state, true, 'always_closed', true)
    assert(policy.visible(state)==false, 'always_closed next inventory session did not start closed')
    policy.sync_inventory(state, false, 'always_closed', true)
    policy.set_user_visible(state, true)
    assert(policy.visible(state)==true, 'manual F4-style open outside inventory failed')
    policy.sync_inventory(state, true, 'always_closed', true)
    assert(policy.visible(state)==true, 'pre-existing manual window was discarded by inventory opening')
    policy.sync_inventory(state, false, 'always_closed', true)
    assert(policy.visible(state)==true, 'pre-existing manual window was discarded by inventory closing')
end

-- Remember Last State: only explicit user changes return a preference to persist. Native
-- inventory closing itself is automatic and must never overwrite the preference.
do
    local state=fresh()
    policy.sync_inventory(state, true, 'remember', true)
    assert(policy.visible(state)==true, 'remember=true was not restored')
    local remembered=policy.set_user_visible(state, false)
    assert(remembered==false and policy.visible(state)==false, 'explicit close did not persist remembered=false')
    local automatic=policy.sync_inventory(state, false, 'remember', false)
    assert(automatic==nil, 'automatic inventory close attempted to persist preference')
    policy.sync_inventory(state, true, 'remember', false)
    assert(policy.visible(state)==false, 'remember=false was not restored on next inventory open')
    remembered=policy.set_user_visible(state, true)
    assert(remembered==true and policy.visible(state)==true, 'explicit open did not persist remembered=true')
    policy.sync_inventory(state, false, 'remember', true)
    assert(policy.visible(state)==false, 'remembered in-inventory window did not auto-hide with inventory')

    -- Simulated restart: a new state consumes the saved setting and gets the same result.
    local restarted=fresh()
    policy.sync_inventory(restarted, true, 'remember', remembered)
    assert(policy.visible(restarted)==true, 'remember preference did not survive recreated state')
end

-- Unknown/legacy setting values must fail compatibly to the old behavior.
do
    local state=fresh()
    policy.sync_inventory(state, true, 'bogus_old_value', false)
    assert(policy.visible(state)==true and policy.normalize_mode('bogus_old_value')=='always_open',
        'invalid policy did not fail back to Always Open')
end

print('menu_inventory_visibility_policy=PASS always_open=true always_closed=true remember=true restart=true automatic_close=true')
