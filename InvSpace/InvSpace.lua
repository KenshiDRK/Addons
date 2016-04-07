--[[Copyright © 2015, Kenshi
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of BCTimer nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL Kenshi BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.]]

_addon.name = 'InvSpace'
_addon.author = 'Kenshi'
_addon.version = '2.0'


require('luau')
texts = require('texts')

-- Config

defaults = {}
defaults.ShowInventory = true
defaults.ShowSatchel = true
defaults.ShowSack = true
defaults.ShowCase = true
defaults.ShowWardrobe = true
defaults.ShowWardrobe2 = true
defaults.ShowSafe = true
defaults.ShowSafe2 = true
defaults.ShowStorage = true
defaults.ShowLocker = true
defaults.ShowGil = true
defaults.display = {}
defaults.display.pos = {}
defaults.display.pos.x = 0
defaults.display.pos.y = 0
defaults.display.bg = {}
defaults.display.bg.red = 0
defaults.display.bg.green = 0
defaults.display.bg.blue = 0
defaults.display.bg.alpha = 102
defaults.display.bg.visible = false
defaults.display.text = {}
defaults.display.text.font = 'Consolas'
defaults.display.text.red = 255
defaults.display.text.green = 255
defaults.display.text.blue = 255
defaults.display.text.alpha = 255
defaults.display.text.size = 10
defaults.display.text.stroke = {}
defaults.display.text.stroke.width = 2
defaults.display.text.stroke.alpha = 255
defaults.display.text.stroke.red = 0
defaults.display.text.stroke.green = 0
defaults.display.text.stroke.blue = 0

settings = config.load(defaults)

text_box = texts.new(settings.display, settings)

-- Function to comma the gils

function comma_value(n) -- credit http://richard.warburton.it
	local left,num,right = string.match(n,'^([^%d]*%d)(%d*)(.-)$')
	return left..(num:reverse():gsub('(%d%d%d)','%1,'):reverse())..right
end

-- Constructor

initialize = function(text, settings)
    local properties = L{}
    if settings.ShowInventory then
        properties:append(' ${inv_current|0}${inv_max|0}${inv_diff|0}')
    end
    if settings.ShowSatchel then
        properties:append(' ${sat_current|0}${sat_max|0}${sat_diff|0}')
    end
    if settings.ShowSack then
        properties:append(' ${sac_current|0}${sac_max|0}${sac_diff|0}')
    end
    if settings.ShowCase then
        properties:append(' ${case_current|0}${case_max|0}${case_diff|0}')
    end
    if settings.ShowWardrobe then
        properties:append(' ${war_current|0}${war_max|0}${war_diff|0}')
    end
    if settings.ShowWardrobe2 then
        properties:append(' ${war2_current|0}${war2_max|0}${war2_diff|0}')
    end
    if settings.ShowSafe then
        properties:append(' ${safe_current|0}${safe_max|0}${safe_diff|0}')
    end
    if settings.ShowSafe2 then
        properties:append(' ${safe2_current|0}${safe2_max|0}${safe2_diff|0}')
    end
    if settings.ShowStorage then
        properties:append(' ${sto_current|0}${sto_max|0}${sto_diff|0}')
    end
    if settings.ShowLocker then
        properties:append(' ${loc_current|0}${loc_max|0}${loc_diff|0}')
    end
    if settings.ShowGil then
        properties:append(' ${gil|0}')
    end
    text:clear()
    text:append(properties:concat('\n'))
end

text_box:register_event('reload', initialize)

windower.register_event('incoming chunk',function(id)
    if id == 0xB and text_box:visible() then
        zoning_bool = true
    elseif id == 0xA and zoning_bool then
        zoning_bool = nil
    end
end)

-- Events

windower.register_event('prerender', function()
    local get = windower.ffxi.get_bag_info()
    local giles = windower.ffxi.get_items().gil
    if not windower.ffxi.get_info().logged_in or not windower.ffxi.get_player() then
        text_box:hide()
        return
    end
    if zoning_bool then
        text_box:hide()
        return
    else
        local info = {}
        local inv_color = get.inventory.max - get.inventory.count
        info.inv_current = (
            inv_color == 0 and
                '\\cs(255,0,0)' .. ('Inventory: '..get.inventory.count:string():lpad(' ', 2))
            or inv_color > 10 and
                '\\cs(0,255,0)' .. ('Inventory: '..get.inventory.count:string():lpad(' ', 2))
            or 
                '\\cs(255,128,0)' .. ('Inventory: '..get.inventory.count:string():lpad(' ', 2))) .. '\\cr'
        info.inv_max = (
            inv_color == 0 and
                '\\cs(255,0,0)' .. ('/'..get.inventory.max:string():lpad(' ', 2))
            or inv_color > 10 and
                '\\cs(0,255,0)' .. ('/'..get.inventory.max:string():lpad(' ', 2))
            or 
                '\\cs(255,128,0)' .. ('/'..get.inventory.max:string():lpad(' ', 2))) .. '\\cr'
        info.inv_diff = (
            inv_color == 0 and
                '\\cs(255,0,0)' .. (' → ' .. (get.inventory.max - get.inventory.count):string():lpad(' ', 2))
            or inv_color > 10 and
                '\\cs(0,255,0)' .. (' → ' .. (get.inventory.max - get.inventory.count):string():lpad(' ', 2))
            or 
                '\\cs(255,128,0)' .. (' → '.. (get.inventory.max - get.inventory.count):string():lpad(' ', 2))) .. '\\cr'
        local sat_color = get.satchel.max - get.satchel.count
        info.sat_current = (
            sat_color == 0 and
                '\\cs(255,0,0)' .. ('Satchel:   '..get.satchel.count:string():lpad(' ', 2))
            or sat_color > 10 and
                '\\cs(0,255,0)' .. ('Satchel:   '..get.satchel.count:string():lpad(' ', 2))
            or 
                '\\cs(255,128,0)' .. ('Satchel:   '..get.satchel.count:string():lpad(' ', 2))) .. '\\cr'
        info.sat_max = (
            sat_color == 0 and
                '\\cs(255,0,0)' .. ('/'..get.satchel.max:string():lpad(' ', 2))
            or sat_color > 10 and
                '\\cs(0,255,0)' .. ('/'..get.satchel.max:string():lpad(' ', 2))
            or 
                '\\cs(255,128,0)' .. ('/'..get.satchel.max:string():lpad(' ', 2))) .. '\\cr'
        info.sat_diff = (
            sat_color == 0 and
                '\\cs(255,0,0)' .. (' → ' .. (get.satchel.max - get.satchel.count):string():lpad(' ', 2))
            or sat_color > 10 and
                '\\cs(0,255,0)' .. (' → ' .. (get.satchel.max - get.satchel.count):string():lpad(' ', 2))
            or 
                '\\cs(255,128,0)' .. (' → '.. (get.satchel.max - get.satchel.count):string():lpad(' ', 2))) .. '\\cr'
        local sac_color = get.sack.max - get.sack.count
        info.sac_current = (
            sac_color == 0 and
                '\\cs(255,0,0)' .. ('Sack:      '..get.sack.count:string():lpad(' ', 2))
            or sac_color > 10 and
                '\\cs(0,255,0)' .. ('Sack:      '..get.sack.count:string():lpad(' ', 2))
            or 
                '\\cs(255,128,0)' .. ('Sack:      '..get.sack.count:string():lpad(' ', 2))) .. '\\cr'
        info.sac_max = (
            sac_color == 0 and
                '\\cs(255,0,0)' .. ('/'..get.sack.max:string():lpad(' ', 2))
            or sac_color > 10 and
                '\\cs(0,255,0)' .. ('/'..get.sack.max:string():lpad(' ', 2))
            or 
                '\\cs(255,128,0)' .. ('/'..get.sack.max:string():lpad(' ', 2))) .. '\\cr'
        info.sac_diff = (
            sac_color == 0 and
                '\\cs(255,0,0)' .. (' → ' .. (get.sack.max - get.sack.count):string():lpad(' ', 2))
            or sac_color > 10 and
                '\\cs(0,255,0)' .. (' → ' .. (get.sack.max - get.sack.count):string():lpad(' ', 2))
            or 
                '\\cs(255,128,0)' .. (' → '.. (get.sack.max - get.sack.count):string():lpad(' ', 2))) .. '\\cr'
        local case_color = get.case.max - get.case.count
        info.case_current = (
            case_color == 0 and
                '\\cs(255,0,0)' .. ('Case:      '..get.case.count:string():lpad(' ', 2))
            or case_color > 10 and
                '\\cs(0,255,0)' .. ('Case:      '..get.case.count:string():lpad(' ', 2))
            or 
                '\\cs(255,128,0)' .. ('Case:      '..get.case.count:string():lpad(' ', 2))) .. '\\cr'
        info.case_max = (
            case_color == 0 and
                '\\cs(255,0,0)' .. ('/'..get.case.max:string():lpad(' ', 2))
            or case_color > 10 and
                '\\cs(0,255,0)' .. ('/'..get.case.max:string():lpad(' ', 2))
            or 
                '\\cs(255,128,0)' .. ('/'..get.case.max:string():lpad(' ', 2))) .. '\\cr'
        info.case_diff = (
            case_color == 0 and
                '\\cs(255,0,0)' .. (' → ' .. (get.case.max - get.case.count):string():lpad(' ', 2))
            or case_color > 10 and
                '\\cs(0,255,0)' .. (' → ' .. (get.case.max - get.case.count):string():lpad(' ', 2))
            or 
                '\\cs(255,128,0)' .. (' → '.. (get.case.max - get.case.count):string():lpad(' ', 2))) .. '\\cr'
        local war_color = get.wardrobe.max - get.wardrobe.count
        info.war_current = (
            war_color == 0 and
                '\\cs(255,0,0)' .. ('Wardrobe:  '..get.wardrobe.count:string():lpad(' ', 2))
            or war_color > 10 and
                '\\cs(0,255,0)' .. ('Wardrobe:  '..get.wardrobe.count:string():lpad(' ', 2))
            or 
                '\\cs(255,128,0)' .. ('Wardrobe:  '..get.wardrobe.count:string():lpad(' ', 2))) .. '\\cr'
        info.war_max = (
            war_color == 0 and
                '\\cs(255,0,0)' .. ('/'..get.wardrobe.max:string():lpad(' ', 2))
            or war_color > 10 and
                '\\cs(0,255,0)' .. ('/'..get.wardrobe.max:string():lpad(' ', 2))
            or 
                '\\cs(255,128,0)' .. ('/'..get.wardrobe.max:string():lpad(' ', 2))) .. '\\cr'
        info.war_diff = (
            war_color == 0 and
                '\\cs(255,0,0)' .. (' → ' .. (get.wardrobe.max - get.wardrobe.count):string():lpad(' ', 2))
            or war_color > 10 and
                '\\cs(0,255,0)' .. (' → ' .. (get.wardrobe.max - get.wardrobe.count):string():lpad(' ', 2))
            or 
                '\\cs(255,128,0)' .. (' → '.. (get.wardrobe.max - get.wardrobe.count):string():lpad(' ', 2))) .. '\\cr'
        local war2_color = get.wardrobe2.max - get.wardrobe2.count
        info.war2_current = (
            war2_color == 0 and
                '\\cs(255,0,0)' .. ('Wardrobe2: '..get.wardrobe2.count:string():lpad(' ', 2))
            or war2_color > 10 and
                '\\cs(0,255,0)' .. ('Wardrobe2: '..get.wardrobe2.count:string():lpad(' ', 2))
            or 
                '\\cs(255,128,0)' .. ('Wardrobe2: '..get.wardrobe2.count:string():lpad(' ', 2))) .. '\\cr'
        info.war2_max = (
            war2_color == 0 and
                '\\cs(255,0,0)' .. ('/'..get.wardrobe2.max:string():lpad(' ', 2))
            or war2_color > 10 and
                '\\cs(0,255,0)' .. ('/'..get.wardrobe2.max:string():lpad(' ', 2))
            or 
                '\\cs(255,128,0)' .. ('/'..get.wardrobe2.max:string():lpad(' ', 2))) .. '\\cr'
        info.war2_diff = (
            war2_color == 0 and
                '\\cs(255,0,0)' .. (' → ' .. (get.wardrobe2.max - get.wardrobe2.count):string():lpad(' ', 2))
            or war2_color > 10 and
                '\\cs(0,255,0)' .. (' → ' .. (get.wardrobe2.max - get.wardrobe2.count):string():lpad(' ', 2))
            or 
                '\\cs(255,128,0)' .. (' → '.. (get.wardrobe2.max - get.wardrobe2.count):string():lpad(' ', 2))) .. '\\cr'
        local safe_color = get.safe.max - get.safe.count
        info.safe_current = (
            safe_color == 0 and
                '\\cs(255,0,0)' .. ('Safe:      '..get.safe.count:string():lpad(' ', 2))
            or safe_color > 10 and
                '\\cs(0,255,0)' .. ('Safe:      '..get.safe.count:string():lpad(' ', 2))
            or 
                '\\cs(255,128,0)' .. ('Safe:      '..get.safe.count:string():lpad(' ', 2))) .. '\\cr'
        info.safe_max = (
            safe_color == 0 and
                '\\cs(255,0,0)' .. ('/'..get.safe.max:string():lpad(' ', 2))
            or safe_color > 10 and
                '\\cs(0,255,0)' .. ('/'..get.safe.max:string():lpad(' ', 2))
            or 
                '\\cs(255,128,0)' .. ('/'..get.safe.max:string():lpad(' ', 2))) .. '\\cr'
        info.safe_diff = (
            safe_color == 0 and
                '\\cs(255,0,0)' .. (' → ' .. (get.safe.max - get.safe.count):string():lpad(' ', 2))
            or safe_color > 10 and
                '\\cs(0,255,0)' .. (' → ' .. (get.safe.max - get.safe.count):string():lpad(' ', 2))
            or 
                '\\cs(255,128,0)' .. (' → '.. (get.safe.max - get.safe.count):string():lpad(' ', 2))) .. '\\cr'
        local safe2_color = get.safe2.max - get.safe2.count
        info.safe2_current = (
            safe2_color == 0 and
                '\\cs(255,0,0)' .. ('Safe2:     '..get.safe2.count:string():lpad(' ', 2))
            or safe2_color > 10 and
                '\\cs(0,255,0)' .. ('Safe2:     '..get.safe2.count:string():lpad(' ', 2))
            or 
                '\\cs(255,128,0)' .. ('Safe2:     '..get.safe2.count:string():lpad(' ', 2))) .. '\\cr'
        info.safe2_max = (
            safe2_color == 0 and
                '\\cs(255,0,0)' .. ('/'..get.safe2.max:string():lpad(' ', 2))
            or safe2_color > 10 and
                '\\cs(0,255,0)' .. ('/'..get.safe2.max:string():lpad(' ', 2))
            or 
                '\\cs(255,128,0)' .. ('/'..get.safe2.max:string():lpad(' ', 2))) .. '\\cr'
        info.safe2_diff = (
            safe2_color == 0 and
                '\\cs(255,0,0)' .. (' → ' .. (get.safe2.max - get.safe2.count):string():lpad(' ', 2))
            or safe2_color > 10 and
                '\\cs(0,255,0)' .. (' → ' .. (get.safe2.max - get.safe2.count):string():lpad(' ', 2))
            or 
                '\\cs(255,128,0)' .. (' → '.. (get.safe2.max - get.safe2.count):string():lpad(' ', 2))) .. '\\cr'
        local sto_color = get.storage.max - get.storage.count
        info.sto_current = (
            sto_color == 0 and
                '\\cs(255,0,0)' .. ('Storage:   '..get.storage.count:string():lpad(' ', 2))
            or sto_color > 10 and
                '\\cs(0,255,0)' .. ('Storage:   '..get.storage.count:string():lpad(' ', 2))
            or 
                '\\cs(255,128,0)' .. ('Storage:   '..get.storage.count:string():lpad(' ', 2))) .. '\\cr'
        info.sto_max = (
            sto_color == 0 and
                '\\cs(255,0,0)' .. ('/'..get.storage.max:string():lpad(' ', 2))
            or sto_color > 10 and
                '\\cs(0,255,0)' .. ('/'..get.storage.max:string():lpad(' ', 2))
            or 
                '\\cs(255,128,0)' .. ('/'..get.storage.max:string():lpad(' ', 2))) .. '\\cr'
        info.sto_diff = (
            sto_color == 0 and
                '\\cs(255,0,0)' .. (' → ' .. (get.storage.max - get.storage.count):string():lpad(' ', 2))
            or sto_color > 10 and
                '\\cs(0,255,0)' .. (' → ' .. (get.storage.max - get.storage.count):string():lpad(' ', 2))
            or 
                '\\cs(255,128,0)' .. (' → '.. (get.storage.max - get.storage.count):string():lpad(' ', 2))) .. '\\cr'
        local loc_color = get.locker.max - get.locker.count
        info.loc_current = (
            loc_color == 0 and
                '\\cs(255,0,0)' .. ('Locker:    '..get.locker.count:string():lpad(' ', 2))
            or loc_color > 10 and
                '\\cs(0,255,0)' .. ('Locker:    '..get.locker.count:string():lpad(' ', 2))
            or 
                '\\cs(255,128,0)' .. ('Locker:    '..get.locker.count:string():lpad(' ', 2))) .. '\\cr'
        info.loc_max = (
            loc_color == 0 and
                '\\cs(255,0,0)' .. ('/'..get.locker.max:string():lpad(' ', 2))
            or loc_color > 10 and
                '\\cs(0,255,0)' .. ('/'..get.locker.max:string():lpad(' ', 2))
            or 
                '\\cs(255,128,0)' .. ('/'..get.locker.max:string():lpad(' ', 2))) .. '\\cr'
        info.loc_diff = (
            loc_color == 0 and
                '\\cs(255,0,0)' .. (' → ' .. (get.locker.max - get.locker.count):string():lpad(' ', 2))
            or loc_color > 10 and
                '\\cs(0,255,0)' .. (' → ' .. (get.locker.max - get.locker.count):string():lpad(' ', 2))
            or 
                '\\cs(255,128,0)' .. (' → '.. (get.locker.max - get.locker.count):string():lpad(' ', 2))) .. '\\cr'
        local gil = comma_value(giles)
        info.gil = (
            comma_value(giles) == 0 and
                '\\cs(255,0,0)' .. ('Gil: ' .. comma_value(giles):lpad(' ', 16))
            or
                '\\cs(255,255,0)' .. ('Gil: ' .. comma_value(giles):lpad(' ', 16))) .. '\\cr'
        text_box:update(info)
        text_box:show()
    end
end)