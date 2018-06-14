class dmglog.RoundPlayers

    new: () =>
        @list = {}

    InitializeWithCurrentPlayers: () =>
        table.Empty(@list)
        for ply in *player.GetAll()
            @AddPlayer(ply)

    AddPlayer: (ply) =>
        roundPlayer = dmglog.RoundPlayer(ply\Name(), ply\SteamID64())
        id = table.insert(@list, roundPlayer)
        roundPlayer\SetId(id)

    GetById: (id) =>
        @roundPlayers[id]