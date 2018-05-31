
CreateDamageTab = (tabs using nil) ->
    with damageTab = vgui.Create('DListLayout')
        \Add('DamagelogSelectionPanel')
        with \Add('DamagelogListView')    
            \SetHeight(415)
        tabs\AddSheet(dmglog.Translate('damagelog_tab_title'), damageTab, 'icon16/application_view_detail.png')

hook.Add('TTTDamagelogsMenuOpen', 'TTTDamagelogs_DamageTab', CreateDamageTab)