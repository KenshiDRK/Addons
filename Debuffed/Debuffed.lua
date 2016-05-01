_addon.name = 'Debuffed'
_addon.author = 'Auk'
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
    [2] = S{253,259,678}, --Sleep
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
	[136] = S{240,705}, --str down
	[137] = S{238}, --dex down
	[138] = S{237}, --VIT down
	[139] = S{236,535}, --AGI down
	[140] = S{235,572,719}, --int down
	[141] = S{239}, --mnd down
	[146] = S{524,699}, --accuracy down
	[147] = S{319,651,659,726}, --attack down
    [148] = S{610,841,842,882}, --Evasion Down
	[149] = S{717,728,651}, -- defense down
	[156] = S{112,707,725}, --Flash
	[167] = S{656}, --Magic Def. Down
	[168] = S{508}, --inhibit TP
	[192] = S{368,369,370,371,372,373,374,375}, --requiem
	[193] = S{463,471,376,377}, --lullabies
	[194] = S{421,422,423}, --elegy
	[217] = S{454,455,456,457,458,459,460,461,871,872,873,874,875,876,877,878}, --threnodies
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

function apply_dot(target, spell)
    if not debuffed_mobs[target] then
        debuffed_mobs[target] = {}
    end

    local priority = 0
    local current = debuffed_mobs[target][134] or debuffed_mobs[target][135]
    if current then
        priority = hierarchy[current.name]
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
                debuffed_mobs[target][134] = spell
            end
            debuffed_mobs[target][135] = nil
        elseif T{230,231,232}:contains(spell) then
            debuffed_mobs[target][134] = nil
            if spell == 230 then
                debuffed_mobs[target][135] = {name = spell, timer = os.clock() + 60}
            elseif spell == 231 then
                debuffed_mobs[target][135] = {name = spell, timer = os.clock() + 120}
            else
                debuffed_mobs[target][135] = spell
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

function show_bio(debuff_table)
    if debuff_table then
        if debuff_table[134] and debuff_table[134] == 25 then
            return false
        elseif debuff_table[135] and (debuff_table[135] == 231 or debuff_table[135] == 232) then
            return false
        end
    end
    return true
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
                        end
                    else
                        current_string = current_string..'\n'..res.spells[spell].en
                    end
                end
            end
        end     

        --if player and player.status == 1 then
          --  current_string = current_string..'\\cs(255,0,0)'
            --if show_bio(debuff_table) then
              --  current_string = current_string..'\nBio'
            --end
        --end
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

            if not debuffed_mobs[target] then
                debuffed_mobs[target] = {}
            end

            if debuffs[effect] and debuffs[effect]:contains(spell) then
                debuffed_mobs[target][effect] = spell
            end
        end
    end
end

function inc_action_message(arr)
    if T{6,20,113,406,605,646}:contains(arr.message_id) then
        debuffed_mobs[arr.target_id] = nil
    elseif T{204,206}:contains(arr.message_id) then
        if debuffed_mobs[arr.target_id] then
            debuffed_mobs[arr.target_id][arr.param_1] = nil
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