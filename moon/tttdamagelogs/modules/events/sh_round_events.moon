class dmglog.RoundEvents

    new: (eventsList = false, roundPlayers = false) =>
        @currentTime = 0
        @eventsList = eventsList or {}
        @roundPlayers = roundPlayers or dmglog.RoundPlayers()

    AddEvent: (event) =>
        table.insert(@eventsList, event)