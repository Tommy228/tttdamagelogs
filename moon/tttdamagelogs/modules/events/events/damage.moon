DamageEvent = do dmglog.RegisterEvent class extends dmglog.Event

    new: (attackerId, targetId, damages, roundTime = false) =>
        super(roundTime)
        @SetDisplayedTypeKey('damage_event_type')
        @attackerId = attackerId
        @targetId = targetId
        @damages = damages

    ToString: (roundPlayers) =>
        attackerInformation = roundPlayers\GetById(@attackerId)
        targetInformation = roundPlayers\GetById(@targetId)
        return dmglog.GetTranslation('damage_event', {
            attacker: attackerInformation.name
            attackerRole: @GetRoleString(attackerInformation.role)
            target: targetInformation.name
            targetRole: @GetRoleString(targetInformation.role)
            damages: @damages
        })

    Send: () =>
        net.WriteUInt(@roundTime, 32)
        net.WriteUInt(@attackerId, 16)
        net.WriteUInt(@targetId, 16)
        net.WriteUInt(@damages, 16)

    @Read: () ->
        roundTime = net.ReadUInt(32)
        attackerId = net.ReadUInt(16)
        targetId = net.ReadUInt(16)
        damages = net.ReadUInt(16)
        return DamageEvent(attackerId, targetId, damages, roundTime)

    @AddServerHook 'EntityTakeDamage', (target, dmginfo) ->
        if not target\IsPlayer! return
        attacker = dmginfo\GetAttacker!
        if attacker == target or not attacker\IsPlayer! return
        do
            attackerId = attacker\GetDamagelogId!
            targetId = target\GetDamagelogId!
            damages = math.Round(dmginfo\GetDamage!)
            damageEvent = DamageEvent(attackerId, targetId, damages)
            dmglog.CallEvent(damageEvent)

if SERVER and dmglog.DebugMode

    concommand.Add 'dmglog_debugdamage', (ply, cmd, args) ->
        dmglog.GetDebugBot (debugBot) ->
            damages = args[0] and tonumber(args[0]) or 20
            damageEvent = DamageEvent(debugBot\GetDamagelogId(), ply\GetDamagelogId(), math.Round(damages))
            dmglog.CallEvent(damageEvent) 