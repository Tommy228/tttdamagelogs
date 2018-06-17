dmglog.DebugMode = true

if dmglog.DebugMode

    dmglog.GetDebugBot = (callback) ->
        findBot = () -> dmglog.table.Find(player\GetAll!, (p) -> p\IsBot!)
        bot = findBot!
        if not bot
            RunConsoleCommand('bot')
            timerName = 'dmglog_debugBot'
            if timer.Exists(timerName)
                timer.Remove(timerName)
            timer.Create timerName, 0.5, 1, () ->
                bot = findBot!
                if not bot
                    MsgN('[Damagelog] Error spawning the debug bot !')
                else
                    callback(bot)
        else
            callback(bot)

    if SERVER

        hook.Add 'PlayerInitialSpawn', 'TTTDamagelogs_DebugBot', () ->
            RunConsoleCommand('bot')
            hook.Remove('PlayerInitialSpawn', 'TTTDamagelogs_DebugBot')

        hook.Add 'PlayerSpawn', 'TTTDamagelogs_DebugWeapons', (ply) ->
            ply\Give('weapon_zm_sledge')