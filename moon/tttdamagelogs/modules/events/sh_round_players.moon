class dmglog.RoundPlayers

    new: (list = false) =>
        @list = list or {}

    InitializeWithCurrentPlayers: () =>
        table.Empty(@list)
        for ply in *player.GetAll!
            @AddPlayer(ply)

    AddPlayer: (ply) =>
        roundPlayer = dmglog.RoundPlayer.Create(ply)
        id = table.insert(@list, roundPlayer)
        roundPlayer\SetId(id)

    GetPlayerId: (ply) =>
        steamId = ply\SteamID!
        return dmglog.table.FindKey(@list, (roundPlayer) -> roundPlayer.steamId == steamId) or false

    GetById: (id) => @list[id]

    Send: () =>
        net.WriteUInt(#@list, 16)
        for roundPlayer in *@list
            roundPlayer\Send!

    @Read: () ->
        list = {}
        for i = 1, net.ReadUInt(16)
            roundPlayer = dmglog.RoundPlayer.Read!
            table.insert(list, roundPlayer)
        return dmglog.RoundPlayers(list)