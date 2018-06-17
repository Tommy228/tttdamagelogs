PreparationStartEvent = do dmglog.RegisterEvent class extends dmglog.Event

    new: (mapName = game.GetMap!) =>
        @roundTime = 0
        @mapName = mapName
        @SetDisplayedTypeKey('preparation_start_event_type')

    ToString: (roundPlayers) =>
        return dmglog.GetTranslation('preparation_start_event', {mapName: @mapName})

    Send: () =>
        net.WriteString(@mapName)
    
    @Read: () =>
        mapName = net.ReadString!
        return PreparationStartEvent(mapName)

    @AddServerHook 'TTTDamagelogsRoundCreated', (roundEvents) ->
        dmglog.CallEvent(PreparationStartEvent!)