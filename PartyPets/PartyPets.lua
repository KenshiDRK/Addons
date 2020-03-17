_addon.name = 'PartyPets'
_addon.author = 'Kenshi'
_addon.version = '1.0'

require('luau')
texts = require('texts')
packets = require('packets')
require('tables')

defaults = {}
defaults.pos = {}
defaults.pos.x = 0
defaults.pos.y = 0
defaults.bg = {}
defaults.bg.red = 0
defaults.bg.green = 0
defaults.bg.blue = 0
defaults.bg.alpha = 102
defaults.bg.visible = false
defaults.text = {}
defaults.text.font = 'Consolas'
defaults.text.red = 255
defaults.text.green = 255
defaults.text.blue = 255
defaults.text.alpha = 255
defaults.text.size = 10
defaults.text.stroke = {}
defaults.text.stroke.width = 2
defaults.text.stroke.alpha = 255
defaults.text.stroke.red = 0
defaults.text.stroke.green = 0
defaults.text.stroke.blue = 0

settings = config.load(defaults)
box = texts.new('${current_string}', settings)
box:show()

local pets = T{}
local member_table = T{}
local pet_table = T{}
local player_name
local player_id

local function hp_col(hpp)
    local hp_col
    if hpp > 75 then
        hp_col = '\\cr\\cs(128,255,128)'
    elseif hpp > 50 then
        hp_col = '\\cr\\cs(255,255,0)'
    elseif hpp > 25 then
        hp_col = '\\cr\\cs(255,160,0)'
    elseif hpp == 0 then
        hp_col = '\\cr\\cs(169,169,169)'
    else
        hp_col = '\\cr\\cs(255,0,0)'
    end
    return hp_col
end

local function line_col(member, player)
    local line_col = member == player and '\\cr\\cs(150,255,255)' or ''
    return line_col
end

local function TP_col(name, index, tp, line_col)
    local TP = tp >= 1000 and ' [\\cr\\cs(128,255,128)'..tp..'\\cr'..line_col..']' or ' ['..tp..']'
    local TP_col = name ~= 'Luopan' and player_name == pet_table[index].O_Name and TP or ''
    return TP_col
end

local function pet_dist(index)
    local pet = windower.ffxi.get_mob_by_index(index)
    return pet and ' ['..string.format('%.2f', pet.distance:sqrt())..']' or ''
end

local function Update()
	local current_string = ''
    local party = windower.ffxi.get_party()
    local key_indices = {'p0','p1', 'p2', 'p3', 'p4', 'p5', 'a10', 'a11', 'a12', 'a13', 'a14', 'a15', 'a20', 'a21', 'a22', 'a23', 'a24', 'a25'}

    if zoning_bool then
        box:hide()
    end
    current_string = 'Party Pets:'
    for k = 1, 18 do
        local member = party[key_indices[k]]
        if member and pets and pets[member.name] and pets[member.name].Pet.Pet_Index and pets[member.name].Pet.Pet_Name then
            local line_c = line_col(member.name, player_name)
            local pet_name = pets[member.name].Pet.Pet_Name
            local owner_name = pets[member.name].Owner_Name
            local hpp = pets[member.name].Pet_HPP
            local tp = pets[member.name].Pet.Pet_TP
            local pet_index = pets[member.name].Pet.Pet_Index
            local hp_color = hp_col(hpp)
            local tp_color = TP_col(pet_name, pet_index, tp, line_c)
            current_string = current_string..'\n'..line_c..pet_name..' ['..owner_name..']:'
            if pets[member.name].Pet.Pet_Dead and hpp == 0 then
                current_string = current_string..' [\\cr\\cs(169,169,169)Dead\\cr'..line_c..']'
            elseif pets[member.name].Pet.Out_of_Range then
                current_string = current_string..' [\\cr\\cs(255,0,0)Out of Range\\cr'..line_c..']'
            elseif pets[member.name].Pet.Pet_is_Automaton then
                local m_hp = pets[member.name].Pet.m_hp
                local c_hp = hpp == 0 and 0 or pets[member.name].Pet.c_hp
                local c_mp = pets[member.name].Pet.c_mp
                local m_mp = pets[member.name].Pet.m_mp
                local mpp = c_mp * 100 / m_mp
                local mp_color = hp_col(mpp)
                current_string = current_string..' '..hp_color..c_hp..line_c..'/'..m_hp..' ['..hp_color..hpp..'%'..line_c..'] '..mp_color..c_mp..line_c..'/'..m_mp..tp_color..pet_dist(pet_index)
            else
                current_string = current_string..' ['..hp_color..hpp..'%\\cr'..line_c..']'..tp_color..pet_dist(pet_index)
            end
        end
        box:show()
    end
    if current_string == '' or current_string == 'Party Pets:' then
        box:hide()
    end
	box.current_string = current_string
end

local function create_members_table()
    if not windower.ffxi.get_info().logged_in then return end
    local party = windower.ffxi.get_party()
    local key_indices = {'p0','p1', 'p2', 'p3', 'p4', 'p5', 'a10', 'a11', 'a12', 'a13', 'a14', 'a15', 'a20', 'a21', 'a22', 'a23', 'a24', 'a25'}
    player_name = windower.ffxi.get_mob_by_target('me').name
    
    for k = 1, 18 do
        local member = party[key_indices[k]]
        
        if member and member.mob then
            local member_pet = member.mob.pet_index and windower.ffxi.get_mob_by_index(member.mob.pet_index) or nil
            if not member.mob.is_npc and not member_table:contains(member.mob.index) then
                member_table:append(member.mob.index)
                member_table[member.mob.index] = {Member_Name = member.name}
                pets[member.name] = {Owner_Index = member.mob.index, Owner_Name = member.name, Pet_HPP = member_pet and member_pet.hpp or 100,
                Pet = {Pet_TP = 0}}
                if member_pet and not pet_table:contains(member_pet.index) then
                    pet_table:append(member_pet.index)
                    pet_table[member_pet.index] = {Owner_Index = member.mob.index, O_Name = member.name}
                    pets[member.name].Pet = {Pet_Name = member_pet.name, Pet_Index = member_pet.index,
                    Pet_TP = 0, Pet_Dead = false, Out_of_Range = false, Pet_is_Automaton = false}
                end
            end
        end
    end
    Update()
end

local function clear_table()
    local party = windower.ffxi.get_party()
    local key_indices = {'p0','p1', 'p2', 'p3', 'p4', 'p5', 'a10', 'a11', 'a12', 'a13', 'a14', 'a15', 'a20', 'a21', 'a22', 'a23', 'a24', 'a25'}
    local _player = windower.ffxi.get_mob_by_target('me')
    for k = 1, 18 do
        local member = party[key_indices[k]]
        if member and pets[member.name] then
            pets[member.name].Pet = {Pet_TP = 0}
        end
    end
    member_table = T{}
    pet_table = T{}
end

windower.register_event('load', 'login', function() --Create member table if addon is loaded while already in pt
    create_members_table()
end)

windower.register_event('incoming chunk', function(id, data)
    if id == 0x0DD then
        local packet = packets.parse('incoming', data)
        
        if not member_table:contains(packet['Index']) then
            member_table:append(packet['Index'])
            member_table[packet['Index']] = {Member_Name = packet['Name']}
            pets[packet['Name']] = {Owner_Index = packet['Index'], Owner_Name = packet['Name'], Pet_HPP = 100, Pet = {Pet_TP = 0}}
        end
    elseif id == 0x00E then
        local packet = packets.parse('incoming', data)
        if packet['Index'] < 1024 then return end
        if pet_table[packet['Index']] then
            local hp_update = string.sub(packet['Mask']:binary(),-3,-3)
            local name_update = string.sub(packet['Mask']:binary(),-4,-4)
            local despawn = string.sub(packet['Mask']:binary(),-6,-6)
            local owner = pet_table[packet['Index']].O_Name
            if despawn == '1' then
                local pet_owner = windower.ffxi.get_mob_by_index(pet_table[packet['Index']].Owner_Index)
                pets[owner].Pet.Pet_Dead = (pets[owner].Pet_HPP == 0 or (pet_owner and not pet_owner.pet_index)) and true
                pets[owner].Pet.Out_of_Range = pets[owner].Pet_HPP > 0 and true
                pets[owner].Pet_HPP = 0
            end
            if hp_update == '1' then
                pets[owner].Pet_HPP = packet['HP %']
                if packet['HP %'] > 0 then
                    pets[owner].Pet.Pet_Dead = false
                    pets[owner].Pet.Out_of_Range = false
                end
            end
            if name_update == '1' then
                pets[owner].Pet.Pet_Name = packet['Name']
            end
        end
    elseif id == 0x044 then
        local packet = packets.parse('incoming', data)
        if packet['Job'] ~= 18 or packet['Subjob'] then return end
        if not pets[player_name].Pet_HPP then return end
        pets[player_name].Pet.Pet_Name = packet['Pet Name']
        pets[player_name].Pet.Pet_is_Automaton = true
        pets[player_name].Pet.c_hp = pets[player_name].Pet_HPP == 0 and 0 or packet['Current HP']
        pets[player_name].Pet.m_hp = packet['Max HP']
        pets[player_name].Pet.c_mp = packet['Current MP']
        pets[player_name].Pet.m_mp = packet['Max MP']
    elseif id == 0x067 or id == 0x068 then
        local packet = packets.parse('incoming', data)
        if packet['Pet Index'] > 1024 and packet['Owner Index'] > 0 and member_table[packet['Owner Index']] then
            local Owner_Name = member_table[packet['Owner Index']].Member_Name
            if packet['Current HP%'] > 0 then
                pets[Owner_Name].Pet.Pet_Dead = false
                pets[Owner_Name].Pet.Out_of_Range = false
            end
            pets[Owner_Name].Pet.Pet_Index = packet['Pet Index']
            if not pet_table[packet['Pet Index']] then
                pet_table:append(packet['Pet Index'])
            end
            pet_table[packet['Pet Index']] = {Owner_Index = packet['Owner Index'], O_Name = Owner_Name}
            if player_name == Owner_Name and id == 0x068 then
                pets[Owner_Name].Pet.Pet_TP = packet['Pet TP']
                pets[Owner_Name].Pet_HPP = packet['Current HP%']
            end
        end
    elseif id == 0x0DF then
        local packet = packets.parse('incoming', data)
        if not member_table:contains(packet['Index']) then
            member_table:append(packet['Index'])
            member_table[packet['Index']] = {Member_Name = player_name}
        end
    elseif id == 0xB then
        zoning_bool = true
        clear_table()
    elseif id == 0xA and zoning_bool then
        zoning_bool = false
    end
end)

Update:loop(0.1)
