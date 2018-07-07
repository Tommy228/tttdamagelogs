
callbackFinishedNetworkString = dmglog.net.AddNetworkString('net_callback')

promises = {}

GetNextPromiseId = do
    promiseId = 1
    () ->
        if table.Count(promises) == 0
            promiseId = 1
        else
            promiseId += 1
        return promiseId

dmglog.net.SendAsync = (ply) ->
    return Promise (resolve, reject) ->
        promiseId = GetNextPromiseId!
        net.WriteUInt(promiseId, 16)
        if CLIENT
            net.SendToServer!
        else
            net.Send(ply)
        promises[promiseId] = {resolve, reject}

net.Receive callbackFinishedNetworkString, () ->
    promiseId = net.ReadUInt(16)
    {resolve, reject} = promises[promiseId]
    promises[promiseId] = nil
    resolve!

dmglog.net.ReceiveAsync = (name, callback) ->
    receiveFunc = (length, ply) ->
        responseFunc = callback(length, ply)
        promiseId = net.ReadUInt(16)
        if responseFunc
            net.Start(callbackFinishedNetworkString)
            net.WriteUInt(promiseId, 16)
            responseFunc!
            if CLIENT
                net.SendToServer!
            else
                net.Send(ply)
    net.Receive(name, receiveFunc)