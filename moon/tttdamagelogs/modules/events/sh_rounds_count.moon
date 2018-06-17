roundsCountNetworkMessage = dmglog.net.AddNetworkString('roundsCount')

if SERVER

    SendRoundsCount = (ply) ->
        net.Start(roundsCountNetworkMessage)
        net.WriteUInt(dmglog.eventsHandler\GetRoundsCount!, 32)
        net.Send(ply)

    hook.Add 'PlayerAuthed', 'TTTDamagelogs_SendRoundsCount', (ply, steamId, uniqueId) ->
        SendRoundsCount(ply)

    hook.Add 'TTTDamagelogsRoundCreated', 'TTTDamagelogs_SendRoundsCount', () ->
        for ply in *player.GetAll!
            SendRoundsCount(ply)

if CLIENT

    dmglog.roundsCount = dmglog.roundsCount or 0

    net.Receive roundsCountNetworkMessage, (length) ->
        updatedRoundsCount = net.ReadUInt(32)
        if updatedRoundsCount != dmglog.roundsCount
            dmglog.roundsCount = updatedRoundsCount
            hook.Run('TTTDamagelogsRoundsCountChanged', dmglog.roundsCount)