askRoundsEvent = dmglog.net.AddNetworkString('AskRoundEvents')
sendRoundEvents = dmglog.net.AddNetworkString('SendRoundEvents')

if SERVER

    net.Receive askRoundsEvent, (length, ply) ->
        callbackId = net.ReadUInt(5)
        roundNumber = net.ReadUInt(8)
        roundEvents = dmglog.eventsHandler.roundEvents[roundNumber]
        if roundEvents
            net.Start(sendRoundEvents)
            net.WriteUInt(callbackId, 5)
            roundEvents\Send!
            net.Send(ply) 

if CLIENT

    callbacks = {}

    dmglog.AskRoundEvents = do
        callbackId = 0
        (roundNumber, callback) ->
            do
                if table.Count(callbacks) == 0
                    callbackId = 1
                else
                    callbackId += 1
                callbacks[callbackId] = callback
            do
                net.Start(askRoundsEvent)
                net.WriteUInt(callbackId, 5)
                net.WriteUInt(roundNumber, 8)
                net.SendToServer!

    net.Receive sendRoundEvents, (length) ->
        callbackId = net.ReadUInt(5)
        roundEvents = dmglog.RoundEvents.Read!
        callback = callbacks[callbackId]
        if callback
            callback(roundEvents)
            callbacks[callbackId] = nil

    if dmglog.DebugMode

        concommand.Add 'dmglog_askroundEvents', (ply, cmd, args) ->
            dmglog.AskRoundEvents (args[0] and tonumber(args[0]) or dmglog.roundsCount), (roundEvents) ->
                PrintTable(roundEvents)