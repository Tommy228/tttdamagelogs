CreateGui = (tabs) ->
    

hook.Add 'TTTDamagelogsMenuOpen', 'TTTDamagelogs_DamageTab', (tabs) ->
    damageTab = vgui.Create('DListLayout')
    damageTab\Add('DamagelogSelectionPanel')
    
    damagelogListView = damageTab\Add('DamagelogListView')
    damagelogListView\SetHeight(415)

    LoadRound = (round) ->
        print('asking')
        dmglog.AskRoundEvents round, (roundEvents) ->
            print('displaying')
            PrintTable(roundEvents)
            damagelogListView\DisplayRoundEvents(roundEvents)

    damageTab.OnSelectedRoundChanged = LoadRound

    tabs\AddSheet(dmglog.GetTranslation('damagelog_tab_title'), damageTab, 'icon16/application_view_detail.png')

    LoadRound(dmglog.roundsCount) 