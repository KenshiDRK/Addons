--[[Copyright © 2016, Kenshi
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

config = require('config')
images = require('images')
packets = require('packets')
require('pack')
require('tables')

defaults = {}

settings = config.load(defaults)

party_buffs = {'p1', 'p2', 'p3', 'p4', 'p5'}

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

member_id = {nil, nil, nil, nil, nil}

names = {nil, nil, nil, nil, nil}

buff = {}

windower.register_event('incoming chunk', function(id, data)
        
    if id == 0x0DD then
        local packet = packets.parse('incoming', data)
        local party = windower.ffxi.get_party()
        local key_indices = {'p1', 'p2', 'p3', 'p4', 'p5',}
        
        for k = 1, 5 do
            local member = party[key_indices[k]]
            
            if names[k] == packet['Name'] then
                buff[k] = packet['ID']
                member_id[k] = packet['ID']
            end
            
            coroutine.sleep(3)
            if member and member.name == packet['Name'] then
                if not member_id[k] or member_id[k] ~= packet['ID'] then
                    buff[k] = packet['ID']
                    member_id[k] = packet['ID']
                end
            end
        end
        
    end
    
    if id == 0x076 then
        
        for  k = 0, 4 do
            local id = data:unpack('I', k*48+5)
            buff[id] = T{}
            
            if id ~= 0 then
                for i = 1, 32 do
                    buff[id][i] = data:byte(k*48+5+16+i-1) + 256*( math.floor( data:byte(k*48+5+8+ math.floor((i-1)/4)) / 4^((i-1)%4) )%4) -- Credit: Byrth, GearSwap
                end
            end
        end
        
    end
    
    if id == 0xB then
        zoning_bool = true
    elseif id == 0xA and zoning_bool then
        zoning_bool = false
    end
    
end)

party_buffs_y_pos = {}
for i = 1, 6 do
    local y_pos = windower.get_windower_settings().ui_y_res - 5
    party_buffs_y_pos[i] = y_pos - 20 * i
end

windower.register_event('prerender', function()
    local party_info = windower.ffxi.get_party_info()
    local zone = windower.ffxi.get_info().zone
    local party = windower.ffxi.get_party()
    local key_indices = {'p1', 'p2', 'p3', 'p4', 'p5',}
   
    for k = 1, 5 do
        local member = party[key_indices[k]]
        
        if member then
            if not names[k] or names[k] ~= member.name then
                names[k] = member.name
            end
        end
        
        if member and member.mob then
            if not member_id[k] or member_id[k] ~= member.mob.id then
                buff[k] = member.mob.id
                member_id[k] = member.mob.id
            end
        end
        
        for image, i in party_buffs[k]:it() do
            if zoning_bool then
                if member_id[k] and buff[member_id[k]] and buff[member_id[k]][i] and buff[member_id[k]][i] ~= 0 then
                    buff[member_id[k]][i] = 0
                end
                image:hide()
            elseif buff[member_id[k]] and buff[member_id[k]][i] then
                if member then
                    if member.mob and member.mob.is_npc then
                        image:hide()
                    elseif member.zone ~= zone then
                        if member_id[k] and buff[member_id[k]] and buff[member_id[k]][i] and buff[member_id[k]][i] ~= 0 then
                            buff[member_id[k]][i] = 0
                        end
                        image:hide()
                    else
                        if buff[member_id[k]][i] ~= 255 and buff[member_id[k]][i] ~= 0 then
                            image:path(windower.windower_path .. 'addons/PartyBuffs/icons/' .. buff[member_id[k]][i] .. '.png')
                            -- Adjust position for party member count
                            if party_info.party1_count ~= nil and i >= 17 then
                                image:pos_y(party_buffs_y_pos[party_info.party1_count] + (((k-1)*20)+10))
                            elseif party_info.party1_count ~= nil and i <= 16 then
                                image:pos_y(party_buffs_y_pos[party_info.party1_count] + ((k-1)*20))
                            end
                            image:show()
                        else
                            image:hide()
                        end
                    end
                else
                    image:hide()
                end
            else
                image:hide()
            end
            image:update()
        end
    
    end
    
end)