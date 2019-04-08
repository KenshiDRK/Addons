--[[Copyright © 2017, Kenshi
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of PartyBuffs nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL KENSHI BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.]]

_addon.name = 'PartyBuffs'
_addon.author = 'Kenshi'
_addon.version = '3.0'
_addon.commands = {'pb', 'partybuffs'}

images = require('images')
packets = require('packets')
config = require('config')
require('pack')
require('tables')
require('filters')

defaults = {}
defaults.size = 10
defaults.mode = 'blacklist'

settings = config.load(defaults)

aliases = T{
    w            = 'whitelist',
    wlist        = 'whitelist',
    white        = 'whitelist',
    whitelist    = 'whitelist',
    b            = 'blacklist',
    blist        = 'blacklist',
    black        = 'blacklist',
    blacklist    = 'blacklist'
}

alias_strs = aliases:keyset()

local icon_size = (settings.size == 20 or defaults.size == 20) and 20 or 10
local party_buffs = {'p1', 'p2', 'p3', 'p4', 'p5'}

do
    local x_pos = windower.get_windower_settings().ui_x_res - 190
    for k = 1, 5 do
        party_buffs[k] = T{}
        
        for i = 1, 32 do
            party_buffs[k][i] = images.new({
                color = {
                    alpha = 255
                },
                texture = {
                    fit = false
                },
                draggable = false,
            })
        end
    end
end

local member_table = S{nil, nil, nil, nil, nil}

buffs = T{}
buffs['whitelist'] = {}
buffs['blacklist'] = {}

windower.register_event('incoming chunk', function(id, data)
    if id == 0x0DD then
        local packet = packets.parse('incoming', data)
        
        if not member_table:contains(packet['Name']) then
            member_table:append(packet['Name'])
            member_table[packet['Name']] = packet['ID']
        end
        coroutine.schedule(buff_sort, 0.5)
    end
    
    if id == 0x076 then
        for  k = 0, 4 do
            local id = data:unpack('I', k*48+5)
            buffs['whitelist'][id] = {}
			buffs['blacklist'][id] = {}
            
            if id ~= 0 then
                for i = 1, 32 do
                    local buff = data:byte(k*48+5+16+i-1) + 256*( math.floor( data:byte(k*48+5+8+ math.floor((i-1)/4)) / 4^((i-1)%4) )%4) -- Credit: Byrth, GearSwap
                    if buffs['whitelist'][id][i] ~= buff then
                        buffs['whitelist'][id][i] = buff
                    end
					if buffs['blacklist'][id][i] ~= buff then
                        buffs['blacklist'][id][i] = buff
                    end
                end
            end
        end
        buff_sort()
    end
    
    if id == 0xB then
        zoning_bool = true
        buff_sort()
    elseif id == 0xA and zoning_bool then
        zoning_bool = false
        coroutine.schedule(buff_sort, 10)
    end
end)

local x_pos = windower.get_windower_settings().ui_x_res - 190
local party_buffs_y_pos = {}
for i = 2, 6 do
    local y_pos = windower.get_windower_settings().ui_y_res - 5
    party_buffs_y_pos[i] = y_pos - 20 * i
end

function buff_sort()
    local player = windower.ffxi.get_player()
    local party = windower.ffxi.get_party()
    local key_indices = {'p1', 'p2', 'p3', 'p4', 'p5'}
    
    if not player then return end
    
    for k = 1, 5 do
        local member = party[key_indices[k]]
        for i = 1, 32 do
            if member then
                if buffs[settings.mode][member_table[member.name]] and buffs[settings.mode][member_table[member.name]][i] then
                    if buffs[settings.mode][member_table[member.name]][i] == 255 then
						buffs[settings.mode][member_table[member.name]][i] = 1000
					elseif blacklist[player.name] and blacklist[player.name][player.main_job] and blacklist[player.name][player.main_job]:contains(buffs['blacklist'][member_table[member.name]][i]) then
                        buffs['blacklist'][member_table[member.name]][i] = 1000
                    elseif whitelist[player.name] and whitelist[player.name][player.main_job] and not whitelist[player.name][player.main_job]:contains(buffs['whitelist'][member_table[member.name]][i]) then
                        buffs['whitelist'][member_table[member.name]][i] = 1000
                    end
                end
            end
        end
        if member and buffs[settings.mode][member_table[member.name]] then
			table.sort(buffs['blacklist'][member_table[member.name]])
			table.sort(buffs['whitelist'][member_table[member.name]])
		end
    end
	Update(buffs[settings.mode])
end

function Update(buff_table)
    local party_info = windower.ffxi.get_party_info()
    local zone = windower.ffxi.get_info().zone
    local party = windower.ffxi.get_party()
    local key_indices = {'p1', 'p2', 'p3', 'p4', 'p5'}
   
    for k = 1, 5 do
        local member = party[key_indices[k]]
        
        for image, i in party_buffs[k]:it() do
            if member then
                if buff_table[member_table[member.name]] and buff_table[member_table[member.name]][i] then
                    if zoning_bool or member.zone ~= zone or buff_table[member_table[member.name]][i] == 1000 then
                        buff_table[member_table[member.name]][i] = 1000
                        image:clear()
                        image:hide()
                    elseif buff_table[member_table[member.name]][i] == 255 or buff_table[member_table[member.name]][i] == 0 then
                        image:clear()
                        image:hide()
                    else            
                        image:path(windower.windower_path .. 'addons/PartyBuffs/icons/' .. buff_table[member_table[member.name]][i] .. '.png')
                        image:transparency(0)
                        image:size(icon_size, icon_size)
                        -- Adjust position for party member count
                        if party_info.party1_count > 1 then
                            local pt_y_pos = party_buffs_y_pos[party_info.party1_count] 
                            local x = (icon_size == 20 and x_pos - (i*20)) or (i <= 16 and x_pos - (i*10)) or x_pos - ((i-16)*10)
                            local y = (icon_size == 20 and pt_y_pos + ((k-1)*20)) or (i <= 16 and pt_y_pos + ((k-1)*20)) or  pt_y_pos + (((k-1)*20)+10)
                            image:pos_x(x)
                            image:pos_y(y)
                        end
                        image:show()
                    end
                end
            else
                image:clear()
                image:hide()
            end
            image:update()
        end
    end
    
end

windower.register_event('load', function() --Create member table if addon is loaded while already in pt
    if not windower.ffxi.get_info().logged_in then return end
    
    local party = windower.ffxi.get_party()
    local key_indices = {'p1', 'p2', 'p3', 'p4', 'p5'}
    
    for k = 1, 5 do
        local member = party[key_indices[k]]
        
        if member and member.mob then
            if not member.mob.is_npc and not member_table:contains(member.name) then
                member_table[k] = member.name
                member_table[member.name] = member.mob.id
            end
        end
    end
end)

windower.register_event('addon command', function(...)
    local args = T{...}
    local command = args[1] and args[1]:lower()
    if command then
        if command == 'size' then
            if not args[2] then
                windower.add_to_chat(207,"Size not specified.")
            elseif args[2] == '10' then
                if icon_size == 10 then
                    windower.add_to_chat(207,"Size already 10.")
                else
                    settings.size = 10
                    icon_size = 10
                    settings:save()
                    buff_sort()
                    windower.add_to_chat(207,'Icons size set to 10x10.')
                end
            elseif args[2] == '20' then
                if icon_size == 20 then
                    windower.add_to_chat(207,"Size already 20.")
                else
                    settings.size = 20
                    icon_size = 20
                    settings:save()
                    buff_sort()
                    windower.add_to_chat(207,'Icons size set to 20x20.')
                end
            else
                windower.add_to_chat(207,'Icons size has to be 10 or 20.')
            end
        elseif command == 'mode' then
            -- If no mode provided, print status.
            local mode = args[2] or 'status'
            if alias_strs:contains(mode) then
                if mode == settings.mode then
                    windower.add_to_chat(207,'Mode is already in ' .. mode .. ' mode.')
                else
                    settings.mode = aliases[mode]
                    windower.add_to_chat(207,'Mode switched to ' .. settings.mode .. '.')
                    settings:save()
                    buff_sort()
                end
            elseif mode == 'status' then
                windower.add_to_chat(207,'Currently in ' .. settings.mode .. ' mode.')
            else
                windower.add_to_chat(207,'Invalid mode:', args[1])
                return
            end
        elseif command == 'help' then
            windower.add_to_chat(207,"Partybuffs Commands:")
            windower.add_to_chat(207,"//pb|partybuffs size 10 (sets the icon size to 10x10)")
            windower.add_to_chat(207,"//pb|partybuffs size 20 (sets the icon size to 20x20)")
            windower.add_to_chat(207,"//pb|partybuffs mode w|wlist|white|whitelist (sets whitelist mode) ")
            windower.add_to_chat(207,"//pb|partybuffs mode b|blist|black|blacklist (sets blacklist mode) ")
        end
    else
        windower.add_to_chat(207,"First argument not specified, use size, mode or help.")
    end
end)