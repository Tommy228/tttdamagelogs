
dmglog.CreateDamageTab = (using nil) ->
    dmglog.DamageTab = vgui.Create('DListLayout')

    dmglog.Tabs\AddSheet('Damagelog', dmglog.DamageTab, 'icon16/application_view_detail.png')

hook.Add('TTTDamagelogsMenuOpen', 'TTTDamagelogs_DamageTab', dmglog.CreateDamageTab)