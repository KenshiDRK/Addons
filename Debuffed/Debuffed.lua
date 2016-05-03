_addon.name = 'Debuffed'
_addon.author = 'original: Auk, improvements and additions: Kenshi'
_addon.version = '1.2'

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

settings = config.load(defaults)
box = texts.new('${current_string}', settings)
box:show()

frame_time = 0
debuffed_mobs = {}

helixes = S{278,279,280,281,282,283,284,285,
    885,886,887,888,889,890,891,892}

debuffs = {
    [2] = S{253,259,273,274,376,377,463,471,584,598,678}, --Sleep
    [3] = S{220,221,225,350,351,716}, --Poison
    [4] = S{58,80,341,644,704}, --Paralyze
    [5] = S{254,276,347,348}, --Blind
    [6] = S{59,687,727}, --Silence
    [7] = S{255,365,722}, --Break
    [10] = S{252}, --Stun
    [11] = S{258,531}, --Bind
    [12] = S{216,217,708}, --Gravity
    [13] = S{56,79,344,345,703}, --Slow
	[21] = S{286,472,884}, --addle/nocturne
	[28] = S{575,720,738,746}, --terror
	[31] = S{682}, --plague
    [128] = S{235,572,719}, --int down
    [129] = S{236,535}, --AGI down
    [130] = S{237}, --VIT down
    [131] = S{238}, --dex down
    [132] = S{239}, --mnd down
	[133] = S{240,705}, --str down
	[146] = S{524,699}, --accuracy down
	[147] = S{319,651,659,726}, --attack down
    [148] = S{610,841,842,882}, --Evasion Down
	[149] = S{651,717,728}, -- defense down
	[156] = S{112,707,725}, --Flash
	[167] = S{656}, --Magic Def. Down
	[168] = S{508}, --inhibit TP
	[192] = S{368,369,370,371,372,373,374,375}, --requiem
	[194] = S{421,422,423}, --elegy
	[217] = S{454,455,456,457,458,459,460,461,871,872,873,874,875,876,877,878}, --threnodies
    [242] = 242, --Absorb ACC
    [266] = 266, --Absorb STR
    [267] = 267, --Absorb DEX
    [268] = 268, --Absorb VIT
    [269] = 269, --Absorb AGI
    [270] = 270, --Absorb INT
    [271] = 271, --Absorb MND
    [272] = 272, --Absorb CHR
    [404] = S{843,844,883}, --Magic Evasion Down
	[597] = S{879}, --inundation

}

hierarchy = {
    [23] = 1, --Dia
    [24] = 4, --Dia II
    [25] = 6, --Dia III
    [33] = 2, --Diaga
    [230] = 3, --Bio
    [231] = 5, --Bio II
    [232] = 7, --Bio III
}

timers = T{}

function apply_dot(target, spell)
    if not debuffed_mobs[target] then
        debuffed_mobs[target] = {}
    end

    local priority = 0
    local current = debuffed_mobs[target][134] or debuffed_mobs[target][135]
    if current then
        priority = hierarchy[current.name] or hierarchy[current]
    end

    if hierarchy[spell] > priority then
        if T{23,24,25,33}:contains(spell) then
            if spell == 23 then
                debuffed_mobs[target][134] = {name = spell, timer = os.clock() + 60}
            elseif spell == 33 then
                debuffed_mobs[target][134] = {name = spell, timer = os.clock() + 60}
            elseif spell == 24 then
                debuffed_mobs[target][134] = {name = spell, timer = os.clock() + 120}
            else
                debuffed_mobs[target][134] = {name = spell, timer = os.clock() + 180}
            end
            debuffed_mobs[target][135] = nil
        elseif T{230,231,232}:contains(spell) then
            debuffed_mobs[target][134] = nil
            if spell == 230 then
                debuffed_mobs[target][135] = {name = spell, timer = os.clock() + 60}
            elseif spell == 231 then
                debuffed_mobs[target][135] = {name = spell, timer = os.clock() + 120}
            else
                debuffed_mobs[target][135] = {name = spell, timer = os.clock() + 180}
            end
        end
    end
end

function apply_helix(target, spell)
    if not debuffed_mobs[target] then
        debuffed_mobs[target] = {}
    end
    debuffed_mobs[target][186] = {name = spell, timer = os.clock() + 230}
end

function update_box()
    local current_string = ''
    local player = windower.ffxi.get_player()
    local target = windower.ffxi.get_mob_by_target('t')
    
    if target and target.valid_target and target.is_npc and (target.claim_id ~= 0 or target.spawn_type == 16) then
    
        local debuff_table = debuffed_mobs[target.id]

        current_string = 'Debuffed ['..target.name..']\n'
        if debuff_table then
            for effect, spell in pairs(debuff_table) do
                if spell then
                    if type(spell) == 'table' then
                        if (spell.timer - os.clock()) >= 0 then
                            current_string = current_string..'\n'..res.spells[spell.name].en
                            current_string = current_string..' : '..string.format('%.0f',spell.timer - os.clock())
                        else
                            debuff_table[effect] = nil
                        end
                    else
                        current_string = current_string..'\n'..res.spells[spell].en
                        if timers[spell] then
                            if (timers[spell] - os.clock()) >= 0 then
                                current_string = current_string..' : '..string.format('%.0f',timers[spell] - os.clock())
                            else
                                debuff_table[effect] = nil
                            end
                        end
                    end
                end
            end
        end     
    end

    box.current_string = current_string
end

function inc_action(act)
    if act.category == 4 then
        if act.targets[1].actions[1].message == 2 or act.targets[1].actions[1].message == 252 then
            if T{23,24,25,33,230,231,232}:contains(act.param) then
                apply_dot(act.targets[1].id, act.param)
            elseif helixes:contains(act.param) then
                apply_helix(act.targets[1].id, act.param)
            end
        elseif T{236,237,268,271}:contains(act.targets[1].actions[1].message) then
            local effect = act.targets[1].actions[1].param
            local target = act.targets[1].id
            local spell = act.param
            
            if T{575}:contains(spell) then -- Jettatura
                timers[spell] = os.clock() + 2
            elseif T{112,252}:contains(spell) then -- flash and stun
                timers[spell] = os.clock() + 12
            elseif T{225,255,365,350,659,716,720,738,746}:contains(spell) then -- 30 secs spells durations
                timers[spell] = os.clock() + 30
            elseif T{376,463}:contains(spell) then -- horde and foe lullaby
                timers[spell] = os.clock() + 45
                if debuffed_mobs[target] and debuffed_mobs[target][2] then
                    debuffed_mobs[target][2] = nil
                end
            elseif T{253,258,273,454,455,456,457,458,459,460,461,531,584,598,610,651,678,682,687,707,722,725}:contains(spell) then -- 1 min spells durations
                timers[spell] = os.clock() + 60
            elseif T{220,259,274,871,872,873,874,875,876,877,878}:contains(spell) then -- 1 min 30 secs spells durations
                timers[spell] = os.clock() + 90
            elseif T{377,471}:contains(spell) then -- horde and foe lullaby II
                timers[spell] = os.clock() + 90
                if debuffed_mobs[target] and debuffed_mobs[target][2] then
                    debuffed_mobs[target][2] = nil
                end
            elseif T{240,705}:contains(spell) then -- Drown overwrittes Burn
                timers[spell] = os.clock() + 90
                if debuffed_mobs[target] and debuffed_mobs[target][128] then
                    debuffed_mobs[target][128] = nil
                end
            elseif T{235,572,719}:contains(spell) then -- Burn overwrittes Frost
                timers[spell] = os.clock() + 90
                if debuffed_mobs[target] and debuffed_mobs[target][129] then
                    debuffed_mobs[target][129] = nil
                end
            elseif T{236,535}:contains(spell) then -- Frost overwrittes Choke
                timers[spell] = os.clock() + 90
                if debuffed_mobs[target] and debuffed_mobs[target][130] then
                    debuffed_mobs[target][130] = nil
                end
            elseif T{237}:contains(spell) then -- Choke overwrittes Rasp
                timers[spell] = os.clock() + 90
                if debuffed_mobs[target] and debuffed_mobs[target][131] then
                    debuffed_mobs[target][131] = nil
                end
            elseif T{238}:contains(spell) then -- Rasp overwrittes Shock
                timers[spell] = os.clock() + 90
                if debuffed_mobs[target] and debuffed_mobs[target][132] then
                    debuffed_mobs[target][132] = nil
                end
            elseif T{239}:contains(spell) then -- Rasp overwrittes Shock
                timers[spell] = os.clock() + 90
                if debuffed_mobs[target] and debuffed_mobs[target][133] then
                    debuffed_mobs[target][133] = nil
                end
            elseif T{56,58,59,80,216,217,221,319,341,344,351,368,369,370,371,372,373,374,375,421,644,656,704,708,717,841,842,843,844}:contains(spell) then -- 2 min spells durations
                timers[spell] = os.clock() + 120
            elseif T{882,883}:contains(spell) then -- 2 min 10 secs spells durations
                timers[spell] = os.clock() + 130
            elseif T{79,254,276,286,347,348,422,508,524,699,703}:contains(spell) then -- 3 min spells durations
                timers[spell] = os.clock() + 180
            elseif T{884}:contains(spell) then -- 3 min 10 secs spells durations
                timers[spell] = os.clock() + 190
            elseif T{423,472}:contains(spell) then -- 4 min spells durations
                timers[spell] = os.clock() + 240
            elseif T{345,726,727,728,879}:contains(spell) then -- 5 min spells durations
                timers[spell] = os.clock() + 300
            end
            
            if not debuffed_mobs[target] then
                debuffed_mobs[target] = {}
            end

            if debuffs[effect] and debuffs[effect]:contains(spell) then
                debuffed_mobs[target][effect] = spell
            end
        elseif T{329,330,331,332,333,334,335,533}:contains(act.targets[1].actions[1].message) then
            local effect = act.param
            local target = act.targets[1].id
            local spell = act.param
            timers[spell] = os.clock() + 215

            if not debuffed_mobs[target] then
                debuffed_mobs[target] = {}
            end

            if debuffs[effect] and tostring(debuffs[effect]):contains(spell) then
                debuffed_mobs[target][effect] = spell
            end
        end
    elseif act.category == 1 and debuffed_mobs[act.actor] then
        if debuffed_mobs[act.actor][2] then
            debuffed_mobs[act.actor][2] = nil
        elseif debuffed_mobs[act.actor][7] then
            debuffed_mobs[act.actor][7] = nil
        elseif debuffed_mobs[act.actor][28] then
            debuffed_mobs[act.actor][28] = nil
        end
    end
end

function inc_action_message(arr)
    if T{6,20,113,406,605,646}:contains(arr.message_id) then
        debuffed_mobs[arr.target_id] = nil
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
    end
end)

windower.register_event('prerender', function()
    local curr = os.clock()
    if curr > frame_time + .1 then
        frame_time = curr
        update_box()
    end
end)