class dmglog.RoundEvents

    new: (eventsList = false, roundPlayers = false) =>
        @currentTime = 0
        @eventsList = eventsList or {}
        @roundPlayers = roundPlayers or dmglog.RoundPlayers()

    AddEvent: (event) =>
        table.insert(@eventsList, event)

    Send: () =>
        @roundPlayers\Send!
        net.WriteUInt(#@eventsList, 32)
        for event in *@eventsList
            net.WriteUInt(event.__class.id, 16)
            event\Send! 

    @Read: () ->
        roundPlayers = dmglog.RoundPlayers.Read!
        eventsList = {}
        for i = 1, net.ReadUInt(32)
            id = net.ReadUInt(16)
            event = dmglog.events[id]
            table.insert(eventsList, event.__class.Read())
        return dmglog.RoundEvents(eventsList, roundPlayers)