dmglog.INVALID_ROUNDPLAYER_ID = -1

class dmglog.RoundPlayer

    new: (name, steamId64) =>
        @name = name
        @steamId64 = steamId64
    
    SetId: (id) =>
        @id = id

dmglog.CreateRoundPlayer = (ply) ->
    dmglog.RoundPlayer(ply\Name(), ply\SteamID64())