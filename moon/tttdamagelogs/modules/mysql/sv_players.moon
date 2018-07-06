hook.Add 'PlayerAuthed', 'TTTDamagelogsMySQLPlayers', (ply, steamId, uniqueId) ->
    name = ply\Name!
    with query = dmglog.db\prepare('CALL on_player_join(?, ?)')
        \setString(1, steamId)
        \setString(2, name)
        \start!
