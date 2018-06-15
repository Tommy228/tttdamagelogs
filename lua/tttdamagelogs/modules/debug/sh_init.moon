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

