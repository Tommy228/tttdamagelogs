class DamageEvent extends dmglog.Event

    new: (attackerId, targetId, damages) =>
        @attackerId = attackerId
        @targetId = targetId
        @damages = math.Round(damages)

    Send: () =>
        net.WriteUInt(@attackerId, 16)
        net.WriteUInt(@targetId, 16)
        net.WriteUInt(@damages, 16)

    ToString: (roundPlayers) =>
        attackerInformation = roundPlayers\GetById(@attackerId)
        targetInformation = roundPayers\GetById(@targetId)
        dmglog.Translate(damageEvent, {
            attacker: attackerInformation.name
            target: targetInformation.name
            damages: @damages
        })

    @Read: () ->
        attackerId = net.ReadUInt(16)
        targetId = net.ReadUInt(16)
        damages = net.ReadUInt(16)
        DamageEvent(attackerId, targetId, damages)

dmglog.RegisterEvent(DamageEvent)

if SERVER

    hook.Add 'EntityTakeDamage', 'TTTDamagelogs_DamageEvent', (target, dmginfo) -> 
        if not target\IsPlayer() return
        attacker = dmginfo\GetAttacker()
        if attacker == target return
        damageEvent = DamageEvent(attacker\GetDamagelogId(), target\GetDamagelogId(), dmginfo\GetDamage())
        dmglog.CallEvent(damageEvent)

    if dmglog.DebugMode

        concommand.Add 'dmglog_debugdamage', (ply, cmd, args) ->
            dmglog.GetDebugBot (debugBot) ->
                damages = args[0] and tonumber(args[0]) or 20
                damageEvent = DamageEvent(debugBot\GetDamagelogId(), ply\GetDamagelogId(), damages)
                dmglog.CallEvent(damageEvent) 