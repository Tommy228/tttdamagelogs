class DamageEvent extends dmglog.Event

    new: (attacker, target, damages) =>
        @attacker = attacker
        @target = target
        @damages = damages


if SERVER

    onEntityDamage = (target, dmginfo) ->
        if not target\IsPlayer() return
        attacker = dmginfo\GetAttacker()
        if attacker == target return
        damageEvent = DamageEvent(attacker, target, dmginfo\GetDamage())
        dmglog.eventsHandler\GetCurrentRound!\AddEvent(damageEvent) 

    hook.Add('EntityTakeDamage', 'TTTDamagelogs_DamageEvent', onEntityDamage)