dmglog.INVALID_ROUNDPLAYER_ID = -1

class dmglog.RoundPlayer

    new: (name, steamId, role = ROLE_INNOCENT) =>
        @name = name
        @steamId = steamId
        @role = role
    
    SetId: (id) =>
        @id = id

    Send: () =>
        net.WriteString(@name)
        dmglog.net.WriteSteamId(@steamId)
        net.WriteUInt(@role, 3)

    @Read: () ->
        name = net.ReadString!
        steamId = dmglog.net.ReadSteamId!
        role = net.ReadUInt(3)
        return dmglog.RoundPlayer(name, steamId, role)

    @Create: (ply) ->
        return dmglog.RoundPlayer(ply\Name!, ply\SteamID!, ply\GetRole!)