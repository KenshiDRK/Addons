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

require('luau')
require('pack')
packets = require('packets')

_addon.name = 'Flags'
_addon.author = 'Kenshi'
_addon.commands = {'flags', 'fg'}
_addon.version = '1.0'

-- Settings
defaults = {}
defaults.Flag = 'off'

settings = config.load(defaults)

local flags = {['pol']=0x60, ['gm']=0x80, ['sgm']=0xA0, ['lgm']=0xC0, ['pro']=0xE0}
local names = S{'pol', 'gm', 'sgm', 'lgm', 'pro'}
local useFlags = settings.Flag

-- Update request to apply flags on addon load, unload
windower.register_event('load', 'unload', function()
    if names:contains(useFlags) then
        update_flag()
    end
end)

function update_flag()
    local player = windower.ffxi.get_player()
    if windower.ffxi.get_info().logged_in then
        packets.inject(packets.new('outgoing', 0x016, {['Target Index'] = player.index}))
    end
end
       
-- Packet modification
windower.register_event('incoming chunk', function(id, data)
    if id == 0x037 then
		local parsed = packets.parse('incoming', data)
		local player = windower.ffxi.get_player()
		if names:contains(useFlags) and parsed.Player == player.id then
            local flags2 =  flags[useFlags] + parsed._flags2
			parsed._flags2 = flags2
			local rebuilt = packets.build(parsed)
			return rebuilt
		end
	end
    
    if id == 0x00D then
        local gm_flags2 = {['pol']=3, ['gm']=4, ['sgm']=5, ['lgm']=6, ['pro']=7}
        
        local player = windower.ffxi.get_player()
        local packet = packets.parse('incoming', data)
        
        if names:contains(useFlags) and packet.Player == player.id then
            local flags2 = data:unpack('b8', 36)
            local new_flags = flags2 + gm_flags2[useFlags]
            return data:sub(1, 35) .. 'b8':pack(new_flags) .. data:sub(37)
        end
    end
end)

windower.register_event('addon command', function(command)
    local command = command and command:lower() or nil
    local Flag_names = {["gm"] = "Support GM", ["sgm"] = "Senior GM", ["lgm"] = "Lead GM", ["pro"] = "Producer", ["pol"] = "Pol Icon"}
    
    if names:contains(command) then
        if command == useFlags then
            log(Flag_names[useFlags]..' already on.')
        else
            useFlags = command
            settings.Flag = command
            config.save(settings)
            log(Flag_names[useFlags]..' on.')
            -- Request update after the command
            update_flag()
        end
    elseif command == 'off' then
        useFlags = command
        settings.Flag = command
        config.save(settings)
        log('Flags off.')
        -- Request update after the command
        update_flag()
    elseif command == 'help' then
        log('commands:')
        log('/flags|fg gm|sgm|lgm|pro|pol|off|help.')
    else
        log('invalid command, use //fg help')
    end
end)
