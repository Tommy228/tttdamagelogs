class DamageEvent extends dmglog.Event

    new: () =>
        super({
            'attacker',
            'victim',
            'damages'
        })

onEntityDamage = (target, dmginfo) ->
    damageEvent = DamageEvent()
    damageEvent\SetAttacker(1)

hook.Add('EntityTakeDamage', 'TTTDamagelogs_DamageEvent', onEntityDamage)
    