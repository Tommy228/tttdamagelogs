
dmglog.CreateDamageTab = (tabs using nil) ->
    damageTab = vgui.Create('DListLayout')
        
    selectionPanel = damageTab\Add('DamagelogSelectionPanel')
        
    tabs\AddSheet(dmglog.Translate('damagelog_tab_title'), damageTab, 'icon16/application_view_detail.png')

hook.Add('TTTDamagelogsMenuOpen', 'TTTDamagelogs_DamageTab', dmglog.CreateDamageTab)