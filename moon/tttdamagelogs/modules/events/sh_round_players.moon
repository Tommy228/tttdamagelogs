class dmglog.RoundPlayers

    new: () =>
        @list = {}

    InitializeWithCurrentPlayers: () =>
        table.Empty(@list)
        for ply in *player.GetAll!
            @AddPlayer(ply)

    AddPlayer: (ply) =>
        roundPlayer = dmglog.CreateRoundPlayer(ply)
        id = table.insert(@list, roundPlayer)
        roundPlayer\SetId(id)

    GetPlayerId: (ply) =>
        steamId64 = ply\SteamID64!
        return dmglog.table.FindKey(@list, (roundPlayer) -> roundPlayer.steamId64 == steamId64) or false

    GetById: (id) => @list[id]