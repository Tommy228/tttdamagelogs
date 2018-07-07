hook.Add 'PlayerAuthed', 'TTTDamagelogsMySQLPlayers', (ply, steamId, uniqueId) ->
    name = ply\Name!
    ply.dmglogJoinName = name
    with query = dmglog.db\prepare('CALL on_player_join(?, ?)')
        \setString(1, steamId)
        \setString(2, name)
        \start!

hook.Add 'TTTDamagelogsPlayerNameChanged', 'TTTDamagelogsChangeMySQLName', (ply) ->
    name = ply\Name!
    ply.dmglogJoinName = name
    steamId = ply\SteamID!
    with query = dmglog.db\prepare('UPDATE damagelogs_players SET name = ? WHERE steamid = ?;')
        \setString(1, name)
        \setString(2, steamId)
        \start!


hook.Add 'Think', 'TTTDamagelogsPlayerNameCheck', ->
    for k, ply in ipairs(player.GetHumans!)
        if ply.dmglogJoinName and ply\Name! != ply.dmglogJoinName
            ply.dmglogJoinName = ply\Name!
            hook.Run('TTTDamagelogsPlayerNameChanged', ply)