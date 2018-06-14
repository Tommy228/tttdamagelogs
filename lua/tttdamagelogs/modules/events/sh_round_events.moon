class dmglog.RoundEvents

    new: () =>
        @eventsList = {}
        @roundPlayers = dmglog.RoundPlayers()

    AddEvent: (event) =>
        table.insert(@eventsList, event)