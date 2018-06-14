 class dmglog.EventsHandler

    new: () =>
        @roundEvents = {}

    NewRound: () =>
        roundEvents = dmglog.RoundEvents!
        print('roundplayers', roundEvents.roundPlayers)
        roundEvents.roundPlayers\InitializeWithCurrentPlayers()
        table.insert(@roundEvents, roundEvents)

    GetCurrentRound: () =>
        @roundEvents[#@roundEvents]


dmglog.eventsHandler = dmglog.EventsHandler!

OnNewRound = () ->
    dmglog.eventsHandler\NewRound!

hook.Add('TTTBeginRound', 'TTTDamagelogs_EventsHandler', OnNewRound)