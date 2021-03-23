_addon.name = 'TParty'
_addon.author = 'Cliff'
_addon.version = '2.0.1.2'

require('sets')
require('functions')
texts = require('texts')
config = require('config')
require('vectors')
require('maths')

defaults = {}
defaults.ShowTargetHPPercent = true
defaults.ShowTargetDistance = true
defaults.ShowPartyTP = true
defaults.ShowPartyDistance = true
defaults.ShowRanges = true

settings = config.load(defaults)

local zoning_bool = false

hpp = texts.new('${hpp}', {
    pos = {
        x = -104,
    },
    bg = {
        visible = false,
    },
    flags = {
        right = true,
        bottom = true,
        bold = true,
        draggable = false,
        italic = true,
    },
    text = {
        size = 10,
        alpha = 185,
        red = 115,
        green = 166,
        blue = 213,
    },
})

tdistance = texts.new('${distance||%.2f}', {
    pos = {
        x = -137,
    },
    bg = {
        visible = false,
    },
    flags = {
        right = true,
        bottom = true,
        bold = true,
        draggable = false,
        italic = false,
    },
    text = {
        size = 10,
        alpha = 185,
        red = 255,
        green = 255,
        blue = 255,
        stroke = {
                width = 2,
                alpha = 255,
                red = 0,
                green = 0,
                blue = 0,
                },
    },
})

rdistance = texts.new('${rdistance||%.2f}', {
    pos = {
        x = -177,
    },
    bg = {
        visible = false,
    },
    flags = {
        right = true,
        bottom = true,
        bold = true,
        draggable = false,
        italic = false,
    },
    text = {
        size = 12,
        alpha = 185,
        red = 255,
        green = 255,
        blue = 255,
        stroke = {
                width = 2,
                alpha = 255,
                red = 0,
                green = 0,
                blue = 0,
                },
    },
})

height = texts.new('${height||%.2f}', {
    pos = {
        x = -137,
    },
    bg = {
        visible = false,
    },
    flags = {
        right = true,
        bottom = true,
        bold = true,
        draggable = false,
        italic = false,
    },
    text = {
        size = 10,
        alpha = 185,
        red = 255,
        green = 255,
        blue = 255,
        stroke = {
                width = 2,
                alpha = 255,
                red = 0,
                green = 0,
                blue = 0,
                },
    },
})

tp = T{}

do
    local x_pos = windower.get_windower_settings().ui_x_res - 118

    for i = 0, 17 do
        local party = (i / 6):floor() + 1
        local key = {'p%i', 'a1%i', 'a2%i'}[party]:format(i % 6)
        local pos_base = {-34, -389, -288}
        tp[key] = texts.new('${tp}', {
            pos = {
                x = x_pos,
                y = pos_base[party] + 16 * (i % 6)
            },
            bg = {
                visible = false,
            },
            flags = {
                right = false,
                bottom = true,
                bold = true,
                draggable = false,
                italic = true,
            },
            text = {
                size = i < 6 and 10 or 8,
                alpha = 185,
                red = 255,
                green = 255,
                blue = 255,
            },
        })
    end
end

distance = T{}

do
    for i = 0, 17 do
        local party = (i / 6):floor() + 1
        local key = {'p%i', 'a1%i', 'a2%i'}[party]:format(i % 6)
        local pos_base = {-34, -396, -295}
        distance[key] = texts.new('${distance||%.1f}', {
            pos = {
                x = -152,
                y = pos_base[party] + 16 * (i % 6)
            },
            bg = {
                visible = false,
            },
            flags = {
                right = true,
                bottom = true,
                bold = true,
                draggable = false,
                italic = false,
            },
            text = {
                size = i < 6 and 10 or 8,
                alpha = 185,
                red = 255,
                green = 255,
                blue = 255,
                stroke = {
                    width = 2,
                    alpha = 255,
                    red = 0,
                    green = 0,
                    blue = 0,
                },
            },
        })
    end
end

hpp_y_pos = {}
for i = 1, 6 do
    hpp_y_pos[i] = -51 - 20 * i
end

tdistance_y_pos = {}
for i = 1, 6 do
    tdistance_y_pos[i] = -75 - 20 * i
end

rdistance_y_pos = {}
for i = 1, 6 do
    rdistance_y_pos[i] = -65 - 20 * i
end

height_y_pos = {}
for i = 1, 6 do
    height_y_pos[i] = -55 - 20 * i
end

ranges_y_pos = {}
for i = 1, 6 do
    ranges_y_pos[i] = -65 - 20 * i
end

key_indices = {
    p0 = 1,
    p1 = 2,
    p2 = 3,
    p3 = 4,
    p4 = 5,
    p5 = 6,
}
tp_y_pos = {}
for i = 1, 6 do
    tp_y_pos[i] = -34 - 20 * (6 - i)
end

distance_y_pos = {}
for i = 1, 6 do
    distance_y_pos[i] = -43 - 20 * (6 - i)
end

windower.register_event('incoming chunk', function(id, data)

    if id == 0xB then
        zoning_bool = true
    elseif id == 0xA and zoning_bool then
        zoning_bool = false
    end
    
end)

windower.register_event('status change', function(new_status_id)
	if new_status_id == 4 then --Cutscene/Menu
		zoning_bool = true
    else
        zoning_bool = false
    end
end)

windower.register_event('prerender', function() 
    -- HP % text
    if settings.ShowTargetHPPercent then
        local mob = windower.ffxi.get_mob_by_target('st') or windower.ffxi.get_mob_by_target('t')
        if zoning_bool then
            hpp:hide()
        elseif mob then
            local party_info = windower.ffxi.get_party_info()

            -- Adjust position for party member count
            hpp:pos_y(hpp_y_pos[party_info.party1_count])
            
            hpp:update(mob)
            hpp:show()
        else
            hpp:hide()
        end
    else
        hpp:hide()
    end
    
    -- Target distance and ranges text
    if settings.ShowTargetDistance then
        local player = windower.ffxi.get_player()
        if player then
            local t = windower.ffxi.get_mob_by_target('st') or windower.ffxi.get_mob_by_target('t')
            if zoning_bool then
                tdistance:hide()
                rdistance:hide()
                height:hide()
            elseif t then
                local s = windower.ffxi.get_mob_by_target('me')
                t.height = t.z - s.z
                t.rdistance = (t.distance + t.height^2):sqrt() 
                t.distance = t.distance:sqrt()
                local party_info = windower.ffxi.get_party_info()
                if player.index == t.index then
                    height:hide()
                    tdistance:hide()
                    rdistance:hide()
                elseif windower.ffxi.get_player().status ~= 4 then
                    height:show()
                    tdistance:show()
                    rdistance:show()
                end
        
                -- Adjust position for party member count
                tdistance:pos_y(tdistance_y_pos[party_info.party1_count])
                rdistance:pos_y(rdistance_y_pos[party_info.party1_count])
                height:pos_y(height_y_pos[party_info.party1_count])
                -- Color
                if t.spawn_type == 16 then
                    if t.height >= 8.5 or t.height <= -7.5 then
                        height:color(0,255,0)
                    else
                        height:color(255,0,0)
                    end
                else
                    height:color(255,255,255)
                end
                rdistance:update(t)
                tdistance:update(t)
                height:update(t)
            else
                height:hide()
                tdistance:hide()
                rdistance:hide()
            end
        else
            height:hide()
            tdistance:hide()
            rdistance:hide()
        end
    end

    -- Alliance TP texts
    if settings.ShowPartyTP then
        local party = T(windower.ffxi.get_party())
        local zone = windower.ffxi.get_info().zone
        
        for text, key in tp:it() do
            local member = party[key]
            if zoning_bool then
                text:hide()
            elseif member and member.zone == zone then
                -- Adjust position for party member count
                if key:startswith('p') then
                    text:pos_y(tp_y_pos[key_indices[key] + 6 - party.party1_count])
                end

                -- Color TP display green when TP > 1000
                if member.tp >= 1000 then
                    text:color(0, 255, 0)
                else
                    text:color(255, 255, 255)
                end

                text:update(member)
                text:show()
            else
                text:hide()
            end
        end
    end
    
    -- Alliance distance texts
    if settings.ShowPartyDistance then
        local party = T(windower.ffxi.get_party())
        local zone = windower.ffxi.get_info().zone
        local player = windower.ffxi.get_player()
        local target = windower.ffxi.get_mob_by_target('st') or windower.ffxi.get_mob_by_target('t')
        
        for text, key in distance:it() do
            local member = party[key]
            if zoning_bool then
                text:hide()
            elseif member and member.zone == zone then
                -- Adjust position for party member count
                if key:startswith('p') then
                    text:pos_y(distance_y_pos[key_indices[key] + 6 - party.party1_count])
                end

                if member.mob then
                    local mob = windower.ffxi.get_mob_by_index(member.mob.index)
                    if mob then
                        mob.distance = mob.distance:sqrt()
                        if mob.index == player.index or mob.valid_target == false then
                            text:hide()
                        elseif windower.ffxi.get_player().status ~= 4 then
                            if target and target.index == mob.index then
                                text:color(0, 255, 0)
                                text:show()
                            else
                                text:color(255, 255, 255)
                                text:show()
                            end
                        end
                        text:update(mob)
                    end
                end
                text:update(member)
            else
                text:hide()
            end
        end
    end
end)

--[[
Copyright © 2014-2015, Windower
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
    * Neither the name of Windower nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL Windower BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]
