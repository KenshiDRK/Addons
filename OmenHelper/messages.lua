
function get_messages(id, param0, param1, param2, param3)
    local Miniboss = {[0] = "Thinker", [1] = "Craver", [2] = "Gorger"}
    local Boss = {[0] = "Kin", [1] = "Gin", [2] = "Kei", [3] = "Kyou", [4] = "Fu", [5] = "Ou"}
    messages = {
        [7316] = 'Kill all Transcended foes',
        [7317] = 'Kill '..param0..' Sweetwater foe'..(param0 > 1 and 's' or '')..': ',
        [7318] = 'Kill 1 specific foe',
        [7319] = 'Kill all foes',
        [7320] = '\\cs(0,255,0)Free floor!\\cr',
        [7321] = param0 <= 2 and 'Kill Glassy '..Miniboss[param0] or '',
        [7322] = param0 <= 5 and 'Kill '..Boss[param0] or '',
        [7323] = 'Open '..param0..' Treasure Portent'..(param0 > 1 and 's' or ''),
        [7324] = '\\cs(0,255,0)Completed!\\cr',
        [7331] = param0..': '..param1..' skillchain'..(param1 > 1 and 's' or '')..' ('..(param1 + 1)..' Steps): ',
        [7332] = param0..': '..param1..' Critical Hits: ',
        [7333] = param0..': Kill '..param1..' foe'..(param1 > 1 and 's' or '')..': ',
        [7334] = param0..': '..param1..' Spells on foes: ',
        [7335] = param0..': '..param1..' abilities on foes: ',
        [7336] = param0..': '..param1..' physical WSs: ',
        [7337] = param0..': '..param1..' elemental WSs: ',
        [7338] = param0..': '..param1..' Weapon Skills: ',
        [7339] = param0..': '..param1..' MB on foes: ',
        [7340] = param0..': 2000+ dmg on Attack Round: ',
        [7341] = param0..': 2000+ dmg on Attack Round: ',
        [7342] = param0..': 30000+ Weapon Skill dmg: ',
        [7343] = param0..': 30000+ Weapon Skill dmg: ',
        [7344] = param0..': 15000+ Mdmg no MB: ',
        [7345] = param0..': 15000+ Mdmg no MB: ',
        [7346] = param0..': 30000+ MB dmg: ',
        [7347] = param0..': 30000+ MB dmg: ',
        [7348] = param0..': 10 500+ Heals: ',
    }
    return messages[id]
end