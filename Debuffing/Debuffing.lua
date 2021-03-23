_addon.name = 'Debuffing'
_addon.author = 'original: Auk, improvements and additions: Kenshi'
_addon.version = '1.7'
_addon.commands = {'df', 'debuffing'}

require('luau')
packets = require('packets')
texts = require('texts')

defaults = {}
defaults.pos = {}
defaults.pos.x = 600
defaults.pos.y = 300
defaults.text = {}
defaults.text.font = 'Consolas'
defaults.text.size = 10
defaults.flags = {}
defaults.flags.bold = false
defaults.flags.draggable = true
defaults.bg = {}
defaults.bg.alpha = 255
defaults.duration = {}

settings = config.load(defaults)
box = texts.new('${current_string}', settings)
box:show()

local frame_time = 0
local debuffed_mobs = {}
local TH = {}
local ja_spells = S{496,497,498,499,500,501}
local step_duration = {}
local erase_abilities = S{2370, 2571, 2714, 2718, 2775, 2831}
local partial_erase_abilities = S{1245, 1273}
local debuffs_map = {
    [112] = {effect = 156, duration = 12},
    [242] = {effect = 242, duration = 215}, --Absorb ACC
    [252] = {effect = 10, duration = 12},
    [266] = {effect = 266, duration = 215}, --Absorb STR
    [267] = {effect = 267, duration = 215}, --Absorb DEX
    [268] = {effect = 268, duration = 215}, --Absorb VIT
    [269] = {effect = 269, duration = 215}, --Absorb AGI
    [270] = {effect = 270, duration = 215}, --Absorb INT
    [271] = {effect = 271, duration = 215}, --Absorb MND
    [272] = {effect = 272, duration = 215}, --Absorb CHR
    [319] = {effect = 147, duration = 120},
    [341] = {effect = 4, duration = 120},
    [344] = {effect = 13, duration = 120},
    [345] = {effect = 13, duration = 300},
    [347] = {effect = 5, duration = 180},
    [348] = {effect = 5, duration = 180},
    [350] = {effect = 3, duration = 60},
    [351] = {effect = 3, duration = 120},
    [365] = {effect = 7, duration = 30},
    [376] = {effect = 193, duration = 45},
    [377] = {effect = 193, duration = 90},
    [463] = {effect = 193, duration = 45},
    [471] = {effect = 193, duration = 90},
    [508] = {effect = 168, duration = 180},
    [524] = {effect = 146, duration = 180},
    [531] = {effect = 11, duration = 60},
    [535] = {effect = 129, duration = 90},
    [572] = {effect = 140, duration = 30},
    [575] = {effect = 28, duration = 2},
    [598] = {effect = 2, duration = 90},
    [610] = {effect = 148, duration = 60},
    [644] = {effect = 4, duration = 90},
    [651] = {effect = {147,149}, duration = 90},
    [656] = {effect = 167, duration = 120},
    [659] = {effect = 147, duration = 30},
    [682] = {effect = 31, duration = 60},
    [687] = {effect = 6, duration = 90},
    [699] = {effect = 146, duration = 120},
    [703] = {effect = 13, duration = 180},
    [704] = {effect = 4, duration = 60},
    [705] = {effect = 133, duration = 180},
    [707] = {effect = 156, duration = 15},
    [708] = {effect = 12, duration = 120},
    [716] = {effect = 3, duration = 30},
    [719] = {effect = 128, duration = 90},
    [720] = {effect = 28, duration = 30},
    [725] = {effect = 156, duration = 60},
    [726] = {effect = 147, duration = 180},
    [738] = {effect = 28, duration = 30},
    [746] = {effect = 28, duration = 30},
}

function handle_overwrites(target, new, t)
    if not debuffed_mobs[target] then
        return true
    end
    
    for effect, spell in pairs(debuffed_mobs[target]) do
        local old = res.spells[spell.id].overwrites or {}
        
        -- Check if there isn't a higher priority debuff active
        if table.length(old) > 0 then
            for _,v in ipairs(old) do
                if new == v then
                    return false
                end
            end
        end
        
        -- Check if a lower priority debuff is being overwritten
        if table.length(t) > 0 then
            for _,v in ipairs(t) do
                if spell.id == v then
                    debuffed_mobs[target][effect] = nil
                end
            end
        end
    end
    return true
end

function apply_debuff(target, effect, spell, duration)
    if not debuffed_mobs[target] then
        debuffed_mobs[target] = {}
    end
    
    -- Check overwrite conditions
    local overwrites = res.spells[spell].overwrites or {}
    if not handle_overwrites(target, spell, overwrites) then
        return
    end
    
    local name = res.spells[spell] and res.spells[spell].en or 'Unknown'
    
    -- Create timer
    debuffed_mobs[target][effect] = {id = spell, name = name, timer = os.clock() + duration}
    if debuffs_map[spell] and type(debuffs_map[spell].effect) == 'table' then
        debuffed_mobs[target][effect].name = name..' ('..res.buffs[effect].en..')'
    end
end

function handle_shot(target, shot)
    if not debuffed_mobs[target] then
        return true
    end
    
    if shot == 125 and debuffed_mobs[target][128] then
        local current = debuffed_mobs[target][128].name
        debuffed_mobs[target][128].name = current..' (Fire Shot)'
    elseif shot == 126 then
        if debuffed_mobs[target][4] then
            local current = debuffed_mobs[target][4].name
            debuffed_mobs[target][4].name = current..' (Ice Shot)'
        end
        if debuffed_mobs[target][129] then
            local current = debuffed_mobs[target][129].name
            debuffed_mobs[target][129].name = current..' (Ice Shot)'
        end
    elseif shot == 127 and debuffed_mobs[target][130] then
        local current = debuffed_mobs[target][130].name
        debuffed_mobs[target][130].name = current..' (Wind Shot)'
    elseif shot == 128 then
        if debuffed_mobs[target][13] then
            local current = debuffed_mobs[target][13].name
            debuffed_mobs[target][13].name = current..' (Eart Shot)'
        end
        if debuffed_mobs[target][131] then
            local current = debuffed_mobs[target][131].name
            debuffed_mobs[target][131].name = current..' (Earth Shot)'
        end
    elseif shot == 129 and debuffed_mobs[target][132] then
        local current = debuffed_mobs[target][132].name
        debuffed_mobs[target][132].name = current..' (Thunder Shot)'
    elseif shot == 130 then
        if debuffed_mobs[target][3] then
            local current = debuffed_mobs[target][3].name
            debuffed_mobs[target][3].name = current..' (Dark Shot)'
        end
        if debuffed_mobs[target][133] then
            local current = debuffed_mobs[target][133].name
            debuffed_mobs[target][133].name = current..' (Dark Shot)'
        end
    elseif shot == 131 and debuffed_mobs[target][134] then
        local current = debuffed_mobs[target][134].name
        debuffed_mobs[target][134].name = current..' (Light Shot)'
    elseif shot == 132 then
        if debuffed_mobs[target][5] then
            local current = debuffed_mobs[target][5].name
            debuffed_mobs[target][5].name = current..' (Dark Shot)'
        end
        if debuffed_mobs[target][135] then
            local current = debuffed_mobs[target][135].name
            debuffed_mobs[target][135].name = current..' (Dark Shot)'
        end
    end
end

local ja_spells_names = {
    [496] = {
        [1] = 'Fire Damage + 5%',
        [2] = 'Fire Damage + 10%',
        [3] = 'Fire Damage + 15%',
        [4] = 'Fire Damage + 20%',
        [5] = 'Fire Damage + 25%',
        },
    [497] = {
        [1] = 'Ice Damage + 5%',
        [2] = 'Ice Damage + 10%',
        [3] = 'Ice Damage + 15%',
        [4] = 'Ice Damage + 20%',
        [5] = 'Ice Damage + 25%',
        },
    [498] = {
        [1] = 'Wind Damage + 5%',
        [2] = 'Wind Damage + 10%',
        [3] = 'Wind Damage + 15%',
        [4] = 'Wind Damage + 20%',
        [5] = 'Wind Damage + 25%',
        },
    [499] = {
        [1] = 'Earth Damage + 5%',
        [2] = 'Earth Damage + 10%',
        [3] = 'Earth Damage + 15%',
        [4] = 'Earth Damage + 20%',
        [5] = 'Earth Damage + 25%',
        },
    [500] = {
        [1] = 'Lightning Damage + 5%',
        [2] = 'Lightning Damage + 10%',
        [3] = 'Lightning Damage + 15%',
        [4] = 'Lightning Damage + 20%',
        [5] = 'Lightning Damage + 25%',
        },
    [501] = {
        [1] = 'Water Damage + 5%',
        [2] = 'Water Damage + 10%',
        [3] = 'Water Damage + 15%',
        [4] = 'Water Damage + 20%',
        [5] = 'Water Damage + 25%',
        },
}

function apply_ja_spells(target, spell)
    if not debuffed_mobs[target] then
        debuffed_mobs[target] = {}
    end
    
    local current = debuffed_mobs[target][1000]
    if current and current.name == spell then
		if ja_tier < 5 then
			ja_tier = current.tier + 1
		end
    else
        ja_tier = 1
        ja_timer = os.clock() + 60
    end
    
    debuffed_mobs[target][1000] = {id = spell, name = spell, tier = ja_tier, timer = ja_timer}
end

function update_box()
    local current_string = ''
    local player = windower.ffxi.get_player()
    local target = windower.ffxi.get_mob_by_target('st') or windower.ffxi.get_mob_by_target('t')
    
    if target and target.valid_target and target.is_npc and (target.claim_id ~= 0 or target.spawn_type == 16) then
    
        local debuff_table = debuffed_mobs[target.id]

        current_string = 'Debuffs ['..target.name..']'
        if TH[target.id] then
            current_string = current_string..'\n- '..TH[target.id]
        end
        if debuff_table then
            for effect, spell in pairs(debuff_table) do
                if spell then
                    if type(spell) == 'table' then
                        if (spell.timer - os.clock()) >= 0 then
                            if ja_spells:contains(spell.name) then
                                current_string = current_string..'\n- '..ja_spells_names[spell.name][spell.tier]
                                current_string = current_string..' : '..string.format('%.0f',spell.timer - os.clock())
                            else
                                current_string = current_string..'\n- '..spell.name --res.spells[spell.name].en
                                current_string = current_string..' : '..string.format('%.0f',spell.timer - os.clock())
                            end
                        else
                            debuff_table[effect] = nil
                        end
                    else
                        current_string = current_string..'\n- '..res.spells[spell].en
                    end
                end
            end
        end
    end

    box.current_string = current_string
end

function inc_action(act)
    if act.category == 4 then
        for i, v in pairs(act.targets) do
            if T{2,252,264,265}:contains(act.targets[i].actions[1].message) then
                if ja_spells:contains(act.param) then
                    apply_ja_spells(act.targets[i].id, act.param)
                else
                    local spell = act.param
                    if T{33,34,35,36,37}:contains(spell) then --Diaga handling
                        spell = spell - 10
                    end
                    local effect = res.spells[spell] and res.spells[spell].status or nil
                    local duration = settings.duration[tostring(spell)] or (res.spells[spell] and res.spells[spell].duration) or (debuffs_map[spell] and debuffs_map[spell].duration) or 0
                    if effect then
                        apply_debuff(act.targets[i].id, effect, act.param, duration)
                    end
                end
            elseif T{236,237,266,267,268,269,270,271,272,277,278,279,280}:contains(act.targets[i].actions[1].message) then
                local effect = act.targets[i].actions[1].param
                local target = act.targets[i].id
                local spell = act.param
                if T{225,226,227,228,229}:contains(spell) then --Poisonga handling
                    spell = spell - 5
                end
                if spell == 719 and debuffed_mobs[target][133] then --Special handling spells
                    return
                elseif spell == 535 and debuffed_mobs[target][128] then
                    return
                elseif spell == 705 and debuffed_mobs[target][132] then
                    return
                end
                local duration = settings.duration[tostring(spell)] or (res.spells[spell] and res.spells[spell].duration) or (debuffs_map[spell] and debuffs_map[spell].duration) or 0
                if res.spells[spell].status and res.spells[spell].status == effect then
                    apply_debuff(target, effect, act.param, duration)
                elseif debuffs_map[spell] and type(debuffs_map[spell].effect) == 'table' then
                    for i, v in pairs(debuffs_map[spell].effect) do
                        apply_debuff(target, v, act.param, duration)
                    end
                elseif debuffs_map[spell] and debuffs_map[spell].effect == effect then
                    apply_debuff(target, effect, act.param, duration)
                elseif debuffs_map[spell] then
                    apply_debuff(target, debuffs_map[spell].effect, act.param, duration)
                end
                --if res.action_messages[act.targets[i].actions[1].message] and res.action_messages[act.targets[i].actions[1].message].color ~= 'D' then
                    --if (debuffs_map[spell] and debuffs_map[spell].effect ~= effect) or (res.spells[spell] and res.spells[spell].status and res.spells[spell].status ~= effect) then
                        --log('Inconsistency: Spell '..spell..', Resources Effect '..res.spells[spell].status..', Debuffing Effect '..debuffs_map[spell].effect..', Server Effect '..effect)
                    --else
                        --log('Unhandled spell: Spell '..spell..', Effect '..effect)
                    --end
                --end
            
            elseif T{329,330,331,332,333,334,335,533}:contains(act.targets[i].actions[1].message) then --absorb spells
                local effect = debuffs_map[spell] and debuffs_map[spell].effect or nil
                if not effect then return end
                local target = act.targets[i].id
                local spell = act.param
                local duration = settings.duration[tostring(spell)] or (res.spells[spell] and res.spells[spell].duration) or (debuffs_map[spell] and debuffs_map[spell].duration) or 0
                local name = res.spells[spell] and res.spells[spell].en or 'Unknown'
                
                if not debuffed_mobs[target] then
                    debuffed_mobs[target] = {}
                end
                
                apply_debuff(target, effect, spell, duration)
            end
        end
    elseif act.category == 6 then
        if T{125,126,127,128,129,130,131,132}:contains(act.param) then
            handle_shot(act.targets[1].id, act.param)
        end
    elseif act.category == 14 then
        for i, v in pairs(act.targets) do
            if T{519,520,521,591}:contains(act.targets[i].actions[1].message) then
                local effect = act.param
                local target = act.targets[i].id
                local tier = act.targets[i].actions[1].param
                
                if not step_duration[target] then step_duration[target] = {} end
                if tier == 1 or not step_duration[target][effect] then
                    step_duration[target][effect] = os.clock() + 60
                elseif step_duration[target][effect] - os.clock() >= 90 then
                    step_duration[target][effect] = os.clock() + 120
                else
                    step_duration[target][effect] = step_duration[target][effect] + 30
                end
                
                if not debuffed_mobs[target] then
                    debuffed_mobs[target] = {}
                end
                
                debuffed_mobs[target][effect] = {name = res.job_abilities[effect].en.." lv."..tier, timer = step_duration[target][effect]}
            end
        end
    elseif T{1,7,8,11}:contains(act.category) then
        if debuffed_mobs[act.actor_id] then
            if debuffed_mobs[act.actor_id][2] then
                debuffed_mobs[act.actor_id][2] = nil
            elseif debuffed_mobs[act.actor_id][7] then
                debuffed_mobs[act.actor_id][7] = nil
            elseif debuffed_mobs[act.actor_id][28] then
                debuffed_mobs[act.actor_id][28] = nil
            elseif debuffed_mobs[act.actor_id][193] then
                debuffed_mobs[act.actor_id][193] = nil
            end
        end
        if act.category == 11 then
            for i, v in pairs(act.targets) do
                if T{101}:contains(act.targets[i].actions[1].message) then
                    if erase_abilities:contains(act.param) and debuffed_mobs[act.targets[i].id] then
                        debuffed_mobs[act.targets[i].id] = nil
                    end
                elseif T{159}:contains(act.targets[i].actions[1].message) then
                    if partial_erase_abilities:contains(act.param) and debuffed_mobs[act.targets[i].id] and debuffed_mobs[act.targets[i].id][act.targets[i].actions[1].param] then
                        debuffed_mobs[act.targets[i].id][act.targets[i].actions[1].param] = nil
                    end
                end
            end
        elseif act.category == 1 and act.targets[1].actions[1].has_add_effect and act.targets[1].actions[1].add_effect_message == 603 then
            TH[act.targets[1].id] = 'TH: '..act.targets[1].actions[1].add_effect_param
        end
    elseif act.category == 3 and act.targets[1].actions[1].message == 608 then
        TH[act.targets[1].id] = 'TH: '..act.targets[1].actions[1].param
    end
end

function inc_action_message(arr)
    if T{6,20,113,406,605,646}:contains(arr.message_id) then
        debuffed_mobs[arr.target_id] = nil
        TH[arr.target_id] = nil
    elseif T{204,206}:contains(arr.message_id) then
        if debuffed_mobs[arr.target_id] then
            if arr.message_id == 206 then
                if arr.param_1 == 136 then
                    debuffed_mobs[arr.target_id][arr.param_1] = nil
                    debuffed_mobs[arr.target_id][266] = nil
                elseif arr.param_1 == 137 then
                    debuffed_mobs[arr.target_id][arr.param_1] = nil
                    debuffed_mobs[arr.target_id][267] = nil
                elseif arr.param_1 == 138 then
                    debuffed_mobs[arr.target_id][arr.param_1] = nil
                    debuffed_mobs[arr.target_id][268] = nil
                elseif arr.param_1 == 139 then
                    debuffed_mobs[arr.target_id][arr.param_1] = nil
                    debuffed_mobs[arr.target_id][269] = nil
                elseif arr.param_1 == 140 then
                    debuffed_mobs[arr.target_id][arr.param_1] = nil
                    debuffed_mobs[arr.target_id][270] = nil
                elseif arr.param_1 == 141 then
                    debuffed_mobs[arr.target_id][arr.param_1] = nil
                    debuffed_mobs[arr.target_id][271] = nil
                elseif arr.param_1 == 142 then
                    debuffed_mobs[arr.target_id][arr.param_1] = nil
                    debuffed_mobs[arr.target_id][272] = nil
                elseif arr.param_1 == 146 then
                    debuffed_mobs[arr.target_id][arr.param_1] = nil
                    debuffed_mobs[arr.target_id][242] = nil
                elseif T{386,387,388,389,390}:contains(arr.param_1) then
                    debuffed_mobs[arr.target_id][201] = nil
                    step_duration[201] = 0
                elseif T{391,392,393,394,395}:contains(arr.param_1) then
                    debuffed_mobs[arr.target_id][202] = nil
                    step_duration[202] = 0
                elseif T{396,397,398,399,400}:contains(arr.param_1) then
                    debuffed_mobs[arr.target_id][203] = nil
                    step_duration[203] = 0
                elseif T{448,449,450,451,452}:contains(arr.param_1) then
                    debuffed_mobs[arr.target_id][312] = nil
                    step_duration[312] = 0
                else
                    debuffed_mobs[arr.target_id][arr.param_1] = nil
                end
            else
                debuffed_mobs[arr.target_id][arr.param_1] = nil
            end
        end
    end
end

windower.register_event('logout','zone change', function()
    debuffed_mobs = {}
    TH = {}
end)

windower.register_event('incoming chunk', function(id, data)
    if id == 0x028 then
        inc_action(windower.packets.parse_action(data))
    elseif id == 0x029 then
        local arr = {}
        arr.target_id = data:unpack('I',0x09)
        arr.param_1 = data:unpack('I',0x0D)
        arr.message_id = data:unpack('H',0x19)%32768
        
        inc_action_message(arr)
    elseif id == 0x00E then
        local packet = packets.parse('incoming', data)
        if TH[packet['NPC']] and packet['Status'] == 0 and packet['HP %'] == 100 then
            TH[packet['NPC']] = nil
        end
    end
end)

windower.register_event('prerender', function()
    local curr = os.clock()
    if curr > frame_time + .1 then
        frame_time = curr
        update_box()
    end
end)

windower.register_event('addon command', function(...)
    local commands = T{...}
    local player = windower.ffxi.get_player()
    if not player then return end
    if commands and #commands > 1 then
        local spell = tostring(table.concat(commands," ",1,#commands - 1):lower())
        local timer = tonumber(commands[#commands])
        if spell then --and type(timer) == 'number' then
            local result = false
            for i, v in pairs(res.spells) do
                if spell == (v.name):lower() or tonumber(spell) == i then
                    if type(timer) == 'number' then
                        if not settings.duration[player.name] then settings.duration[player.name] = {} end
                        settings.duration[player.name][tostring(v.id)] = timer
                        log('Duration for '..v.name..' set to '..timer..' seconds')
                        config.save(settings)
                    elseif commands[#commands]:lower() == 'remove' then
                        if settings.duration[player.name] and settings.duration[player.name][tostring(v.id)] then
                            settings.duration[player.name][tostring(v.id)] = nil
                            log('Duration for '..v.name..' removed')
                            config.save(settings)
                        else
                            log('Spell '..v.name..' doesn\'t have a specified timer')
                        end
                    end
                    result = true
                    break
                end
            end
            if not result then
                log('Spell not found: incorrent spell name/id or outdated resources')
            end
        else
            log('Invalid command: //df|debuffing [spell name|id] [time in seconds|remove]')
        end
    else
        log('Invalid command: //df|debuffing [spell name|id] [time in seconds|remove]')
    end
end)