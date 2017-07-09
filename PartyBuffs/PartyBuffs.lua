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
_addon.version = '1.0'

images = require('images')
packets = require('packets')
require('pack')
require('tables')

local party_buffs = {'p1', 'p2', 'p3', 'p4', 'p5'}

do
    local x_pos = windower.get_windower_settings().ui_x_res - 190
    
    for k = 1, 5 do
        party_buffs[k] = T{}
        
        for i = 1, 16 do
            party_buffs[k][i] = images.new({
                pos = {
                    x = x_pos - (i*10),
                },
                draggable = false,
            })
        end
        for i = 17, 32 do
            party_buffs[k][i] = images.new({
                pos = {
                    x = x_pos - ((i-16)*10),
                },
                draggable = false,
            })
        end
    end
  
end

local member_table = S{nil, nil, nil, nil, nil}

local buffs = T{}

windower.register_event('incoming chunk', function(id, data)
        
    if id == 0x0DD then
        local packet = packets.parse('incoming', data)
        
        if not member_table:contains(packet['Name']) then
            member_table:append(packet['Name'])
            member_table[packet['Name']] = packet['ID']
        end
        coroutine.schedule(Update, 1)
        
    end
    
    if id == 0x076 then
        
        for  k = 0, 4 do
            local id = data:unpack('I', k*48+5)
            buffs[id] = {}
            
            if id ~= 0 then
                for i = 1, 32 do
                    local buff = data:byte(k*48+5+16+i-1) + 256*( math.floor( data:byte(k*48+5+8+ math.floor((i-1)/4)) / 4^((i-1)%4) )%4) -- Credit: Byrth, GearSwap
                    if buffs[id][i] ~= buff then
                        buffs[id][i] = buff
                    end
                end
            end
        end
        Update()
        
    end
    
    if id == 0xB then
        zoning_bool = true
        Update()
    elseif id == 0xA and zoning_bool then
        zoning_bool = false
        coroutine.schedule(Update, 10)
    end
    
end)

party_buffs_y_pos = {}
for i = 2, 6 do
    local y_pos = windower.get_windower_settings().ui_y_res - 5
    party_buffs_y_pos[i] = y_pos - 20 * i
end

function Update()
    local party_info = windower.ffxi.get_party_info()
    local zone = windower.ffxi.get_info().zone
    local party = windower.ffxi.get_party()
    local key_indices = {'p1', 'p2', 'p3', 'p4', 'p5'}
   
    for k = 1, 5 do
        local member = party[key_indices[k]]
        
        for image, i in party_buffs[k]:it() do
            if member then
                if buffs[member_table[member.name]] and buffs[member_table[member.name]][i] then
                    if zoning_bool then
                        buffs[member_table[member.name]][i] = 0
                        image:clear()
                        image:hide()
                    elseif member.zone ~= zone then
                        buffs[member_table[member.name]][i] = 0
                        image:clear()
                        image:hide()
                    elseif buffs[member_table[member.name]][i] == 255 or buffs[member_table[member.name]][i] == 0 then
                        image:clear()
                        image:hide()
                    else
                        image:path(windower.windower_path .. 'addons/PartyBuffs/icons/' .. buffs[member_table[member.name]][i] .. '.png')
                        -- Adjust position for party member count
                        if party_info.party1_count > 1 then
                            if i <= 16 then
                                image:pos_y(party_buffs_y_pos[party_info.party1_count] + ((k-1)*20))
                            else
                                image:pos_y(party_buffs_y_pos[party_info.party1_count] + (((k-1)*20)+10))
                            end
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