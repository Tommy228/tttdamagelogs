GetNetworkString = (name) -> 'dmglog_' .. name

if SERVER

    dmglog.net = 

        AddNetworkString: (name) ->
            networkString = GetNetworkString(name)
            util.AddNetworkString(networkString)
            return networkString

        WriteSteamId: do 
            steamIdInformationStart = #'STEAM_' + 1
            (steamId) ->
                if steamId == 'BOT'
                    net.WriteBit(1)
                else
                    net.WriteBit(0)
                    steamIdInformation = string.sub(steamId, steamIdInformationStart)
                    {universe, id, accountNumber} = string.Explode(':', steamIdInformation)
                    net.WriteUInt(tonumber(universe), 3)
                    net.WriteBit(id == '1')
                    net.WriteUInt(tonumber(accountNumber), 32)

if CLIENT

    dmglog.net = 

        AddNetworkString: (name) -> GetNetworkString(name)

        ReadSteamId: () ->
            isBot = net.ReadBit! == 1
            if isBot
                return 'BOT'
            else
                universe = net.ReadUInt(3)
                id = net.ReadBit!
                accountNumber = net.ReadUInt(32)
                return "STEAM_#{universe}:#{id}:#{accountNumber}"