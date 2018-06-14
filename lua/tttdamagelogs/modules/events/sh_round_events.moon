class dmglog.RoundEvents

    @roundPlayers: {}

    @eventsList: {}

    @InitializeWithCurrentPlayers: () =>
        table.Empty(@roundPlayers)
        for ply in *player.GetAll()
            roundPlayer = dmglog.EventPlayer(ply\Name(), ply\SteamID64())
            id = table.insert(@roundPlayers, roundPlayer)
            roundPlayer\SetId(id)

    @GetRoundPlayer: (id) =>
        @roundPlayers[id]

    @AddEvent: (event) =>
        table.insert(@eventsList, event)