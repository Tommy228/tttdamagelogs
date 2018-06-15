GetNetworkString = (name) -> 'dmglog' .. name

if SERVER

    dmglog.AddNetworkString = (name) ->
        networkString = GetNetworkString(name)
        util.AddNetworkString(networkString)
        return networkString

if CLIENT

    dmglog.AddNetworkString = (name) -> GetNetworkString(name)