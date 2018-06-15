class dmglog.RoundEvents

    new: () =>
        @currentTime = 0
        @eventsList = {}
        @roundPlayers = dmglog.RoundPlayers()

    AddEvent: (event) =>
        table.insert(@eventsList, event)