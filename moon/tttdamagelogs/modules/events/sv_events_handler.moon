 class dmglog.EventsHandler

    new: () =>
        @roundEvents = {}

    NewRound: () =>
        roundEvents = dmglog.RoundEvents!
        roundEvents.roundPlayers\InitializeWithCurrentPlayers()
        table.insert(@roundEvents, roundEvents)
        return roundEvents

    GetRoundsCount: () => #@roundEvents

    GetCurrentRound: () => @roundEvents[@GetRoundsCount!]


dmglog.eventsHandler = dmglog.EventsHandler!

hook.Add 'TTTBeginRound', 'TTTDamagelogs_EventsHandlerNewRound', () ->
    roundEvents = dmglog.eventsHandler\NewRound!
    hook.Run('TTTDamagelogsRoundCreated', roundEvents)

hook.Add 'OnEntityCreated', 'TTTDamagelogs_EventsHandlerAddPlayer', (ent) ->
    if ent\IsPlayer!
        currentRound = dmglog.eventsHandler\GetCurrentRound!
        if currentRound
            currentRound.roundPlayers\AddPlayer(ent)

timer.Create 'TTTDamagelogs_EventsHandlerRoundTimer', 1, 0, () ->
    currentRound = dmglog.eventsHandler\GetCurrentRound!
    if currentRound
        currentRound.currentTime += 1

Player = FindMetaTable('Player')
Player.GetDamagelogId = (round = dmglog.eventsHandler\GetCurrentRound()) =>
    return round.roundPlayers\GetPlayerId(self) if round else dmglog.INVALID_ROUNDPLAYER_ID