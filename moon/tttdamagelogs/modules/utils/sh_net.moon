dmglog.net = 

    AddNetworkString: (name) ->
        networkString = 'dmglog_' .. name
        util.AddNetworkString(networkString) if SERVER
        return networkString

    WriteSteamId: do 
        steamIdInformationStart = #'STEAM_' + 1
        (steamId) ->
            if steamId == 'BOT'
                net.WriteBool(true)
            else
                net.WriteBool(false)
                steamIdInformation = string.sub(steamId, steamIdInformationStart)
                {universe, id, accountNumber} = string.Explode(':', steamIdInformation)
                net.WriteUInt(tonumber(universe), 3)
                net.WriteBit(id == '1')
                net.WriteUInt(tonumber(accountNumber), 32)

    ReadSteamId: () ->
        isBot = net.ReadBool!
        if isBot
            return 'BOT'
        else
            universe = net.ReadUInt(3)
            id = net.ReadBit!
            accountNumber = net.ReadUInt(32)
            return "STEAM_#{universe}:#{id}:#{accountNumber}"