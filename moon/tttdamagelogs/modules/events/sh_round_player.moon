dmglog.INVALID_ROUNDPLAYER_ID = -1

class dmglog.RoundPlayer

    new: (name, steamId64, role = ROLE_INNOCENT) =>
        @name = name
        @steamId64 = steamId64
        @role = role
    
    SetId: (id) =>
        @id = id

    Send: () =>
        net.WriteString(@name)
        net.WriteString(@steamId64)
        net.WriteUInt(@role, 3)

    @Read: () ->
        name = net.ReadString!
        steamId64 = net.ReadString!
        role = net.ReadUInt(3)
        return dmglog.RoundPlayer(name, steamId64, role)

    @Create: (ply) ->
        return dmglog.RoundPlayer(ply\Name!, ply\SteamID64!, ply\GetRole!)