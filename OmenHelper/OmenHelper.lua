_addon.name = 'OmenHelper'
_addon.author = 'Kenshi'
_addon.version = '1.0'
_addon.command = 'oh'

packets = require('packets')
texts = require('texts')
require 'luau'
messages = require('messages')

defaults = {}
defaults.pos = {}
defaults.pos.x = 0
defaults.pos.y = 0
defaults.text = {}
defaults.text.font = 'Consolas'
defaults.text.size = 10

settings = config.load(defaults)

objetives_text = texts.new(settings)

local objetives = {true, false, false, false, false, false, false, false, false, false}
local subs_bool = true
local total = {}
local mains = {}
local subs = {}
local start_time = 0
local start_kills = 0

initialize = function(text, settings)
    local properties = L{}
    properties:append('Main Objetive:   Omens: ${omens}')
    properties:append('${Main_Objetive|Waiting objetives}${current}')
    if objetives[1] then
        properties:append('Sub Objetives:   Time: ${timer}')
        properties:append('${Sub_Objetive_1|Waiting objetives}${current_1}')
    end
    for i = 2, 10 do
        if objetives[i] then
            properties:append('${Sub_Objetive_'..i..'}${current_'..i..'}')
        end
    end
    text:clear()
    text:append(properties:concat('\n'))
end

objetives_text:register_event('reload', initialize)

objetives_text:hide()
if windower.ffxi.get_info().zone == 292 then -- Show if loaded in Omen
    objetives_text:show()
end

function party_size(message_id)
    local party = windower.ffxi.get_party()
    local key_indices = {'p1', 'p2', 'p3', 'p4', 'p5'}
    local party_size = 1
    local objetives_table = {[7331] = 1, [7332] = 3, [7333] = 1, [7334] = 3, [7335] = 2, [7336] = 3, [7337] = 3, [7338] = 5, [7339] = 3}
    
    for k = 1, 5 do
        local member = party[key_indices[k]]
        
        if member and member.mob then
            if not member.mob.is_npc then
                party_size = party_size + 1
            end
        end
    end
    return objetives_table[message_id] * party_size
end

--Omen messages in rom/353/58.dat
windower.register_event('incoming chunk',function(id, data)
    local zone_id = windower.ffxi.get_info().zone
    if id == 0x00B and objetives_text:visible() then
        objetives_text:clear()
        objetives_text:hide()
        for i = 2, 10 do
            if objetives[i] then
                objetives[i] = false
            end
        end
        objetives[1] = true
        initialize(objetives_text, settings)
    elseif id == 0x00A then
        local packet = packets.parse('incoming', data)
        if packet['Zone'] == 292 then
            objetives_text:show()
        end
    end
    if zone_id ~= 292 then
        return
    end
    if id == 0x027 then
        local packet = packets.parse('incoming', data)
        if packet.Type ~= 5 then
            return
        end
        local message_id = packet['Message ID'] - 0x8000
        if S{7319, 7323, 7324, 7325}:contains(message_id) then
            mains['Main_Objetive'] = get_messages(message_id, packet['Param 1'], packet['Param 2'], packet['Param 3'], packet['Param 4'])
            if S{7323, 7324, 7325}:contains(message_id) then
                subs_bool = false
            else
                subs_bool = true
                total_kills = packet['Param 1']
                if not mains['current'] or mains['current'] == '' then
                    mains['current'] = packet['Param 1']
                end
            end
            objetives_text:update(mains)
        elseif S{7329, 7330}:contains(message_id) then
            start_time = packet['Param 1']
            end_time = os.time() + start_time
        elseif message_id == 7331 then
            subs['current_'..packet['Param 1']] = '\\cs(0,255,0)Completed!\\cr'
            objetives_text:update(subs)
        elseif S{7333, 7334, 7335, 7336, 7337, 7338, 7339, 7340, 7341}:contains(message_id) then
            local current_progress = {}
            if packet['Param 4'] == 0 then
                subs['Sub_Objetive_'..packet['Param 1']] = get_messages(message_id, packet['Param 1'], packet['Param 2'], packet['Param 3'], packet['Param 4'])
                total[packet['Param 1']] = packet['Param 2']
                if not subs['current_'..packet['Param 1']] or subs['current_'..packet['Param 1']] == '\\cs(0,255,0)Completed!\\cr' or subs['current_'..packet['Param 1']] == '\\cs(255,0,0)Failed!\\cr' then
                    subs['current_'..packet['Param 1']] = packet['Param 2']
                end
                if not objetives[packet['Param 1']] then
                    objetives[packet['Param 1']] = true
                    initialize(objetives_text, settings)
                    objetives_text:update(mains)
                end
            elseif packet['Param 4'] == 3 then
                if not subs['Sub_Objetive_'..packet['Param 1']] then
                    subs['Sub_Objetive_'..packet['Param 1']] = get_messages(message_id, packet['Param 1'], party_size(message_id), packet['Param 3'], packet['Param 4'])
                    total[packet['Param 1']] = party_size(message_id)
                    if not objetives[packet['Param 1']] then
                        objetives[packet['Param 1']] = true
                        initialize(objetives_text, settings)
                        objetives_text:update(mains)
                    end
                end
                current_progress[packet['Param 1']] = total[packet['Param 1']] - packet['Param 2']
                subs['current_'..packet['Param 1']] = total[packet['Param 1']] == packet['Param 2'] and '\\cs(0,255,0)Completed!\\cr' or current_progress[packet['Param 1']]
            elseif packet['Param 4'] == 2 then
                subs['current_'..packet['Param 1']] = '\\cs(255,0,0)Failed!\\cr'
            else
                subs['current_'..packet['Param 1']] = '\\cs(0,255,0)Completed!\\cr'
            end
            objetives_text:update(subs)
        elseif S{7342, 7344, 7346, 7348}:contains(message_id) then --Progress for this objetives goes on other messages
            subs['Sub_Objetive_'..packet['Param 1']] = get_messages(message_id, packet['Param 1'], packet['Param 2'], packet['Param 3'], packet['Param 4'])
            if not objetives[packet['Param 1']] then
                objetives[packet['Param 1']] = true
                initialize(objetives_text, settings)
                objetives_text:update(mains)
            end
            if packet['Param 4'] == 0 then
                if not subs['current_'..packet['Param 1']] or subs['current_'..packet['Param 1']] == '\\cs(0,255,0)Completed!\\cr' or subs['current_'..packet['Param 1']] == '\\cs(255,0,0)Failed!\\cr' then
                    subs['current_'..packet['Param 1']] = '0'
                end
            elseif packet['Param 4'] == 3 then
                subs['current_'..packet['Param 1']] = '\\cs(0,255,0)Completed!\\cr'
            elseif packet['Param 4'] == 2 then
                subs['current_'..packet['Param 1']] = '\\cs(255,0,0)Failed!\\cr'
            else
                subs['current_'..packet['Param 1']] = '\\cs(0,255,0)Completed!\\cr'
            end
            objetives_text:update(subs)
        elseif S{7343, 7345, 7347, 7349}:contains(message_id) then --Progression messages for some objetives (adding failed and completed just to make sure, as it could go on both)
            subs['Sub_Objetive_'..packet['Param 1']] = get_messages(message_id, packet['Param 1'], packet['Param 2'], packet['Param 3'], packet['Param 4'])
            if not objetives[packet['Param 1']] then
                objetives[packet['Param 1']] = true
                initialize(objetives_text, settings)
                objetives_text:update(mains)
            end
            if packet['Param 4'] == 0 then
                if not subs['current_'..packet['Param 1']] or subs['current_'..packet['Param 1']] == '\\cs(0,255,0)Completed!\\cr' or subs['current_'..packet['Param 1']] == '\\cs(255,0,0)Failed!\\cr' then
                    subs['current_'..packet['Param 1']] = '0'
                end
            elseif packet['Param 4'] == 3 then
                subs['current_'..packet['Param 1']] = packet['Param 2']
            elseif packet['Param 4'] == 2 then
                subs['current_'..packet['Param 1']] = '\\cs(255,0,0)Failed!\\cr'
            else
                subs['current_'..packet['Param 1']] = '\\cs(0,255,0)Completed!\\cr'
            end
            objetives_text:update(subs)
        elseif S{7350}:contains(message_id) then
            subs['Sub_Objetive_'..packet['Param 1']] = get_messages(message_id, packet['Param 1'], packet['Param 2'], packet['Param 3'], packet['Param 4'])
            if not objetives[packet['Param 1']] then
                objetives[packet['Param 1']] = true
                initialize(objetives_text, settings)
                objetives_text:update(mains)
            end
            if packet['Param 4'] == 0 then
                if not subs['current_'..packet['Param 1']] or subs['current_'..packet['Param 1']] == '\\cs(0,255,0)Completed!\\cr' or subs['current_'..packet['Param 1']] == '\\cs(255,0,0)Failed!\\cr' then
                    subs['current_'..packet['Param 1']] = '10'
                end
            elseif packet['Param 4'] == 3 then
                local current_heals = packet['Param 3']
                subs['current_'..packet['Param 1']] = current_heals == 10 and '\\cs(0,255,0)Completed!\\cr' or (10 - current_heals)
            elseif packet['Param 4'] == 2 then
                subs['current_'..packet['Param 1']] = '\\cs(255,0,0)Failed!\\cr'
            else
                subs['current_'..packet['Param 1']] = '\\cs(0,255,0)Completed!\\cr'
            end
            objetives_text:update(subs)
        elseif message_id == 7327 then
            if packet['Param 1'] == 666 then
                mains['omens'] = '\\cs(0,255,0)' ..packet['Param 1'].. '\\cr'
            else
                mains['omens'] = packet['Param 1']
            end
            objetives_text:update(mains)
        end
    elseif id == 0x036 then
        local packet = packets.parse('incoming', data)
        mains['Main_Objetive'] = get_messages(packet['Message ID'], 0, 0, 0, 0)
        subs_bool = true
        if packet['Message ID'] == 7326 then
            mains['current'] = ''
            start_kills = 0
        end
        objetives_text:update(mains)
    elseif id == 0x029 then
        local packet = packets.parse('incoming', data)
        local mob = windower.ffxi.get_mob_by_index(packet['Target Index'])
        if S{6 , 20}:contains(packet['Message']) and mob and mob.name:startswith('Sweetwater') and total_kills and mains['Main_Objetive'] and mains['Main_Objetive']:endswith(': ') then
            local actual_kills = start_kills + 1
            start_kills = actual_kills
            mains['current'] = total_kills - actual_kills
            if mains['current'] <= 0 then
                mains['Main_Objetive'] = '\\cs(0,255,0)Completed!\\cr'
                mains['current'] = ''
            end
            objetives_text:update(mains)
        end
    elseif id == 0x05C then --wipe the secondary objetives after warping floor
        coroutine.sleep(1)
        if subs_bool then
            for i = 2, 10 do
                objetives[i] = false
                subs['current_'..i] = nil
            end
            objetives[1] = true
            subs['current_1'] = nil
        else
            for i = 1, 10 do
                objetives[i] = false
            end
        end
        start_time = 0
        initialize(objetives_text, settings)
        objetives_text:update(mains)
    elseif id == 0x00E then
        local packet = packets.parse('incoming', data)
        local mob = windower.ffxi.get_mob_by_id(packet['NPC'])
        if mob and mob.name == 'Ethereal Ingress' and packet['_unknown2'] == 768 then
            mains['Main_Objetive'] = '\\cs(0,255,0)Completed!\\cr'
            mains['current'] = ''
            objetives_text:update(mains)
        end
    end
end)

windower.register_event('prerender', function()
    if start_time == 0 then return end
    local total_time = end_time - os.time()
    if total_time == 0 then
        start_time = 0
    end
    subs.timer = (
        total_time < 30 and
                '\\cs(255,0,0)' .. total_time ..'\\cr'
            or total_time > 60 and
                '\\cs(0,255,0)' .. total_time ..'\\cr'
            or 
                '\\cs(255,128,0)' .. total_time .. '\\cr')
    objetives_text:update(subs)
end)