dmglog.INVALID_ROUNDPLAYER_ID = -1

class dmglog.RoundPlayer

    new: (name, steamId, onlyPlayedPreparation = false, role = ROLE_INNOCENT) =>
        @name = name
        @steamId = steamId
        @role = role
        @onlyPlayedPreparation = onlyPlayedPreparation
    
    SetId: (id) =>
        @id = id

    Send: () =>
        net.WriteString(@name)
        dmglog.net.WriteSteamId(@steamId)
        net.WriteBool(@onlyPlayedPreparation)
        net.WriteUInt(@role, 3)

    @Read: () ->
        name = net.ReadString!
        steamId = dmglog.net.ReadSteamId!
        onlyPlayedPreparation = net.ReadBool!
        role = net.ReadUInt(3)
        return dmglog.RoundPlayer(name, steamId, onlyPlayedPreparation, role)

    @Create: (ply) ->
        return dmglog.RoundPlayer(ply\Name!, ply\SteamID!, ply\GetRole!)