askRoundsEvent = dmglog.AddNetworkString('AskRoundEvents')
sendRoundEvents = dmglog.AddNetworkString('SendRoundEvents')

if SERVER

    WriteEventsList = (eventsList) ->
        net.WriteUInt(#eventsList, 32)
        for event in *eventsList
            net.WriteUInt(event.__class.id, 16)
            event\Send!

    WriteRoundPlayers = (roundPlayersList) ->
        net.WriteUInt(#roundPlayersList, 16)
        for roundPlayer in *roundPlayersList
            net.WriteString(roundPlayer.name)
            net.WriteUInt(roundPlayer.steamId64, 32)

    SendRoundEvents = (ply, callbackId, roundEvents) ->
        net.Start(sendRoundEvents)
        net.WriteUInt(callbackId, 32)
        do
            WriteEventsList(roundEvents.eventsList)
            WriteRoundPlayers(roundEvents.roundPlayers.list)
        net.Send(ply)

    net.Receive askRoundsEvent, (length, ply) ->
        callbackId = net.ReadUInt(32)
        askedId = net.ReadUInt(32)
        roundEvents = dmglog.eventsHandler.roundEvents[askedId]
        if roundEvents
            SendRoundEvents(ply, callbackId, roundEvents)

if CLIENT

    ReadEventsList = () ->
        events = {}
        length = net.ReadUInt(32)
        for i = 1, length
            id = net.ReadUInt(16)
            event = dmglog.Events[id]
            table.insert(events, event.__class.Read())
        return events

    ReadRoundPlayers = () ->
        roundPlayersList = {}
        length = net.ReadUInt(16)
        print(length)
        for i = 1, length
            name = net.ReadString()
            steamId64 = net.ReadUInt(32)
            roundPlayer = dmglog.RoundPlayer(name, steamId64)
            print(name, steamId64)
            table.insert(roundPlayersList, roundPlayer)
        return dmglog.RoundPlayers(roundPlayersList)

    callbacks = {}

    dmglog.AskRoundEvents = do
        callbackId = 0
        (round, callback) ->
            callbackId += 1
            callbacks[callbackId] = callback
            net.Start(askRoundsEvent)
            net.WriteUInt(callbackId, 32)
            net.WriteUInt(round, 32)
            net.SendToServer!

    net.Receive sendRoundEvents, (length) ->
        callbackId = net.ReadUInt(32)
        eventsList = ReadEventsList!
        roundPlayers = ReadRoundPlayers!
        roundEvents = dmglog.RoundEvents(eventsList, roundPlayers)
        callback = callbacks[callbackId]
        if callback
            callback(roundEvents)
            callbacks[callbackId] = nil

    if dmglog.DebugMode

        concommand.Add 'dmglog_askroundEvents', (ply, cmd, args) ->
            dmglog.AskRoundEvents (args[0] and tonumber(args[0]) or 1), (roundEvents) ->
                PrintTable(roundEvents)