class DamageEvent extends dmglog.Event

    new: (attackerId, targetId, damages) =>
        @attackerId = attackerId
        @targetId = targetId
        @damages = math.Round(damages)

    ToString: (roundPlayers) =>
        attackerInformation = roundPlayers\GetById(@attackerId)
        targetInformation = roundPlayers\GetById(@targetId)
        return dmglog.GetTranslation('damage_event', {
            attacker: attackerInformation.name
            target: targetInformation.name
            damages: @damages
        })

    Send: () =>
        net.WriteUInt(@attackerId, 16)
        net.WriteUInt(@targetId, 16)
        net.WriteUInt(@damages, 16)

    @Read: () ->
        attackerId = net.ReadUInt(16)
        targetId = net.ReadUInt(16)
        damages = net.ReadUInt(16)
        return DamageEvent(attackerId, targetId, damages)

dmglog.RegisterEvent(DamageEvent)

if SERVER

    hook.Add 'EntityTakeDamage', 'TTTDamagelogs_DamageEvent', (target, dmginfo) -> 
        if not target\IsPlayer! return
        attacker = dmginfo\GetAttacker!
        if attacker == target or not target\IsPlayer! return
        damageEvent = DamageEvent(attacker\GetDamagelogId!, target\GetDamagelogId!, dmginfo\GetDamage!)
        dmglog.CallEvent(damageEvent)

    if dmglog.DebugMode

        concommand.Add 'dmglog_debugdamage', (ply, cmd, args) ->
            dmglog.GetDebugBot (debugBot) ->
                damages = args[0] and tonumber(args[0]) or 20
                damageEvent = DamageEvent(debugBot\GetDamagelogId(), ply\GetDamagelogId(), damages)
                dmglog.CallEvent(damageEvent) 