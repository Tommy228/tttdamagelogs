hook.Add 'TTTDamagelogsMenuOpen', 'TTTDamagelogs_DamageTab', (tabs) ->
    with damageTab = vgui.Create('DListLayout')
        \Add('DamagelogSelectionPanel')
        with \Add('DamagelogListView')
            \SetHeight(415)
        tabs\AddSheet(dmglog.GetTranslation('damagelog_tab_title'), damageTab, 'icon16/application_view_detail.png')