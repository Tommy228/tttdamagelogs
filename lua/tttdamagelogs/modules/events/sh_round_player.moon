class dmglog.RoundPlayer

    new: (name, steamId64) =>
        @name = name
        @steamId64 = steamId64
    
    SetId: (id) =>
        @id = id