askRoundsEvent = dmglog.AddNetworkString('AskRoundEvents')
sendRoundEvents = dmglog.AddNetworkString('SendRoundEvents')

if SERVER

    net.Receive askRoundsEvent, (length, ply) ->
        callbackId = net.ReadUInt(32)
        askedId = net.ReadUInt(32)
        roundEvents = dmglog.eventsHandler.roundEvents[askedId]
        if roundEvents
            net.Start(sendRoundEvents)
            net.WriteUInt(callbackId, 32)
            roundEvents\Send!
            net.Send(ply)

if CLIENT

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
        roundEvents = dmglog.RoundEvents.Read!
        callback = callbacks[callbackId]
        if callback
            callback(roundEvents)
            callbacks[callbackId] = nil

    if dmglog.DebugMode

        concommand.Add 'dmglog_askroundEvents', (ply, cmd, args) ->
            dmglog.AskRoundEvents (args[0] and tonumber(args[0]) or dmglog.roundsCount), (roundEvents) ->
                PrintTable(roundEvents)