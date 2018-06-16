CreateGui = (tabs) ->
    

hook.Add 'TTTDamagelogsMenuOpen', 'TTTDamagelogs_DamageTab', (tabs) ->
    damageTab = vgui.Create('DListLayout')
    
    selectionPanel = damageTab\Add('DamagelogSelectionPanel')
    
    damagelogListView = damageTab\Add('DamagelogListView')
    damagelogListView\SetHeight(415)

    LoadRound = (round) ->
        dmglog.AskRoundEvents round, (roundEvents) ->
            damagelogListView\DisplayRoundEvents(roundEvents)
            selectionPanel.roles\SetRoundNumber(round)
            selectionPanel.roles\SetRoundPlayers(roundEvents.roundPlayers)

    damageTab.OnSelectedRoundChanged = LoadRound

    tabs\AddSheet(dmglog.GetTranslation('damagelog_tab_title'), damageTab, 'icon16/application_view_detail.png')

    LoadRound(dmglog.roundsCount) 