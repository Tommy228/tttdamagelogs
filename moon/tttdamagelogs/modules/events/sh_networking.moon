askRoundsEvent = dmglog.AddNetworkString('AskRoundEvents')
sendRoundEvents = dmglog.AddNetworkString('SendRoundEvents')

if SERVER

    SendRoundEvents = (ply, roundEvents) ->
        eventsList = roundEvents.eventsList
        net.Start(sendRoundEvents)
        do
            net.WriteUInt(#eventsList, 32)
            for event in *eventsList
                net.WriteUInt(event.__class.id, 16)
                event\Send!
        net.Send(ply)

    net.Receive askRoundsEvent, (length, ply) ->
        askedId = net.ReadUInt(32)
        roundEvents = dmglog.eventsHandler.roundEvents[askedId]
        if roundEvents
            SendRoundEvents(ply, roundEvents)

if CLIENT

    net.Receive sendRoundEvents, (length) ->
        events = {}
        length = net.ReadUInt(32)
        for i = 1, length
            id = net.ReadUInt(16)
            event = dmglog.Events[id]
            table.insert(events, event.__class.Read())
        PrintTable(events)

    if dmglog.DebugMode

        concommand.Add 'dmglog_askroundEvents', (ply, cmd, args) ->
            net.Start(askRoundsEvent)
            net.WriteUInt(args[0] and tonumber(args[0]) or 1, 32)
            net.SendToServer!